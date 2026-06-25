# Integración de lógica Pong en firmware

## Propósito

Este documento describe la integración de la lógica del juego Pong dentro del firmware bare-metal ejecutado por MicroBlaze V.

La integración reutiliza la arquitectura del proyecto:

```text
MicroBlaze V -> AXI-Lite -> video_vram_axi_core -> VRAM -> VGA
```

Además, usa `axi_gpio_0` para leer controles físicos acondicionados y `axi_quad_spi_0` para el modo multijugador con una FPGA esclava.

## Archivos integrados

La lógica común del juego se ubicó en:

```text
firmware/include/game/
firmware/src/game/
```

Los archivos principales son:

| Archivo | Función |
| --- | --- |
| `game_config.h` | Parámetros lógicos del juego: resolución, paletas, pelota y puntaje. |
| `game_state.h` | Estructura principal `game_state_t`. |
| `player_input.h` | Estructura genérica de entrada por jugador. |
| `game_logic.c/h` | Actualización del Pong: movimiento, colisiones, puntaje y estado. |
| `game_app.c/h` | Capa de aplicación para modo local, maestro SPI y esclavo SPI. |
| `input_driver.c/h` | Decodificación de entradas y lectura desde AXI GPIO. |
| `game_packet.c/h` | Construcción y validación de paquetes de entrada/estado. |
| `spi_game.c/h` | Comunicación SPI real sobre `axi_quad_spi_0` usando `XSpi`. |
| `pong_renderer.c/h` | Renderizado del estado del juego hacia VRAM RGB444. |

## Modos implementados

El firmware puede operar en modo local o multijugador según `SW15`:

```text
SW15 = 0 -> modo solitario/local
SW15 = 1 -> modo multijugador SPI
```

En modo local:

```text
botones/switches -> system_io_wrapper -> INPUT_DRIVER[7:0] -> AXI GPIO -> input_driver -> game_app_update_local -> pong_render_state -> VRAM
```

En modo multijugador:

```text
P1 local -> INPUT_DRIVER -> firmware maestro
P2 remoto -> SPI MISO -> firmware maestro
estado oficial -> SPI MOSI -> FPGA esclava
estado oficial -> VRAM -> VGA
```

## Mapeo de entradas usado por firmware

| Bit | Función |
| ---: | --- |
| 0 | Barra izquierda arriba |
| 1 | Barra izquierda abajo |
| 2 | Start |
| 3 | Barra derecha arriba |
| 4 | Barra derecha abajo |
| 5 | Selector de modo multijugador |
| 6 | Reset de partida |
| 7 | Reservado |

## Mapeo físico en la FPGA maestra

| Control físico | Pin FPGA | Función |
| --- | --- | --- |
| `CPU_RESETN` | C12 | Reset completo del sistema |
| `BTNC` | N17 | Start |
| `BTNU` | M18 | Barra izquierda arriba |
| `BTNL` | P17 | Barra izquierda abajo |
| `BTNR` | M17 | Barra derecha arriba en modo local |
| `BTND` | P18 | Barra derecha abajo en modo local |
| `SW15` | V10 | Selector de modo: 0 solitario, 1 multijugador |
| `SW0` | J15 | Reset de partida |

`C12` es un reset completo de hardware y no se decodifica como un input del juego. `SW0` se usa como reset lógico de partida y se convierte en un pulso cuando pasa de 0 a 1.

## Direcciones usadas

La VRAM se mantiene en la dirección generada por Vivado para `video_vram_axi_core_0`. Si `xparameters.h` no define la base, se usa el valor de respaldo existente:

```text
VRAM_BASE_ADDR = 0x00020000
```

El AXI GPIO de entrada se lee desde:

```text
INPUT_DRIVER_BASE_ADDR = 0x40000000
```

El código también acepta `XPAR_INPUT_DRIVER_BASEADDR` o `XPAR_AXI_GPIO_0_BASEADDR` cuando estén disponibles desde `xparameters.h`.

El SPI se maneja mediante el periférico AXI Quad SPI generado por Vivado. En el firmware se inicializa con `XSpi_Initialize`, se configura como maestro y se ejecutan transferencias full-duplex de 24 bytes para intercambiar estado e input remoto.

## Estado pendiente

La integración actual ya valida Pong local, renderizado VGA, controles físicos con debounce y modo multijugador SPI con dos FPGA.

Quedan pendientes o sujetos a integración posterior:

- uso efectivo de DDR2 desde firmware para datos del juego o recursos gráficos;
- microSD;
- temporizador real de 60 Hz;
- renderizado avanzado de texto o sprites;
- integración permanente del top de la FPGA esclava dentro de un repositorio/versionado formal, si se desea conservar ese diseño junto al maestro.
