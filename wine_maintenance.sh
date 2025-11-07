#!/bin/bash

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Importar utilidades
source "$SCRIPT_DIR/tui_utils.sh"
source "$SCRIPT_DIR/00_config.sh" || log_message "WARNING" "00_config.sh no encontrado; usando valores por defecto"

WINE_MAINTENANCE_LOG="$LOG_DIR/wine_maintenance.log"
touch "$WINE_MAINTENANCE_LOG" 2>/dev/null || true

# Función para listar prefijos Wine
list_prefixes() {
    local prefix_dirs=(
        "$HOME/.local/share/wineprefixes"
        "$HOME/.wine"
        "$HOME/.local/share/heroic/prefixes"
        "$HOME/.local/share/Steam/steamapps/compatdata"
    )
    
    # Crear array para el menú
    local prefix_options=()
    local option_num=1
    declare -a prefix_paths=()
    
    for dir in "${prefix_dirs[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r prefix; do
                if [ -d "$prefix" ]; then
                    prefix_paths+=("$prefix")
                    prefix_options+=("$option_num")
                    prefix_options+=("🍷 $(basename "$prefix") ($(dirname "$prefix"))")
                    ((option_num++))
                fi
            done < <(find "$dir" -name "drive_c" -type d -exec dirname {} \;)
        fi
    done
    
    # Si no hay prefijos, mostrar error
    if [ ${#prefix_paths[@]} -eq 0 ]; then
        show_error "Error" "No se encontraron prefijos Wine"
        return 1
    fi
    
    # Agregar opción para cancelar
    prefix_options+=("$option_num" "❌ Cancelar")
    
    # Mostrar menú y obtener selección
    local choice=$(show_menu "Prefijos Wine" "Selecciona un prefijo:" "${prefix_options[@]}")
    
    # Si se seleccionó cancelar o ESC
    if [ "$choice" = "$option_num" ] || [ -z "$choice" ]; then
        return 1
    fi
    
    # Devolver el prefijo seleccionado
    echo "${prefix_paths[$((choice-1))]}"
    return 0
}

# Función para limpiar un prefijo
clean_prefix() {
    local prefix=$1
    export WINEPREFIX="$prefix"
    
    log_message "INFO" "Iniciando limpieza del prefijo: $prefix" "$WINE_MAINTENANCE_LOG"
    
    show_progress "Limpiando archivos temporales..." "rm -rf \"$prefix/drive_c/windows/temp/\"* \"$prefix/drive_c/users/$USER/Temp/\"*"
    
    show_progress "Desfragmentando registro de Wine..." "wine regedit /s \"$prefix/system.reg\""
    
    log_message "SUCCESS" "Limpieza completada para: $prefix" "$WINE_MAINTENANCE_LOG"
    show_success "Limpieza Completada" "El prefijo ha sido limpiado exitosamente:\n$prefix"
    
    return 0
}

# Función para hacer backup de un prefijo
backup_prefix() {
    local prefix=$1
    local backup_dir="$HOME/.wine_backups"
    mkdir -p "$backup_dir"
    
    local backup_name="wine_prefix_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="$backup_dir/$backup_name"
    
    log_message "INFO" "Iniciando backup del prefijo: $prefix" "$WINE_MAINTENANCE_LOG"
    
    # Mostrar diálogo de progreso mientras se crea el backup
    (
        cd "$(dirname "$prefix")" || exit 1
        tar czf "$backup_path" "$(basename "$prefix")"
    ) 2>&1 | dialog --gauge "Creando backup del prefijo..." 10 70 0
    
    if [ -f "$backup_path" ]; then
        log_message "SUCCESS" "Backup creado en: $backup_path" "$WINE_MAINTENANCE_LOG"
        show_success "Backup Completado" "El backup ha sido creado exitosamente en:\n$backup_path"
    else
        log_message "ERROR" "Error al crear backup en: $backup_path" "$WINE_MAINTENANCE_LOG"
        show_error "Error" "No se pudo crear el backup del prefijo"
        return 1
    fi
    
    return 0
}

# Función para instalar componentes comunes de Wine
install_components() {
    local prefix=$1
    export WINEPREFIX="$prefix"
    
    log_message "INFO" "Iniciando instalación de componentes en: $prefix" "$WINE_MAINTENANCE_LOG"
    
    # Lista de componentes a instalar
    local components=(
        "vcrun2019:Visual C++ 2019 Runtime"
        "d3dx9:DirectX 9"
        "xact:XACT Audio"
        "dxvk:DXVK (DirectX sobre Vulkan)"
    )
    
    # Crear menú de selección múltiple
    local options=()
    local i=1
    for comp in "${components[@]}"; do
        IFS=':' read -r id desc <<< "$comp"
        options+=("$i" "$desc" "on")
        ((i++))
    done
    
    # Mostrar menú de selección
    local selected
    exec 3>&1
    selected=$(dialog --title "Instalación de Componentes" \
                     --checklist "Selecciona los componentes a instalar:" \
                     15 60 8 \
                     "${options[@]}" \
                     2>&1 1>&3)
    local result=$?
    exec 3>&-
    
    # Si se canceló la selección
    if [ $result -ne 0 ]; then
        return 1
    fi
    
    # Instalar componentes seleccionados
    for choice in $selected; do
        local comp_id=$(echo "${components[$((choice-1))]}" | cut -d: -f1)
        show_progress "Instalando $comp_id..." "winetricks -q $comp_id"
        log_message "INFO" "Componente instalado: $comp_id" "$WINE_MAINTENANCE_LOG"
    done
    
    show_success "Instalación Completada" "Los componentes seleccionados han sido instalados en:\n$prefix"
    log_message "SUCCESS" "Instalación de componentes completada en: $prefix" "$WINE_MAINTENANCE_LOG"
    
    return 0
}

# Función principal
main() {
    # Inicializar TUI
    init_tui
    
    # Log de inicio
    log_message "INFO" "Iniciando herramienta de mantenimiento de Wine" "$WINE_MAINTENANCE_LOG"
    
    # Menú principal
    while true; do
        local main_options=(
            "1" "🧹 Limpiar prefijo Wine"
            "2" "💾 Hacer backup de prefijo"
            "3" "🔧 Instalar componentes"
            "4" "📋 Ver logs"
            "5" "❌ Salir"
        )
        
        local choice=$(show_menu "Mantenimiento de Wine" "Selecciona una operación:" "${main_options[@]}")
        
        case $choice in
            1)  # Limpiar prefijo
                local prefix
                if prefix=$(list_prefixes); then
                    if [ -d "$prefix" ]; then
                        clean_prefix "$prefix"
                    else
                        show_error "Error" "El prefijo seleccionado no existe:\n$prefix"
                    fi
                fi
                ;;
            2)  # Backup
                local prefix
                if prefix=$(list_prefixes); then
                    if [ -d "$prefix" ]; then
                        backup_prefix "$prefix"
                    else
                        show_error "Error" "El prefijo seleccionado no existe:\n$prefix"
                    fi
                fi
                ;;
            3)  # Instalar componentes
                local prefix
                if prefix=$(list_prefixes); then
                    if [ -d "$prefix" ]; then
                        install_components "$prefix"
                    else
                        show_error "Error" "El prefijo seleccionado no existe:\n$prefix"
                    fi
                fi
                ;;
            4)  # Ver logs
                view_logs
                ;;
            5|"")  # Salir
                cleanup_tui
                exit 0
                ;;
        esac
    done
}

# Ejecutar programa si no es sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi