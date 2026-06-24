# Arquitectura MicroBlaze V + VRAM + VGA

## Propósito

Este documento describe la arquitectura implementada para la integración entre el procesador MicroBlaze V, el bus AXI, la memoria de video VRAM, la salida VGA y la entrada digital mediante AXI GPIO.

Esta arquitectura forma parte del sistema embebido del proyecto Pong sobre FPGA Nexys A7-100T. La función principal de este bloque es permitir que el firmware ejecutado en MicroBlaze V pueda escribir información gráfica en una memoria de video, mientras un controlador VGA lee esa memoria para generar imagen en pantalla.

## Componentes principales

| Componente                        | Función                                                      |
| --------------------------------- | ------------------------------------------------------------ |
| `microblaze_riscv_0`              | Procesador MicroBlaze V basado en RISC-V                     |
| `microblaze_riscv_0_local_memory` | Memoria local BRAM para instrucciones y datos del procesador |
| `microblaze_riscv_0_axi_periph`   | Interconexión AXI entre MicroBlaze y periféricos             |
| `video_vram_axi_core_0`           | Núcleo de video con interfaz AXI, VRAM y salida VGA          |
| `axi_gpio_0`                      | Entrada digital de 8 bits para `INPUT_DRIVER[7:0]`           |
| `mig_7series_0`                   | Controlador DDR2 externo mediante MIG                        |
| `axi_quad_spi_0`                  | Periférico SPI para comunicación con la otra FPGA             |
| `axi_uartlite_0`                  | UARTLite para depuración desde firmware                       |
| `clk_wiz_1`                       | Generación de reloj interno                                  |
| `rst_clk_wiz_1_100M`              | Sistema de reset sincronizado                                |
| `mdm_1`                           | Módulo de depuración para MicroBlaze                         |

## Flujo general del sistema

El sistema funciona de la siguiente manera:

1. El procesador MicroBlaze V ejecuta firmware bare-metal.
2. El firmware escribe datos de color en la VRAM mediante el bus AXI.
3. La VRAM almacena pixeles en formato RGB444.
4. El controlador VGA lee continuamente la VRAM.
5. La salida VGA genera las señales `VGA_R`, `VGA_G`, `VGA_B`, `VGA_HS` y `VGA_VS`.
6. El bloque AXI GPIO permite leer 8 entradas digitales desde firmware usando `INPUT_DRIVER[7:0]`.

## Relación procesador - memoria - video

La VRAM funciona como una memoria compartida entre dos partes del sistema:

* El MicroBlaze escribe pixeles en la VRAM.
* El controlador VGA lee pixeles desde la VRAM.

Esto permite separar la lógica de procesamiento del juego de la lógica de generación de video. El procesador no genera directamente las señales VGA; solamente actualiza la memoria de video. El núcleo de video se encarga de convertir esa memoria en imagen visible.

## Resolución de video

La salida VGA visible es de 640x480 pixeles. Sin embargo, la VRAM utiliza una resolución lógica de 160x120 pixeles para reducir el consumo de memoria BRAM.

Cada pixel lógico representa un bloque de 4x4 pixeles físicos en pantalla.

| Parámetro              |   Valor |
| ---------------------- | ------: |
| Resolución VGA visible | 640x480 |
| Resolución lógica VRAM | 160x120 |
| Escala                 |     4x4 |
| Pixeles lógicos        |  19 200 |
| Formato de color       |  RGB444 |

## Bus AXI

El bus AXI permite que el MicroBlaze acceda a periféricos internos del diseño. En esta integración, el MicroBlaze accede principalmente a:

* `video_vram_axi_core_0`, para escribir en la memoria de video.
* `axi_gpio_0`, para leer las entradas digitales `INPUT_DRIVER[7:0]`.
* `mig_7series_0`, para acceder a memoria DDR2 externa.
* `axi_quad_spi_0`, para la comunicación SPI con la otra FPGA.
* `axi_uartlite_0`, para depuración por UART.

La dirección base de cada periférico es generada por Vivado y queda disponible para el firmware mediante `xparameters.h`.

## Entrada INPUT_DRIVER

El diseño incluye un bloque AXI GPIO configurado como entrada de 8 bits. Esta entrada está expuesta como:

```text
INPUT_DRIVER[7:0]
```

En la integración actual, estos bits se conectan a switches físicos de la Nexys A7. El firmware puede leerlos mediante el periférico AXI GPIO y usarlos como comandos de control para el juego.

## Estado de integración

La arquitectura fue probada en hardware real. Se programó la FPGA con el bitstream generado desde el diseño integrado y se cargó un firmware bare-metal en MicroBlaze V. El sistema mostró una escena tipo Pong por VGA, confirmando la integración entre procesador, bus AXI, VRAM y salida VGA.

También se integró el AXI GPIO de 8 bits para permitir entrada digital desde firmware.

En un avance posterior del Block Design se agregaron `mig_7series_0`, `axi_quad_spi_0` y `axi_uartlite_0`. Esa integración prepara el hardware para DDR2, comunicación SPI y depuración UART, pero todavía requiere validar constraints, regenerar bitstream, exportar un nuevo `.xsa` y actualizar la plataforma Vitis.
