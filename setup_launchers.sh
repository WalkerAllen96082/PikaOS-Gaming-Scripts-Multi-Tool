#!/bin/bash
source "$(dirname "$0")/../00_config.sh"
# Cargar wrapper de gestor de paquetes (pkg_install, pkg_remove, ...)
source "$(dirname "$0")/pkg_manager.sh"

LAUNCHER_CONFIG_LOG="$LOG_DIR/launcher_config.log"
touch "$LAUNCHER_CONFIG_LOG"

# Función para configurar Proton-GE
setup_proton_ge() {
    local proton_dir="$HOME/.steam/root/compatibilitytools.d"
    
    # Crear directorio si no existe
    mkdir -p "$proton_dir"
    
    # Obtener última versión de Proton-GE
    local download_url=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest | grep "browser_download_url.*tar.gz" | cut -d '"' -f 4)
    
    if [ -n "$download_url" ]; then
        log_message "INFO" "Descargando Proton-GE..." "$LAUNCHER_CONFIG_LOG"
        wget -q -P /tmp "$download_url"
        tar xf /tmp/GE-Proton*.tar.gz -C "$proton_dir"
        rm /tmp/GE-Proton*.tar.gz
        log_message "SUCCESS" "Proton-GE instalado correctamente" "$LAUNCHER_CONFIG_LOG"
    fi
}

# Función para listar versiones de Proton-GE instaladas
list_proton_versions() {
    local proton_dir="$HOME/.steam/root/compatibilitytools.d"
    declare -a versions=()
    
    if [ -d "$proton_dir" ]; then
        echo "Versiones de Proton-GE instaladas:"
        local i=1
        while IFS= read -r version; do
            versions+=("$version")
            echo "$i. $version"
            ((i++))
        done < <(ls -1 "$proton_dir" | grep "GE-Proton" | sort -V -r)
    else
        echo "No se encontraron versiones de Proton-GE instaladas"
    fi
    
    echo "$i. Descargar última versión"
    return 0
}

# Función para listar versiones de Wine-GE instaladas
list_wine_versions() {
    local wine_dir="$HOME/.local/share/wine-ge-custom"
    declare -a versions=()
    
    if [ -d "$wine_dir" ]; then
        echo "Versiones de Wine-GE instaladas:"
        local i=1
        while IFS= read -r version; do
            versions+=("$version")
            echo "$i. $version"
            ((i++))
        done < <(ls -1 "$wine_dir" | grep "wine-" | sort -V -r)
    else
        echo "No se encontraron versiones de Wine-GE instaladas"
    fi
    
    echo "$i. Descargar última versión"
    return 0
}

# Función para detectar launchers instalados
detect_launchers() {
    declare -A launchers
    
    # Detectar Steam
    if command -v steam &> /dev/null; then
        launchers["steam"]="Instalado"
    else
        launchers["steam"]="No instalado"
    fi
    
    # Detectar Heroic
    if command -v heroic &> /dev/null; then
        launchers["heroic"]="Instalado"
    else
        launchers["heroic"]="No instalado"
    fi
    
    # Detectar Lutris
    if command -v lutris &> /dev/null; then
        launchers["lutris"]="Instalado"
    else
        launchers["lutris"]="No instalado"
    fi
    
    echo "Launchers detectados:"
    for launcher in "${!launchers[@]}"; do
        echo "- ${launcher^}: ${launchers[$launcher]}"
    done
    
    return 0
}

# Función para instalar launcher
install_launcher() {
    local launcher=$1
    case $launcher in
        steam)
            pkg_install steam
            ;;
        heroic)
            # 'heroic' se mapea en pkg_manager según la distro (ej. heroic-games-launcher-bin en Arch/AUR)
            pkg_install heroic
            ;;
        lutris)
            pkg_install lutris
            ;;
        *)
            echo "Launcher no soportado: $launcher"
            return 1
            ;;
    esac
}

