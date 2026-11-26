# Power BI

Recursos del dashboard de la Etapa 3.

Contenido previsto:

- `Northwind_RFM.pbix`: modelo, medidas y páginas del dashboard.
- Conexión a `Northwind_DW` mediante autenticación de Windows.
- Relaciones 1:N desde las dimensiones hacia `Hechos_Ventas`.
- Filtros por cliente, país, categoría y periodo.

Buenas prácticas:

- No almacenar credenciales en el archivo ni en el repositorio.
- Versionar el `.pbix` solo si su tamaño es razonable (menos de ~50 MB);
  de lo contrario, usar Git LFS o almacenamiento externo.
- Documentar el origen de cada visual en `evidencias/`.

Pendiente: construir el modelo en la Fase 3.
