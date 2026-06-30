# Proyecto Pong FPGA Maestro - Nexys A7-100T

## Descripción del proyecto

Este repositorio contiene la integración correspondiente a la FPGA maestra del proyecto. El sistema implementa un juego Pong embebido sobre una FPGA Nexys A7-100T con salida VGA, procesador MicroBlaze V/RISC-V, memoria de video, comunicación AXI, soporte para DDR2, periféricos de entrada, lectura de recursos desde microSD y comunicación SPI en modo maestro para la operación multijugador.

La FPGA maestra ejecuta la lógica principal del juego. En modo local, el jugador controla el sistema directamente desde los botones de la placa. En modo multijugador, la FPGA maestra mantiene el estado principal del Pong y recibe por SPI las entradas del segundo jugador provenientes de una FPGA externa configurada como esclava.

La salida gráfica se genera a partir de una memoria de video lógica de 160x120 píxeles. Esta imagen se escala por hardware a una salida VGA de 640x480 mediante un escalado 4x4. El firmware actualiza el estado del juego, escribe en la memoria de video y utiliza doble buffer para reducir parpadeos y rastros visuales.

## Alcance del repositorio

Este repositorio corresponde únicamente a la parte de la FPGA maestra. Por lo tanto, los elementos principales incluidos y documentados son:

```text
- Sistema maestro sobre Nexys A7-100T.
- Procesador MicroBlaze V/RISC-V.
- Salida VGA 640x480.
- Memoria de video lógica 160x120.
- Doble buffer de video.
- Interconexión AXI.
- Soporte DDR2 mediante MIG.
- Comunicación SPI configurada como maestro.
- Lectura de archivos desde microSD.
- Firmware principal del juego Pong en C.
```

La FPGA esclava no forma parte del alcance de este repositorio. La comunicación con esa placa se considera una interfaz externa mediante SPI.

## Estado validado en hardware

La versión estable de la FPGA maestra fue validada físicamente en hardware. Se comprobó el funcionamiento de:

```text
- Carga del bitstream maestro en Nexys A7-100T.
- Carga del firmware maestro en el procesador embebido.
- Salida VGA funcional.
- Modo local funcional.
- Modo multijugador funcional desde el lado maestro.
- Lectura de controles locales del jugador 1.
- Recepción por SPI de las entradas del jugador 2.
- Actualización correcta del estado del juego desde la FPGA maestra.
```

## Artefactos funcionales de la FPGA maestra

Para la demostración se deben usar los artefactos validados en hardware correspondientes a la FPGA maestra:

```text
artifacts/working_spi_20260627/system_io_wrapper.bit
artifacts/working_spi_20260627/pong_app.elf
```

Los archivos de recursos para la microSD son:

```text
artifacts/working_spi_20260627/config.bin
artifacts/working_spi_20260627/sprites.bin
```

Estos archivos representan el punto funcional comprobado para la FPGA maestra.

## Arquitectura general del sistema maestro

La FPGA maestra integra los siguientes bloques principales:

```text
Entradas locales ─┐
                  ├──> Firmware Pong ───> VRAM / doble buffer ───> VGA 640x480
SPI maestro    ───┘          │
                             ├──> Lectura de recursos desde microSD
                             └──> Actualización de estado del juego
```

El procesador embebido ejecuta el firmware principal. Este firmware lee las entradas locales, recibe entradas remotas mediante SPI, actualiza la lógica del Pong y escribe los cambios en la memoria de video. El hardware VGA lee la memoria de video y genera la salida visual.

## Comunicación SPI maestro

En modo multijugador, la FPGA maestra utiliza SPI para comunicarse con una FPGA externa. Desde el punto de vista de este repositorio, la placa maestra es responsable de:

```text
- Iniciar la transferencia SPI.
- Enviar el estado principal del juego.
- Recibir las entradas remotas del jugador 2.
- Validar la trama recibida.
- Aplicar las entradas remotas al estado del juego.
```

Las señales físicas usadas para la interfaz SPI son:

```text
SCK  maestro  -> señal de reloj SPI
MOSI maestro  -> datos enviados por la FPGA maestra
MISO maestro  -> datos recibidos por la FPGA maestra
SS   maestro  -> selección del dispositivo externo
GND           -> referencia común entre placas
```

No se debe conectar 3.3V entre placas si ambas FPGA están alimentadas por USB.

## Controles de la FPGA maestra

Para probar la FPGA maestra:

```text
SW15 arriba  -> modo multijugador
BTNC         -> iniciar partida
BTNU / BTNL  -> movimiento del jugador 1
```

En modo local, la FPGA maestra puede ejecutar el Pong sin depender de la comunicación SPI. En modo multijugador, la FPGA maestra utiliza sus controles locales para el jugador 1 y recibe las entradas del jugador 2 por SPI.

## Reporte de latencia

La salida VGA trabaja sobre una resolución de 640x480 a aproximadamente 60 Hz. Por lo tanto, el tiempo aproximado de un cuadro completo es:

```text
T_frame = 1 / 60 Hz = 16.67 ms
```

