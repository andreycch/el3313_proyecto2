#include "game/spi_game.h"
#include "game/game_packet.h"

/*
 * Temporary SPI stub buffers.
 *
 * These variables simulate what would travel through SPI.
 * In the final hardware version, this section will be replaced by SPI
 * transmit and receive functions from Vitis.
 */
static game_input_packet_t spi_stub_input_packet;
static game_state_packet_t spi_stub_state_packet;

static uint8_t spi_stub_input_available = 0;
static uint8_t spi_stub_state_available = 0;

/*
 * Clears the temporary SPI stub buffers.
 */
void spi_game_stub_clear(void)
{
    spi_stub_input_available = 0;
    spi_stub_state_available = 0;
}

/*
 * Sends a player input packet through the SPI game link.
 *
 * Stub behavior:
 * stores the packet in a temporary memory buffer.
 */
void spi_game_send_player_input(
    player_input_t input,
    uint8_t frame_id
)
{
    game_packet_build_input(
        &spi_stub_input_packet,
        input,
        frame_id
    );

    spi_stub_input_available = 1;
}

/*
 * Receives a player input packet from the SPI game link.
 *
 * Stub behavior:
 * reads the temporary memory buffer and validates its checksum.
 */
uint8_t spi_game_receive_player_input(
    player_input_t *input
)
{
    if (!spi_stub_input_available) {
        return 0;
    }

    if (!game_packet_validate_input(&spi_stub_input_packet)) {
        spi_stub_input_available = 0;
        return 0;
    }

    *input = game_packet_decode_input(&spi_stub_input_packet);

    spi_stub_input_available = 0;

    return 1;
}

/*
 * Sends the official game state through the SPI game link.
 *
 * Stub behavior:
 * stores the packet in a temporary memory buffer.
 */
void spi_game_send_state(
    const game_state_t *state
)
{
    game_packet_build_state(
        &spi_stub_state_packet,
        state
    );

    spi_stub_state_available = 1;
}

/*
 * Receives the official game state through the SPI game link.
 *
 * Stub behavior:
 * reads the temporary memory buffer, validates its checksum,
 * and applies the received packet to a game_state_t structure.
 */
uint8_t spi_game_receive_state(
    game_state_t *state
)
{
    if (!spi_stub_state_available) {
        return 0;
    }

    if (!game_packet_validate_state(&spi_stub_state_packet)) {
        spi_stub_state_available = 0;
        return 0;
    }

    game_packet_apply_state(state, &spi_stub_state_packet);

    spi_stub_state_available = 0;

    return 1;
}