-- =============================================================================
-- Online Shopping Database - SQL Server Schema
-- =============================================================================
-- Purpose: E-commerce relational database covering customer, product, and order
-- management with analytical queries for business insights.
-- =============================================================================

-- Configure session language and date format
SET LANGUAGE British;
GO

SELECT CONVERT(VARCHAR, GETDATE(), 103) AS CurrentDate;
-- Date format: dd/mm/yyyy
GO

-- =============================================================================
-- Create Database
-- =============================================================================

CREATE DATABASE OnlineShoppingDB;
GO

USE OnlineShoppingDB;
GO

-- =============================================================================
-- Core Tables
-- =============================================================================

-- Customers table with contact information
CREATE TABLE dbo.Customers (
    customer_id INT PRIMARY KEY,
    name NVARCHAR(100),
    email NVARCHAR(100),
    phone NVARCHAR(50),
    country NVARCHAR(50)
);

-- Products table with pricing and categorization
CREATE TABLE dbo.Products (
    product_id INT PRIMARY KEY,
    product_name NVARCHAR(100),
    category NVARCHAR(50),
    price DECIMAL(10,2)
);

-- Orders table linked to customers
CREATE TABLE dbo.Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date NVARCHAR(10),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Order items table for order line items
CREATE TABLE dbo.Order_items (
    order_item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price_each DECIMAL(10,2),
    Total_price DECIMAL(10,2),
    Total_amount DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Payments table for transaction records
CREATE TABLE dbo.Payments (
    payment_id INT PRIMARY KEY,
    order_id INT,
    payment_date NVARCHAR(10),
    payment_method NVARCHAR(50),
    Amount_paid DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- =============================================================================
-- Add Constraints
-- =============================================================================

ALTER TABLE dbo.Customers ADD CONSTRAINT unique_email UNIQUE (email);
ALTER TABLE dbo.Products ADD CONSTRAINT unique_product_name UNIQUE (product_name);

-- =============================================================================
-- Data Integrity Validation Queries
-- =============================================================================

-- Verify no missing customer IDs in orders
-- SELECT order_id, customer_id FROM dbo.Orders
-- WHERE customer_id NOT IN (SELECT customer_id FROM dbo.Customers);

-- Verify order_id references in order_items
-- SELECT order_id FROM dbo.Order_items
-- WHERE order_id NOT IN (SELECT order_id FROM dbo.Orders);

-- Verify product_id references in order_items
-- SELECT product_id FROM dbo.Order_items
-- WHERE product_id NOT IN (SELECT product_id FROM dbo.Products);

-- Verify no duplicate order_item_id values
-- SELECT order_item_id, COUNT(*)
-- FROM dbo.Order_items
-- GROUP BY order_item_id
-- HAVING COUNT(*) > 1;

-- Verify total_amount consistency within orders
-- SELECT order_id, COUNT(DISTINCT total_amount) AS unique_total_amounts
-- FROM dbo.Order_items
-- GROUP BY order_id
-- HAVING COUNT(DISTINCT total_amount) > 1;

-- Verify total_amount equals sum of total_price per order
-- SELECT order_id, SUM(total_price) AS calculated_total_amount, MAX(total_amount) AS reported_total_amount
-- FROM dbo.Order_items
-- GROUP BY order_id;

-- =============================================================================
-- Analytical Queries
-- =============================================================================

-- Query 1: Customers with orders between 500 and 1000
-- Returns customers who made orders within specified amount range
SELECT
    c.customer_id,
    c.name,
    c.country,
    o.order_id,
    SUM(oi.total_price) AS order_total
FROM dbo.Customers c
JOIN dbo.Orders o ON c.customer_id = o.customer_id
JOIN dbo.Order_items oi ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.name, c.country, o.order_id
HAVING SUM(oi.total_price) BETWEEN 500 AND 1000
ORDER BY order_total ASC;

-- Query 2: Total amount paid by UK customers with >3 products per order
-- Identifies high-volume UK purchases and total revenue generated
WITH UK_Orders_With_MoreThan3Products AS (
    SELECT
        o.order_id,
        o.customer_id,
        SUM(oi.quantity) AS total_products
    FROM Orders o
    JOIN Customers c ON o.customer_id = c.customer_id
    JOIN Order_items oi ON o.order_id = oi.order_id
    WHERE c.country = 'UK'
    GROUP BY o.order_id, o.customer_id
    HAVING SUM(oi.quantity) > 3
),
Deduplicated_Payments AS (
    SELECT
        p.order_id,
        p.Amount_paid,
        ROW_NUMBER() OVER (PARTITION BY p.order_id ORDER BY p.payment_id DESC) AS rn
    FROM Payments p
    WHERE p.Amount_paid > 0
)
SELECT
    c.customer_id,
    c.name AS customer_name,
    c.country,
    uk.order_id,
    uk.total_products,
    dp.Amount_paid
FROM UK_Orders_With_MoreThan3Products uk
JOIN Orders o ON uk.order_id = o.order_id
JOIN Customers c ON uk.customer_id = c.customer_id
JOIN Deduplicated_Payments dp ON uk.order_id = dp.order_id AND dp.rn = 1
ORDER BY dp.Amount_paid DESC;

-- Query 3: Highest and second-highest amounts paid with VAT applied
-- Filters UK and Australia customers, applies 12.2% VAT, and ranks by amount
WITH VAT_Payments AS (
    SELECT
        ROUND(p.Amount_paid * 1.122, 0) AS Amount_with_VAT
    FROM Payments p
    JOIN Orders o ON p.order_id = o.order_id
    JOIN Customers c ON o.customer_id = c.customer_id
    WHERE c.country IN ('UK', 'Australia')
    AND p.Amount_paid > 0
    AND p.payment_id = (
        SELECT MAX(payment_id)
        FROM Payments
        WHERE order_id = p.order_id
    )
),
Ranked_Payments AS (
    SELECT
        Amount_with_VAT,
        DENSE_RANK() OVER (ORDER BY Amount_with_VAT DESC) AS Amount_Rank
    FROM VAT_Payments
)
SELECT
    MAX(CASE WHEN Amount_Rank = 1 THEN Amount_with_VAT ELSE NULL END) AS Highest_Amount,
    MAX(CASE WHEN Amount_Rank = 2 THEN Amount_with_VAT ELSE NULL END) AS Second_Highest
FROM Ranked_Payments;

-- Query 4: Product sales summary
-- Shows each product name and total quantity purchased, sorted by quantity
SELECT
    p.product_name,
    SUM(oi.quantity) AS total_quantity
FROM Products p
JOIN Order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_name
ORDER BY total_quantity;

-- =============================================================================
-- Stored Procedures
-- =============================================================================

-- Procedure to apply 5% discount to Laptop and Smartphone purchases >= 17,000
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'ApplyTechDiscount')
DROP PROCEDURE ApplyTechDiscount;
GO

CREATE PROCEDURE ApplyTechDiscount
AS
BEGIN
    -- Reset all potentially discounted amounts
    UPDATE Payments
    SET Amount_paid = Amount_paid / 0.95
    WHERE order_id IN (
        SELECT DISTINCT o.order_id
        FROM Orders o
        JOIN Order_items oi ON o.order_id = oi.order_id
        JOIN Products p ON oi.product_id = p.product_id
        WHERE p.product_name IN ('Laptop', 'Smartphone')
    )
    AND Amount_paid < (
        SELECT MAX(Amount_paid)
        FROM Payments p2
        WHERE p2.order_id = Payments.order_id
    );

    -- Apply 5% discount to highest payment per qualifying order
    WITH PaymentsToUpdate AS (
        SELECT
            p.payment_id,
            p.order_id,
            p.Amount_paid,
            ROW_NUMBER() OVER (
                PARTITION BY p.order_id
                ORDER BY p.Amount_paid DESC, p.payment_date DESC
            ) AS payment_rank
        FROM Payments p
        JOIN Orders o ON p.order_id = o.order_id
        JOIN Order_items oi ON o.order_id = oi.order_id
        JOIN Products pr ON oi.product_id = pr.product_id
        WHERE pr.product_name IN ('Laptop', 'Smartphone')
        AND p.Amount_paid >= 17000
    )
    UPDATE p
    SET p.Amount_paid = ptu.Amount_paid * 0.95
    FROM Payments p
    JOIN PaymentsToUpdate ptu ON p.payment_id = ptu.payment_id
    WHERE ptu.payment_rank = 1;
END;
GO

-- =============================================================================
-- Advanced Analytical Queries
-- =============================================================================

-- Query 1: Customers who never purchased electronics
-- Identifies customer segments for targeted marketing
SELECT
    c.customer_id,
    c.name,
    c.country
FROM Customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM Orders o
    JOIN Order_items oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_id = p.product_id
    WHERE o.customer_id = c.customer_id
    AND p.category = 'Electronics'
)
ORDER BY c.name;

