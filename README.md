# HR-Data_pipeline-with-sample-data

Project Summary

HR Data Pipeline - Databricks Lakeflow
This is a end-to-end HR analytics data pipeline using Databricks Lakeflow Spark Declarative Pipelines with medallion architecture (Bronze/Silver/Gold layers). The pipeline processes employee data including demographics, compensation, and employment history for 200+ records.

Key Technical Components:
•	Built serverless data pipeline with Photon engine optimization for high-performance processing
•	Implemented continuous streaming mode for real-time data updates
•	Integrated with Unity Catalog (workspace catalog, default schema) for data governance
•	Created bronze layer materialized views with automated data quality tracking
•	Generated comprehensive employee dataset with 10+ attributes including employee IDs, contact information, department assignments, job titles, salary data, hire dates, locations, and employment status
•	Utilized SQL-based transformations with declarative pipeline syntax
Technologies: Databricks, Spark Declarative Pipelines (SDP), SQL, Unity Catalog, Photon Engine, Serverless Compute

This is an automated ETL pipeline for Human resources fully written using SQL. using the medallion architecture.

Dashboard link:
https://dbc-ca9bcb57-4aa3.cloud.databricks.com/dashboardsv3/01f1470c41001d07982e57673249bc0b/published?o=7474656912461022&f_0dbd3d64%7Esalary_distribution_chart=%257B%2522columns%2522%253A%255B%2522x%2522%252C%2522y%2522%255D%252C%2522rows%2522%253A%255B%255B%2522Mid%2520Level%2520%28R400k-R700k%29%2522%252C%252251%2522%255D%255D%257D
