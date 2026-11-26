# Inventario de archivos y política de versionado

Inventario de la entrega recibida, su tamaño y si se versiona en GitHub.

## 1. Archivos versionados

| Ruta | Tamaño | Función |
|---|---:|---|
| `00_Documentacion/Informe.docx` | 4,78 MB | Informe de Etapas 1 y 2 |
| `00_Documentacion/decisiones.md` | < 0,01 MB | Decisiones e inconsistencias |
| `00_Documentacion/inventario_archivos.md` | < 0,01 MB | Este documento |
| `02_Staging/creacion_BD_Northwind_Staging.sql` | < 0,01 MB | DDL del staging |
| `03_Transformacion/ETL_2_2_4_Transformacion.sql` | 0,01 MB | Transformación y rechazos |
| `04_DataWarehouse/SQL_Hechos_Ventas.sql` | < 0,01 MB | DDL del DW |
| `05_SSIS/01_Extraccion_2.2.2/**` | 0,17 MB | Proyecto SSIS de extracción (fuente) |
| `05_SSIS/02_Carga_2.2.5/**` | 0,31 MB | Proyecto SSIS de carga (fuente) |
| `06_Validacion/SQL_2_2_6_Validacion_Nicole.sql` | < 0,01 MB | Validación básica |
| `06_Validacion/SQL_2_3_Integridad_Calidad_Datos.sql` | 0,01 MB | Validación completa |
| `07_Etapa3_RFM/**` | < 0,01 MB | Estructura y documentación de la Etapa 3 |
| `README.md`, `.gitignore`, `.gitattributes` | < 0,01 MB | Documentación y configuración |

Los proyectos SSIS se versionan **solo como código fuente**: `Package.dtsx`,
`.dtproj`, `.slnx`, `.conmgr`, `Project.params` y el archivo `.database`.

## 2. Archivos conservados localmente (no versionados)

| Ruta | Tamaño | Motivo |
|---|---:|---|
| `01_Fuente/northwind2024.bak` | 7,09 MB | Backup binario; respaldo de la fuente |
| `02_Staging/Northwind_Staging.bak` | 5,18 MB | Backup binario; solo contiene `STG_*` |
| `99_Archivo/artefactos/**` | 0,83 MB | `.vs`, `bin`, `obj`, `.ispac`, `*.user` |

Total fuera de Git: **13,10 MB**.

## 3. Comparación con los límites de GitHub

| Límite | Valor | Situación |
|---|---|---|
| Tamaño máximo por archivo | 100 MB (bloqueo) | Ningún archivo lo supera |
| Aviso por archivo | 50 MB | Ningún archivo lo supera |
| Tamaño recomendado del repositorio | < 1 GB | El repositorio versionado ronda los 5,3 MB |

Técnicamente, los backups también podrían versionarse. Se excluyen por política:
son binarios, cambian por completo con cada restauración y no aportan
trazabilidad línea a línea de los scripts.

## 4. Política adoptada

- **Sí se versiona:** scripts SQL, documentación, fuentes de los proyectos SSIS
  y estructura de la Etapa 3.
- **No se versiona:** backups `.bak`, artefactos de compilación e IDE y
  cualquier archivo con credenciales.
- **Backups:** conservar una copia en almacenamiento externo (OneDrive, disco
  externo o Git LFS). El repositorio no debe ser el único lugar donde existen.
- **Power BI:** el `.pbix` se versiona si pesa menos de ~50 MB; si supera ese
  umbral, usar Git LFS o almacenamiento externo.
- **Credenciales:** nunca se almacenan. Las conexiones usan autenticación de
  Windows.

## 5. Procedencia de los backups

| Backup | Base | Servidor de origen | Versión de origen |
|---|---|---|---|
| `northwind2024.bak` | `Northwind` | `DESKTOP-KRD86TL` | SQL Server 2019 (MSSQL15) |
| `Northwind_Staging.bak` | `Northwind_Staging` | `DESKTOP-VJL19IG` | SQL Server 2025 (MSSQL17) |

Al restaurar en la instancia local (`STG_PERU`, SQL Server 2025) se debe usar
`WITH MOVE`, porque las rutas de archivo corresponden a los servidores de
origen.
