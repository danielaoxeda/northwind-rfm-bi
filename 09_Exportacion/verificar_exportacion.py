#!/usr/bin/env python3
"""Verifica que los CSV y el XLSX coincidan con Northwind_DW.

Compara conteos, claves, relaciones y montos contra SQL Server (via sqlcmd)
y revisa la estructura del libro XLSX. Devuelve codigo 1 si algo no cuadra.
"""
import csv
import datetime as dt
import json
import os
import re
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET
from decimal import Decimal

BASE = os.path.dirname(os.path.abspath(__file__))
SQLCMD_CANDIDATES = [
    r"C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\180\Tools\Binn\SQLCMD.EXE",
    "sqlcmd",
]

SCHEMA = {
    "Dim_Cliente": ["ID_Cliente", "ID_Cliente_Northwind", "Nombre_Empresa", "Pais", "Ciudad"],
    "Dim_Producto": ["ID_Producto", "ID_Producto_Northwind", "Nombre_Producto", "Categoria"],
    "Dim_Tiempo": ["ID_Tiempo", "Fecha_Completa", "Dia", "Mes", "Nombre_Mes", "Trimestre", "Anio"],
    "Hechos_Ventas": [
        "ID_Hecho_Venta", "ID_Tiempo", "ID_Cliente", "ID_Producto", "OrderID",
        "ProductID", "Cantidad", "Precio_Unitario", "Descuento", "Monto_Total",
    ],
}

METRICS_SQL = """
SET NOCOUNT ON;
SELECT
 (SELECT COUNT(*) FROM dbo.Dim_Cliente) AS clientes,
 (SELECT COUNT(*) FROM dbo.Dim_Producto) AS productos,
 (SELECT COUNT(*) FROM dbo.Dim_Tiempo) AS dias,
 (SELECT COUNT(*) FROM dbo.Hechos_Ventas) AS hechos,
 (SELECT CONVERT(VARCHAR(40), SUM(Monto_Total)) FROM dbo.Hechos_Ventas) AS monto,
 (SELECT CONVERT(VARCHAR(20), SUM(Cantidad)) FROM dbo.Hechos_Ventas) AS unidades,
 (SELECT COUNT(DISTINCT OrderID) FROM dbo.Hechos_Ventas) AS pedidos,
 (SELECT COUNT(*) FROM dbo.Hechos_Ventas h WHERE NOT EXISTS
    (SELECT 1 FROM dbo.Dim_Cliente c WHERE c.ID_Cliente = h.ID_Cliente)) AS huerfanos_cliente,
 (SELECT COUNT(*) FROM dbo.Hechos_Ventas h WHERE NOT EXISTS
    (SELECT 1 FROM dbo.Dim_Producto p WHERE p.ID_Producto = h.ID_Producto)) AS huerfanos_producto,
 (SELECT COUNT(*) FROM dbo.Hechos_Ventas h WHERE NOT EXISTS
    (SELECT 1 FROM dbo.Dim_Tiempo t WHERE t.ID_Tiempo = h.ID_Tiempo)) AS huerfanos_tiempo
FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
"""


def find_sqlcmd():
    for candidate in SQLCMD_CANDIDATES:
        if os.path.isabs(candidate):
            if os.path.exists(candidate):
                return candidate
        else:
            return candidate
    raise FileNotFoundError("No se encontro sqlcmd")


def sql_metrics():
    cmd = [
        find_sqlcmd(), "-S", "localhost", "-E", "-C", "-b", "-h", "-1", "-W",
        "-d", "Northwind_DW", "-Q", METRICS_SQL,
    ]
    out = subprocess.check_output(cmd, text=True, encoding="utf-8", errors="replace")
    line = next(l.strip() for l in out.splitlines() if l.strip().startswith("{"))
    return json.loads(line)


def read_csv(table):
    path = os.path.join(BASE, "csv", table + ".csv")
    with open(path, "r", encoding="utf-8-sig", newline="") as fh:
        rows = list(csv.reader(fh))
    return rows[0], rows[1:]


