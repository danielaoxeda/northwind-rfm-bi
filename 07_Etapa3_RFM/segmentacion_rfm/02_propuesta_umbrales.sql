/*
=====================================================================
 ETAPA 3 - PROPUESTA DE UMBRALES Y SEGMENTOS RFM  (NO APROBADA)

 Analiza la distribucion real de R, F y M y propone reglas de puntaje
 1-5 y segmentos excluyentes. NO modifica el DW ni crea objetos.

 Fecha de corte: 1998-05-07.
 Universo: 89 clientes con compras; los 2 sin compras se clasifican
 aparte y nunca entran a la puntuacion.

 Los umbrales y segmentos requieren aprobacion antes de implementarse
 en Power BI.
=====================================================================
*/
USE Northwind_DW;
GO

DECLARE @Corte DATE = '1998-05-07';

/* ------------------------------------------------------------------
   0. Base RFM por cliente (una fila por cliente con compras)
   ------------------------------------------------------------------ */
IF OBJECT_ID(N'tempdb..#RFM') IS NOT NULL DROP TABLE #RFM;

;WITH Base AS
(
    SELECT
        c.ID_Cliente,
        c.ID_Cliente_Northwind,
        c.Nombre_Empresa,
        DATEDIFF(DAY, MAX(t.Fecha_Completa), @Corte) AS R,
        COUNT(DISTINCT h.OrderID)                     AS F,
        SUM(h.Monto_Total)                            AS M
    FROM dbo.Dim_Cliente AS c
    INNER JOIN dbo.Hechos_Ventas AS h ON h.ID_Cliente = c.ID_Cliente
    INNER JOIN dbo.Dim_Tiempo   AS t ON t.ID_Tiempo   = h.ID_Tiempo
    GROUP BY c.ID_Cliente, c.ID_Cliente_Northwind, c.Nombre_Empresa
)
SELECT * INTO #RFM FROM Base;

/* ------------------------------------------------------------------
   1. Estadistica descriptiva
   ------------------------------------------------------------------ */
SELECT
    COUNT(*)                          AS Clientes,
    MIN(R)                            AS R_Min,
    MAX(R)                            AS R_Max,
    CAST(AVG(R * 1.0) AS DECIMAL(10,2)) AS R_Promedio,
    MIN(F)                            AS F_Min,
    MAX(F)                            AS F_Max,
    CAST(AVG(F * 1.0) AS DECIMAL(10,3)) AS F_Promedio,
    MIN(M)                            AS M_Min,
    MAX(M)                            AS M_Max,
    CAST(AVG(M) AS DECIMAL(19,4))     AS M_Promedio
FROM #RFM;

/* ------------------------------------------------------------------
   2. Percentiles continuos (p20, p40, p60, p80)
   Base objetiva para los umbrales; los cortes se redondean a valores
   operativos en la seccion 3.
   ------------------------------------------------------------------ */
SELECT DISTINCT
    CAST(PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY R) OVER() AS DECIMAL(10,2)) AS R_p20,
    CAST(PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY R) OVER() AS DECIMAL(10,2)) AS R_p40,
    CAST(PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY R) OVER() AS DECIMAL(10,2)) AS R_p60,
    CAST(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY R) OVER() AS DECIMAL(10,2)) AS R_p80,
    CAST(PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY F) OVER() AS DECIMAL(10,2)) AS F_p20,
    CAST(PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY F) OVER() AS DECIMAL(10,2)) AS F_p40,
    CAST(PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY F) OVER() AS DECIMAL(10,2)) AS F_p60,
    CAST(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY F) OVER() AS DECIMAL(10,2)) AS F_p80,
    CAST(PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY M) OVER() AS DECIMAL(19,2)) AS M_p20,
    CAST(PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY M) OVER() AS DECIMAL(19,2)) AS M_p40,
    CAST(PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY M) OVER() AS DECIMAL(19,2)) AS M_p60,
    CAST(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY M) OVER() AS DECIMAL(19,2)) AS M_p80
FROM #RFM;

/* ------------------------------------------------------------------
   3. Puntajes propuestos (1-5) con umbrales operativos

   Recencia (menor es mejor):
     5: R <= 8     4: 9-16     3: 17-31     2: 32-70     1: > 70
   Frecuencia (mayor es mejor):
     1: F <= 5     2: 6-7      3: 8-10      4: 11-13     5: >= 14
   Monto USD (mayor es mejor):
     1: < 3 000    2: 3 000-5 199,99   3: 5 200-11 499,99
     4: 11 500-19 999,99              5: >= 20 000

   Los limites usan <= / < de forma consistente: todos los clientes con
   el mismo valor reciben el mismo puntaje (empates agrupados).
   ------------------------------------------------------------------ */
ALTER TABLE #RFM ADD SR TINYINT, SF TINYINT, SM TINYINT, RFM TINYINT;

