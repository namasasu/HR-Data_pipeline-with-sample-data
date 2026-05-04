-- ==============================================================================
-- GOLD LAYER: Employee Quality & Analytics Reports
-- ==============================================================================
-- Purpose: Business intelligence and quality monitoring views
-- Author: Tatenda Namasasu
-- Created: 2026-05-03
-- Source: workspace.default.employees_silver_mv
--
-- Reports:
--   1. quality_summary_report - Executive KPI dashboard
--   2. quality_by_department - Department-level metrics
--   3. quality_salary_distribution - Compensation analysis by salary band
--   4. quality_tenure_distribution - Workforce tenure demographics
--   5. quality_employment_status - Employment status monitoring
-- ==============================================================================


-- ==============================================================================
-- REPORT 1: EXECUTIVE SUMMARY - Key Performance Indicators
-- ==============================================================================
-- Purpose: High-level workforce metrics for executive dashboards
-- Metrics: Total employees, avg salary, avg tenure, retention, location spread
-- ==============================================================================

CREATE OR REFRESH MATERIALIZED VIEW quality_summary_report
COMMENT "Gold layer - Executive KPI summary with comprehensive workforce metrics"
TBLPROPERTIES ('quality' = 'gold', 'report_type' = 'executive_summary')
AS
WITH combined_stats AS (
  SELECT 
    COUNT(*) as total_count,
    COALESCE(SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END), 0) as active_count,
    COALESCE(AVG(salary), 0) as avg_salary_value,
    COALESCE(AVG(tenure_years), 0) as avg_tenure_value,
    COUNT(DISTINCT department) as dept_count,
    COUNT(DISTINCT location) as loc_count
  FROM workspace.default.employees_silver_mv
)
SELECT 
  -- Workforce size metrics
  COALESCE(total_count, 0) as total_employees,
  COALESCE(active_count, 0) as active_employees,
  COALESCE(total_count - active_count, 0) as inactive_employees,
  
  -- Retention metrics with division-by-zero protection
  ROUND(
    COALESCE(active_count, 0) * 100.0 / NULLIF(total_count, 0),
    2
  ) as retention_rate_pct,
  
  -- Compensation metrics
  CAST(ROUND(COALESCE(avg_salary_value, 0), 2) AS DECIMAL(15, 2)) as avg_salary_zar,
  
  -- Tenure metrics
  CAST(ROUND(COALESCE(avg_tenure_value, 0), 2) AS DECIMAL(10, 2)) as avg_tenure_years,
  
  -- Organizational diversity metrics
  COALESCE(dept_count, 0) as total_departments,
  COALESCE(loc_count, 0) as total_locations,
  
  -- Report metadata
  current_timestamp() as report_generated_at
FROM combined_stats;


-- ==============================================================================
-- REPORT 2: DEPARTMENT ANALYSIS - Department-level Performance
-- ==============================================================================
-- Purpose: Compare workforce metrics across departments
-- Metrics: Headcount, avg salary, avg tenure, retention by department
-- ==============================================================================

CREATE OR REFRESH MATERIALIZED VIEW quality_by_department
COMMENT "Gold layer - Department-level workforce analytics"
TBLPROPERTIES ('quality' = 'gold', 'report_type' = 'department_analysis')
AS
SELECT 
  -- Department identification
  COALESCE(department, 'Unknown') as department,
  
  -- Headcount metrics
  COALESCE(COUNT(*), 0) as employee_count,
  COALESCE(SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END), 0) as active_count,
  COALESCE(SUM(CASE WHEN is_active = false THEN 1 ELSE 0 END), 0) as inactive_count,
  
  -- Retention rate with division-by-zero protection
  ROUND(
    COALESCE(SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END), 0) * 100.0 / 
    NULLIF(COUNT(*), 0),
    2
  ) as retention_rate_pct,
  
  -- Compensation metrics
  CAST(ROUND(COALESCE(AVG(salary), 0), 2) AS DECIMAL(15, 2)) as avg_salary_zar,
  CAST(ROUND(COALESCE(MIN(salary), 0), 2) AS DECIMAL(15, 2)) as min_salary_zar,
  CAST(ROUND(COALESCE(MAX(salary), 0), 2) AS DECIMAL(15, 2)) as max_salary_zar,
  
  -- Tenure metrics
  CAST(ROUND(COALESCE(AVG(tenure_years), 0), 2) AS DECIMAL(10, 2)) as avg_tenure_years,
  
  -- Report metadata
  current_timestamp() as report_generated_at

FROM workspace.default.employees_silver_mv
GROUP BY ALL
ORDER BY employee_count DESC;


-- ==============================================================================
-- REPORT 3: SALARY DISTRIBUTION - Compensation Analysis
-- ==============================================================================
-- Purpose: Analyze workforce compensation distribution across salary bands
-- Metrics: Headcount, percentage, avg tenure by salary band
-- ==============================================================================