La imagen interna del juego se maneja en una resolución lógica de 160x120 píxeles. Cada píxel lógico se escala a un bloque de 4x4 píxeles físicos para llenar la salida VGA de 640x480.

La latencia visual principal está determinada por el ciclo de refrescamiento VGA y por el momento en que el firmware termina de escribir el nuevo estado en la memoria de video. En condiciones normales, un cambio realizado por el firmware puede verse reflejado en pantalla dentro del siguiente cuadro VGA.

Por esta razón, la latencia visual estimada del sistema es aproximadamente de 0 a 1 cuadro VGA:

```text
Latencia visual estimada ≈ 0 ms a 16.67 ms
```

En modo multijugador existe una latencia adicional asociada al intercambio SPI. Esta latencia depende de la frecuencia SPI, del tamaño de la trama transmitida y del momento del ciclo de juego en que se actualicen los datos. Para una medición exacta sería necesario instrumentar el sistema con una señal GPIO de depuración y medirla con osciloscopio o analizador lógico.

## Reporte de recursos

Los recursos utilizados fueron obtenidos desde el reporte de utilización generado por Vivado para el bitstream final del sistema maestro.

| Recurso         |   Uso | Disponible | Utilización |
| --------------- | ----: | ---------: | ----------: |
| Slice LUTs      | 20463 |      63400 |     32.28 % |
| LUT as Logic    | 10187 |      63400 |     16.07 % |
| LUT as Memory   | 10276 |      19000 |     54.08 % |
| Slice Registers |  8669 |     126800 |      6.84 % |
| Block RAM Tile  |    32 |        135 |     23.70 % |
| RAMB36/FIFO     |    32 |        135 |     23.70 % |
| RAMB18          |     0 |        270 |      0.00 % |
| DSPs            |     0 |        240 |      0.00 % |

El diseño utiliza LUTs, registros y BRAM para implementar el procesador embebido, la interconexión AXI, la memoria de video, el controlador VGA, los periféricos SPI, GPIO, UARTLite y la integración con DDR2 mediante MIG. No se utilizan bloques DSP en esta implementación.

La estimación de potencia reportada por Vivado fue:

| Parámetro                       |   Valor |
| ------------------------------- | ------: |
| Potencia total en chip          | 1.184 W |
| Potencia dinámica               | 1.074 W |
| Potencia estática               | 0.110 W |
| Temperatura de juntura estimada | 30.4 °C |

El reporte de timing de Vivado indica que las restricciones temporales no se cumplen completamente:

```text
Timing constraints are not met.
```

A pesar de esta advertencia, el sistema maestro fue validado funcionalmente en hardware con salida VGA, ejecución del firmware y comunicación SPI desde el lado maestro.

## Instrucciones de carga para la FPGA maestra

Para la demostración se recomienda usar directamente los artefactos funcionales validados en hardware.

Conectar únicamente la FPGA maestra al equipo y ejecutar:

```bash
cd ~/el3313_proyecto2

cat > /tmp/load_master_working_spi.tcl <<'TCL'
connect

puts "=== Seleccionando FPGA maestra ==="
targets -set -filter {name =~ "xc7a100t"}

puts "=== Cargando bitstream maestro ==="
fpga -file /home/leandro/el3313_proyecto2/artifacts/working_spi_20260627/system_io_wrapper.bit

after 2000

puts "=== Seleccionando procesador maestro ==="
targets -set -filter {name =~ "Hart #0*"}

rst -processor

puts "=== Cargando ELF maestro ==="
dow /home/leandro/el3313_proyecto2/artifacts/working_spi_20260627/pong_app.elf

con

puts "=== MAESTRO CARGADO OK ==="
exit
TCL

XSDB=/tools/Xilinx/vitisproyecto/Vitis/2024.1/bin/xsdb
[ -x "$XSDB" ] || XSDB=/tools/Xilinx/vitisproyecto/Vivado/2024.1/bin/xsdb

$XSDB /tmp/load_master_working_spi.tcl
```

Si la FPGA se apaga, se deben volver a cargar tanto el bitstream como el ELF.

## Archivos para microSD

Los archivos que deben copiarse a la raíz de la microSD son:

```text
config.bin
sprites.bin
```

La versión validada de estos archivos se encuentra en:

```text
artifacts/working_spi_20260627/config.bin
artifacts/working_spi_20260627/sprites.bin
```

## Nota de reproducibilidad

El repositorio conserva los archivos fuente, scripts y reportes del desarrollo de la FPGA maestra. Sin embargo, para la entrega y demostración final se deben usar los artefactos funcionales de la FPGA maestra ubicados en:

```text
artifacts/working_spi_20260627/
```

Los archivos principales para la FPGA maestra son:

```text
system_io_wrapper.bit
pong_app.elf
config.bin
sprites.bin
```

Estos archivos representan el punto probado y estable de la FPGA maestra.

## Enlace a la conversacion con ChatGPT
```text
https://chatgpt.com/share/6a42c87b-8cfc-83e8-a823-677156f10351
```

## Enlace al repositorio maestro
```text
https://github.com/andreycch/el3313_proyecto2.git
```
## Enlace al repositorio maestro
```text
https://github.com/nicolecr71/Proyecto-Final
```
