/*
=====================================================================
 ETAPA 2 - 2.2.4 TRANSFORMACION   (Integrante 4)
 Proyecto : Segmentacion de clientes RFM - Northwind
 Origen   : Northwind_Staging  (STG_Customers, STG_Orders, STG_OrderDetails, STG_Products)
 Destino  : tablas TRF_* dentro de Northwind_Staging (las consume la Carga, 2.2.5)

 Que hace este script
   1. Crea las tablas de transformacion (TRF_*) y la tabla de rechazos.
   2. Limpia y tipifica clientes y productos.
   3. Hace el JOIN Detalle + Pedido + Cliente + Producto, valida y
      calcula TotalVenta = Precio_Unitario x Cantidad x (1 - Descuento).
   4. Las filas invalidas NO se pierden: van a TRF_Rechazados con su motivo.
   5. Muestra un resumen y un control de cuadre (leidos = cargados + rechazados).

 Es re-ejecutable: cada corrida vacia las TRF_* y las vuelve a llenar.
 Mapeo hacia el DW:  TotalVenta -> Hechos_Ventas.Monto_Total
=====================================================================
*/
USE Northwind_Staging;
GO
SET NOCOUNT ON;
GO

/* ------------------------------------------------------------------
   0. Estructuras de transformacion
   ------------------------------------------------------------------ */
IF OBJECT_ID(N'dbo.TRF_Ventas',     N'U') IS NOT NULL DROP TABLE dbo.TRF_Ventas;
IF OBJECT_ID(N'dbo.TRF_Tiempo',     N'U') IS NOT NULL DROP TABLE dbo.TRF_Tiempo;
IF OBJECT_ID(N'dbo.TRF_Clientes',   N'U') IS NOT NULL DROP TABLE dbo.TRF_Clientes;
IF OBJECT_ID(N'dbo.TRF_Productos',  N'U') IS NOT NULL DROP TABLE dbo.TRF_Productos;
IF OBJECT_ID(N'dbo.TRF_Rechazados', N'U') IS NOT NULL DROP TABLE dbo.TRF_Rechazados;
IF OBJECT_ID(N'dbo.REF_Categoria',  N'U') IS NOT NULL DROP TABLE dbo.REF_Categoria;
GO

