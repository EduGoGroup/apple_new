# EduGo Native Apple - Especificacion de Procesos

## Documento de Referencia para Implementacion en Swift 6.2

**Proyecto origen**: EduGo KMP (Android/iOS/Desktop/Web)
**Proyecto destino**: EduGo Apple Native (iPhone/iPad/Mac)
**APIs compartidas**: edugo-api-mobile (puerto 8080) + edugo-api-administracion (puerto 8081)
**Fecha**: Febrero 2026

---

## Indice de Documentos

| # | Documento | Descripcion |
|---|-----------|-------------|
| 01 | [Arquitectura General](./01-ARQUITECTURA-GENERAL.md) | Vision global, APIs, plataformas, filosofia de Dynamic UI |
| 02 | [Autenticacion y Tokens](./02-AUTENTICACION-TOKENS.md) | Login, JWT, refresh automatico, session restore, logout |
| 03 | [RBAC y Permisos](./03-RBAC-PERMISOS.md) | Roles, permisos, ActiveContext, menus dinamicos |
| 04 | [Resiliencia de Red](./04-RESILIENCIA-RED.md) | CircuitBreaker, RateLimiter, RetryPolicy, configuracion por entorno |
| 05 | [Dynamic UI - Filosofia](./05-DYNAMIC-UI-FILOSOFIA.md) | Concepto server-driven UI, templates, instancias, slots, zones |
| 06 | [Dynamic UI - Renderizado](./06-DYNAMIC-UI-RENDERIZADO.md) | Pipeline de renderizado, patterns, controles, bindings |
| 07 | [Dynamic UI - Acciones](./07-DYNAMIC-UI-ACCIONES.md) | Sistema de acciones, handlers genericos, handlers custom |
| 08 | [Navegacion Adaptativa](./08-NAVEGACION-ADAPTATIVA.md) | TabBar, Sidebar, NavigationSplitView, adaptacion por dispositivo |
| 09 | [Dual API Routing](./09-DUAL-API-ROUTING.md) | Mobile API vs Admin API, prefijo admin:, endpoints completos |
| 10 | [Adaptacion Apple Design](./10-ADAPTACION-APPLE-DESIGN.md) | Mapeo de patterns a SwiftUI, HIG, size classes, platform idioms |

---

## Como usar este documento

1. Leer **01-Arquitectura** para entender la vision global
2. Implementar **02-Autenticacion** primero (es prerequisito de todo)
3. Implementar **03-RBAC** junto con autenticacion
4. Implementar **04-Resiliencia** como capa de red
5. Implementar **05/06/07-Dynamic UI** como el core del renderizado
6. Implementar **08-Navegacion** para el shell de la app
7. Usar **09-Dual API** como referencia de endpoints
8. Usar **10-Adaptacion Apple** como guia de diseno

Cada documento es autocontenido y describe PROCESOS, no codigo. El objetivo es que sirva como especificacion funcional para implementar en Swift 6.2 con SwiftUI, siguiendo los estandares de Apple.
