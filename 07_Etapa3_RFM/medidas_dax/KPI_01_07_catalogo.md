# Catálogo de medidas DAX KPI (borrador para Power BI Desktop)

Cada KPI tiene su archivo `.dax` independiente. Copiar cada expresión de
medida desde su archivo a **Modelado → Nueva medida**. Las expresiones son
propuestas y **no se declaran ejecutadas**; Power BI debe validar la sintaxis y
los resultados manualmente.

| Archivo | KPI | Regla |
|---|---|---|
| `KPI_01_clientes_activos.dax` | Activos y recencia promedio activa | R ≤ 60 días, fecha de corte |
| `KPI_02_pedidos_trimestrales.dax` | Clientes con 3+ pedidos y variación | Q1 completo 1998 vs Q1 completo 1997 |
| `KPI_03_crecimiento_monto.dax` | Crecimiento del monto en Frecuentes | Dos ventanas completas comparables de 300 días |
| `KPI_04_ticket_promedio.dax` | Ticket y meta | USD 500; meta reformulada, no conversión |
| `KPI_05_porcentaje_vip.dax` | % VIP | VIP / clientes con compras |
| `KPI_06_reduccion_riesgo.dax` | Variación de clientes en riesgo | Ventanas comparables de 180 días |
| `KPI_07_reactivacion_proxy.dax` | Proxy histórico de reactivación | Brecha intercompra de 61–120 días |

## Dependencias

1. `00_tabla_cliente_rfm.dax` crea la tabla calculada `Cliente_RFM`.
2. Agregar `02_puntuacion_rfm.dax` como columnas calculadas de `Cliente_RFM`.
3. Agregar `03_segmentacion.dax` como columna calculada.
4. `KPI_03` y `KPI_05` filtran esta tabla por su segmento.
5. Las medidas base de `01_medidas_base.dax` deben estar creadas previamente.

No crear la tabla `Cliente_RFM` como relación adicional del esquema estrella:
debe permanecer desconectada y sirve como snapshot por cliente al corte fijo.

## Meta monetaria

KPI 4 usa meta **USD 500 por pedido**. No se convirtió la meta histórica de
S/ 500 porque no existe tipo de cambio autorizado; es una reformulación de
objetivo en la moneda nativa de Northwind.
