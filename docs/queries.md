# Example queries explained

All queries are in [`sql/05_queries.sql`](../sql/05_queries.sql) and run against the fictional sample data.

| # | Technique | Question it answers |
|---|---|---|
| Q1 | `INNER JOIN` across three tables | Who are the active employees, and which department and job title does each have? |
| Q2 | `LEFT JOIN … WHERE right.key IS NULL` (anti-join) | Which current employees are not assigned to any project? |
| Q3 | Self-join + `GROUP BY` | How many direct reports does each manager have? |
| Q4 | `GROUP BY` + `HAVING` with a subquery | Which departments pay above the company average? |
| Q5 | Window function `RANK() OVER (PARTITION BY …)` | How does each person's salary rank within their department? |
| Q6 | Recursive CTE | What is the full reporting chain under a department head? |
| Q7 | Aggregation with `HAVING` | Who is allocated to more than 100% across projects? |
| Q8 | Date functions, filtered aggregation | How many approved leave days has each person taken this year? |
| Q9 | Views | Department headcount and payroll; project staffing |
| Q10 | Stored procedures | Paged employee search; department summary report |

## Notes on design choices

- **Anti-join (Q2)** with `LEFT JOIN … IS NULL` is clear and uses the index on `EmployeeProjects(EmployeeId)` through the primary key. `NOT EXISTS` would work equally well.
- **Recursive CTE (Q6)** builds a readable path string (`Head > Lead > Engineer`) and a `Level` column, which is easy to indent in a report.
- **Paging (`usp_Employee_Search`)** uses `OFFSET … FETCH` with a deterministic `ORDER BY` (last name, first name, id) so pages never overlap. `COUNT(*) OVER ()` returns the total without a second query.
- **Transactions**: `usp_Employee_ChangeSalary` and `usp_Employee_Delete` change several rows; they commit all-or-nothing, using a savepoint when called inside an existing transaction.
