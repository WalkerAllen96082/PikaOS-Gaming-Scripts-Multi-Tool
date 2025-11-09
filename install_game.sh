#!/bin/bash

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Verificar dependencias críticas
if [ ! -f "$SCRIPT_DIR/tui_utils.sh" ]; then
    echo "Error: No se encuentra tui_utils.sh"
    exit 1
fi

# Importar utilidades
source "$SCRIPT_DIR/tui_utils.sh"
source "$SCRIPT_DIR/00_config.sh" || log_message "WARNING" "00_config.sh no encontrado; usando valores por defecto"
source "$SCRIPT_DIR/pkg_manager.sh"

# Inicializar log
GAME_INSTALL_LOG="$LOG_DIR/game_installer.log"
touch "$GAME_INSTALL_LOG"

# Función para volver al menú principal
return_to_main() {
    if confirm "Menú Principal" "¿Deseas volver al menú principal?"; then
        cleanup_tui
        exec "$SCRIPT_DIR/gaming_tools.sh"
    fi
}

# Función para reiniciar el script actual
restart_script() {
    if confirm "Reiniciar" "¿Deseas realizar otra operación en este menú?"; then
        cleanup_tui
        exec "$0"
    fi
}

# Función para manejar el final de una operación
handle_operation_end() {
    local options=(
        "1" "↩️ Instalar otro juego"
        "2" "🏠 Volver al menú principal"
        "3" "❌ Salir"
    )
    
    local choice=$(show_menu "¿Qué deseas hacer?" "Operación completada" "${options[@]}")
    case $choice in
        1)
            cleanup_tui
            exec "$0"
            ;;
        2)
            cleanup_tui
            exec "$SCRIPT_DIR/gaming_tools.sh"
            ;;
        3)
            cleanup_tui
            exit 0
            ;;
        *)
            handle_operation_end
            ;;
    esac
}

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
    
    echo "LAUNCHERS=${launchers[*]}"
    echo "DESCRIPTIONS=${descriptions[*]}"
}

# Función para crear perfil Wine
create_wine_prefix() {
    local prefix_name="$1"
    local prefix_path="$HOME/.local/share/wineprefixes/$prefix_name"
    
    mkdir -p "$prefix_path"
    export WINEPREFIX="$prefix_path"
    
    show_progress "Creando prefijo Wine..." "wineboot -i"
    
    echo "$prefix_path"
}

# Función para añadir juego a Heroic
add_to_heroic() {
    local game_name="$1"
    local exe_path="$2"
    local prefix_path="$3"
    
    local config_dir="$HOME/.config/heroic/games/windows"
    mkdir -p "$config_dir"
    
    show_info "Heroic" "Configurando juego en Heroic..."
    
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

    show_success "Éxito" "Juego añadido a Heroic"
}

# Función para añadir juego a Steam
add_to_steam() {
    local game_name="$1"
    local exe_path="$2"
    local prefix_path="$3"
    
    if [ ! -f "$HOME/.steam/steam/steam.sh" ]; then
        show_error "Error" "Steam no está instalado"
        return 1
    fi
    
    show_info "Steam" "Creando script de lanzamiento..."
    
    local script_path="$HOME/.local/share/steam-shortcuts/${game_name}.sh"
    mkdir -p "$(dirname "$script_path")"
    
    cat > "$script_path" << EOF
#!/bin/bash
export WINEPREFIX="$prefix_path"
export STEAM_COMPAT_DATA_PATH="$prefix_path"
"$HOME/.steam/steam/compatibilitytools.d/proton/proton" run "$exe_path"
EOF
    
    chmod +x "$script_path"
    
    show_info "Steam" "Por favor:\n1. Cierra Steam si está abierto\n2. Abre Steam\n3. Añade un juego no Steam\n4. Selecciona el script: $script_path\n5. Nombra el juego como: $game_name"
    show_progress "Abriendo Steam..." "steam"
}

