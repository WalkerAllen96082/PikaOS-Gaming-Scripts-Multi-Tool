#!/bin/bash

# Obtener el directorio del script
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Importar utilidades comunes
if [ -f "$SCRIPT_DIR/game_utils.sh" ]; then
    source "$SCRIPT_DIR/game_utils.sh"
else
    echo "Error: No se encuentran las utilidades comunes"
    exit 1
fi

# Verificar dependencias críticas
for dep in dialog pv; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "Error: Falta la dependencia $dep"
        echo "Por favor, instala $dep antes de continuar"
        exit 1
    fi
done

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

# Función para reiniciar el script actual
restart_script() {
    if confirm "Reiniciar" "¿Deseas realizar otra operación?"; then
        cleanup_tui
        exec "$0"
    fi
}

# Función para mostrar el banner
show_banner() {
    echo "=================================="
    echo "🎮 PikaOS Gaming Tools 🎮"
    echo "=================================="
    echo "Sistema de gestión de juegos completo"
    echo ""
}

# Función para mostrar el menú principal
show_main_menu() {
    clear
    show_banner
    echo "Menú Principal:"
    echo "1. 🚀 Configuración Inicial (Recomendado primero)"
    echo "2. 🎮 Instalar/Configurar Juego"
    echo "3. 🛠️ Mantenimiento de Wine"
    echo "4. ⚙️ Gestionar Launchers"
    echo "5. ℹ️ Ver Documentación"
    echo "6. ❌ Salir"
    echo ""
    read -p "Seleccione una opción (1-6): " choice
}

# Función para mostrar documentación rápida
show_quick_docs() {
    clear
    echo "📚 Guía Rápida de Gaming Tools"
    echo "==============================="
    echo ""
    echo "Orden recomendado de uso:"
    echo "1. Ejecutar Configuración Inicial para instalar y configurar:"
    echo "   - Proton-GE (para Steam)"
    echo "   - Wine-GE (para Heroic/Lutris)"
    echo "   - Launchers necesarios"
    echo ""
    echo "2. Usar Instalar/Configurar Juego para:"
    echo "   - Instalar nuevos juegos"
    echo "   - Configurar juegos existentes"
    echo "   - Seleccionar versiones de compatibilidad"
    echo ""
    echo "3. Usar Mantenimiento de Wine para:"
    echo "   - Limpiar prefijos"
    echo "   - Hacer backups"
    echo "   - Instalar componentes adicionales"
    echo ""
    echo "4. Usar Gestionar Launchers para:"
    echo "   - Actualizar Proton/Wine-GE"
    echo "   - Configurar launchers específicos"
    echo "   - Gestionar versiones de compatibilidad"
    echo ""
    read -p "Presione Enter para volver al menú principal..."
}

# Función principal
main() {
    # Inicializar TUI
    init_tui

    while true; do
        local options=(
            "1" "🚀 Configuración Inicial"
            "2" "🎮 Instalar/Configurar Juego"
            "3" "🛠️ Mantenimiento de Wine"
            "4" "⚙️ Gestionar Launchers"
            "5" "ℹ️ Ver Documentación"
            "6" "❌ Salir"
        )
        
        local choice=$(show_menu "PikaOS Gaming Tools" "Menú Principal" "${options[@]}")
        
        case $choice in
            1) # Configuración Inicial
                show_info "Configuración Inicial" "Iniciando configuración inicial..."
                if [ -x "$SCRIPT_DIR/setup_launchers.sh" ]; then
                    cleanup_tui
                    exec "$SCRIPT_DIR/setup_launchers.sh"
                else
                    show_error "Error" "No se encuentra el script de configuración"
                    sleep 2
                fi
                ;;
                
            2) # Instalar/Configurar Juego
                show_info "Instalación" "Iniciando asistente de instalación..."
                if [ -x "$SCRIPT_DIR/install_game.sh" ]; then
                    cleanup_tui
                    exec "$SCRIPT_DIR/install_game.sh"
                else
                    show_error "Error" "No se encuentra el asistente de instalación"
                    sleep 2
                fi
                ;;
                
            3) # Mantenimiento de Wine
                show_info "Mantenimiento" "Iniciando herramientas de mantenimiento..."
                if [ -x "$SCRIPT_DIR/wine_maintenance.sh" ]; then
                    cleanup_tui
                    exec "$SCRIPT_DIR/wine_maintenance.sh"
                else
                    show_error "Error" "No se encuentran las herramientas de mantenimiento"
                    sleep 2
                fi
                ;;
                
            4) # Gestionar Launchers
                show_info "Launchers" "Iniciando gestión de launchers..."
                if [ -x "$SCRIPT_DIR/setup_launchers.sh" ]; then
                    cleanup_tui
                    exec "$SCRIPT_DIR/setup_launchers.sh"
                else
                    show_error "Error" "No se encuentra el gestor de launchers"
                    sleep 2
                fi
                ;;
                
            5) # Ver Documentación
                show_info "Documentación" "Mostrando documentación..."
                show_quick_docs
                ;;
                
            6|"") # Salir
                show_info "Salir" "¡Gracias por usar PikaOS Gaming Tools!"
                cleanup_tui
                exit 0
                ;;
        esac
    done
}

# Iniciar la aplicación
main