# Medidas DAX

Documentación de las medidas del modelo de Power BI. Cada medida debe incluir
nombre, expresión, formato y descripción funcional.

Medidas previstas:

- Clientes activos
- Recencia promedio (días)
- Frecuencia promedio
- Monto total
- Ticket promedio por pedido
- % de clientes VIP
- Clientes en riesgo
- Tasa de reactivación

Convenciones:

- Nombres en español y sin prefijos ambiguos.
- Importes en USD, formato monetario de dos decimales.
- La recencia se calcula contra la fecha de corte definida, no con `TODAY()`.

Pendiente: crear el archivo `.dax` o el documento de medidas en la Fase 3.