UPDATE #RFM
SET SR = CASE WHEN R <= 8 THEN 5 WHEN R <= 16 THEN 4 WHEN R <= 31 THEN 3
              WHEN R <= 70 THEN 2 ELSE 1 END,
    SF = CASE WHEN F <= 5 THEN 1 WHEN F <= 7 THEN 2 WHEN F <= 10 THEN 3
              WHEN F <= 13 THEN 4 ELSE 5 END,
    SM = CASE WHEN M < 3000 THEN 1 WHEN M < 5200 THEN 2 WHEN M < 11500 THEN 3
              WHEN M < 20000 THEN 4 ELSE 5 END;

UPDATE #RFM SET RFM = SR + SF + SM;

/* 3.1 Clientes exactamente en cada umbral (empates) */
SELECT
    'Clientes en el limite' AS Control,
    SUM(CASE WHEN R = 8  THEN 1 ELSE 0 END) AS R8,
    SUM(CASE WHEN R = 16 THEN 1 ELSE 0 END) AS R16,
    SUM(CASE WHEN R = 31 THEN 1 ELSE 0 END) AS R31,
    SUM(CASE WHEN R = 70 THEN 1 ELSE 0 END) AS R70,
    SUM(CASE WHEN F = 5  THEN 1 ELSE 0 END) AS F5,
    SUM(CASE WHEN F = 7  THEN 1 ELSE 0 END) AS F7,
    SUM(CASE WHEN F = 10 THEN 1 ELSE 0 END) AS F10,
    SUM(CASE WHEN F = 13 THEN 1 ELSE 0 END) AS F13,
    SUM(CASE WHEN M = 3000  THEN 1 ELSE 0 END) AS M3000,
    SUM(CASE WHEN M = 5200  THEN 1 ELSE 0 END) AS M5200,
    SUM(CASE WHEN M = 11500 THEN 1 ELSE 0 END) AS M11500,
    SUM(CASE WHEN M = 20000 THEN 1 ELSE 0 END) AS M20000
FROM #RFM;

/* 3.2 Distribucion de puntajes */
SELECT 'R' AS Dimension, SR AS Puntaje, COUNT(*) AS Clientes FROM #RFM GROUP BY SR
UNION ALL
SELECT 'F', SF, COUNT(*) FROM #RFM GROUP BY SF
UNION ALL
SELECT 'M', SM, COUNT(*) FROM #RFM GROUP BY SM
ORDER BY Dimension, Puntaje;

/* 3.3 Distribucion del puntaje combinado (3-15) */
SELECT RFM AS Puntaje_Combinado, COUNT(*) AS Clientes
FROM #RFM
GROUP BY RFM
ORDER BY RFM;

/* ------------------------------------------------------------------
   4. Reglas de segmentacion propuestas (excluyentes por orden)
      1. VIP:        R >= 4 AND F >= 4 AND M >= 4
      2. En riesgo:  no VIP, R <= 2 y (F >= 3 o M >= 3)
      3. Frecuentes: no VIP, R >= 3 y F >= 3
      4. Inactivos:  el resto
      (los clientes sin compras se reportan aparte)
   El orden del CASE garantiza que cada cliente caiga en un solo grupo.
   ------------------------------------------------------------------ */
ALTER TABLE #RFM ADD Segmento VARCHAR(20);

UPDATE #RFM
SET Segmento =
    CASE
        WHEN SR >= 4 AND SF >= 4 AND SM >= 4 THEN 'VIP'
        WHEN SR <= 2 AND (SF >= 3 OR SM >= 3) THEN 'En riesgo'
        WHEN SR >= 3 AND SF >= 3 THEN 'Frecuentes'
        ELSE 'Inactivos'
    END;

SELECT
    Segmento,
    COUNT(*) AS Clientes,
    CAST(100.0 * COUNT(*) / 89 AS DECIMAL(5,1)) AS Pct,
    CAST(AVG(R * 1.0) AS DECIMAL(10,1)) AS R_Promedio,
    CAST(AVG(F * 1.0) AS DECIMAL(10,1)) AS F_Promedio,
    CAST(AVG(M) AS DECIMAL(19,0))       AS M_Promedio
FROM #RFM
GROUP BY Segmento
ORDER BY Clientes DESC;

/* 4.1 Control de exclusion mutua: la suma debe ser 89 */
SELECT COUNT(*) AS Clasificados,
       SUM(CASE WHEN Segmento IS NULL THEN 1 ELSE 0 END) AS Sin_Clasificar
FROM #RFM;

/* 4.2 Clientes sin compras (fuera de la puntuacion) */
SELECT
    c.ID_Cliente,
    c.ID_Cliente_Northwind,
    c.Nombre_Empresa,
    c.Pais,
    'Sin compras' AS Segmento
FROM dbo.Dim_Cliente AS c
WHERE NOT EXISTS
(
    SELECT 1 FROM dbo.Hechos_Ventas AS h WHERE h.ID_Cliente = c.ID_Cliente
)
ORDER BY c.ID_Cliente;
GO
