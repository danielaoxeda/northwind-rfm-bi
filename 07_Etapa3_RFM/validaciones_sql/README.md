# Validaciones SQL de la Etapa 3

Controles previstos para asegurar que el cálculo RFM es consistente con el DW:

- Total de clientes en `RFM_Cliente` = clientes con ventas en `Hechos_Ventas`.
- `SUM(Monto)` por cliente = `SUM(Monto_Total)` del DW.
- `SUM(Frecuencia)` = pedidos distintos del DW.
- Recencia mínima ≥ 1 y máxima ≤ rango analizado.
- Ningún cliente con R, F o M nulos.
- Distribución de segmentos y porcentaje por segmento.

Cada control debe indicar el resultado esperado y devolver 0 filas cuando todo
es correcto, siguiendo el estilo de `06_Validacion`.

Pendiente: crear los scripts en la Fase 3.