# Función principal
main() {
    # Inicializar TUI
    init_tui
    
    # Log de inicio
    log_message "INFO" "Iniciando asistente de instalación de juegos..." "$GAME_INSTALL_LOG"
    
    # Seleccionar carpeta del instalador
    while true; do
        local SETUP_DIR=$(user_input "Instalación de Juego" "Ingresa la ruta de la carpeta que contiene setup.exe:")
        
        if [ -z "$SETUP_DIR" ]; then
            show_error "Error" "No se especificó una ruta"
            handle_operation_end
            return
        fi
        
        # Expandir ~ si está presente
        SETUP_DIR="${SETUP_DIR/#\~/$HOME}"
        
        if [ -f "$SETUP_DIR/setup.exe" ]; then
            break
        else
            show_error "Error" "No se encontró setup.exe en el directorio especificado.\n\nPor favor, verifica la ruta."
            sleep 2
        fi
    done
    
    log_message "INFO" "Directorio de instalación: $SETUP_DIR" "$GAME_INSTALL_LOG"
    
    # Verificar y seleccionar launcher
    eval "$(get_available_launchers)"
    
    if [ ${#LAUNCHERS[@]} -eq 0 ]; then
        if confirm "Instalación Requerida" "No se encontraron lanzadores instalados.\n¿Deseas instalar alguno?"; then
            local launcher_options=(
                "1" "🍷 Wine (Recomendado para juegos de Windows)"
                "2" "🚀 Proton-GE (Recomendado para Steam)"
                "3" "🏆 Lutris (Plataforma de gaming)"
                "4" "❌ Cancelar"
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
                    handle_operation_end
                    return
                    ;;
            esac
            
            # Actualizar lista de lanzadores
            eval "$(get_available_launchers)"
        fi
    fi
    
    # Mostrar lanzadores disponibles
    local launcher_options=()
    local i=1
    for launcher in "${LAUNCHERS[@]}"; do
        launcher_options+=("$i" "🎮 ${launcher^} (${DESCRIPTIONS[$((i-1))]})")
        ((i++))
    done
    
    local LAUNCHER_CHOICE=$(show_menu "Selección de Launcher" "Selecciona un launcher:" "${launcher_options[@]}")
    if [ -z "$LAUNCHER_CHOICE" ]; then
        handle_operation_end
        return
    fi
    
    LAUNCHER="${LAUNCHERS[$((LAUNCHER_CHOICE-1))]}"
    
    # Preguntar si desea instalar versiones adicionales
    if confirm "Versiones Adicionales" "¿Deseas instalar versiones adicionales del launcher seleccionado?"; then
        case $LAUNCHER in
            wine)
                local wine_options=(
                    "1" "🍷 Wine-GE"
                    "2" "🍷 Wine-Staging"
                    "3" "❌ Cancelar"
                )
                
                local choice=$(show_menu "Wine" "Selecciona una versión:" "${wine_options[@]}")
                case $choice in
                    1)
                        show_progress "Instalando Wine-GE..." "$SCRIPT_DIR/setup_launchers.sh --wine-ge-only"
                        ;;
                    2)
                        show_progress "Instalando Wine Staging..." "pkg_install wine-staging"
                        ;;
                    3|"")
                        ;;
                esac
                ;;
            proton)
                if confirm "Proton-GE" "¿Deseas instalar Proton-GE?"; then
                    show_progress "Instalando Proton-GE..." "$SCRIPT_DIR/setup_launchers.sh --proton-only"
                fi
                ;;
        esac
    fi
    
    # Configurar prefijo
    local prefix_options=(
        "1" "📂 Usar un prefijo existente"
        "2" "🆕 Crear nuevo prefijo"
        "3" "❌ Cancelar"
    )
    
    local prefix_choice=$(show_menu "Configuración de Prefijo" "Selecciona una opción:" "${prefix_options[@]}")
    local WINE_PREFIX
    
    case $prefix_choice in
        1)
            WINE_PREFIX=$(user_input "Selección de Prefijo" "Ingresa la ruta al prefijo existente:")
            if [ ! -d "$WINE_PREFIX" ]; then
                show_error "Error" "El directorio del prefijo no existe"
                handle_operation_end
                return
            fi
            ;;
        2)
            local PREFIX_NAME=$(user_input "Nuevo Prefijo" "Ingresa un nombre para el nuevo prefijo:")
            if [ -n "$PREFIX_NAME" ]; then
                WINE_PREFIX=$(create_wine_prefix "$PREFIX_NAME")
                show_success "Éxito" "Prefijo creado en:\n$WINE_PREFIX"
            else
                handle_operation_end
                return
            fi
            ;;
        3|"")
            handle_operation_end
            return
            ;;
    esac
    
    # Ejecutar instalador
    log_message "INFO" "Ejecutando instalador..." "$GAME_INSTALL_LOG"
    
    show_info "Instalación" "Se iniciará el instalador del juego.\nPor favor, sigue las instrucciones en pantalla."
    
    case "$LAUNCHER" in
        wine)
            show_progress "Ejecutando instalador con Wine..." "WINEPREFIX=\"$WINE_PREFIX\" wine \"$SETUP_DIR/setup.exe\""
            ;;
        proton)
            show_progress "Ejecutando instalador con Proton..." "STEAM_COMPAT_DATA_PATH=\"$WINE_PREFIX\" \"$HOME/.steam/steam/compatibilitytools.d/proton/proton\" run \"$SETUP_DIR/setup.exe\""
            ;;
        lutris)
            show_progress "Ejecutando instalador con Lutris..." "lutris --install-wine-prefix=\"$WINE_PREFIX\" \"$SETUP_DIR/setup.exe\""
            ;;
    esac
    
    # Configurar ejecutable y nombre
    local GAME_EXE=$(user_input "Configuración del Juego" "Ingresa la ruta completa al ejecutable del juego (dentro del prefijo):")
    if [ -z "$GAME_EXE" ]; then
        show_error "Error" "No se especificó el ejecutable del juego"
        handle_operation_end
        return
    fi
    
    local GAME_NAME=$(user_input "Nombre del Juego" "Ingresa el nombre del juego:")
    if [ -z "$GAME_NAME" ]; then
        show_error "Error" "No se especificó el nombre del juego"
        handle_operation_end
        return
    fi
    
    # Seleccionar plataforma
    local platform_options=(
        "1" "🎮 Heroic (Launcher alternativo)"
        "2" "🚀 Steam (Plataforma principal)"
        "3" "🎯 Ambos launchers"
        "4" "❌ Cancelar"
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
            handle_operation_end
            return
            ;;
    esac
    
    log_message "SUCCESS" "Instalación completada" "$GAME_INSTALL_LOG"
    show_success "¡Instalación Completada!" "El juego ha sido configurado y está listo para jugar.\n\nPuedes encontrarlo en el launcher seleccionado."
    
    handle_operation_end
}

# Punto de entrada principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi