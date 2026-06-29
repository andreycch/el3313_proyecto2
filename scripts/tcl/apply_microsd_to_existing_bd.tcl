set proj_path [file normalize "Projects/el3313_proyecto2/el3313_proyecto2.xpr"]
set bd_path   [file normalize "Projects/el3313_proyecto2/el3313_proyecto2.srcs/sources_1/bd/system/system.bd"]

open_project $proj_path
open_bd_design $bd_path

puts "==> Agregando puerto externo SPI microSD si no existe"
if {[llength [get_bd_intf_ports -quiet spi_sd_rtl_0]] == 0} {
    create_bd_intf_port -mode Master -vlnv xilinx.com:interface:spi_rtl:1.0 spi_sd_rtl_0
}

puts "==> Agregando axi_quad_spi_1 si no existe"
if {[llength [get_bd_cells -quiet axi_quad_spi_1]] == 0} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi:3.2 axi_quad_spi_1

    set_property -dict [list \
        CONFIG.C_FIFO_DEPTH {16} \
        CONFIG.C_NUM_SS_BITS {1} \
        CONFIG.C_SCK_RATIO {16} \
        CONFIG.C_SPI_MODE {0} \
        CONFIG.C_USE_STARTUP {0} \
        CONFIG.C_USE_STARTUP_INT {0} \
    ] [get_bd_cells axi_quad_spi_1]
}

puts "==> Aumentando AXI interconnect a 6 salidas M00..M05"
set_property CONFIG.NUM_MI 6 [get_bd_cells microblaze_riscv_0_axi_periph]

puts "==> Conectando SPI externo"
catch {
    connect_bd_intf_net \
        [get_bd_intf_ports spi_sd_rtl_0] \
        [get_bd_intf_pins axi_quad_spi_1/SPI_0]
}

puts "==> Conectando AXI M05 -> axi_quad_spi_1"
catch {
    connect_bd_intf_net \
        [get_bd_intf_pins microblaze_riscv_0_axi_periph/M05_AXI] \
        [get_bd_intf_pins axi_quad_spi_1/AXI_LITE]
}

puts "==> Conectando clocks"
catch {
    connect_bd_net \
        [get_bd_pins clk_wiz_1/clk_out1] \
        [get_bd_pins axi_quad_spi_1/s_axi_aclk]
}

catch {
    connect_bd_net \
        [get_bd_pins clk_wiz_1/clk_out1] \
        [get_bd_pins axi_quad_spi_1/ext_spi_clk]
}

catch {
    connect_bd_net \
        [get_bd_pins clk_wiz_1/clk_out1] \
        [get_bd_pins microblaze_riscv_0_axi_periph/M05_ACLK]
}

puts "==> Conectando reset"
catch {
    connect_bd_net \
        [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] \
        [get_bd_pins axi_quad_spi_1/s_axi_aresetn]
}

catch {
    connect_bd_net \
        [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] \
        [get_bd_pins microblaze_riscv_0_axi_periph/M05_ARESETN]
}

puts "==> Asignando direccion 0x44B00000"
assign_bd_address -offset 0x44B00000 -range 0x00010000 \
    -target_address_space [get_bd_addr_spaces microblaze_riscv_0/Data] \
    [get_bd_addr_segs axi_quad_spi_1/AXI_LITE/Reg] -force

puts "==> Validando BD"
validate_bd_design
save_bd_design

puts "==> Eliminando wrapper viejo del proyecto"
set old_wrappers [get_files -quiet *system_wrapper.vhd]
if {[llength $old_wrappers] > 0} {
    remove_files $old_wrappers
}

puts "==> Regenerando system_wrapper"
make_wrapper -files [get_files $bd_path] -top

set gen_wrapper_vhd [file normalize "Projects/el3313_proyecto2/el3313_proyecto2.gen/sources_1/bd/system/hdl/system_wrapper.vhd"]
set gen_wrapper_v   [file normalize "Projects/el3313_proyecto2/el3313_proyecto2.gen/sources_1/bd/system/hdl/system_wrapper.v"]

if {[file exists $gen_wrapper_vhd]} {
    add_files -norecurse $gen_wrapper_vhd
} elseif {[file exists $gen_wrapper_v]} {
    add_files -norecurse $gen_wrapper_v
} else {
    error "No se encontro system_wrapper generado"
}

puts "==> Manteniendo top superior system_io_wrapper"
set_property top system_io_wrapper [current_fileset]
update_compile_order -fileset sources_1

save_project
close_project

puts "==> MicroSD SPI1 integrada al BD y wrapper regenerado"
