# Integración microSD/FatFS en FPGA maestro

Este patch agrega un overlay seguro con la implementación de microSD entregada por el grupo compañero.
No reemplaza automáticamente el diseño maestro al aplicar el patch; primero deja los archivos en:

```text
integrations/microsd_master_overlay/
```

Para copiar los archivos al proyecto real:

```bash
cd ~/el3313_proyecto2
bash scripts/bash/apply_microsd_overlay.sh
```

El script respalda cada archivo existente con extensión `.bak-<timestamp>` antes de sobrescribirlo.

## Flujo esperado de arranque

1. El bitstream crea MicroBlaze V, DDR2/MIG, VRAM/VGA, GPIO, SPI FPGA-FPGA y un segundo SPI para microSD.
2. El `.elf` arranca en BRAM.
3. Se valida DDR2 con `ddr2_self_test()`.
4. Se escriben `config` y sprites de respaldo en DDR2.
5. Se monta la microSD FAT32 con FatFS.
6. Se cargan `/sprites.bin` y `/config.bin` desde la raíz de la microSD.
7. `game_params_load_from_ddr2()` actualiza `max_score`, velocidades y `paddle_speed`.
8. El renderer dibuja bola y paletas leyendo pixeles RGB444 desde DDR2.

## Direcciones usadas

```text
DDR2_CONFIG_ADDR       = 0x80002000
DDR2_GAME_STATE_ADDR   = 0x80003000
DDR2_SPRITE_BANK_ADDR  = 0x80010000
DDR2_FRAMEBUFFER_SHADOW= 0x80100000
```

## Archivos en la microSD

La microSD debe estar en FAT32 y contener en la raíz:

```text
/config.bin
/sprites.bin
```

Se pueden generar con:

```bash
python3 tools/make_sprites.py
python3 tools/make_config.py --max-score 7 --ball-speed-x 2 --paddle-speed 3
```

## Advertencias de hardware

El archivo `sd_card.c` usa `axi_quad_spi_1`, por lo que el maestro necesita un segundo AXI Quad SPI para la microSD. No se debe reutilizar el SPI FPGA-FPGA (`axi_quad_spi_0`) para evitar conflictos con el enlace maestro-esclava.

El overlay incluye como referencia:

```text
scripts/tcl/reference/create_system_bd_microsd_reference.tcl
```

Ese archivo muestra el diseño con `axi_quad_spi_1`, puerto externo `spi_sd_rtl_0`, dirección `0x44B00000` y puerto de instrucciones `M_AXI_IP` hacia DDR2.
