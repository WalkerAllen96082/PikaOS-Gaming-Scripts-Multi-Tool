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
WINE_MAINTENANCE_LOG="$LOG_DIR/wine_maintenance.log"
touch "$WINE_MAINTENANCE_LOG"

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

# Función para listar prefijos de Wine
list_wine_prefixes() {
    local prefixes=()
    local descriptions=()
    local i=1
    
    # Buscar en ubicaciones comunes
    for prefix_dir in "$HOME/.wine" "$HOME/.local/share/wineprefixes/"*/ "$HOME/.local/share/wine/"*/; do
        if [ -d "$prefix_dir" ] && [ -f "$prefix_dir/system.reg" ]; then
            local name=$(basename "$prefix_dir")
            prefixes+=("$prefix_dir")
            descriptions+=("Prefijo: $name")
            ((i++))
        fi
    done
    
    echo "PREFIXES=${prefixes[*]}"
    echo "DESCRIPTIONS=${descriptions[*]}"
}

# Función para hacer backup de un prefijo
backup_prefix() {
    local prefix="$1"
    local backup_dir="$HOME/.local/share/wine-backups"
    mkdir -p "$backup_dir"
    
    local backup_name="wine-prefix-$(basename "$prefix")-$(date +%Y%m%d-%H%M%S).tar.gz"
    local backup_path="$backup_dir/$backup_name"
    
    show_progress "Creando backup..." "tar czf \"$backup_path\" -C \"$(dirname "$prefix")\" \"$(basename "$prefix")\""
    
    if [ -f "$backup_path" ]; then
        show_success "Backup Completado" "Backup guardado en:\n$backup_path"
        log_message "SUCCESS" "Backup creado: $backup_path" "$WINE_MAINTENANCE_LOG"
    else
        show_error "Error" "No se pudo crear el backup"
        log_message "ERROR" "Fallo al crear backup de $prefix" "$WINE_MAINTENANCE_LOG"
    fi
    
    handle_operation_end
}

