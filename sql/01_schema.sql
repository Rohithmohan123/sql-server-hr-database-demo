/* =========================================================================================
   HR Management database: schema
   Independent learning project (SQL Server 2019+). All data is fictional.
   Run order: 01_schema → 02_seed → 03_views → 04_procedures → (05_queries for examples)
   ========================================================================================= */
SET NOCOUNT ON;
GO

IF DB_ID(N'HrManagement') IS NULL
    CREATE DATABASE HrManagement;
GO
USE HrManagement;
GO

/* Drop in dependency order so the script can be re-run */
DROP VIEW IF EXISTS dbo.vw_ProjectStaffing, dbo.vw_DepartmentHeadcount, dbo.vw_EmployeeDirectory;
DROP TABLE IF EXISTS dbo.LeaveRequests, dbo.SalaryHistory, dbo.EmployeeProjects, dbo.Projects, dbo.Employees, dbo.JobTitles, dbo.Departments;
GO

/* Departments ------------------------------------------------------------------------------ */
CREATE TABLE dbo.Departments
(
    DepartmentId   INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Departments PRIMARY KEY,
    Name           NVARCHAR(100)     NOT NULL CONSTRAINT UQ_Departments_Name UNIQUE,
    Location       NVARCHAR(100)     NOT NULL,
    CreatedAt      DATETIME2(0)      NOT NULL CONSTRAINT DF_Departments_CreatedAt DEFAULT SYSUTCDATETIME()
);

/* Job titles with a salary band ------------------------------------------------------------ */
CREATE TABLE dbo.JobTitles
(
    JobTitleId     INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_JobTitles PRIMARY KEY,
    Title          NVARCHAR(100)     NOT NULL CONSTRAINT UQ_JobTitles_Title UNIQUE,
    MinSalary      DECIMAL(10,2)     NOT NULL,
    MaxSalary      DECIMAL(10,2)     NOT NULL,
    CONSTRAINT CK_JobTitles_SalaryBand CHECK (MinSalary > 0 AND MaxSalary >= MinSalary)
);

/* Employees (self-reference for the reporting line) ---------------------------------------- */
CREATE TABLE dbo.Employees
(
    EmployeeId     INT IDENTITY(1000,1) NOT NULL CONSTRAINT PK_Employees PRIMARY KEY,
    FirstName      NVARCHAR(50)      NOT NULL,
    LastName       NVARCHAR(50)      NOT NULL,
    Email          NVARCHAR(254)     NOT NULL CONSTRAINT UQ_Employees_Email UNIQUE,
    Phone          VARCHAR(20)       NULL,
    HireDate       DATE              NOT NULL,
    DepartmentId   INT               NOT NULL CONSTRAINT FK_Employees_Departments REFERENCES dbo.Departments (DepartmentId),
    JobTitleId     INT               NOT NULL CONSTRAINT FK_Employees_JobTitles   REFERENCES dbo.JobTitles (JobTitleId),
    ManagerId      INT               NULL     CONSTRAINT FK_Employees_Manager     REFERENCES dbo.Employees (EmployeeId),
    MonthlySalary  DECIMAL(10,2)     NOT NULL,
    Status         VARCHAR(12)       NOT NULL CONSTRAINT DF_Employees_Status DEFAULT 'Active',
    CreatedAt      DATETIME2(0)      NOT NULL CONSTRAINT DF_Employees_CreatedAt DEFAULT SYSUTCDATETIME(),
    UpdatedAt      DATETIME2(0)      NOT NULL CONSTRAINT DF_Employees_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT CK_Employees_Status   CHECK (Status IN ('Active', 'OnLeave', 'Terminated')),
    CONSTRAINT CK_Employees_Salary   CHECK (MonthlySalary > 0),
    CONSTRAINT CK_Employees_Email    CHECK (Email LIKE '%_@_%._%'),
    CONSTRAINT CK_Employees_NotOwnManager CHECK (ManagerId IS NULL OR ManagerId <> EmployeeId)
);
CREATE INDEX IX_Employees_DepartmentId ON dbo.Employees (DepartmentId) INCLUDE (Status, MonthlySalary);
CREATE INDEX IX_Employees_ManagerId    ON dbo.Employees (ManagerId);
CREATE INDEX IX_Employees_LastName     ON dbo.Employees (LastName, FirstName);

