# Lógica RFM consolidada

Umbrales aprobados, límites exactos, exclusividad y distribución: ver
`00_reglas_rfm.md`.

| Archivo | Función |
|---|---|
| `00_reglas_rfm.md` | Reglas aprobadas, scores, segmentos y excepciones |
| `01_contraste_dax_sql.sql` | Contraste de métricas R/F/M base |
| `02_propuesta_umbrales.sql` | SQL de solo lectura con distribución actual de segmentos |

## Resultados al corte 1998-05-07

- 89 clientes con compras; 2 sin compras (FISSA 22, PARIS 57).
- 67 activos (R≤60); 22 no activos.
- Segmentos: 17 VIP (19,1 %), 28 Activos (31,5 %), 22 Ocasionales (24,7 %),
  5 En riesgo (5,6 %), 2 Frecuentes (2,2 %), 15 Inactivos (16,9 %).
- VIP: 17/89 = 19,10 % de clientes con compras.

`Activo` incluye compradores recientes no VIP de intensidad media/alta;
`Ocasional` identifica compradores recientes de baja F y M. Ningún cliente
con compra en los últimos 60 días aparece como Inactivo, En riesgo o Frecuente.

## Estado DAX

Las expresiones se encuentran en `../medidas_dax/02_puntuacion_rfm.dax` y
`03_segmentacion.dax`. Se han contrastado las reglas equivalentes en SQL; la
ejecución real de DAX requiere validación manual en Power BI Desktop.
