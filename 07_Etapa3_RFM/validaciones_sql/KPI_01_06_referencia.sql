/*
Fase 7 - SQL equivalente de KPI 1 a 6.
Solo lectura; SQL Server Northwind_DW.
*/
USE Northwind_DW;
GO

/* KPI 1: activo = compra dentro de 60 días inclusivos del corte */
DECLARE @Corte DATE = '1998-05-07';
;WITH Ultima AS
(
    SELECT c.ID_Cliente, MAX(t.Fecha_Completa) AS Ultima
    FROM dbo.Dim_Cliente c
    LEFT JOIN dbo.Hechos_Ventas h ON h.ID_Cliente = c.ID_Cliente
    LEFT JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo = h.ID_Tiempo
    WHERE t.Fecha_Completa < @Corte OR t.Fecha_Completa IS NULL
    GROUP BY c.ID_Cliente
)
SELECT COUNT(*) AS Clientes_Con_Compras,
       SUM(CASE WHEN DATEDIFF(DAY, Ultima, @Corte) <= 60 THEN 1 ELSE 0 END) AS Activos_60d,
       CAST(AVG(CASE WHEN DATEDIFF(DAY, Ultima, @Corte) <= 60
                     THEN DATEDIFF(DAY, Ultima, @Corte) * 1.0 END) AS DECIMAL(10,2)) AS Recencia_Promedio_Activos
FROM Ultima WHERE Ultima IS NOT NULL;
GO

/* KPI 2: Q1 completo 1998 vs Q1 completo 1997, clientes con >=3 pedidos */
;WITH Periodos AS
(
    SELECT 'Q1_1997' AS Periodo, ID_Cliente, COUNT(DISTINCT OrderID) AS Pedidos
    FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
    WHERE t.Fecha_Completa BETWEEN '1997-01-01' AND '1997-03-31'
    GROUP BY ID_Cliente
    UNION ALL
    SELECT 'Q1_1998', ID_Cliente, COUNT(DISTINCT OrderID)
    FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
    WHERE t.Fecha_Completa BETWEEN '1998-01-01' AND '1998-03-31'
    GROUP BY ID_Cliente
)
SELECT Periodo, COUNT(CASE WHEN Pedidos >= 3 THEN 1 END) AS Clientes_3mas_Pedidos,
       SUM(Pedidos) AS Pedidos
FROM Periodos GROUP BY Periodo ORDER BY Periodo;
GO

/* KPI 3: dos ventanas completas de 300 días Jul 11-May 6.
   Cohorte: clientes actualmente Frecuentes por la regla RFM aprobada. */
;WITH Actual AS
(
 SELECT h.ID_Cliente,
        DATEDIFF(DAY,MAX(t.Fecha_Completa),'1998-05-07') R,
        COUNT(DISTINCT h.OrderID) F, SUM(h.Monto_Total) M
 FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
 WHERE t.Fecha_Completa<'1998-05-07' GROUP BY h.ID_Cliente
), S AS
(
 SELECT *, CASE WHEN R<=8 THEN 5 WHEN R<=16 THEN 4 WHEN R<=31 THEN 3 WHEN R<=70 THEN 2 ELSE 1 END SR,
        CASE WHEN F<=5 THEN 1 WHEN F<=7 THEN 2 WHEN F<=10 THEN 3 WHEN F<=13 THEN 4 ELSE 5 END SF,
        CASE WHEN M<3000 THEN 1 WHEN M<5200 THEN 2 WHEN M<11500 THEN 3 WHEN M<20000 THEN 4 ELSE 5 END SM
 FROM Actual
), Frecuentes AS
(
 SELECT ID_Cliente FROM S
 WHERE NOT(SR>=4 AND SF>=4 AND SM>=4) AND R>60 AND SF>=3
)
SELECT 'Previo_1996-07-11_a_1997-05-06' AS Periodo,
       SUM(h.Monto_Total) AS Monto_USD, COUNT(DISTINCT h.OrderID) AS Pedidos
FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
JOIN Frecuentes f ON f.ID_Cliente=h.ID_Cliente
WHERE t.Fecha_Completa BETWEEN '1996-07-11' AND '1997-05-06'
UNION ALL
SELECT 'Reciente_1997-07-11_a_1998-05-06',
       SUM(h.Monto_Total), COUNT(DISTINCT h.OrderID)
FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
JOIN Frecuentes f ON f.ID_Cliente=h.ID_Cliente
WHERE t.Fecha_Completa BETWEEN '1997-07-11' AND '1998-05-06';
GO

/* KPI 4: ticket promedio y nueva meta USD 500 (no conversión de soles) */
SELECT SUM(Monto_Total) AS Monto_USD, COUNT(DISTINCT OrderID) AS Pedidos,
       SUM(Monto_Total)/NULLIF(COUNT(DISTINCT OrderID),0) AS Ticket_USD,
       CAST(500 AS DECIMAL(19,4)) AS Meta_USD,
       CASE WHEN SUM(Monto_Total)/NULLIF(COUNT(DISTINCT OrderID),0) >= 500 THEN 1 ELSE 0 END AS Cumple
