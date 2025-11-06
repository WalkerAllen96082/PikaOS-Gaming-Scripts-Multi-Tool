#!/bin/bash
source "$(dirname "$0")/../00_config.sh"

WINE_MAINTENANCE_LOG="$LOG_DIR/wine_maintenance.log"
touch "$WINE_MAINTENANCE_LOG"

# Función para listar prefijos Wine
list_prefixes() {
    echo "Prefijos Wine encontrados:"
    echo "-------------------------"
    
    # Buscar en ubicaciones comunes
    local prefix_dirs=(
        "$HOME/.local/share/wineprefixes"
        "$HOME/.wine"
        "$HOME/.local/share/heroic/prefixes"
        "$HOME/.local/share/Steam/steamapps/compatdata"
    )
    
    for dir in "${prefix_dirs[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -name "drive_c" -type d -exec dirname {} \;
        fi
    done
}

# Función para limpiar un prefijo
clean_prefix() {
    local prefix=$1
    export WINEPREFIX="$prefix"
    
    echo "Limpiando prefijo: $prefix"
    
    # Eliminar archivos temporales
    rm -rf "$prefix/drive_c/windows/temp/"*
    rm -rf "$prefix/drive_c/users/$USER/Temp/"*
    
    # Desfragmentar registro de Wine
    wine regedit /s "$prefix/system.reg"
    
    echo "Limpieza completada"
}

# Función para hacer backup de un prefijo
backup_prefix() {
    local prefix=$1
    local backup_dir="$HOME/.wine_backups"
    mkdir -p "$backup_dir"
    
    local backup_name="wine_prefix_$(date +%Y%m%d_%H%M%S).tar.gz"
    tar -czf "$backup_dir/$backup_name" -C "$(dirname "$prefix")" "$(basename "$prefix")"
    
    echo "Backup creado: $backup_dir/$backup_name"
}

# Función para instalar componentes comunes de Wine
install_components() {
    local prefix=$1
    export WINEPREFIX="$prefix"
    
    echo "Instalando componentes en: $prefix"
    
    winetricks -q vcrun2019
    winetricks -q d3dx9
    winetricks -q xact
    winetricks -q dxvk
    
    echo "Componentes instalados"
}

# Menú principal
while true; do
    echo ""
    echo "=== Mantenimiento de Prefijos Wine ==="
    echo "1. Listar prefijos Wine"
    echo "2. Limpiar prefijo"
    echo "3. Hacer backup de prefijo"
    echo "4. Instalar componentes comunes"
    echo "5. Salir"
    
    read -p "Selecciona una opción: " option
    
    case $option in
        1)
            list_prefixes
            ;;
        2)
            list_prefixes
            read -p "Ingresa la ruta del prefijo a limpiar: " prefix
            if [ -d "$prefix" ]; then
                clean_prefix "$prefix"
            else
                echo "Prefijo no encontrado"
            fi
            ;;
        3)
            list_prefixes
            read -p "Ingresa la ruta del prefijo para backup: " prefix
            if [ -d "$prefix" ]; then
                backup_prefix "$prefix"
            else
                echo "Prefijo no encontrado"
            fi
            ;;
        4)
            list_prefixes
            read -p "Ingresa la ruta del prefijo para instalar componentes: " prefix
            if [ -d "$prefix" ]; then
                install_components "$prefix"
            else
                echo "Prefijo no encontrado"
            fi
            ;;
        5)
            exit 0
            ;;
        *)
            echo "Opción inválida"
            ;;
    esac
done