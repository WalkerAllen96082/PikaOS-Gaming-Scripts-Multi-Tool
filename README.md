# Herramientas de Gaming para PikaOS

Este conjunto de herramientas está diseñado para facilitar la instalación y gestión de juegos Windows en PikaOS.

## 🚀 Inicio Rápido

Para comenzar, simplemente ejecute:
```bash
./gaming_tools.sh
```

Este es el script principal que le guiará a través de todas las herramientas disponibles en un menú interactivo y fácil de usar.

### Orden Recomendado
1. Ejecute la "Configuración Inicial" primero para preparar su sistema
2. Use "Instalar/Configurar Juego" para añadir nuevos juegos
3. Use "Mantenimiento de Wine" cuando necesite optimizar o hacer backups
4. Use "Gestionar Launchers" para actualizaciones y configuraciones específicas

## Índice
1. [Instalación de Juegos](#instalación-de-juegos)
2. [Configuración de Launchers](#configuración-de-launchers)
3. [Mantenimiento de Wine](#mantenimiento-de-wine)
4. [Utilidades Adicionales](#utilidades-adicionales)
5. [Tutoriales](#tutoriales)
6. [Solución de Problemas](#solución-de-problemas)

## Instalación de Juegos

### Uso Básico
```bash
cd game_tools
./install_game.sh
```

El script te guiará a través del proceso de:
1. Selección de la carpeta del instalador
2. Elección del launcher (Wine/Proton/Lutris)
3. Configuración del prefijo Wine
4. Instalación del juego
5. Integración con launchers

### Opciones Disponibles
- Instalación en prefijo existente o nuevo
- Integración con Steam o Heroic Games Launcher
- Soporte para Wine, Proton y Lutris
- Logging detallado de la instalación

## Configuración de Launchers

### Uso del Setup de Launchers
```bash
# Uso interactivo
./setup_launchers.sh

# Instalación individual de componentes
./setup_launchers.sh --proton-only    # Instalar solo Proton-GE
./setup_launchers.sh --wine-only      # Instalar solo Wine-GE
./setup_launchers.sh --heroic-only    # Configurar solo Heroic
./setup_launchers.sh --help           # Mostrar ayuda
```

### Características
- Instalación automática de Proton-GE y Wine-GE
- Detección y gestión de launchers instalados
- Configuración optimizada de Heroic con soporte dual Wine-GE/Proton-GE
- Configuración de Lutris
- Gestión de versiones de compatibilidad
- Instalación bajo demanda de launchers

### Configuraciones Disponibles
1. **Proton-GE**
   - Instalación y actualización automática
   - Listado y selección de versiones instaladas
   - Integración automática con Steam
   - Soporte para Heroic Games Launcher
   - Optimizaciones para gaming

2. **Wine-GE**
   - Instalación y actualización bajo demanda
   - Gestión de múltiples versiones
   - Parches de rendimiento
   - Compatibilidad mejorada
   - Integración con Heroic y Lutris

3. **Heroic Games Launcher**
   - Soporte dual Wine-GE/Proton-GE
   - Selección flexible del motor de compatibilidad
   - Gestión de versiones de compatibilidad
   - Configuración predeterminada optimizada
   - Sincronización automática

4. **Lutris**
   - Configuración guiada
   - Optimizaciones de rendimiento
   - Integración con Wine

## Mantenimiento de Wine

### Uso del Mantenimiento
```bash
./wine_maintenance.sh
```

### Funciones Disponibles
1. **Listado de Prefijos**
   - Busca en todas las ubicaciones comunes
   - Muestra detalles de cada prefijo
   - Identifica prefijos huérfanos

2. **Limpieza de Prefijos**
   - Elimina archivos temporales
   - Desfragmenta el registro
   - Optimiza el rendimiento

3. **Backup de Prefijos**
   - Backup completo del prefijo
   - Compresión automática
   - Nombrado por fecha/hora

4. **Instalación de Componentes**
   - DirectX
   - Visual C++ Runtime
   - DXVK
   - XAudio

## Utilidades Adicionales

### Uso de Game Utils
```bash
./game_utils.sh
```

### Características
1. **Gestión de Accesos Directos**
   - Creación individual
   - Creación en lote
   - Personalización de iconos

2. **Búsqueda de Ejecutables**
   - Escaneo de prefijos
   - Identificación automática
   - Filtrado por tipo

## Tutoriales

### Instalar un Juego Nuevo

1. **Preparación**
   ```bash
   # Primero, configura los launchers
   ./setup_launchers.sh
   # Selecciona instalar Proton-GE y Wine-GE
   ```

2. **Instalación**
   ```bash
   ./install_game.sh
   # Sigue las instrucciones en pantalla
   ```

3. **Post-Instalación**
   ```bash
   # Opcional: Crear accesos directos adicionales
   ./game_utils.sh
   # Selecciona la opción 1
   ```

### Mantener Prefijos Wine

1. **Limpieza Regular**
   ```bash
   ./wine_maintenance.sh
   # Selecciona opción 2 para limpiar
   ```

2. **Backup Antes de Cambios**
   ```bash
   ./wine_maintenance.sh
   # Selecciona opción 3 para backup
   ```

### Optimizar Rendimiento

1. **Instalar Componentes**
   ```bash
   ./wine_maintenance.sh
   # Selecciona opción 4
   # Instala DXVK y otros componentes
   ```

2. **Configurar Launcher**
   ```bash
   ./setup_launchers.sh
   # Configura Proton-GE para mejor rendimiento
   ```

## Solución de Problemas

### Problemas Comunes

1. **El juego no inicia**
   - Verificar componentes de Wine instalados
   - Comprobar versión de Proton-GE
   - Revisar logs en ~/.wine/logs

2. **Bajo rendimiento**
   - Activar DXVK
   - Usar última versión de Proton-GE
   - Verificar configuración de Heroic/Steam

3. **Errores de instalación**
   - Limpiar prefijo Wine
   - Reinstalar componentes básicos
   - Verificar permisos de archivos

### Logs y Diagnóstico
- Todos los logs se guardan en `logs/`
- Cada herramienta tiene su propio archivo de log
- Use `tail -f` para seguimiento en tiempo real

## Consejos y Trucos

1. **Prefijos Wine**
   - Usar prefijos separados por juego
   - Hacer backup antes de cambios importantes
   - Mantener registro de configuraciones exitosas

2. **Launchers**
   - Proton-GE para juegos Steam
   - Wine-GE para otros juegos
   - Heroic para gestión simplificada

3. **Rendimiento**
   - Usar DXVK cuando sea posible
   - Mantener drivers actualizados
   - Limpiar prefijos regularmente

## Referencias

- [Wiki de PikaOS](https://wiki.pika-os.com)
- [Proton-GE](https://github.com/GloriousEggroll/proton-ge-custom)
- [Wine-GE](https://github.com/GloriousEggroll/wine-ge-custom)
- [Documentación de Wine](https://wiki.winehq.org)
- [Heroic Games Launcher](https://heroicgameslauncher.com/)