/* Projects owned by a department ----------------------------------------------------------- */
CREATE TABLE dbo.Projects
(
    ProjectId      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Projects PRIMARY KEY,
    Code           VARCHAR(12)       NOT NULL CONSTRAINT UQ_Projects_Code UNIQUE,
    Name           NVARCHAR(120)     NOT NULL,
    DepartmentId   INT               NOT NULL CONSTRAINT FK_Projects_Departments REFERENCES dbo.Departments (DepartmentId),
    StartDate      DATE              NOT NULL,
    EndDate        DATE              NULL,
    Budget         DECIMAL(12,2)     NOT NULL,
    CONSTRAINT CK_Projects_Dates  CHECK (EndDate IS NULL OR EndDate >= StartDate),
    CONSTRAINT CK_Projects_Budget CHECK (Budget >= 0)
);

/* Many-to-many: employees assigned to projects --------------------------------------------- */
CREATE TABLE dbo.EmployeeProjects
(
    EmployeeId     INT               NOT NULL CONSTRAINT FK_EmployeeProjects_Employees REFERENCES dbo.Employees (EmployeeId) ON DELETE CASCADE,
    ProjectId      INT               NOT NULL CONSTRAINT FK_EmployeeProjects_Projects  REFERENCES dbo.Projects (ProjectId)   ON DELETE CASCADE,
    Role           NVARCHAR(60)      NOT NULL,
    AllocationPct  TINYINT           NOT NULL,
    AssignedOn     DATE              NOT NULL CONSTRAINT DF_EmployeeProjects_AssignedOn DEFAULT CAST(SYSUTCDATETIME() AS DATE),
    CONSTRAINT PK_EmployeeProjects PRIMARY KEY (EmployeeId, ProjectId),
    CONSTRAINT CK_EmployeeProjects_Allocation CHECK (AllocationPct BETWEEN 1 AND 100)
);
CREATE INDEX IX_EmployeeProjects_ProjectId ON dbo.EmployeeProjects (ProjectId);

/* Salary history: one row per change ------------------------------------------------------- */
CREATE TABLE dbo.SalaryHistory
(
    SalaryHistoryId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_SalaryHistory PRIMARY KEY,
    EmployeeId      INT               NOT NULL CONSTRAINT FK_SalaryHistory_Employees REFERENCES dbo.Employees (EmployeeId) ON DELETE CASCADE,
    OldSalary       DECIMAL(10,2)     NOT NULL,
    NewSalary       DECIMAL(10,2)     NOT NULL,
    EffectiveDate   DATE              NOT NULL,
    Reason          NVARCHAR(200)     NOT NULL,
    CONSTRAINT CK_SalaryHistory_New CHECK (NewSalary > 0)
);
CREATE INDEX IX_SalaryHistory_Employee ON dbo.SalaryHistory (EmployeeId, EffectiveDate DESC);

/* Leave requests ----------------------------------------------------------------------------- */
CREATE TABLE dbo.LeaveRequests
(
    LeaveRequestId INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_LeaveRequests PRIMARY KEY,
    EmployeeId     INT               NOT NULL CONSTRAINT FK_LeaveRequests_Employees REFERENCES dbo.Employees (EmployeeId) ON DELETE CASCADE,
    LeaveType      VARCHAR(12)       NOT NULL,
    StartDate      DATE              NOT NULL,
    EndDate        DATE              NOT NULL,
    Status         VARCHAR(10)       NOT NULL CONSTRAINT DF_LeaveRequests_Status DEFAULT 'Pending',
    ApprovedBy     INT               NULL     CONSTRAINT FK_LeaveRequests_Approver REFERENCES dbo.Employees (EmployeeId),
    CONSTRAINT CK_LeaveRequests_Type   CHECK (LeaveType IN ('Annual', 'Sick', 'Unpaid')),
    CONSTRAINT CK_LeaveRequests_Status CHECK (Status IN ('Pending', 'Approved', 'Rejected')),
    CONSTRAINT CK_LeaveRequests_Dates  CHECK (EndDate >= StartDate)
);
CREATE INDEX IX_LeaveRequests_Employee ON dbo.LeaveRequests (EmployeeId, StartDate);
GO

PRINT 'Schema created.';
GO
