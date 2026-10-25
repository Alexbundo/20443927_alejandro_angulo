# Arquitectura de privacidad y cumplimiento

```text
                         BASE DE DATOS
                              │
     ┌───────────────┬────────┼─────────────┬────────────────┐
     │               │        │             │                │
     ▼               ▼        ▼             ▼                ▼
 OPERACIÓN       PRIVACIDAD  ANALÍTICA    AUDITORÍA      RESPALDOS
 (schema         (schema     (schema      (schema        (cifrados,
 operacion)      privacidad) analitica)   auditoria)     con retención)
     │               │        ▲             ▲
     ▼               ▼        │             │
 Datos           Consentimiento│            │
 necesarios      Solicitudes   │            │
 para operación  ARCO          │            │
 ├─ contacto     Política de   │            │
 ├─ fiscales     retención     │            │
 │  (cifrados)                  │            │
 └─ ciclo de vida               │            │
     │                          │            │
     └── proceso de minimización ┘            │
         (agrega, generaliza,                 │
          seudonimiza)                        │
                                              │
     Todas las zonas envían eventos ─────────┘
```
