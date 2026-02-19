# ADR 001: Reestructuracion para Xcode

## Estado
Aceptado

## Contexto
La estructura anterior basada en TIERs era confusa para navegacion en Xcode:
- TIER-2 tenia Domain e Infrastructure
- TIER-3 tenia Domain, Presentation y ViewModels
- 23 carpetas .build dispersas
- Proxy targets innecesarios
- Tiempo de build de ~5-8 minutos
- ~6.3GB de espacio en carpetas .build

## Decision
Reestructurar a nomenclatura funcional:
- Foundation, Core, Infrastructure, Domain, Presentation, Features
- Un solo Package.swift raiz
- Submodulos agrupados logicamente
- Consolidar Domain (TIER-2-Domain + TIER-3-Domain)
- Consolidar Presentation (TIER-3-Presentation + TIER-3-ViewModels)

## Nueva Estructura

```
EduGoModules/
├── Packages/
│   ├── Foundation/     <- TIER-0
│   ├── Core/           <- TIER-1
│   ├── Infrastructure/ <- TIER-2-Infrastructure
│   ├── Domain/         <- TIER-2-Domain + TIER-3-Domain
│   ├── Presentation/   <- TIER-3-Presentation + TIER-3-ViewModels
│   └── Features/       <- TIER-4
├── Apps/
├── Documentation/
└── Tools/
```

## Consecuencias

### Positivas
- Navegacion intuitiva en Xcode
- Build times reducidos (~2-3 min)
- Onboarding mas rapido
- Mantenimiento simplificado
- Una sola carpeta .build (~1.5GB)
- Cadena de dependencias clara

### Negativas
- Requiere actualizacion de imports en todo el proyecto
- Periodo de adaptacion para el equipo

## Migracion

La migracion se realizo en 6 fases:
1. Preparacion e infraestructura
2. Foundation y Core
3. Infrastructure
4. Domain
5. Presentation
6. Features y finalizacion (actual)

## Fecha
4 de Febrero 2026
