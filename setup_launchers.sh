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
LAUNCHER_CONFIG_LOG="$LOG_DIR/launcher_config.log"
touch "$LAUNCHER_CONFIG_LOG"

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
        "1" "↩️ Realizar otra operación en este menú"
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

# Función para configurar Proton-GE
setup_proton_ge() {
    local proton_dir="$HOME/.steam/root/compatibilitytools.d"
    mkdir -p "$proton_dir"
    
    show_info "Proton-GE" "Obteniendo información de la última versión..."
    local download_url=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep "browser_download_url.*tar.gz" | cut -d '"' -f 4)
    
    if [ -n "$download_url" ]; then
        log_message "INFO" "Descargando Proton-GE..." "$LAUNCHER_CONFIG_LOG"
        local temp_file="/tmp/proton-ge.tar.gz"
        download_with_progress "$download_url" "$temp_file"
        
        show_progress "Extrayendo Proton-GE..." "tar xf \"$temp_file\" -C \"$proton_dir\""
        rm -f "$temp_file"
        
        show_success "Éxito" "Proton-GE instalado en:\n$proton_dir"
        handle_operation_end
    else
        show_error "Error" "No se pudo obtener la última versión"
        handle_operation_end
    fi
}

# Función para configurar Wine-GE
setup_wine_ge() {
    local wine_dir="$HOME/.local/share/wine-ge-custom"
    mkdir -p "$wine_dir"
    
    show_info "Wine-GE" "Obteniendo información de la última versión..."
    local download_url=$(curl -s https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases/latest | grep "browser_download_url.*tar.xz" | cut -d '"' -f 4)
    
    if [ -n "$download_url" ]; then
        log_message "INFO" "Descargando Wine-GE..." "$LAUNCHER_CONFIG_LOG"
        local temp_file="/tmp/wine-ge.tar.xz"
        download_with_progress "$download_url" "$temp_file"
        
        show_progress "Extrayendo Wine-GE..." "tar xf \"$temp_file\" -C \"$wine_dir\""
        rm -f "$temp_file"
        
        show_success "Éxito" "Wine-GE instalado en:\n$wine_dir"
        handle_operation_end
    else
        show_error "Error" "No se pudo obtener la última versión"
        handle_operation_end
    fi
}

# Función para configurar Heroic
setup_heroic() {
    local heroic_config="$HOME/.config/heroic/config.json"
    mkdir -p "$(dirname "$heroic_config")"
    
    show_info "Heroic" "Configurando launcher..."
    
    # Configuración básica
    cat > "$heroic_config" << EOF
{
    "defaultSettings": {
        "wineVersion": "Wine-GE",
        "winePrefix": "$HOME/.local/share/heroic/prefixes/default",
        "autoSync": true,
        "targetFps": 0,
        "useGameMode": true,
        "language": "es",
        "maxWorkers": 0,
        "preventSleep": true
    }
}
EOF
    
    show_success "Éxito" "Heroic configurado correctamente"
    handle_operation_end
}

# Función para detectar launchers instalados
detect_launchers() {
    local launchers=()
    local descriptions=()
    local i=1
    
    # Detectar Steam
    if command -v steam &> /dev/null; then
        launchers+=("steam")
        descriptions+=("Steam (instalado)")
        ((i++))
    fi
    
    # Detectar Heroic
    if command -v heroic &> /dev/null; then
        launchers+=("heroic")
        descriptions+=("Heroic Games Launcher (instalado)")
        ((i++))
    fi
    
    # Detectar Lutris
    if command -v lutris &> /dev/null; then
        launchers+=("lutris")
        descriptions+=("Lutris (instalado)")
        ((i++))
    fi
    
    echo "LAUNCHERS=${launchers[*]}"
    echo "DESCRIPTIONS=${descriptions[*]}"
}

# Función principal del menú
main_menu() {
    while true; do
        local options=(
            "1" "🚀 Instalar/Configurar componentes"
            "2" "🎮 Configurar launchers existentes"
            "3" "📋 Ver logs"
            "4" "🏠 Volver al menú principal"
            "5" "❌ Salir"
        )
        
        local choice=$(show_menu "Configuración de Launchers" "Selecciona una opción:" "${options[@]}")
        
        case $choice in
            1)
                components_menu
                ;;
            2)
                launchers_menu
                ;;
            3)
                view_logs
                ;;
            4)
                cleanup_tui
                exec "$SCRIPT_DIR/gaming_tools.sh"
                ;;
            5|"")
                cleanup_tui
                exit 0
                ;;
        esac
    done
}

# Menú de componentes
components_menu() {
    local options=(
        "1" "🚀 Proton-GE (Recomendado para Steam)"
        "2" "🍷 Wine-GE (Recomendado para Heroic/Lutris)"
        "3" "🎮 Heroic Games Launcher"
        "4" "⬅️ Volver"
    )
    
    local choice=$(show_menu "Componentes" "Selecciona un componente a instalar:" "${options[@]}")
    
    case $choice in
        1)
            setup_proton_ge
            ;;
        2)
            setup_wine_ge
            ;;
        3)
            if ! command -v heroic &> /dev/null; then
                if confirm "Instalación" "Heroic no está instalado. ¿Deseas instalarlo?"; then
                    show_progress "Instalando Heroic..." "pkg_install heroic"
                    show_success "Éxito" "Heroic instalado correctamente"
                fi
            fi
            setup_heroic
            ;;
        4|"")
            return
            ;;
    esac
}

