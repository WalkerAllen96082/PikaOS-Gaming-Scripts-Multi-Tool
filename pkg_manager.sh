#!/usr/bin/env bash
# Wrapper simple de gestores de paquete
# Proporciona funciones: pkg_install, pkg_remove, pkg_update, pkg_available
# Detecta y prefiere: pikman -> apt (Debian-based) ; en Arch: yay -> paru -> pacman
# Nota: pikman (PikaOS) según su wiki no requiere ejecutar con sudo — maneja internamente la elevación
# cuando es necesaria y solicita autenticación. Por eso en este wrapper NO anteponemos sudo a pikman.
# Para otros gestores (apt, pacman, yay, paru, dnf) mantenemos sudo cuando sea apropiado.

set -euo pipefail

# Directorio del script (usado para llamar a utilidades del repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

# Mapa de nombres de paquetes (genérico -> nombre por distro)
# Añadir/ajustar según sea necesario. El script intentará usar el nombre genérico si no hay mapeo.
declare -A PKG_MAP_DEBIAN=(
    [steam]=steam
    [lutris]=lutris
    [heroic]=heroic
    [wine]=wine
    ["wine-staging"]=wine-staging
)

# Para mayor robustez intentamos varias alternativas comunes por paquete
declare -A PKG_CANDIDATES_DEBIAN=(
    [steam]="steam"
    [lutris]="lutris"
    # PikaOS podría empaquetar 'heroic' de varias maneras; probamos varias opciones
    [heroic]="heroic heroic-games-launcher heroic-games-launcher-bin"
    [wine]="wine"
    [wine-staging]="wine-staging"
)

declare -A PKG_MAP_ARCH=(
    [steam]=steam
    [lutris]=lutris
    # En Arch/AUR muchas veces se usa heroic-games-launcher-bin o heroic
    [heroic]=heroic-games-launcher-bin
    [wine]=wine
    ["wine-staging"]=wine-staging
)

declare -A PKG_CANDIDATES_ARCH=(
    [steam]="steam"
    [lutris]="lutris"
    [heroic]="heroic-games-launcher-bin heroic-bin heroic"
    [wine]="wine"
    [wine-staging]="wine-staging"
)

PKG_MGR=""
PKG_TYPE="" # arch or debian or unknown

detect_pkg_manager() {
    if command -v pikman >/dev/null 2>&1; then
        PKG_MGR="pikman"
        # pikman puede usarse en PikaOS (basado en Debian) o en otras distros; preferir "debian" fallback
        if grep -qi "arch" /etc/os-release 2>/dev/null; then
            PKG_TYPE="arch"
        else
            PKG_TYPE="debian"
        fi
        return
    fi

    # Debian/Ubuntu family
    if command -v apt >/dev/null 2>&1; then
        PKG_MGR="apt"
        PKG_TYPE="debian"
        return
    fi

    # Arch family
    if command -v yay >/dev/null 2>&1; then
        PKG_MGR="yay"
        PKG_TYPE="arch"
        return
    fi
    if command -v paru >/dev/null 2>&1; then
        PKG_MGR="paru"
        PKG_TYPE="arch"
        return
    fi
    if command -v pacman >/dev/null 2>&1; then
        PKG_MGR="pacman"
        PKG_TYPE="arch"
        return
    fi

    # Fallbacks
    if command -v dnf >/dev/null 2>&1; then
        PKG_MGR="dnf"
        PKG_TYPE="rpm"
        return
    fi

    PKG_MGR=""
    PKG_TYPE="unknown"
}

# Mapear nombre de paquete genérico al nombre por distro
map_pkg_name() {
    local generic="$1"
    detect_pkg_manager
    local candidates
    if [ "$PKG_TYPE" = "arch" ]; then
        candidates="${PKG_CANDIDATES_ARCH[$generic]:-${PKG_MAP_ARCH[$generic]:-$generic}}"
    else
        candidates="${PKG_CANDIDATES_DEBIAN[$generic]:-${PKG_MAP_DEBIAN[$generic]:-$generic}}"
    fi

    # Probar cada candidato y devolver el primero disponible
    IFS=' ' read -ra cand_arr <<< "$candidates"
    for c in "${cand_arr[@]}"; do
        if pkg_available "$c"; then
            echo "$c"
            return 0
        fi
    done

    # Si ninguno está disponible, devolver el nombre mapeado o el genérico
    if [ "$PKG_TYPE" = "arch" ]; then
        echo "${PKG_MAP_ARCH[$generic]:-$generic}"
    else
        echo "${PKG_MAP_DEBIAN[$generic]:-$generic}"
    fi
}

pkg_update() {
    detect_pkg_manager
    case "$PKG_MGR" in
        pikman)
            # pikman gestiona privilegios por sí mismo
            pikman -Syu --noconfirm || pikman -Syu
            ;;
        apt)
            sudo apt update && sudo apt -y upgrade
            ;;
        yay)
            yay -Syu --noconfirm || yay -Syu
            ;;
        paru)
            paru -Syu --noconfirm || paru -Syu
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            ;;
        dnf)
            sudo dnf upgrade --refresh -y
            ;;
        *)
            echo "[pkg_manager] No se detectó gestor de paquetes. PKG_MGR=")
            return 1
            ;;
    esac
}

