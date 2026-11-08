# Actividad – Exportar la bitácora como evidencia y proteger su integridad

## 1. Un resumen SHA-256, ¿impide que alguien modifique la bitácora? ¿Qué permite demostrar?

No impide nada. Un hash no protege el archivo: cualquiera con acceso de escritura puede editarlo, borrarlo o reemplazarlo. Lo que hace es permitir **detectar** una modificación.

## 2. ¿Dónde debería guardarse el hash para que sea útil como control de integridad?

En un lugar que **no controle la misma persona o sistema que puede modificar la bitácora**. Un hash guardado al lado del archivo, en el mismo equipo y con los mismos permisos, no protege nada, porque ambos pueden alterarse a la vez.

## 3. La guía NIST SP 800-92 trata la conservación y protección de bitácoras. ¿Qué riesgos tiene conservar la bitácora solo en el servidor que la produce?

- **Pérdida por fallo o reinstalación.** Un fallo de disco, una reinstalación o recreación del servidor (algo habitual con contenedores) destruye la evidencia.
- **Alteración o borrado por un atacante.** Quien comprometa el servidor puede borrar o editar el log para ocultar su actividad. Es precisamente el escenario en el que más se necesita la evidencia.
- **Alteración por un administrador.** Como se vio en la actividad del trigger desactivado, quien controla el servidor controla también el instrumento que lo vigila. No hay independencia entre lo auditado y la evidencia.
- **Indisponibilidad durante un incidente.** Si el servidor está caído, saturado o comprometido, no se puede consultar la bitácora justo cuando hace falta.
- **Exposición de datos sensibles.** El log contiene datos personales y puede contener secretos, y en el servidor está sujeto a los permisos del sistema operativo, a menudo más amplios que los de la base de datos.

## 4. Propón durante cuánto tiempo conservarías esta bitácora y justifica tu criterio

conservar la bitácora 12 meses de forma accesible y, por el valor de la evidencia del laboratorio, mantener la copia exportada y su hash junto con el informe hasta que concluya el curso y el periodo de revisión o apelación de calificaciones, momento en que se depura bajo procedimiento autorizado.

Para un entorno de producción como el de nuestro caso, propondría 12 meses en línea.

- **Tiempo de detección.** Muchos incidentes se descubren meses después de ocurrir. Un plazo corto, de semanas, haría imposible investigar un cambio como el del RFC reportado por facturación, que apareció en un reporte posterior. Doce meses cubren al menos un ciclo completo de facturación y cierre anual.
- **Minimización de datos.** La bitácora contiene datos personales (RFC, correos, nombres en las sentencias). Conservarla indefinidamente aumenta el impacto de una filtración y choca con la política de retención de la Unidad II, que pide eliminar datos cuando ya no sean necesarios. Por eso el plazo debe ser finito y justificado.
- **Costo y gestión.** Más retención implica más almacenamiento, más respaldos y más superficie que proteger. Mover los registros antiguos a archivo cifrado y comprimido reduce el costo y el riesgo.
