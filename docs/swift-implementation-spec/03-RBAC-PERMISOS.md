# 03 - RBAC y Permisos

## 3.1 Modelo RBAC

EduGo implementa Role-Based Access Control con contexto activo. Un usuario puede tener multiples roles en diferentes escuelas, pero solo un contexto esta activo a la vez.

### Estructura
```
Usuario
  └── Tiene multiples UserRoles (via tabla user_roles)
       └── Cada UserRole tiene:
            - role_id → apunta a un Role
            - school_id → en que escuela tiene ese rol

Role
  └── Tiene multiples Permissions (via tabla role_permissions)
       └── Cada Permission tiene:
            - key: "materials:read"
            - resource_id: a que recurso aplica

ActiveContext (lo que el JWT lleva)
  └── El contexto ACTIVO seleccionado al hacer login
       - role_id, role_name
       - school_id, school_name
       - academic_unit_id, academic_unit_name
       - permissions: [lista plana de permission keys]
```

## 3.2 Roles del Sistema

| Rol | Scope | Descripcion |
|-----|-------|-------------|
| `super_admin` | system | Administrador de toda la plataforma |
| `platform_admin` | system | Similar a super_admin, gestiona plataforma |
| `school_admin` | school | Administrador de una escuela |
| `school_director` | school | Director de escuela |
| `teacher` | unit | Profesor, opera dentro de unidades academicas |
| `student` | unit | Estudiante, consume contenido |
| `guardian` | system | Apoderado/padre, ve progreso de sus hijos |

## 3.3 Permisos por Modulo

### Users
- `users:create` - Crear usuarios
- `users:read` - Ver lista/detalle de usuarios
- `users:update` - Editar usuarios
- `users:delete` - Eliminar usuarios
- `users:read:own` - Ver solo su propio perfil
- `users:update:own` - Editar solo su propio perfil

### Schools
- `schools:create`, `schools:read`, `schools:update`, `schools:delete`, `schools:manage`

### Units (Unidades Academicas)
- `units:create`, `units:read`, `units:update`, `units:delete`

### Materials
- `materials:create`, `materials:read`, `materials:update`, `materials:delete`
- `materials:publish` - Publicar material
- `materials:download` - Descargar archivos

### Assessments
- `assessments:create`, `assessments:read`, `assessments:update`, `assessments:delete`
- `assessments:publish` - Publicar evaluacion
- `assessments:grade` - Calificar
- `assessments:attempt` - Rendir evaluacion
- `assessments:view_results` - Ver resultados

### Progress
- `progress:read`, `progress:update`, `progress:read:own`

### Stats
- `stats:global` - Estadisticas del sistema
- `stats:school` - Estadisticas por escuela
- `stats:unit` - Estadisticas por unidad

### Screen Config
- `screen_templates:read/create/update/delete`
- `screen_instances:read/create/update/delete`
- `screens:read`

### Permissions Management
- `permissions_mgmt:read`, `permissions_mgmt:update`

## 3.4 Verificacion de Permisos en la App

### Verificar en el cliente
El `UserContext` contiene la lista completa de permisos del usuario. La app verifica localmente:

```
Metodos necesarios en UserContext:

hasPermission("materials:read") → Bool
  // Busca coincidencia exacta en la lista de permissions

hasAnyPermission("materials:read", "materials:create") → Bool
  // True si tiene AL MENOS uno

hasAllPermissions("materials:read", "materials:create") → Bool
  // True si tiene TODOS

hasRole("teacher") → Bool
  // Comparacion case-insensitive contra roleName

hasSchool() → Bool
  // schoolId no es nil/vacio

hasAcademicUnit() → Bool
  // academicUnitId no es nil/vacio
```

### Verificar en el servidor
El backend verifica permisos en cada request via middleware. Si el usuario no tiene permiso, responde 403.