-- Query 2: Monthly revenue by country (excludes low-revenue months)
-- Shows revenue trends for inventory and resource planning
SELECT
    c.country,
    LEFT(o.order_date, 7) AS Year_Month,
    SUM(p.Amount_paid) AS Revenue
FROM Payments p
JOIN Orders o ON p.order_id = o.order_id
JOIN Customers c ON o.customer_id = c.customer_id
WHERE LEN(o.order_date) = 10
AND o.order_date LIKE '____-__-__'
GROUP BY c.country, LEFT(o.order_date, 7)
HAVING SUM(p.Amount_paid) > 1000
ORDER BY LEFT(o.order_date, 7), c.country;

-- Query 3: Top-selling product categories (>50 units sold)
-- Highlights best-performing and underperforming categories
SELECT
    p.category,
    SUM(oi.quantity) AS Total_Units_Sold,
    SUM(oi.Total_price) AS Revenue
FROM Order_items oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY p.category
HAVING SUM(oi.quantity) > 50
ORDER BY Revenue DESC;

-- Query 4: Orders with multiple payment methods
-- Reveals customer payment preferences and potential UX issues
SELECT
    o.order_id,
    COUNT(DISTINCT p.payment_method) AS Payment_Methods_Used
FROM Orders o
JOIN Payments p ON o.order_id = p.order_id
GROUP BY o.order_id
HAVING COUNT(DISTINCT p.payment_method) > 1
ORDER BY Payment_Methods_Used DESC;

-- Query 5: Customer lifetime value and average order value
-- Ranks customers by profitability for segmentation strategies
SELECT
    c.customer_id,
    c.name,
    SUM(p.Amount_paid) AS Total_Spend,
    COUNT(DISTINCT o.order_id) AS Order_Count,
    SUM(p.Amount_paid) / NULLIF(COUNT(DISTINCT o.order_id), 0) AS Avg_Order_Value
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN Payments p ON o.order_id = p.order_id
GROUP BY c.customer_id, c.name
ORDER BY Total_Spend DESC;
GO
