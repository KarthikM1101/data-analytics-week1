-- create database and select it
CREATE DATABASE Internship;
USE Internship;
SHOW DATABASES;
-- customers table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(50),
    City VARCHAR(50)
);
SHOW TABLES;
-- insert customer data
INSERT INTO Customers
(CustomerID, CustomerName, City)
VALUES
(1, 'Ravi', 'Hyderabad'),
(2, 'Kiran', 'Bangalore'),
(3, 'Arun', 'Chennai'),
(4, 'Priya', 'Hyderabad'),
(5, 'Suresh', 'Bangalore');
SELECT * FROM Customers;

-- products table
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2)
);

-- insert product data
INSERT INTO Products
(ProductID, ProductName, Price)
VALUES
(101, 'Laptop', 50000),
(102, 'Mobile', 20000),
(103, 'Mouse', 500),
(104, 'Keyboard', 1500),
(105, 'Monitor', 12000);

SELECT * FROM Products;
SHOW TABLES;

-- orders table with foreign keys
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    CustomerID INT,
    ProductID INT,
    Quantity INT,
    OrderDate DATE,

    FOREIGN KEY (CustomerID)
        REFERENCES Customers(CustomerID),

    FOREIGN KEY (ProductID)
        REFERENCES Products(ProductID)
);

-- insert order data
INSERT INTO Orders
(OrderID, CustomerID, ProductID, Quantity, OrderDate)
VALUES
(1, 1, 101, 1, '2026-11-01'),
(2, 2, 102, 2, '2026-11-02'),
(3, 3, 103, 3, '2026-11-03'),
(4, 1, 104, 2, '2026-11-04'),
(5, 4, 101, 1, '2026-11-05'),
(6, 5, 105, 2, '2026-11-06'),
(7, 2, 104, 1, '2026-11-07'),
(8, 3, 102, 1, '2026-11-08');
SELECT * FROM Orders;
SHOW TABLES;
-- join all 3 tables: customer, product, quantity
SELECT
    Customers.CustomerName,
    Products.ProductName,
    Orders.Quantity
FROM Orders
INNER JOIN Customers
ON Orders.CustomerID = Customers.CustomerID
INNER JOIN Products
ON Orders.ProductID = Products.ProductID;

-- revenue for each order (price * quantity)
SELECT
    Products.ProductName,
    Products.Price,
    Orders.Quantity,
    Products.Price * Orders.Quantity AS Revenue
FROM Orders
INNER JOIN Products
ON Orders.ProductID = Products.ProductID;
-- total revenue
SELECT
    SUM(Products.Price * Orders.Quantity)
    AS TotalRevenue
FROM Orders
INNER JOIN Products
ON Orders.ProductID = Products.ProductID;
-- aggregate functions
SELECT COUNT(*) FROM Orders;

SELECT SUM(Price) FROM Products;

SELECT AVG(Price) FROM Products;

SELECT MAX(Price) FROM Products;

SELECT MIN(Price) FROM Products;

-- quantity and revenue per product, highest first
SELECT
    Products.ProductName,
    SUM(Orders.Quantity) AS TotalQuantity,
    SUM(Products.Price * Orders.Quantity) AS TotalRevenue
FROM Orders
INNER JOIN Products
ON Orders.ProductID = Products.ProductID
GROUP BY Products.ProductID, Products.ProductName
ORDER BY TotalRevenue DESC;

-- same as above, only products with revenue > 10000 (HAVING)
SELECT
    Products.ProductName,
    SUM(Orders.Quantity) AS TotalQuantity,
    SUM(Products.Price * Orders.Quantity) AS TotalRevenue

FROM Orders

INNER JOIN Products
ON Orders.ProductID = Products.ProductID

GROUP BY
    Products.ProductID,
    Products.ProductName

HAVING SUM(Products.Price * Orders.Quantity) > 10000

ORDER BY TotalRevenue DESC;


-- subquery: products costlier than average price
SELECT *
FROM Products
WHERE Price > (
    SELECT AVG(Price)
    FROM Products
);
-- checking the average price
SELECT AVG(Price)
FROM Products;
-- same query with average value typed directly
SELECT *
FROM Products
WHERE Price > 16800;

-- products cheaper than average price
SELECT *
FROM Products
WHERE Price < (
    SELECT AVG(Price)
    FROM Products
);

