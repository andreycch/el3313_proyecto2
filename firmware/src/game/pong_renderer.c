#include <stdint.h>

#include "game/pong_renderer.h"
#include "game/game_config.h"
#include "vram_memory_map.h"

#define PONG_COLOR_BACKGROUND  VRAM_COLOR_BLACK
#define PONG_COLOR_FOREGROUND  VRAM_COLOR_WHITE
#define PONG_COLOR_DIM         VRAM_COLOR_GRAY
#define PONG_COLOR_P1          VRAM_RGB444(0x0, 0xF, 0xF)
#define PONG_COLOR_P2          VRAM_RGB444(0xF, 0xA, 0x0)
#define PONG_COLOR_BALL        VRAM_COLOR_WHITE

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

static void draw_border(void)
{
    uint32_t x;
    uint32_t y;

    for (x = 0U; x < GAME_WIDTH; x++) {
        vram_write_pixel(x, 0U, PONG_COLOR_DIM);
        vram_write_pixel(x, GAME_HEIGHT - 1U, PONG_COLOR_DIM);
    }

    for (y = 0U; y < GAME_HEIGHT; y++) {
        vram_write_pixel(0U, y, PONG_COLOR_DIM);
        vram_write_pixel(GAME_WIDTH - 1U, y, PONG_COLOR_DIM);
    }
}

static void draw_center_line(void)
{
    uint32_t y;

    for (y = 0U; y < GAME_HEIGHT; y++) {
        if ((y & 0x04U) == 0U) {
            vram_write_pixel((GAME_WIDTH / 2U) - 1U, y, PONG_COLOR_DIM);
            vram_write_pixel((GAME_WIDTH / 2U), y, PONG_COLOR_DIM);
        }
    }
}

static void draw_score_bar(uint8_t score, uint32_t x0, uint16_t color)
{
    uint8_t i;

    for (i = 0U; i < score; i++) {
        draw_rect(x0 + ((uint32_t)i * 5U), 4U, 3U, 5U, color);
    }
}

void pong_render_state(const game_state_t *state)
{
    vram_clear(PONG_COLOR_BACKGROUND);

    draw_border();
    draw_center_line();

    draw_score_bar(state->score_p1, 58U, PONG_COLOR_P1);
    draw_score_bar(state->score_p2, 92U, PONG_COLOR_P2);

    draw_rect(
        PADDLE_MARGIN,
        state->paddle_p1_y,
        PADDLE_WIDTH,
        PADDLE_HEIGHT,
        PONG_COLOR_P1
    );

    draw_rect(
        GAME_WIDTH - PADDLE_MARGIN - PADDLE_WIDTH,
        state->paddle_p2_y,
        PADDLE_WIDTH,
        PADDLE_HEIGHT,
        PONG_COLOR_P2
    );

    draw_rect(
        state->ball_x,
        state->ball_y,
        BALL_SIZE,
        BALL_SIZE,
        PONG_COLOR_BALL
    );

    if (state->status == GAME_WAITING) {
        draw_rect(68U, 20U, 24U, 3U, PONG_COLOR_DIM);
    }

    if (state->status == GAME_OVER) {
        draw_rect(55U, 20U, 50U, 3U, VRAM_COLOR_RED);
    }
}
