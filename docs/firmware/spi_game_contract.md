# Contrato SPI Maestro-Esclavo para Pong

## 1. Objetivo

Este documento define el protocolo SPI entre la FPGA maestro y la FPGA esclavo.

La FPGA maestro contiene el MicroBlaze y ejecuta la lógica oficial del Pong.
La FPGA esclavo lee los controles remotos del jugador 2 y recibe el estado oficial del juego.

## 2. Roles

### FPGA maestro

- Genera el reloj SPI.
- Controla la señal CS/SS.
- Ejecuta la lógica oficial del juego.
- Envía el estado oficial por MOSI.
- Recibe los controles del jugador 2 por MISO.

### FPGA esclavo

- Espera el reloj y CS del maestro.
- Lee sus controles locales.
- Devuelve el input del jugador 2 por MISO.
- Recibe el estado oficial del juego por MOSI.

## 3. Configuración SPI

| Parámetro | Valor |
|---|---|
| Modo SPI | Mode 0 |
| CPOL | 0 |
| CPHA | 0 |
| Bits por palabra | 8 |
| Orden de bits | MSB first |
| CS/SS | Activo en bajo |
| Tamaño de transacción | 24 bytes |

## 4. Conexión física

| Maestro | Esclavo | Función |
|---|---|---|
| JA1 | CS/SS | Selección del esclavo |
| JA2 | MOSI/SDI | Estado del maestro hacia esclavo |
| JA3 | MISO/SDO | Input del esclavo hacia maestro |
| JA4 | SCLK | Reloj SPI |
| GND | GND | Tierra común |

No se debe conectar 3.3 V entre placas si ambas FPGA están alimentadas por USB.

## 5. Transacción principal

En cada frame, el maestro ejecuta una transferencia SPI fija de 24 bytes.

Durante esa misma transferencia:

- MOSI envía el estado oficial del juego.
- MISO devuelve los controles actuales del jugador 2.

Esto aprovecha que SPI es full-duplex.

## 6. Paquete MISO: input del esclavo

El esclavo debe colocar este paquete en los primeros 7 bytes de MISO.

| Byte | Campo | Descripción |
|---:|---|---|
| 0 | packet_type | Siempre 0x01 |
| 1 | frame_id | Identificador de frame |
| 2 | up | 1 si P2 sube |
| 3 | down | 1 si P2 baja |
| 4 | start | 1 si P2 inicia |
| 5 | reset | 1 si P2 reinicia |
| 6 | checksum | XOR de bytes 0 a 5 |

Checksum:

```text
checksum = byte0 ^ byte1 ^ byte2 ^ byte3 ^ byte4 ^ byte5
```


## 7. Paquete MOSI: estado oficial del maestro

El maestro envía 24 bytes por MOSI.

| Byte | Campo               |
| ---: | ------------------- |
|    0 | packet_type = 0x02  |
|    1 | frame_id LSB        |
|    2 | frame_id MSB        |
|    3 | ball_x LSB          |
|    4 | ball_x MSB          |
|    5 | ball_y LSB          |
|    6 | ball_y MSB          |
|    7 | paddle_p1_y LSB     |
|    8 | paddle_p1_y MSB     |
|    9 | paddle_p2_y LSB     |
|   10 | paddle_p2_y MSB     |
|   11 | score_p1            |
|   12 | score_p2            |
|   13 | status              |
|   14 | winner              |
|   15 | last_point          |
|   16 | elapsed_seconds LSB |
|   17 | elapsed_seconds MSB |
|   18 | serve_direction     |
|   19 | flags               |
|   20 | reserved            |
|   21 | reserved            |
|   22 | reserved            |
|   23 | checksum            |

Checksum:

```text
checksum = XOR de byte 0 hasta byte 22
```

## 8. Estados del juego

| Valor | Estado       |
| ----: | ------------ |
|     0 | GAME_WAITING |
|     1 | GAME_RUNNING |
|     2 | GAME_PAUSED  |
|     3 | GAME_OVER    |

## 9. Reglas para el esclavo

Antes de cada transacción, el esclavo debe tener listo su paquete de input.

Cuando CS baja:

1. El esclavo empieza a recibir bytes por MOSI.
2. El esclavo transmite su paquete de input por MISO.
3. Al terminar la transferencia, valida el paquete recibido.
4. Si el paquete del maestro es válido, actualiza su estado local.

## 10. Regla principal

El maestro siempre manda el estado oficial.

El esclavo nunca decide la física del juego; solo reporta controles.
