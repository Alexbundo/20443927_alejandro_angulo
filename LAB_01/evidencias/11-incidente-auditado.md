# Incidente auditado

## 1. Compara tu hipótesis de la Actividad 11 con este resultado

En la simulación, la conclusión fue que no se podía demostrar quién modificó el RFC, ni descartar a `soporte_ana`, ni conocer el valor anterior. Solo existía una hipótesis basada en circunstancias: el cambio era compatible con un rol que tuviera `UPDATE` sobre `clientes`. Era una deducción a partir del diseño de privilegios, no una prueba.

## 2. Escribe la sentencia `UPDATE` que restauraría el valor anterior

La forma más segura es leer el valor desde la propia evidencia, en lugar de teclearlo:

```sql
UPDATE public.clientes
SET rfc = (
    SELECT valores_antes ->> 'rfc'
    FROM auditoria.cambios_clientes
    WHERE id_evento = 1
)
WHERE id = 3;
```

## 3. ¿Qué columna conserva más valor para una investigación: `aplicacion` o `ip_cliente`? ¿Cuál puede falsificar el cliente con más facilidad?

**Conserva más valor `ip_cliente`.** Y la que el cliente puede falsificar con más facilidad es **`aplicacion`**.

`aplicacion` toma el valor de `application_name`, que el propio cliente escribe en la cadena de conexión. Cualquiera con las credenciales puede poner `app-ventas-web`, `reporte-mensual` o lo que quiera, sin ningún obstáculo.

`ip_cliente` proviene de `inet_client_addr()`, es decir, de la dirección que el servidor observa en la conexión TCP. El cliente no puede declararla en el protocolo, y para falsificarla debería controlar la red. Por eso permite correlacionar con otras fuentes: el firewall, los registros del DHCP, los de la red. Aun así tiene límites:

- **Un `NULL`** indica conexión por socket local, de modo que no hay dirección que registrar.
- **`127.0.0.1`** solo dice que el cliente está en el mismo equipo, como ocurre en esta práctica.
- **Una IP identifica un equipo, no una persona.**
  