-- ROW_NUMBER
SELECT
    ProductName,
    Price,
    ROW_NUMBER() OVER (
        ORDER BY Price DESC
    ) AS ProductRank
FROM Products;

-- RANK
SELECT
    ProductName,
    Price,
    RANK() OVER (
        ORDER BY Price DESC
    ) AS ProductRank
FROM Products;

-- DENSE_RANK
SELECT
    ProductName,
    Price,
    DENSE_RANK() OVER (
        ORDER BY Price DESC
    ) AS ProductRank
FROM Products;

-- order number for each customer (PARTITION BY)
SELECT
    Customers.CustomerName,
    Orders.OrderID,
    Orders.OrderDate,

    ROW_NUMBER() OVER (
        PARTITION BY Orders.CustomerID
        ORDER BY Orders.OrderDate, Orders.OrderID
    ) AS OrderNumber

FROM Orders

INNER JOIN Customers
ON Orders.CustomerID = Customers.CustomerID;

-- total quantity per customer on every row
SELECT
    Customers.CustomerName,
    Orders.OrderID,
    Orders.Quantity,

    SUM(Orders.Quantity) OVER (
        PARTITION BY Orders.CustomerID
    ) AS CustomerTotalQuantity

FROM Orders

INNER JOIN Customers
ON Orders.CustomerID = Customers.CustomerID;

-- running total of revenue by date
SELECT
    Orders.OrderID,
    Customers.CustomerName,
    Orders.OrderDate,
    Products.ProductName,
    Orders.Quantity,

    (Products.Price * Orders.Quantity) AS OrderRevenue,

    SUM(Products.Price * Orders.Quantity) OVER (
        ORDER BY Orders.OrderDate, Orders.OrderID
        ROWS BETWEEN UNBOUNDED PRECEDING
        AND CURRENT ROW
    ) AS RunningTotalRevenue

FROM Orders

INNER JOIN Customers
ON Orders.CustomerID = Customers.CustomerID

INNER JOIN Products
ON Orders.ProductID = Products.ProductID;

-- orders and revenue for each customer
SELECT
    Customers.CustomerName,

    COUNT(Orders.OrderID) AS TotalOrders,

    SUM(Products.Price * Orders.Quantity)
        AS TotalRevenue

FROM Orders

INNER JOIN Customers
ON Orders.CustomerID = Customers.CustomerID

INNER JOIN Products
ON Orders.ProductID = Products.ProductID

GROUP BY Customers.CustomerName

ORDER BY TotalRevenue DESC;
-- CTE: customer revenue first, then rank customers
WITH CustomerSales AS (
    SELECT
        Customers.CustomerName,
        SUM(Products.Price * Orders.Quantity) AS TotalRevenue
    FROM Customers
    INNER JOIN Orders
        ON Customers.CustomerID = Orders.CustomerID
    INNER JOIN Products
        ON Orders.ProductID = Products.ProductID
    GROUP BY Customers.CustomerName
)

SELECT
    CustomerName,
    TotalRevenue,
    DENSE_RANK() OVER (
        ORDER BY TotalRevenue DESC
    ) AS RevenueRank
FROM CustomerSales;
-- overall summary: orders, quantity, revenue, avg order value
SELECT
    COUNT(DISTINCT Orders.OrderID) AS TotalOrders,

    SUM(Orders.Quantity) AS TotalQuantity,

    SUM(Products.Price * Orders.Quantity)
        AS TotalRevenue,

    ROUND(
        SUM(Products.Price * Orders.Quantity) /
        COUNT(DISTINCT Orders.OrderID), 2
    ) AS AverageOrderValue

FROM Orders
INNER JOIN Products
ON Orders.ProductID = Products.ProductID;
-- product-wise sales with rank by revenue
SELECT
    Products.ProductName,
    SUM(Orders.Quantity) AS TotalQuantity,
    SUM(Products.Price * Orders.Quantity) AS TotalRevenue,
    DENSE_RANK() OVER (
        ORDER BY SUM(Products.Price * Orders.Quantity) DESC
    ) AS ProductRank
FROM Orders
INNER JOIN Products
    ON Orders.ProductID = Products.ProductID
GROUP BY Products.ProductID, Products.ProductName
ORDER BY ProductRank;