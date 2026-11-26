# Etapa 3 — Cálculo RFM, segmentación y dashboard

Artefactos de la Etapa 3. Las medidas base, la propuesta de segmentos y el
contraste con SQL están listos. El dashboard y los siete KPI comprendidos
siguen pendientes de aprobación.

## Subcarpetas

| Carpeta | Contenido |
|---|---|
| `segmentacion_rfm/` | Reglas propuestas, análisis de umbrales y contraste DAX/SQL |
| `validaciones_sql/` | Consulta de referencia R, F y M contra el DW |
| `medidas_dax/` | Medidas DAX base para Power BI |
| `power_bi/` | Recursos del dashboard y decisión sobre PBIP |
| `evidencias/` | Resultados reales de las validaciones |

## Definiciones aprobadas

- **Recencia:** días entre la fecha de corte y la última compra del cliente.
- **Fecha de corte:** última fecha de venta + 1 día (**1998-05-07**).
- **Frecuencia:** `COUNT(DISTINCT OrderID)` por cliente.
- **Monto:** `SUM(Monto_Total)` por cliente.
- **Moneda:** USD, sin conversión.

## Estado real (Fase 6)

| Elemento | Estado |
|---|---|
| Medidas DAX R, F, M | Implementadas en `.dax`, validadas por equivalencia SQL |
| Importación del XLSX | Validada estructuralmente; apertura visual pendiente |
| Modelo estrella | Especificado, pendiente de construir en Power BI |
| Umbrales 1–5 | Propuestos, **sin aprobar** |
| Segmentos | Propuestos y excluyentes, **sin aprobar** |
| PBIP | Evaluado y recomendado; no generado |
| 7 KPI | Analizados; no implementados |

`07_Etapa3_RFM/modelo_power_bi.md` contiene los pasos manuales exactos y la
matriz de validación esperada.

## Reglas

- No se modifican datos de origen: la Etapa 3 solo lee del DW.
- No se generan datos simulados.
- Toda cifra del informe debe poder reproducirse con un script del repositorio.
- Los umbrales y segmentos no se publican hasta su aprobación.
