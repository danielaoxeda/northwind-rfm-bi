#!/usr/bin/env python3
"""Genera CSV UTF-8 y un libro XLSX (OOXML) a partir de los JSON exportados.

No requiere dependencias externas: usa solo la biblioteca estandar.
Uso: python generar_xlsx_csv.py --input <carpeta_json> --output <carpeta_salida>
"""
import argparse
import csv
import datetime as dt
import json
import os
import zipfile
from decimal import Decimal
from xml.sax.saxutils import escape

TABLES = [
    {
        "name": "Dim_Cliente",
        "key": "ID_Cliente",
        "cols": [
            ("ID_Cliente", "int"),
            ("ID_Cliente_Northwind", "text"),
            ("Nombre_Empresa", "text"),
            ("Pais", "text"),
            ("Ciudad", "text"),
        ],
    },
    {
        "name": "Dim_Producto",
        "key": "ID_Producto",
        "cols": [
            ("ID_Producto", "int"),
            ("ID_Producto_Northwind", "int"),
            ("Nombre_Producto", "text"),
            ("Categoria", "text"),
        ],
    },
    {
        "name": "Dim_Tiempo",
        "key": "ID_Tiempo",
        "cols": [
            ("ID_Tiempo", "int"),
            ("Fecha_Completa", "date"),
            ("Dia", "int"),
            ("Mes", "int"),
            ("Nombre_Mes", "text"),
            ("Trimestre", "int"),
            ("Anio", "int"),
        ],
    },
    {
        "name": "Hechos_Ventas",
        "key": "ID_Hecho_Venta",
        "cols": [
            ("ID_Hecho_Venta", "int"),
            ("ID_Tiempo", "int"),
            ("ID_Cliente", "int"),
            ("ID_Producto", "int"),
            ("OrderID", "int"),
            ("ProductID", "int"),
            ("Cantidad", "int"),
            ("Precio_Unitario", "dec4"),
            ("Descuento", "dec6"),
            ("Monto_Total", "dec4"),
        ],
    },
]


def fmt_value(value, kind):
    """Devuelve el texto canonico para CSV/XLSX."""
    if value is None or value == "":
        return ""
    if kind == "int":
        return str(int(value))
    if kind == "text":
        return str(value)
    if kind == "date":
        return str(value)
    if kind == "dec4":
        return f"{Decimal(str(value)):.4f}"
    if kind == "dec6":
        return f"{Decimal(str(value)):.6f}"
    return str(value)


def excel_serial(date_text):
    d = dt.date.fromisoformat(date_text)
    return (d - dt.date(1899, 12, 30)).days


def col_letter(idx):
    letters = ""
    idx += 1
    while idx:
        idx, rem = divmod(idx - 1, 26)
        letters = chr(65 + rem) + letters
    return letters


def cell_xml(ref, value, kind, style):
    if value == "":
        return ""
    if kind == "text":
        return (
            f'<c r="{ref}" t="inlineStr" s="{style}"><is>'
            f'<t xml:space="preserve">{escape(value)}</t></is></c>'
        )
    if kind == "date":
        return f'<c r="{ref}" s="{style}"><v>{excel_serial(value)}</v></c>'
    return f'<c r="{ref}" s="{style}"><v>{escape(value)}</v></c>'


