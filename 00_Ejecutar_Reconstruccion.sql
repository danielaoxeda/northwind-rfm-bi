/*
=====================================================================
 RECONSTRUCCION COMPLETA DE NORTHWIND_DW
 Script maestro: ejecuta los pasos en el orden correcto.

 PRERREQUISITOS
   1. Instancia SQL Server local con autenticacion de Windows.
   2. Base Northwind restaurada (01_Fuente/northwind2024.bak).
      Restauracion sugerida (ajustar rutas y ejecutar aparte):
        RESTORE DATABASE Northwind
        FROM DISK = N'...\northwind2024.bak'
        WITH MOVE N'Northwind'     TO N'...\Northwind.mdf',
             MOVE N'Northwind_log' TO N'...\Northwind_log.ldf',
             RECOVERY;
   3. Haber cerrado sesiones sobre Northwind_Staging y Northwind_DW.

 USO
   sqlcmd -S localhost -E -C -b -f 65001 -i 00_Ejecutar_Reconstruccion.sql
   o, en SSMS, activar "Consulta > Modo SQLCMD" y abrir este archivo.

 NOTAS
   - El script es re-ejecutable: recreate el staging, vuelve a extraer y
     transformar, y actualiza el DW sin duplicar.
   - Si existe un Northwind_DW con el esquema anterior (ID_Tiempo
     IDENTITY), el DDL no lo modifica. En ese caso hay que eliminarlo
     manualmente antes de ejecutar este maestro.
   - No elimina Northwind ni los backups.
=====================================================================
*/
:on error exit

PRINT N'Paso 0: verificando Northwind...';
IF DB_ID(N'Northwind') IS NULL
BEGIN
    ;THROW 50000, N'No existe la base Northwind. Restaure 01_Fuente/northwind2024.bak antes de continuar.', 1;
END;
GO

PRINT N'Paso 1: creando Northwind_Staging...';
:r .\02_Staging\creacion_BD_Northwind_Staging.sql

PRINT N'Paso 2: extrayendo datos de Northwind...';
:r .\02_Staging\Extraccion_2_2_2_T-SQL.sql

PRINT N'Paso 3: transformando y validando...';
:r .\03_Transformacion\ETL_2_2_4_Transformacion.sql

PRINT N'Paso 4: creando el esquema del Data Warehouse...';
:r .\04_DataWarehouse\SQL_Hechos_Ventas.sql

PRINT N'Paso 5: cargando dimensiones y calendario...';
:r .\04_DataWarehouse\02_Carga_Dimensiones.sql

PRINT N'Paso 6: cargando hechos...';
:r .\04_DataWarehouse\03_Carga_Hechos.sql

PRINT N'Paso 7: validando la carga...';
:r .\06_Validacion\SQL_2_2_6_Validacion_Nicole.sql
:r .\06_Validacion\SQL_2_3_Integridad_Calidad_Datos.sql

PRINT N'Reconstruccion finalizada. Revise que todos los controles devuelvan 0 filas.';
GO
