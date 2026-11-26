# Medidas DAX

Medidas base de la Etapa 3, listas para pegar en Power BI Desktop.

| Archivo | Contenido |
|---|---|
| `01_medidas_base.dax` | Tabla `Parametros`, fecha de corte y medidas R, F, M |

## Medidas incluidas

- `Fecha de Corte` = 1998-05-07.
- `Recencia (dias)`: días desde la última compra del cliente hasta el corte.
- `Recencia Promedio (dias)`: promedio solo de clientes con compras.
- `Frecuencia`: `DISTINCTCOUNT(OrderID)`.
- `Monto Total`: `SUM(Monto_Total)` en USD.
- `Clientes con Compras`, `Clientes Sin Compras`, `Clientes Totales`.

No incluye puntajes 1–5, segmentos ni los siete KPI: están pendientes de
aprobación.

## Contraste con SQL

La semántica de las medidas se tradujo a SQL y se validó contra la consulta de
referencia. Resultados reales (89 clientes con compras):

| Medida | Esperado | SQL | Estado |
|---|---:|---:|---|
| Fecha de Corte | 1998-05-07 | 1998-05-07 | OK |
| Clientes Totales | 91 | 91 | OK |
| Clientes con Compras | 89 | 89 | OK |
| Clientes Sin Compras | 2 | 2 | OK |
| Recencia (dias) total | 1 | 1 | OK |
| Recencia Promedio (dias) | 52,56 | 52,56 | OK |
| Frecuencia total | 830 | 830 | OK |
| Monto Total | 1 265 793,0395 | 1 265 793,0395 | OK |

Huella por cliente: `CHECKSUM_AGG(BINARY_CHECKSUM(ID_Cliente,R,F,M))` =
`1385243027`, con 89 filas, R 1–658, suma F 830 y suma M 1 265 793,0395.

Evidencia: `07_Etapa3_RFM/evidencias/2026-11-26_contraste_dax_sql.txt`.

**Pendiente:** ejecutar las medidas en Power BI Desktop y comprobar la misma
matriz (pasos en `../modelo_power_bi.md`). La ejecución DAX no se simula.
