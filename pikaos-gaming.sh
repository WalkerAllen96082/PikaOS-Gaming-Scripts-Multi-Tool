#!/bin/bash

# Asegurar que se ejecuta con bash
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Verificar si tenemos dialog instalado
check_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        echo "Instalando dialog..."
        if command -v pikman >/dev/null 2>&1; then
            pikman install dialog
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y dialog
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -Sy --noconfirm dialog
        else
            echo "No se pudo instalar dialog. Por favor, instálalo manualmente."
            exit 1
        fi
    fi
}

# Verificar permisos de ejecución
check_permissions() {
    local scripts=("gaming_tools.sh" "game_utils.sh" "install_game.sh" "setup_launchers.sh" "wine_maintenance.sh" "pkg_manager.sh")
    local missing_perms=0
    
    for script in "${scripts[@]}"; do
        if [ -f "$SCRIPT_DIR/$script" ] && [ ! -x "$SCRIPT_DIR/$script" ]; then
            echo "Dando permisos de ejecución a $script..."
            chmod +x "$SCRIPT_DIR/$script"
            missing_perms=1
        fi
    done
    
    return $missing_perms
}

# Función para mostrar el menú principal usando dialog
show_main_menu() {
    while true; do
        exec 3>&1
        selection=$(dialog \
            --clear \
            --title "🎮 PikaOS Gaming Tools 🎮" \
            --backtitle "Sistema de gestión de juegos completo" \
            --colors \
            --menu "Selecciona una opción:" 20 70 8 \
            "1" "🚀 Configuración Inicial (Recomendado primero)" \
            "2" "🎮 Instalar/Configurar Juego" \
            "3" "🛠️ Mantenimiento de Wine" \
            "4" "⚙️ Gestionar Launchers" \
            "5" "ℹ️ Ver Documentación" \
            "6" "📋 Ver Log" \
            "7" "🔄 Actualizar Scripts" \
            "8" "❌ Salir" \
            2>&1 1>&3)
        exit_status=$?
        exec 3>&-
        
        case $exit_status in
            1)
                clear
                echo "¡Gracias por usar PikaOS Gaming Tools!"
                exit 0
                ;;
            255)
                clear
                echo "La aplicación se cerró con ESC"
                exit 0
                ;;
        esac
        
        case $selection in
            1)
                dialog --infobox "Iniciando configuración inicial..." 3 40
                sleep 1
                clear
                "$SCRIPT_DIR/setup_launchers.sh"
                ;;
            2)
                dialog --infobox "Iniciando asistente de instalación..." 3 40
                sleep 1
                clear
                "$SCRIPT_DIR/install_game.sh"
                ;;
            3)
                dialog --infobox "Iniciando mantenimiento de Wine..." 3 40
                sleep 1
                clear
                "$SCRIPT_DIR/wine_maintenance.sh"
                ;;
            4)
                dialog --infobox "Iniciando gestión de launchers..." 3 40
                sleep 1
                clear
                "$SCRIPT_DIR/setup_launchers.sh"
                ;;
            5)
                show_documentation
                ;;
            6)
                show_logs
                ;;
            7)
                update_scripts
                ;;
            8)
                clear
                echo "¡Gracias por usar PikaOS Gaming Tools!"
                exit 0
                ;;
        esac
        
        # Pausa después de cada operación
        if [ $selection != "8" ]; then
            dialog --title "Operación Completada" \
                --msgbox "Presiona ENTER para volver al menú principal" 5 50
        fi
    done
}

# Función para mostrar documentación
show_documentation() {
    dialog --title "📚 Guía Rápida de Gaming Tools" \
        --msgbox "\
Orden recomendado de uso:

1. Ejecutar Configuración Inicial para instalar:
   - Proton-GE (para Steam)
   - Wine-GE (para Heroic/Lutris)
   - Launchers necesarios

2. Usar Instalar/Configurar Juego para:
   - Instalar nuevos juegos
   - Configurar juegos existentes
   - Seleccionar versiones de compatibilidad

3. Usar Mantenimiento de Wine para:
   - Limpiar prefijos
   - Hacer backups
   - Instalar componentes

4. Usar Gestionar Launchers para:
   - Actualizar Proton/Wine-GE
   - Configurar launchers
   - Gestionar versiones" 20 60
}

# Función para mostrar logs
show_logs() {
    local log_file="$HOME/.local/share/pikaos-gaming/pikaos-gaming.log"
    if [ -f "$log_file" ]; then
        dialog --title "📋 Logs del Sistema" \
            --textbox "$log_file" 20 70
    else
        dialog --title "📋 Logs del Sistema" \
            --msgbox "No hay logs disponibles." 5 30
    fi
}

# Función para actualizar los scripts
update_scripts() {
    if [ -d "$SCRIPT_DIR/.git" ]; then
        dialog --infobox "Actualizando scripts desde el repositorio..." 3 50
        if git -C "$SCRIPT_DIR" pull; then
            dialog --title "✅ Actualización Completada" \
                --msgbox "Los scripts se han actualizado correctamente." 5 50
            # Verificar permisos después de actualizar
            check_permissions
        else
            dialog --title "❌ Error" \
                --msgbox "No se pudo actualizar los scripts." 5 40
        fi
    else
        dialog --title "❌ Error" \
            --msgbox "No se encontró el repositorio git." 5 40
    fi
}

# Crear acceso directo en el escritorio
create_desktop_shortcut() {
    local desktop_dir="$HOME/Desktop"
    [ ! -d "$desktop_dir" ] && desktop_dir="$HOME/Escritorio"
    
    cat > "$desktop_dir/pikaos-gaming.desktop" << EOF
[Desktop Entry]
Name=PikaOS Gaming Tools
Comment=Herramientas de gaming para PikaOS
Exec=bash -c 'cd "$(dirname "$(readlink -f "%k")")" && ./pikaos-gaming.sh'
Icon=applications-games
Terminal=true
Type=Application
Categories=Game;
EOF
    
    chmod +x "$desktop_dir/pikaos-gaming.desktop"
}

# Configuración inicial
setup() {
    # Crear directorio para logs
    mkdir -p "$HOME/.local/share/pikaos-gaming"
    
    # Verificar y dar permisos de ejecución
    check_permissions
    
    # Verificar dialog
    check_dialog
    
    # Crear acceso directo
    create_desktop_shortcut
}

# Punto de entrada principal
main() {
    # Configuración inicial
    setup
    
    # Mostrar menú principal
    show_main_menu
}

# Ejecutar el programa
main