# Función para restaurar backup
restore_prefix() {
    local backup_dir="$HOME/.local/share/wine-backups"
    if [ ! -d "$backup_dir" ]; then
        show_error "Error" "No se encontraron backups"
        handle_operation_end
        return
    fi
    
    # Crear lista de backups disponibles
    local backups=()
    local i=1
    while IFS= read -r backup; do
        backups+=("$i" "📦 $(basename "$backup")")
        ((i++))
    done < <(ls -1 "$backup_dir"/*.tar.gz 2>/dev/null)
    
    if [ ${#backups[@]} -eq 0 ]; then
        show_error "Error" "No hay backups disponibles"
        handle_operation_end
        return
    fi
    
    backups+=("$i" "⬅️ Volver")
    
    local choice=$(show_menu "Restaurar Backup" "Selecciona un backup:" "${backups[@]}")
    
    if [ "$choice" != "$i" ] && [ -n "$choice" ]; then
        local selected_backup="$backup_dir/$(basename "${backups[$(((choice-1)*2+1))]}")"
        local restore_dir="$HOME/.local/share/wineprefixes"
        
        if confirm "Restaurar" "¿Estás seguro de restaurar este backup?\nSe sobrescribirá el prefijo existente si ya existe."; then
            mkdir -p "$restore_dir"
            show_progress "Restaurando backup..." "tar xzf \"$selected_backup\" -C \"$restore_dir\""
            show_success "Éxito" "Backup restaurado correctamente"
            log_message "SUCCESS" "Backup restaurado: $selected_backup" "$WINE_MAINTENANCE_LOG"
        fi
    fi
    
    handle_operation_end
}

# Función para limpiar un prefijo
clean_prefix() {
    # Obtener lista de prefijos
    eval "$(list_wine_prefixes)"
    
    if [ ${#PREFIXES[@]} -eq 0 ]; then
        show_error "Error" "No se encontraron prefijos de Wine"
        handle_operation_end
        return
    fi
    
    # Crear opciones de menú
    local options=()
    local i=1
    for prefix in "${PREFIXES[@]}"; do
        options+=("$i" "🗑️ $(basename "$prefix")")
        ((i++))
    done
    options+=("$i" "⬅️ Volver")
    
    local choice=$(show_menu "Limpiar Prefijo" "Selecciona un prefijo:" "${options[@]}")
    
    if [ "$choice" != "$i" ] && [ -n "$choice" ]; then
        local selected_prefix="${PREFIXES[$((choice-1))]}"
        
        if confirm "Limpiar" "¿Estás seguro de limpiar este prefijo?\nSe eliminarán archivos temporales y caché."; then
            show_progress "Limpiando prefijo..." "rm -rf \"$selected_prefix/drive_c/users/*/Temp/*\" \"$selected_prefix/drive_c/users/*/AppData/Local/Temp/*\""
            show_success "Éxito" "Prefijo limpiado correctamente"
            log_message "SUCCESS" "Prefijo limpiado: $selected_prefix" "$WINE_MAINTENANCE_LOG"
        fi
    fi
    
    handle_operation_end
}

# Función para instalar componentes
install_components() {
    local component_options=(
        "1" "📦 vcrun2015"
        "2" "📦 d3dx9"
        "3" "📦 xact"
        "4" "📦 corefonts"
        "5" "⬅️ Volver"
    )
    
    local choice=$(show_menu "Componentes de Wine" "Selecciona un componente:" "${component_options[@]}")
    
    case $choice in
        1|2|3|4)
            eval "$(list_wine_prefixes)"
            if [ ${#PREFIXES[@]} -eq 0 ]; then
                show_error "Error" "No se encontraron prefijos de Wine"
                handle_operation_end
                return
            fi
            
            local prefix_options=()
            local i=1
            for prefix in "${PREFIXES[@]}"; do
                prefix_options+=("$i" "🍷 $(basename "$prefix")")
                ((i++))
            done
            prefix_options+=("$i" "⬅️ Volver")
            
            local prefix_choice=$(show_menu "Seleccionar Prefijo" "¿En qué prefijo quieres instalar?" "${prefix_options[@]}")
            
            if [ "$prefix_choice" != "$i" ] && [ -n "$prefix_choice" ]; then
                local selected_prefix="${PREFIXES[$((prefix_choice-1))]}"
                local component
                case $choice in
                    1) component="vcrun2015";;
                    2) component="d3dx9";;
                    3) component="xact";;
                    4) component="corefonts";;
                esac
                
                show_progress "Instalando $component..." "WINEPREFIX=\"$selected_prefix\" winetricks $component"
                show_success "Éxito" "$component instalado correctamente"
                log_message "SUCCESS" "Componente $component instalado en $selected_prefix" "$WINE_MAINTENANCE_LOG"
            fi
            ;;
        5|"")
            return
            ;;
    esac
    
    handle_operation_end
}

# Función principal del menú
main_menu() {
    while true; do
        local options=(
            "1" "💾 Backup de Prefijo"
            "2" "📥 Restaurar Backup"
            "3" "🧹 Limpiar Prefijo"
            "4" "📦 Instalar Componentes"
            "5" "📋 Ver Logs"
            "6" "🏠 Volver al Menú Principal"
            "7" "❌ Salir"
        )
        
        local choice=$(show_menu "Mantenimiento de Wine" "Selecciona una opción:" "${options[@]}")
        
        case $choice in
            1)
                eval "$(list_wine_prefixes)"
                if [ ${#PREFIXES[@]} -eq 0 ]; then
                    show_error "Error" "No se encontraron prefijos de Wine"
                    handle_operation_end
                else
                    local prefix_options=()
                    local i=1
                    for prefix in "${PREFIXES[@]}"; do
                        prefix_options+=("$i" "🍷 $(basename "$prefix")")
                        ((i++))
                    done
                    prefix_options+=("$i" "⬅️ Volver")
                    
                    local backup_choice=$(show_menu "Backup de Prefijo" "Selecciona un prefijo:" "${prefix_options[@]}")
                    
                    if [ "$backup_choice" != "$i" ] && [ -n "$backup_choice" ]; then
                        backup_prefix "${PREFIXES[$((backup_choice-1))]}"
                    fi
                fi
                ;;
            2)
                restore_prefix
                ;;
            3)
                clean_prefix
                ;;
            4)
                install_components
                ;;
            5)
                view_logs
                ;;
            6)
                cleanup_tui
                exec "$SCRIPT_DIR/gaming_tools.sh"
                ;;
            7|"")
                cleanup_tui
                exit 0
                ;;
        esac
    done
}

# Punto de entrada principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    init_tui
    main_menu
fi