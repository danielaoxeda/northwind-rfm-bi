# Etapa 3 — Cálculo RFM, segmentación y dashboard

Artefactos de la Etapa 3. **Todavía no hay scripts ni modelo construidos**;
esta estructura se preparó en la Fase 2 y se completará en la Fase 3, después
de reconstruir y validar `Northwind_DW`.

## Subcarpetas

| Carpeta | Contenido previsto |
|---|---|
| `segmentacion_rfm/` | Scripts de cálculo de R, F, M y asignación de segmentos |
| `validaciones_sql/` | Controles de cuadre del cálculo RFM contra el DW |
| `medidas_dax/` | Medidas DAX documentadas para el modelo de Power BI |
| `power_bi/` | Archivo `.pbix` y recursos del dashboard |
| `evidencias/` | Capturas, resultados y consultas de sustento |

## Definiciones aprobadas

- **Recencia:** días entre la fecha de corte y el último pedido del cliente.
- **Fecha de corte:** última fecha de venta + 1 día (`1998-05-07` con los
  datos actuales).
- **Frecuencia:** `COUNT(DISTINCT OrderID)` por cliente.
- **Monto:** `SUM(Monto_Total)` por cliente.
- **Moneda:** USD, sin conversión.
- **Segmentos:** VIP, Frecuentes, En riesgo e Inactivos, con umbrales
  explícitos y documentados.

## Requisitos de entrada

1. `Northwind_DW` reconstruido (Fase 3).
2. Validaciones de `06_Validacion` sin diferencias.
3. Fecha de corte confirmada.

## Reglas

- No se modifican datos de origen: la Etapa 3 solo lee del DW.
- No se generan datos simulados.
- Toda cifra del informe debe poder reproducirse con un script del repositorio.
