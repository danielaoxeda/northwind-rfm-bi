# Northwind RFM — Proyecto de Inteligencia de Negocios

Segmentación de clientes de Northwind mediante el modelo **RFM** (Recencia,
Frecuencia y Monto) sobre un Data Warehouse en esquema estrella.

- **Curso:** Inteligencia de Negocios — Sección 35126
- **Fuente:** base de datos `Northwind` (SQL Server)
- **Staging:** `Northwind_Staging`
- **Data Warehouse:** `Northwind_DW`
- **Repositorio:** `northwind-rfm-bi` (privado)

---

## Estado del proyecto

| Etapa | Estado |
|---|---|
| Etapa 1 — Fundamentación y análisis | Documentada en `00_Documentacion/Informe.docx` |
| Etapa 2 — Diseño, ETL, calidad de datos | Documentada e implementada (scripts + proyectos SSIS) |
| Etapa 3 — Cálculo RFM y dashboard | **Pendiente** (ver `07_Etapa3_RFM/README.md`) |

El informe cubre hasta la sección 2.3.8. La Etapa 3 aún no está redactada.

---

## Estructura

```
00_Documentacion/   Informe y decisiones de diseño
01_Fuente/          Backup de la base operacional (no versionado)
02_Staging/         Creación del staging y extracción
03_Transformacion/  Limpieza, unión y cálculo de TotalVenta
04_DataWarehouse/   DDL y carga del esquema estrella
05_SSIS/            Proyectos SSIS originales (legado)
06_Validacion/      Controles de integridad y reconciliación
07_Etapa3_RFM/      Cálculo RFM, segmentación y Power BI
99_Archivo/         Material histórico y artefactos de build
```

### Orden de ejecución

1. `02_Staging/creacion_BD_Northwind_Staging.sql`
2. `02_Staging/Extraccion_2_2_2_T-SQL.sql`
3. `03_Transformacion/ETL_2_2_4_Transformacion.sql`
4. `04_DataWarehouse/SQL_Hechos_Ventas.sql`
5. `04_DataWarehouse/Carga_2_2_5_T-SQL.sql`
6. `06_Validacion/SQL_2_2_6_Validacion_Nicole.sql`
7. `06_Validacion/SQL_2_3_Integridad_Calidad_Datos.sql`

Los pasos 2 y 5 son la alternativa T-SQL a los paquetes SSIS, necesaria porque
**SSIS no está disponible** en el entorno actual. Los scripts son
re-ejecutables: vacían sus tablas destino antes de cargar.

---

## Requisitos del entorno

| Componente | Estado verificado |
|---|---|
| SQL Server 2025 Developer (`MSSQLSERVER`) | Instalado y en ejecución |
| SQL Server Management Studio 22 | Instalado |
| Visual Studio 2026 Insiders | Instalado |
| Power BI Desktop | Instalado |
| SSIS (servicio y diseñador) | **No disponible** |

El backup `Northwind_Staging.bak` proviene de una instancia SQL Server 2025;
`northwind2024.bak`, de una instancia SQL Server 2019. Ambos requieren
`RESTORE ... WITH MOVE` porque conservan rutas de sus servidores de origen.

---

## Archivos no versionados

Por tamaño se excluyen del repositorio (`ver .gitignore`):

- `01_Fuente/northwind2024.bak`
- `02_Staging/Northwind_Staging.bak`
- `05_SSIS/**/bin`, `obj`, `.vs` y `*.ispac`
- `*.user`, `*.suo`

Los backups **permanecen en el equipo local**. Si se necesita compartirlos,
usar Git LFS o almacenamiento externo; no se deben perder.

---

## Convenciones de trabajo

- Rama principal: `main` (contiene la entrega original tal como se recibió).
- Rama de trabajo: `feature/consolidacion-dw`.
- Commits pequeños, en español, un cambio lógico por commit.
- No se hace `push` sin autorización explícita.

---

## Advertencias conocidas

- El paquete SSIS `05_SSIS/02_Carga_2.2.5` carga `Dim_Tiempo` con claves
  `yyyymmdd` sobre una columna `IDENTITY`, por lo que **no es ejecutable** tal
  como está. La carga vigente es el script T-SQL.
- El modelo vigente usa claves subrogadas `IDENTITY`, según el informe
  (secciones 2.1.5 y 2.1.6) y el DDL de `04_DataWarehouse`.
- La fecha de corte para Recencia está pendiente de definición. Los datos
  terminan el 1998-05-06; usar `GETDATE()` invalidaría el análisis.
