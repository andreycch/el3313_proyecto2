# Integración microSD/FatFS para maestro Pong

Esta carpeta es un overlay seguro: `git apply` solo agrega archivos aquí y no sobrescribe
el código funcional del maestro. Para aplicar los cambios reales al árbol del proyecto,
ejecutar:

```bash
cd ~/el3313_proyecto2
bash scripts/bash/apply_microsd_overlay.sh
```

El script crea respaldos `.bak-<timestamp>` antes de reemplazar archivos existentes.

## Qué integra

- FatFS de solo lectura para FAT32.
- Driver SPI para microSD sobre `axi_quad_spi_1`.
- Loader `sd_loader_*` que carga archivos desde la raíz de la SD a DDR2.
- `game_params` para reemplazar parámetros hardcodeados en tiempo de ejecución.
- Renderer que lee sprites desde DDR2.
- Linker script que deja el arranque en BRAM y mueve el `.text` de aplicación a DDR2.
- Scripts para generar `sprites.bin` y `config.bin`.

## Archivos esperados en la microSD

Copiar a la raíz de una microSD FAT32:

```text
/config.bin
/sprites.bin
```

Los binarios de ejemplo están en `integrations/microsd_master_overlay/sdcard_root/`.
