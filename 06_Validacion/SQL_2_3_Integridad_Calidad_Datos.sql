/*
=====================================================================
 ETAPA 2 - 2.3 INTEGRIDAD Y CALIDAD DE DATOS
 Proyecto : Segmentacion de clientes RFM - Northwind
 Bases    : Northwind (origen), Northwind_Staging, Northwind_DW
 Amplia   : SQL_2_2_6_Validacion_Nicole.sql (conteos, huerfanos, suma total)

 Cada control indica su resultado esperado. Los controles marcados
 "debe devolver 0 filas" no muestran filas si todo esta correcto.
 Si la base de origen en tu servidor no se llama Northwind
 (por ejemplo northwind2024), cambia el nombre en la seccion 2.3.7.
=====================================================================
*/

/* ------------------------------------------------------------------
   2.2.6  Conteos del DW (referencia)
   ------------------------------------------------------------------ */
USE Northwind_DW;
GO
SELECT 'Dim_Cliente' AS Tabla, COUNT(*) AS Total_Registros FROM Dim_Cliente
UNION ALL SELECT 'Dim_Producto',  COUNT(*) FROM Dim_Producto
UNION ALL SELECT 'Dim_Tiempo',    COUNT(*) FROM Dim_Tiempo
UNION ALL SELECT 'Hechos_Ventas', COUNT(*) FROM Hechos_Ventas;
GO

/* ------------------------------------------------------------------
   2.3.2  Integridad referencial   (esperado: 0 en todos los controles)
   ------------------------------------------------------------------ */
-- Claves nulas
SELECT COUNT(*) AS Registros_Huerfanos
FROM Hechos_Ventas
WHERE ID_Cliente IS NULL OR ID_Producto IS NULL OR ID_Tiempo IS NULL;

-- Claves que no existen en la dimension
SELECT 'Sin cliente'  AS Control, COUNT(*) AS Filas
FROM Hechos_Ventas h LEFT JOIN Dim_Cliente  c ON c.ID_Cliente  = h.ID_Cliente  WHERE c.ID_Cliente  IS NULL
UNION ALL
SELECT 'Sin producto', COUNT(*)
FROM Hechos_Ventas h LEFT JOIN Dim_Producto p ON p.ID_Producto = h.ID_Producto WHERE p.ID_Producto IS NULL
UNION ALL
SELECT 'Sin fecha', COUNT(*)
FROM Hechos_Ventas h LEFT JOIN Dim_Tiempo   t ON t.ID_Tiempo   = h.ID_Tiempo   WHERE t.ID_Tiempo   IS NULL;

-- Llaves foraneas existentes y habilitadas (esperado: is_disabled = 0)
SELECT name, OBJECT_NAME(parent_object_id) AS Tabla, is_disabled
FROM sys.foreign_keys;
GO

/* ------------------------------------------------------------------
   2.3.3  Valores nulos   (esperado: 0 en todos los controles)
   ------------------------------------------------------------------ */
SELECT
  SUM(CASE WHEN Cantidad        IS NULL THEN 1 ELSE 0 END) AS Nulos_Cantidad,
  SUM(CASE WHEN Precio_Unitario IS NULL THEN 1 ELSE 0 END) AS Nulos_Precio,
  SUM(CASE WHEN Descuento       IS NULL THEN 1 ELSE 0 END) AS Nulos_Descuento,
  SUM(CASE WHEN Monto_Total     IS NULL THEN 1 ELSE 0 END) AS Nulos_Monto
FROM Hechos_Ventas;

-- Valores por defecto usados en las dimensiones
SELECT 'Nombre = Sin nombre' AS Control, COUNT(*) AS Filas FROM Dim_Cliente  WHERE Nombre_Empresa = N'Sin nombre'
UNION ALL SELECT 'Pais = Desconocido',        COUNT(*) FROM Dim_Cliente  WHERE Pais      = N'Desconocido'
UNION ALL SELECT 'Ciudad = Desconocido',      COUNT(*) FROM Dim_Cliente  WHERE Ciudad    = N'Desconocido'
UNION ALL SELECT 'Categoria = Sin categoria', COUNT(*) FROM Dim_Producto WHERE Categoria = N'Sin categoria';
GO

/* ------------------------------------------------------------------
   2.3.4  Duplicados   (esperado: 0 en todos los controles)
   ------------------------------------------------------------------ */
