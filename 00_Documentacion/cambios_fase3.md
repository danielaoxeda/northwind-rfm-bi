# Fase 3 — Cambios realizados y diferencias con el informe original

Registro de lo corregido en los scripts SQL y de las diferencias detectadas
respecto del informe de las Etapas 1 y 2. El informe Word **no se modificó**:
las correcciones de redacción quedan para cuando se autorice su actualización.

Última actualización: Fase 3 (unificación y corrección de scripts).

---

## 1. Cambios realizados en los scripts

| Script | Cambio | Motivo |
|---|---|---|
| `02_Staging/creacion_BD_Northwind_Staging.sql` | Creación condicional con `IF DB_ID(...)` y `DROP TABLE IF EXISTS` antes de crear. | Era no idempotente: fallaba si la base o las tablas ya existían. |
| `02_Staging/Extraccion_2_2_2_T-SQL.sql` | **Nuevo.** Extracción T-SQL transaccional con `TRUNCATE` previo y controles de cuadre. | Reemplaza el paquete SSIS, no disponible. Reproducible y sin duplicados. |
| `03_Transformacion/ETL_2_2_4_Transformacion.sql` | `REF_Categoria` se puebla con `SELECT` desde `Northwind.dbo.Categories`. | Elimina el `INSERT` con los 8 valores hardcodeados (I11). |
| `04_DataWarehouse/SQL_Hechos_Ventas.sql` | `Dim_Tiempo.ID_Tiempo` pasa de `INT IDENTITY` a `INT` con `CK_Dim_Tiempo_ID = AAAAMMDD`. | Alinea el DDL con el paquete SSIS y la decisión D1 (I1). |
| `04_DataWarehouse/02_Carga_Dimensiones.sql` | **Nuevo.** Actualiza/inserta dimensiones por clave natural y genera calendario continuo con `CHOOSE` en español. | Carga reproducible; `ID_Tiempo` sin IDENTITY; calendario sin huecos (D2). |
| `04_DataWarehouse/03_Carga_Hechos.sql` | **Nuevo.** Borra hechos inexistentes, actualiza e inserta por `(OrderID, ProductID)`; valida FKs y montos. | Carga idempotente con integridad referencial (D4). |
| `06_Validacion/SQL_2_3_Integridad_Calidad_Datos.sql` | Redondeo a 4 decimales en las sumas; nueva sección 2.3.9 de calendario y clave de tiempo. | Evita diferencias por redondeo y valida las nuevas reglas. |
| `00_Ejecutar_Reconstruccion.sql` | **Nuevo.** Script maestro con el orden completo y `:on error exit`. | Orden de ejecución único y reproducible. |

Los proyectos SSIS y la versión original de cada script se conservan en el
historial de Git; nada se borró del repositorio.

---

## 2. Diferencias con el informe original

| Tema | Informe original | Estado real / corrección |
|---|---|---|
| Clave de tiempo | No detalla el tipo; el DDL define `IDENTITY`. | `ID_Tiempo` = `INT` `AAAAMMDD`, sin IDENTITY, con restricción de verificación. |
| Calendario | Se reportan 480 fechas. | El rango real de ventas es 1996-07-04 a 1998-05-06: **672 días continuos**. |
| Categorías | Valores fijos en el script. | Se leen de `Northwind.dbo.Categories` (8 categorías, IDs 1–8). |
| Moneda | Metas en soles (S/ 500). | Northwind está en USD; se conserva la moneda original (D7). |
| `ID_Hecho_Venta` | `INT` según el informe. | `BIGINT IDENTITY` en el DDL. |
| `ID_Cliente_Northwind` | `VARCHAR(5)` según el informe. | `NCHAR(5)` en origen; el staging usa `NCHAR(10)` y la longitud real es 5. |
| `Descuento` | `DECIMAL(5,2)` según el informe. | `DECIMAL(9,6)` en el DDL, coherente con `real` de origen. |
| Nombre de columna | `Año` en el informe. | `Anio` en el DDL, para evitar caracteres no ASCII en identificadores. |
| Volumetría | 91 clientes, 77 productos, 2155 líneas, 480 fechas, monto 1 265 793,0395. | Verificado en `Northwind`: 91 clientes, 77 productos, 2155 líneas, monto **1 265 793,0395**. Las 480 fechas del informe no coinciden con los 672 días del rango. |
| Etapa 3 | No redactada. | Pendiente de la Fase 4 / Etapa 3. |

---

## 3. Validaciones ejecutadas en esta fase

| Prueba | Resultado |
|---|---|
| Creación del staging dos veces | Correcta; tablas quedan vacías y re-creadas. |
| Extracción dos veces | 91 / 830 / 2155 / 77 filas estables, sin duplicados; control de cuadre en 0 filas. |
| Transformación dos veces | 91 / 77 / 2155 transformados, 0 rechazados, en ambas ejecuciones. |
| Categorías desde Northwind | 8 categorías; coinciden una a una con `Northwind.dbo.Categories`. |
| Cobertura referencial del staging | 0 ventas sin cliente, sin producto o sin fecha. |
| Calendario continuo | 672 días, de 1996-07-04 a 1998-05-06, sin huecos. |
| DDL del DW | Creado y verificado: `ID_Tiempo` sin IDENTITY, 3 FKs activas, CK de `AAAAMMDD` presente. |
| Compilación de cargas | `SET NOEXEC ON` sin errores; las tablas permanecen vacías. |
| Esquema de prueba | `Northwind_DW` eliminado tras validar; el entorno queda limpio. |

No se ejecutó la reconstrucción completa del DW ni se modificó el informe Word.

---

## 4. Pendientes para la Fase 4

1. Autorizar y ejecutar `00_Ejecutar_Reconstruccion.sql` de punta a punta.
2. Confirmar los conteos y montos finales del DW contra `Northwind`.
3. Generar y conservar un backup de `Northwind_DW`.
4. Actualizar el informe Word con las diferencias de la sección 2.
5. Calcular RFM y construir el dashboard (Etapa 3).
