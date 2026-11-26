# Archivo

Material histórico y artefactos que no forman parte del flujo vigente.

- La entrega original, con su estructura de carpetas inicial, está conservada
  en la rama `main` del repositorio.
- Los artefactos de compilación e IDE (`.vs/`, `bin/`, `obj/`, `*.user`) de
  ambos proyectos SSIS se movieron a `artefactos/`. Están excluidos de Git y
  se pueden regenerar abriendo o compilando los proyectos.
- Los backups `.bak` permanecen en `01_Fuente/` y `02_Staging/`, también
  excluidos de Git por tamaño.

No eliminar archivos de esta carpeta sin revisar antes la rama `main` y
`00_Documentacion/inventario_archivos.md`.
