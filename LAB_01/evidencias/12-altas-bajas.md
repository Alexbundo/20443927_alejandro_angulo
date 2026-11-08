# Actividad 13 – Altas y bajas en la auditoría

## 1. El cliente `Pedro Ruiz` ya no existe en `clientes`. ¿Dónde queda evidencia de que existió y de sus datos?

La evidencia queda en `auditoria.cambios_clientes`. El evento 2 prueba que fue dado de alta, quién lo hizo y cuándo, y el evento 3 prueba que fue eliminado, quién lo hizo y cuándo.

## 2. ¿Por qué `ip_cliente` está vacía en los eventos 2 y 3?

Porque el administrador se conectó por socket local, no por red. Cuando `psql` se ejecuta en el mismo equipo con `-U postgres` y sin indicar host, usa el canal local en lugar de TCP/IP, y `inet_client_addr()` devuelve `NULL` al no existir una dirección IP de origen. En la bitácora esa misma situación aparece como `client=[local]`.

## 3. La política de retención de la Unidad II pedía eliminar datos cuando ya no fueran necesarios. ¿Qué conflicto aparece? ¿Quién debe resolverlo?

Aparece un conflicto entre dos obligaciones legítimas. La política de retención y la protección de datos personales piden **no conservar datos más tiempo del necesario**: al eliminar a Pedro Ruiz de `clientes`, se espera que sus datos dejen de existir. La auditoría exige lo contrario: **conservar el historial** para poder reconstruir lo ocurrido, y por eso el RFC, el correo y el resto de sus datos siguen en `valores_antes` aunque el cliente ya fue borrado.

No es una decisión técnica del DBA, porque ambas posiciones tienen fundamento. Debe resolverla la organización, con participación de quienes responden por cada lado: el responsable de protección de datos o cumplimiento, el responsable de seguridad de la información, el área jurídica y la dirección como dueña del riesgo. El DBA ejecuta lo que se decida, pero no debería decidirlo solo, y tampoco debería ser quien depure su propia evidencia (separación de funciones).
