/* Fictional sample data (generated). Names, emails and salaries are invented. */
USE HrManagement;
GO
SET NOCOUNT ON;

INSERT INTO dbo.Departments (Name, Location) VALUES
    (N'Engineering', N'Dubai'),
    (N'Finance', N'Dubai'),
    (N'Human Resources', N'Abu Dhabi'),
    (N'Sales', N'Dubai'),
    (N'Customer Support', N'Sharjah'),
    (N'Marketing', N'Dubai');
INSERT INTO dbo.JobTitles (Title, MinSalary, MaxSalary) VALUES
    (N'Head of Department', 28000, 45000),
    (N'Senior Software Engineer', 18000, 28000),
    (N'Software Engineer', 11000, 18000),
    (N'Junior Software Engineer', 7000, 11000),
    (N'Financial Analyst', 10000, 17000),
    (N'HR Specialist', 9000, 15000),
    (N'Sales Executive', 8000, 14000),
    (N'Support Agent', 5500, 9000),
    (N'Marketing Specialist', 9000, 15000),
    (N'QA Engineer', 9000, 15000);
GO
INSERT INTO dbo.Employees (FirstName, LastName, Email, Phone, HireDate, DepartmentId, JobTitleId, ManagerId, MonthlySalary) VALUES
    (N'Aisha', N'Al Mansoori', N'aisha.almansoori@example.com', '+971531120642', '2015-01-24', 1, 1, NULL, 40000.00),
    (N'Omar', N'Iyer', N'omar.iyer@example.com', '+971511987737', '2016-04-05', 2, 1, NULL, 34000.00),
    (N'Fatima', N'Al Suwaidi', N'fatima.alsuwaidi@example.com', '+971532130789', '2015-11-24', 3, 1, NULL, 41500.00),
    (N'Rahul', N'Khan', N'rahul.khan@example.com', '+971506543670', '2015-10-14', 4, 1, NULL, 38500.00),
    (N'Priya', N'Saleh', N'priya.saleh@example.com', '+971519626108', '2015-02-07', 5, 1, NULL, 30500.00),
    (N'Ahmed', N'Das', N'ahmed.das@example.com', '+971535672073', '2019-10-01', 6, 1, NULL, 33500.00);