# Función para configurar Wine-GE
setup_wine_ge() {
    local wine_dir="$HOME/.local/share/wine-ge-custom"
    
    mkdir -p "$wine_dir"
    
    # Obtener última versión de Wine-GE
    local download_url=$(curl -s https://api.github.com/repos/GloriousEggroll/wine-ge-custom/releases/latest | grep "browser_download_url.*tar.xz" | cut -d '"' -f 4)
    
    if [ -n "$download_url" ]; then
        log_message "INFO" "Descargando Wine-GE..." "$LAUNCHER_CONFIG_LOG"
        wget -q -P /tmp "$download_url"
        tar xf /tmp/wine-*.tar.xz -C "$wine_dir"
        rm /tmp/wine-*.tar.xz
        log_message "SUCCESS" "Wine-GE instalado correctamente" "$LAUNCHER_CONFIG_LOG"
    fi
}

# Función para configurar Heroic
setup_heroic() {
    local heroic_config="$HOME/.config/heroic/config.json"
    mkdir -p "$(dirname "$heroic_config")"
    
    # Configuración básica de Heroic
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
}

# Procesar argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        --proton-only)
            setup_proton_ge
            exit 0
            ;;
        --wine-only)
            setup_wine_ge
            exit 0
            ;;
        --heroic-only)
            setup_heroic
            exit 0
            ;;
        --help)
            echo "Uso: $0 [OPCIÓN]"
            echo "Opciones:"
            echo "  --proton-only     Instalar solo Proton-GE"
            echo "  --wine-only       Instalar solo Wine-GE"
            echo "  --heroic-only     Configurar solo Heroic"
            echo "  --help            Mostrar esta ayuda"
            exit 0
            ;;
        *)
            if [ "$1" != "" ]; then
                echo "Opción desconocida: $1"
                echo "Use --help para ver las opciones disponibles"
                exit 1
            fi
            ;;
    esac
    shift
done

echo "=== Configuración de Launchers ==="
echo "Este script configurará los launchers con las mejores opciones para gaming"

# Detectar launchers instalados
detect_launchers

