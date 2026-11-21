/* Reusable read models built with joins */
USE HrManagement;
GO

/* One row per employee with department, job title and manager name (self-join) */
CREATE OR ALTER VIEW dbo.vw_EmployeeDirectory
AS
SELECT
    e.EmployeeId,
    CONCAT(e.FirstName, N' ', e.LastName)       AS FullName,
    e.Email,
    d.Name                                     AS Department,
    j.Title                                    AS JobTitle,
    CONCAT(m.FirstName, N' ', m.LastName)      AS ManagerName,
    e.HireDate,
    DATEDIFF(MONTH, e.HireDate, CAST(SYSUTCDATETIME() AS DATE)) / 12 AS YearsOfService,
    e.MonthlySalary,
    e.Status
FROM dbo.Employees      AS e
JOIN dbo.Departments    AS d ON d.DepartmentId = e.DepartmentId
JOIN dbo.JobTitles      AS j ON j.JobTitleId   = e.JobTitleId
LEFT JOIN dbo.Employees AS m ON m.EmployeeId   = e.ManagerId;
GO

/* Headcount and payroll per department (active staff only); LEFT JOIN keeps empty departments */
CREATE OR ALTER VIEW dbo.vw_DepartmentHeadcount
AS
SELECT
    d.DepartmentId,
    d.Name                                            AS Department,
    d.Location,
    COUNT(e.EmployeeId)                               AS ActiveHeadcount,
    COALESCE(SUM(e.MonthlySalary), 0)                 AS MonthlyPayroll,
    CAST(COALESCE(AVG(e.MonthlySalary), 0) AS DECIMAL(10,2)) AS AvgMonthlySalary
FROM dbo.Departments AS d
LEFT JOIN dbo.Employees AS e
       ON e.DepartmentId = d.DepartmentId AND e.Status <> 'Terminated'
GROUP BY d.DepartmentId, d.Name, d.Location;
GO

/* Staffing and allocation per project */
CREATE OR ALTER VIEW dbo.vw_ProjectStaffing
AS
SELECT
    p.ProjectId,
    p.Code,
    p.Name                         AS Project,
    d.Name                         AS OwningDepartment,
    p.Budget,
    COUNT(ep.EmployeeId)           AS TeamSize,
    COALESCE(SUM(ep.AllocationPct), 0) / 100.0 AS FullTimeEquivalents,
    CASE WHEN p.EndDate IS NULL OR p.EndDate >= CAST(SYSUTCDATETIME() AS DATE) THEN 'Active' ELSE 'Closed' END AS ProjectStatus
FROM dbo.Projects AS p
JOIN dbo.Departments AS d ON d.DepartmentId = p.DepartmentId
LEFT JOIN dbo.EmployeeProjects AS ep ON ep.ProjectId = p.ProjectId
GROUP BY p.ProjectId, p.Code, p.Name, d.Name, p.Budget, p.EndDate;
GO

PRINT 'Views created.';
GO