FROM dbo.Hechos_Ventas;
GO

/* KPI 5: segmentos al corte y %VIP sobre clientes con compras.
   Reglas consolidadas: VIP>Activo/Ocasional>Riesgo>Frecuente>Inactivo. */
DECLARE @Corte5 DATE='1998-05-07';
;WITH B AS
(
 SELECT h.ID_Cliente, DATEDIFF(DAY,MAX(t.Fecha_Completa),@Corte5) R,
        COUNT(DISTINCT h.OrderID) F, SUM(h.Monto_Total) M
 FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
 WHERE t.Fecha_Completa<@Corte5 GROUP BY h.ID_Cliente
), S AS
(
 SELECT *, CASE WHEN R<=8 THEN 5 WHEN R<=16 THEN 4 WHEN R<=31 THEN 3 WHEN R<=70 THEN 2 ELSE 1 END SR,
        CASE WHEN F<=5 THEN 1 WHEN F<=7 THEN 2 WHEN F<=10 THEN 3 WHEN F<=13 THEN 4 ELSE 5 END SF,
        CASE WHEN M<3000 THEN 1 WHEN M<5200 THEN 2 WHEN M<11500 THEN 3 WHEN M<20000 THEN 4 ELSE 5 END SM
 FROM B
), C AS
(
 SELECT *, CASE WHEN SR>=4 AND SF>=4 AND SM>=4 THEN 'VIP'
                WHEN R<=60 AND SF<=2 AND SM<=2 THEN 'Ocasional'
                WHEN R<=60 THEN 'Activo'
                WHEN SF>=4 OR SM>=4 THEN 'En riesgo'
                WHEN SF>=3 THEN 'Frecuente' ELSE 'Inactivo' END Segmento
 FROM S
)
SELECT Segmento, COUNT(*) AS Clientes FROM C GROUP BY Segmento;
;WITH B AS
(
 SELECT h.ID_Cliente, DATEDIFF(DAY,MAX(t.Fecha_Completa),@Corte5) R,
        COUNT(DISTINCT h.OrderID) F, SUM(h.Monto_Total) M
 FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
 WHERE t.Fecha_Completa<@Corte5 GROUP BY h.ID_Cliente
), S AS
(
 SELECT *, CASE WHEN R<=8 THEN 5 WHEN R<=16 THEN 4 WHEN R<=31 THEN 3 WHEN R<=70 THEN 2 ELSE 1 END SR,
        CASE WHEN F<=5 THEN 1 WHEN F<=7 THEN 2 WHEN F<=10 THEN 3 WHEN F<=13 THEN 4 ELSE 5 END SF,
        CASE WHEN M<3000 THEN 1 WHEN M<5200 THEN 2 WHEN M<11500 THEN 3 WHEN M<20000 THEN 4 ELSE 5 END SM
 FROM B
)
SELECT SUM(CASE WHEN SR>=4 AND SF>=4 AND SM>=4 THEN 1 ELSE 0 END) AS Clientes_VIP,
       COUNT(*) AS Clientes_Con_Compras,
       100.0*SUM(CASE WHEN SR>=4 AND SF>=4 AND SM>=4 THEN 1 ELSE 0 END)/COUNT(*) AS Porcentaje_VIP
FROM S;
GO

/* KPI 6: dos ventanas comparables de 180 días.
   Riesgo = R>60 al corte y F>=3 o M>=USD 3,000 en la ventana. */
;WITH P AS
(
 SELECT '180d_1996' Periodo, h.ID_Cliente, MAX(t.Fecha_Completa) Ultima,
        COUNT(DISTINCT h.OrderID) F, SUM(h.Monto_Total) M,
        CAST('1996-12-31' AS DATE) Corte
 FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
 WHERE t.Fecha_Completa BETWEEN '1996-07-05' AND '1996-12-31'
 GROUP BY h.ID_Cliente
 UNION ALL
 SELECT '180d_1997', h.ID_Cliente, MAX(t.Fecha_Completa),
        COUNT(DISTINCT h.OrderID), SUM(h.Monto_Total),
        CAST('1997-12-31' AS DATE)
 FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
 WHERE t.Fecha_Completa BETWEEN '1997-07-05' AND '1997-12-31'
 GROUP BY h.ID_Cliente
)
SELECT Periodo,
       SUM(CASE WHEN DATEDIFF(DAY,Ultima,Corte)>60 AND (F>=3 OR M>=3000) THEN 1 ELSE 0 END) AS Clientes_Riesgo,
       COUNT(*) AS Clientes_Con_Compras_Trimestre
FROM P GROUP BY Periodo ORDER BY Periodo;
GO