def main():
    checks = []
    ok = True

    def check(name, expected, actual):
        nonlocal ok
        good = str(expected) == str(actual)
        ok = ok and good
        checks.append((name, expected, actual, "OK" if good else "FALLA"))

    metrics = sql_metrics()

    data = {}
    for table, expected_cols in SCHEMA.items():
        header, rows = read_csv(table)
        data[table] = rows
        check(f"{table}: columnas", expected_cols, header)
        pk = expected_cols[0]
        keys = [int(r[0]) for r in rows]
        check(f"{table}: filas", len(rows), len(rows))
        check(f"{table}: PK unica", len(set(keys)), len(keys))
        check(f"{table}: PK minima", min(keys), min(keys))
        check(f"{table}: PK maxima", max(keys), max(keys))

    check("Dim_Cliente: filas vs SQL", metrics["clientes"], len(data["Dim_Cliente"]))
    check("Dim_Producto: filas vs SQL", metrics["productos"], len(data["Dim_Producto"]))
    check("Dim_Tiempo: filas vs SQL", metrics["dias"], len(data["Dim_Tiempo"]))
    check("Hechos_Ventas: filas vs SQL", metrics["hechos"], len(data["Hechos_Ventas"]))

    hechos = data["Hechos_Ventas"]
    monto = sum(Decimal(r[9]) for r in hechos)
    unidades = sum(int(r[6]) for r in hechos)
    pedidos = len({r[4] for r in hechos})
    check("Hechos: monto", metrics["monto"], str(monto))
    check("Hechos: unidades", metrics["unidades"], str(unidades))
    check("Hechos: pedidos distintos", metrics["pedidos"], pedidos)

    clientes = {int(r[0]) for r in data["Dim_Cliente"]}
    productos = {int(r[0]) for r in data["Dim_Producto"]}
    tiempos = {int(r[0]) for r in data["Dim_Tiempo"]}
    huerf_cli = sum(1 for r in hechos if int(r[2]) not in clientes)
    huerf_pro = sum(1 for r in hechos if int(r[3]) not in productos)
    huerf_tie = sum(1 for r in hechos if int(r[1]) not in tiempos)
    check("Hechos: huerfanos cliente", metrics["huerfanos_cliente"], huerf_cli)
    check("Hechos: huerfanos producto", metrics["huerfanos_producto"], huerf_pro)
    check("Hechos: huerfanos tiempo", metrics["huerfanos_tiempo"], huerf_tie)

    # Clave de tiempo AAAAMMDD y calendario continuo.
    ids_tiempo = sorted(tiempos)
    mal_formato = sum(1 for i in ids_tiempo if len(str(i)) != 8)
    check("Dim_Tiempo: claves AAAAMMDD mal formadas", 0, mal_formato)
    fechas = [
        dt.date(int(str(i)[:4]), int(str(i)[4:6]), int(str(i)[6:8]))
        for i in ids_tiempo
    ]
    faltantes = (fechas[-1] - fechas[0]).days + 1 - len(fechas)
    check("Dim_Tiempo: dias faltantes", 0, faltantes)

    # Verificacion del XLSX
    xlsx = os.path.join(BASE, "Northwind_DW.xlsx")
    with zipfile.ZipFile(xlsx) as z:
        names = set(z.namelist())
        # Todos los XML y relaciones deben estar bien formados.
        xml_ok = True
        for part in names:
            if part.endswith(".xml") or part.endswith(".rels"):
                try:
                    ET.fromstring(z.read(part))
                except ET.ParseError:
                    xml_ok = False
        check("XLSX: XML bien formado", True, xml_ok)

        # Los destinos de las relaciones internas deben existir.
        missing = []
        for rels_name in [n for n in names if n.endswith(".rels")]:
            base_dir = os.path.dirname(os.path.dirname(rels_name))
            root = ET.fromstring(z.read(rels_name))
            for rel in root:
                target = rel.get("Target", "")
                if target.startswith("http") or target.startswith("/"):
                    continue
                resolved = os.path.normpath(os.path.join(base_dir, target)).replace("\\", "/")
                if resolved not in names:
                    missing.append(resolved)
        check("XLSX: relaciones internas resueltas", [], sorted(set(missing)))

        workbook = z.read("xl/workbook.xml").decode("utf-8")
        names = re.findall(r'<sheet name="([^"]+)"', workbook)
        check("XLSX: hojas", list(SCHEMA.keys()), names)
        for i, table in enumerate(SCHEMA, start=1):
            xml = z.read(f"xl/worksheets/sheet{i}.xml").decode("utf-8")
            rows = len(re.findall(r"<row ", xml))
            check(f"XLSX {table}: filas (incluye cabecera)",
                  len(data[table]) + 1, rows)
            header_cells = re.findall(r"<t[^>]*>([^<]*)</t>", xml.split("</row>", 1)[0])
            check(f"XLSX {table}: cabecera", SCHEMA[table], header_cells)
        # Fecha como serial con formato de fecha (estilo 2)
        sheet_tiempo = z.read("xl/worksheets/sheet3.xml").decode("utf-8")
        check("XLSX Dim_Tiempo: fecha serial con estilo de fecha",
              True, 'r="B2" s="2"' in sheet_tiempo)

    print("VERIFICACION DE EXPORTACION")
    print("=" * 78)
    for name, expected, actual, status in checks:
        print(f"[{status:5}] {name}: esperado={expected!r} obtenido={actual!r}")
    print("=" * 78)
    print("RESULTADO:", "TODO CORRECTO" if ok else "HAY DIFERENCIAS")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
