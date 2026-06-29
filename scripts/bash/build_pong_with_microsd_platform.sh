#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/el3313_proyecto2"
APP="$ROOT/workspace/pong_app"
PLAT="$ROOT/workspace/el3313_platform_microsd"
OLD_PLAT="$ROOT/workspace/el3313_platform"
VITIS="/tools/Xilinx/vitisproyecto/Vitis/2024.1"
TOOL="$VITIS/gnu/riscv/lin/riscv64-unknown-elf/bin"

source "$VITIS/settings64.sh"

XP="$(find "$PLAT" -path "*/include/xparameters.h" -print -quit)"
if [ -z "$XP" ]; then
    echo "ERROR: no encontré xparameters.h en $PLAT"
    exit 1
fi

INC="$(dirname "$XP")"

LIBXIL="$(find "$PLAT" -name libxil.a -print -quit)"
if [ -z "$LIBXIL" ]; then
    echo "ERROR: no encontré libxil.a en la plataforma microSD"
    echo "Buscando:"
    find "$PLAT" -name "*.a" -print
    exit 1
fi

LIB="$(dirname "$LIBXIL")"

SPEC="$(find "$PLAT" -name Xilinx.spec -print -quit 2>/dev/null || true)"

if [ -z "$SPEC" ]; then
    SPEC="$(find "$OLD_PLAT" -name Xilinx.spec -print -quit 2>/dev/null || true)"
fi

if [ -z "$SPEC" ]; then
    SPEC="$(find "$VITIS" -name Xilinx.spec -print -quit 2>/dev/null || true)"
fi

if [ -z "$SPEC" ]; then
    SPEC="$(find "$HOME/.local/share/Trash" -name Xilinx.spec -print -quit 2>/dev/null || true)"
fi

if [ -z "$SPEC" ]; then
    echo "ERROR: no encontré Xilinx.spec"
    echo "Revisá con:"
    echo "  find workspace /tools/Xilinx/vitisproyecto ~/.local/share/Trash -name Xilinx.spec -type f 2>/dev/null"
    exit 1
fi

echo "==> xparameters: $XP"
echo "==> include:     $INC"
echo "==> lib:         $LIB"
echo "==> spec:        $SPEC"

echo
echo "==> Verificando SPI1 real"
grep -n "XPAR_XSPI_NUM_INSTANCES\|AXI_QUAD_SPI_1\|44B00000" "$XP"

echo
echo "==> Corrigiendo CMakeLists con include nuevo"
cd "$APP/src"

cp CMakeLists.txt "CMakeLists.txt.bak-before-microsd-platform-$(date +%Y%m%d_%H%M%S)"

python3 <<PY
from pathlib import Path
p = Path("CMakeLists.txt")
s = p.read_text()

old_paths = [
"/home/leandro/el3313_proyecto2/workspace/el3313_platform/export/el3313_platform/sw/standalone_microblaze_riscv_0/include",
"/home/leandro/el3313_proyecto2/workspace/el3313_platform_microsd/export/el3313_platform_microsd/sw/el3313_platform_microsd/standalone_domain/bspinclude/include",
]

new_inc = "$INC"

for old in old_paths:
    s = s.replace(old, new_inc)

p.write_text(s)
PY

echo
echo "==> Copiando firmware actualizado al workspace"
cd "$ROOT"

cp firmware/src/main.c workspace/pong_app/src/main.c
cp firmware/src/game/*.c workspace/pong_app/src/game/
cp firmware/src/fatfs/*.c workspace/pong_app/src/fatfs/

cp firmware/include/*.h workspace/pong_app/src/ 2>/dev/null || true
cp firmware/include/game/*.h workspace/pong_app/src/game/
cp firmware/include/fatfs/*.h workspace/pong_app/src/fatfs/
cp firmware/lscript.ld workspace/pong_app/src/lscript.ld

echo
echo "==> Build limpio"
cd "$APP"

if [ -d build ]; then
    mv build "build_old_$(date +%Y%m%d_%H%M%S)"
fi

mkdir build
cd build

cmake ../src \
  -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
  -DCMAKE_MODULE_PATH="$PLAT;$VITIS/data/embeddedsw/cmake" \
  -DCMAKE_C_COMPILER="$TOOL/riscv64-unknown-elf-gcc" \
  -DCMAKE_CXX_COMPILER="$TOOL/riscv64-unknown-elf-g++" \
  -DCMAKE_ASM_COMPILER="$TOOL/riscv64-unknown-elf-gcc" \
  -DCMAKE_LIBRARY_PATH="$LIB" \
  -DCMAKE_C_FLAGS="-O0 -g3 -march=rv32i -mabi=ilp32 -DSDT -specs=$SPEC -I$INC -Wall -Wextra -U__clang__" \
  -DCMAKE_CXX_FLAGS="-O0 -g3 -march=rv32i -mabi=ilp32 -DSDT -specs=$SPEC -I$INC -Wall -Wextra -U__clang__" \
  -DCMAKE_ASM_FLAGS="-march=rv32i -mabi=ilp32 -specs=$SPEC" \
  -DCMAKE_EXE_LINKER_FLAGS="-march=rv32i -mabi=ilp32 -specs=$SPEC -Wl,--no-relax -Wl,--gc-sections"

make VERBOSE=1 -j4

echo
echo "==> ELF generado:"
ls -lh pong_app.elf

echo
echo "==> Confirmando BSP usado con SPI1:"
grep -n "XPAR_XSPI_NUM_INSTANCES\|AXI_QUAD_SPI_1\|44B00000" "$XP"
