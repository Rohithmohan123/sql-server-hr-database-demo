/* Documented example queries (explained in docs/queries.md) */
USE HrManagement;
GO

/* Q1. INNER JOIN: active employees with department and job title */
SELECT e.EmployeeId, e.FirstName, e.LastName, d.Name AS Department, j.Title
FROM dbo.Employees AS e
INNER JOIN dbo.Departments AS d ON d.DepartmentId = e.DepartmentId
INNER JOIN dbo.JobTitles   AS j ON j.JobTitleId   = e.JobTitleId
WHERE e.Status = 'Active'
ORDER BY d.Name, e.LastName;

/* Q2. LEFT JOIN: employees not assigned to any project */
SELECT e.EmployeeId, CONCAT(e.FirstName, ' ', e.LastName) AS FullName, d.Name AS Department
FROM dbo.Employees AS e
JOIN dbo.Departments AS d ON d.DepartmentId = e.DepartmentId
LEFT JOIN dbo.EmployeeProjects AS ep ON ep.EmployeeId = e.EmployeeId
WHERE ep.EmployeeId IS NULL AND e.Status <> 'Terminated';

/* Q3. SELF JOIN: each manager and how many direct reports they have */
SELECT m.EmployeeId AS ManagerId, CONCAT(m.FirstName, ' ', m.LastName) AS Manager, COUNT(r.EmployeeId) AS DirectReports
FROM dbo.Employees AS m
JOIN dbo.Employees AS r ON r.ManagerId = m.EmployeeId
GROUP BY m.EmployeeId, m.FirstName, m.LastName
ORDER BY DirectReports DESC;

/* Q4. GROUP BY + HAVING: departments whose average salary is above the company average */
SELECT d.Name AS Department, CAST(AVG(e.MonthlySalary) AS DECIMAL(10,2)) AS AvgSalary
FROM dbo.Employees AS e
JOIN dbo.Departments AS d ON d.DepartmentId = e.DepartmentId
WHERE e.Status <> 'Terminated'
GROUP BY d.Name
HAVING AVG(e.MonthlySalary) > (SELECT AVG(MonthlySalary) FROM dbo.Employees WHERE Status <> 'Terminated');

/* Q5. Window function: salary rank within each department */
SELECT Department, FullName, JobTitle, MonthlySalary,
       RANK() OVER (PARTITION BY Department ORDER BY MonthlySalary DESC) AS SalaryRank
FROM dbo.vw_EmployeeDirectory
WHERE Status <> 'Terminated';

/* Q6. Recursive CTE: full reporting chain under one department head */
WITH OrgChart AS
(
    SELECT EmployeeId, ManagerId, CAST(CONCAT(FirstName, ' ', LastName) AS NVARCHAR(400)) AS Path, 0 AS Level
    FROM dbo.Employees
    WHERE EmployeeId = 1000
    UNION ALL
    SELECT e.EmployeeId, e.ManagerId, CAST(CONCAT(o.Path, N' > ', e.FirstName, N' ', e.LastName) AS NVARCHAR(400)), o.Level + 1
    FROM dbo.Employees AS e
    JOIN OrgChart AS o ON e.ManagerId = o.EmployeeId
)
SELECT EmployeeId, Level, Path FROM OrgChart ORDER BY Level, Path;

/* Q7. Over-allocated employees (more than 100% across projects) */
SELECT ep.EmployeeId, CONCAT(e.FirstName, ' ', e.LastName) AS FullName, SUM(ep.AllocationPct) AS TotalAllocation
FROM dbo.EmployeeProjects AS ep
JOIN dbo.Employees AS e ON e.EmployeeId = ep.EmployeeId
GROUP BY ep.EmployeeId, e.FirstName, e.LastName
HAVING SUM(ep.AllocationPct) > 100;

/* Q8. Leave days taken per employee this year (approved only) */
SELECT e.EmployeeId, CONCAT(e.FirstName, ' ', e.LastName) AS FullName,
       SUM(DATEDIFF(DAY, lr.StartDate, lr.EndDate) + 1) AS ApprovedLeaveDays
FROM dbo.LeaveRequests AS lr
JOIN dbo.Employees AS e ON e.EmployeeId = lr.EmployeeId
WHERE lr.Status = 'Approved' AND YEAR(lr.StartDate) = YEAR(SYSUTCDATETIME())
GROUP BY e.EmployeeId, e.FirstName, e.LastName
ORDER BY ApprovedLeaveDays DESC;

/* Q9. Views in use */
SELECT * FROM dbo.vw_DepartmentHeadcount ORDER BY MonthlyPayroll DESC;
SELECT * FROM dbo.vw_ProjectStaffing ORDER BY Budget DESC;

/* Q10. Stored procedures in use */
EXEC dbo.usp_Employee_Search @Search = N'an', @PageNumber = 1, @PageSize = 5;
EXEC dbo.usp_Department_Summary;
GO
