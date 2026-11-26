/*
=====================================================================
 ETAPA 2 - 2.2.3 STAGING AREA
 Crea la base Northwind_Staging y las cuatro tablas espejo de Northwind.

 - Sin claves primarias ni foraneas: la carga replica el origen y la
   validacion se centraliza en la transformacion (2.2.4).
 - Re-ejecutable: si las tablas existen se eliminan y se crean vacias.
   No conserva datos: la extraccion se ejecuta despues.
 - No crea datos ni modifica Northwind.
=====================================================================
*/

IF DB_ID(N'Northwind_Staging') IS NULL
BEGIN
    CREATE DATABASE Northwind_Staging;
END;
GO

USE Northwind_Staging;
GO

-- Se eliminan en cualquier orden porque no hay claves foraneas.
DROP TABLE IF EXISTS dbo.STG_OrderDetails;
DROP TABLE IF EXISTS dbo.STG_Orders;
DROP TABLE IF EXISTS dbo.STG_Products;
DROP TABLE IF EXISTS dbo.STG_Customers;
GO

CREATE TABLE dbo.STG_Customers (
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

CREATE TABLE dbo.STG_Orders (
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

CREATE TABLE dbo.STG_OrderDetails (
    OrderID int,
    ProductID int,
    UnitPrice money,
    Quantity smallint,
    Discount real
);

CREATE TABLE dbo.STG_Products (
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
GO

-- Volumetria esperada tras la extraccion (no valida datos aqui).
SELECT 'STG_Customers' AS Tabla, COUNT(*) AS Filas FROM dbo.STG_Customers
UNION ALL SELECT 'STG_Orders',      COUNT(*) FROM dbo.STG_Orders
UNION ALL SELECT 'STG_OrderDetails', COUNT(*) FROM dbo.STG_OrderDetails
UNION ALL SELECT 'STG_Products',    COUNT(*) FROM dbo.STG_Products;
GO
