# Evidencias

Resultados reales de las consultas de la Etapa 3, ejecutadas sobre
`Northwind_DW` en la instancia local `STG_PERU`.

| Archivo | Origen | Contenido |
|---|---|---|
| `2026-11-26_referencia_rfm.txt` | `validaciones_sql/00_consulta_referencia_rfm.sql` | R, F y M por cliente; 2 sin compras; controles |
| `2026-11-26_distribucion_rfm.txt` | `segmentacion_rfm/02_propuesta_umbrales.sql` | Distribución, percentiles, empates, puntajes y segmentos |
| `2026-11-26_contraste_dax_sql.txt` | `segmentacion_rfm/01_contraste_dax_sql.sql` | Equivalencia SQL de las medidas DAX y matriz de control |

## Convención

```
AAAA-MM-DD_descripcion_corta.txt
AAAA-MM-DD_captura.png
```

Cada evidencia debe indicar el script que la genera, la fecha, la base y la
instancia. No incluir credenciales ni cadenas de conexión con usuarios.
