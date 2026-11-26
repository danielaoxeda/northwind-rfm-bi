# Los siete KPI de la Etapa 1 — definición consolidada

Consolidación de los KPI del informe (sección 1.2.4) contra el DW reconstruido.
Las expresiones DAX/SQL están en archivos independientes. DAX no se declara
ejecutado hasta validarlo en Power BI Desktop.

Contexto común:

- Datos históricos del 1996-07-04 al 1998-05-06 (672 días, 830 pedidos).
- Fecha de evaluación: **1998-05-07** en las referencias iniciales.
- Activo: compra en los últimos **60 días inclusive**.
- Importes en **USD**.
- 91 clientes: 89 con compras y 2 sin compras.

---

## KPI 1 — Días desde la última compra (recencia)

| | |
|---|---|
| Meta del informe | Reducir a menos de 60 días el promedio de recencia de clientes activos |
| Viabilidad | **Alta** |
| Fórmula | Clientes activos: `R <= 60`; recencia promedio de esos clientes |
| DAX / SQL | `medidas_dax/KPI_01_clientes_activos.dax`; `validaciones_sql/KPI_01_06_referencia.sql` |
| Resultado SQL | 67 activos; recencia promedio activa **19,64 días** |

**Limitaciones**

- Con un histórico cerrado, la recencia no baja con el tiempo: la meta solo
  puede evaluarse como foto del periodo, no como mejora mes a mes.
- Definición aprobada: activo si R ≤ 60 días inclusive.

## KPI 2 — Número de pedidos por cliente

| | |
|---|---|
| Meta del informe | Incrementar 10 % los clientes con 3 o más pedidos trimestrales |
| Viabilidad | **Alta** (conteo); **media** (variación) |
| Fórmula | Clientes con ≥3 pedidos por Q1 completo; variación Q1 1998 contra Q1 1997 |
| DAX / SQL | `medidas_dax/KPI_02_pedidos_trimestrales.dax`; `validaciones_sql/KPI_01_06_referencia.sql` |
| Resultado SQL | 30 clientes Q1-1998 vs 8 Q1-1997; variación **+275 %** |

**Limitaciones**

- Q1 es un periodo completo de 90 días en ambos años. Clientes contados una
  vez por trimestre aunque realicen múltiples pedidos.
- La variación mide cambio histórico, no causalidad ni meta alcanzada.

## KPI 3 — Monto total de compra por cliente

| | |
|---|---|
| Meta del informe | Aumentar 15 % el ticket acumulado anual de los clientes "Frecuentes" |
| Viabilidad | **Alta** (monto); **media** (crecimiento anual) |
| Fórmula | Suma M de la cohorte actualmente Frecuente, en ventanas iguales de 300 días |
| DAX / SQL | `medidas_dax/KPI_03_crecimiento_monto.dax`; `validaciones_sql/KPI_01_06_referencia.sql` |
| Resultado SQL | USD 51 380,0200 previo vs USD 38 656,6275 reciente; variación **−24,76 %** (cohorte actual: 2 Frecuentes) |

**Limitaciones**

- Se compara 1996-07-11–1997-05-06 con 1997-07-11–1998-05-06: 300 días cada
  uno, ambos dentro del rango disponible.
- El KPI del informe pide monto anual; solo hay una ventana comparable
  completa inferior a 365 días. No presentarlo como crecimiento anual.
- Cohorte Frecuente según la clasificación RFM consolidada al 1998-05-07:
  solo 2 clientes, por lo que la variación es muy sensible.

## KPI 4 — Ticket promedio por cliente

| | |
|---|---|
| Meta consolidada | Mantener o superar **USD 500 por pedido** |
| Viabilidad | **Alta** |
| Fórmula | `SUM(Monto_Total) / DISTINCTCOUNT(OrderID)` |
| DAX / SQL | `medidas_dax/KPI_04_ticket_promedio.dax`; SQL en `KPI_01_06_referencia.sql` |
| Resultado SQL | **USD 1 525,051854** por pedido; cumple meta |

**Limitaciones**

- La meta USD 500 es una reformulación del objetivo en moneda nativa, no una
  conversión de S/ 500. No se usó tipo de cambio.
- El ticket promedio por pedido no es lo mismo que por línea; el grano del
  hecho es la línea.

## KPI 5 — Porcentaje de clientes VIP

| | |
|---|---|
| Meta | Al menos 15 % de clientes con compras como VIP |
| Viabilidad | **Alta** |
| Fórmula | VIP / clientes con compras (denominador aprobado) |
| DAX / SQL | `medidas_dax/KPI_05_porcentaje_vip.dax`; `validaciones_sql/KPI_01_06_referencia.sql` |
| Resultado SQL | 17 / 89 = **19,10 %** |

