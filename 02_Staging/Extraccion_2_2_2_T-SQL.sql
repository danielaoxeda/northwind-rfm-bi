/*
=====================================================================
 ETAPA 2 - 2.2.2 EXTRACCION  (alternativa T-SQL al paquete SSIS)

 Origen : Northwind.dbo.Customers, Orders, OrderDetails, Products
 Destino: Northwind_Staging.dbo.STG_*

 Copia 1 a 1, sin transformaciones: replica los cuatro conjuntos que
 extraia el paquete SSIS DFT_Extraer_*.

 - Re-ejecutable: vacia las STG_* antes de copiar, sin duplicar filas.
 - Transaccional: si algun conteo no cuadra, revierte todo.
 - No modifica Northwind.

 Requiere: Northwind restaurada y Northwind_Staging creada
           (02_Staging/creacion_BD_Northwind_Staging.sql).
=====================================================================
*/
USE Northwind_Staging;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE dbo.STG_Customers;
    TRUNCATE TABLE dbo.STG_Orders;
    TRUNCATE TABLE dbo.STG_OrderDetails;
    TRUNCATE TABLE dbo.STG_Products;

    INSERT INTO dbo.STG_Customers
        (CustomerID, CompanyName, ContactName, ContactTitle, Address, City,
         Region, PostalCode, Country, Phone, Fax)
    SELECT
        CustomerID, CompanyName, ContactName, ContactTitle, Address, City,
        Region, PostalCode, Country, Phone, Fax
    FROM Northwind.dbo.Customers;

    INSERT INTO dbo.STG_Orders
        (OrderID, CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate,
         ShipVia, Freight, ShipName, ShipAddress, ShipCity, ShipRegion,
         ShipPostalCode, ShipCountry)
    SELECT
        OrderID, CustomerID, EmployeeID, OrderDate, RequiredDate, ShippedDate,
        ShipVia, Freight, ShipName, ShipAddress, ShipCity, ShipRegion,
        ShipPostalCode, ShipCountry
    FROM Northwind.dbo.Orders;

    INSERT INTO dbo.STG_OrderDetails
        (OrderID, ProductID, UnitPrice, Quantity, Discount)
    SELECT OrderID, ProductID, UnitPrice, Quantity, Discount
    FROM Northwind.dbo.OrderDetails;

    INSERT INTO dbo.STG_Products
        (ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit,
         UnitPrice, UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued)
    SELECT
        ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit,
        UnitPrice, UnitsInStock, UnitsOnOrder, ReorderLevel, Discontinued
    FROM Northwind.dbo.Products;

    -- Control de cuadre contra el origen (dentro de la transaccion).
    IF (SELECT COUNT(*) FROM dbo.STG_Customers)
       <> (SELECT COUNT(*) FROM Northwind.dbo.Customers)
    BEGIN
        ;THROW 50001, N'Extraccion de Customers no cuadra con Northwind.', 1;
    END;

    IF (SELECT COUNT(*) FROM dbo.STG_Orders)
       <> (SELECT COUNT(*) FROM Northwind.dbo.Orders)
    BEGIN
        ;THROW 50002, N'Extraccion de Orders no cuadra con Northwind.', 1;
    END;

    IF (SELECT COUNT(*) FROM dbo.STG_OrderDetails)
       <> (SELECT COUNT(*) FROM Northwind.dbo.OrderDetails)
    BEGIN
        ;THROW 50003, N'Extraccion de OrderDetails no cuadra con Northwind.', 1;
    END;

    IF (SELECT COUNT(*) FROM dbo.STG_Products)
       <> (SELECT COUNT(*) FROM Northwind.dbo.Products)
    BEGIN
        ;THROW 50004, N'Extraccion de Products no cuadra con Northwind.', 1;
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;
    THROW;
END CATCH;
GO

/* ------------------------------------------------------------------
   Resumen de la extraccion
   ------------------------------------------------------------------ */
SELECT 'STG_Customers'    AS Tabla, COUNT(*) AS Filas FROM dbo.STG_Customers
UNION ALL SELECT 'STG_Orders',       COUNT(*) FROM dbo.STG_Orders
UNION ALL SELECT 'STG_OrderDetails', COUNT(*) FROM dbo.STG_OrderDetails
UNION ALL SELECT 'STG_Products',     COUNT(*) FROM dbo.STG_Products;

-- Debe devolver 0 filas.
SELECT 'Cuadre de extraccion' AS Control
WHERE (SELECT COUNT(*) FROM dbo.STG_Customers)
        <> (SELECT COUNT(*) FROM Northwind.dbo.Customers)
   OR (SELECT COUNT(*) FROM dbo.STG_Orders)
        <> (SELECT COUNT(*) FROM Northwind.dbo.Orders)
   OR (SELECT COUNT(*) FROM dbo.STG_OrderDetails)
        <> (SELECT COUNT(*) FROM Northwind.dbo.OrderDetails)
   OR (SELECT COUNT(*) FROM dbo.STG_Products)
        <> (SELECT COUNT(*) FROM Northwind.dbo.Products);
GO
