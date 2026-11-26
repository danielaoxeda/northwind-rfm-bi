# Etapa 3 — Cálculo RFM, segmentación y dashboard

Esta carpeta está reservada para los artefactos de la Etapa 3. Todavía no
contiene scripts ni el modelo de Power BI.

## Dependencias

- `Northwind_DW` reconstruido y validado (scripts de `04_DataWarehouse` y
  `06_Validacion`).
- Fecha de corte aprobada (ver `00_Documentacion/decisiones.md`, D4).

## Trabajo previsto

1. `01_rfm_calculo.sql`: una fila por cliente con
   - `R = DATEDIFF(DAY, MAX(Fecha_Completa), @fecha_corte)`
   - `F = COUNT(DISTINCT OrderID)`
   - `M = SUM(Monto_Total)`
2. `02_rfm_segmentacion.sql`: puntajes 1–5 por quintiles (`NTILE`), puntaje
   combinado y mapa de segmentos (VIP, Frecuentes, En riesgo, Inactivos) con
   umbrales explícitos.
3. `03_rfm_kpis.sql`: los siete KPIs definidos en la Etapa 1.
4. `Northwind_RFM.pbix`: modelo estrella, medidas DAX y dashboard con filtros
   por cliente, país, categoría y periodo.
5. Actualización del informe con resultados, evidencias y recomendaciones.

## Criterios

- La frecuencia cuenta pedidos distintos, no líneas.
- El monto es la suma de `Monto_Total`.
- La recencia se mide contra una fecha de corte documentada, no contra la
  fecha actual.
- No se modifican datos de origen: la Etapa 3 solo lee del DW.
