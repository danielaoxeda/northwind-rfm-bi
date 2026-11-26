# Decisiones técnicas e inconsistencias detectadas

Documento de referencia del proyecto. Registra los hallazgos de la auditoría,
las decisiones aprobadas por el equipo y lo que queda pendiente para la
reconstrucción.

Última actualización: Fase 2 (preparación del entorno y organización).

---

## 1. Inconsistencias detectadas

| # | Hallazgo | Impacto | Estado |
|---|---|---|---|
| I1 | `SQL_Hechos_Ventas.sql` define `Dim_Tiempo.ID_Tiempo` como `IDENTITY(1,1)`, mientras el paquete SSIS 2.2.5 calcula `ID_Tiempo` como `YYYYMMDD` y lo inserta con `FastLoadKeepIdentity=false`. | Bloqueante: la carga falla por columna identidad, o la FK falla si se usan claves 1..N. | Resuelto por decisión D1; el DDL se corrige en Fase 3. |
| I2 | El paquete SSIS 2.2.5 no es ejecutable tal como está y no existe SSIS en el entorno. | Bloqueante para la carga. | Reemplazado por scripts T-SQL (D3). |
| I3 | Los flujos de carga SSIS no hacen `TRUNCATE` ni validan duplicados; las extracciones no tienen precedencia respecto de las cargas. | Alto: una segunda ejecución duplica el staging o falla por PK/UQ. | Reemplazado por cargas reproducibles (D4). |
| I4 | Nombres de servidor fijos y mezclados: `DESKTOP-V3OMCK2`, `localhost`, y backups originados en `DESKTOP-VJL19IG` y `DESKTOP-KRD86TL`. | Alto: los paquetes no son portables. | La reconstrucción usa la instancia local `STG_PERU` (D3). |
| I5 | `TRF_Tiempo` no lo usa el paquete SSIS: `Dim_Tiempo` se puebla desde `STG_Orders` y con `DATENAME` (depende del idioma del servidor). | Medio: meses en inglés si el servidor no está en español; el informe afirma lo contrario. | Se usará `TRF_Tiempo` y un calendario continuo (D2, D5). |
| I6 | No existe respaldo de `Northwind_DW`. El backup de staging contiene solo las tablas `STG_*`, no las `TRF_*`. | Alto: el DW debe reconstruirse por completo. | Aceptado; reconstrucción desde scripts en Fase 3. |
| I7 | `northwind2024.bak` proviene de SQL Server 2019 y `Northwind_Staging.bak` de SQL Server 2025. | Medio: el backup de staging no se puede restaurar en versiones anteriores a 2025. | La instancia local es 2025; sin bloqueo. |
| I8 | Diferencias entre el informe y los scripts: `ID_Hecho_Venta` INT vs BIGINT; `ID_Cliente_Northwind` VARCHAR(5) vs NCHAR(10); `Descuento` DECIMAL(5,2) vs DECIMAL(9,6); `Año` vs `Anio`. | Medio: inconsistencia documental. | Se corrige el informe en Fase 3. |
| I9 | El informe fija metas en soles (S/ 500) y Northwind almacena USD. | Bajo/medio: interpretación de KPIs. | Se conserva la moneda original (D7) y se corrige el texto. |
| I10 | El informe declara 91 clientes, 77 productos, 2155 líneas, 480 fechas y monto 1 265 793,0395, pero no hay DW que lo verifique. | Medio: cifras no reproducibles hoy. | No se asumen; se validarán al reconstruir. |
| I11 | `REF_Categoria` está hardcodeada porque el staging no tiene `STG_Categories`. | Bajo: depende de que las 8 categorías estándar no cambien. | Se mantiene; documentado en el script. |
| I12 | `creacion_BD_Northwind_Staging.sql` no es idempotente (falla si la base existe). | Bajo: obliga a limpiar manualmente entre intentos. | Se corrige en Fase 3, sin alterar la lógica de datos. |
| I13 | Los scripts de validación referencian la base `Northwind` por nombre. | Bajo: si se restaura con otro nombre, hay que ajustarlos. | Se restaura como `Northwind`. |
| I14 | El informe llega hasta la sección 2.3.8; no existe Etapa 3 redactada. | Medio: entrega incompleta. | Se aborda en Fase 3. |

