#ifndef VRAM_MEMORY_MAP_H
#define VRAM_MEMORY_MAP_H

#include <stdint.h>

#define VRAM_LOGICAL_WIDTH      160u
#define VRAM_LOGICAL_HEIGHT     120u
#define VRAM_PIXEL_COUNT        (VRAM_LOGICAL_WIDTH * VRAM_LOGICAL_HEIGHT)

#define VRAM_PIXEL_BYTES        4u

#ifndef VRAM_BASE_ADDR
#define VRAM_BASE_ADDR          0x44A00000u
#endif

#define VRAM_RGB444(red, green, blue) \
    ((((uint16_t)(red)   & 0xFu) << 8) | \
     (((uint16_t)(green) & 0xFu) << 4) | \
     (((uint16_t)(blue)  & 0xFu) << 0))

#define VRAM_COLOR_BLACK        VRAM_RGB444(0x0, 0x0, 0x0)
#define VRAM_COLOR_RED          VRAM_RGB444(0xF, 0x0, 0x0)
#define VRAM_COLOR_GREEN        VRAM_RGB444(0x0, 0xF, 0x0)
#define VRAM_COLOR_BLUE         VRAM_RGB444(0x0, 0x0, 0xF)
#define VRAM_COLOR_GRAY         VRAM_RGB444(0x5, 0x5, 0x5)
#define VRAM_COLOR_WHITE        VRAM_RGB444(0xF, 0xF, 0xF)

#define VRAM_PIXEL_INDEX(x, y) \
    (((uint32_t)(y) * VRAM_LOGICAL_WIDTH) + (uint32_t)(x))

#define VRAM_PIXEL_OFFSET(x, y) \
    (VRAM_PIXEL_INDEX((x), (y)) * VRAM_PIXEL_BYTES)

static inline uint32_t vram_is_valid_coordinate(uint32_t x, uint32_t y)
{
    return (x < VRAM_LOGICAL_WIDTH) && (y < VRAM_LOGICAL_HEIGHT);
}

static inline void vram_write_pixel(uint32_t base_addr, uint32_t x, uint32_t y, uint16_t rgb444)
{
    if (vram_is_valid_coordinate(x, y)) {
        volatile uint32_t *pixel_addr;

        pixel_addr = (volatile uint32_t *)(base_addr + VRAM_PIXEL_OFFSET(x, y));
        *pixel_addr = ((uint32_t)rgb444) & 0x00000FFFu;
    }
}

static inline uint32_t vram_read_pixel(uint32_t base_addr, uint32_t x, uint32_t y)
{
    if (vram_is_valid_coordinate(x, y)) {
        volatile uint32_t *pixel_addr;

        pixel_addr = (volatile uint32_t *)(base_addr + VRAM_PIXEL_OFFSET(x, y));
        return (*pixel_addr) & 0x00000FFFu;
    }

    return 0u;
}

static inline void vram_clear(uint32_t base_addr, uint16_t rgb444)
{
    uint32_t x;
    uint32_t y;

    for (y = 0u; y < VRAM_LOGICAL_HEIGHT; y++) {
        for (x = 0u; x < VRAM_LOGICAL_WIDTH; x++) {
            vram_write_pixel(base_addr, x, y, rgb444);
        }
    }
}

#endif
