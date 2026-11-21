/* Automated checks. Each test THROWs on failure, so sqlcmd -b exits non-zero and CI fails.
   Run after 01–04. Everything runs inside a transaction that is rolled back, leaving the data unchanged. */
USE HrManagement;
GO
SET NOCOUNT ON;
SET XACT_ABORT OFF;
DECLARE @failures INT = 0, @id INT, @n INT, @msg NVARCHAR(400);

BEGIN TRANSACTION;

/* T1 seed data loaded */
IF (SELECT COUNT(*) FROM dbo.Employees) <> 40 BEGIN SET @failures += 1; PRINT 'FAIL T1: expected 40 employees'; END ELSE PRINT 'PASS T1 seed data';

/* T2 create employee via procedure */
EXEC dbo.usp_Employee_Create @FirstName = N'Test', @LastName = N'User', @Email = N'test.user@example.com', @HireDate = '2026-01-05',
     @DepartmentId = 1, @JobTitleId = 4, @ManagerId = 1000, @MonthlySalary = 8000, @NewEmployeeId = @id OUTPUT;
IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @id AND Email = N'test.user@example.com') BEGIN SET @failures += 1; PRINT 'FAIL T2: create'; END ELSE PRINT 'PASS T2 create';

/* T3 duplicate email rejected */
BEGIN TRY
    EXEC dbo.usp_Employee_Create @FirstName = N'Dup', @LastName = N'User', @Email = N'test.user@example.com', @HireDate = '2026-01-05',
         @DepartmentId = 1, @JobTitleId = 4, @MonthlySalary = 8000, @NewEmployeeId = @n OUTPUT;
    SET @failures += 1; PRINT 'FAIL T3: duplicate email accepted';
END TRY BEGIN CATCH IF ERROR_NUMBER() = 50002 PRINT 'PASS T3 duplicate email rejected'; ELSE BEGIN SET @failures += 1; PRINT 'FAIL T3: ' + ERROR_MESSAGE(); END END CATCH;

/* T4 salary outside band rejected */
BEGIN TRY
    EXEC dbo.usp_Employee_Create @FirstName = N'Band', @LastName = N'Test', @Email = N'band.test@example.com', @HireDate = '2026-01-05',
         @DepartmentId = 1, @JobTitleId = 4, @MonthlySalary = 99999, @NewEmployeeId = @n OUTPUT;
    SET @failures += 1; PRINT 'FAIL T4: out-of-band salary accepted';
END TRY BEGIN CATCH IF ERROR_NUMBER() = 50003 PRINT 'PASS T4 salary band enforced'; ELSE BEGIN SET @failures += 1; PRINT 'FAIL T4: ' + ERROR_MESSAGE(); END END CATCH;

/* T5 check constraint: invalid status */
BEGIN TRY
    UPDATE dbo.Employees SET Status = 'Retired' WHERE EmployeeId = @id;
    SET @failures += 1; PRINT 'FAIL T5: invalid status accepted';
END TRY BEGIN CATCH PRINT 'PASS T5 status check constraint'; END CATCH;

/* T6 update via procedure */
EXEC dbo.usp_Employee_Update @EmployeeId = @id, @Phone = '+971500000000', @DepartmentId = 1, @JobTitleId = 4, @ManagerId = 1000, @Status = 'OnLeave';
IF NOT EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @id AND Status = 'OnLeave') BEGIN SET @failures += 1; PRINT 'FAIL T6: update'; END ELSE PRINT 'PASS T6 update';

/* T7 salary change writes history atomically */
EXEC dbo.usp_Employee_ChangeSalary @EmployeeId = @id, @NewSalary = 9000, @EffectiveDate = '2026-06-01', @Reason = N'Probation completed';
IF NOT EXISTS (SELECT 1 FROM dbo.SalaryHistory WHERE EmployeeId = @id AND OldSalary = 8000 AND NewSalary = 9000)
   OR (SELECT MonthlySalary FROM dbo.Employees WHERE EmployeeId = @id) <> 9000
   BEGIN SET @failures += 1; PRINT 'FAIL T7: salary change'; END ELSE PRINT 'PASS T7 salary change + history';

