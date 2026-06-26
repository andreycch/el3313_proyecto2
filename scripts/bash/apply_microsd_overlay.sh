#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
OVERLAY="$ROOT/integrations/microsd_master_overlay"
STAMP="$(date +%Y%m%d_%H%M%S)"

if [[ ! -d "$OVERLAY" ]]; then
  echo "ERROR: no existe $OVERLAY" >&2
  exit 1
fi

backup_and_copy() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -f "$dst" ]]; then
    cp -p "$dst" "$dst.bak-$STAMP"
  fi
  cp -p "$src" "$dst"
  echo "OK: ${dst#$ROOT/}"
}

copy_tree_files() {
  local src_dir="$1"
  local dst_dir="$2"
  if [[ ! -d "$src_dir" ]]; then
    return 0
  fi
  while IFS= read -r -d '' src; do
    local rel="${src#$src_dir/}"
    backup_and_copy "$src" "$dst_dir/$rel"
  done < <(find "$src_dir" -type f -print0)
}

echo "== Aplicando overlay microSD al proyecto maestro =="
echo "Root: $ROOT"
echo "Backups: *.bak-$STAMP"

# Firmware versionable
copy_tree_files "$OVERLAY/firmware/src/game"     "$ROOT/firmware/src/game"
copy_tree_files "$OVERLAY/firmware/include/game" "$ROOT/firmware/include/game"
copy_tree_files "$OVERLAY/firmware/src/fatfs"    "$ROOT/firmware/src/fatfs"
copy_tree_files "$OVERLAY/firmware/include/fatfs" "$ROOT/firmware/include/fatfs"
backup_and_copy "$OVERLAY/firmware/src/main.c" "$ROOT/firmware/src/main.c"
backup_and_copy "$OVERLAY/firmware/lscript.ld" "$ROOT/firmware/lscript.ld"

# Herramientas y binarios de ejemplo para la microSD
copy_tree_files "$OVERLAY/tools" "$ROOT/tools"
copy_tree_files "$OVERLAY/sdcard_root" "$ROOT/tools/sdcard_root"

# Workspace Vitis, si existe. Esto evita olvidar copiar los cambios antes de make.
if [[ -d "$ROOT/workspace/pong_app/src" ]]; then
  echo "== Sincronizando también workspace/pong_app/src =="
  mkdir -p "$ROOT/workspace/pong_app/src/game" "$ROOT/workspace/pong_app/src/fatfs"
  copy_tree_files "$OVERLAY/firmware/src/game"     "$ROOT/workspace/pong_app/src/game"
  copy_tree_files "$OVERLAY/firmware/include/game" "$ROOT/workspace/pong_app/src/game"
  copy_tree_files "$OVERLAY/firmware/src/fatfs"    "$ROOT/workspace/pong_app/src/fatfs"
  copy_tree_files "$OVERLAY/firmware/include/fatfs" "$ROOT/workspace/pong_app/src/fatfs"
  backup_and_copy "$OVERLAY/firmware/src/main.c" "$ROOT/workspace/pong_app/src/main.c"
  backup_and_copy "$OVERLAY/firmware/lscript.ld" "$ROOT/workspace/pong_app/src/lscript.ld"
else
  echo "AVISO: no existe workspace/pong_app/src; solo se actualizó firmware/."
fi

# Referencia de BD: no se reemplaza create_system_bd.tcl automáticamente para no romper el diseño actual.
mkdir -p "$ROOT/scripts/tcl/reference"
backup_and_copy "$OVERLAY/scripts/tcl/create_system_bd_microsd_reference.tcl" \
  "$ROOT/scripts/tcl/reference/create_system_bd_microsd_reference.tcl"

echo
echo "Listo. Ahora revisá:"
echo "  git diff --stat"
echo "  git diff -- firmware/src/main.c firmware/src/game/game_logic.c firmware/src/game/pong_renderer.c"
echo
echo "IMPORTANTE: el driver SD usa axi_quad_spi_1. Antes de probar microSD en hardware, el BD debe tener un segundo AXI Quad SPI mapeado en 0x44B00000 y conectado a los pines de la microSD."