### Regla importante
La verificacion en el cliente es para UX (ocultar botones, menus). La verificacion en el servidor es para SEGURIDAD. Ambas deben estar alineadas pero la del servidor es la fuente de verdad.

## 3.5 Generacion Dinamica de Menus

### Proceso

1. **App solicita navegacion**: `GET /v1/screens/navigation?platform=mobile`
2. **Backend procesa**:
   - Lee los Resources del sistema (dashboard, admin, academic, content, reports + hijos)
   - Filtra segun permisos del usuario autenticado
   - Solo incluye resources donde `is_menu_visible = true`
   - Ordena por `sort_order`
   - Genera la estructura de navegacion

3. **Respuesta**: NavigationDefinition
   ```
   {
     "bottom_nav": [           // Items para TabBar/bottom navigation
       {
         "key": "dashboard",
         "label": "Dashboard",
         "icon": "dashboard",
         "screen_key": "dashboard-home",
         "sort_order": 1
       },
       {
         "key": "materials",
         "label": "Materials",
         "icon": "folder",
         "screen_key": "materials-list",
         "sort_order": 2
       },
       ...
     ],
     "drawer_items": [         // Items para sidebar/drawer (futuro)
       {
         "key": "admin",
         "label": "Administration",
         "icon": "settings",
         "sort_order": 1,
         "children": [
           {"key": "users", "label": "Users", "icon": "users", "screen_key": "users-list"},
           {"key": "schools", "label": "Schools", "icon": "school", "screen_key": "schools-list"}
         ]
       }
     ],
     "version": 1
   }
   ```

4. **App renderiza** la navegacion segun la plataforma:
   - iPhone: TabBar con bottom_nav items
   - iPad: Sidebar con drawer_items (hierarchico)
   - Mac: Sidebar permanente con drawer_items

### Recursos del Sistema (Arbol)
```
dashboard (system)
admin (system)
  ├── users (school)
  ├── schools (system)
  ├── roles (system)
  └── permissions_mgmt (system)
academic (school)
  ├── units (school)
  └── memberships (school)
content (unit)
  ├── materials (unit)
  └── assessments (unit)
reports (school)
  ├── progress (unit)
  └── stats (school)
```

### Ejemplo por rol

**super_admin ve**: dashboard, admin (users, schools, roles, permissions), academic (units, memberships), content (materials, assessments), reports (progress, stats)

**teacher ve**: dashboard, content (materials, assessments), reports (progress)

**student ve**: dashboard, content (materials, assessments)

**guardian ve**: dashboard (solo su dashboard de guardian)

## 3.6 Switch Context

Un usuario con multiples roles puede cambiar de contexto sin hacer logout:

1. `POST /v1/auth/switch-context`
   ```
   {
     "school_id": "uuid",
     "role_id": "uuid"
   }
   ```
2. Backend verifica que el usuario tiene ese rol en esa escuela
3. Responde con nuevo `access_token` y `active_context`
4. App actualiza Keychain y estado
5. Recargar navegacion (permisos cambiaron)
6. Recargar pantalla actual

## 3.7 Resource-Screen Mapping

Cada recurso RBAC tiene asociadas pantallas dinamicas:

```
Resource "materials" → Screen Instances:
  - materials-list (type: list, default)
  - material-detail (type: detail)
  - material-create (type: form)
  - material-edit (type: form-edit)
```

Este mapping permite que el backend sepa que pantallas servir para cada recurso segun el rol y permisos del usuario.

## 3.8 Seleccion de Dashboard por Rol

La pantalla de dashboard es especial: se selecciona segun el rol activo del usuario:

| Rol | Screen Key |
|-----|-----------|
| super_admin | dashboard-superadmin |
| platform_admin | dashboard-superadmin |
| school_admin | dashboard-schooladmin |
| school_director | dashboard-schooladmin |
| teacher | dashboard-teacher |
| guardian | dashboard-guardian |
| student (default) | dashboard-student |

La app implementa esta logica localmente al navegar al tab de dashboard.
