# Actividad 3 — Diccionario de datos completado

| Columna | Clasificación (Unidad II) | Finalidad | Control aplicado | ¿Cambios auditados? | Regla de calidad |
| --- | --- | --- | --- | --- | --- |
| id | Dato interno | Identificar al cliente en el sistema | Llave primaria; generado por el sistema | Sí, trigger `trg_auditoria_clientes` | Unicidad y no nulo |
| nombre | Dato personal (identificador directo) | Identificar al cliente | Acceso restringido por rol | Sí, trigger `trg_auditoria_clientes` | No nulo; sin espacios de más |
| correo | Dato personal | Notificaciones al cliente | Acceso restringido por rol | Sí, trigger `trg_auditoria_clientes` | No nulo; formato de correo; unicidad (sin distinguir mayúsculas) |
| rfc | Dato personal | Facturación | Vista enmascarada para soporte (U2) | Sí, LAB-01 Parte B | Formato RFC |
| telefono | Dato personal | Comunicación y seguimiento | Acceso restringido por rol | Sí, trigger `trg_auditoria_clientes` | Formato: 10 dígitos |
| ciudad | Dato personal (ubicación) | Analítica agregada y logística | Acceso por rol | Sí, trigger `trg_auditoria_clientes` | Valor de catálogo de ciudades (sin variantes de escritura) |
| segmento | Dato de negocio | Analítica y estrategia comercial | Acceso por rol | Sí, trigger `trg_auditoria_clientes` | Valores permitidos (catálogo de segmentos) |

## Preguntas

### 1. ¿Qué ventaja tiene guardar el significado en COMMENT en lugar de solo en un documento aparte?

El significado viaja con el dato: se consulta desde el mismo motor (`\d+`, `col_description`), se respalda y se migra con la base, y no se desactualiza tan fácilmente como un documento externo que nadie abre.

### 2. ¿Quedaron registrados los COMMENT en la bitácora? ¿Con qué nivel de log_statement?

`COMMENT ON` es una sentencia DDL, así que queda registrada si `log_statement` está en `ddl`, `mod` o `all`; con `none` no aparece. Se verifica con:

```sql
SHOW log_statement;
SELECT * FROM dba.bitacora WHERE linea ILIKE '%COMMENT ON%';
```

### 3. ¿Qué información del diccionario debe mantenerse fuera del motor? ¿Por qué?

Los nombres y aprobaciones de propietarios, la base legal y el aviso de privacidad, las políticas de clasificación y retención, y el historial de decisiones. Son información organizacional que el motor no conoce ni controla, que cambia sin tocar la base y que debe sobrevivir si la base se pierde o se migra. Además, los COMMENT los puede leer cualquier usuario con acceso al catálogo, así que no deben incluir datos sensibles.
