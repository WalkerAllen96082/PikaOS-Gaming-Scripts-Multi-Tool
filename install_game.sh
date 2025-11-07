#!/bin/bash

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Importar utilidades
source "$SCRIPT_DIR/tui_utils.sh"
source "$SCRIPT_DIR/00_config.sh" || log_message "WARNING" "00_config.sh no encontrado; usando valores por defecto"
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

# Función principal
main() {
    # Inicializar TUI
    init_tui
    
    # Log de inicio
    log_message "INFO" "Iniciando asistente de instalación de juegos..."
    
    # Seleccionar carpeta del instalador
    local SETUP_DIR
    while true; do
        SETUP_DIR=$(user_input "Instalación de Juego" "Ingresa la ruta de la carpeta que contiene setup.exe:")
        
        if [ -z "$SETUP_DIR" ]; then
            cleanup_tui
            exit 0
        fi
        
        # Expandir ~ si está presente
        SETUP_DIR="${SETUP_DIR/#\~/$HOME}"
        
        if [ -f "$SETUP_DIR/setup.exe" ]; then
            break
        else
            show_error "Error" "No se encontró setup.exe en el directorio especificado.\n\nPor favor, verifica la ruta."
        fi
    done
    
    log_message "INFO" "Directorio de instalación seleccionado: $SETUP_DIR"

# Verificar y seleccionar launcher
    eval "$(get_available_launchers)"
    IFS=' ' read -ra LAUNCHER_ARRAY <<< "$LAUNCHERS"
    IFS=' ' read -ra DESCRIPTION_ARRAY <<< "$DESCRIPTIONS"

    if [ ${#LAUNCHER_ARRAY[@]} -eq 0 ]; then
        if confirm "Instalación Requerida" "No se encontraron lanzadores instalados.\n¿Deseas instalar alguno?"; then
            local launcher_options=(
                "1" "Wine (Recomendado para juegos de Windows)"
                "2" "Proton-GE (Recomendado para Steam)"
                "3" "Lutris (Plataforma de gaming)"
                "4" "Cancelar"
            )
            
            local choice=$(show_menu "Instalación de Launcher" "Selecciona el launcher a instalar:" "${launcher_options[@]}")
            
            case $choice in
                1)
                    show_progress "Instalando Wine..." "pkg_install wine"
                    show_success "Éxito" "Wine instalado correctamente"
                    ;;
                2)
                    if confirm "Steam" "¿Deseas instalar Steam y Proton-GE?"; then
                        show_progress "Instalando Steam..." "pkg_install steam"
                        show_progress "Instalando Proton-GE..." "$SCRIPT_DIR/setup_launchers.sh --proton-only"
                        show_success "Éxito" "Steam y Proton-GE instalados correctamente"
                    fi
                    ;;
                3)
                    show_progress "Instalando Lutris..." "pkg_install lutris"
                    show_success "Éxito" "Lutris instalado correctamente"
                    ;;
                4|"")
                    cleanup_tui
                    exit 0
                    ;;
            esac
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

# Configurar prefijo
    local prefix_options=(
        "1" "Usar un prefijo existente"
        "2" "Crear nuevo prefijo"
    )
    
    local prefix_choice=$(show_menu "Configuración de Prefijo" "Selecciona una opción:" "${prefix_options[@]}")
    local WINE_PREFIX
    
    case $prefix_choice in
        1)
            WINE_PREFIX=$(user_input "Selección de Prefijo" "Ingresa la ruta al prefijo existente:")
            if [ ! -d "$WINE_PREFIX" ]; then
                show_error "Error" "El directorio del prefijo no existe"
                cleanup_tui
                exit 1
            fi
            ;;
        2)
            local PREFIX_NAME=$(user_input "Nuevo Prefijo" "Ingresa un nombre para el nuevo prefijo:")
            if [ -n "$PREFIX_NAME" ]; then
                show_progress "Creando prefijo..." "create_wine_prefix \"$PREFIX_NAME\""
                WINE_PREFIX=$(create_wine_prefix "$PREFIX_NAME")
                show_success "Éxito" "Prefijo creado en:\n$WINE_PREFIX"
            else
                cleanup_tui
                exit 0
            fi
            ;;
        *)
            cleanup_tui
            exit 0
            ;;
    esac

    # Ejecutar instalador con barra de progreso
    log_message "INFO" "Ejecutando instalador..." "$GAME_INSTALL_LOG"
    
    show_info "Instalación" "Se iniciará el instalador del juego.\nPor favor, sigue las instrucciones en pantalla."
    
    case "$LAUNCHER" in
        "wine")
            show_progress "Ejecutando instalador con Wine..." "WINEPREFIX=\"$WINE_PREFIX\" wine \"$SETUP_DIR/setup.exe\""
            ;;
        "proton")
            show_progress "Ejecutando instalador con Proton..." "STEAM_COMPAT_DATA_PATH=\"$WINE_PREFIX\" \"$HOME/.steam/steam/compatibilitytools.d/proton/proton\" run \"$SETUP_DIR/setup.exe\""
            ;;
        "lutris")
            show_progress "Ejecutando instalador con Lutris..." "lutris --install-wine-prefix=\"$WINE_PREFIX\" \"$SETUP_DIR/setup.exe\""
            ;;
    esac

# Configurar ejecutable y nombre
    local GAME_EXE=$(user_input "Configuración del Juego" "Ingresa la ruta completa al ejecutable del juego (dentro del prefijo):")
    if [ -z "$GAME_EXE" ]; then
        show_error "Error" "No se especificó el ejecutable del juego"
        cleanup_tui
        exit 1
    fi
    
    local GAME_NAME=$(user_input "Nombre del Juego" "Ingresa el nombre del juego:")
    if [ -z "$GAME_NAME" ]; then
        show_error "Error" "No se especificó el nombre del juego"
        cleanup_tui
        exit 1
    fi

    # Seleccionar plataforma
    local platform_options=(
        "1" "Heroic (Launcher alternativo)"
        "2" "Steam (Plataforma principal)"
        "3" "Ambos launchers"
        "4" "Cancelar"
    )
    
    local platform_choice=$(show_menu "Selección de Launcher" "¿Dónde quieres añadir el juego?" "${platform_options[@]}")
    
    case $platform_choice in
        1)
            show_progress "Añadiendo a Heroic..." "add_to_heroic \"$GAME_NAME\" \"$GAME_EXE\" \"$WINE_PREFIX\""
            show_success "Éxito" "Juego añadido a Heroic"
            ;;
        2)
            show_progress "Añadiendo a Steam..." "add_to_steam \"$GAME_NAME\" \"$GAME_EXE\" \"$WINE_PREFIX\""
            show_success "Éxito" "Juego añadido a Steam"
            ;;
        3)
            show_progress "Añadiendo a Heroic..." "add_to_heroic \"$GAME_NAME\" \"$GAME_EXE\" \"$WINE_PREFIX\""
            show_progress "Añadiendo a Steam..." "add_to_steam \"$GAME_NAME\" \"$GAME_EXE\" \"$WINE_PREFIX\""
            show_success "Éxito" "Juego añadido a ambos launchers"
            ;;
        4|"")
            cleanup_tui
            exit 0
            ;;
    esac

    log_message "SUCCESS" "Instalación completada. El juego ha sido configurado en el launcher seleccionado" "$GAME_INSTALL_LOG"
    show_success "¡Instalación Completada!" "El juego ha sido configurado y está listo para jugar.\n\nPuedes encontrarlo en el launcher seleccionado."
    
    cleanup_tui
    exit 0
}

# Ejecutar el programa
main