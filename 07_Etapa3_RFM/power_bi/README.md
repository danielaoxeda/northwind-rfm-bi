# Power BI

Recursos del dashboard de la Etapa 3.

## Estado

El modelo está especificado y las medidas base están listas, pero **no se ha
creado el archivo de Power BI** en esta fase. La construcción requiere Power BI
Desktop y la aprobación de los umbrales RFM.

## Formato recomendado: PBIP

Se evaluó el formato **Power BI Project (PBIP)** y se recomienda adoptarlo:

- Versiona el modelo como texto TMDL (medidas y relaciones con diffs legibles).
- Facilita la revisión en GitHub y reduce conflictos en las medidas.
- Requiere Power BI Desktop para crear y probar.
- El reporte visual sigue siendo JSON y puede presentar conflictos de diseño.

Estructura prevista:

```
07_Etapa3_RFM/power_bi/Northwind_RFM.pbip
07_Etapa3_RFM/power_bi/Northwind_RFM.SemanticModel/definition/*.tmdl
07_Etapa3_RFM/power_bi/Northwind_RFM.Report/definition/**
```

No se genera un PBIP ni un PBIX vacío o inválido: debe crearse desde Power BI
Desktop cuando el modelo esté aprobado.

## Contenido previsto del dashboard

- Tarjetas de clientes totales, con compras y sin compras.
- Distribución de segmentos (VIP, frecuentes, en riesgo, inactivos).
- Recencia, frecuencia y monto promedio por segmento.
- Detalle por cliente con filtros de país, categoría y periodo.

## Instrucciones

Ver `../modelo_power_bi.md`: importación del XLSX, tipos de datos, relaciones,
tabla de fechas, medidas DAX, validación y trabajo colaborativo.

## Buenas prácticas

- No almacenar credenciales en el archivo ni en el repositorio.
- Excluir cachés (`.pbi/`, `*.pbix.tmp`) y versionar solo la definición.
- Documentar el origen de cada visual en `../evidencias/`.
