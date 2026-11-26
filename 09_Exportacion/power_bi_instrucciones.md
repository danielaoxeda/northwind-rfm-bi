# Instrucciones para Power BI Desktop

Cómo importar las tablas exportadas y configurar el modelo estrella. Aplica
tanto al libro `Northwind_DW.xlsx` como a los CSV de `csv/`.

---

## 1. Importar desde Excel (recomendado)

1. Abrir Power BI Desktop → **Inicio → Obtener datos → Libro de Excel**.
2. Seleccionar `09_Exportacion/Northwind_DW.xlsx`.
3. En el navegador, marcar las cuatro hojas: `Dim_Cliente`, `Dim_Producto`,
   `Dim_Tiempo` y `Hechos_Ventas`.
4. Pulsar **Transformar datos** (no "Cargar" directo) y revisar:
   - `Dim_Tiempo[Fecha_Completa]` debe ser tipo **Fecha**.
   - `ID_Tiempo`, `ID_Cliente`, `ID_Producto`, `OrderID`, `ProductID`,
     `Cantidad`, `Dia`, `Mes`, `Trimestre`, `Anio`: **Número entero**.
   - `ID_Hecho_Venta`: **Número entero** (64 bits si Power BI lo solicita).
   - `Precio_Unitario`, `Monto_Total`, `Descuento`: **Número decimal fijo**.
   - Columnas de texto: **Texto**.
5. **Cerrar y aplicar**.

## 2. Importar desde CSV

1. **Obtener datos → Carpeta** y apuntar a `09_Exportacion/csv/`.
2. **Combinar y transformar**.
3. Origen: **Archivo CSV**, delimitador **coma**, codificación **65001: Unicode
   (UTF-8)**.
4. Confirmar que la primera fila se usa como encabezado y aplicar los mismos
   tipos del punto 1.

> Si se importa un solo archivo: **Obtener datos → Texto/CSV**, seleccionar el
> archivo y usar la misma codificación.

## 3. Relaciones

En la vista **Modelo**, crear tres relaciones:

| Desde (varios) | Hacia (uno) | Cardinalidad | Dirección |
|---|---|---|---|
| `Hechos_Ventas[ID_Cliente]` | `Dim_Cliente[ID_Cliente]` | Varios a uno (*:1) | Única |
| `Hechos_Ventas[ID_Producto]` | `Dim_Producto[ID_Producto]` | Varios a uno (*:1) | Única |
| `Hechos_Ventas[ID_Tiempo]` | `Dim_Tiempo[ID_Tiempo]` | Varios a uno (*:1) | Única |

Comprobar que Power BI detectó la cardinalidad y el filtro correctos. No crear
relaciones entre las dimensiones.

## 4. Tabla de fechas

1. Seleccionar `Dim_Tiempo`.
2. **Herramientas de tabla → Marcar como tabla de fechas → Fecha_Completa**.
3. Ordenar `Nombre_Mes` por `Mes` (**Herramientas de columna → Ordenar por
   columna**).
4. Opcional: crear una jerarquía `Anio → Trimestre → Mes → Fecha_Completa`.

## 5. Ajustes de presentación

- Ocultar de la vista de informe las claves técnicas: `ID_Cliente`,
  `ID_Producto`, `ID_Tiempo`, `ID_Hecho_Venta`, `OrderID`, `ProductID`.
- Formato de `Monto_Total`, `Precio_Unitario`: **moneda**, 2 decimales, símbolo
  `$` (USD). El valor subyacente conserva 4 decimales.
- `Descuento`: porcentaje con 2 decimales.
- Renombrar tablas si se desea, sin cambiar los nombres de columna usados por
  las relaciones.

## 6. Actualizar los datos

1. Reejecutar la exportación desde la raíz del repositorio:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\09_Exportacion\exportar_datos.ps1
   ```

2. En Power BI: **Inicio → Actualizar**.

Si se movió el archivo, actualizar la ruta en **Transformar datos → Origen**.

## 7. Validación rápida del modelo

- `Hechos_Ventas` debe tener **2155** filas.
- `Dim_Cliente` **91**, `Dim_Producto` **77**, `Dim_Tiempo` **672**.
- `SUM(Hechos_Ventas[Monto_Total])` = **1 265 793,0395**.
- `DISTINCTCOUNT(Hechos_Ventas[OrderID])` = **830**.
- Las tres relaciones deben mostrar **sin errores de integridad**.

## 8. Compartir con el equipo

- El `.xlsx` y los CSV están versionados en Git (peso total < 1 MB).
- No incluir el `.pbix` con credenciales; la conexión usa los archivos
  exportados, no la base directamente.
- Para compartir el dashboard, publicar el `.pbix` en el área de trabajo de
  Power BI o adjuntarlo al repositorio si pesa menos de ~50 MB.
