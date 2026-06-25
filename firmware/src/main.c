#include <stdint.h>

#include "game/game_app.h"
#include "game/input_driver.h"
#include "game/pong_renderer.h"
#include "game/spi_game.h"
#include "game/ddr2_memory.h"
#include "vram_memory_map.h"

#define MAIN_LOOP_DELAY_CYCLES 120000U

static void delay_cycles(uint32_t cycles)
{
    volatile uint32_t i;

    for (i = 0U; i < cycles; i++) {
        /* Busy wait used until a timer/tick source is integrated. */
    }
}

static void draw_ddr2_status_indicator(uint8_t ddr2_ok)
{
    uint32_t x;
    uint32_t y;
    uint16_t color;

    color = ddr2_ok ? VRAM_COLOR_GREEN : VRAM_COLOR_RED;

    for (y = 108U; y < 117U; y++) {
        for (x = 148U; x < 157U; x++) {
            vram_write_pixel(x, y, color);
        }
    }
}

int main(void)
{
    game_app_t app;
    player_input_t p1;
    player_input_t p2;
    player_input_t p2_remote;
    uint8_t multiplayer_mode;
    uint8_t game_reset;
    uint8_t game_reset_prev;
    uint8_t ddr2_ok;

    game_reset_prev = 0U;

    delay_cycles(2000000U);

    ddr2_ok = ddr2_self_test();

    if (ddr2_ok != 0U) {
        ddr2_init_game_config();
        ddr2_init_demo_sprite_bank();
    }

    game_app_init(
        &app,
        GAME_MODE_LOCAL,
        GAME_ROLE_MASTER
    );

    if (ddr2_ok != 0U) {
        ddr2_store_game_state(&app.state);
    }

    pong_render_state(&app.state);
    draw_ddr2_status_indicator(ddr2_ok);

    while (1) {
        p1 = input_read_player1();
        p2 = input_read_player2();

        multiplayer_mode = input_read_multiplayer_mode();

        if (multiplayer_mode) {
            if (spi_game_exchange_state_input(&app.state, &p2_remote)) {
                p2 = p2_remote;
            }
        }

        game_reset = input_read_game_reset();

        if ((game_reset != 0U) && (game_reset_prev == 0U)) {
            p1.reset = 1U;
            p2.reset = 1U;
        }

        game_reset_prev = game_reset;

        game_app_update_local(
            &app,
            p1,
            p2
        );

        if (ddr2_ok != 0U) {
            ddr2_store_game_state(&app.state);
        }

        pong_render_state(&app.state);
        draw_ddr2_status_indicator(ddr2_ok);

        delay_cycles(MAIN_LOOP_DELAY_CYCLES);
    }

    return 0;
}
