# Reglas RFM propuestas (pendientes de aprobación)

Documento de trabajo para la Etapa 3. Define puntajes 1–5 y segmentos
excluyentes a partir de la distribución real. **No implementar en Power BI
hasta recibir aprobación.**

Fecha de corte: **1998-05-07**. Universo puntuado: **89 clientes con compras**.
Los **2 sin compras** (FISSA 22 y PARIS 57) se clasifican aparte y no reciben
puntaje.

---

## 1. Base estadística

| Métrica | Mín | Máx | Promedio | p20 | p40 | p60 | p80 |
|---|---:|---:|---:|---:|---:|---:|---:|
| R (días) | 1 | 658 | 52,56 | 8 | 16 | 30,8 | 70,4 |
| F (pedidos) | 1 | 31 | 9,326 | 5 | 7 | 10 | 13,4 |
| M (USD) | 100,80 | 110 277,31 | 14 222,39 | 2 975,56 | 5 182,98 | 11 445,41 | 19 926,91 |

Los percentiles se calcularon con `PERCENTILE_CONT`. Los cortes operativos se
redondearon para que sean legibles y reproducibles.

---

## 2. Puntajes 1–5

### Recencia (menor es mejor)

| Puntaje | Regla | Clientes |
|---:|---|---:|
| 5 | R ≤ 8 | 20 |
| 4 | 9 ≤ R ≤ 16 | 17 |
| 3 | 17 ≤ R ≤ 31 | 17 |
| 2 | 32 ≤ R ≤ 70 | 17 |
| 1 | R > 70 | 18 |

### Frecuencia (mayor es mejor)

| Puntaje | Regla | Clientes |
|---:|---|---:|
| 5 | F ≥ 14 | 18 |
| 4 | 11 ≤ F ≤ 13 | 10 |
| 3 | 8 ≤ F ≤ 10 | 20 |
| 2 | 6 ≤ F ≤ 7 | 15 |
| 1 | F ≤ 5 | 26 |

### Monto (mayor es mejor)

| Puntaje | Regla | Clientes |
|---:|---|---:|
| 5 | M ≥ 20 000 | 18 |
| 4 | 11 500 ≤ M < 20 000 | 17 |
| 3 | 5 200 ≤ M < 11 500 | 18 |
| 2 | 3 000 ≤ M < 5 200 | 18 |
| 1 | M < 3 000 | 18 |

### Empates

Los umbrales usan `≤` o `<` de forma consistente, de modo que **todos los
clientes con el mismo valor reciben el mismo puntaje**. No se usa `NTILE`, que
reparte empates de forma arbitraria.

Clientes exactamente en cada límite:

| Límite | R | F | M |
|---|---:|---:|---:|
| p20 | 3 en R=8 | 10 en F=5 | 0 |
| p40 | 3 en R=16 | 7 en F=7 | 0 |
| p60 | 1 en R=31 | 11 en F=10 | 0 |
| p80 | 0 en R=70 | 3 en F=13 | 0 |

Consecuencia: los grupos no son exactamente 20 % cada uno. En frecuencia, el
puntaje 1 concentra 26 clientes (29 %) porque hay muchos clientes con 1–5
pedidos. Es el comportamiento correcto al respetar empates.

### Puntaje combinado

`RFM = R + F + M`, entre 3 y 15. Distribución real:

| RFM | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Clientes | 8 | 5 | 9 | 6 | 6 | 12 | 5 | 7 | 5 | 7 | 6 | 7 | 6 |

---

## 3. Segmentos propuestos

Se evalúan **en este orden**; el primer `CASE` que cumple asigna el segmento.
Así se garantiza exclusividad y cobertura total.

| Orden | Segmento | Regla | Clientes | % de 89 |
|---:|---|---|---:|---:|
| 1 | **VIP** | R ≥ 4 y F ≥ 4 y M ≥ 4 | 17 | 19,1 % |
| 2 | **En riesgo** | no VIP, R ≤ 2 y (F ≥ 3 o M ≥ 3) | 15 | 16,9 % |
| 3 | **Frecuentes** | no VIP, R ≥ 3 y F ≥ 3 | 19 | 21,3 % |
| 4 | **Inactivos** | el resto | 38 | 42,7 % |
| — | **Sin compras** | no tiene filas en `Hechos_Ventas` | 2 | — |

### Perfil promedio por segmento

| Segmento | R promedio | F promedio | M promedio |
|---|---:|---:|---:|
| VIP | 7,0 | 16,6 | 35 188 |
| Frecuentes | 16,1 | 11,8 | 19 007 |
| En riesgo | 82,9 | 9,7 | 12 203 |
| Inactivos | 79,2 | 4,7 | 3 248 |

### Por qué estas reglas

- **VIP** exige buen desempeño en las tres dimensiones, no solo gasto alto.
- **En riesgo** captura clientes que fueron valiosos (frecuencia o monto altos)
  pero llevan más de ~30 días sin comprar (R ≤ 2). Se evalúa antes que
  "Frecuentes" para no ocultar la fuga.
- **Frecuentes** son clientes con actividad razonable y no recientes de riesgo.
- **Inactivos** agrupa a quienes nunca fueron intensivos y además están fríos.
- **Sin compras** queda fuera: no tiene sentido asignarle R, F o M.

### Verificación de exclusividad

- `Clasificados = 89`, `Sin_Clasificar = 0`.
- Ningún cliente puede cumplir dos reglas por el orden del `CASE`.
- Cambiar cualquier umbral exige recalcular y volver a ejecutar
  `02_propuesta_umbrales.sql`.

---

## 4. Puntos a aprobar

1. Umbrales de R, F y M de la sección 2.
2. Reglas y nombres de los segmentos de la sección 3.
3. Definición de "cliente activo" para el KPI 1 (se propone R ≤ 90).
4. Si el denominador de `% VIP` es 91 (todos) o 89 (con compras).
5. Si "En riesgo" debe exigir además M ≥ cierto valor.

Hasta la aprobación, estas reglas son solo un análisis y no se implementan como
medidas ni columnas del modelo.
