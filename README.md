# Herramientas de Gaming para PikaOS

Este conjunto de herramientas está diseñado para facilitar la instalación y gestión de juegos Windows en PikaOS y otras distribuciones Linux, con una interfaz TUI moderna y un sistema de logs detallado.

## 🎯 Características Principales

- 🖥️ Interfaz TUI moderna con dialog
- 📊 Barras de progreso para todas las operaciones
- 📝 Sistema de logs detallado y centralizado
- 🔄 Soporte multi-distro (PikaOS, Debian, Arch)
- 🛠️ Gestión avanzada de Wine/Proton
- 🎮 Integración con múltiples launchers

## 🚀 Inicio Rápido

Para comenzar, asegúrate de tener los permisos correctos y ejecuta el launcher principal:

```bash
# Dar permisos de ejecución
chmod +x *.sh

# Ejecutar el launcher principal
./pikaos-gaming.sh
```

El sistema detectará automáticamente las dependencias necesarias (`dialog`, `pv`) y las instalará si es necesario. La interfaz TUI te guiará a través de todas las herramientas disponibles con menús interactivos y barras de progreso.

### Orden Recomendado
1. Ejecute la "Configuración Inicial" primero para preparar su sistema
2. Use "Instalar/Configurar Juego" para añadir nuevos juegos
3. Use "Mantenimiento de Wine" cuando necesite optimizar o hacer backups
4. Use "Gestionar Launchers" para actualizaciones y configuraciones específicas

## Gestor de paquetes adaptativo (pkg_manager.sh)

Los scripts de este repositorio ahora usan un wrapper central llamado `pkg_manager.sh` para instalar/actualizar/remover paquetes.
Esto permite que los scripts funcionen correctamente en varias distribuciones y gestores de paquete, preferiendo las herramientas nativas cuando sea posible.

Principales comportamientos:

- Prioridad de gestores:
   - Si está disponible, `pikman` (PikaOS) será preferido. Según la documentación de PikaOS, `pikman` no requiere usar `sudo` porque maneja internamente la elevación cuando es necesario.
   - En distribuciones Debian/Ubuntu se usará `apt`.
   - En Arch y derivadas se intentará `yay`, luego `paru`, y por último `pacman`.
   - Otros gestores soportados de forma básica: `dnf`.

- Mapas y candidatos de nombre de paquete:
   - Para cada "paquete genérico" (por ejemplo `heroic`, `wine-ge`, `steam`) el wrapper mantiene una lista de nombres candidatos comunes (p. ej. `heroic-games-launcher-bin`, `heroic-bin`, `heroic`) y selecciona el primero que esté disponible en el repositorio de la máquina.
   - Esto evita fallos cuando un paquete tiene nombres distintos entre AUR, repositorios oficiales o paquetes personalizados de PikaOS.

- Fallbacks especiales para builds desde releases:
   - Si no existe un paquete empaquetado para `wine-ge` o `proton-ge`, `pkg_manager.sh` intentará ejecutar los helpers del repositorio (`setup_launchers.sh --wine-only` o `--proton-only`) para descargar e instalar la versión desde las releases (descarga y extracción en rutas locales). Esto permite cubrir instalaciones donde Wine-GE o Proton-GE no están empaquetados pero sí disponibles como binarios en GitHub.

- Ejemplos de funciones expuestas por el wrapper:
   - `pkg_install <paquete-genérico>`  — instala el paquete usando el gestor detectado
   - `pkg_remove <paquete-genérico>`   — elimina el paquete
   - `pkg_update`                      — actualiza el sistema
   - `pkg_available <nombre>`          — chequea si un paquete existe en los repositorios

- Forzar/Anular nombres:
   - Si necesitas forzar un nombre concreto (por ejemplo porque PikaOS tiene un paquete con nombre especial), edita `pkg_manager.sh` y añade/ajusta `PKG_CANDIDATES_DEBIAN` o `PKG_CANDIDATES_ARCH` para la entrada correspondiente.

