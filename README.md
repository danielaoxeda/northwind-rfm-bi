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
| Fase 2 — Entorno y organización | **Completada** (esta fase) |
| Fase 3 — Reconstrucción del DW | Pendiente |
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

Bases existentes al inicio de la Fase 2: solo las del sistema (`master`,
`tempdb`, `model`, `msdb`). `Northwind`, `Northwind_Staging` y `Northwind_DW`
aún no están restauradas.

---

## Estructura

```
00_Documentacion/   Informe, decisiones e inventario de archivos
01_Fuente/          Backup de la base operacional (no versionado)
02_Staging/         Creación del staging y backup del staging
03_Transformacion/  Limpieza, unión y cálculo de TotalVenta
04_DataWarehouse/   DDL del esquema estrella
05_SSIS/            Proyectos SSIS originales (evidencia de la Etapa 2)
06_Validacion/      Controles de integridad y reconciliación
07_Etapa3_RFM/      Cálculo RFM, DAX, Power BI y evidencias
99_Archivo/         Artefactos de compilación e IDE (no versionados)
```

### Archivos principales

| Archivo | Función |
|---|---|
| `01_Fuente/northwind2024.bak` | Backup de `Northwind` (SQL Server 2019, externo a Git) |
| `02_Staging/Northwind_Staging.bak` | Backup de staging, solo tablas `STG_*` (SQL Server 2025, externo a Git) |
| `02_Staging/creacion_BD_Northwind_Staging.sql` | Crea la base de staging y las 4 tablas espejo |
| `03_Transformacion/ETL_2_2_4_Transformacion.sql` | Genera `TRF_*` y `TRF_Rechazados`; controles de cuadre |
| `04_DataWarehouse/SQL_Hechos_Ventas.sql` | DDL de dimensiones y `Hechos_Ventas` |
| `06_Validacion/SQL_2_2_6_Validacion_Nicole.sql` | Conteos, huérfanos y suma total |
| `06_Validacion/SQL_2_3_Integridad_Calidad_Datos.sql` | Integridad, duplicados, cálculos y reconciliación |

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

> El DDL actual todavía define `ID_Tiempo` como IDENTITY. La corrección
> corresponde a la Fase 3 y está registrada en `00_Documentacion/decisiones.md`.

---

## Procedimiento de reconstrucción (previsto para Fase 3)

SSIS no está disponible, por lo que la extracción y la carga se harán con
scripts T-SQL. El orden será:

1. Restaurar `01_Fuente/northwind2024.bak` como base `Northwind`
   (`RESTORE ... WITH MOVE`, por las rutas del servidor de origen).
2. Ejecutar `02_Staging/creacion_BD_Northwind_Staging.sql`.
3. Poblar el staging: restaurar `02_Staging/Northwind_Staging.bak` o ejecutar
   el script de extracción T-SQL (a crear).
4. Ejecutar `03_Transformacion/ETL_2_2_4_Transformacion.sql`.
5. Ajustar y ejecutar el DDL de `04_DataWarehouse` (clave `AAAAMMDD`, sin
   IDENTITY, calendario continuo) y la carga T-SQL (a crear).
6. Ejecutar las validaciones de `06_Validacion`.
7. Generar un backup de `Northwind_DW`.

Ninguno de estos pasos se ha ejecutado todavía: requieren autorización expresa.

---

## Repositorio

- Rama principal: `main` (entrega original sin reorganizar).
- Rama de trabajo: `feature/consolidacion-dw`.
- Commits pequeños, en español, un cambio lógico por commit.
- Sin `push` hasta autorización.
- `origin` pendiente: no se recibió una URL válida del repositorio.

### Archivos fuera de Git

Por tamaño o por ser artefactos generados:

- `01_Fuente/northwind2024.bak` (7,1 MB)
- `02_Staging/Northwind_Staging.bak` (5,2 MB)
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
