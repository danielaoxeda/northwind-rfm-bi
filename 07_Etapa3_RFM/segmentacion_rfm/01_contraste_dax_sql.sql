/*
=====================================================================
 ETAPA 3 - CONTRASTE: MEDIDAS DAX vs CONSULTAS SQL

 Las medidas DAX de 01_medidas_base.dax se traducen a su equivalente
 SQL y se comparan con la consulta de referencia RFM.

 Importante: este script valida la semantica y los valores esperados de
 las medidas. La ejecucion real de DAX requiere Power BI Desktop; alli
 debe comprobarse la misma matriz (ver medidas_dax/README.md).

 Fecha de corte: 1998-05-07.
=====================================================================
*/
USE Northwind_DW;
GO

DECLARE @Corte DATE = '1998-05-07';

IF OBJECT_ID(N'tempdb..#RFM') IS NOT NULL DROP TABLE #RFM;

;WITH Base AS
(
    SELECT
        c.ID_Cliente,
        DATEDIFF(DAY, MAX(t.Fecha_Completa), @Corte) AS R,
        COUNT(DISTINCT h.OrderID)                     AS F,
        SUM(h.Monto_Total)                            AS M
    FROM dbo.Dim_Cliente AS c
    INNER JOIN dbo.Hechos_Ventas AS h ON h.ID_Cliente = c.ID_Cliente
    INNER JOIN dbo.Dim_Tiempo   AS t ON t.ID_Tiempo   = h.ID_Tiempo
    GROUP BY c.ID_Cliente
)
SELECT * INTO #RFM FROM Base;

/* ------------------------------------------------------------------
   1. Valores de las medidas DAX en el total del modelo
   ------------------------------------------------------------------ */
DECLARE @ClientesTotales   INT            = (SELECT COUNT(*) FROM dbo.Dim_Cliente);
DECLARE @ClientesConCompras INT           = (SELECT COUNT(DISTINCT ID_Cliente) FROM dbo.Hechos_Ventas);
DECLARE @RecenciaTotal     INT            = (SELECT DATEDIFF(DAY, MAX(t.Fecha_Completa), @Corte)
                                             FROM dbo.Hechos_Ventas h
                                             JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo = h.ID_Tiempo);
DECLARE @RecenciaPromedio  DECIMAL(10,2)  = (SELECT CAST(AVG(R * 1.0) AS DECIMAL(10,2)) FROM #RFM);
DECLARE @Frecuencia        INT            = (SELECT COUNT(DISTINCT OrderID) FROM dbo.Hechos_Ventas);
DECLARE @MontoTotal        DECIMAL(19,4)  = (SELECT SUM(Monto_Total) FROM dbo.Hechos_Ventas);

SELECT
    @ClientesTotales                                  AS Clientes_Totales,      -- 91
    @ClientesConCompras                               AS Clientes_Con_Compras,  -- 89
    @ClientesTotales - @ClientesConCompras            AS Clientes_Sin_Compras,  -- 2
    @RecenciaTotal                                    AS Recencia_Total,        -- 1
    @RecenciaPromedio                                 AS Recencia_Promedio,     -- 52.56
    @Frecuencia                                       AS Frecuencia,            -- 830
    @MontoTotal                                       AS Monto_Total;           -- 1265793.0395

/* ------------------------------------------------------------------
   2. Matriz de contraste medida a medida
   ------------------------------------------------------------------ */
SELECT *
FROM (VALUES
    ('Fecha de Corte',             CAST('1998-05-07' AS VARCHAR(10)), CAST('1998-05-07' AS VARCHAR(10))),
    ('Clientes Totales',           '91',      CAST(@ClientesTotales AS VARCHAR(20))),
    ('Clientes con Compras',       '89',      CAST(@ClientesConCompras AS VARCHAR(20))),
    ('Clientes Sin Compras',       '2',       CAST(@ClientesTotales - @ClientesConCompras AS VARCHAR(20))),
    ('Recencia (dias) total',      '1',       CAST(@RecenciaTotal AS VARCHAR(20))),
    ('Recencia Promedio (dias)',   '52.56',   CAST(@RecenciaPromedio AS VARCHAR(20))),
    ('Frecuencia total',           '830',     CAST(@Frecuencia AS VARCHAR(20))),
    ('Monto Total',                '1265793.0395', CAST(@MontoTotal AS VARCHAR(20)))
) AS M(Medida, Esperado, SQL)
CROSS APPLY (SELECT CASE WHEN M.Esperado = M.SQL THEN 'OK' ELSE 'FALLA' END AS Estado) AS E;

/* ------------------------------------------------------------------
   3. Huella de la tabla RFM por cliente
   Sirve para comparar contra una tabla calculada en Power BI.
   ------------------------------------------------------------------ */
SELECT
    COUNT(*)                                              AS Clientes,
    CHECKSUM_AGG(BINARY_CHECKSUM(ID_Cliente, R, F, M))    AS Checksum_RFM,
    MIN(R) AS R_Min, MAX(R) AS R_Max,
    SUM(F) AS F_Suma, SUM(M) AS M_Suma
FROM #RFM;

/* ------------------------------------------------------------------
   4. Los dos clientes sin compras
   ------------------------------------------------------------------ */
SELECT c.ID_Cliente, c.ID_Cliente_Northwind, c.Nombre_Empresa, c.Pais
FROM dbo.Dim_Cliente c
WHERE NOT EXISTS (SELECT 1 FROM dbo.Hechos_Ventas h WHERE h.ID_Cliente = c.ID_Cliente)
ORDER BY c.ID_Cliente;
GO