STYLES = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
 <numFmts count="3">
  <numFmt numFmtId="164" formatCode="yyyy\\-mm\\-dd"/>
  <numFmt numFmtId="165" formatCode="0.0000"/>
  <numFmt numFmtId="166" formatCode="0.000000"/>
 </numFmts>
 <fonts count="2">
  <font><sz val="11"/><name val="Calibri"/></font>
  <font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
 </fonts>
 <fills count="3">
  <fill><patternFill patternType="none"/></fill>
  <fill><patternFill patternType="gray125"/></fill>
  <fill><patternFill patternType="solid"><fgColor rgb="FF1F4E78"/><bgColor indexed="64"/></patternFill></fill>
 </fills>
 <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
 <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
 <cellXfs count="5">
  <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
  <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
  <xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
  <xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
  <xf numFmtId="166" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
 </cellXfs>
 <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>"""


def build_sheet(columns, rows):
    ncols = len(columns)
    nrows = len(rows) + 1
    last_col = col_letter(ncols - 1)
    widths = []
    for idx, (col_name, kind) in enumerate(columns):
        longest = len(col_name)
        for row in rows:
            longest = max(longest, len(fmt_value(row.get(col_name), kind)))
        widths.append(min(max(longest + 2, 10), 50))

    parts = [
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">',
        f'<dimension ref="A1:{last_col}{nrows}"/>',
        '<sheetViews><sheetView workbookViewId="0">'
        '<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>'
        '</sheetView></sheetViews>',
        '<sheetFormatPr defaultRowHeight="15"/>',
        "<cols>",
    ]
    for idx, width in enumerate(widths):
        parts.append(f'<col min="{idx + 1}" max="{idx + 1}" width="{width}" customWidth="1"/>')
    parts.append("</cols><sheetData>")

    # Cabecera
    header_cells = "".join(
        cell_xml(f"{col_letter(i)}1", name, "text", 1) for i, (name, _) in enumerate(columns)
    )
    parts.append(f'<row r="1">{header_cells}</row>')

    for r_idx, row in enumerate(rows, start=2):
        cells = []
        for c_idx, (name, kind) in enumerate(columns):
            value = fmt_value(row.get(name), kind)
            style = {"date": 2, "dec4": 3, "dec6": 4}.get(kind, 0)
            cells.append(cell_xml(f"{col_letter(c_idx)}{r_idx}", value, kind, style))
        parts.append(f'<row r="{r_idx}">{"".join(cells)}</row>')

    parts.append("</sheetData>")
    parts.append(f'<autoFilter ref="A1:{last_col}{nrows}"/>')
    parts.append("</worksheet>")
    return "".join(parts)


def build_xlsx(path, sheets):
    content_types = [
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">',
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
        '<Default Extension="xml" ContentType="application/xml"/>',
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>',
    ]
    for i in range(len(sheets)):
        content_types.append(
            f'<Override PartName="/xl/worksheets/sheet{i + 1}.xml" '
            'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        )
    content_types.append(
        '<Override PartName="/xl/styles.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
    )
    content_types.append(
        '<Override PartName="/docProps/core.xml" '
        'ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>'
    )
    content_types.append(
        '<Override PartName="/docProps/app.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>'
    )
    content_types.append("</Types>")

    rels = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>'
        '<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>'
        "</Relationships>"
    )

    wb = [
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">',
        "<sheets>",
    ]
    for i, (name, _, _) in enumerate(sheets):
        wb.append(f'<sheet name="{escape(name)}" sheetId="{i + 1}" r:id="rId{i + 1}"/>')
    wb.append("</sheets></workbook>")

    wb_rels = [
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>',
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">',
    ]
    for i in range(len(sheets)):
        wb_rels.append(
            f'<Relationship Id="rId{i + 1}" '
            'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
            f'Target="worksheets/sheet{i + 1}.xml"/>'
        )
    wb_rels.append(
        f'<Relationship Id="rId{len(sheets) + 1}" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
        'Target="styles.xml"/>'
    )
    wb_rels.append("</Relationships>")

    core = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">'
        "<dc:title>Northwind_DW</dc:title>"
        "<dc:creator>Proyecto Northwind RFM</dc:creator>"
        "<cp:lastModifiedBy>Proyecto Northwind RFM</cp:lastModifiedBy>"
        '<dcterms:created xsi:type="dcterms:W3CDTF">2026-11-26T00:00:00Z</dcterms:created>'
        '<dcterms:modified xsi:type="dcterms:W3CDTF">2026-11-26T00:00:00Z</dcterms:modified>'
        "</cp:coreProperties>"
    )

    app = (
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" '
        'xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">'
        "<Application>Python OOXML</Application></Properties>"
    )

    with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("[Content_Types].xml", "".join(content_types))
        z.writestr("_rels/.rels", rels)
        z.writestr("xl/workbook.xml", "".join(wb))
        z.writestr("xl/_rels/workbook.xml.rels", "".join(wb_rels))
        z.writestr("xl/styles.xml", STYLES)
        z.writestr("docProps/core.xml", core)
        z.writestr("docProps/app.xml", app)
        for i, (_, columns, sheet_xml) in enumerate(sheets):
            z.writestr(f"xl/worksheets/sheet{i + 1}.xml", sheet_xml)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--input", required=True)
    ap.add_argument("--output", required=True)
    args = ap.parse_args()

    out_csv = os.path.join(args.output, "csv")
    os.makedirs(out_csv, exist_ok=True)

    sheets = []
    for table in TABLES:
        src = os.path.join(args.input, table["name"] + ".json")
        with open(src, "r", encoding="utf-8-sig") as fh:
            rows = json.load(fh)

        columns = table["cols"]

        # CSV UTF-8 con BOM (compatible con Excel y Power BI)
        csv_path = os.path.join(out_csv, table["name"] + ".csv")
        with open(csv_path, "w", encoding="utf-8-sig", newline="") as fh:
            writer = csv.writer(fh, lineterminator="\r\n")
            writer.writerow([c for c, _ in columns])
            for row in rows:
                writer.writerow([fmt_value(row.get(c), k) for c, k in columns])

        sheets.append((table["name"], columns, build_sheet(columns, rows)))
        print(f"{table['name']}: {len(rows)} filas -> {csv_path}")

    xlsx_path = os.path.join(args.output, "Northwind_DW.xlsx")
    build_xlsx(xlsx_path, sheets)
    print(f"XLSX -> {xlsx_path} ({os.path.getsize(xlsx_path)} bytes)")


if __name__ == "__main__":
    main()