---

## 2. Decisiones aprobadas

### D1 — `ID_Tiempo` con formato `YYYYMMDD`, sin `IDENTITY`
**Estado:** aprobada.

`Dim_Tiempo.ID_Tiempo` es un `INT` con el patrón `AAAAMMDD` (por ejemplo,
`19960704`). No usa `IDENTITY`. `Dim_Cliente` y `Dim_Producto` conservan sus
claves subrogadas `INT IDENTITY`, con la clave natural de Northwind en una
columna aparte.

**Consecuencia:** el DDL actual debe modificarse en Fase 3 (quitar `IDENTITY`
de `ID_Tiempo`). El paquete SSIS 2.2.5 queda como evidencia, no como mecanismo
de carga.

### D2 — Calendario continuo
**Estado:** aprobada.

`Dim_Tiempo` contiene **todas** las fechas del rango analizado, sin huecos,
aunque no haya ventas en un día. El rango se toma de las fechas de venta
(mínima y máxima) y se completa día a día.

**Motivo:** permite series temporales correctas y comparaciones por periodo.

### D3 — Reconstrucción mediante scripts SQL, sin SSIS
**Estado:** aprobada.

La extracción, transformación y carga se ejecutan con scripts T-SQL sobre SQL
Server 2025. Los proyectos SSIS se conservan en `05_SSIS/` como evidencia de
la Etapa 2.

### D4 — Cargas reproducibles y sin duplicados
**Estado:** aprobada.

Cada carga vacía sus tablas destino en orden de dependencias y vuelve a
insertar dentro de una transacción. Al finalizar, verifica conteos y montos
contra el staging; si no cuadra, revierte.

### D5 — Fecha de corte RFM
**Estado:** aprobada.

Fecha de corte inicial = **última fecha de venta + 1 día**. Con los datos
actuales corresponde a `1998-05-07`. Debe quedar documentada en el informe y
parametrizada en el cálculo.

**Motivo:** usar `GETDATE()` daría más de 10 000 días de recencia a todos los
clientes.

### D6 — Frecuencia por pedidos distintos
**Estado:** aprobada.

`F = COUNT(DISTINCT OrderID)` por cliente. No se cuentan líneas de pedido.

### D7 — Moneda original
**Estado:** aprobada.

Se conservan los importes en USD tal como están en Northwind. No se convierten
ni se simulan tipos de cambio. El informe debe expresar las metas en USD.

### D8 — Visualización en Power BI
**Estado:** aprobada.

El dashboard de la Etapa 3 se construye en Power BI Desktop, conectado a
`Northwind_DW`.

### D9 — Conservar SSIS como evidencia
**Estado:** aprobada.

Ambos proyectos SSIS permanecen en el repositorio con su código fuente. Los
artefactos de compilación e IDE se conservan localmente en
`99_Archivo/artefactos/`.

### D10 — Sin datos simulados
**Estado:** aprobada.

No se generan ventas, clientes ni fechas artificiales. El calendario continuo
es una dimensión de fechas, no un dato de venta.

---

## 3. Pendientes

| Tema | Responsable | Fase |
|---|---|---|
| Corregir `ID_Tiempo` (sin `IDENTITY`) y añadir calendario continuo en el DDL. | Equipo | 3 |
| Crear extracción y carga T-SQL reproducibles. | Equipo | 3 |
| Restaurar `Northwind` y reconstruir el DW. | Equipo | 3 |
| Corregir tipos y moneda en el informe. | Equipo | 3 |
| Configurar `origin` del repositorio (falta la URL real). | Equipo | 2/3 |
| Definir si los `.bak` se comparten por Git LFS o almacenamiento externo. | Equipo | 2 |
| Calcular RFM, segmentar y construir el dashboard. | Equipo | 3 |