INSERT INTO dbo.Employees (FirstName, LastName, Email, Phone, HireDate, DepartmentId, JobTitleId, ManagerId, MonthlySalary) VALUES
    (N'Sara', N'Haddad', N'sara.haddad@example.com', '+971574594297', '2024-12-18', 5, 8, 1004, 8250.00),
    (N'Karthik', N'Pillai', N'karthik.pillai@example.com', '+971583219824', '2023-05-26', 4, 7, 1003, 11500.00),
    (N'Mariam', N'Farouk', N'mariam.farouk@example.com', '+971598930103', '2022-06-09', 1, 3, 1000, 16500.00),
    (N'Yusuf', N'Nair', N'yusuf.nair@example.com', '+971538935169', '2021-02-03', 1, 3, 1000, 17000.00),
    (N'Neha', N'Rahman', N'neha.rahman@example.com', '+971564194548', '2025-06-20', 4, 7, 1003, 10750.00),
    (N'Hassan', N'Reddy', N'hassan.reddy@example.com', '+971512626229', '2022-09-04', 3, 6, 1002, 14750.00),
    (N'Layla', N'Sharma', N'layla.sharma@example.com', '+971566944126', '2021-11-20', 4, 7, 1003, 12250.00),
    (N'Arjun', N'Fernandes', N'arjun.fernandes@example.com', '+971567897151', '2019-01-22', 4, 7, 1003, 13500.00),
    (N'Noor', N'Hamdan', N'noor.hamdan@example.com', '+971571908841', '2025-04-28', 2, 5, 1001, 10500.00),
    (N'Vikram', N'Al Hashimi', N'vikram.alhashimi@example.com', '+971512016911', '2022-11-27', 1, 10, 1000, 11000.00),
    (N'Huda', N'Qureshi', N'huda.qureshi@example.com', '+971566692553', '2021-04-22', 4, 7, 1003, 10750.00),
    (N'Sanjay', N'Thomas', N'sanjay.thomas@example.com', '+971515171761', '2024-03-18', 3, 6, 1002, 13750.00),
    (N'Reem', N'Menon', N'reem.menon@example.com', '+971534191175', '2022-05-21', 2, 5, 1001, 13500.00),
    (N'Daniel', N'Varghese', N'daniel.varghese@example.com', '+971588526486', '2021-01-08', 5, 8, 1004, 8000.00),
    (N'Ananya', N'Al Mansoori', N'ananya.almansoori@example.com', '+971528077999', '2021-02-07', 1, 4, 1000, 10000.00),
    (N'Khalid', N'Iyer', N'khalid.iyer@example.com', '+971525673212', '2024-08-13', 6, 9, 1005, 10500.00),
    (N'Meera', N'Al Suwaidi', N'meera.alsuwaidi@example.com', '+971575191056', '2020-04-24', 5, 8, 1004, 6500.00),
    (N'Ali', N'Khan', N'ali.khan@example.com', '+971518434500', '2023-07-19', 5, 8, 1004, 8250.00),
    (N'Zainab', N'Saleh', N'zainab.saleh@example.com', '+971582642635', '2020-09-16', 4, 7, 1003, 9750.00),
    (N'Rohan', N'Das', N'rohan.das@example.com', '+971501247595', '2020-11-06', 1, 2, 1000, 19750.00),
    (N'Hind', N'Haddad', N'hind.haddad@example.com', '+971514965789', '2022-10-15', 4, 7, 1003, 11000.00),
    (N'Faisal', N'Pillai', N'faisal.pillai@example.com', '+971527818496', '2025-01-22', 5, 8, 1004, 7500.00),
    (N'Divya', N'Farouk', N'divya.farouk@example.com', '+971579075854', '2019-05-14', 1, 4, 1000, 9500.00),
    (N'Tariq', N'Nair', N'tariq.nair@example.com', '+971537728339', '2024-12-09', 1, 10, 1000, 9000.00),
    (N'Sneha', N'Rahman', N'sneha.rahman@example.com', '+971503762152', '2019-11-10', 5, 8, 1004, 7500.00),
    (N'Imran', N'Reddy', N'imran.reddy@example.com', '+971561036161', '2021-03-18', 5, 8, 1004, 6000.00),
    (N'Leena', N'Sharma', N'leena.sharma@example.com', '+971565449368', '2021-08-01', 5, 8, 1004, 7750.00),
    (N'Joseph', N'Fernandes', N'joseph.fernandes@example.com', '+971575785687', '2020-01-08', 1, 4, 1000, 9250.00),
    (N'Salma', N'Hamdan', N'salma.hamdan@example.com', '+971569164991', '2024-08-27', 6, 9, 1005, 9500.00),
    (N'Nikhil', N'Al Hashimi', N'nikhil.alhashimi@example.com', '+971524185957', '2024-08-18', 1, 3, 1000, 12000.00),
    (N'Amal', N'Qureshi', N'amal.qureshi@example.com', '+971544652414', '2020-09-25', 1, 4, 1000, 10250.00),
    (N'Kevin', N'Thomas', N'kevin.thomas@example.com', '+971502022698', '2024-11-12', 2, 5, 1001, 13000.00),
    (N'Rania', N'Menon', N'rania.menon@example.com', '+971551959074', '2020-04-03', 5, 8, 1004, 5750.00),
    (N'Manoj', N'Varghese', N'manoj.varghese@example.com', '+971508999183', '2023-04-19', 4, 7, 1003, 12500.00);
UPDATE dbo.Employees SET Status = 'OnLeave' WHERE EmployeeId IN (1012, 1027);
UPDATE dbo.Employees SET Status = 'Terminated' WHERE EmployeeId = 1033;
GO
INSERT INTO dbo.Projects (Code, Name, DepartmentId, StartDate, EndDate, Budget) VALUES
    ('ENG-PORTAL', N'Customer self-service portal', 1, '2025-02-01', NULL, 850000),
    ('ENG-MOBILE', N'Field service mobile app', 1, '2025-06-15', NULL, 620000),
    ('FIN-CLOSE', N'Faster month-end close', 2, '2025-01-10', '2025-09-30', 180000),
    ('HR-ONBOARD', N'Digital onboarding', 3, '2025-04-01', NULL, 140000),
    ('SAL-CRM', N'CRM roll-out', 4, '2024-11-01', '2025-08-31', 390000),
    ('SUP-KB', N'Support knowledge base', 5, '2025-03-01', NULL, 95000),
    ('MKT-BRAND', N'Brand refresh', 6, '2025-05-01', NULL, 210000);
