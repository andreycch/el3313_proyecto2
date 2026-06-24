#ifndef SPI_GAME_H
#define SPI_GAME_H

#include <stdint.h>

#include "player_input.h"
#include "game_state.h"

/*
 * SPI game communication layer.
 *
 * This module is a temporary stub.
 * It defines the functions that will later be connected to the real SPI
 * driver in Vitis/MicroBlaze.
 *
 * Communication idea:
 *
 * Slave FPGA -> Master FPGA:
 * player 2 input
 *
 * Master FPGA -> Slave FPGA:
 * official game state
 */

/*
 * Sends a player input packet through the SPI game link.
 *
 * In the final FPGA version, this function will transmit bytes using
 * the SPI peripheral.
 */
void spi_game_send_player_input(
    player_input_t input,
    uint8_t frame_id
);

/*
 * Receives a player input packet from the SPI game link.
 *
 * Returns:
 * 1 = valid input received
 * 0 = no valid input available
 */
uint8_t spi_game_receive_player_input(
    player_input_t *input
);

/*
 * Sends the official game state through the SPI game link.
 *
 * In the final FPGA version, this function will transmit the state packet
 * using the SPI peripheral.
 */
void spi_game_send_state(
    const game_state_t *state
);

/*
 * Receives the official game state through the SPI game link.
 *
 * Returns:
 * 1 = valid state received
 * 0 = no valid state available
 */
uint8_t spi_game_receive_state(
    game_state_t *state
);

/*
 * Clears the temporary SPI stub buffers.
 * Useful for tests and initialization.
 */
void spi_game_stub_clear(void);

#endif