# SAP Eco-tax Textile Query

## Overview
This SQL query extracts and processes delivery and supplier data for textiles subject to eco-tax regulations in the Netherlands. It integrates multiple SAP tables and external reference files to provide insights into sales, supplier origins, and product classifications.

## Key Features
- **Common Table Expressions (CTEs):**
  - `Data_t`: Extracts relevant delivery items within a specified period.
  - `likp`: Joins outbound deliveries with their respective sales organization.
  - `vbpa`: Filters deliveries based on the customer’s country.
  - `md_file`: Adds clarifying information about customer countries.
  - `nl_textile`: Loads eco-tax-related textile product data.
- **Joins & Transformations:**
  - Matches deliveries with country data for accurate reporting.
  - Cleans product codes (`matnr_trm`) and assigns standardized categories.
  - Extracts HS codes and calculates weight per unit.
- **Filtering & Business Rules:**
  - Includes deliveries to the Netherlands (`cus_cntry = 'NL'`).
  - Categorizes delivery types and sales organizations.
  - Assigns EPR (Extended Producer Responsibility) classifications.

## How It Works
1. Retrieves delivery data from SAP (`lips`) based on warehouse and sales division filters.
2. Joins with `likp`, `vbpa`, and `md_file` to add contextual information (sales org, customer country, etc.).
3. Enriches with `nl_textile` data to classify textiles based on eco-tax applicability.
4. Outputs a structured dataset with key metrics like product categories, weights, and HS codes.

## Use Cases
- **Eco-Tax Compliance:** Ensuring textile sales in the Netherlands comply with environmental regulations.
- **Supplier & Customer Analysis:** Understanding product origins and sales distribution.
- **Product Classification:** Matching SKUs with HS codes and EPR subjection categories.
- **Financial & Operational Reporting:** Tracking sales volume, weight, and supply chain data for better decision-making.

## Technologies Used
- SQL (BigQuery or similar syntax)
- SAP Data Extraction (Tables: `lips`, `likp`, `vbpa`, `eina`, `lfa1`)
- External Data Sources (`excel_sheet.stg_sheet_countrycodes`, `excel_sheet.stg_sheet_textile_NL`)

## Contribution
Potential improvements include:
- Expanding coverage for other EU countries.
- Enhancing supplier classification logic.
- Optimizing query performance by refining joins and indexes.
