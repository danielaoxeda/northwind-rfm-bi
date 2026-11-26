/*
=====================================================================
 ETAPA 3 - CONSULTAS DE REFERENCIA RFM  (sin puntuacion ni segmentacion)

 Valida posteriormente Recencia (R), Frecuencia (F) y Monto (M) por
 cliente sobre Northwind_DW.

 Fecha de corte aprobada: 1998-05-07
   = ultima fecha de venta (1998-05-06) + 1 dia.

 Definiciones:
   R = DATEDIFF(DAY, ultima compra del cliente, fecha de corte)
   F = COUNT(DISTINCT OrderID) por cliente
   M = SUM(Monto_Total) por cliente (USD, sin conversion)

 Este script NO calcula puntajes 1-5, ni segmentos, ni medidas DAX.
=====================================================================
*/
USE Northwind_DW;
GO

DECLARE @FechaCorte DATE = '1998-05-07';

/* ------------------------------------------------------------------
   1. Clientes CON compras: R, F y M
   Esperado: 89 filas. Recencia minima = 1 (venta del 1998-05-06).
   ------------------------------------------------------------------ */
SELECT
    c.ID_Cliente,
    c.ID_Cliente_Northwind,
    c.Nombre_Empresa,
    c.Pais,
    MAX(t.Fecha_Completa)                                   AS Ultima_Compra,
    DATEDIFF(DAY, MAX(t.Fecha_Completa), @FechaCorte)       AS Recencia_Dias,
    COUNT(DISTINCT h.OrderID)                               AS Frecuencia_Pedidos,
    SUM(h.Monto_Total)                                      AS Monto_Total
FROM dbo.Dim_Cliente AS c
INNER JOIN dbo.Hechos_Ventas AS h ON h.ID_Cliente = c.ID_Cliente
INNER JOIN dbo.Dim_Tiempo   AS t ON t.ID_Tiempo   = h.ID_Tiempo
GROUP BY c.ID_Cliente, c.ID_Cliente_Northwind, c.Nombre_Empresa, c.Pais
ORDER BY Recencia_Dias, Frecuencia_Pedidos DESC, Monto_Total DESC;
GO

/* ------------------------------------------------------------------
   2. Clientes SIN compras (identificados por separado)
   Esperado: 2 filas. R, F y M quedan en NULL / 0.
   Con los datos actuales: FISSA (22) y PARIS (57).
   ------------------------------------------------------------------ */
SELECT
    c.ID_Cliente,
    c.ID_Cliente_Northwind,
    c.Nombre_Empresa,
    c.Pais,
    CAST(NULL AS DATE)  AS Ultima_Compra,
    CAST(NULL AS INT)   AS Recencia_Dias,
    0                   AS Frecuencia_Pedidos,
    CAST(0 AS DECIMAL(19,4)) AS Monto_Total,
    'Sin compras'       AS Situacion
FROM dbo.Dim_Cliente AS c
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Hechos_Ventas AS h
    WHERE h.ID_Cliente = c.ID_Cliente
)
ORDER BY c.ID_Cliente;
GO

/* ------------------------------------------------------------------
   3. Vista combinada (todos los clientes) con indicador de compras
   Util para validar el universo de 91 clientes antes de puntuar.
   ------------------------------------------------------------------ */
DECLARE @FechaCorte DATE = '1998-05-07';

SELECT
    c.ID_Cliente,
    c.ID_Cliente_Northwind,
    c.Nombre_Empresa,
    c.Pais,
    CASE WHEN COUNT(h.ID_Hecho_Venta) = 0 THEN 0 ELSE 1 END AS Tiene_Compras,
    CASE WHEN COUNT(h.ID_Hecho_Venta) = 0 THEN NULL
         ELSE DATEDIFF(DAY, MAX(t.Fecha_Completa), @FechaCorte) END AS Recencia_Dias,
    COUNT(DISTINCT h.OrderID)                               AS Frecuencia_Pedidos,
    COALESCE(SUM(h.Monto_Total), CAST(0 AS DECIMAL(19,4)))  AS Monto_Total
FROM dbo.Dim_Cliente AS c
LEFT JOIN dbo.Hechos_Ventas AS h ON h.ID_Cliente = c.ID_Cliente
LEFT JOIN dbo.Dim_Tiempo   AS t ON t.ID_Tiempo   = h.ID_Tiempo
GROUP BY c.ID_Cliente, c.ID_Cliente_Northwind, c.Nombre_Empresa, c.Pais
ORDER BY c.ID_Cliente;
GO

/* ------------------------------------------------------------------
   4. Controles de cuadre de las consultas RFM contra el DW
   Todos deben devolver los valores indicados.
   ------------------------------------------------------------------ */
DECLARE @FechaCorte DATE = '1998-05-07';

SELECT
    (SELECT COUNT(*) FROM dbo.Dim_Cliente)                       AS Clientes_Total,        -- 91
    (SELECT COUNT(*) FROM dbo.Dim_Cliente c
      WHERE EXISTS (SELECT 1 FROM dbo.Hechos_Ventas h
                    WHERE h.ID_Cliente = c.ID_Cliente))          AS Clientes_Con_Compras,  -- 89
    (SELECT COUNT(*) FROM dbo.Dim_Cliente c
      WHERE NOT EXISTS (SELECT 1 FROM dbo.Hechos_Ventas h
                        WHERE h.ID_Cliente = c.ID_Cliente))      AS Clientes_Sin_Compras,  -- 2
    (SELECT COUNT(DISTINCT OrderID) FROM dbo.Hechos_Ventas)      AS Pedidos_Distintos,     -- 830
    (SELECT SUM(Monto_Total) FROM dbo.Hechos_Ventas)             AS Monto_Total,           -- 1265793.0395
    (SELECT MIN(Recencia) FROM
        (SELECT DATEDIFF(DAY, MAX(t.Fecha_Completa), @FechaCorte) AS Recencia
         FROM dbo.Hechos_Ventas h
         JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo = h.ID_Tiempo
         GROUP BY h.ID_Cliente) r)                               AS Recencia_Minima,       -- 1
    (SELECT MAX(Recencia) FROM
        (SELECT DATEDIFF(DAY, MAX(t.Fecha_Completa), @FechaCorte) AS Recencia
         FROM dbo.Hechos_Ventas h
         JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo = h.ID_Tiempo
         GROUP BY h.ID_Cliente) r)                               AS Recencia_Maxima;
GO
