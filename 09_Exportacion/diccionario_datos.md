# Diccionario de datos — `Northwind_DW`

Define las cuatro tablas exportadas a `Northwind_DW.xlsx` y `csv/`. Los tipos
corresponden a SQL Server; entre paréntesis, el tipo recomendado en Power BI.

- **PK**: clave primaria.
- **FK**: clave foránea hacia otra tabla.
- **Natural**: identificador de origen que no es la clave del DW.
- **Nulo**: si admite valores nulos.

---

## `Dim_Cliente` — 91 filas

| # | Columna | Tipo SQL | Power BI | Clave | Nulo | Descripción |
|---:|---|---|---|---|---|---|
| 1 | `ID_Cliente` | `INT` | Número entero | PK | No | Clave subrogada del cliente en el DW (IDENTITY, 1–91). |
| 2 | `ID_Cliente_Northwind` | `NCHAR(5)` | Texto | Natural | No | Código de cliente de Northwind (`ALFKI`, `ANATR`, …). Se exporta sin relleno de espacios. |
| 3 | `Nombre_Empresa` | `NVARCHAR(100)` | Texto | — | Sí | Razón social del cliente. |
| 4 | `Pais` | `NVARCHAR(50)` | Texto | — | Sí | País de la empresa. |
| 5 | `Ciudad` | `NVARCHAR(50)` | Texto | — | Sí | Ciudad de la empresa. |

## `Dim_Producto` — 77 filas

| # | Columna | Tipo SQL | Power BI | Clave | Nulo | Descripción |
|---:|---|---|---|---|---|---|
| 1 | `ID_Producto` | `INT` | Número entero | PK | No | Clave subrogada del producto en el DW (IDENTITY, 1–77). |
| 2 | `ID_Producto_Northwind` | `INT` | Número entero | Natural | No | `ProductID` original de Northwind. |
| 3 | `Nombre_Producto` | `NVARCHAR(100)` | Texto | — | No | Nombre comercial del producto. |
| 4 | `Categoria` | `NVARCHAR(100)` | Texto | — | Sí | Categoría leída de `Northwind.dbo.Categories`. |

## `Dim_Tiempo` — 672 filas

Calendario continuo del 1996-07-04 al 1998-05-06, sin huecos.

| # | Columna | Tipo SQL | Power BI | Clave | Nulo | Descripción |
|---:|---|---|---|---|---|---|
| 1 | `ID_Tiempo` | `INT` | Número entero | PK | No | Fecha inteligente `AAAAMMDD` (p. ej. `19960704`). Sin IDENTITY. |
| 2 | `Fecha_Completa` | `DATE` | Fecha | — | No | Fecha calendario. **Marcar como tabla de fechas.** |
| 3 | `Dia` | `TINYINT` | Número entero | — | No | Día del mes (1–31). |
| 4 | `Mes` | `TINYINT` | Número entero | — | No | Número de mes (1–12). Ordena `Nombre_Mes`. |
| 5 | `Nombre_Mes` | `NVARCHAR(15)` | Texto | — | No | Nombre del mes en español. |
| 6 | `Trimestre` | `TINYINT` | Número entero | — | No | Trimestre (1–4). |
| 7 | `Anio` | `SMALLINT` | Número entero | — | No | Año calendario. |

> En Power BI, ordenar `Nombre_Mes` por `Mes` y `Trimestre` por sí mismo. No
> crear relación entre dimensiones.

## `Hechos_Ventas` — 2155 filas

Grano: una fila por línea de pedido `(OrderID, ProductID)`.

| # | Columna | Tipo SQL | Power BI | Clave | Nulo | Descripción |
|---:|---|---|---|---|---|---|
| 1 | `ID_Hecho_Venta` | `BIGINT` | Número entero | PK | No | Clave subrogada de la línea de venta (IDENTITY). |
| 2 | `ID_Tiempo` | `INT` | Número entero | FK → `Dim_Tiempo` | No | Fecha de la venta en formato `AAAAMMDD`. |
| 3 | `ID_Cliente` | `INT` | Número entero | FK → `Dim_Cliente` | No | Cliente que realizó el pedido. |
| 4 | `ID_Producto` | `INT` | Número entero | FK → `Dim_Producto` | No | Producto vendido. |
| 5 | `OrderID` | `INT` | Número entero | Natural | No | Número de pedido de Northwind. |
| 6 | `ProductID` | `INT` | Número entero | Natural | No | `ProductID` de Northwind. Junto con `OrderID` identifica la línea. |
| 7 | `Cantidad` | `SMALLINT` | Número entero | — | No | Unidades vendidas. |
| 8 | `Precio_Unitario` | `DECIMAL(19,4)` | Número decimal fijo | — | No | Precio unitario en USD. |
| 9 | `Descuento` | `DECIMAL(9,6)` | Número decimal fijo | — | No | Descuento como fracción (0–1). |
| 10 | `Monto_Total` | `DECIMAL(19,4)` | Número decimal fijo | — | No | `Precio_Unitario × Cantidad × (1 − Descuento)`, redondeado a 4 decimales, en USD. |

## Relaciones del modelo

```
Dim_Cliente  (1) ───< (N) Hechos_Ventas
Dim_Producto (1) ───< (N) Hechos_Ventas
Dim_Tiempo   (1) ───< (N) Hechos_Ventas
```

Todas son de uno a varios, dirección única desde la dimensión hacia los hechos.

## Notas de exportación

- **CSV:** UTF-8 con BOM, separador coma, fechas `AAAA-MM-DD` y decimales con
  punto. Los campos de texto con espacios finales de origen (`NCHAR`) se
  exportan recortados.
- **XLSX:** los enteros y decimales son celdas numéricas; `Fecha_Completa` es
  una fecha real de Excel (formato `aaaa-mm-dd`); los textos son cadenas.
- **Importes:** en USD; no se convierten ni se redondean a 2 decimales en el
  archivo (se conservan 4).
