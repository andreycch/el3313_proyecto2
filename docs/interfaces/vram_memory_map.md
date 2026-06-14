# Mapa de memoria de VRAM

## Propósito

Este documento define el contrato inicial de direccionamiento para la memoria de video del proyecto.

La VRAM funciona como intermediario entre el procesador MicroBlaze V y el controlador VGA. El procesador escribe datos de color en la memoria, y el sistema VGA lee esos datos continuamente para generar la imagen en pantalla.

## Resolución lógica

La salida VGA trabaja con resolución visible de 640x480 pixeles. Para reducir el uso de BRAM, la VRAM usa una resolución lógica menor:

| Parámetro | Valor |
|---|---:|
| Ancho lógico | 160 pixeles |
| Alto lógico | 120 pixeles |
| Pixeles totales | 19 200 |
| Escala VGA | 4x4 |
| Formato de color | RGB444 |
| Bits útiles por pixel | 12 bits |

Cada pixel lógico de VRAM representa un bloque de 4x4 pixeles en la salida VGA.

## Formato de color RGB444

Cada pixel usa 12 bits:

| Bits | Campo |
|---|---|
| [11:8] | Rojo |
| [7:4] | Verde |
| [3:0] | Azul |

Ejemplos:

| Color | Valor RGB444 |
|---|---|
| Negro | 0x000 |
| Rojo | 0xF00 |
| Verde | 0x0F0 |
| Azul | 0x00F |
| Gris | 0x555 |
| Blanco | 0xFFF |

## Dirección interna de hardware

La VRAM usa una dirección lineal:

```text
addr = y * 160 + x
```
Donde:

```text
x = 0..159
y = 0..119
addr = 0..19199
```

Ejemplos:

|   x |   y | Dirección |
| --: | --: | --------: |
|   0 |   0 |         0 |
|   1 |   0 |         1 |
|   0 |   1 |       160 |
|  80 |  60 |      9680 |
| 159 | 119 |     19199 |

## Dirección desde firmware

Para facilitar la integración con AXI, cada pixel se mapeará como una palabra de 32 bits.

Aunque el color útil usa solo 12 bits, el procesador escribirá una palabra completa:

```text
bits [11:0]  = RGB444
bits [31:12] = reservado
```

El desplazamiento en bytes desde firmware será:
```text
offset = (y * 160 + x) * 4
```

Por tanto:
```text
direccion_pixel = VRAM_BASE_ADDR + offset
```

## Base address provisional

La dirección base será definida finalmente por Vivado en el Address Editor cuando se integre el periférico AXI.

Valor provisional para firmware:
```text
VRAM_BASE_ADDR = 0x44A00000
```

Este valor debe revisarse y actualizarse cuando se cree el diseño de bloques con MicroBlaze V y AXI.

## Relación con módulos RTL

| Módulo                       | Función                                                    |
| ---------------------------- | ---------------------------------------------------------- |
| `vram_dual_port.v`           | Memoria de video de doble puerto                           |
| `vram_read_addr_gen.v`       | Convierte coordenadas VGA 640x480 a dirección VRAM 160x120 |
| `vram_test_pattern_writer.v` | Escribe una escena de prueba en VRAM                       |
| `vram_cpu_write_adapter.v`   | Convierte coordenadas CPU x,y a dirección lineal de VRAM   |
