#include <stdint.h>

#include "game/game_app.h"
#include "game/input_driver.h"
#include "game/pong_renderer.h"

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

    game_app_init(
        &app,
        GAME_MODE_LOCAL,
        GAME_ROLE_NONE
    );

    pong_render_state(&app.state);

    while (1) {
        p1 = input_read_player1();
        p2 = input_read_player2();

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
