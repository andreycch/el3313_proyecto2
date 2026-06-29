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