# Menú principal
while true; do
    echo -e "\nOpciones disponibles:"
    echo "1. Instalar/Configurar componentes"
    echo "2. Configurar un juego"
    echo "3. Salir"
    read -p "Seleccione una opción (1-3): " main_option

    case $main_option in
        1)
            echo -e "\nComponentes disponibles:"
            echo "1. Proton-GE (Recomendado para Steam)"
            echo "2. Wine-GE (Recomendado para Heroic/Lutris)"
            echo "3. Heroic Games Launcher"
            echo "4. Volver al menú principal"
            read -p "Seleccione un componente (1-4): " component_option

            case $component_option in
                1)
                    setup_proton_ge
                    ;;
                2)
                    setup_wine_ge
                    ;;
                3)
                    if ! command -v heroic &> /dev/null; then
                        read -p "Heroic no está instalado. ¿Desea instalarlo? [s/N]: " install_heroic
                        if [[ $install_heroic =~ ^[Ss]$ ]]; then
                            install_launcher "heroic"
                        fi
                    fi
                    setup_heroic
                    ;;
                4)
                    continue
                    ;;
            esac
            ;;
        2)
            echo -e "\nLaunchers disponibles:"
            declare -a available_launchers=()
            
            # Verificar Steam
            if command -v steam &> /dev/null; then
                available_launchers+=("steam")
                echo "${#available_launchers[@]}. Steam"
            fi
            
            # Verificar Heroic
            if command -v heroic &> /dev/null; then
                available_launchers+=("heroic")
                echo "${#available_launchers[@]}. Heroic Games Launcher"
            fi
            
            # Verificar Lutris
            if command -v lutris &> /dev/null; then
                available_launchers+=("lutris")
                echo "${#available_launchers[@]}. Lutris"
            fi
            
            if [ ${#available_launchers[@]} -eq 0 ]; then
                echo "No hay launchers instalados. Instale al menos uno primero."
                read -p "¿Desea instalar algún launcher ahora? [s/N]: " install_now
                if [[ $install_now =~ ^[Ss]$ ]]; then
                    echo "Launchers disponibles para instalar:"
                    echo "1. Steam"
                    echo "2. Heroic Games Launcher"
                    echo "3. Lutris"
                    read -p "Seleccione un launcher para instalar (1-3): " launcher_choice
                    case $launcher_choice in
                        1) install_launcher "steam" ;;
                        2) install_launcher "heroic" ;;
                        3) install_launcher "lutris" ;;
                        *) echo "Opción inválida" ;;
                    esac
                fi
                continue
            fi
            
            echo "$((${#available_launchers[@]}+1)). Volver al menú principal"
            
            read -p "Seleccione un launcher (1-$((${#available_launchers[@]}+1))): " launcher_choice
            
            if [ "$launcher_choice" -le "${#available_launchers[@]}" ]; then
                selected_launcher="${available_launchers[$((launcher_choice-1))]}"
                case $selected_launcher in
                    steam)
                        echo -e "\nConfiguración de Steam:"
                        echo "1. Agregar juego no Steam"
                        echo "2. Abrir Steam"
                        echo "3. Volver"
                        read -p "Seleccione una opción (1-3): " steam_option
                        
                        case $steam_option in
                            1)
                                echo -e "\nSeleccione la versión de Proton-GE a usar:"
                                list_proton_versions
                                read -p "Seleccione una opción: " proton_choice
                                
                                if [ "$proton_choice" -eq "$i" ]; then
                                    setup_proton_ge
                                    echo "Nueva versión de Proton-GE instalada"
                                    list_proton_versions
                                    read -p "Seleccione una versión para usar: " proton_choice
                                fi
                                
                                # Continuar con Steam
                                steam
                                ;;
                            2)
                                steam
                                ;;
                            3)
                                continue
                                ;;
                        esac
                        ;;
                    heroic)
                        echo -e "\nConfiguración de Heroic:"
                        echo "1. Agregar juego"
                        echo "2. Abrir Heroic"
                        echo "3. Volver"
                        read -p "Seleccione una opción (1-3): " heroic_option
                        
                        case $heroic_option in
                            1)
                                echo -e "\nSeleccione el tipo de compatibilidad:"
                                echo "1. Wine-GE (Recomendado para la mayoría de juegos)"
                                echo "2. Proton-GE (Alternativa para juegos específicos)"
                                read -p "Seleccione una opción (1-2): " compat_choice
                                
                                case $compat_choice in
                                    1)
                                        echo -e "\nSeleccione la versión de Wine-GE a usar:"
                                        list_wine_versions
                                        read -p "Seleccione una opción: " wine_choice
                                        
                                        if [ "$wine_choice" -eq "$i" ]; then
                                            setup_wine_ge
                                            echo "Nueva versión de Wine-GE instalada"
                                            list_wine_versions
                                            read -p "Seleccione una versión para usar: " wine_choice
                                        fi
                                        ;;
                                    2)
                                        echo -e "\nSeleccione la versión de Proton-GE a usar:"
                                        list_proton_versions
                                        read -p "Seleccione una opción: " proton_choice
                                        
                                        if [ "$proton_choice" -eq "$i" ]; then
                                            setup_proton_ge
                                            echo "Nueva versión de Proton-GE instalada"
                                            list_proton_versions
                                            read -p "Seleccione una versión para usar: " proton_choice
                                        fi
                                        ;;
                                    *)
                                        echo "Opción inválida"
                                        continue
                                        ;;
                                esac
                                
                                # Continuar con Heroic
                                heroic
                                ;;
                            2)
                                heroic
                                ;;
                            3)
                                continue
                                ;;
                        esac
                        ;;
                    lutris)
                        echo -e "\nAbriendo Lutris..."
                        lutris
                        ;;
                esac
            fi
            ;;
        3)
            echo "¡Configuración completada!"
            exit 0
            ;;
        *)
            echo "Opción inválida"
            ;;
    esac
done

# 4. Configurar Lutris (si está instalado)
if command -v lutris &> /dev/null; then
    read -p "¿Deseas configurar Lutris? [s/N]: " config_lutris
    if [[ $config_lutris =~ ^[Ss]$ ]]; then
        lutris --configure
    fi
fi

echo "Configuración completada. Los launchers están listos para usar."