/*
=====================================================================
 ETAPA 2 - 2.2.5 CARGA DE DIMENSIONES  (alternativa T-SQL a SSIS)

 Origen : Northwind_Staging.dbo.TRF_Clientes, TRF_Productos, TRF_Ventas
 Destino: Northwind_DW.dbo.Dim_Cliente, Dim_Producto, Dim_Tiempo

 - Dim_Cliente y Dim_Producto conservan su clave subrogada IDENTITY:
   se actualizan por clave natural y solo se insertan las nuevas, de
   modo que las claves no cambian entre ejecuciones.
 - Dim_Tiempo usa ID_Tiempo = AAAAMMDD (sin IDENTITY) y se genera como
   calendario continuo: todas las fechas entre la primera y la ultima
   venta, aunque no haya ventas ese dia.
 - Transaccional y re-ejecutable: no duplica filas.

 Requiere: 04_DataWarehouse/SQL_Hechos_Ventas.sql ejecutado y la
           transformacion 2.2.4 completada.
=====================================================================
*/
USE Northwind_DW;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM Northwind_Staging.dbo.TRF_Ventas)
    BEGIN
        ;THROW 50100, N'TRF_Ventas esta vacia: ejecute primero la transformacion 2.2.4.', 1;
    END;

    /* ------------------------------------------------------------------
       1. Dim_Cliente
       ------------------------------------------------------------------ */
    UPDATE d
    SET d.Nombre_Empresa = s.Nombre_Empresa,
        d.Pais           = s.Pais,
        d.Ciudad         = s.Ciudad
    FROM dbo.Dim_Cliente AS d
    INNER JOIN Northwind_Staging.dbo.TRF_Clientes AS s
        ON s.ID_Cliente_Northwind = d.ID_Cliente_Northwind;

    INSERT INTO dbo.Dim_Cliente (ID_Cliente_Northwind, Nombre_Empresa, Pais, Ciudad)
    SELECT s.ID_Cliente_Northwind, s.Nombre_Empresa, s.Pais, s.Ciudad
    FROM Northwind_Staging.dbo.TRF_Clientes AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Dim_Cliente AS d
        WHERE d.ID_Cliente_Northwind = s.ID_Cliente_Northwind
    );

    /* ------------------------------------------------------------------
       2. Dim_Producto
       ------------------------------------------------------------------ */
    UPDATE d
    SET d.Nombre_Producto = s.Nombre_Producto,
        d.Categoria       = s.Categoria
    FROM dbo.Dim_Producto AS d
    INNER JOIN Northwind_Staging.dbo.TRF_Productos AS s
        ON s.ID_Producto_Northwind = d.ID_Producto_Northwind;

    INSERT INTO dbo.Dim_Producto (ID_Producto_Northwind, Nombre_Producto, Categoria)
    SELECT s.ID_Producto_Northwind, s.Nombre_Producto, s.Categoria
    FROM Northwind_Staging.dbo.TRF_Productos AS s
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Dim_Producto AS d
        WHERE d.ID_Producto_Northwind = s.ID_Producto_Northwind
    );

    /* ------------------------------------------------------------------
       3. Dim_Tiempo - calendario continuo
       ------------------------------------------------------------------ */
    IF OBJECT_ID(N'tempdb..#Calendario') IS NOT NULL DROP TABLE #Calendario;

    ;WITH Fechas AS
    (
        SELECT MIN(Fecha) AS Fecha,
               MAX(Fecha) AS FechaMax
        FROM Northwind_Staging.dbo.TRF_Ventas
        UNION ALL
        SELECT DATEADD(DAY, 1, Fecha), FechaMax
        FROM Fechas
        WHERE Fecha < FechaMax
    )
    SELECT
        ID_Tiempo      = CONVERT(INT, CONVERT(CHAR(8), Fecha, 112)),
        Fecha_Completa = Fecha,
        Dia            = DAY(Fecha),
        Mes            = MONTH(Fecha),
        Nombre_Mes     = CHOOSE(MONTH(Fecha),
                                N'Enero', N'Febrero', N'Marzo', N'Abril',
                                N'Mayo', N'Junio', N'Julio', N'Agosto',
                                N'Septiembre', N'Octubre', N'Noviembre', N'Diciembre'),
        Trimestre      = DATEPART(QUARTER, Fecha),
        Anio           = YEAR(Fecha)
    INTO #Calendario
    FROM Fechas
    OPTION (MAXRECURSION 0);

    UPDATE t
    SET t.Fecha_Completa = c.Fecha_Completa,
        t.Dia            = c.Dia,
        t.Mes            = c.Mes,
        t.Nombre_Mes     = c.Nombre_Mes,
        t.Trimestre      = c.Trimestre,
        t.Anio           = c.Anio
    FROM dbo.Dim_Tiempo AS t
    INNER JOIN #Calendario AS c
        ON c.ID_Tiempo = t.ID_Tiempo;

    INSERT INTO dbo.Dim_Tiempo (ID_Tiempo, Fecha_Completa, Dia, Mes, Nombre_Mes, Trimestre, Anio)
    SELECT c.ID_Tiempo, c.Fecha_Completa, c.Dia, c.Mes, c.Nombre_Mes, c.Trimestre, c.Anio
    FROM #Calendario AS c
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dbo.Dim_Tiempo AS t
        WHERE t.ID_Tiempo = c.ID_Tiempo
    );

    DROP TABLE #Calendario;

    /* ------------------------------------------------------------------
       4. Controles dentro de la transaccion
       ------------------------------------------------------------------ */
    IF EXISTS
    (
        SELECT 1
        FROM Northwind_Staging.dbo.TRF_Clientes AS s
        WHERE NOT EXISTS
        (
            SELECT 1 FROM dbo.Dim_Cliente AS d
            WHERE d.ID_Cliente_Northwind = s.ID_Cliente_Northwind
        )
    )
    BEGIN
        ;THROW 50101, N'Hay clientes del staging sin fila en Dim_Cliente.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM Northwind_Staging.dbo.TRF_Productos AS s
        WHERE NOT EXISTS
        (
            SELECT 1 FROM dbo.Dim_Producto AS d
            WHERE d.ID_Producto_Northwind = s.ID_Producto_Northwind
        )
    )
    BEGIN
        ;THROW 50102, N'Hay productos del staging sin fila en Dim_Producto.', 1;
    END;

    IF EXISTS
    (
        SELECT 1
        FROM Northwind_Staging.dbo.TRF_Ventas AS v
        WHERE NOT EXISTS
        (
            SELECT 1 FROM dbo.Dim_Tiempo AS t
            WHERE t.Fecha_Completa = v.Fecha
        )
    )
    BEGIN
        ;THROW 50103, N'Hay fechas de venta sin fila en Dim_Tiempo.', 1;
    END;

    IF (SELECT COUNT(*) FROM dbo.Dim_Tiempo)
       <> (SELECT DATEDIFF(DAY, MIN(Fecha_Completa), MAX(Fecha_Completa)) + 1 FROM dbo.Dim_Tiempo)
    BEGIN
        ;THROW 50104, N'Dim_Tiempo no es un calendario continuo.', 1;
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;
    THROW;
END CATCH;
GO

/* ------------------------------------------------------------------
   Resumen de dimensiones
   ------------------------------------------------------------------ */
SELECT 'Dim_Cliente' AS Tabla, COUNT(*) AS Filas FROM dbo.Dim_Cliente
UNION ALL SELECT 'Dim_Producto', COUNT(*) FROM dbo.Dim_Producto
UNION ALL SELECT 'Dim_Tiempo',   COUNT(*) FROM dbo.Dim_Tiempo;

SELECT MIN(Fecha_Completa) AS Fecha_Minima, MAX(Fecha_Completa) AS Fecha_Maxima
FROM dbo.Dim_Tiempo;
GO
