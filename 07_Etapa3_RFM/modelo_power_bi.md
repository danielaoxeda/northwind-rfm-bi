# Modelo Power BI — configuración y colaboración

Guía para construir el modelo estrella desde `09_Exportacion/Northwind_DW.xlsx`,
validar las medidas DAX y decidir el formato de versionado.

---

## 1. Verificación del archivo para Power BI

| Comprobación | Resultado |
|---|---|
| Libro OOXML abre como ZIP válido | Sí (`testzip` sin errores) |
| Todas las partes XML bien formadas | Sí |
| Relaciones internas resueltas | Sí (sin destinos faltantes) |
| Cuatro hojas con nombres exactos | Sí |
| Filas por hoja (incluye cabecera) | 92 / 78 / 673 / 2156 |
| Tipos: fecha real, importes numéricos | Sí |
| CSV UTF-8 con BOM y acentos correctos | Sí |

Power BI Desktop instalado en el equipo:

- `C:\Program Files\Microsoft Power BI Desktop\bin\PBIDesktop.exe` — 2.139.1678.0
- Microsoft Store — 2.160.1151.0

La validación estructural está en
`09_Exportacion/evidencias/2026-11-26_verificacion_exportacion.txt`. **La
apertura en la interfaz de Power BI es manual** y queda pendiente de
confirmación visual; no se simula.

### Pasos exactos de importación (manual)

1. Abrir **Power BI Desktop**.
2. **Inicio → Obtener datos → Libro de Excel**.
3. Seleccionar `09_Exportacion/Northwind_DW.xlsx` → **Conectar**.
4. En el navegador marcar las cuatro hojas → **Transformar datos**.
5. En Power Query, para cada tabla:
   - `Dim_Tiempo[Fecha_Completa]` → tipo **Fecha**.
   - `ID_Tiempo`, `ID_Cliente`, `ID_Producto`, `ID_Hecho_Venta`, `OrderID`,
     `ProductID`, `Cantidad`, `Dia`, `Mes`, `Trimestre`, `Anio` → **Número
     entero**.
   - `Precio_Unitario`, `Descuento`, `Monto_Total` → **Número decimal fijo**.
   - Resto → **Texto**.
6. **Inicio → Cerrar y aplicar**.
7. Verificar en la vista **Datos** los conteos: 91 / 77 / 672 / 2155.

---

## 2. Modelo estrella

### Relaciones (vista Modelo)

| Desde (varios) | Hacia (uno) | Cardinalidad | Dirección | Activa |
|---|---|---|---|---|
| `Hechos_Ventas[ID_Cliente]` | `Dim_Cliente[ID_Cliente]` | *:1 | Única | Sí |
| `Hechos_Ventas[ID_Producto]` | `Dim_Producto[ID_Producto]` | *:1 | Única | Sí |
| `Hechos_Ventas[ID_Tiempo]` | `Dim_Tiempo[ID_Tiempo]` | *:1 | Única | Sí |

- No crear relaciones entre dimensiones.
- No usar filtros bidireccionales.
- Ocultar de la vista de informe las claves técnicas.

### Tabla de fechas

1. Seleccionar `Dim_Tiempo`.
2. **Herramientas de tabla → Marcar como tabla de fechas → Fecha_Completa**.
3. `Nombre_Mes` ordenado por `Mes`.
4. Jerarquía opcional: `Anio → Trimestre → Mes → Fecha_Completa`.

### Medidas

Crear la tabla `Parametros` y las medidas de
`07_Etapa3_RFM/medidas_dax/01_medidas_base.dax`:

1. **Modelado → Nueva tabla** → pegar el bloque `Parametros`.
2. **Modelado → Nueva medida** → pegar cada medida.
3. Formato: `Monto Total` y `Ticket` en moneda USD; `Recencia (dias)` entero.

### Validación esperada en Power BI

| Medida / control | Valor esperado |
|---|---:|
| `Fecha de Corte` | 1998-05-07 |
| `Clientes Totales` | 91 |
| `Clientes con Compras` | 89 |
| `Clientes Sin Compras` | 2 |
| `Recencia (dias)` (total) | 1 |
| `Recencia Promedio (dias)` | 52,56 |
| `Frecuencia` (total) | 830 |
| `Monto Total` | 1 265 793,0395 |

Estos valores ya se contrastaron con SQL en
`07_Etapa3_RFM/evidencias/2026-11-26_contraste_dax_sql.txt`. Si Power BI
devuelve algo distinto, revisar relaciones, tipos y la fecha de corte antes de
continuar.

---

## 3. ¿Conviene el formato PBIP?

**Recomendación: sí, para la Etapa 3, una vez aprobados los umbrales.**

PBIP (Power BI Project) guarda el modelo y el informe como archivos de texto:

```
Northwind_RFM.pbip
Northwind_RFM.SemanticModel/
  definition/
    model.tmdl
    tables/*.tmdl
    relationships.tmdl
Northwind_RFM.Report/
  definition/...
```

### Ventajas

- **Versionado legible:** las medidas DAX y las relaciones quedan en TMDL, con
  diffs claros en GitHub.
- **Colaboración:** varios integrantes pueden revisar medidas y cambios sin
  abrir un `.pbix` binario.
- **Menos conflictos:** los cambios en medidas se aíslan por archivo; el
  reporte visual sigue siendo JSON y puede dar conflictos, pero es revisable.
- **Integración con Git:** se pueden ignorar cachés (`.pbi/`, `*.pbix.tmp`) y
  versionar solo la definición.

### Limitaciones

- Requiere Power BI Desktop para crear y probar; no se puede generar un PBIP
  válido desde SQL ni desde scripts sin la aplicación.
- El reporte visual se guarda como JSON: los conflictos de diseño se resuelven
  a mano.
- Algunas características nuevas pueden no estar soportadas en PBIP según la
  versión.
- Nunca debe contener credenciales: la conexión usa los archivos exportados.

### Cómo adoptarlo

1. Construir y validar el modelo con el XLSX (sección 1–2).
2. **Archivo → Guardar como → Power BI Project (*.pbip)**.
3. Guardar en `07_Etapa3_RFM/power_bi/Northwind_RFM.pbip`.
4. Confirmar que `.gitignore` excluye cachés y que se versionan `.pbip`,
   `*.SemanticModel/definition/**` y `*.Report/definition/**`.
5. Hacer commits pequeños: modelo, medidas, páginas del reporte.

**No se genera ningún PBIP en esta fase** para no producir archivos inválidos.

---

## 4. Instrucciones de trabajo colaborativo

1. Actualizar la rama: `git pull` (cuando exista remoto) y trabajar siempre en
   `feature/consolidacion-dw` o en una rama derivada.
2. Regenerar datos si cambió el DW:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\09_Exportacion\exportar_datos.ps1
   python .\09_Exportacion\verificar_exportacion.py
   ```

3. En Power BI, **Actualizar** y comprobar la matriz de validación.
4. Commits pequeños y en español; no hacer `push` sin autorización.
5. No versionar `.pbix` con credenciales ni cachés; el backup `.bak` permanece
   fuera de Git.
6. Documentar cada cambio de umbral o segmento en
   `07_Etapa3_RFM/segmentacion_rfm/` antes de implementarlo.

---

## 5. Pendientes que requieren aprobación

- Umbrales de puntaje 1–5 y reglas de segmento (ver
  `segmentacion_rfm/02_propuesta_umbrales.sql`).
- Definición de "cliente activo" y de la ventana de los KPI.
- Reformulación de metas en USD.
- Adopción formal de PBIP al iniciar el dashboard.
