# Segmentación RFM

Scripts previstos:

- `01_rfm_calculo.sql`: una fila por cliente con recencia, frecuencia y monto.
- `02_rfm_puntajes.sql`: puntajes 1–5 por quintiles (`NTILE`).
- `03_rfm_segmentos.sql`: puntaje combinado y asignación de segmento.

Reglas acordadas:

- Recencia contra la fecha de corte, no contra `GETDATE()`.
- Frecuencia = pedidos distintos (`COUNT(DISTINCT OrderID)`).
- Monto = `SUM(Monto_Total)`.
- Umbrales de segmento explícitos y versionados en el script.

Pendiente: definir la tabla o vista destino (`RFM_Cliente`) y los umbrales.
