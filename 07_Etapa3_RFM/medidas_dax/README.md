# Medidas DAX y KPI

Expresiones preparadas para Power BI Desktop; todavía no ejecutadas en la
aplicación.

| Archivo | Elemento |
|---|---|
| `00_tabla_cliente_rfm.dax` | Tabla calculada con una fila por cliente al corte |
| `01_medidas_base.dax` | Corte, Recencia, Frecuencia, Monto y universo |
| `02_puntuacion_rfm.dax` | Scores R/F/M y combinado 3–15 |
| `03_segmentacion.dax` | Segmento excluyente y estado activo |
| `KPI_01_clientes_activos.dax` | Activos y recencia promedio de activos |
| `KPI_02_pedidos_trimestrales.dax` | Clientes con ≥3 pedidos y cambio Q1 |
| `KPI_03_crecimiento_monto.dax` | Monto de Frecuentes en ventanas 300d comparables |
| `KPI_04_ticket_promedio.dax` | Ticket y meta reformulada USD 500 |
| `KPI_05_porcentaje_vip.dax` | VIP / clientes compradores |
| `KPI_06_reduccion_riesgo.dax` | Variación del riesgo en ventanas 180d |
| `KPI_07_reactivacion_proxy.dax` | Pausa y recompra histórica proxy |
| `KPI_01_07_catalogo.md` | Dependencias y orden de creación |

Contraste SQL real en `../evidencias/`. No declarar resultados DAX como
verificados hasta ejecutar medidas en Power BI y contrastar cada indicador.
