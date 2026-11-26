# Artefactos de compilación e IDE

Contenido movido aquí durante la Fase 2 para separar el código fuente de los
artefactos generados:

- `.vs/` — índices y estado del IDE.
- `bin/` — salida de compilación, incluidos los `.ispac`.
- `obj/` — archivos intermedios de compilación.
- `*.dtproj.user` — preferencias locales del proyecto.

Corresponden a los proyectos de `05_SSIS/01_Extraccion_2.2.2` y
`05_SSIS/02_Carga_2.2.5`. **No se versionan** (ver `.gitignore`) y se pueden
regenerar al abrir o compilar los proyectos en Visual Studio.

Los `.ispac` son los paquetes de despliegue de la Etapa 2 y se conservan aquí
como respaldo, no como fuente de verdad.
