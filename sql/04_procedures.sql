/* Stored procedures: CRUD, search with paging, salary change in a transaction, leave approval */
USE HrManagement;
GO

/* CREATE ------------------------------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.usp_Employee_Create
    @FirstName     NVARCHAR(50),
    @LastName      NVARCHAR(50),
    @Email         NVARCHAR(254),
    @Phone         VARCHAR(20) = NULL,
    @HireDate      DATE,
    @DepartmentId  INT,
    @JobTitleId    INT,
    @ManagerId     INT = NULL,
    @MonthlySalary DECIMAL(10,2),
    @NewEmployeeId INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM dbo.Departments WHERE DepartmentId = @DepartmentId)
        THROW 50001, 'Department does not exist.', 1;
    IF EXISTS (SELECT 1 FROM dbo.Employees WHERE Email = @Email)
        THROW 50002, 'An employee with this email already exists.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.JobTitles WHERE JobTitleId = @JobTitleId AND @MonthlySalary BETWEEN MinSalary AND MaxSalary)
        THROW 50003, 'Salary is outside the band for this job title (or the job title does not exist).', 1;

    INSERT INTO dbo.Employees (FirstName, LastName, Email, Phone, HireDate, DepartmentId, JobTitleId, ManagerId, MonthlySalary)
    VALUES (@FirstName, @LastName, @Email, @Phone, @HireDate, @DepartmentId, @JobTitleId, @ManagerId, @MonthlySalary);

    SET @NewEmployeeId = CAST(SCOPE_IDENTITY() AS INT);
END;
GO

/* READ (single) ------------------------------------------------------------------------------ */
CREATE OR ALTER PROCEDURE dbo.usp_Employee_GetById
    @EmployeeId INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM dbo.vw_EmployeeDirectory WHERE EmployeeId = @EmployeeId;

    SELECT p.Code, p.Name, ep.Role, ep.AllocationPct
    FROM dbo.EmployeeProjects AS ep
    JOIN dbo.Projects AS p ON p.ProjectId = ep.ProjectId
    WHERE ep.EmployeeId = @EmployeeId
    ORDER BY p.Code;
END;
GO

