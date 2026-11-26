# Northwind RFM — Proyecto de Inteligencia de Negocios

Segmentación de clientes de Northwind mediante el modelo **RFM** (Recencia,
Frecuencia y Monto) sobre un Data Warehouse en esquema estrella.

| | |
|---|---|
| Curso | Inteligencia de Negocios — Sección 35126 |
| Fuente | `Northwind` (SQL Server) |
| Staging | `Northwind_Staging` |
| Data Warehouse | `Northwind_DW` |
| Visualización | Power BI Desktop |
| Repositorio | `northwind-rfm-bi` (privado) |

---

## Estado

| Fase | Estado |
|---|---|
| Etapa 1 — Fundamentación y análisis | Documentada |
| Etapa 2 — Diseño, ETL y calidad de datos | Documentada; scripts y proyectos SSIS recibidos |
| Fase 2 — Entorno y organización | Completada |
| Fase 3 — Unificación y corrección de scripts | Completada |
| Fase 4 — Reconstrucción completa del DW | **Completada** (esta fase) |
| Etapa 3 — RFM y dashboard | Pendiente |

El informe cubre hasta la sección 2.3.8. La Etapa 3 aún no está redactada.

---

## Entorno verificado

| Componente | Valor |
|---|---|
| SQL Server | 2025 RTM, 17.0.1000.7, Developer Edition (64 bits) |
| Instancia | Predeterminada (`MSSQLSERVER`), servidor `STG_PERU` |
| Servicio | `MSSQLSERVER` en ejecución, inicio automático |
| Autenticación | Windows (`STG_PERU\STG`) |
| `sqlcmd` | 17.0.1000.7, en `Client SDK\ODBC\180\Tools\Binn` |
| SSMS | 22.12.1 |
| Visual Studio | 2026 Insiders |
| SSIS | **No disponible** |
| Power BI Desktop | Instalado |

Bases tras la Fase 4: `Northwind` y `Northwind_Staging` cargadas y
`Northwind_DW` reconstruido y verificado. La reconstrucción se ejecutó dos
veces con resultado idéntico y se generó un backup validado en
`08_Backups/Northwind_DW.bak` (fuera de Git).

---

## Estructura

```
00_Documentacion/   Informe, decisiones e inventario de archivos
01_Fuente/          Backup de la base operacional (no versionado)
02_Staging/         Creación del staging y backup del staging
03_Transformacion/  Limpieza, unión y cálculo de TotalVenta
04_DataWarehouse/   DDL del esquema estrella
05_SSIS/            Proyectos SSIS originales (evidencia de la Etapa 2)
06_Validacion/      Controles de integridad, reconciliación y evidencias
07_Etapa3_RFM/      Cálculo RFM, DAX, Power BI y evidencias
08_Backups/         Backup de Northwind_DW (no versionado)
99_Archivo/         Artefactos de compilación e IDE (no versionados)
```

### Archivos principales

| Archivo | Función |
|---|---|
| `01_Fuente/northwind2024.bak` | Backup de `Northwind` (SQL Server 2019, externo a Git) |
| `02_Staging/Northwind_Staging.bak` | Backup de staging, solo tablas `STG_*` (SQL Server 2025, externo a Git) |
| `02_Staging/creacion_BD_Northwind_Staging.sql` | Crea la base de staging y las 4 tablas espejo (idempotente) |
| `02_Staging/Extraccion_2_2_2_T-SQL.sql` | Extracción T-SQL equivalente al paquete SSIS |
| `03_Transformacion/ETL_2_2_4_Transformacion.sql` | Genera `TRF_*` y `TRF_Rechazados`; controles de cuadre |
| `04_DataWarehouse/SQL_Hechos_Ventas.sql` | DDL de dimensiones y `Hechos_Ventas` (`ID_Tiempo` AAAAMMDD) |
| `04_DataWarehouse/02_Carga_Dimensiones.sql` | Carga dimensiones y calendario continuo (reproducible) |
| `04_DataWarehouse/03_Carga_Hechos.sql` | Carga hechos con integridad referencial (reproducible) |
| `06_Validacion/SQL_2_2_6_Validacion_Nicole.sql` | Conteos, huérfanos y suma total |
| `06_Validacion/SQL_2_3_Integridad_Calidad_Datos.sql` | Integridad, duplicados, cálculos y reconciliación |
| `00_Ejecutar_Reconstruccion.sql` | Script maestro con el orden de ejecución completo |

---

## Modelo dimensional

Esquema estrella con grano por línea de pedido `(OrderID, ProductID)`.