pkg_install() {
    detect_pkg_manager
    local pkg_generic="$1"
    local pkg="$(map_pkg_name "$pkg_generic")"

    case "$PKG_MGR" in
        pikman)
            # pikman acepta -S o install según implementación; intentamos ambas
            if pikman -h 2>&1 | grep -qi "-S"; then
                pikman -S --noconfirm "$pkg" || pikman -S "$pkg"
            else
                pikman install --noconfirm "$pkg" || pikman install "$pkg"
            fi
            ;;
        apt)
            sudo apt update
            sudo apt install -y "$pkg"
            ;;
        yay)
            yay -S --noconfirm --needed "$pkg" || yay -S --needed "$pkg"
            ;;
        paru)
            paru -S --noconfirm --needed "$pkg" || paru -S --needed "$pkg"
            ;;
        pacman)
            sudo pacman -S --noconfirm --needed "$pkg"
            ;;
        dnf)
            sudo dnf install -y "$pkg"
            ;;
        *)
            echo "[pkg_install] No se detectó gestor de paquetes. Intenta instalar manualmente: $pkg"
            return 1
            ;;
    esac

    # Después del intento de instalación, verificar si ahora está disponible
    if pkg_available "$pkg"; then
        return 0
    fi

    # Fallbacks especiales: si no existe paquete empaquetado, para wine-ge o proton-ge
    # intentamos instalar desde las releases/compilar usando los helpers del repo
    if [ "$pkg_generic" = "wine-ge" ] || [ "$pkg_generic" = "wine_ge" ]; then
        echo "[pkg_install] Paquete 'wine-ge' no disponible vía paquete; intentando instalación desde fuente/releases..."
        if [ -x "$SCRIPT_DIR/setup_launchers.sh" ]; then
            "$SCRIPT_DIR/setup_launchers.sh" --wine-only || true
            # Comprobar nuevamente
            if pkg_available "$pkg" || [ -d "$HOME/.local/share/wine-ge-custom" ]; then
                echo "[pkg_install] wine-ge instalado desde releases"
                return 0
            fi
        fi
    fi

    if [ "$pkg_generic" = "proton-ge" ] || [ "$pkg_generic" = "proton_ge" ]; then
        echo "[pkg_install] Paquete 'proton-ge' no disponible vía paquete; intentando instalación desde releases..."
        if [ -x "$SCRIPT_DIR/setup_launchers.sh" ]; then
            "$SCRIPT_DIR/setup_launchers.sh" --proton-only || true
            # Comprobar si Proton-GE fue instalado en compatibilitytools.d
            if [ -d "$HOME/.steam/root/compatibilitytools.d" ]; then
                echo "[pkg_install] proton-ge instalado desde releases"
                return 0
            fi
        fi
    fi

    echo "[pkg_install] Falló la instalación de: $pkg (intentados: $PKG_MGR y fallbacks)"
    return 1
}

pkg_remove() {
    detect_pkg_manager
    local pkg_generic="$1"
    local pkg="$(map_pkg_name "$pkg_generic")"

    case "$PKG_MGR" in
        pikman)
            pikman -R --noconfirm "$pkg" || pikman -R "$pkg"
            ;;
        apt)
            sudo apt remove -y "$pkg"
            ;;
        yay|paru)
            $PKG_MGR -R --noconfirm "$pkg" || $PKG_MGR -R "$pkg"
            ;;
        pacman)
            sudo pacman -R --noconfirm "$pkg"
            ;;
        dnf)
            sudo dnf remove -y "$pkg"
            ;;
        *)
            echo "[pkg_remove] No se detectó gestor de paquetes. Intenta eliminar manualmente: $pkg"
            return 1
            ;;
    esac
}

pkg_available() {
    detect_pkg_manager
    local pkg_generic="$1"
    local pkg="$(map_pkg_name "$pkg_generic")"

    case "$PKG_MGR" in
        pikman)
            pikman search "$pkg" >/dev/null 2>&1 && return 0 || return 1
            ;;
        apt)
            apt-cache policy "$pkg" | grep -q "Candidate:" && return 0 || return 1
            *)
                echo "[pkg_manager] No se detectó gestor de paquetes. PKG_MGR=$PKG_MGR PKG_TYPE=$PKG_TYPE"
                return 1
                ;;
        pacman)
            pacman -Ss "^$pkg( |$)" >/dev/null 2>&1 && return 0 || return 1
            ;;
        dnf)
            dnf info "$pkg" >/dev/null 2>&1 && return 0 || return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# Exponer versión simple
pkg_manager_info() {
    detect_pkg_manager
    echo "PKG_MGR=$PKG_MGR PKG_TYPE=$PKG_TYPE"
}

# Si este script se ejecuta directamente, mostrar ayuda rápida
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "Uso: source this_file.sh o ejecutar las funciones pkg_install/pk_update/etc"
    pkg_manager_info
fi