/* READ (search + paging) --------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_Employee_Search
    @Search       NVARCHAR(100) = NULL,
    @DepartmentId INT = NULL,
    @Status       VARCHAR(12) = NULL,
    @PageNumber   INT = 1,
    @PageSize     INT = 20
AS
BEGIN
    SET NOCOUNT ON;
    IF @PageNumber < 1 SET @PageNumber = 1;
    IF @PageSize NOT BETWEEN 1 AND 100 SET @PageSize = 20;

    SELECT e.EmployeeId, CONCAT(e.FirstName, N' ', e.LastName) AS FullName, e.Email, d.Name AS Department,
           j.Title AS JobTitle, e.Status,
           COUNT(*) OVER () AS TotalRows
    FROM dbo.Employees AS e
    JOIN dbo.Departments AS d ON d.DepartmentId = e.DepartmentId
    JOIN dbo.JobTitles   AS j ON j.JobTitleId   = e.JobTitleId
    WHERE (@Search IS NULL OR e.FirstName LIKE N'%' + @Search + N'%' OR e.LastName LIKE N'%' + @Search + N'%' OR e.Email LIKE N'%' + @Search + N'%')
      AND (@DepartmentId IS NULL OR e.DepartmentId = @DepartmentId)
      AND (@Status IS NULL OR e.Status = @Status)
    ORDER BY e.LastName, e.FirstName, e.EmployeeId
    OFFSET (@PageNumber - 1) * @PageSize ROWS FETCH NEXT @PageSize ROWS ONLY;
END;
GO

/* UPDATE ------------------------------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_Employee_Update
    @EmployeeId   INT,
    @Phone        VARCHAR(20) = NULL,
    @DepartmentId INT,
    @JobTitleId   INT,
    @ManagerId    INT = NULL,
    @Status       VARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    IF @ManagerId = @EmployeeId THROW 50004, 'An employee cannot be their own manager.', 1;

    UPDATE dbo.Employees
       SET Phone = @Phone, DepartmentId = @DepartmentId, JobTitleId = @JobTitleId,
           ManagerId = @ManagerId, Status = @Status, UpdatedAt = SYSUTCDATETIME()
     WHERE EmployeeId = @EmployeeId;

    IF @@ROWCOUNT = 0 THROW 50404, 'Employee not found.', 1;
END;
GO

/* DELETE: blocked while the employee still manages people ---------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_Employee_Delete
    @EmployeeId INT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.Employees WHERE ManagerId = @EmployeeId)
        THROW 50005, 'Reassign this employee''s direct reports before deleting.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId)
        THROW 50404, 'Employee not found.', 1;

    -- Own transaction, or a savepoint when the caller already has one, so a failure never dooms the caller
    DECLARE @outer INT = @@TRANCOUNT;
    BEGIN TRY
        IF @outer = 0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION EmployeeDelete;
        UPDATE dbo.LeaveRequests SET ApprovedBy = NULL WHERE ApprovedBy = @EmployeeId;
        DELETE FROM dbo.Employees WHERE EmployeeId = @EmployeeId;   -- assignments, history and leave cascade
        IF @outer = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 BEGIN IF @outer = 0 ROLLBACK TRANSACTION; ELSE ROLLBACK TRANSACTION EmployeeDelete; END;
        THROW;
    END CATCH;
END;
GO

/* Salary change: updates the employee and writes history in one transaction ---------------- */
CREATE OR ALTER PROCEDURE dbo.usp_Employee_ChangeSalary
    @EmployeeId    INT,
    @NewSalary     DECIMAL(10,2),
    @EffectiveDate DATE,
    @Reason        NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Old DECIMAL(10,2), @Min DECIMAL(10,2), @Max DECIMAL(10,2);

    SELECT @Old = e.MonthlySalary, @Min = j.MinSalary, @Max = j.MaxSalary
    FROM dbo.Employees AS e JOIN dbo.JobTitles AS j ON j.JobTitleId = e.JobTitleId
    WHERE e.EmployeeId = @EmployeeId;

    IF @Old IS NULL THROW 50404, 'Employee not found.', 1;
    IF @NewSalary NOT BETWEEN @Min AND @Max THROW 50003, 'Salary is outside the band for this job title.', 1;

    DECLARE @outer INT = @@TRANCOUNT;
    BEGIN TRY
        IF @outer = 0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION SalaryChange;
        UPDATE dbo.Employees SET MonthlySalary = @NewSalary, UpdatedAt = SYSUTCDATETIME() WHERE EmployeeId = @EmployeeId;
        INSERT INTO dbo.SalaryHistory (EmployeeId, OldSalary, NewSalary, EffectiveDate, Reason)
        VALUES (@EmployeeId, @Old, @NewSalary, @EffectiveDate, @Reason);
        IF @outer = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() = -1 ROLLBACK TRANSACTION;
        ELSE IF XACT_STATE() = 1 BEGIN IF @outer = 0 ROLLBACK TRANSACTION; ELSE ROLLBACK TRANSACTION SalaryChange; END;
        THROW;
    END CATCH;
END;
GO

/* Leave approval: only the employee's manager (or department head) can decide ------------- */
CREATE OR ALTER PROCEDURE dbo.usp_LeaveRequest_Decide
    @LeaveRequestId INT,
    @ApproverId     INT,
    @Approve        BIT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EmployeeId INT, @Status VARCHAR(10);
    SELECT @EmployeeId = EmployeeId, @Status = Status FROM dbo.LeaveRequests WHERE LeaveRequestId = @LeaveRequestId;

    IF @EmployeeId IS NULL THROW 50404, 'Leave request not found.', 1;
    IF @Status <> 'Pending' THROW 50006, 'Only pending requests can be decided.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @EmployeeId AND ManagerId = @ApproverId)
        THROW 50007, 'Only the employee''s manager can decide this request.', 1;

    UPDATE dbo.LeaveRequests
       SET Status = CASE WHEN @Approve = 1 THEN 'Approved' ELSE 'Rejected' END, ApprovedBy = @ApproverId
     WHERE LeaveRequestId = @LeaveRequestId;
END;
GO

/* Department summary report ----------------------------------------------------------------- */
CREATE OR ALTER PROCEDURE dbo.usp_Department_Summary
    @DepartmentId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SELECT h.Department, h.Location, h.ActiveHeadcount, h.MonthlyPayroll, h.AvgMonthlySalary,
           (SELECT COUNT(*) FROM dbo.Projects AS p WHERE p.DepartmentId = h.DepartmentId) AS Projects
    FROM dbo.vw_DepartmentHeadcount AS h
    WHERE @DepartmentId IS NULL OR h.DepartmentId = @DepartmentId
    ORDER BY h.MonthlyPayroll DESC;
END;
GO

PRINT 'Stored procedures created.';
GO
