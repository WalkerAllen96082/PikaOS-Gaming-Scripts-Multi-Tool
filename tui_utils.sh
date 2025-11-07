#!/bin/bash
# Utilidades comunes para TUI
# Requiere: dialog, pv, wget/curl

# Asegurar que tenemos las dependencias necesarias
check_tui_deps() {
    local deps=(dialog pv)
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Instalando dependencias necesarias: ${missing[*]}"
        if command -v pikman >/dev/null 2>&1; then
            for pkg in "${missing[@]}"; do
                pikman install "$pkg"
            done
        elif command -v apt >/dev/null 2>&1; then
            sudo apt update && sudo apt install -y "${missing[@]}"
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -Sy --noconfirm "${missing[@]}"
        else
            echo "No se pudieron instalar las dependencias. Por favor, instala: ${missing[*]}"
            exit 1
        fi
    fi
}

# Mostrar barra de progreso para descargas
# Uso: download_with_progress "URL" "archivo_destino"
download_with_progress() {
    local url="$1"
    local dest="$2"
    local size
    
    # Obtener tamaño del archivo
    size=$(curl -sI "$url" | grep -i content-length | awk '{print $2}' | tr -d '\r')
    size=${size:-0}
    
    # Mostrar barra de progreso con dialog
    (wget -O- "$url" 2>/dev/null | pv -s "$size" > "$dest") 2>&1 | \
    dialog --gauge "Descargando $(basename "$dest")..." 10 70 0
}

# Mostrar progreso de operaciones lentas
# Uso: show_progress "Mensaje" "Comando"
show_progress() {
    local msg="$1"
    local cmd="$2"
    
    # Ejecutar comando y mostrar progreso
    ($cmd) 2>&1 | \
    dialog --progressbox "$msg" 20 70
}

