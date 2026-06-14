#include <stdint.h>
#include "xparameters.h"
#include "vram_memory_map.h"

static void draw_rect(uint32_t x0, uint32_t y0, uint32_t w, uint32_t h, uint16_t color)
{
    uint32_t x;
    uint32_t y;

    for (y = y0; y < (y0 + h); y++) {
        for (x = x0; x < (x0 + w); x++) {
            vram_write_pixel(x, y, color);
        }
    }
}

static void draw_center_line(void)
{
    uint32_t y;

    for (y = 0u; y < VRAM_LOGICAL_HEIGHT; y++) {
        if ((y & 0x04u) == 0u) {
            vram_write_pixel(79u, y, VRAM_COLOR_GRAY);
            vram_write_pixel(80u, y, VRAM_COLOR_GRAY);
        }
    }
}

static void draw_border(void)
{
    uint32_t x;
    uint32_t y;

    for (x = 0u; x < VRAM_LOGICAL_WIDTH; x++) {
        vram_write_pixel(x, 0u, VRAM_COLOR_GRAY);
        vram_write_pixel(x, VRAM_LOGICAL_HEIGHT - 1u, VRAM_COLOR_GRAY);
    }

    for (y = 0u; y < VRAM_LOGICAL_HEIGHT; y++) {
        vram_write_pixel(0u, y, VRAM_COLOR_GRAY);
        vram_write_pixel(VRAM_LOGICAL_WIDTH - 1u, y, VRAM_COLOR_GRAY);
    }
}

static void draw_color_test_pixels(void)
{
    draw_rect(5u, 5u, 6u, 6u, VRAM_COLOR_RED);
    draw_rect(13u, 5u, 6u, 6u, VRAM_COLOR_GREEN);
    draw_rect(21u, 5u, 6u, 6u, VRAM_COLOR_BLUE);
}

static void draw_pong_scene(void)
{
    vram_clear(VRAM_COLOR_BLACK);

    draw_border();
    draw_center_line();

    draw_rect(10u, 50u, 3u, 20u, VRAM_COLOR_WHITE);
    draw_rect(147u, 50u, 3u, 20u, VRAM_COLOR_WHITE);
    draw_rect(78u, 58u, 4u, 4u, VRAM_COLOR_WHITE);

    draw_color_test_pixels();
}

int main(void)
{
    draw_pong_scene();

    while (1) {
        /*
         * Firmware bare-metal:
         * MicroBlaze V escribe pixeles en VRAM por AXI-Lite.
         * El controlador VGA lee la VRAM continuamente.
         */
    }

    return 0;
}