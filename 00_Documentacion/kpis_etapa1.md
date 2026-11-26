# Los siete KPI de la Etapa 1 — viabilidad y fórmulas propuestas

Revisión de los KPI definidos en el informe (sección 1.2.4) contra el DW
reconstruido. **No se implementan todavía**: este documento evalúa su
viabilidad, propone fórmulas y señala limitaciones.

Contexto común:

- Datos históricos del 1996-07-04 al 1998-05-06 (672 días, 830 pedidos).
- Fecha de corte fija: **1998-05-07**. No se usa `TODAY()`.
- Importes en **USD** (el informe los expresa en soles; ver limitación L1).
- 91 clientes: 89 con compras y 2 sin compras.

---

## KPI 1 — Días desde la última compra (recencia)

| | |
|---|---|
| Meta del informe | Reducir a menos de 60 días el promedio de recencia de clientes activos |
| Viabilidad | **Alta** |
| Fórmula propuesta | `AVERAGEX(FILTER(VALUES(Dim_Cliente[ID_Cliente]), [Recencia (dias)] <= 90), [Recencia (dias)])` |
| Medidas base | `[Recencia (dias)]`, `[Recencia Promedio (dias)]` |
| Valor actual | Promedio global 52,56 días; mínimo 1 y máximo 658 |

**Limitaciones**

- Con un histórico cerrado, la recencia no baja con el tiempo: la meta solo
  puede evaluarse como foto del periodo, no como mejora mes a mes.
- Falta aprobar la definición de "cliente activo" (se propone R ≤ 90 días).

## KPI 2 — Número de pedidos por cliente

| | |
|---|---|
| Meta del informe | Incrementar 10 % los clientes con 3 o más pedidos trimestrales |
| Viabilidad | **Alta** (conteo); **media** (variación) |
| Fórmula propuesta | `Clientes con >=3 pedidos = CALCULATE(DISTINCTCOUNT(Dim_Cliente[ID_Cliente]), FILTER(VALUES(Dim_Cliente[ID_Cliente]), [Frecuencia] >= 3))` |
| Porcentaje | `DIVIDE([Clientes con >=3 pedidos], [Clientes con Compras])` |
| Valor actual | 89 clientes con compras; frecuencia media 9,33 pedidos; máximo 31 |

**Limitaciones**

- La variación de +10 % exige una línea base comparable; el histórico solo
  cubre 1996 (parcial), 1997 y 1998 (parcial).
- "Trimestral" debe fijarse a trimestre calendario (`Dim_Tiempo[Trimestre]`).

## KPI 3 — Monto total de compra por cliente

| | |
|---|---|
| Meta del informe | Aumentar 15 % el ticket acumulado anual de los clientes "Frecuentes" |
| Viabilidad | **Alta** (monto); **media** (crecimiento anual) |
| Fórmula propuesta | `Monto Anual = CALCULATE([Monto Total], Dim_Tiempo[Anio] = SELECTEDVALUE(Dim_Tiempo[Anio]))` |
| Variación | `DIVIDE([Monto Año Actual] - [Monto Año Anterior], [Monto Año Anterior])` |
| Valor actual | Monto total 1 265 793,0395 USD; promedio por cliente 14 222,39 USD |

**Limitaciones**

- Depende de que "Frecuentes" esté aprobado; hoy es una propuesta.
- Los años 1996 y 1998 están incompletos, así que la comparación anual puede
  distorsionarse.

## KPI 4 — Ticket promedio por cliente

| | |
|---|---|
| Meta del informe | Mantener o superar S/ 500 por pedido |
| Viabilidad | **Alta** (cálculo); **bloqueada** (moneda de la meta) |
| Fórmula propuesta | `Ticket Promedio = DIVIDE([Monto Total], [Frecuencia])` |
| Valor actual | 1 265 793,0395 / 830 = **1 525,05 USD por pedido** |

**Limitaciones**

- L1: la meta está en soles y los datos en USD. No hay tipo de cambio en el
  repositorio; no se convierte ni se simula. La meta debe reformularse en USD.
- El ticket promedio por pedido no es lo mismo que por línea; el grano del
  hecho es la línea.

## KPI 5 — Porcentaje de clientes VIP

| | |
|---|---|
| Meta del informe | Alcanzar al menos 15 % de la cartera como VIP |
| Viabilidad | **Alta**, condicionada a aprobar la regla VIP |
| Fórmula propuesta | `DIVIDE(CALCULATE([Clientes con Compras], Segmento = "VIP"), [Clientes Totales])` |
| Valor con la propuesta | 17 de 91 = **18,7 %** (19,1 % de los 89 con compras) |

**Limitaciones**

- El segmento VIP aún no está aprobado; el cálculo cambiará con los umbrales.
- Incluir o excluir a los 2 clientes sin compras altera el denominador.

## KPI 6 — Clientes en riesgo de abandono

| | |
|---|---|
| Meta del informe | Reducir 20 % los clientes "En riesgo" |
| Viabilidad | **Alta** (conteo); **baja** (reducción) |
| Fórmula propuesta | `Clientes en Riesgo = CALCULATE([Clientes con Compras], Segmento = "En riesgo")` |
| Valor con la propuesta | 15 de 89 = 16,9 % |

**Limitaciones**

- Sin snapshots periódicos no se puede medir la reducción de 20 %; solo el
  estado actual.
- La regla "En riesgo" depende de umbrales pendientes de aprobación.

## KPI 7 — Tasa de reactivación de clientes inactivos

| | |
|---|---|
| Meta del informe | Reactivar al menos 10 % de inactivos por campaña |
| Viabilidad | **No viable con los datos actuales** |
| Fórmula propuesta | `DIVIDE(Clientes reactivados, Clientes inactivos al inicio de la campaña)` |
| Dato faltante | No existe tabla de campañas ni de compras posteriores al corte |

**Limitaciones**

- Reactivación exige comparar dos momentos y registrar la acción comercial.
  El DW es una foto histórica sin seguimiento de campañas.
- Se puede aproximar con un proxy (cliente inactivo que vuelve a comprar en
  una ventana), pero no mide la campaña. No se implementará como KPI oficial
  sin una fuente de eventos.

---

## Resumen de viabilidad

| # | KPI | Viabilidad | Requiere aprobación |
|---:|---|---|---|
| 1 | Días desde la última compra | Alta | Definición de cliente activo |
| 2 | Pedidos por cliente | Alta / media | Ventana trimestral |
| 3 | Monto por cliente | Alta / media | Regla de "Frecuentes" |
| 4 | Ticket promedio | Alta / bloqueada | Meta en USD |
| 5 | % VIP | Alta | Umbrales y regla VIP |
| 6 | Clientes en riesgo | Alta / baja | Umbrales y snapshots |
| 7 | Tasa de reactivación | **No viable** | Fuente de campañas |

## Limitaciones transversales

- **L1 — Moneda:** metas en soles vs datos en USD. No se convierte.
- **L2 — Historia corta:** 1996 y 1998 incompletos; sin serie mensual continua
  de negocio más allá de 21 meses.
- **L3 — Sin campañas:** no hay eventos de marketing ni fechas de reacción.
- **L4 — Base pequeña:** 91 clientes; los porcentajes cambian mucho con pocos
  casos.
- **L5 — Reglas pendientes:** VIP, frecuentes, en riesgo e inactivos requieren
  aprobación antes de publicar cifras.