# Mostrar menú con opciones
# Uso: show_menu "Título" "Subtítulo" ["opción1" "descripción1" ...]
show_menu() {
    local title="$1"
    local subtitle="$2"
    shift 2
    local options=("$@")
    local menu_height=$((${#options[@]} / 2 + 7))
    
    exec 3>&1
    local selection=$(dialog \
        --clear \
        --title "$title" \
        --backtitle "$subtitle" \
        --menu "Selecciona una opción:" \
        $menu_height 70 ${#options[@]} \
        "${options[@]}" \
        2>&1 1>&3)
    local result=$?
    exec 3>&-
    echo "$selection"
    return $result
}

# Mostrar mensaje de información
# Uso: show_info "Título" "Mensaje"
show_info() {
    dialog --title "$1" \
           --msgbox "$2" 0 0
}

# Mostrar mensaje de error
# Uso: show_error "Título" "Mensaje"
show_error() {
    dialog --title "$1" \
           --colors \
           --msgbox "\Z1$2\Zn" 0 0
}

# Mostrar mensaje de éxito
# Uso: show_success "Título" "Mensaje"
show_success() {
    dialog --title "$1" \
           --colors \
           --msgbox "\Z2$2\Zn" 0 0
}

# Solicitar entrada del usuario
# Uso: user_input "Título" "Pregunta"
user_input() {
    exec 3>&1
    local input=$(dialog \
        --title "$1" \
        --inputbox "$2" \
        0 0 \
        2>&1 1>&3)
    local result=$?
    exec 3>&-
    echo "$input"
    return $result
}

# Mostrar progreso de instalación de paquetes
# Uso: pkg_install_progress "paquete"
pkg_install_progress() {
    local pkg="$1"
    local temp_file=$(mktemp)
    
    (
        # Redireccionar salida del instalador al archivo temporal
        pkg_install "$pkg" > "$temp_file" 2>&1 &
        local pid=$!
        
        # Mostrar progreso mientras se instala
        while kill -0 $pid 2>/dev/null; do
            local progress=$(tail -n 1 "$temp_file" | tr '\r' '\n' | tail -n 1)
            echo "XXX"
            echo "50"
            echo "Instalando $pkg...\n$progress"
            echo "XXX"
            sleep 0.1
        done
    ) | dialog --gauge "Instalando $pkg..." 10 70 0
    
    rm -f "$temp_file"
}

# Función para log con timestamp y detalles extendidos
log_message() {
    local level="$1"
    local message="$2"
    local script_name="${3:-${BASH_SOURCE[1]}}"
    local func_name="${FUNCNAME[1]:-main}"
    
    # Obtener el directorio del script que se está ejecutando
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    local log_dir="$script_dir/logs"
    mkdir -p "$log_dir"
    
    # Crear logs específicos por componente y un log general
    local component_log="$log_dir/$(basename "$script_name" .sh).log"
    local general_log="$log_dir/pikaos-gaming.log"
    
    # Obtener información del sistema
    local distro="$(cat /etc/os-release 2>/dev/null | grep "^NAME=" | cut -d= -f2 | tr -d '"' || echo "Unknown")"
    local kernel="$(uname -r 2>/dev/null || echo "Unknown")"
    local pkg_mgr="$(command -v pikman >/dev/null && echo "pikman" || command -v apt >/dev/null && echo "apt" || echo "unknown")"
    
    # Formatear mensaje con detalles extendidos
    local log_entry="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] [$(basename "$script_name"):$func_name]"
    log_entry+=" [System: $distro | Kernel: $kernel | PkgMgr: $pkg_mgr]"
    log_entry+=$'\n'"Message: $message"
    
    # Si hay variables de entorno relevantes, incluirlas
    if [ -n "$WINEPREFIX" ]; then
        log_entry+=$'\n'"WINEPREFIX: $WINEPREFIX"
    fi
    if [ -n "$STEAM_COMPAT_DATA_PATH" ]; then
        log_entry+=$'\n'"STEAM_COMPAT_DATA_PATH: $STEAM_COMPAT_DATA_PATH"
    fi
    
    # Añadir separador para mejor legibilidad
    log_entry+=$'\n'"----------------------------------------"
    
    # Escribir en ambos logs
    echo -e "$log_entry" >> "$component_log"
    echo -e "$log_entry" >> "$general_log"
    
    # Para errores, también guardar el stack trace
    if [ "$level" = "ERROR" ]; then
        echo "Stack trace:" >> "$component_log"
        echo "Stack trace:" >> "$general_log"
        local frame=0
        while caller $frame; do
            ((frame++))
        done | tac | sed 's/^/  /' >> "$component_log"
        caller 0 | tac | sed 's/^/  /' >> "$general_log"
    fi
}

# Función para ver logs
view_logs() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
    local log_dir="$script_dir/logs"
    
    if [ ! -d "$log_dir" ]; then
        show_error "Error" "No hay directorio de logs"
        return 1
    fi
    
    # Crear lista de logs disponibles
    local log_options=()
    local i=1
    
    # Primero añadir el log general
    if [ -f "$log_dir/pikaos-gaming.log" ]; then
        log_options+=("$i" "📋 Log General del Sistema")
        ((i++))
    fi
    
    # Añadir logs específicos de componentes
    for log in "$log_dir"/*.log; do
        if [ -f "$log" ] && [ "$(basename "$log")" != "pikaos-gaming.log" ]; then
            log_options+=("$i" "📄 Log de $(basename "$log" .log)")
            ((i++))
        fi
    done
    
    # Si no hay logs, mostrar error
    if [ ${#log_options[@]} -eq 0 ]; then
        show_error "Error" "No hay logs disponibles"
        return 1
    fi
    
    # Añadir opción para ver todos los logs
    log_options+=("$i" "📚 Ver todos los logs")
    ((i++))
    
    # Añadir opción para limpiar logs
    log_options+=("$i" "🗑️ Limpiar logs")
    ((i++))
    
    # Mostrar menú de selección
    local choice=$(show_menu "Visor de Logs" "Selecciona un log para ver:" "${log_options[@]}")
    
    case $choice in
        "")  # ESC presionado
            return 0
            ;;
        "$((i-1))")  # Limpiar logs
            if confirm "Limpiar Logs" "¿Estás seguro de que quieres limpiar todos los logs?"; then
                rm -f "$log_dir"/*.log
                show_success "Logs Limpiados" "Todos los logs han sido eliminados"
            fi
            ;;
        "$((i-2))")  # Ver todos
            # Concatenar todos los logs en orden temporal
            (
                echo "=== LOGS COMPLETOS DEL SISTEMA ==="
                echo "Generado: $(date '+%Y-%m-%d %H:%M:%S')"
                echo "----------------------------------------"
                for log in "$log_dir"/*.log; do
                    if [ -f "$log" ]; then
                        echo -e "\n=== $(basename "$log") ===\n"
                        cat "$log"
                    fi
                done
            ) | dialog --title "📚 Todos los Logs" --textbox /dev/stdin 30 100
            ;;
        *)  # Ver log específico
            if [ "$choice" = "1" ]; then
                dialog --title "📋 Log General del Sistema" \
                       --textbox "$log_dir/pikaos-gaming.log" \
                       30 100
            else
                local log_file
                local j=2
                for log in "$log_dir"/*.log; do
                    if [ -f "$log" ] && [ "$(basename "$log")" != "pikaos-gaming.log" ]; then
                        if [ "$j" = "$choice" ]; then
                            log_file="$log"
                            break
                        fi
                        ((j++))
                    fi
                done
                if [ -n "$log_file" ]; then
                    dialog --title "📄 Log de $(basename "$log_file" .log)" \
                           --textbox "$log_file" \
                           30 100
                fi
            fi
            ;;
    esac
}

# Función para confirmar acción
# Uso: confirm "Título" "Mensaje"
confirm() {
    dialog --title "$1" \
           --yesno "$2" \
           0 0
    return $?
}

# Inicializar TUI
init_tui() {
    # Verificar dependencias
    check_tui_deps
    
    # Configurar dialog
    export DIALOGRC="/dev/null"
    export DIALOG_CANCEL=1
    export DIALOG_ESC=255
    
    # Configurar colores si el terminal los soporta
    if [ -t 1 ] && tput colors &>/dev/null; then
        export DIALOG_COLOR=1
    fi
    
    # Crear directorio de logs
    mkdir -p "$HOME/.local/share/pikaos-gaming"
}

# Limpiar TUI al salir
cleanup_tui() {
    clear
}