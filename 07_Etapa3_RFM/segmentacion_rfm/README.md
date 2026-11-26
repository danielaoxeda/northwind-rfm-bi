# Segmentación RFM

Propuesta de puntajes 1–5 y segmentos excluyentes. **No aprobada todavía.**

| Archivo | Contenido |
|---|---|
| `01_contraste_dax_sql.sql` | Traduce las medidas DAX a SQL y las compara con la referencia |
| `02_propuesta_umbrales.sql` | Distribución real, percentiles, empates, puntajes y segmentos |
| `00_reglas_rfm.md` | Reglas propuestas y análisis de empates |

## Distribución real (89 clientes con compras)

| Métrica | Mín | Máx | Promedio | p20 | p40 | p60 | p80 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Recencia (días) | 1 | 658 | 52,56 | 8 | 16 | 30,8 | 70,4 |
| Frecuencia (pedidos) | 1 | 31 | 9,326 | 5 | 7 | 10 | 13,4 |
| Monto (USD) | 100,80 | 110 277,31 | 14 222,39 | 2 975,56 | 5 182,98 | 11 445,41 | 19 926,91 |

## Propuesta de segmentos (excluyentes por orden)

| Segmento | Regla | Clientes | % de 89 |
|---|---|---:|---:|
| VIP | R ≥ 4, F ≥ 4, M ≥ 4 | 17 | 19,1 % |
| En riesgo | no VIP, R ≤ 2 y (F ≥ 3 o M ≥ 3) | 15 | 16,9 % |
| Frecuentes | no VIP, R ≥ 3 y F ≥ 3 | 19 | 21,3 % |
| Inactivos | resto | 38 | 42,7 % |
| Sin compras | sin filas en hechos | 2 | — |

`Clasificados = 89` y `Sin_Clasificar = 0`: las reglas son mutuamente
excluyentes y cubren a todos los clientes con compras.

Evidencia: `07_Etapa3_RFM/evidencias/2026-11-26_distribucion_rfm.txt`.

Pendiente: aprobación de umbrales, puntajes y nombres de segmento antes de
implementarlos en Power BI.
