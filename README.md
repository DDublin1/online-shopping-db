# Online Shopping Database

A comprehensive e-commerce relational database system built in SQL Server for managing customers, products, orders, and payments with advanced analytical queries for business intelligence.

## Overview

This database system provides a complete solution for online shopping operations, from customer management through order fulfillment and payment processing. It includes sophisticated analytical capabilities for revenue analysis, customer segmentation, and product performance tracking.

### Key Features

- **Customer Management**: Comprehensive customer profiles with multi-country support
- **Product Catalog**: Product management with categorization and pricing
- **Order Management**: Complete order lifecycle from placement to payment
- **Payment Processing**: Multi-method payment tracking and reconciliation
- **Data Integrity Validation**: Built-in verification queries for data consistency
- **Advanced Analytics**: Pre-built queries for business intelligence
- **Revenue Analysis**: Monthly and country-level revenue reporting
- **Customer Segmentation**: Lifetime value analysis and purchase pattern identification
- **Discount Management**: Automated promotion application for tech products

## Schema

The database consists of 5 core tables:

- **Customers**: Customer information including contact details and location
- **Products**: Product catalog with categories and pricing
- **Orders**: Order records linked to customers
- **Order_items**: Line items for each order with quantity and pricing
- **Payments**: Payment transactions with method tracking

## Setup

### Prerequisites

- SQL Server 2016 or later
- SQL Server Management Studio (SSMS) or equivalent T-SQL client
- Data import capability (the schema expects pre-populated data)

### Installation

1. Connect to your SQL Server instance
2. Run the schema.sql file to create the database and all tables
3. Import data from your source using SQL Server import tools
4. Verify data integrity using the included validation queries

```sql
-- Execute in SQL Server Management Studio
USE OnlineShoppingDB;
GO
```

### Configuration

The system uses British English date format (dd/mm/yyyy):

```sql
SET LANGUAGE British;
SELECT CONVERT(VARCHAR, GETDATE(), 103); -- Returns: dd/mm/yyyy
```

## Features

### Analytical Queries

#### Query 1: Customer Order Analysis (500-1000 Range)
Returns customers who placed orders within a specific amount range, useful for targeting mid-tier customers.

#### Query 2: UK Customer High-Volume Analysis
Identifies UK customers with high-quantity orders (>3 products) and calculates their total spending with deduplication.

#### Query 3: International Payment Analysis with VAT
Analyzes top payments from UK and Australian customers with 12.2% VAT applied, identifying highest and second-highest transactions.

#### Query 4: Product Sales Summary
Lists all products with their total quantity sold, sorted by volume to identify best and worst sellers.

#### Query 5: Advanced Business Intelligence

**Electronics Purchase Analysis**: Identifies customer segments who have never purchased electronics for targeted marketing.

**Monthly Revenue by Country**: Tracks revenue trends by country and month, filtering low-revenue periods for focus areas.

**Category Performance**: Highlights product categories with strong sales (>50 units) and their revenue contribution.

**Multi-Method Payments**: Identifies orders split across multiple payment methods to understand customer behavior patterns.

**Customer Lifetime Value**: Ranks customers by total spending and calculates average order value with division-by-zero protection.

### Stored Procedures

- **ApplyTechDiscount**: Applies 5% discount to Laptop and Smartphone purchases exceeding 17,000

## Data Validation

The schema includes comprehensive validation queries:

- Missing customer ID verification
- Foreign key constraint checking
- Duplicate detection in order items
- Total amount consistency verification
- Cross-table reference validation
- Data format validation for dates

## Queries and Analytics

All queries follow best practices:

- Use DISTINCT and deduplication techniques to avoid inflated totals
- Implement window functions for ranking and ordering
- Apply NULLIF protection for division operations
- Use CTEs for complex multi-step analysis
- Include filtering for data quality (e.g., excluding zero-value payments)

## Technology

- **Database**: SQL Server 2016+
- **Language**: T-SQL
- **Date Format**: British (dd/mm/yyyy)
- **Constraints**: Unique constraints, foreign keys, referential integrity
- **Advanced Features**: CTEs, window functions, stored procedures

## Data Requirements

The system expects data with:

- Customer IDs, names, emails, phone numbers, and countries
- Product IDs, names, categories, and prices
- Order IDs, customer references, and order dates (in dd/mm/yyyy or YYYY-MM-DD format)
- Order line items with quantities and pricing
- Payment records with methods and amounts

## Key Insights Enabled

- **Customer Segmentation**: Identify high-value, medium-value, and low-value customers
- **Product Performance**: Track which categories and products drive revenue
- **Geographic Trends**: Understand revenue by country and seasonal patterns
- **Payment Methods**: Analyze customer payment preferences and multi-method usage
- **Promotional Effectiveness**: Measure impact of discount strategies on tech products

## Notes

- Date format is configurable; adjust SET LANGUAGE and CONVERT as needed
- All sample data should be replaced with actual business data
- Discount procedures should be tested with production data before deployment
- VAT rate (12.2%) is configurable; adjust as needed for your jurisdiction
- Zero-value payments are excluded from analysis queries; review handling if needed

## License

This project is provided as-is for professional use.
