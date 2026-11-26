/*
=====================================================================
 ETAPA 2 - 2.2.5 CARGA DE HECHOS  (alternativa T-SQL a SSIS)

 Origen : Northwind_Staging.dbo.TRF_Ventas
 Destino: Northwind_DW.dbo.Hechos_Ventas

 - Grano: una fila por (OrderID, ProductID).
 - Cruza las claves naturales contra las dimensiones para obtener las
   claves subrogadas (ID_Cliente, ID_Producto) y la clave AAAAMMDD de
   tiempo (ID_Tiempo).
 - Re-ejecutable: actualiza las filas existentes, inserta las nuevas y
   elimina las que ya no existen en el origen. No duplica.
 - Transaccional: si los controles no cuadran, revierte todo.

 Requiere: dimensiones cargadas (02_Carga_Dimensiones.sql).
=====================================================================
*/
USE Northwind_DW;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM Northwind_Staging.dbo.TRF_Ventas)
    BEGIN
        ;THROW 50110, N'TRF_Ventas esta vacia: ejecute primero la transformacion 2.2.4.', 1;
    END;

    -- 1. Eliminar hechos que ya no existen en el staging.
    DELETE h
    FROM dbo.Hechos_Ventas AS h
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM Northwind_Staging.dbo.TRF_Ventas AS v
        WHERE v.OrderID   = h.OrderID
          AND v.ProductID = h.ProductID
    );

    -- 2. Actualizar hechos existentes (mismas claves naturales).
    UPDATE h
    SET h.ID_Tiempo       = t.ID_Tiempo,
        h.ID_Cliente      = c.ID_Cliente,
        h.ID_Producto     = p.ID_Producto,
        h.Cantidad        = v.Cantidad,
        h.Precio_Unitario = v.Precio_Unitario,
        h.Descuento       = v.Descuento,
        h.Monto_Total     = v.TotalVenta
    FROM dbo.Hechos_Ventas AS h
    INNER JOIN Northwind_Staging.dbo.TRF_Ventas AS v
        ON v.OrderID = h.OrderID AND v.ProductID = h.ProductID
    INNER JOIN dbo.Dim_Tiempo AS t
        ON t.Fecha_Completa = v.Fecha
    INNER JOIN dbo.Dim_Cliente AS c
        ON c.ID_Cliente_Northwind = v.CustomerID
    INNER JOIN dbo.Dim_Producto AS p
        ON p.ID_Producto_Northwind = v.ProductID;

    -- 3. Insertar hechos nuevos.
    INSERT INTO dbo.Hechos_Ventas
        (ID_Tiempo, ID_Cliente, ID_Producto, OrderID, ProductID,
         Cantidad, Precio_Unitario, Descuento, Monto_Total)
    SELECT
        t.ID_Tiempo,
        c.ID_Cliente,
        p.ID_Producto,
        v.OrderID,
        v.ProductID,
        v.Cantidad,
        v.Precio_Unitario,
        v.Descuento,
        v.TotalVenta
    FROM Northwind_Staging.dbo.TRF_Ventas AS v
    INNER JOIN dbo.Dim_Tiempo AS t
        ON t.Fecha_Completa = v.Fecha
    INNER JOIN dbo.Dim_Cliente AS c
        ON c.ID_Cliente_Northwind = v.CustomerID
    INNER JOIN dbo.Dim_Producto AS p
        ON p.ID_Producto_Northwind = v.ProductID
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Hechos_Ventas AS h
        WHERE h.OrderID = v.OrderID AND h.ProductID = v.ProductID
    );

    /* ------------------------------------------------------------------
       4. Controles dentro de la transaccion
       ------------------------------------------------------------------ */
    IF (SELECT COUNT(*) FROM dbo.Hechos_Ventas)
       <> (SELECT COUNT(*) FROM Northwind_Staging.dbo.TRF_Ventas)
    BEGIN
        ;THROW 50111, N'El numero de hechos no coincide con TRF_Ventas.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Hechos_Ventas
        WHERE ID_Tiempo IS NULL OR ID_Cliente IS NULL OR ID_Producto IS NULL
    )
    BEGIN
        ;THROW 50112, N'Hay hechos con claves de dimension nulas.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM dbo.Hechos_Ventas AS h
        LEFT JOIN dbo.Dim_Cliente AS c  ON c.ID_Cliente  = h.ID_Cliente
        LEFT JOIN dbo.Dim_Producto AS p ON p.ID_Producto = h.ID_Producto
        LEFT JOIN dbo.Dim_Tiempo AS t   ON t.ID_Tiempo   = h.ID_Tiempo
        WHERE c.ID_Cliente IS NULL OR p.ID_Producto IS NULL OR t.ID_Tiempo IS NULL
    )
    BEGIN
        ;THROW 50113, N'Hay hechos con claves que no existen en las dimensiones.', 1;
    END;

    IF ABS
    (
        (SELECT SUM(TotalVenta) FROM Northwind_Staging.dbo.TRF_Ventas)
        - (SELECT SUM(Monto_Total) FROM dbo.Hechos_Ventas)
    ) > 0.0001
    BEGIN
        ;THROW 50114, N'El monto total de hechos no coincide con TRF_Ventas.', 1;
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
   Resumen de hechos
   ------------------------------------------------------------------ */
SELECT COUNT(*) AS Hechos,
       COUNT(DISTINCT OrderID) AS Pedidos_Distintos,
       SUM(Monto_Total) AS Monto_Total
FROM dbo.Hechos_Ventas;

-- Debe devolver 0 filas.
SELECT 'Cuadre de hechos' AS Control
WHERE (SELECT COUNT(*) FROM dbo.Hechos_Ventas)
        <> (SELECT COUNT(*) FROM Northwind_Staging.dbo.TRF_Ventas)
   OR ABS((SELECT SUM(TotalVenta) FROM Northwind_Staging.dbo.TRF_Ventas)
        - (SELECT SUM(Monto_Total) FROM dbo.Hechos_Ventas)) > 0.0001;
GO
