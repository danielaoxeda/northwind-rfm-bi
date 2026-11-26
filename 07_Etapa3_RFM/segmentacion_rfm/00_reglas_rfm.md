# Reglas RFM consolidadas — aprobadas para implementar

Fecha de evaluación inicial: **1998-05-07**. Fecha de evaluación dinámica en
Power BI: la fecha seleccionada por el usuario, limitada al máximo de fechas
disponibles en el DW.

## 1. Puntajes exactos (solo clientes con compras hasta la evaluación)

Los cortes son enteros para R/F y decimales exactos para M. No hay huecos ni
solapamientos; los empates reciben el mismo puntaje.

| Puntaje | R, días (menor mejor) | F, pedidos (mayor mejor) | M, USD (mayor mejor) |
|---:|---|---|---|
| 5 | R ≤ 8 | F ≥ 14 | M ≥ 20 000 |
| 4 | 9 ≤ R ≤ 16 | 11 ≤ F ≤ 13 | 11 500 ≤ M < 20 000 |
| 3 | 17 ≤ R ≤ 31 | 8 ≤ F ≤ 10 | 5 200 ≤ M < 11 500 |
| 2 | 32 ≤ R ≤ 70 | 6 ≤ F ≤ 7 | 3 000 ≤ M < 5 200 |
| 1 | R ≥ 71 | 1 ≤ F ≤ 5 | 0 < M < 3 000 |

F=0 o M=0 no se puntúa: corresponde a **Sin compras**. R no es NULL para un
cliente con compras. La puntuación R2 acaba en 70 y R1 comienza en 71; la
actividad (60 días) es una regla aparte y no altera el umbral R aprobado.

## 2. Estado de actividad y clasificación excluyente

**Activo** significa una compra en los últimos 60 días inclusive:
`Recencia_Dias <= 60`. Un cliente activo nunca se llama Inactivo, En riesgo ni
Frecuente solo por su puntuación. Los activos no-VIP se dividen en `Ocasional`
(baja F y M) y `Activo` (resto).

Prioridad de asignación:

1. **Sin compras**: no existe venta hasta la fecha de evaluación. No recibe
   puntajes.
2. **VIP**: tiene compras y `SR >= 4 AND SF >= 4 AND SM >= 4`.
3. **Ocasional**: activo no-VIP y `SF <= 2 AND SM <= 2`.
4. **Activo**: activo no-VIP que no cumple la regla Ocasional.
5. **En riesgo**: no activo y `(SF >= 4 OR SM >= 4)`. Cliente valioso en el
   pasado, con recencia de 61 días o más.
6. **Frecuente**: no activo, no En riesgo, `SF >= 3`.
7. **Inactivo**: no activo, no En riesgo, `SF < 3`.

Las condiciones de los pasos son excluyentes por orden y el último caso es el
fallback. `En riesgo` va antes de `Frecuente` para identificar clientes que
fueron valiosos pero llevan más de 60 días sin comprar. Activo/Ocasional
distingue actividad reciente alta o moderada de actividad reciente baja, sin
confundir ninguna con inactividad.

### Convención para KPI

- **Activo** (KPI 1): R ≤ 60 días al corte/evaluación.
- **% VIP**: VIP / clientes con compras al corte, no sobre los 91 clientes.
- **Sin compras**: se reporta aparte y no entra al denominador de puntajes.

## 3. Distribución histórica al 1998-05-07

R/F/M se calculan con pedidos hasta el corte. Los resultados SQL verificables
se registran en `evidencias/2026-11-26_segmentos_consolidados.txt`.
Distribución de estados: 89 clientes con compras, 2 sin compras. Los conteos
por segmento se toman de la evidencia SQL. Actividad 60d: 67 clientes.
Evidencia SQL:
`evidencias/2026-11-26_segmentos_consolidados.txt`.

### Conteos finales por puntaje (89 compradores)

| Score | R | F | M |
|---:|---:|---:|---:|
| 1 | 18 | 26 | 18 |
| 2 | 17 | 15 | 18 |
| 3 | 17 | 20 | 18 |
| 4 | 17 | 10 | 17 |
| 5 | 20 | 18 | 18 |

## 4. No confundir puntajes con decisiones de negocio

Las bandas aprobadas producen cinco puntajes, pero el mapeo a los segmentos
anteriores es una regla adicional de negocio. No usar `NTILE`: dividiría
empates arbitrariamente y variaría los límites con cada actualización.
