#!/usr/bin/env bash
# Test rápido para pkg_manager.sh
# No realiza instalaciones; muestra el gestor detectado y los mapeos seleccionados.
set -euo pipefail

# Buscar y cargar config si existe
for p in "./00_config.sh" "$(dirname "${BASH_SOURCE[0]}")/00_config.sh" "$(dirname "${BASH_SOURCE[0]}")/../00_config.sh"; do
    if [ -f "$p" ]; then source "$p"; break; fi
done

# Cargar wrapper
source "$(dirname "${BASH_SOURCE[0]}")/pkg_manager.sh"

echo "== PKG MANAGER INFO =="
pkg_manager_info || true

echo "\n== MAPEO DE PAQUETES (simulación) =="
for pkg in steam heroic lutris wine-ge proton-ge; do
    printf "%s -> %s\n" "$pkg" "$(map_pkg_name "$pkg")"
done

echo "\n== CHEQUEO DISPONIBILIDAD (puede tardar y consultar repos) =="
for name in steam heroic lutris; do
    if pkg_available "$(map_pkg_name "$name")"; then
        echo "$name: disponible"
    else
        echo "$name: no disponible o no consultable desde este host"
    fi
done

echo "\nTest concluido. Para probar instalaciones reales use 'pkg_install <paquete>' (en su distro)."