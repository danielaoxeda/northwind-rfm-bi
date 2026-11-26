# Validaciones SQL de RFM y los siete KPI

Consultas de referencia reales contra `Northwind_DW`. Son el oráculo para
contrastar DAX manualmente en Power BI Desktop; no significan que DAX se haya
ejecutado.

| Archivo | Contenido |
|---|---|
| `00_consulta_referencia_rfm.sql` | R/F/M al corte 1998-05-07; 89 compradores y 2 sin compras |
| `KPI_01_06_referencia.sql` | Referencias SQL para KPI 1–6 |
| `KPI_07_reactivacion_proxy.sql` | Proxy histórico para KPI 7, con detalle de eventos |

Resultados:

- KPI 1: 67 activos R≤60; recencia promedio activa 19,64 días.
- KPI 2: 8 clientes con ≥3 pedidos en Q1-1997, 30 en Q1-1998 (+275 %).
- KPI 3: USD 51 380,0200 vs USD 38 656,6275 en dos ventanas de 300 días;
  crecimiento −24,76 % para la cohorte actualmente Frecuente.
- KPI 4: ticket USD 1 525,051854; supera la meta reformulada USD 500.
- KPI 5: 17/89 VIP = 19,10 %.
- KPI 6: 7 vs 6 clientes de riesgo en ventanas comparables de 180 días;
  variación −14,29 %.
- KPI 7: 69/89 = 77,53 % de reactivación proxy histórica; no mide campañas.

Resultados SQL completos en `../evidencias/2026-11-26_kpi_01_06.txt` y
`../evidencias/2026-11-26_kpi_07_reactivacion.txt`.
