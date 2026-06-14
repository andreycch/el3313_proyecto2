#include <stdint.h>

#define VRAM_BASE_ADDR          0x44A00000u

#define VRAM_LOGICAL_WIDTH      160u
#define VRAM_LOGICAL_HEIGHT     120u
#define VRAM_PIXEL_BYTES        4u

#define VRAM_RGB444(red, green, blue) \
    ((((uint16_t)(red)   & 0xFu) << 8) | \
     (((uint16_t)(green) & 0xFu) << 4) | \
     (((uint16_t)(blue)  & 0xFu) << 0))

#define VRAM_COLOR_BLACK        VRAM_RGB444(0x0, 0x0, 0x0)
#define VRAM_COLOR_GRAY         VRAM_RGB444(0x5, 0x5, 0x5)
#define VRAM_COLOR_WHITE        VRAM_RGB444(0xF, 0xF, 0xF)

static inline uint32_t vram_pixel_offset(uint32_t x, uint32_t y)
{
    return ((y * VRAM_LOGICAL_WIDTH) + x) * VRAM_PIXEL_BYTES;
}

static inline void vram_write_pixel(uint32_t x, uint32_t y, uint16_t color)
{
    uintptr_t pixel_addr;

    if ((x < VRAM_LOGICAL_WIDTH) && (y < VRAM_LOGICAL_HEIGHT)) {
        pixel_addr = (uintptr_t)VRAM_BASE_ADDR + (uintptr_t)vram_pixel_offset(x, y);
        *((volatile uint32_t *)pixel_addr) = ((uint32_t)color) & 0x00000FFFu;
    }
}

static void vram_clear(uint16_t color)
{
    uint32_t x;
    uint32_t y;

    for (y = 0u; y < VRAM_LOGICAL_HEIGHT; y++) {
        for (x = 0u; x < VRAM_LOGICAL_WIDTH; x++) {
            vram_write_pixel(x, y, color);
        }
    }
}

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

static void draw_pong_scene(void)
{
    vram_clear(VRAM_COLOR_BLACK);

    draw_center_line();

    draw_rect(10u, 50u, 3u, 20u, VRAM_COLOR_WHITE);
    draw_rect(147u, 50u, 3u, 20u, VRAM_COLOR_WHITE);
    draw_rect(78u, 58u, 4u, 4u, VRAM_COLOR_WHITE);
}

int main(void)
{
    draw_pong_scene();

    while (1) {
        /* MicroBlaze V escribe en VRAM y VGA lee continuamente. */
    }

    return 0;
}