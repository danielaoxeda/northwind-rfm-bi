# Evidencias RFM/KPI

Salidas SQL reales, ejecutadas en `STG_PERU` / `Northwind_DW`. Las evidencias
validan los datos y la equivalencia SQL. No prueban ejecución de DAX.

| Archivo | Script | Resultado |
|---|---|---|
| `2026-11-26_referencia_rfm.txt` | `validaciones_sql/00_consulta_referencia_rfm.sql` | R/F/M por cliente, 2 sin compras |
| `2026-11-26_segmentos_consolidados.txt` | `segmentacion_rfm/02_propuesta_umbrales.sql` | Distribución de segmentos y activos |
| `2026-11-26_kpi_01_06.txt` | `validaciones_sql/KPI_01_06_referencia.sql` | Referencias SQL KPI 1–6 |
| `2026-11-26_kpi_07_reactivacion.txt` | `validaciones_sql/KPI_07_reactivacion_proxy.sql` | Tasa proxy y eventos históricos |
| `2026-11-26_contraste_dax_sql.txt` | `segmentacion_rfm/01_contraste_dax_sql.sql` | R/F/M base (Fase 6) |
| `2026-11-26_resumen_fase7.txt` | Consolidado | Resultados de segmentos y KPI; declara que DAX no se ejecutó |

Para calcular con otra fecha, modificar el parámetro en el SQL y documentar
el corte; R/F/M, scoring y actividad son relativos a esa fecha.