/* T8 cannot delete a manager with direct reports */
BEGIN TRY
    EXEC dbo.usp_Employee_Delete @EmployeeId = 1000;
    SET @failures += 1; PRINT 'FAIL T8: deleted a manager';
END TRY BEGIN CATCH IF ERROR_NUMBER() = 50005 PRINT 'PASS T8 manager delete blocked'; ELSE BEGIN SET @failures += 1; PRINT 'FAIL T8: ' + ERROR_MESSAGE(); END END CATCH;

/* T9 leave request decided only by the manager */
INSERT INTO dbo.LeaveRequests (EmployeeId, LeaveType, StartDate, EndDate) VALUES (@id, 'Annual', '2026-07-01', '2026-07-03');
SET @n = CAST(SCOPE_IDENTITY() AS INT);
BEGIN TRY
    EXEC dbo.usp_LeaveRequest_Decide @LeaveRequestId = @n, @ApproverId = 1001, @Approve = 1;
    SET @failures += 1; PRINT 'FAIL T9: non-manager approved leave';
END TRY BEGIN CATCH IF ERROR_NUMBER() = 50007 PRINT 'PASS T9a only manager can decide'; ELSE BEGIN SET @failures += 1; PRINT 'FAIL T9a: ' + ERROR_MESSAGE(); END END CATCH;
EXEC dbo.usp_LeaveRequest_Decide @LeaveRequestId = @n, @ApproverId = 1000, @Approve = 1;
IF NOT EXISTS (SELECT 1 FROM dbo.LeaveRequests WHERE LeaveRequestId = @n AND Status = 'Approved' AND ApprovedBy = 1000) BEGIN SET @failures += 1; PRINT 'FAIL T9b: approve'; END ELSE PRINT 'PASS T9b manager approves';

/* T10 delete cascades to assignments, history and leave */
INSERT INTO dbo.EmployeeProjects (EmployeeId, ProjectId, Role, AllocationPct) VALUES (@id, 1, N'Tester', 50);
EXEC dbo.usp_Employee_Delete @EmployeeId = @id;
IF EXISTS (SELECT 1 FROM dbo.Employees WHERE EmployeeId = @id) OR EXISTS (SELECT 1 FROM dbo.EmployeeProjects WHERE EmployeeId = @id)
   OR EXISTS (SELECT 1 FROM dbo.SalaryHistory WHERE EmployeeId = @id) OR EXISTS (SELECT 1 FROM dbo.LeaveRequests WHERE EmployeeId = @id)
   BEGIN SET @failures += 1; PRINT 'FAIL T10: delete cascade'; END ELSE PRINT 'PASS T10 delete cascades';

/* T11 views agree with base tables */
IF (SELECT SUM(ActiveHeadcount) FROM dbo.vw_DepartmentHeadcount) <> (SELECT COUNT(*) FROM dbo.Employees WHERE Status <> 'Terminated')
   BEGIN SET @failures += 1; PRINT 'FAIL T11: headcount view'; END ELSE PRINT 'PASS T11 headcount view';
IF (SELECT COUNT(*) FROM dbo.vw_EmployeeDirectory) <> (SELECT COUNT(*) FROM dbo.Employees)
   BEGIN SET @failures += 1; PRINT 'FAIL T12: directory view'; END ELSE PRINT 'PASS T12 directory view';

/* T13 search paging returns at most PageSize rows and a total */
DECLARE @page TABLE (EmployeeId INT, FullName NVARCHAR(120), Email NVARCHAR(254), Department NVARCHAR(100), JobTitle NVARCHAR(100), Status VARCHAR(12), TotalRows INT);
INSERT INTO @page EXEC dbo.usp_Employee_Search @PageNumber = 2, @PageSize = 10;
IF (SELECT COUNT(*) FROM @page) <> 10 OR (SELECT MAX(TotalRows) FROM @page) <> (SELECT COUNT(*) FROM dbo.Employees)
   BEGIN SET @failures += 1; PRINT 'FAIL T13: paging'; END ELSE PRINT 'PASS T13 search paging';

ROLLBACK TRANSACTION;

IF @failures > 0
BEGIN
    SET @msg = CONCAT(@failures, ' test(s) failed.');
    THROW 50999, @msg, 1;
END
PRINT 'All tests passed.';
GO
