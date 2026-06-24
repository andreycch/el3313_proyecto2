# Integración inicial de DDR2, SPI y UARTLite en el Block Design

## Propósito

Este documento registra la adaptación inicial del avance compartido por el otro grupo dentro del `create_system_bd.tcl` del proyecto maestro.

El objetivo de este paso es ampliar el Block Design actual, conservando la arquitectura ya existente de MicroBlaze V, VRAM, VGA y `INPUT_DRIVER[7:0]`, y agregando periféricos requeridos para las siguientes etapas del proyecto.

## Bloques agregados

| Bloque | IP | Función |
| --- | --- | --- |
| `mig_7series_0` | `xilinx.com:ip:mig_7series:4.2` | Controlador de memoria DDR2 externo de la Nexys A7. |
| `rst_mig_7series_0_100M` | `xilinx.com:ip:proc_sys_reset:5.0` | Reset sincronizado para el dominio de reloj de usuario del MIG. |
| `axi_quad_spi_0` | `xilinx.com:ip:axi_quad_spi:3.2` | Periférico SPI conectado al bus AXI del MicroBlaze. |
| `axi_uartlite_0` | `xilinx.com:ip:axi_uartlite:2.0` | UARTLite a 115200 baudios para depuración por firmware. |

## Bloques conservados

No se reemplazó el diseño anterior. Se conservaron los bloques que ya estaban funcionando:

| Bloque | Función |
| --- | --- |
| `microblaze_riscv_0` | Procesador principal MicroBlaze V RISC-V. |
| `microblaze_riscv_0_local_memory` | Memoria local BRAM para instrucciones y datos. |
| `video_vram_axi_core_0` | Núcleo AXI-Lite + VRAM + VGA. |
| `axi_gpio_0` | Entrada digital `INPUT_DRIVER[7:0]`. |
| `mdm_1` | Depuración del MicroBlaze. |
| `clk_wiz_1` | Reloj interno del sistema. |
| `rst_clk_wiz_1_100M` | Reset principal sincronizado. |

## Interconexión AXI

El `axi_interconnect` pasó de dos salidas maestras a cinco:

| Interfaz AXI | Periférico conectado | Dirección base | Rango |
| --- | --- | ---: | ---: |
| `M00_AXI` | `video_vram_axi_core_0` | `0x00020000` | `0x00020000` |
| `M01_AXI` | `axi_gpio_0` | `0x40000000` | `0x00010000` |
| `M02_AXI` | `mig_7series_0` | `0x80000000` | `0x08000000` |
| `M03_AXI` | `axi_quad_spi_0` | `0x44A00000` | `0x00010000` |
| `M04_AXI` | `axi_uartlite_0` | `0x40600000` | `0x00010000` |

Se mantuvo la base de VRAM en `0x00020000` y la base del GPIO de entrada en `0x40000000`, para no romper el firmware integrado en el paso anterior.

## Corrección aplicada al avance recibido

El `create_system_bd.tcl` recibido por el otro grupo usaba el dispositivo:

```text
xc7a100tcsg324-3
```

En esta integración se conservó el dispositivo usado por el repositorio maestro y la guía del proyecto:

```text
xc7a100tcsg324-1
```

También se corrigió el campo interno del archivo PRJ generado para MIG:

```text
<TargetFPGA>xc7a100t-csg324/-1</TargetFPGA>
```

## Estado actual

Este avance solo integra los periféricos en el script TCL del Block Design. Todavía queda pendiente:

- regenerar el proyecto en Vivado;
- validar el Block Design;
- generar wrapper, bitstream y nuevo `.xsa`;
- las constraints físicas de `spi_rtl_0` fueron fijadas en Pmod JA con orden estándar SPI;
- las constraints físicas de `UART_0` fueron fijadas en el puente USB-UART integrado;
- actualizar la plataforma Vitis con el nuevo `.xsa`;
- reemplazar el stub de `spi_game.c` por un driver real sobre `axi_quad_spi_0`.

## Relación con el modo multijugador

La integración del AXI Quad SPI prepara el hardware para el modo multijugador. La idea de integración sigue siendo:

```text
Maestro local lee P1 desde INPUT_DRIVER
Maestro recibe P2 remoto por SPI
MicroBlaze calcula el estado oficial del juego
MicroBlaze renderiza en VRAM local
MicroBlaze envía estado oficial al esclavo por SPI
```

Este avance no implementa todavía esa comunicación en firmware; solamente deja el periférico SPI en el mapa de memoria del procesador y define el conector físico maestro en Pmod JA. El detalle del pinout queda documentado en `docs/interfaces/spi_maestro_pmod_ja.md`.
