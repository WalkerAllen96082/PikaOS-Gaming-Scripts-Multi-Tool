#!/bin/bash
# Cargar configuración global (busca en varias ubicaciones relativas)
CONFIG_PATH=""
for p in "$(dirname "${BASH_SOURCE[0]}")/00_config.sh" "$(dirname "${BASH_SOURCE[0]}")/../00_config.sh" "$(pwd)/00_config.sh"; do
    if [ -f "$p" ]; then CONFIG_PATH="$p"; break; fi
done
if [ -n "$CONFIG_PATH" ]; then
    source "$CONFIG_PATH"
else
    echo "Warning: 00_config.sh no encontrado; se usarán valores por defecto (LOG_DIR en el home)"
fi

GAME_UTILS_LOG="$LOG_DIR/game_utils.log"
touch "$GAME_UTILS_LOG"

# Función para crear acceso directo de un juego
create_game_shortcut() {
    local game_name=$1
    local exe_path=$2
    local prefix=$3
    local icon=${4:-"applications-games"}
    
    create_desktop_entry \
        "$game_name" \
        "WINEPREFIX=\"$prefix\" wine \"$exe_path\"" \
        "$icon" \
        "Game;" \
        "Juego Windows ejecutado con Wine"
}

# Función para buscar ejecutables en un prefijo
find_executables() {
    local prefix=$1
    
    echo "Buscando ejecutables en: $prefix/drive_c"
    find "$prefix/drive_c" -type f -name "*.exe" -o -name "*.EXE"
}

# Función para crear accesos directos batch
create_batch_shortcuts() {
    local prefix=$1
    local shortcuts_dir="$HOME/.local/share/applications/wine-shortcuts"
    mkdir -p "$shortcuts_dir"
    
    echo "Creando accesos directos para ejecutables encontrados..."
    while IFS= read -r exe; do
        local name=$(basename "$exe" .exe)
        create_game_shortcut "$name" "$exe" "$prefix"
    done < <(find_executables "$prefix")
}

# Función para mostrar el menú de utilidades
show_utils_menu() {
    while true; do
        echo ""
        echo "=== Utilidades para Juegos ==="
        echo "1. Crear acceso directo para un juego"
        echo "2. Buscar ejecutables en prefijo Wine"
        echo "3. Crear accesos directos en lote"
        echo "4. Salir"
    
    read -p "Selecciona una opción: " option
    
    case $option in
        1)
            read -p "Nombre del juego: " game_name
            read -p "Ruta al ejecutable: " exe_path
            read -p "Ruta al prefijo Wine: " prefix
            read -p "Ruta al icono (opcional): " icon
            
            if [ -z "$icon" ]; then
                create_game_shortcut "$game_name" "$exe_path" "$prefix"
            else
                create_game_shortcut "$game_name" "$exe_path" "$prefix" "$icon"
            fi
            ;;
        2)
            read -p "Ruta al prefijo Wine: " prefix
            if [ -d "$prefix" ]; then
                find_executables "$prefix"
            else
                echo "Prefijo no encontrado"
            fi
            ;;
        3)
            read -p "Ruta al prefijo Wine: " prefix
            if [ -d "$prefix" ]; then
                create_batch_shortcuts "$prefix"
            else
                echo "Prefijo no encontrado"
            fi
            ;;
        4)
            exit 0
            ;;
        *)
            echo "Opción inválida"
            ;;
    esac
    done
}

# Solo mostrar el menú si el script se ejecuta directamente (no al ser sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    show_utils_menu
fi