#include <stdint.h>

#include "game/game_app.h"
#include "game/input_driver.h"
#include "game/pong_renderer.h"
#include "game/spi_game.h"

#define MAIN_LOOP_DELAY_CYCLES 120000U

static void delay_cycles(uint32_t cycles)
{
    volatile uint32_t i;

    for (i = 0U; i < cycles; i++) {
        /* Busy wait used until a timer/tick source is integrated. */
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

    game_reset_prev = 0U;

    game_app_init(
        &app,
        GAME_MODE_LOCAL,
        GAME_ROLE_MASTER
    );

    pong_render_state(&app.state);

    while (1) {
        p1 = input_read_player1();
        p2 = input_read_player2();

        /*
         * SW15 selects the operating mode:
         *
         * SW15 = 0:
         *   Solo/local mode. SPI is not used and both paddles are controlled
         *   from the master FPGA buttons.
         *
         * SW15 = 1:
         *   Multiplayer mode. SPI is enabled and player 2 input is taken
         *   from the slave FPGA when a valid packet is received.
         */
        multiplayer_mode = input_read_multiplayer_mode();

        if (multiplayer_mode) {
            if (spi_game_exchange_state_input(&app.state, &p2_remote)) {
                p2 = p2_remote;
            }
        }

        /*
         * SW0 is a game-level reset.
         * It is converted into a one-frame pulse on rising edge so the game
         * resets once when SW0 is moved from 0 to 1.
         */
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

        pong_render_state(&app.state);

        delay_cycles(MAIN_LOOP_DELAY_CYCLES);
    }

    return 0;
}
