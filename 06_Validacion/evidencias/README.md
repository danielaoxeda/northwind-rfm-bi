# Evidencias de validación

Resultados reales de la reconstrucción de `Northwind_DW` ejecutada el
26 de noviembre de 2026 sobre la instancia local `STG_PERU` (SQL Server 2025).

| Archivo | Contenido |
|---|---|
| `2026-11-26_reconstruccion_ejecucion_1.txt` | Salida completa de la primera ejecución de `00_Ejecutar_Reconstruccion.sql` |
| `2026-11-26_reconstruccion_ejecucion_2.txt` | Salida de la segunda ejecución (prueba de reproducibilidad) |
| `2026-11-26_resultados_validaciones.txt` | Conteos, medidas, reconciliación contra `Northwind` y controles de calidad |

## Resultado de la reconstrucción

- Primera y segunda ejecución: **sin errores** (`exit code 0`).
- Las claves subrogadas y los checksums de las cuatro tablas son idénticos entre
  ambas ejecuciones: la carga es reproducible y no genera duplicados.
- `Northwind_DW` quedó con 91 clientes, 77 productos, 672 días de calendario y
  2155 líneas de hecho; monto total `1 265 793,0395`, igual que `Northwind`.

## Cómo reproducir

```powershell
sqlcmd -S localhost -E -C -b -f 65001 -i 00_Ejecutar_Reconstruccion.sql
```

Desde la raíz del repositorio. Las rutas `:r` del script maestro son relativas
al directorio de ejecución.
