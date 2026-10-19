# Pregunta

¿Qué ocurriría si una persona obtiene acceso de lectura a esta tabla?
Si alguien logra leer la tabla, verá todas las contraseñas en texto plano tal como fueron almacenadas. Eso compromete de inmediato a cada cuenta, porque el atacante puede iniciar sesión como cualquiera de los usuarios sin necesidad de romper ninguna otra capa de seguridad.

## Preguntas 7.3

¿Son iguales? Si no son iguales, ¿por qué?
No son iguales. Si se usa la misma contraseña, el hash generado cambia porque `gen_salt()` crea un salt aleatorio nuevo cada vez que se invoca.

¿Qué función cumple `gen_salt()`?
Genera un valor aleatorio llamado salt, que se añade a la contraseña antes de calcular el hash. Esto hace que el mismo texto base produzca resultados distintos en cada ejecución.

¿Qué función cumple `crypt()`?
Calcula el hash de la contraseña combinada con el salt recibido. El resultado incluye el algoritmo, el costo, el salt y el valor final del hash. Cuando se compara más tarde con otra contraseña, `crypt()` extrae el salt del hash almacenado, vuelve a calcular el valor y valida si coinciden.

¿Esto es cifrado reversible?
No. La operación de hash es unidireccional: no se puede recuperar la contraseña original a partir del resultado generado.

## Preguntas 7.5

¿Qué resultado obtuviste con la contraseña correcta?
La comparación devuelve verdadero porque el sistema toma el salt almacenado, recalcula el hash con la contraseña ingresada y obtiene la misma cadena que está guardada.

¿Qué resultado obtuviste con la contraseña incorrecta?
La comparación devuelve falso, porque aunque el salt sea el mismo, el hash resultante cambia completamente cuando la contraseña es distinta. Incluso un solo carácter diferente altera el resultado final.

¿Por qué no es necesario recuperar la contraseña original?
El sistema no necesita conocer la contraseña; solo necesita verificar si la persona que intenta acceder posee la credencial correcta. La validación se hace comparando hashes, no revelando el secreto original.

¿Por qué un hash no debe confundirse con cifrado?
El cifrado es reversible y se usa para proteger información que luego se necesita recuperar. El hash es una comprobación unidireccional: sirve para validar, no para deshacer la transformación ni recuperar el dato original.
