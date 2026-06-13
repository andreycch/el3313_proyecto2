# EL3313 Proyecto 2

Sistema embebido sobre FPGA Nexys A7 para el Proyecto 2 del curso EL3313.

## Alcance de este repositorio

Este repositorio contiene la parte del grupo maestro:

- MicroBlaze V con arquitectura RISC-V.
- Firmware bare-metal en C.
- Subsistema de video VGA.
- VRAM como mediador entre procesador y controlador VGA.
- Estructura para integración posterior con DDR2, microSD, SPI y juego Pong.

## Herramientas

- Ubuntu 22.04.5 LTS
- Vivado 2024.1
- Vitis / Vitis HLS 2024.1
- HoG
- Git / GitHub
- VSCode
- TerosHDL

## Estructura

- `src/rtl/`: módulos Verilog sintetizables.
- `sim/tb/`: bancos de prueba.
- `constraints/`: archivos XDC.
- `Top/el3313_proyecto2/`: configuración HoG.
- `scripts/`: automatización Bash/Tcl.
- `firmware/`: código C bare-metal.
- `docs/`: diagramas, decisiones de diseño e interfaces.

## Flujo HoG

```bash
./Hog/Do LIST
./Hog/Do CREATE el3313_proyecto2
```

## Convención de Commits

Formato:

```bash
tipo(alcance): descripción
```
