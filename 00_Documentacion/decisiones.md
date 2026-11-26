# Decisiones de diseño y alcance

Registro de las decisiones tomadas durante la consolidación del proyecto.
Cada decisión indica su estado y su justificación.

---

## D1 — Claves subrogadas en las dimensiones

**Estado:** adoptada.

`Dim_Cliente`, `Dim_Tiempo` y `Dim_Producto` usan una clave subrogada
`INT IDENTITY` como clave primaria, y conservan el identificador de Northwind
en una columna independiente (`ID_Cliente_Northwind`, `ID_Producto_Northwind`).
Para `Dim_Tiempo`, la clave natural es `Fecha_Completa`.

**Motivo:** es el modelo documentado en el informe (secciones 2.1.5 y 2.1.6) y
el implementado en `04_DataWarehouse/SQL_Hechos_Ventas.sql`.

**Consecuencia:** el paquete SSIS 2.2.5, que calcula `ID_Tiempo` como
`yyyymmdd`, queda como legado no ejecutable. La carga vigente es
`04_DataWarehouse/Carga_2_2_5_T-SQL.sql`.

---

## D2 — `Dim_Tiempo` se puebla desde `TRF_Tiempo`

**Estado:** adoptada.

La carga toma las fechas y los nombres de mes desde `TRF_Tiempo` (generado en
la transformación, con meses en español), no desde `STG_Orders` como hacía el
paquete SSIS.

**Motivo:** elimina la dependencia del idioma del servidor (`DATENAME`) y usa
el resultado real de la etapa 2.2.4.

---

## D3 — Carga y extracción en T-SQL

**Estado:** adoptada por restricción del entorno.

SSIS no está disponible. La extracción (`Extraccion_2_2_2_T-SQL.sql`) y la
carga (`Carga_2_2_5_T-SQL.sql`) se implementan como scripts T-SQL
re-ejecutables, equivalentes funcionales de los paquetes.

**Motivo:** permitir la reconstrucción completa del DW con SQL Server y SSMS,
sin depender de Integration Services.

**Nota:** los proyectos SSIS se conservan en `05_SSIS/` como evidencia de la
Etapa 2.

---

## D4 — Fecha de corte para Recencia

**Estado:** pendiente de aprobación.

Propuesta: `DATEADD(DAY, 1, MAX(Fecha_Completa))` sobre `Hechos_Ventas`, es
decir, 1998-05-07 para los datos actuales.

**Motivo:** con `GETDATE()` todos los clientes tendrían más de 10 000 días de
recencia y la segmentación perdería sentido. La fecha debe quedar documentada
en el informe.

---

## D5 — Backups fuera de Git

**Estado:** adoptada.

Los `.bak` no se versionan por peso; se conservan en el equipo local. El
repositorio contiene los scripts necesarios para reconstruir las bases.

---

## D6 — Moneda

**Estado:** pendiente de corrección documental.

Northwind almacena importes en USD. El informe fija metas en soles (S/ 500).
Debe unificarse la moneda en el informe y en el dashboard.

---

## D7 — Entorno de ejecución

**Estado:** informada.

SQL Server 2025 Developer, SSMS 22 y Visual Studio 2026 están instalados.
SSIS no. Ejecuciones y restauraciones de backup quedan pendientes de
autorización expresa.
