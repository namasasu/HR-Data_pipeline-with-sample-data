-- ==============================================================================
-- SILVER LAYER: Employee Data Transformation & Quality
-- ==============================================================================
-- Purpose: Clean and enrich bronze employee data with business logic
-- Author: Tatenda Namasasu
-- Created: 2026-05-03
-- Source: workspace.default.bronze_employees (bronze layer)
--
-- Transformations:
--   - Data quality validations with expectations
--   - Derived columns: full_name, tenure_years, salary_band
--   - Type conversions and null handling
--   - Business rule enforcement
-- ==============================================================================

CREATE OR REFRESH MATERIALIZED VIEW employees_silver_mv
(
  -- Critical data quality constraints (FAIL UPDATE or DROP ROW)
  CONSTRAINT valid_employee_id EXPECT (employee_id IS NOT NULL AND employee_id != '') ON VIOLATION FAIL UPDATE,
  CONSTRAINT valid_name EXPECT (first_name IS NOT NULL AND last_name IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_department EXPECT (department IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_salary EXPECT (salary > 0) ON VIOLATION DROP ROW,
  CONSTRAINT valid_hire_date EXPECT (hire_date IS NOT NULL AND hire_date <= current_date()) ON VIOLATION DROP ROW,
  CONSTRAINT valid_location EXPECT (location IS NOT NULL) ON VIOLATION DROP ROW,
  
  -- Warning-level constraints (tracked but don't drop rows)
  CONSTRAINT valid_email_format EXPECT (email LIKE '%@%.%'),
  CONSTRAINT reasonable_salary_range EXPECT (salary BETWEEN 250000 AND 2000000)
)
CLUSTER BY (department, status)
COMMENT "Silver layer - Cleaned and enriched employee data with quality checks (Materialized View)"
TBLPROPERTIES (
  'quality' = 'silver'
)
AS
SELECT 
  -- ============================================================================
  -- IDENTITY COLUMNS
  -- ============================================================================
  employee_id,
  
  -- Combine first and last name for convenience
  concat(first_name, ' ', last_name) as full_name,
  first_name,
  last_name,
  
  -- Clean and validate email
  lower(trim(email)) as email,
  
  -- ============================================================================
  -- ORGANIZATIONAL DATA
  -- ============================================================================
  COALESCE(department, 'Unknown') as department,
  COALESCE(job_title, 'Not Specified') as job_title,
  COALESCE(location, 'Unknown') as location,
  
  -- ============================================================================
  -- COMPENSATION DATA
  -- ============================================================================
  -- Ensure salary is positive and cast to FLOAT for consistency
  CAST(COALESCE(salary, 0) AS FLOAT) as salary,
  
  -- Salary band categorization for reporting
  CASE 
    WHEN salary IS NULL OR salary = 0 THEN 'Not Specified'
    WHEN salary < 400000 THEN 'Entry Level (< R400k)'
    WHEN salary < 700000 THEN 'Mid Level (R400k-R700k)'
    WHEN salary < 1000000 THEN 'Senior (R700k-R1M)'
    WHEN salary < 1300000 THEN 'Executive (R1M-R1.3M)'
    ELSE 'C-Suite (>= R1.3M)'
  END as salary_band,
  
  -- ============================================================================
  -- EMPLOYMENT DATA
  -- ============================================================================
  hire_date,
  
  -- Calculate tenure in years with explicit decimal type
  CAST(
    GREATEST(
      round(datediff(current_date(), hire_date) / 365.25, 2),
      0.0
    ) AS DECIMAL(10, 2)
  ) as tenure_years,
  
  -- Tenure category: Entry Level, Mid Level, Senior Level
  CASE 
    WHEN datediff(current_date(), hire_date) < 730 THEN 'Entry Level'
    WHEN datediff(current_date(), hire_date) < 1825 THEN 'Mid Level'
    ELSE 'Senior Level'
  END as tenure_category,
  
  -- Employment status
  COALESCE(status, 'Unknown') as status,
  
  -- Derive boolean for easier filtering
  CASE WHEN lower(status) = 'active' THEN true ELSE false END as is_active,
  
  -- ============================================================================
  -- AUDIT & METADATA
  -- ============================================================================
  ingestion_timestamp as bronze_ingestion_timestamp,
  current_timestamp() as silver_processed_timestamp

FROM workspace.default.bronze_employees;

-- ==============================================================================
-- END OF SILVER LAYER TRANSFORMATION
-- ==============================================================================
-- Output Table: workspace.default.employees_silver_mv (Materialized View)
--
-- Output Schema:
--   - employee_id (STRING) - Primary key
--   - full_name (STRING) - Combined first and last name
--   - first_name (STRING) - Given name
--   - last_name (STRING) - Surname
--   - email (STRING) - Lowercase, trimmed email
--   - department (STRING) - Department with default handling
--   - job_title (STRING) - Job role
--   - location (STRING) - Office location in South Africa
--   - salary (FLOAT) - Annual compensation in ZAR
--   - salary_band (STRING) - Categorized salary range
--   - hire_date (DATE) - Date of hire
--   - tenure_years (DECIMAL(10,2)) - Years with company
--   - tenure_category (STRING) - Entry Level (< 2 years), Mid Level (2-5 years), Senior Level (5+ years)
--   - status (STRING) - Employment status
--   - is_active (BOOLEAN) - Active employee flag
--   - bronze_ingestion_timestamp (TIMESTAMP) - Source data timestamp
--   - silver_processed_timestamp (TIMESTAMP) - Silver processing timestamp
--
-- Data Quality:
--   - FAIL UPDATE: Invalid employee_id (critical)
--   - DROP ROW: Missing name, department, invalid salary/hire_date/location
--   - TRACKED: Invalid email format, salary outside typical range (250k-2M ZAR)
--
-- Clustering: By department and status for optimized query performance
-- Architecture Note: Materialized View (batch) handles bronze layer overwrites correctly
-- Note: Old silver_employees (streaming table) will become inactive once this is established
-- ==============================================================================
