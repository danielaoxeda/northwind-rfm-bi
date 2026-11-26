# Exportación de datos para Power BI

Archivos generados desde `Northwind_DW` para compartir con el equipo y cargar
en Power BI, sin necesidad de conectarse a SQL Server.

| Archivo | Contenido | Tamaño |
|---|---|---:|
| `Northwind_DW.xlsx` | Libro con cuatro hojas: `Dim_Cliente`, `Dim_Producto`, `Dim_Tiempo`, `Hechos_Ventas` | 130 KB |
| `csv/Dim_Cliente.csv` | 91 filas, UTF-8 con BOM | 4,2 KB |
| `csv/Dim_Producto.csv` | 77 filas | 2,8 KB |
| `csv/Dim_Tiempo.csv` | 672 filas | 26,7 KB |
| `csv/Hechos_Ventas.csv` | 2155 filas | 121,8 KB |
| `diccionario_datos.md` | Columnas, tipos, claves y descripciones | — |
| `power_bi_instrucciones.md` | Importación, relaciones, tabla de fechas y actualización | — |

Los conteos y montos coinciden con SQL Server; la verificación completa está en
`evidencias/2026-11-26_verificacion_exportacion.txt`.

## Regenerar

Desde la raíz del repositorio:

```powershell
powershell -ExecutionPolicy Bypass -File .\09_Exportacion\exportar_datos.ps1
python .\09_Exportacion\verificar_exportacion.py
```

`exportar_datos.ps1` consulta `Northwind_DW` con autenticación de Windows, deja
los JSON intermedios en `_tmp/` (ignorado por Git) y llama a
`generar_xlsx_csv.py`, que produce el XLSX y los CSV sin dependencias externas
(solo biblioteca estándar de Python).

## Compartir con el equipo

### Opción A — Git (recomendada)

El XLSX y los CSV pesan menos de 1 MB en total y **sí se versionan**. El equipo
los obtiene al clonar o actualizar la rama:

```powershell
git clone https://github.com/danielaoxeda/northwind-rfm-bi.git
git checkout feature/consolidacion-dw
```

Cada actualización de datos se publica con un commit que incluya
`09_Exportacion/`.

### Opción B — Archivo directo

Compartir `Northwind_DW.xlsx` por correo, OneDrive o el aula virtual. Es
autocontenido: no requiere la base ni credenciales.

### Recomendaciones

- No editar los CSV a mano: se regeneran desde el DW y se sobrescriben.
- Si se comparte el `.pbix`, debe apuntar a una ruta local de estos archivos o
  publicarse en un área de trabajo de Power BI.
- No incluir cadenas de conexión ni credenciales en capturas o documentos.

## Notas de formato

- CSV en UTF-8 con BOM, separador coma, fechas `AAAA-MM-DD`, decimales con
  punto. Compatible con Excel y Power BI.
- En el XLSX, `Fecha_Completa` es una fecha real y los importes son numéricos.
- Los códigos `NCHAR` de origen se exportan sin espacios de relleno.
