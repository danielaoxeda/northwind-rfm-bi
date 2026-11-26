# Modelo Power BI — construcción manual y colaboración

Esta guía prepara Power BI Desktop desde `09_Exportacion/Northwind_DW.xlsx`.
La estructura OOXML fue validada, pero la apertura visual, ejecución DAX y
guardado PBIP/PBIX requieren intervención manual. No se afirma que DAX haya
sido ejecutado.

## 1. Importar y tipar

1. Abrir Power BI Desktop → **Inicio → Obtener datos → Libro de Excel**.
2. Elegir `09_Exportacion/Northwind_DW.xlsx` → **Conectar**.
3. Seleccionar las cuatro hojas (`Dim_Cliente`, `Dim_Producto`, `Dim_Tiempo`,
   `Hechos_Ventas`) → **Transformar datos**.
4. En Power Query asignar:
   - `Fecha_Completa`: **Fecha**.
   - Identificadores, claves, `OrderID`, `ProductID`, `Cantidad`, día/mes/año:
     **Número entero** (BigInt ID_Hecho_Venta como entero de 64 bits).
   - `Precio_Unitario`, `Monto_Total`, `Descuento`: **Número decimal fijo**.
   - Resto: **Texto**.
5. **Cerrar y aplicar**. Verificar 91 / 77 / 672 / 2155 filas.

## 2. Modelo estrella

Vista **Modelo**, crear relaciones activas, uno a varios y filtro unidireccional:

| Tabla (1) | Tabla (*) | Columna |
|---|---|---|
| `Dim_Cliente` | `Hechos_Ventas` | `ID_Cliente` |
| `Dim_Producto` | `Hechos_Ventas` | `ID_Producto` |
| `Dim_Tiempo` | `Hechos_Ventas` | `ID_Tiempo` |

No relacionar dimensiones entre sí. No usar filtro bidireccional.

Seleccionar `Dim_Tiempo` → **Herramientas de tabla → Marcar como tabla de
fechas → Fecha_Completa**. Ordenar `Nombre_Mes` por `Mes`; opcionalmente crear
jerarquía `Anio > Trimestre > Mes > Fecha_Completa`.

## 3. Crear DAX (borradores; validar uno por uno)

1. **Modelado → Nueva tabla**: pegar `Cliente_RFM` de
   `medidas_dax/00_tabla_cliente_rfm.dax`.
2. Seleccionar `Cliente_RFM` → **Nueva columna**: crear las columnas de
   `02_puntuacion_rfm.dax`.
3. Crear columnas `Segmento` y `Estado_Actividad` desde `03_segmentacion.dax`.
4. Crear medidas de `01_medidas_base.dax` y después las medidas KPI de cada
   `KPI_*.dax`. Pegar una definición por medida, sin el comentario introductorio.
5. Mantener `Cliente_RFM` desconectada. Formato: importes en USD; R entero;
   tasas como porcentaje.

### Valores SQL de referencia (no resultados ejecutados por DAX)

| Medida/KPI | Referencia SQL |
|---|---:|
| Corte | 1998-05-07 |
| Compradores / sin compras | 89 / 2 |
| Activos R≤60 / recencia promedio activa | 67 / 19,64 días |
| Frecuencia total / monto total | 830 / USD 1 265 793,0395 |
| Segmentos actuales | VIP 17; Activo 28; Ocasional 22; En riesgo 5; Frecuente 2; Inactivo 15 |
| KPI 1 | 67 activos; promedio activo 19,64 |
| KPI 2 | 8 Q1-1997 vs 30 Q1-1998 |
| KPI 3 | USD 51 380,0200 vs USD 38 656,6275 |
| KPI 4 | Ticket USD 1 525,051854; meta USD 500 |
| KPI 5 | 17/89 = 19,10 % |
| KPI 6 | 7 vs 6 clientes riesgo |
| KPI 7 | Proxy 69/89 = 77,53 % |

Resultados SQL reales en `evidencias/2026-11-26_kpi_01_06.txt`,
`evidencias/2026-11-26_kpi_07_reactivacion.txt` y
`evidencias/2026-11-26_segmentos_consolidados.txt`.

## 4. PBIP y entrega PBIX

PBIP se recomienda para el trabajo en Git: modelo TMDL legible/diffeable y
report definition JSON. Requiere Desktop; no se puede fabricar con seguridad
desde scripts. Pasos:

1. Completar la importación, relaciones y DAX de arriba.
2. Validar manualmente los resultados contra las referencias SQL; corregir
   errores y guardar.
3. **Archivo → Guardar como → Power BI Project (*.pbip)**.
4. Guardar en `07_Etapa3_RFM/power_bi/Northwind_RFM.pbip`.
5. Cerrar Desktop; comprobar `.pbip`, carpetas `.SemanticModel` y `.Report`,
   definiciones TMDL/JSON; abrir nuevamente el PBIP y refrescar.
6. Versionar PBIP y definiciones. Excluir cachés (`.pbi/`) y credenciales.
7. Para entrega binaria, abrir el PBIP revisado → **Archivo → Guardar como →
   Power BI Desktop (.pbix)** → `Northwind_RFM.pbix`.
8. Abrir el PBIX, refrescar, validar y revisar que no guarde credenciales.
   El PBIX se entrega después de la revisión del PBIP.

No hay PBIP/PBIX creado en este repo todavía. No se debe versionar un archivo
vacío o inválido.

## 5. Colaboración

- Compartir la rama `feature/consolidacion-dw`; no hacer push sin autorización.
- Commits pequeños: modelo, medidas, reglas, visuales.
- Regenerar XLSX/CSV con `09_Exportacion/exportar_datos.ps1`, verificar con
  `verificar_exportacion.py`, actualizar en Power BI.
- Revisar diffs TMDL al cambiar medidas; resolver a mano conflictos JSON del
  reporte.
- No versionar `.bak`, credenciales ni cachés.

## 6. Aprobaciones ya registradas y límites

- Umbrales R/F/M, actividad ≤60 días, definición de segmentos y denominador
  VIP están consolidados en `segmentacion_rfm/00_reglas_rfm.md`.
- La meta ticket se expresa como **USD 500**, nueva meta en moneda nativa, no
  conversión de S/ 500.
- KPI 3/6 usan ventanas comparables completas; KPI 7 es proxy histórico y no
  mide impacto causal de campañas.
- La apertura visual, validación DAX y guardado PBIP/PBIX son tareas manuales.
