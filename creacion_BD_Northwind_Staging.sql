CREATE DATABASE Northwind_Staging;
GO
USE Northwind_Staging;
GO

CREATE TABLE STG_Customers (
    CustomerID nchar(10),
    CompanyName nvarchar(80),
    ContactName nvarchar(60),
    ContactTitle nvarchar(60),
    Address nvarchar(120),
    City nvarchar(30),
    Region nvarchar(30),
    PostalCode nvarchar(20),
    Country nvarchar(30),
    Phone nvarchar(48),
    Fax nvarchar(48)
);

CREATE TABLE STG_Orders (
    OrderID int,
    CustomerID nchar(10),
    EmployeeID int,
    OrderDate datetime,
    RequiredDate datetime,
    ShippedDate datetime,
    ShipVia int,
    Freight money,
    ShipName nvarchar(80),
    ShipAddress nvarchar(120),
    ShipCity nvarchar(30),
    ShipRegion nvarchar(30),
    ShipPostalCode nvarchar(20),
    ShipCountry nvarchar(30)
);

CREATE TABLE STG_OrderDetails (
    OrderID int,
    ProductID int,
    UnitPrice money,
    Quantity smallint,
    Discount real
);

CREATE TABLE STG_Products (
    ProductID int,
    ProductName nvarchar(80),
    SupplierID int,
    CategoryID int,
    QuantityPerUnit nvarchar(40),
    UnitPrice money,
    UnitsInStock smallint,
    UnitsOnOrder smallint,
    ReorderLevel smallint,
    Discontinued bit
);