/*
KPI 7 - Aproximacion de reactivacion historica, NO efecto de campaña.

Evento proxy: cliente vuelve a comprar 61-120 dias despues de un pedido.
Elegible: su pedido anterior ocurre hasta 1998-03-07, de modo que existe
un seguimiento completo de 60 dias hasta 1998-05-06.
Numerador: clientes elegibles con una siguiente compra entre dias 61 y 120.
Denominador: clientes con al menos un pedido que alcanzo 60 dias observables.
*/
USE Northwind_DW;
GO

DECLARE @FinDatos DATE='1998-05-06';
DECLARE @InicioSeguimiento DATE=DATEADD(DAY,-60,@FinDatos);

;WITH PedidosCliente AS
(
    SELECT h.ID_Cliente, h.OrderID, MIN(t.Fecha_Completa) AS FechaPedido
    FROM dbo.Hechos_Ventas h
    JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
    GROUP BY h.ID_Cliente, h.OrderID
), Pares AS
(
    SELECT ID_Cliente, FechaPedido,
           LEAD(FechaPedido) OVER(PARTITION BY ID_Cliente ORDER BY FechaPedido, OrderID) AS FechaSiguiente
    FROM PedidosCliente
), Elegibles AS
(
    SELECT ID_Cliente,
           MAX(CASE WHEN FechaPedido <= @InicioSeguimiento
                    THEN 1 ELSE 0 END) AS TuvoVentana60d,
           MAX(CASE WHEN FechaSiguiente IS NOT NULL
                         AND DATEDIFF(DAY,FechaPedido,FechaSiguiente) BETWEEN 61 AND 120
                         AND FechaPedido <= @InicioSeguimiento
                    THEN 1 ELSE 0 END) AS ReactivadoProxy
    FROM Pares
    GROUP BY ID_Cliente
)
SELECT SUM(TuvoVentana60d) AS Clientes_Elegibles,
       SUM(CASE WHEN TuvoVentana60d=1 AND ReactivadoProxy=1 THEN 1 ELSE 0 END) AS Reactivados_Proxy,
       CAST(100.0*SUM(CASE WHEN TuvoVentana60d=1 AND ReactivadoProxy=1 THEN 1 ELSE 0 END)
            / NULLIF(SUM(TuvoVentana60d),0) AS DECIMAL(6,2)) AS Tasa_Proxy_Pct,
       @InicioSeguimiento AS Inicio_Seguimiento,
       @FinDatos AS Fin_Datos
FROM Elegibles;
GO

-- Auditoria de eventos proxy por cliente.
DECLARE @Fin DATE='1998-05-06';
DECLARE @Inicio DATE=DATEADD(DAY,-60,@Fin);
;WITH Pedidos AS
(
 SELECT h.ID_Cliente,h.OrderID,MIN(t.Fecha_Completa) FechaPedido
 FROM dbo.Hechos_Ventas h JOIN dbo.Dim_Tiempo t ON t.ID_Tiempo=h.ID_Tiempo
 GROUP BY h.ID_Cliente,h.OrderID
), P AS
(
 SELECT *, LEAD(FechaPedido) OVER(PARTITION BY ID_Cliente ORDER BY FechaPedido,OrderID) Siguiente
 FROM Pedidos
)
SELECT ID_Cliente, MIN(FechaPedido) AS Pedido_Anterior,
       MIN(Siguiente) AS Compra_Reactivacion
FROM P
WHERE FechaPedido<=@Inicio AND Siguiente IS NOT NULL
  AND DATEDIFF(DAY,FechaPedido,Siguiente) BETWEEN 61 AND 120
GROUP BY ID_Cliente
ORDER BY ID_Cliente;
GO
