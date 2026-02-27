# ``Logger``

Sistema de logging centralizado para EduGo basado en os.Logger de Apple.

## Overview

El modulo Logger proporciona un sistema de logging unificado con integracion nativa con Unified Logging System de Apple. Soporta categorias por modulo, niveles configurables, y configuracion dinamica via variables de entorno.

### Caracteristicas Principales

- Integracion con `os.Logger` de Apple
- Categorias por modulo para filtrado granular
- Niveles: debug, info, warning, error
- Configuracion via variables de entorno
- Thread-safety con Swift Concurrency (actors)
- Cumplimiento de Swift 6.2 Strict Concurrency

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Integration>

### Logging

- ``LoggerProtocol``
- ``OSLoggerAdapter``
- ``OSLoggerFactory``
- ``LoggerRegistry``

### Configuration

- ``LogConfiguration``
- ``LoggerConfigurator``
- ``EnvironmentConfiguration``
- ``LogConfigurationPreset``

### Levels and Categories

- ``LogLevel``
- ``LogCategory``
- ``SystemLogCategory``
- ``StandardLogCategory``
- ``DynamicLogCategory``

### Advanced

- <doc:BestPractices>
- <doc:Troubleshooting>
- <doc:CategoryGuide>
