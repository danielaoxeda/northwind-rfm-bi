/*
=====================================================================
 Data Warehouse Northwind para analisis RFM
 SQL Server - DDL dimensional

 Crea las dimensiones y la tabla de hechos descritas en el informe.

 Claves:
   - Dim_Cliente.ID_Cliente   : subrogada, INT IDENTITY.
   - Dim_Producto.ID_Producto : subrogada, INT IDENTITY.
   - Dim_Tiempo.ID_Tiempo     : inteligente, INT con formato AAAAMMDD
                                (por ejemplo 19960704), SIN IDENTITY.
   - Hechos_Ventas            : ID_Hecho_Venta BIGINT IDENTITY y clave
                                natural UNIQUE (OrderID, ProductID).

 El calendario continuo de Dim_Tiempo se genera en la carga
 (04_DataWarehouse/02_Carga_Dimensiones.sql), no en este DDL.

 La carga de datos desde Northwind_Staging corresponde al proceso ETL.
=====================================================================
*/
IF DB_ID(N'Northwind_DW') IS NULL
BEGIN
    CREATE DATABASE Northwind_DW;
END;
GO

USE Northwind_DW;
GO

IF OBJECT_ID(N'dbo.Dim_Cliente', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Cliente
    (
        ID_Cliente             INT IDENTITY(1,1) NOT NULL,
        ID_Cliente_Northwind   NCHAR(10) NOT NULL,
        Nombre_Empresa         NVARCHAR(100) NULL,
        Pais                   NVARCHAR(50) NULL,
        Ciudad                 NVARCHAR(50) NULL,
        CONSTRAINT PK_Dim_Cliente PRIMARY KEY CLUSTERED (ID_Cliente),
        CONSTRAINT UQ_Dim_Cliente_Northwind UNIQUE (ID_Cliente_Northwind)
    );
END;
GO

IF OBJECT_ID(N'dbo.Dim_Tiempo', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Tiempo
    (
        ID_Tiempo       INT NOT NULL,
        Fecha_Completa  DATE NOT NULL,
        Dia             TINYINT NOT NULL,
        Mes             TINYINT NOT NULL,
        Nombre_Mes      NVARCHAR(15) NOT NULL,
        Trimestre       TINYINT NOT NULL,
        Anio            SMALLINT NOT NULL,
        CONSTRAINT PK_Dim_Tiempo PRIMARY KEY CLUSTERED (ID_Tiempo),
        CONSTRAINT UQ_Dim_Tiempo_Fecha UNIQUE (Fecha_Completa),
        CONSTRAINT CK_Dim_Tiempo_ID
            CHECK (ID_Tiempo = CONVERT(INT, CONVERT(CHAR(8), Fecha_Completa, 112))),
        CONSTRAINT CK_Dim_Tiempo_Dia CHECK (Dia BETWEEN 1 AND 31),
        CONSTRAINT CK_Dim_Tiempo_Mes CHECK (Mes BETWEEN 1 AND 12),
        CONSTRAINT CK_Dim_Tiempo_Trimestre CHECK (Trimestre BETWEEN 1 AND 4)
    );
END;
GO

IF OBJECT_ID(N'dbo.Dim_Producto', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Dim_Producto
    (
        ID_Producto            INT IDENTITY(1,1) NOT NULL,
        ID_Producto_Northwind  INT NOT NULL,
        Nombre_Producto        NVARCHAR(100) NOT NULL,
        Categoria              NVARCHAR(100) NULL,
        CONSTRAINT PK_Dim_Producto PRIMARY KEY CLUSTERED (ID_Producto),
        CONSTRAINT UQ_Dim_Producto_Northwind UNIQUE (ID_Producto_Northwind)
    );
END;
GO

IF OBJECT_ID(N'dbo.Hechos_Ventas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.Hechos_Ventas
    (
        ID_Hecho_Venta  BIGINT IDENTITY(1,1) NOT NULL,
        ID_Tiempo       INT NOT NULL,
        ID_Cliente      INT NOT NULL,
        ID_Producto     INT NOT NULL,
        OrderID         INT NOT NULL,
        ProductID       INT NOT NULL,
        Cantidad        SMALLINT NOT NULL,
        Precio_Unitario DECIMAL(19,4) NOT NULL,
        Descuento       DECIMAL(9,6) NOT NULL,
        Monto_Total     DECIMAL(19,4) NOT NULL,
        CONSTRAINT PK_Hechos_Ventas PRIMARY KEY CLUSTERED (ID_Hecho_Venta),
        CONSTRAINT UQ_Hechos_Ventas_Origen UNIQUE (OrderID, ProductID),
        CONSTRAINT FK_Hechos_Ventas_Dim_Tiempo FOREIGN KEY (ID_Tiempo)
            REFERENCES dbo.Dim_Tiempo (ID_Tiempo),
        CONSTRAINT FK_Hechos_Ventas_Dim_Cliente FOREIGN KEY (ID_Cliente)
            REFERENCES dbo.Dim_Cliente (ID_Cliente),
        CONSTRAINT FK_Hechos_Ventas_Dim_Producto FOREIGN KEY (ID_Producto)
            REFERENCES dbo.Dim_Producto (ID_Producto),
        CONSTRAINT CK_Hechos_Ventas_Cantidad CHECK (Cantidad > 0),
        CONSTRAINT CK_Hechos_Ventas_Precio CHECK (Precio_Unitario >= 0),
        CONSTRAINT CK_Hechos_Ventas_Descuento CHECK (Descuento BETWEEN 0 AND 1),
        CONSTRAINT CK_Hechos_Ventas_Monto CHECK (Monto_Total >= 0)
    );
END;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = N'IX_Hechos_Ventas_Cliente_Tiempo'
      AND object_id = OBJECT_ID(N'dbo.Hechos_Ventas')
)
BEGIN
    CREATE INDEX IX_Hechos_Ventas_Cliente_Tiempo
        ON dbo.Hechos_Ventas (ID_Cliente, ID_Tiempo);
END;
GO

