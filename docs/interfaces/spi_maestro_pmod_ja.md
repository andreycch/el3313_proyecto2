# Interfaz SPI maestro por Pmod JA

## Propósito

Este documento fija el conector físico y el orden de señales para la comunicación SPI entre la FPGA maestro y la FPGA esclava.

La decisión permite continuar con la integración del hardware sin esperar una asignación externa de pines. La FPGA de este repositorio actúa como maestro SPI.

## Conector elegido

Se utiliza el conector **Pmod JA** de la Nexys A7.

Razones de la elección:

- JA está libre en el diseño actual.
- Permite usar los cuatro pines superiores del Pmod para las cuatro señales SPI principales.
- Sigue el orden físico usual de un Pmod SPI: `SS`, `MOSI`, `MISO`, `SCLK`.
- Deja otros conectores Pmod disponibles para pruebas futuras.

## Pinout maestro

| Señal SPI | Puerto del wrapper Vivado | Pin Pmod | Pin FPGA | Descripción |
| --- | --- | --- | --- | --- |
| `SS_N` | `spi_rtl_0_ss_io[0]` | JA1 | C17 | Selección activa en bajo hacia la FPGA esclava. |
| `MOSI` | `spi_rtl_0_io0_io` | JA2 | D18 | Datos del maestro hacia el esclavo. |
| `MISO` | `spi_rtl_0_io1_io` | JA3 | E18 | Datos del esclavo hacia el maestro. |
| `SCLK` | `spi_rtl_0_sck_io` | JA4 | G17 | Reloj SPI generado por el maestro. |

Además, ambas FPGAs deben compartir **GND común** usando un pin GND del mismo Pmod.

## Cableado entre las dos FPGA

Si la otra FPGA usa el mismo orden físico desde la perspectiva del bus SPI, el cableado recomendado es:

| Maestro | Esclavo | Nota |
| --- | --- | --- |
| JA1 / `SS_N` | `SS_N` | Selección de esclavo, activa en bajo. |
| JA2 / `MOSI` | `MOSI` | Señal maestro a esclavo. |
| JA3 / `MISO` | `MISO` | Señal esclavo a maestro. |
| JA4 / `SCLK` | `SCLK` | Reloj generado por el maestro. |
| GND | GND | Tierra común obligatoria. |

No se debe conectar alimentación de 3.3 V entre placas si ambas están alimentadas por separado; para la comunicación basta con compartir GND y señales lógicas de 3.3 V.

## Relación con AXI Quad SPI

El Block Design usa `axi_quad_spi_0`. En el wrapper generado por Vivado, la interfaz SPI externa se espera con nombres similares a:

```text
spi_rtl_0_ss_io[0]
spi_rtl_0_io0_io
spi_rtl_0_io1_io
spi_rtl_0_sck_io
```

En la nomenclatura del AXI Quad SPI:

```text
io0 = MOSI
io1 = MISO
```

Si Vivado genera nombres diferentes al crear el wrapper, se deben ajustar únicamente los nombres de los puertos en el archivo `.xdc`, manteniendo el mismo conector físico y el mismo orden de señales.

## Estado pendiente

Esta asignación solo define los pines físicos. Todavía falta implementar en firmware el uso real del periférico `axi_quad_spi_0` y acordar con el grupo esclavo el formato final de los paquetes de entrada y estado.
