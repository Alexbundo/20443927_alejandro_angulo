# Actividad 5

## 1. ¿Qué campo distingue un acceso fallido de uno exitoso?

Dos campos de la misma línea, que conviene usar juntos:

- **`msg`**: `"Failed to authenticate"` frente a `"Successfully authenticated"`. Es el que se usó para filtrar.
- **`attr.result`**: el código de resultado. `0` indica éxito, y cualquier otro valor es un fallo (aquí `18` para credenciales incorrectas y `11` para usuario no encontrado).

## 2. ¿Qué diferencia hay entre el error de contraseña incorrecta y el de usuario inexistente? ¿Por qué el cliente recibe el mismo mensaje en ambos casos?

**Diferencia en la bitácora.** Con contraseña incorrecta, el usuario existe y falla la comprobación de la credencial: el error es `AuthenticationFailed: SCRAM authentication failed, storedKey mismatch` (`result: 18`). Con usuario inexistente, el servidor ni siquiera encuentra la cuenta: el error es `UserNotFound: Could not find user ... for db "comercial"` (`result: 11`). Esa distinción permite al administrador saber si alguien está probando contraseñas sobre una cuenta real o tanteando nombres de usuario.

**Por qué el cliente recibe lo mismo.** Ambos casos devuelven solo `Authentication failed.`, y es deliberado. Si el servidor respondiera "usuario no encontrado" para un caso y "contraseña incorrecta" para el otro, un atacante podría **enumerar cuentas válidas** .

## 3. ¿Por qué el nombre de la aplicación del intento fallido es `mongosh 2.10.0` y no `app-ventas-web`?

Porque las cadenas de conexión de los intentos fallidos **no incluyeron `appName=app-ventas-web`**. Se escribieron sin ese parámetro, y cuando el cliente no declara un nombre propio, el controlador envía el predeterminado.
