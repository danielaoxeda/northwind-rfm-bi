USE Northwind_DW;
SELECT 'Dim_Cliente' AS Tabla, COUNT(*) AS Total_Registros FROM Dim_Cliente
UNION ALL SELECT 'Dim_Producto', COUNT(*) FROM Dim_Producto
UNION ALL SELECT 'Dim_Tiempo', COUNT(*) FROM Dim_Tiempo
UNION ALL SELECT 'Hechos_Ventas', COUNT(*) FROM Hechos_Ventas;

USE Northwind_DW;

-- 1. Verificar que no haya ventas sin cliente, producto o fecha
SELECT COUNT(*) AS Registros_Huerfanos 
FROM Hechos_Ventas 
WHERE ID_Cliente IS NULL OR ID_Producto IS NULL OR ID_Tiempo IS NULL;

-- 2. Verificar que la suma total de ventas coincida
SELECT SUM(Monto_Total) AS Gran_Total_Ventas 
FROM Hechos_Ventas;