**Limitaciones**

- Los dos clientes sin compras se excluyen del denominador.

## KPI 6 — Clientes en riesgo de abandono

| | |
|---|---|
| Meta | Reducir 20 % clientes en riesgo |
| Viabilidad | **Media**, con cortes comparables |
| Fórmula | Variación del conteo de riesgo entre ventanas comparables de 180 días |
| DAX / SQL | `medidas_dax/KPI_06_reduccion_riesgo.dax`; `validaciones_sql/KPI_01_06_referencia.sql` |
| Resultado SQL | 7 (1996-07-05–12-31) vs 6 (1997-07-05–12-31): **−14,29 %** |

**Limitaciones**

- Son dos ventanas iguales de 180 días con riesgo definido dentro de cada
  ventana (R>60 y F≥3 o M≥USD 3 000). No hay snapshots originales.
- No confundir esta definición histórica del KPI con el segmento RFM de corte.

## KPI 7 — Tasa de reactivación de clientes inactivos

| | |
|---|---|
| Meta del informe | Reactivar al menos 10 % de inactivos por campaña |
| Viabilidad | **Aproximación histórica viable; efecto de campaña no medible** |
| Fórmula | Clientes con brecha intercompra de 61–120 días / clientes con 60 días observables |
| DAX / SQL | `medidas_dax/KPI_07_reactivacion_proxy.dax`; `validaciones_sql/KPI_07_reactivacion_proxy.sql` |
| Resultado SQL | 69 / 89 = **77,53 %** (proxy histórico) |

**Limitaciones**

- El proxy identifica recompra tras una pausa >60 días dentro del histórico;
  no prueba que una campaña causó la recompra.
- No hay registros de campañas, clientes expuestos ni grupo de control.

---

## Resumen de viabilidad

| # | KPI | Viabilidad | Requiere aprobación |
|---:|---|---|---|
| 1 | Activos y recencia promedio | Alta | Implementación DAX por comprobar |
| 2 | Clientes con 3+ pedidos | Alta | Periodos Q1 comparables |
| 3 | Crecimiento de monto Frecuentes | Media | Ventanas 300d; no anual |
| 4 | Ticket promedio | Alta | Meta USD 500 reformulada |
| 5 | % VIP | Alta | Denominador: clientes compradores |
| 6 | Reducción de riesgo | Media | Proxy comparable 180d |
| 7 | Reactivación | Proxy | No atribuye efecto de campaña |

## Lectura de metas contra los valores históricos disponibles

| KPI | Resultado SQL | Meta normalizada | Lectura |
|---:|---|---|---|
| 1 | Recencia media activa 19,64 días | <60 días | Cumple como fotografía histórica |
| 2 | 8 → 30 clientes Q1 con ≥3 pedidos (+275 %) | +10 % | Supera el cambio histórico; no implica causalidad |
| 3 | USD 51 380,02 → USD 38 656,63 para 2 Frecuentes (−24,76 %) | +15 % | No cumple; cohorte y ventana limitadas |
| 4 | USD 1 525,05 por pedido | ≥USD 500 | Cumple la meta reformulada |
| 5 | 17/89 = 19,10 % VIP | ≥15 % | Cumple según las reglas aprobadas |
| 6 | 7 → 6 casos de riesgo (−14,29 %) | −20 % | No alcanza la reducción; ventana 180 días |
| 7 | 69/89 = 77,53 % proxy | ≥10 % | No comparable a meta de campaña; sin atribución |

## Limitaciones transversales

- **L1 — Moneda:** KPI 4 reformulado a USD 500, sin conversión de moneda.
- **L2 — Historia corta:** 1996 y 1998 incompletos; sin serie mensual continua
  de negocio más allá de 21 meses.
- **L3 — Sin campañas:** no hay eventos de marketing ni fechas de reacción.
- **L4 — Base pequeña:** 91 clientes; los porcentajes cambian mucho con pocos
  casos.
- **L5 — DAX:** fórmulas definidas y sus equivalentes SQL validados; ejecución
  y contraste real en Power BI Desktop todavía pendientes.

## Trazabilidad

- Expresiones DAX independientes: `07_Etapa3_RFM/medidas_dax/KPI_*.dax`.
- Resultados SQL: `07_Etapa3_RFM/evidencias/2026-11-26_kpi_01_06.txt` y
  `2026-11-26_kpi_07_reactivacion.txt`.
- Consultas equivalentes: `07_Etapa3_RFM/validaciones_sql/KPI_01_06_referencia.sql`
  y `KPI_07_reactivacion_proxy.sql`.
