/*
 Fase 7 - Segmentos RFM consolidados.
 Solo lectura. Corte: 1998-05-07. No escribe tablas del DW.
*/
USE Northwind_DW;
GO
DECLARE @Corte DATE = '1998-05-07';

;WITH Base AS
(
    SELECT c.ID_Cliente, c.ID_Cliente_Northwind, c.Nombre_Empresa,
           DATEDIFF(DAY, MAX(t.Fecha_Completa), @Corte) AS R,
           COUNT(DISTINCT h.OrderID) AS F,
           SUM(h.Monto_Total) AS M
    FROM dbo.Dim_Cliente c
    JOIN dbo.Hechos_Ventas h ON h.ID_Cliente = c.ID_Cliente
    JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo = h.ID_Tiempo
    WHERE t.Fecha_Completa < @Corte
    GROUP BY c.ID_Cliente, c.ID_Cliente_Northwind, c.Nombre_Empresa
), Scores AS
(
    SELECT *,
        CASE WHEN R <= 8 THEN 5 WHEN R <= 16 THEN 4 WHEN R <= 31 THEN 3
             WHEN R <= 60 THEN 2 ELSE 1 END AS SR,
        CASE WHEN F <= 5 THEN 1 WHEN F <= 7 THEN 2 WHEN F <= 10 THEN 3
             WHEN F <= 13 THEN 4 ELSE 5 END AS SF,
        CASE WHEN M < 3000 THEN 1 WHEN M < 5200 THEN 2 WHEN M < 11500 THEN 3
             WHEN M < 20000 THEN 4 ELSE 5 END AS SM
    FROM Base
), Classified AS
(
    SELECT *,
        CASE
            WHEN SR >= 4 AND SF >= 4 AND SM >= 4 THEN 'VIP'
            WHEN R <= 60 AND SF <= 2 AND SM <= 2 THEN 'Ocasional'
            WHEN R <= 60 THEN 'Activo'
            WHEN SF >= 4 OR SM >= 4 THEN 'En riesgo'
            WHEN SF >= 3 THEN 'Frecuente'
            ELSE 'Inactivo'
        END AS Segmento
    FROM Scores
)
SELECT Segmento, COUNT(*) AS Clientes,
       CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER() AS DECIMAL(5,1)) AS Pct_Con_Compras,
       CAST(AVG(R * 1.0) AS DECIMAL(10,1)) AS R_Promedio,
       CAST(AVG(F * 1.0) AS DECIMAL(10,1)) AS F_Promedio,
       CAST(AVG(M) AS DECIMAL(19,0)) AS M_Promedio
FROM Classified
GROUP BY Segmento
ORDER BY Segmento;

-- Distribucion final de cada puntuacion, con el limite R2 cerrado en 60.
;WITH B AS
(
    SELECT h.ID_Cliente,
           DATEDIFF(DAY, MAX(t.Fecha_Completa), @Corte) AS R,
           COUNT(DISTINCT h.OrderID) AS F,
           SUM(h.Monto_Total) AS M
    FROM dbo.Hechos_Ventas h
    JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
    WHERE t.Fecha_Completa<@Corte
    GROUP BY h.ID_Cliente
), S AS
(
    SELECT *,
        CASE WHEN R<=8 THEN 5 WHEN R<=16 THEN 4 WHEN R<=31 THEN 3
             WHEN R<=70 THEN 2 ELSE 1 END AS SR,
        CASE WHEN F<=5 THEN 1 WHEN F<=7 THEN 2 WHEN F<=10 THEN 3
             WHEN F<=13 THEN 4 ELSE 5 END AS SF,
        CASE WHEN M<3000 THEN 1 WHEN M<5200 THEN 2 WHEN M<11500 THEN 3
             WHEN M<20000 THEN 4 ELSE 5 END AS SM
    FROM B
)
SELECT 'R' AS Dim, SR AS Puntaje, COUNT(*) AS Clientes FROM S GROUP BY SR
UNION ALL SELECT 'F', SF, COUNT(*) FROM S GROUP BY SF
UNION ALL SELECT 'M', SM, COUNT(*) FROM S GROUP BY SM
ORDER BY Dim, Puntaje;

-- Actividad, clientes con compras recientes de 60 días inclusive.
;WITH Ultima AS
(
    SELECT h.ID_Cliente, MAX(t.Fecha_Completa) AS Ultima
    FROM dbo.Hechos_Ventas h
    JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo = h.ID_Tiempo
    WHERE t.Fecha_Completa < @Corte
    GROUP BY h.ID_Cliente
)
SELECT COUNT(*) AS Clientes_Con_Compras,
       SUM(CASE WHEN DATEDIFF(DAY, Ultima, @Corte) <= 60 THEN 1 ELSE 0 END) AS Activos_60d,
       SUM(CASE WHEN DATEDIFF(DAY, Ultima, @Corte) > 60 THEN 1 ELSE 0 END) AS No_Activos
FROM Ultima;

-- Los clientes sin compras se identifican aparte.
SELECT c.ID_Cliente, RTRIM(c.ID_Cliente_Northwind) AS Codigo,
       c.Nombre_Empresa, c.Pais, 'Sin compras' AS Segmento
FROM dbo.Dim_Cliente c
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Hechos_Ventas h
    JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo = h.ID_Tiempo
    WHERE h.ID_Cliente = c.ID_Cliente AND t.Fecha_Completa < @Corte
)
ORDER BY c.ID_Cliente;
GO
