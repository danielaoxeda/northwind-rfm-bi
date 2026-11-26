# Propuesta visual del dashboard (no construido)

Composición de una página ejecutiva y una página de detalle. Las cifras KPI
se muestran como resultados de la historia disponible, no como desempeño de
campañas.

## Página 1 — Resumen de cartera

**Franja superior: filtros**

- Fecha de evaluación (por defecto 1998-05-07; selector si se valida el corte
  dinámico).
- País, categoría y año.

**Fila de tarjetas**

1. Clientes con compras: 89.
2. Activos (R≤60): 67.
3. % VIP de compradores: 19,10 %.
4. Pedidos: 830.
5. Monto total: USD 1 265 793,0395.
6. Ticket promedio: USD 1 525,05 (meta nueva USD 500).

**Visuales**

- Barra horizontal de clientes por segmento: VIP, Activo, Ocasional, En riesgo,
  Frecuente, Inactivo; tarjeta aparte para 2 sin compras.
- Dispersión R vs F; tamaño/color por M/segmento. Excluir o etiquetar
  compradores ausentes sin puntaje.
- Tabla de clientes con R, F, M, scores y segmento; orden inicial por riesgo
  y monto.
- Línea de ventas por mes, con advertencia de que el histórico termina el
  1998-05-06 y el calendario solo cubre 672 días.

## Página 2 — Indicadores históricos

- KPI 2: clientes con ≥3 pedidos, Q1 1997 frente a Q1 1998.
- KPI 3: monto de cohorte Frecuente en ventanas comparables de 300 días.
- KPI 6: clientes en riesgo en ventanas iguales de 180 días.
- KPI 7: reactivación proxy por brecha de 61–120 días, claramente marcado
  **sin atribución a campaña**.
- Tabla de límites, fecha de corte, definición de población y advertencias.

## Semántica y accesibilidad

- Usar colores con contraste y etiquetas directas (no depender solo del color).
- Rojo/ámbar/verde no implica causalidad; incluir conteos junto a porcentajes.
- Mostrar moneda USD en todos los importes.
- Incluir tooltip con definición del indicador, ventana y denominador.
- Visuales propuestos; los siete KPI no se implementan en el dashboard durante
  esta fase.

## Estado

Especificación funcional únicamente. No hay PBIX/PBIP ni visuales creados.