- Mensajes y depuración:
   - `pkg_manager_info` muestra el gestor detectado y el tipo de distro.
   - Antes de ejecutar instalaciones masivas, puedes probar con `map_pkg_name <paquete-genérico>` para ver qué nombre concreto elegiría el wrapper en la máquina actual.

Cómo probar el wrapper (en tu Linux o WSL):

```bash
# cargar el wrapper en la sesión actual
source ./pkg_manager.sh

# ver el gestor detectado
pkg_manager_info

# ver qué nombre usaría para 'heroic' o 'steam'
map_pkg_name heroic
map_pkg_name steam

# intentar instalar (modo real) — en PikaOS pikman gestionará elevación internamente
pkg_install steam

# casos especiales: si no existe 'proton-ge' empaquetado, el wrapper intentará ejecutar
# setup_launchers.sh --proton-only para descargar Proton-GE desde las releases
pkg_install proton-ge
```

Notas importantes:
- En PikaOS no anteponemos `sudo` a `pikman` ya que el propio `pikman` pedirá permisos cuando sea necesario.
- En otros gestores (apt, pacman, yay, paru, dnf) el wrapper sí usa `sudo` donde es apropiado.
- Si el método de fallback (descarga de releases) no es deseado, puedes desactivarlo modificando `pkg_manager.sh`.

Si quieres que incluya un pequeño archivo `PKG_MAP_OVERRIDES.md` o ejemplos concretos para PikaOS, puedo generarlo (por ejemplo, mostrar cómo priorizar `heroic-games-launcher-bin` sobre `heroic`).

## 🎨 Interfaz TUI Moderna

La nueva interfaz TUI proporciona una experiencia de usuario mejorada:

### Características de la TUI
- 🖥️ Menús navegables con teclado y ratón
- 📊 Barras de progreso para todas las operaciones
- 🎨 Soporte para colores y emojis
- 📝 Diálogos informativos y de error
- ✅ Confirmaciones visuales
- 💾 Progreso en tiempo real

### Componentes Interactivos
1. **Menús Principales**
   - Navegación con flechas
   - Atajos numéricos
   - ESC para cancelar/volver
   - Indicadores visuales

2. **Barras de Progreso**
   - Descarga de archivos
   - Instalación de paquetes
   - Extracción de archivos
   - Operaciones largas

3. **Diálogos**
   - Mensajes de información
   - Alertas de error
   - Confirmaciones
   - Selección múltiple

4. **Visualización de Logs**
   - Vista en tiempo real
   - Navegación por categorías
   - Filtrado de contenido
   - Gestión de logs

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

### Sistema de Logs Detallado

El sistema mantiene logs detallados de todas las operaciones en el directorio `logs/`:

#### Estructura de Logs
- `pikaos-gaming.log`: Log general del sistema
- `install_game.log`: Logs específicos de instalación
- `setup_launchers.log`: Logs de configuración
- `wine_maintenance.log`: Logs de mantenimiento

#### Información Registrada
Cada entrada de log incluye:
- ⏰ Timestamp preciso
- 📝 Nivel de log (INFO/WARNING/ERROR)
- 🔍 Script y función que genera el log
- 💻 Información del sistema (Distro, Kernel, Package Manager)
- 🔧 Variables de entorno relevantes (WINEPREFIX, etc.)
- 📚 Stack trace completo para errores

#### Visualización de Logs
Los logs se pueden ver desde la TUI con estas características:
- 📋 Vista de logs individuales o combinados
- 🔍 Navegación fácil entre diferentes logs
- 🗑️ Opción para limpiar logs antiguos
- 📊 Formateo para mejor legibilidad

#### Seguimiento en Tiempo Real
```bash
# Ver log general
tail -f logs/pikaos-gaming.log

# Ver log específico
tail -f logs/install_game.log
```

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