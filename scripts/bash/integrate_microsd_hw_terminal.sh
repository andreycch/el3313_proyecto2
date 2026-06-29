#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/el3313_proyecto2"
TS="$(date +%Y%m%d_%H%M%S)"

cd "$ROOT"

echo "==> Backup de Tcl BD real"
cp scripts/tcl/create_system_bd.tcl \
   scripts/tcl/create_system_bd.tcl.bak-before-microsd-hw-$TS

echo "==> Activando Tcl de referencia con microSD"
cp scripts/tcl/reference/create_system_bd_microsd_reference.tcl \
   scripts/tcl/create_system_bd.tcl

echo "==> Verificando axi_quad_spi_1 en Tcl"
grep -n "spi_sd_rtl_0\|axi_quad_spi_1\|44B00000\|M05_AXI" scripts/tcl/create_system_bd.tcl | head -40

TOP="src/rtl/top/system_io_wrapper.v"

echo "==> Backup de system_io_wrapper.v"
cp "$TOP" "$TOP.bak-before-microsd-hw-$TS"

echo "==> Parcheando system_io_wrapper.v para exponer SD_SCK/SD_CMD/SD_DAT0/SD_DAT3"
python3 <<'PY'
from pathlib import Path
import re

p = Path("src/rtl/top/system_io_wrapper.v")
s = p.read_text()

# 1) Agregar puertos top-level de microSD si no existen
module_header_end = s.find(");\n")
if module_header_end == -1:
    raise SystemExit("ERROR: no encontré el cierre del puerto del módulo system_io_wrapper")

header = s[:module_header_end]
if "SD_SCK" not in header:
    s = s[:module_header_end] + """,
    inout wire SD_SCK,
    inout wire SD_CMD,
    inout wire SD_DAT0,
    inout wire SD_DAT3,
    output wire SD_RESET,
    input wire SD_CD""" + s[module_header_end:]

# 2) Mantener SD habilitada. SD_CD queda como entrada disponible.
if "assign SD_RESET" not in s:
    s = s.replace("endmodule", "assign SD_RESET = 1'b1;\n\nendmodule", 1)

# 3) Conectar los puertos nuevos al system_wrapper generado por el BD
if ".spi_sd_rtl_0_io0_io(" not in s:
    m = re.search(r'\bsystem_wrapper\s+\w+\s*\(', s)
    if not m:
        raise SystemExit("ERROR: no encontré la instancia de system_wrapper")

    open_idx = s.find("(", m.start())
    level = 0
    close_idx = None

    for i in range(open_idx, len(s)):
        if s[i] == "(":
            level += 1
        elif s[i] == ")":
            level -= 1
            if level == 0:
                close_idx = i
                break

    if close_idx is None:
        raise SystemExit("ERROR: no encontré el cierre de la instancia system_wrapper")

    insert = """
        ,
        .spi_sd_rtl_0_io0_io(SD_CMD),
        .spi_sd_rtl_0_io1_io(SD_DAT0),
        .spi_sd_rtl_0_sck_io(SD_SCK),
        .spi_sd_rtl_0_ss_io(SD_DAT3)"""

    s = s[:close_idx] + insert + s[close_idx:]

p.write_text(s)
PY

echo "==> Creando constraints para microSD integrada Nexys A7"
mkdir -p constraints

cat > constraints/microsd_nexys_a7.xdc <<'XDC'
## MicroSD integrada Nexys A7 en modo SPI
## SD_SCK  -> SPI SCK
## SD_CMD  -> SPI MOSI
## SD_DAT0 -> SPI MISO
## SD_DAT3 -> SPI CS

set_property -dict { PACKAGE_PIN B1 IOSTANDARD LVCMOS33 } [get_ports { SD_SCK }]
set_property -dict { PACKAGE_PIN C1 IOSTANDARD LVCMOS33 } [get_ports { SD_CMD }]
set_property -dict { PACKAGE_PIN C2 IOSTANDARD LVCMOS33 } [get_ports { SD_DAT0 }]
set_property -dict { PACKAGE_PIN D2 IOSTANDARD LVCMOS33 } [get_ports { SD_DAT3 }]

set_property -dict { PACKAGE_PIN E2 IOSTANDARD LVCMOS33 } [get_ports { SD_RESET }]
set_property -dict { PACKAGE_PIN A1 IOSTANDARD LVCMOS33 } [get_ports { SD_CD }]

set_property PULLUP true [get_ports { SD_CMD }]
set_property PULLUP true [get_ports { SD_DAT3 }]
XDC

echo "==> Agregando XDC al proyecto Vivado"
cat > /tmp/add_microsd_xdc.tcl <<'TCL'
set proj_path [file normalize "Projects/el3313_proyecto2/el3313_proyecto2.xpr"]
set xdc_path  [file normalize "constraints/microsd_nexys_a7.xdc"]

open_project $proj_path

if {[llength [get_files -quiet $xdc_path]] == 0} {
    add_files -fileset constrs_1 $xdc_path
}

set_property used_in_synthesis true [get_files $xdc_path]
set_property used_in_implementation true [get_files $xdc_path]

save_project
close_project
TCL

/tools/Xilinx/vitisproyecto/Vivado/2024.1/bin/vivado \
  -mode batch \
  -source /tmp/add_microsd_xdc.tcl \
  -journal add_microsd_xdc.jou \
  -log add_microsd_xdc.log

echo "==> Cambios aplicados. Ahora toca build de Vivado."