CREATE TABLE dbo.TRF_Rechazados
(
    ID_Rechazo    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Tabla_Origen  NVARCHAR(30)  NOT NULL,
    Clave_Origen  NVARCHAR(60)  NOT NULL,
    Motivo        NVARCHAR(200) NOT NULL,
    Fecha_Proceso DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE dbo.TRF_Clientes
(
    ID_Cliente_Northwind NCHAR(10)     NOT NULL PRIMARY KEY,
    Nombre_Empresa       NVARCHAR(100) NOT NULL,
    Pais                 NVARCHAR(50)  NOT NULL,
    Ciudad               NVARCHAR(50)  NOT NULL
);

CREATE TABLE dbo.TRF_Productos
(
    ID_Producto_Northwind INT           NOT NULL PRIMARY KEY,
    Nombre_Producto       NVARCHAR(100) NOT NULL,
    Categoria             NVARCHAR(100) NOT NULL
);

CREATE TABLE dbo.TRF_Ventas
(
    OrderID         INT           NOT NULL,
    ProductID       INT           NOT NULL,
    CustomerID      NCHAR(10)     NOT NULL,
    Fecha           DATE          NOT NULL,
    Cantidad        SMALLINT      NOT NULL,
    Precio_Unitario DECIMAL(19,4) NOT NULL,
    Descuento       DECIMAL(9,6)  NOT NULL,
    TotalVenta      DECIMAL(19,4) NOT NULL,
    CONSTRAINT PK_TRF_Ventas PRIMARY KEY (OrderID, ProductID)
);

CREATE TABLE dbo.TRF_Tiempo
(
    Fecha_Completa DATE         NOT NULL PRIMARY KEY,
    Dia            TINYINT      NOT NULL,
    Mes            TINYINT      NOT NULL,
    Nombre_Mes     NVARCHAR(15) NOT NULL,
    Trimestre      TINYINT      NOT NULL,
    Anio           SMALLINT     NOT NULL
);

/* Categorias de Northwind (CategoryID -> nombre).
   STG_Products solo trae CategoryID y el staging no tiene tabla de categorias,
   asi que se usa esta referencia con los 8 valores estandar de Northwind.
   Si el Integrante 3 agrega STG_Categories, reemplazar este INSERT por un SELECT a esa tabla. */
CREATE TABLE dbo.REF_Categoria
(
    CategoryID   INT           NOT NULL PRIMARY KEY,
    CategoryName NVARCHAR(100) NOT NULL
);
INSERT INTO dbo.REF_Categoria (CategoryID, CategoryName) VALUES
 (1, N'Beverages'), (2, N'Condiments'), (3, N'Confections'), (4, N'Dairy Products'),
 (5, N'Grains/Cereals'), (6, N'Meat/Poultry'), (7, N'Produce'), (8, N'Seafood');
GO

/* ------------------------------------------------------------------
   1. CLIENTES  (STG_Customers -> TRF_Clientes)
      - Limpieza : LTRIM/RTRIM, '' -> NULL, CustomerID en mayusculas
      - Nulos    : Nombre_Empresa -> 'Sin nombre'; Pais/Ciudad -> 'Desconocido'
      - Erroneos : CustomerID nulo o vacio -> rechazo
      - Duplicados: se conserva la primera fila por CustomerID
   ------------------------------------------------------------------ */
IF OBJECT_ID('tempdb..#cli') IS NOT NULL DROP TABLE #cli;

SELECT
    IDENTITY(INT,1,1) AS Id,
    ClienteID     = UPPER(NULLIF(LTRIM(RTRIM(CustomerID)), N'')),
    Nombre        = ISNULL(NULLIF(LTRIM(RTRIM(CompanyName)), N''), N'Sin nombre'),
    Pais          = ISNULL(NULLIF(LTRIM(RTRIM(Country)),     N''), N'Desconocido'),
    Ciudad        = ISNULL(NULLIF(LTRIM(RTRIM(City)),        N''), N'Desconocido'),
    Motivo        = CAST(NULL AS NVARCHAR(200)),
    ClaveOriginal = ISNULL(CAST(CustomerID AS NVARCHAR(60)), N'(NULL)')
INTO #cli
FROM dbo.STG_Customers;

UPDATE #cli SET Motivo = N'CustomerID nulo o vacio' WHERE ClienteID IS NULL;

UPDATE c SET Motivo = N'Cliente duplicado (se conserva la primera fila)'
FROM #cli c
JOIN (SELECT Id, rn = ROW_NUMBER() OVER (PARTITION BY ClienteID ORDER BY Id)
      FROM #cli WHERE Motivo IS NULL) d ON d.Id = c.Id
WHERE d.rn > 1;

INSERT INTO dbo.TRF_Rechazados (Tabla_Origen, Clave_Origen, Motivo)
SELECT N'STG_Customers', ClaveOriginal, Motivo FROM #cli WHERE Motivo IS NOT NULL;

INSERT INTO dbo.TRF_Clientes (ID_Cliente_Northwind, Nombre_Empresa, Pais, Ciudad)
SELECT ClienteID, Nombre, Pais, Ciudad FROM #cli WHERE Motivo IS NULL;
GO

/* ------------------------------------------------------------------
   2. PRODUCTOS  (STG_Products -> TRF_Productos)
      - Limpieza : LTRIM/RTRIM, '' -> NULL
      - Nulos    : Categoria sin CategoryID valido -> 'Sin categoria'
      - Erroneos : ProductID nulo o ProductName vacio -> rechazo
      - Duplicados: se conserva la primera fila por ProductID
   ------------------------------------------------------------------ */
IF OBJECT_ID('tempdb..#pro') IS NOT NULL DROP TABLE #pro;

SELECT
    IDENTITY(INT,1,1) AS Id,
    p.ProductID,
    Nombre        = NULLIF(LTRIM(RTRIM(p.ProductName)), N''),
    Categoria     = ISNULL(r.CategoryName, N'Sin categoria'),
    Motivo        = CAST(NULL AS NVARCHAR(200)),
    ClaveOriginal = ISNULL(CAST(p.ProductID AS NVARCHAR(60)), N'(NULL)')
INTO #pro
FROM dbo.STG_Products p
LEFT JOIN dbo.REF_Categoria r ON r.CategoryID = p.CategoryID;

UPDATE #pro SET Motivo = N'ProductID nulo'            WHERE ProductID IS NULL;
UPDATE #pro SET Motivo = N'ProductName nulo o vacio'  WHERE Motivo IS NULL AND Nombre IS NULL;

UPDATE p SET Motivo = N'Producto duplicado (se conserva la primera fila)'
FROM #pro p
JOIN (SELECT Id, rn = ROW_NUMBER() OVER (PARTITION BY ProductID ORDER BY Id)
      FROM #pro WHERE Motivo IS NULL) d ON d.Id = p.Id
WHERE d.rn > 1;

INSERT INTO dbo.TRF_Rechazados (Tabla_Origen, Clave_Origen, Motivo)
SELECT N'STG_Products', ClaveOriginal, Motivo FROM #pro WHERE Motivo IS NOT NULL;

INSERT INTO dbo.TRF_Productos (ID_Producto_Northwind, Nombre_Producto, Categoria)
SELECT ProductID, Nombre, Categoria FROM #pro WHERE Motivo IS NULL;
GO

/* ------------------------------------------------------------------
   3. VENTAS  (JOIN STG_OrderDetails + STG_Orders + TRF_Clientes + TRF_Productos)
      Grano: una fila por (OrderID, ProductID).
      - JOIN     : LEFT JOIN para poder detectar huerfanos y registrarlos
      - Tipos    : datetime -> DATE ; money -> DECIMAL(19,4) ; real -> DECIMAL(9,6)
      - Nulos    : Discount nulo -> 0
      - Erroneos : ver CASE de Motivo (el primero que aplique)
      - TotalVenta = ROUND(Precio_Unitario * Cantidad * (1 - Descuento), 4)
   ------------------------------------------------------------------ */
IF OBJECT_ID('tempdb..#lin') IS NOT NULL DROP TABLE #lin;

SELECT
    IDENTITY(INT,1,1) AS Id,
    od.OrderID,
    od.ProductID,
    CustomerID = UPPER(NULLIF(LTRIM(RTRIM(o.CustomerID)), N'')),
    Fecha      = CAST(o.OrderDate AS DATE),
    Cantidad   = od.Quantity,
    Precio     = CAST(od.UnitPrice AS DECIMAL(19,4)),
    Descuento  = CASE WHEN ISNULL(od.Discount, 0) BETWEEN 0 AND 1
                      THEN CAST(ISNULL(od.Discount, 0) AS DECIMAL(9,6)) END,
    Motivo     = CAST(
        CASE
            WHEN od.OrderID   IS NULL OR od.ProductID IS NULL            THEN N'Detalle sin OrderID o ProductID'
            WHEN o.OrderID    IS NULL                                    THEN N'Detalle sin pedido (OrderID huerfano)'
            WHEN NULLIF(LTRIM(RTRIM(o.CustomerID)), N'') IS NULL         THEN N'Pedido sin CustomerID'
            WHEN c.ID_Cliente_Northwind IS NULL                          THEN N'Cliente inexistente o rechazado'
            WHEN p.ID_Producto_Northwind IS NULL                         THEN N'Producto inexistente o rechazado'
            WHEN o.OrderDate  IS NULL                                    THEN N'Pedido sin fecha'
            WHEN o.OrderDate < '19900101' OR o.OrderDate > GETDATE()     THEN N'Fecha fuera de rango'
            WHEN od.Quantity  IS NULL OR od.Quantity <= 0                THEN N'Cantidad nula o no positiva'
            WHEN od.UnitPrice IS NULL OR od.UnitPrice < 0                THEN N'Precio unitario nulo o negativo'
            WHEN ISNULL(od.Discount, 0) < 0 OR ISNULL(od.Discount, 0) > 1 THEN N'Descuento fuera del rango 0-1'
        END AS NVARCHAR(200)),
    ClaveOriginal = N'OrderID=' + ISNULL(CAST(od.OrderID AS NVARCHAR(20)), N'NULL')
                  + N', ProductID=' + ISNULL(CAST(od.ProductID AS NVARCHAR(20)), N'NULL')
INTO #lin
FROM dbo.STG_OrderDetails od
LEFT JOIN dbo.STG_Orders    o ON o.OrderID = od.OrderID
LEFT JOIN dbo.TRF_Clientes  c ON c.ID_Cliente_Northwind = UPPER(NULLIF(LTRIM(RTRIM(o.CustomerID)), N''))
LEFT JOIN dbo.TRF_Productos p ON p.ID_Producto_Northwind = od.ProductID;

/* Duplicados: entre las lineas validas, solo la primera por (OrderID, ProductID) */
UPDATE l SET Motivo = N'Linea duplicada (OrderID, ProductID)'
FROM #lin l
JOIN (SELECT Id, rn = ROW_NUMBER() OVER (PARTITION BY OrderID, ProductID ORDER BY Id)
      FROM #lin WHERE Motivo IS NULL) d ON d.Id = l.Id
WHERE d.rn > 1;

/* Un pedido duplicado en STG_Orders multiplicaria las lineas en el JOIN: queda cubierto
   por el control anterior, que deja una sola fila por (OrderID, ProductID). */

INSERT INTO dbo.TRF_Rechazados (Tabla_Origen, Clave_Origen, Motivo)
SELECT N'STG_OrderDetails', ClaveOriginal, Motivo FROM #lin WHERE Motivo IS NOT NULL;

INSERT INTO dbo.TRF_Ventas
       (OrderID, ProductID, CustomerID, Fecha, Cantidad, Precio_Unitario, Descuento, TotalVenta)
SELECT OrderID, ProductID, CustomerID, Fecha, Cantidad, Precio, Descuento,
       CAST(ROUND(Precio * Cantidad * (1 - Descuento), 4) AS DECIMAL(19,4))
FROM #lin
WHERE Motivo IS NULL;

/* Fechas distintas de las ventas validas -> insumo para Dim_Tiempo
   (nombres de mes fijos en espanol para no depender del idioma del servidor) */
INSERT INTO dbo.TRF_Tiempo (Fecha_Completa, Dia, Mes, Nombre_Mes, Trimestre, Anio)
SELECT f.Fecha,
       DAY(f.Fecha),
       MONTH(f.Fecha),
       CHOOSE(MONTH(f.Fecha), N'Enero', N'Febrero', N'Marzo', N'Abril', N'Mayo', N'Junio',
                              N'Julio', N'Agosto', N'Septiembre', N'Octubre', N'Noviembre', N'Diciembre'),
       DATEPART(QUARTER, f.Fecha),
       YEAR(f.Fecha)
FROM (SELECT DISTINCT Fecha FROM dbo.TRF_Ventas) f;
GO

/* ------------------------------------------------------------------
   4. RESUMEN Y CONTROL DE CUADRE
   ------------------------------------------------------------------ */
SELECT 'STG_Customers'    AS Tabla,
       (SELECT COUNT(*) FROM dbo.STG_Customers)    AS Leidos,
       (SELECT COUNT(*) FROM dbo.TRF_Clientes)     AS Transformados,
       (SELECT COUNT(*) FROM dbo.TRF_Rechazados WHERE Tabla_Origen = N'STG_Customers')    AS Rechazados
UNION ALL
SELECT 'STG_Products',
       (SELECT COUNT(*) FROM dbo.STG_Products),
       (SELECT COUNT(*) FROM dbo.TRF_Productos),
       (SELECT COUNT(*) FROM dbo.TRF_Rechazados WHERE Tabla_Origen = N'STG_Products')
UNION ALL
SELECT 'STG_OrderDetails',
       (SELECT COUNT(*) FROM dbo.STG_OrderDetails),
       (SELECT COUNT(*) FROM dbo.TRF_Ventas),
       (SELECT COUNT(*) FROM dbo.TRF_Rechazados WHERE Tabla_Origen = N'STG_OrderDetails');

-- Rechazos por motivo (si no devuelve filas, no hubo datos erroneos)
SELECT Tabla_Origen, Motivo, COUNT(*) AS Filas
FROM dbo.TRF_Rechazados
GROUP BY Tabla_Origen, Motivo
ORDER BY Tabla_Origen, Filas DESC;

-- Cuadre: Leidos = Transformados + Rechazados  (debe devolver 0 filas)
SELECT 'Cuadre de lineas de venta' AS Control
WHERE (SELECT COUNT(*) FROM dbo.STG_OrderDetails)
   <> (SELECT COUNT(*) FROM dbo.TRF_Ventas)
    + (SELECT COUNT(*) FROM dbo.TRF_Rechazados WHERE Tabla_Origen = N'STG_OrderDetails');

-- Control de calculo: TotalVenta recalculado desde el staging crudo (debe devolver 0 filas)
SELECT t.OrderID, t.ProductID, t.TotalVenta,
       Esperado = CAST(ROUND(CAST(od.UnitPrice AS DECIMAL(19,4)) * od.Quantity
                        * (1 - CAST(ISNULL(od.Discount, 0) AS DECIMAL(9,6))), 4) AS DECIMAL(19,4))
FROM dbo.TRF_Ventas t
JOIN dbo.STG_OrderDetails od ON od.OrderID = t.OrderID AND od.ProductID = t.ProductID
WHERE t.TotalVenta <> CAST(ROUND(CAST(od.UnitPrice AS DECIMAL(19,4)) * od.Quantity
                        * (1 - CAST(ISNULL(od.Discount, 0) AS DECIMAL(9,6))), 4) AS DECIMAL(19,4));
GO
