#!/bin/bash
source "$(dirname "$0")/../00_config.sh"
# Cargar wrapper de gestor de paquetes
source "$(dirname "$0")/pkg_manager.sh"

GAME_INSTALL_LOG="$LOG_DIR/game_installer.log"
touch "$GAME_INSTALL_LOG"

log_message "INFO" "Iniciando asistente de instalación de juegos..." "$GAME_INSTALL_LOG"

# Función para obtener lanzadores disponibles
get_available_launchers() {
    local launchers=()
    local descriptions=()
    
    # Verificar Wine
    if command -v wine &> /dev/null; then
        local wine_version=$(wine --version)
        launchers+=("wine")
        descriptions+=("$wine_version")
    fi
    
    # Verificar Steam (y Proton)
    if [ -d "$HOME/.steam" ]; then
        # Buscar versiones de Proton instaladas
        local proton_versions=()
        if [ -d "$HOME/.steam/root/compatibilitytools.d" ]; then
            for proton in "$HOME/.steam/root/compatibilitytools.d"/*/; do
                if [ -d "$proton" ]; then
                    proton_versions+=($(basename "$proton"))
                fi
            done
        fi
        launchers+=("proton")
        if [ ${#proton_versions[@]} -eq 0 ]; then
            descriptions+=("Steam Proton (versión por defecto)")
        else
            descriptions+=("Proton disponible: ${proton_versions[*]}")
        fi
    fi
    
    # Verificar Lutris
    if command -v lutris &> /dev/null; then
        local lutris_version=$(lutris --version 2>/dev/null || echo "versión desconocida")
        launchers+=("lutris")
        descriptions+=("$lutris_version")
    fi
    
    # Devolver ambos arrays
    echo "LAUNCHERS=${launchers[*]}"
    echo "DESCRIPTIONS=${descriptions[*]}"
}

# Función para seleccionar un directorio
select_directory() {
    local prompt=$1
    local path
    
    while true; do
        read -p "$prompt: " path
        
        # Expandir ~ si está presente
        path="${path/#\~/$HOME}"
        
        if [ -d "$path" ]; then
            echo "$path"
            break
        else
            echo "Directorio no válido. Inténtalo de nuevo."
        fi
    done
}

# Función para crear perfil Wine
create_wine_prefix() {
    local prefix_name=$1
    local prefix_path="$HOME/.local/share/wineprefixes/$prefix_name"
    
    mkdir -p "$prefix_path"
    export WINEPREFIX="$prefix_path"
    wineboot -i
    
    echo "$prefix_path"
}

# Función para añadir juego a Heroic
add_to_heroic() {
    local game_name=$1
    local exe_path=$2
    local prefix_path=$3
    
    local config_dir="$HOME/.config/heroic/games/windows"
    mkdir -p "$config_dir"
    
    # Crear configuración del juego
    cat > "$config_dir/${game_name}.json" << EOF
{
    "name": "$game_name",
    "executable": "$exe_path",
    "winePrefix": "$prefix_path",
    "wineVersion": {
        "type": "wine",
        "version": "default"
    },
    "platform": "windows"
}
EOF
}

# Función para añadir juego a Steam
add_to_steam() {
    local game_name=$1
    local exe_path=$2
    local prefix_path=$3
    
    # Verificar que Steam está instalado
    if [ ! -f "$HOME/.steam/steam/steam.sh" ]; then
        return 1
    fi
    
    # Crear script de lanzamiento
    local script_path="$HOME/.local/share/steam-shortcuts/${game_name}.sh"
    mkdir -p "$(dirname "$script_path")"
    
    cat > "$script_path" << EOF
#!/bin/bash
export WINEPREFIX="$prefix_path"
export STEAM_COMPAT_DATA_PATH="$prefix_path"
"$HOME/.steam/steam/compatibilitytools.d/proton/proton" run "$exe_path"
EOF
    
    chmod +x "$script_path"
    
    # Añadir a Steam (requiere Steam cerrado)
    echo "Por favor:"
    echo "1. Cierra Steam si está abierto"
    echo "2. Abre Steam"
    echo "3. Añade un juego no Steam"
    echo "4. Selecciona el script: $script_path"
    echo "5. Nombra el juego como: $game_name"
    read -p "Presiona Enter cuando hayas completado estos pasos..."
}

# Principal
echo "=== Asistente de Instalación de Juegos ==="

# 1. Seleccionar carpeta del instalador
SETUP_DIR=$(select_directory "Ingresa la ruta de la carpeta que contiene setup.exe")
if [ ! -f "$SETUP_DIR/setup.exe" ]; then
    log_message "ERROR" "No se encontró setup.exe en el directorio especificado" "$GAME_INSTALL_LOG"
    exit 1
fi

# 2. Mostrar lanzadores disponibles
eval "$(get_available_launchers)"
IFS=' ' read -ra LAUNCHER_ARRAY <<< "$LAUNCHERS"
IFS=' ' read -ra DESCRIPTION_ARRAY <<< "$DESCRIPTIONS"

if [ ${#LAUNCHER_ARRAY[@]} -eq 0 ]; then
    echo "No se encontraron lanzadores instalados."
    echo "¿Deseas instalar alguno?"
    select OPTION in "Wine" "Proton-GE" "Lutris" "Cancelar"; do
                case $OPTION in
            "Wine")
                pkg_install wine
                break
                ;;
            "Proton-GE")
                read -p "¿Deseas instalar Steam y Proton-GE? [s/N] " response
                if [[ $response =~ ^[Ss]$ ]]; then
                    pkg_install steam
                    # Llamar al script de setup_launchers para instalar Proton-GE
                    "$(dirname "$0")/setup_launchers.sh" --proton-only
                fi
                break
                ;;
            "Lutris")
                pkg_install lutris
                break
                ;;
            "Cancelar")
                exit 0
                ;;
        esac
    done
    # Actualizar lista de lanzadores después de la instalación
    eval "$(get_available_launchers)"
    IFS=' ' read -ra LAUNCHER_ARRAY <<< "$LAUNCHERS"
    IFS=' ' read -ra DESCRIPTION_ARRAY <<< "$DESCRIPTIONS"
fi

echo "Lanzadores disponibles:"
for i in "${!LAUNCHER_ARRAY[@]}"; do
    echo "$((i+1))) ${LAUNCHER_ARRAY[i]} (${DESCRIPTION_ARRAY[i]})"
done

while true; do
    read -p "Selecciona un lanzador (1-${#LAUNCHER_ARRAY[@]}): " selection
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#LAUNCHER_ARRAY[@]}" ]; then
        LAUNCHER="${LAUNCHER_ARRAY[$((selection-1))]}"
        break
    else
        echo "Selección inválida"
    fi
done

# Preguntar si desea instalar versiones adicionales
read -p "¿Deseas instalar versiones adicionales del lanzador seleccionado? [s/N] " install_more
if [[ $install_more =~ ^[Ss]$ ]]; then
    case $LAUNCHER in
        "wine")
            echo "Opciones disponibles para Wine:"
            select WINE_OPTION in "Wine-GE" "Wine-Staging" "Cancelar"; do
                case $WINE_OPTION in
                    "Wine-GE")
                        "$(dirname "$0")/setup_launchers.sh" --wine-ge-only
                        break
                        ;;
                    "Wine-Staging")
                        pkg_install "wine-staging"
                        break
                        ;;
                    "Cancelar")
                        break
                        ;;
                esac
            done
            ;;
        "proton")
            echo "Opciones disponibles para Proton:"
            select PROTON_OPTION in "Proton-GE" "Cancelar"; do
                case $PROTON_OPTION in
                    "Proton-GE")
                        "$(dirname "$0")/setup_launchers.sh" --proton-only
                        break
                        ;;
                    "Cancelar")
                        break
                        ;;
                esac
            done
            ;;
    esac
fi

# 3. Configurar perfil Wine/Proton
echo "Configuración del prefijo Wine/Proton:"
echo "1) Usar un prefijo existente"
echo "2) Crear nuevo prefijo"
read -p "Selecciona una opción (1/2): " PREFIX_OPTION

if [ "$PREFIX_OPTION" = "1" ]; then
    WINE_PREFIX=$(select_directory "Selecciona el prefijo existente")
else
    read -p "Nombre para el nuevo prefijo: " PREFIX_NAME
    WINE_PREFIX=$(create_wine_prefix "$PREFIX_NAME")
fi

# 4. Ejecutar instalador
log_message "INFO" "Ejecutando instalador..." "$GAME_INSTALL_LOG"
case "$LAUNCHER" in
    "wine")
        WINEPREFIX="$WINE_PREFIX" wine "$SETUP_DIR/setup.exe"
        ;;
    "proton")
        STEAM_COMPAT_DATA_PATH="$WINE_PREFIX" "$HOME/.steam/steam/compatibilitytools.d/proton/proton" run "$SETUP_DIR/setup.exe"
        ;;
    "lutris")
        lutris --install-wine-prefix="$WINE_PREFIX" "$SETUP_DIR/setup.exe"
        ;;
esac

# 5. Obtener ruta del ejecutable
read -p "Ingresa la ruta completa al ejecutable del juego (dentro del prefijo): " GAME_EXE
read -p "Ingresa el nombre del juego: " GAME_NAME

# 6. Añadir a launcher
echo "¿Dónde quieres añadir el juego?"
select PLATFORM in "Heroic" "Steam" "Ambos"; do
    case $PLATFORM in
        "Heroic")
            add_to_heroic "$GAME_NAME" "$GAME_EXE" "$WINE_PREFIX"
            break
            ;;
        "Steam")
            add_to_steam "$GAME_NAME" "$GAME_EXE" "$WINE_PREFIX"
            break
            ;;
        "Ambos")
            add_to_heroic "$GAME_NAME" "$GAME_EXE" "$WINE_PREFIX"
            add_to_steam "$GAME_NAME" "$GAME_EXE" "$WINE_PREFIX"
            break
            ;;
    esac
done

log_message "SUCCESS" "Instalación completada. El juego ha sido configurado en el launcher seleccionado" "$GAME_INSTALL_LOG"
echo "¡Instalación completada! Puedes encontrar el juego en el launcher seleccionado."
exit 0