SELECT 'Hechos (OrderID, ProductID)' AS Control, COUNT(*) AS Duplicados
FROM (SELECT OrderID, ProductID FROM Hechos_Ventas GROUP BY OrderID, ProductID HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'Dim_Cliente', COUNT(*)
FROM (SELECT ID_Cliente_Northwind FROM Dim_Cliente GROUP BY ID_Cliente_Northwind HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'Dim_Producto', COUNT(*)
FROM (SELECT ID_Producto_Northwind FROM Dim_Producto GROUP BY ID_Producto_Northwind HAVING COUNT(*) > 1) x
UNION ALL
SELECT 'Dim_Tiempo', COUNT(*)
FROM (SELECT Fecha_Completa FROM Dim_Tiempo GROUP BY Fecha_Completa HAVING COUNT(*) > 1) x;
GO

/* ------------------------------------------------------------------
   2.3.5  Valores invalidos   (esperado: 0 en los controles)
   ------------------------------------------------------------------ */
SELECT
  SUM(CASE WHEN Cantidad <= 0                 THEN 1 ELSE 0 END) AS Cantidad_No_Positiva,
  SUM(CASE WHEN Precio_Unitario < 0           THEN 1 ELSE 0 END) AS Precio_Negativo,
  SUM(CASE WHEN Descuento NOT BETWEEN 0 AND 1 THEN 1 ELSE 0 END) AS Descuento_Fuera_Rango,
  SUM(CASE WHEN Monto_Total < 0               THEN 1 ELSE 0 END) AS Monto_Negativo
FROM Hechos_Ventas;

-- Rango de fechas (esperado: coherente con Northwind, 1996 a 1998)
SELECT MIN(Fecha_Completa) AS Fecha_Minima, MAX(Fecha_Completa) AS Fecha_Maxima
FROM Dim_Tiempo;
GO

-- Filas rechazadas en la transformacion (esperado: sin filas)
USE Northwind_Staging;
GO
SELECT Tabla_Origen, Motivo, COUNT(*) AS Filas
FROM TRF_Rechazados
GROUP BY Tabla_Origen, Motivo;
GO

/* ------------------------------------------------------------------
   2.3.6  Validacion de calculos   (debe devolver 0 filas)
   ------------------------------------------------------------------ */
USE Northwind_DW;
GO
SELECT ID_Hecho_Venta, OrderID, ProductID, Monto_Total,
       Esperado = CAST(ROUND(Precio_Unitario * Cantidad * (1 - Descuento), 4) AS DECIMAL(19,4))
FROM Hechos_Ventas
WHERE Monto_Total <> CAST(ROUND(Precio_Unitario * Cantidad * (1 - Descuento), 4) AS DECIMAL(19,4));
GO

/* ------------------------------------------------------------------
   2.3.7  Reconciliacion Northwind vs DW
   ------------------------------------------------------------------ */
USE Northwind_DW;
GO
-- a) Conteos y monto total: origen vs DW (las dos filas deben ser iguales)
SELECT 'Northwind' AS Sistema,
       (SELECT COUNT(*) FROM Northwind.dbo.Customers)    AS Clientes,
       (SELECT COUNT(*) FROM Northwind.dbo.Products)     AS Productos,
       (SELECT COUNT(*) FROM Northwind.dbo.OrderDetails) AS Lineas,
       (SELECT SUM(CAST(UnitPrice AS DECIMAL(19,4)) * Quantity * (1 - CAST(Discount AS DECIMAL(9,6))))
        FROM Northwind.dbo.OrderDetails)                 AS Monto_Total
UNION ALL
SELECT 'Northwind_DW',
       (SELECT COUNT(*) FROM Northwind_DW.dbo.Dim_Cliente),
       (SELECT COUNT(*) FROM Northwind_DW.dbo.Dim_Producto),
       (SELECT COUNT(*) FROM Northwind_DW.dbo.Hechos_Ventas),
       (SELECT SUM(Monto_Total) FROM Northwind_DW.dbo.Hechos_Ventas);

-- b) Monto y frecuencia por cliente: debe devolver 0 filas
WITH Origen AS (
  SELECT UPPER(LTRIM(RTRIM(o.CustomerID))) AS Cliente,
         COUNT(DISTINCT o.OrderID) AS Pedidos,
         SUM(CAST(d.UnitPrice AS DECIMAL(19,4)) * d.Quantity * (1 - CAST(d.Discount AS DECIMAL(9,6)))) AS Monto
  FROM Northwind.dbo.Orders o
  JOIN Northwind.dbo.OrderDetails d ON d.OrderID = o.OrderID
  GROUP BY UPPER(LTRIM(RTRIM(o.CustomerID)))
),
Destino AS (
  SELECT LTRIM(RTRIM(c.ID_Cliente_Northwind)) AS Cliente,
         COUNT(DISTINCT h.OrderID) AS Pedidos,
         SUM(h.Monto_Total) AS Monto
  FROM Northwind_DW.dbo.Hechos_Ventas h
  JOIN Northwind_DW.dbo.Dim_Cliente c ON c.ID_Cliente = h.ID_Cliente
  GROUP BY LTRIM(RTRIM(c.ID_Cliente_Northwind))
)
SELECT o.Cliente, o.Pedidos AS Ped_Origen, d.Pedidos AS Ped_DW,
       ROUND(o.Monto, 2) AS Monto_Origen, ROUND(d.Monto, 2) AS Monto_DW
FROM Origen o
FULL JOIN Destino d ON d.Cliente = o.Cliente
WHERE d.Cliente IS NULL OR o.Cliente IS NULL
   OR o.Pedidos <> d.Pedidos
   OR ABS(o.Monto - d.Monto) > 0.01;
GO
