# Integración inicial de lógica Pong en firmware

## Propósito

Este documento describe la primera integración de la lógica del juego Pong dentro del firmware bare-metal ejecutado por MicroBlaze V.

La integración reutiliza la arquitectura ya existente del proyecto:

```text
MicroBlaze V -> AXI-Lite -> video_vram_axi_core -> VRAM -> VGA
```

El objetivo de este avance es sustituir la escena estática de prueba por una actualización básica del estado del juego y un renderizado hacia VRAM.

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
| `spi_game.c/h` | Interfaz temporal para comunicación SPI. Actualmente sigue siendo stub. |
| `pong_renderer.c/h` | Renderizado del estado del juego hacia VRAM RGB444. |

## Modo implementado en este avance

El firmware actual ejecuta el modo local:

```text
INPUT_DRIVER[7:0] -> AXI GPIO -> input_driver -> game_app_update_local -> pong_render_state -> VRAM
```

El mapeo de entradas usado por firmware es:

| Bit | Función |
| ---: | --- |
| 0 | P1 arriba |
| 1 | P1 abajo |
| 2 | P1 start |
| 3 | P1 reset |
| 4 | P2 arriba |
| 5 | P2 abajo |
| 6 | P2 start |
| 7 | P2 reset |

En el diseño actual, `INPUT_DRIVER[7:0]` está conectado a switches físicos de la Nexys A7 mediante el archivo de constraints.

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

## Estado pendiente

Este avance no integra todavía:

- SPI real mediante AXI Quad SPI.
- DDR2 como memoria principal del firmware o datos.
- microSD.
- Temporizador real de 60 Hz.
- Renderizado avanzado de texto o sprites.

El SPI incluido en `spi_game.c` conserva el comportamiento de stub y solo define la interfaz que luego deberá conectarse con el periférico real de Vitis.