CREATE OR REFRESH MATERIALIZED VIEW quality_salary_distribution
COMMENT "Gold layer - Salary band distribution and compensation analytics"
TBLPROPERTIES ('quality' = 'gold', 'report_type' = 'compensation_analysis')
AS
WITH band_stats AS (
  SELECT 
    COALESCE(salary_band, 'Not Specified') as salary_band,
    COALESCE(COUNT(*), 0) as employee_count,
    COALESCE(AVG(tenure_years), 0) as avg_tenure,
    COALESCE(AVG(salary), 0) as avg_salary,
    COALESCE(SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END), 0) as active_count
  FROM workspace.default.employees_silver_mv
  GROUP BY salary_band
)
SELECT 
  salary_band,
  employee_count,
  active_count,
  
  -- Percentage of total workforce with division-by-zero protection
  ROUND(
    employee_count * 100.0 / NULLIF(SUM(employee_count) OVER(), 0),
    2
  ) as percentage_of_workforce,
  
  -- Compensation metrics
  CAST(ROUND(avg_salary, 2) AS DECIMAL(15, 2)) as avg_salary_zar,
  
  -- Tenure metrics
  CAST(ROUND(avg_tenure, 2) AS DECIMAL(10, 2)) as avg_tenure_years,
  
  -- Report metadata
  current_timestamp() as report_generated_at

FROM band_stats
ORDER BY 
  CASE salary_band
    WHEN 'Entry Level (< R400k)' THEN 1
    WHEN 'Mid Level (R400k-R700k)' THEN 2
    WHEN 'Senior (R700k-R1M)' THEN 3
    WHEN 'Executive (R1M-R1.3M)' THEN 4
    WHEN 'C-Suite (>= R1.3M)' THEN 5
    ELSE 6
  END;


-- ==============================================================================
-- REPORT 4: TENURE DISTRIBUTION - Workforce Demographics by Tenure
-- ==============================================================================
-- Purpose: Analyze workforce tenure distribution and experience levels
-- Metrics: Headcount, percentage, avg salary by tenure category
-- ==============================================================================

CREATE OR REFRESH MATERIALIZED VIEW quality_tenure_distribution
COMMENT "Gold layer - Tenure distribution and workforce experience analytics"
TBLPROPERTIES ('quality' = 'gold', 'report_type' = 'tenure_analysis')
AS
WITH tenure_stats AS (
  SELECT 
    COALESCE(tenure_category, 'Unknown') as tenure_category,
    COALESCE(COUNT(*), 0) as employee_count,
    COALESCE(AVG(salary), 0) as avg_salary,
    COALESCE(SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END), 0) as active_count,
    COALESCE(AVG(tenure_years), 0) as avg_tenure
  FROM workspace.default.employees_silver_mv
  GROUP BY tenure_category
)
SELECT 
  tenure_category,
  employee_count,
  active_count,
  
  -- Percentage of total workforce with division-by-zero protection
  ROUND(
    employee_count * 100.0 / NULLIF(SUM(employee_count) OVER(), 0),
    2
  ) as percentage_of_workforce,
  
  -- Compensation metrics
  CAST(ROUND(avg_salary, 2) AS DECIMAL(15, 2)) as avg_salary_zar,
  
  -- Tenure metrics
  CAST(ROUND(avg_tenure, 2) AS DECIMAL(10, 2)) as avg_tenure_years,
  
  -- Report metadata
  current_timestamp() as report_generated_at

FROM tenure_stats
ORDER BY 
  CASE tenure_category
    WHEN 'Entry Level' THEN 1
    WHEN 'Mid Level' THEN 2
    WHEN 'Senior Level' THEN 3
    ELSE 4
  END;


-- ==============================================================================
-- REPORT 5: EMPLOYMENT STATUS - Turnover Monitoring
-- ==============================================================================
-- Purpose: Monitor employment status and active/inactive workforce distribution
-- Metrics: Headcount, percentage, avg salary/tenure by employment status
-- ==============================================================================

CREATE OR REFRESH MATERIALIZED VIEW quality_employment_status
COMMENT "Gold layer - Employment status distribution and turnover analytics"
TBLPROPERTIES ('quality' = 'gold', 'report_type' = 'status_monitoring')
AS
WITH status_stats AS (
  SELECT 
    COALESCE(status, 'Unknown') as status,
    COALESCE(is_active, false) as is_active,
    COALESCE(COUNT(*), 0) as employee_count,
    COALESCE(AVG(salary), 0) as avg_salary,
    COALESCE(AVG(tenure_years), 0) as avg_tenure
  FROM workspace.default.employees_silver_mv
  GROUP BY status, is_active
)
SELECT 
  status,
  is_active,
  employee_count,
  
  -- Percentage of total workforce with division-by-zero protection
  ROUND(
    employee_count * 100.0 / NULLIF(SUM(employee_count) OVER(), 0),
    2
  ) as percentage_of_workforce,
  
  -- Compensation metrics
  CAST(ROUND(avg_salary, 2) AS DECIMAL(15, 2)) as avg_salary_zar,
  
  -- Tenure metrics
  CAST(ROUND(avg_tenure, 2) AS DECIMAL(10, 2)) as avg_tenure_years,
  
  -- Report metadata
  current_timestamp() as report_generated_at

FROM status_stats
ORDER BY employee_count DESC;


-- ==============================================================================
-- END OF GOLD LAYER QUALITY REPORTS
-- ==============================================================================
-- Output Tables (all materialized views):
--   1. workspace.default.quality_summary_report - Executive KPIs
--   2. workspace.default.quality_by_department - Department metrics
--   3. workspace.default.quality_salary_distribution - Salary band analysis
--   4. workspace.default.quality_tenure_distribution - Tenure demographics
--   5. workspace.default.quality_employment_status - Status monitoring
--
-- All reports include:
--   - Comprehensive NULL and division-by-zero handling
--   - Report generation timestamp
--   - Professional South African business context (ZAR currency)
--   - Optimized for empty data scenarios (returns zeros, not errors)
-- ==============================================================================
