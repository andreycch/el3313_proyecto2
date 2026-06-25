# Prueba de integración SPI con dos FPGA

## Objetivo

Validar la comunicación SPI real entre dos FPGA Nexys A7-100T para el proyecto Pong maestro-esclavo.

## Configuración probada

- FPGA maestro: ejecuta el juego Pong, genera VGA y controla el estado oficial del juego.
- FPGA esclava: recibe el estado del juego por MOSI y devuelve los controles del jugador 2 por MISO.
- Protocolo: SPI Mode 0, 8 bits, MSB first, CS activo en bajo.
- Tamaño de trama: 24 bytes.

## Conexión física

| Maestro | Esclavo | Señal |
|---|---|---|
| JA1 | JA1 | CS / SS |
| JA2 | JA2 | MOSI |
| JA3 | JA3 | MISO |
| JA4 | JA4 | SCLK |
| GND | GND | Tierra común |

No se conectó 3.3 V entre placas, ya que ambas estaban alimentadas por USB.

## Resultado

La prueba fue exitosa. La FPGA maestro ejecutó el Pong en VGA y la FPGA esclava controló la paleta del jugador 2 mediante sus switches locales.

Mapeo usado en la FPGA esclava:

| Switch esclavo | Función |
|---|---|
| SW0 | P2 arriba |
| SW1 | P2 abajo |
| SW2 | P2 start |
| SW3 | P2 reset |

Indicadores:

| LED esclavo | Función |
|---|---|
| LED0 | Trama SPI válida recibida |
| LED1 | Estado de SW0 |
| LED2 | Estado de SW1 |
| LED3 | Estado de SW2 |
| LED4 | Estado de SW3 |

## Conclusión

Se validó la comunicación bidireccional SPI entre dos FPGA reales. El maestro envió el estado oficial del juego y recibió correctamente los controles del jugador 2 desde la FPGA esclava.