# Menú de launchers
launchers_menu() {
    # Detectar launchers instalados
    eval "$(detect_launchers)"
    
    if [ ${#LAUNCHERS[@]} -eq 0 ]; then
        show_error "Error" "No hay launchers instalados"
        if confirm "Instalación" "¿Deseas instalar un launcher ahora?"; then
            local install_options=(
                "1" "🎮 Steam (Recomendado)"
                "2" "🏹 Heroic Games Launcher"
                "3" "🏆 Lutris"
                "4" "❌ Cancelar"
            )
            
            local choice=$(show_menu "Instalación de Launcher" "Selecciona un launcher:" "${install_options[@]}")
            case $choice in
                1)
                    show_progress "Instalando Steam..." "pkg_install steam"
                    show_success "Éxito" "Steam instalado correctamente"
                    ;;
                2)
                    show_progress "Instalando Heroic..." "pkg_install heroic"
                    show_success "Éxito" "Heroic instalado correctamente"
                    ;;
                3)
                    show_progress "Instalando Lutris..." "pkg_install lutris"
                    show_success "Éxito" "Lutris instalado correctamente"
                    ;;
                4|"")
                    return
                    ;;
            esac
        fi
        return
    fi
    
    # Crear menú dinámico con los launchers instalados
    local options=()
    local i=1
    for launcher in "${LAUNCHERS[@]}"; do
        options+=("$i" "🎮 ${launcher^}")
        ((i++))
    done
    options+=("$i" "⬅️ Volver")
    
    local choice=$(show_menu "Launchers Instalados" "Selecciona un launcher:" "${options[@]}")
    
    if [ "$choice" -lt "$i" ]; then
        local selected="${LAUNCHERS[$((choice-1))]}"
        configure_launcher "$selected"
    fi
}

# Función para configurar un launcher específico
configure_launcher() {
    local launcher="$1"
    case "$launcher" in
        steam)
            local options=(
                "1" "🎮 Agregar juego no Steam"
                "2" "🚀 Actualizar Proton-GE"
                "3" "⚙️ Configurar Steam"
                "4" "⬅️ Volver"
            )
            
            local choice=$(show_menu "Steam" "Configuración:" "${options[@]}")
            case $choice in
                1)
                    show_info "Steam" "Selecciona el ejecutable del juego..."
                    ;;
                2)
                    setup_proton_ge
                    ;;
                3)
                    show_progress "Abriendo Steam..." "steam"
                    ;;
                4|"")
                    return
                    ;;
            esac
            ;;
        
        heroic)
            local options=(
                "1" "🎮 Agregar juego"
                "2" "🚀 Actualizar Wine-GE"
                "3" "⚙️ Configurar Heroic"
                "4" "⬅️ Volver"
            )
            
            local choice=$(show_menu "Heroic" "Configuración:" "${options[@]}")
            case $choice in
                1)
                    show_info "Heroic" "Selecciona el ejecutable del juego..."
                    ;;
                2)
                    setup_wine_ge
                    ;;
                3)
                    setup_heroic
                    ;;
                4|"")
                    return
                    ;;
            esac
            ;;
        
        lutris)
            local options=(
                "1" "🎮 Agregar juego"
                "2" "🚀 Actualizar Wine-GE"
                "3" "⚙️ Configurar Lutris"
                "4" "⬅️ Volver"
            )
            
            local choice=$(show_menu "Lutris" "Configuración:" "${options[@]}")
            case $choice in
                1)
                    show_info "Lutris" "Selecciona el ejecutable del juego..."
                    ;;
                2)
                    setup_wine_ge
                    ;;
                3)
                    show_progress "Abriendo Lutris..." "lutris"
                    ;;
                4|"")
                    return
                    ;;
            esac
            ;;
    esac
}

# Función para procesar argumentos
process_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --proton-only)
                init_tui
                setup_proton_ge
                ;;
            --wine-only)
                init_tui
                setup_wine_ge
                ;;
            --heroic-only)
                init_tui
                setup_heroic
                ;;
            --help)
                cat << EOF
Uso: $0 [OPCIÓN]
Opciones:
  --proton-only     Instalar solo Proton-GE
  --wine-only       Instalar solo Wine-GE
  --heroic-only     Configurar solo Heroic
  --help            Mostrar esta ayuda
EOF
                exit 0
                ;;
            *)
                show_error "Error" "Opción desconocida: $1\nUsa --help para ver las opciones disponibles"
                exit 1
                ;;
        esac
        shift
    done
}

# Punto de entrada principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Procesar argumentos si existen
    if [ $# -gt 0 ]; then
        process_args "$@"
    else
        # Inicializar TUI y ejecutar menú principal
        init_tui
        main_menu
    fi
fi