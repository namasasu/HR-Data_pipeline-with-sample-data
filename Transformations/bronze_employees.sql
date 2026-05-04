-- ==============================================================================
-- BRONZE LAYER: Employee Data Generation
-- ==============================================================================
-- Purpose: Generating sample employee records for pipeline testing
-- Author: Tatenda Namasasu 
-- Created: 2026-04-30
--
-- Notes:
--   This is a simple function to generate sample employee data for testing model pipeline. 
--   Normally,in production, this would be replaced with Auto Loader reading from
--   cloud storage or a streaming source. This is a convenience function
--   for demonstrating the pipeline's data quality and transformation logic.
-- ==============================================================================

CREATE OR REFRESH MATERIALIZED VIEW bronze_employees
COMMENT "Bronze layer - Sample employee data (200 records)"
TBLPROPERTIES (
  'quality' = 'bronze'
)
AS
WITH numbered_rows AS (
  -- Generate 200 sequential row numbers using sequence + explode
  SELECT explode(sequence(1, 200)) as row_num
),
random_data AS (
  -- Generate pseudo-random values using hash functions on row_num
  -- This provides deterministic but varied selections across rows
  SELECT 
    row_num,
    -- Use mod with hash to create index values for array selection
    abs(hash(concat('fname_', row_num))) % 24 as first_name_idx,
    abs(hash(concat('lname_', row_num))) % 24 as last_name_idx,
    abs(hash(concat('dept_', row_num))) % 8 as dept_idx,
    abs(hash(concat('job_', row_num))) % 8 as job_idx,
    abs(hash(concat('loc_', row_num))) % 8 as loc_idx,
    -- Use hash for salary variation (0 to 1200000 range for ZAR)
    abs(hash(concat('salary_', row_num))) % 1200000 as salary_offset,
    -- Use hash for hire date variation (0 to 1800 days)
    abs(hash(concat('hire_', row_num))) % 1800 as hire_days,
    -- Use hash for status (0-99, threshold at 80 for 80% Active)
    abs(hash(concat('status_', row_num))) % 100 as status_rand
  FROM numbered_rows
)
SELECT 
  -- Employee ID: EMP00001, EMP00002, ..., EMP00200
  concat('EMP', lpad(cast(row_num as string), 5, '0')) as employee_id,
  
  -- Random African first names from array of 24 common South African names
  array('Thabo', 'Zanele', 'Sipho', 'Nomsa', 'Mandla', 'Lindiwe', 'Bongani', 'Thandeka', 
        'Kagiso', 'Naledi', 'Tshepo', 'Palesa', 'Lerato', 'Sizwe', 'Mbali', 'Nkosi',
        'Themba', 'Zinhle', 'Mpho', 'Busisiwe', 'Jabu', 'Ntombi', 'Musa', 'Nandi')[first_name_idx] as first_name,
  
  -- Random African surnames from array of 24 common South African surnames
  array('Ndlovu', 'Dlamini', 'Khumalo', 'Nkosi', 'Mokoena', 'Mthembu', 'Sithole', 'Mahlangu',
        'Ngcobo', 'Zulu', 'Molefe', 'Naidoo', 'Shabalala', 'Zwane', 'Maseko', 'Radebe',
        'Mabaso', 'Sibiya', 'Vilakazi', 'Mtshali', 'Cele', 'Buthelezi', 'Mazibuko', 'Khoza')[last_name_idx] as last_name,
  
  -- Email address: employee1@company.com, employee2@company.com, etc.
  concat('employee', row_num, '@company.com') as email,
  
  -- Random department from 8 departments
  array('Engineering', 'Sales', 'Marketing', 'HR', 'Finance', 'Operations', 'IT', 'Customer Support')[dept_idx] as department,
  
  -- Random job title from 8 titles
  array('Manager', 'Senior Analyst', 'Analyst', 'Coordinator', 'Specialist', 'Director', 'Associate', 'Lead')[job_idx] as job_title,
  
  -- Random salary between R300,000 and R1,500,000 ZAR, rounded to 2 decimal places
  round(300000 + salary_offset, 2) as salary,
  
  -- Random hire date between 2020-01-01 and approximately 2024-11-25 (1800 days later)
  date_add('2020-01-01', hire_days) as hire_date,
  
  -- Random office location from 8 South African cities
  array('Johannesburg', 'Cape Town', 'Durban', 'Pretoria', 'Port Elizabeth', 'Bloemfontein', 'East London', 'Polokwane')[loc_idx] as location,
  
  -- Employment status: 80% Active, 20% On Leave
  -- Uses threshold on hash value for realistic distribution
  CASE WHEN status_rand < 80 THEN 'Active' ELSE 'On Leave' END as status,
  
  -- Audit timestamp showing when this data was generated
  current_timestamp() as ingestion_timestamp
  
FROM random_data;

-- ==============================================================================
-- END OF BRONZE EMPLOYEES GENERATION
-- ==============================================================================
-- Schema: 
--   employee_id (STRING) - Primary key, format EMP#####
--   first_name (STRING) - Employee first name
--   last_name (STRING) - Employee last name
--   email (STRING) - Company email address
--   department (STRING) - Department assignment
--   job_title (STRING) - Job role
--   salary (DOUBLE) - Annual salary in South African Rand (ZAR)
--   hire_date (DATE) - Date of hire
--   location (STRING) - Office location (South African cities)
--   status (STRING) - Employment status (Active/On Leave)
--   ingestion_timestamp (TIMESTAMP) - When data was generated
--
-- Expected Output: 200 rows with diverse, realistic employee data
--
-- Technical Notes:
--   Uses hash() function with concatenated strings to generate deterministic
--   but varied pseudo-random selections. This ensures consistent data across
--   pipeline runs while providing good distribution across categories.
-- ==============================================================================
