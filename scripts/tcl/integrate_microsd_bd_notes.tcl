# Notas para integrar microSD en el Block Design maestro.
# Este archivo NO modifica el BD automáticamente porque el diseño actual ya contiene cambios
# delicados de VGA, VRAM doble buffer, GPIO de controles y SPI FPGA-FPGA.
#
# Ver referencia completa en:
#   scripts/tcl/reference/create_system_bd_microsd_reference.tcl
#
# Cambios requeridos en Vivado:
#   1) MicroBlaze V: habilitar C_I_AXI = 1 para exponer M_AXI_IP.
#   2) Interconnect AXI: NUM_SI = 2 y NUM_MI = 6.
#   3) Conectar microblaze_riscv_0/M_AXI_IP -> microblaze_riscv_0_axi_periph/S01_AXI.
#   4) Agregar axi_quad_spi_1 para microSD.
#   5) Conectar axi_quad_spi_1/AXI_LITE -> microblaze_riscv_0_axi_periph/M05_AXI.
#   6) Mapear axi_quad_spi_1 en Data space: 0x44B00000, rango 0x00010000.
#   7) Mapear DDR2 en Instruction space: 0x80000000, rango 0x08000000.
#   8) Exportar SPI_0 de axi_quad_spi_1 como puerto externo y asignar pines en XDC.
