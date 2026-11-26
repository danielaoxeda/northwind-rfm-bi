# Validaciones SQL de la Etapa 3

Controles para asegurar que el cálculo RFM sea consistente con el DW:

- Total de clientes = clientes con ventas + clientes sin compras.
- `SUM(Monto)` por cliente = `SUM(Monto_Total)` del DW.
- `SUM(Frecuencia)` = pedidos distintos del DW.
- Recencia mínima ≥ 1 y máxima ≤ rango analizado.
- Ningún cliente con compras y R, F o M nulos.
- Distribución de segmentos y porcentaje por segmento.

## Consulta de referencia

`00_consulta_referencia_rfm.sql` calcula R, F y M por cliente usando la fecha
de corte **1998-05-07** (última venta + 1 día), sin puntajes ni segmentos:

1. Clientes con compras (89).
2. Clientes sin compras, identificados aparte: **FISSA (22)** y **PARIS (57)**.
3. Vista combinada de los 91 clientes con indicador `Tiene_Compras`.
4. Controles de cuadre (91 / 89 / 2 / 830 / 1 265 793,0395 / recencia 1–658).

Resultado real guardado en `07_Etapa3_RFM/evidencias/2026-11-26_referencia_rfm.txt`.

Pendiente para la Etapa 3: puntajes por quintiles y asignación de segmentos.