INSERT INTO dbo.EmployeeProjects (EmployeeId, ProjectId, Role, AllocationPct, AssignedOn) VALUES
    (1000, 1, N'Lead', 20, '2025-02-01'),
    (1033, 1, N'Coordinator', 20, '2025-02-01'),
    (1008, 1, N'Analyst', 50, '2025-02-01'),
    (1009, 1, N'Developer', 60, '2025-02-01'),
    (1035, 2, N'Tester', 80, '2025-06-15'),
    (1036, 2, N'Coordinator', 60, '2025-06-15'),
    (1000, 2, N'Lead', 60, '2025-06-15'),
    (1008, 2, N'Contributor', 40, '2025-06-15'),
    (1018, 3, N'Contributor', 50, '2025-01-10'),
    (1001, 3, N'Lead', 40, '2025-01-10'),
    (1014, 3, N'Developer', 20, '2025-01-10'),
    (1037, 3, N'Tester', 60, '2025-01-10'),
    (1009, 3, N'Coordinator', 20, '2025-01-10'),
    (1017, 4, N'Contributor', 20, '2025-04-01'),
    (1002, 4, N'Lead', 25, '2025-04-01'),
    (1011, 4, N'Contributor', 40, '2025-04-01'),
    (1009, 4, N'Analyst', 50, '2025-04-01'),
    (1039, 5, N'Developer', 25, '2024-11-01'),
    (1003, 5, N'Lead', 40, '2024-11-01'),
    (1016, 5, N'Developer', 20, '2024-11-01'),
    (1013, 5, N'Coordinator', 25, '2024-11-01'),
    (1010, 5, N'Contributor', 40, '2024-11-01'),
    (1036, 5, N'Coordinator', 25, '2024-11-01'),
    (1022, 6, N'Tester', 100, '2025-03-01'),
    (1023, 6, N'Contributor', 20, '2025-03-01'),
    (1031, 6, N'Developer', 40, '2025-03-01'),
    (1019, 6, N'Analyst', 80, '2025-03-01'),
    (1004, 6, N'Lead', 40, '2025-03-01'),
    (1008, 6, N'Analyst', 80, '2025-03-01'),
    (1034, 7, N'Developer', 80, '2025-05-01'),
    (1021, 7, N'Analyst', 60, '2025-05-01'),
    (1005, 7, N'Lead', 20, '2025-05-01'),
    (1008, 7, N'Contributor', 60, '2025-05-01');
INSERT INTO dbo.SalaryHistory (EmployeeId, OldSalary, NewSalary, EffectiveDate, Reason) VALUES
    (1035, 11320.00, 12000.00, '2025-02-01', N'Annual review'),
    (1009, 16040.00, 17000.00, '2025-06-01', N'Annual review'),
    (1027, 7080.00, 7500.00, '2025-09-01', N'Annual review'),
    (1008, 15570.00, 16500.00, '2025-07-01', N'Annual review'),
    (1002, 39150.00, 41500.00, '2025-03-01', N'Annual review'),
    (1019, 7550.00, 8000.00, '2025-04-01', N'Annual review'),
    (1023, 7780.00, 8250.00, '2025-03-01', N'Annual review'),
    (1039, 11790.00, 12500.00, '2025-03-01', N'Annual review'),
    (1022, 6130.00, 6500.00, '2025-07-01', N'Annual review'),
    (1006, 7780.00, 8250.00, '2025-01-01', N'Annual review'),
    (1021, 9910.00, 10500.00, '2025-03-01', N'Annual review'),
    (1007, 10850.00, 11500.00, '2025-06-01', N'Annual review');
INSERT INTO dbo.LeaveRequests (EmployeeId, LeaveType, StartDate, EndDate, Status, ApprovedBy) VALUES
    (1032, 'Annual', '2026-05-08', DATEADD(DAY, 3, '2026-05-08'), 'Approved', 1004),
    (1021, 'Annual', '2026-07-11', DATEADD(DAY, 4, '2026-07-11'), 'Pending', NULL),
    (1023, 'Sick', '2026-06-17', DATEADD(DAY, 0, '2026-06-17'), 'Rejected', 1004),
    (1011, 'Sick', '2026-02-09', DATEADD(DAY, 0, '2026-02-09'), 'Approved', 1002),
    (1031, 'Sick', '2026-02-20', DATEADD(DAY, 5, '2026-02-20'), 'Rejected', 1004),
    (1028, 'Unpaid', '2026-07-20', DATEADD(DAY, 9, '2026-07-20'), 'Approved', 1000),
    (1009, 'Unpaid', '2026-04-09', DATEADD(DAY, 0, '2026-04-09'), 'Approved', 1000),
    (1018, 'Sick', '2026-09-18', DATEADD(DAY, 6, '2026-09-18'), 'Approved', 1001),
    (1007, 'Annual', '2026-02-11', DATEADD(DAY, 4, '2026-02-11'), 'Pending', NULL),
    (1038, 'Sick', '2026-09-10', DATEADD(DAY, 6, '2026-09-10'), 'Rejected', 1004),
    (1013, 'Annual', '2026-12-10', DATEADD(DAY, 6, '2026-12-10'), 'Approved', 1003),
    (1012, 'Sick', '2026-11-13', DATEADD(DAY, 6, '2026-11-13'), 'Approved', 1003),
    (1020, 'Sick', '2026-09-01', DATEADD(DAY, 3, '2026-09-01'), 'Pending', NULL),
    (1017, 'Unpaid', '2026-07-19', DATEADD(DAY, 7, '2026-07-19'), 'Pending', NULL);
GO
PRINT 'Seed data loaded: ' + CAST((SELECT COUNT(*) FROM dbo.Employees) AS VARCHAR(10)) + ' employees.';
GO
