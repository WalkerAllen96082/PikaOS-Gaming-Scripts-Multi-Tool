#!/bin/bash

# Obtener el directorio del script
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Importar utilidades comunes
source "$SCRIPT_DIR/game_utils.sh"

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

# Bucle principal
while true; do
    show_main_menu
    
    case $choice in
        1) # Configuración Inicial
            echo "Iniciando configuración inicial..."
            "$SCRIPT_DIR/setup_launchers.sh"
            ;;
            
        2) # Instalar/Configurar Juego
            echo "Iniciando asistente de instalación de juegos..."
            "$SCRIPT_DIR/install_game.sh"
            ;;
            
        3) # Mantenimiento de Wine
            echo "Iniciando herramientas de mantenimiento..."
            "$SCRIPT_DIR/wine_maintenance.sh"
            ;;
            
        4) # Gestionar Launchers
            echo "Iniciando gestión de launchers..."
            "$SCRIPT_DIR/setup_launchers.sh"
            ;;
            
        5) # Ver Documentación
            show_quick_docs
            ;;
            
        6) # Salir
            echo "¡Gracias por usar PikaOS Gaming Tools!"
            exit 0
            ;;
            
        *)
            echo "Opción inválida. Por favor, seleccione una opción válida."
            sleep 2
            ;;
    esac
done