- `Dim_Cliente`: clave subrogada `ID_Cliente` (IDENTITY) + `ID_Cliente_Northwind`.
- `Dim_Producto`: clave subrogada `ID_Producto` (IDENTITY) + `ID_Producto_Northwind`.
- `Dim_Tiempo`: clave `ID_Tiempo` con formato `AAAAMMDD`, **sin IDENTITY**, y
  calendario continuo.
- `Hechos_Ventas`: `ID_Hecho_Venta` (IDENTITY), tres FK, medidas `Cantidad`,
  `Precio_Unitario`, `Descuento`, `Monto_Total`.

`Monto_Total = Precio_Unitario × Cantidad × (1 − Descuento)`, redondeado a
4 decimales. Los importes se conservan en USD.

> El DDL ya aplica la clave `AAAAMMDD` sin `IDENTITY` y una restricción
> `CK_Dim_Tiempo_ID` que la garantiza. Ver `00_Documentacion/cambios_fase3.md`.

---

## Resultado de la reconstrucción (Fase 4)

Ejecutada dos veces el 2026-11-26 sobre `STG_PERU`, sin errores y con resultado
idéntico entre ambas corridas:

| Tabla | Filas | Clave mín.–máx. | Checksum |
|---|---:|---|---:|
| `Dim_Cliente` | 91 | 1 – 91 | `-1744422070` |
| `Dim_Producto` | 77 | 1 – 77 | `-1572385952` |
| `Dim_Tiempo` | 672 | 19960704 – 19980506 | `-1315692542` |
| `Hechos_Ventas` | 2155 | 1 – 2155 | `303468615` |

- `830` pedidos distintos, `51 317` unidades, monto **`1 265 793,0395`** (USD).
- Reconciliación contra `Northwind`: 89 clientes con ventas, 77 productos,
  2155 líneas y el mismo monto.
- Controles en cero: huérfanos, duplicados `(OrderID, ProductID)`, nulos,
  cantidades no positivas, precios/montos negativos, descuentos fuera de rango,
  claves de tiempo inválidas y huecos de calendario.

Evidencias en `06_Validacion/evidencias/`.

---

## Procedimiento de reconstrucción

SSIS no está disponible, por lo que la extracción y la carga se hacen con
scripts T-SQL. El script maestro `00_Ejecutar_Reconstruccion.sql` ejecuta el
orden completo (desde la raíz del repositorio, porque usa rutas `:r` relativas):

1. Restaurar `01_Fuente/northwind2024.bak` como base `Northwind`
   (`RESTORE ... WITH MOVE`; la copia debe ser legible por la cuenta del
   servicio `NT Service\MSSQLSERVER`). Solo si la base no existe.
2. Crear/recrear el staging con `02_Staging/creacion_BD_Northwind_Staging.sql`.
3. Extraer con `02_Staging/Extraccion_2_2_2_T-SQL.sql`.
4. Transformar con `03_Transformacion/ETL_2_2_4_Transformacion.sql`.
5. Crear el DW con `04_DataWarehouse/SQL_Hechos_Ventas.sql`.
6. Cargar dimensiones y calendario con `04_DataWarehouse/02_Carga_Dimensiones.sql`.
7. Cargar hechos con `04_DataWarehouse/03_Carga_Hechos.sql`.
8. Validar con los scripts de `06_Validacion`.
9. Generar un backup de `Northwind_DW` (ver `08_Backups/`).

La reconstrucción ya se ejecutó y validó. Puede repetirse sin duplicar datos.

---

## Repositorio

- Rama principal: `main` (entrega original sin reorganizar).
- Rama de trabajo: `feature/consolidacion-dw`.
- Commits pequeños, en español, un cambio lógico por commit.
- Sin `push` hasta autorización.
- Remoto `origin`: `https://github.com/danielaoxeda/northwind-rfm-bi.git`.

### Archivos fuera de Git

Por tamaño o por ser artefactos generados:

- `01_Fuente/northwind2024.bak` (7,1 MB)
- `02_Staging/Northwind_Staging.bak` (5,2 MB)
- `08_Backups/Northwind_DW.bak` (0,72 MB, verificado)
- `99_Archivo/artefactos/**` (`.vs`, `bin`, `obj`, `.ispac`, `*.user`)

Se conservan en el equipo local y deben respaldarse por separado. Ver
`00_Documentacion/inventario_archivos.md`.

---

## Advertencias

- El paquete SSIS `05_SSIS/02_Carga_2.2.5` no es ejecutable tal como está
  (clave de tiempo incompatible y cargas no idempotentes). Se conserva como
  evidencia.
- El backup de staging contiene solo `STG_*`: la transformación debe
  ejecutarse de nuevo.
- No existen credenciales en el repositorio; las conexiones usan autenticación
  de Windows.
