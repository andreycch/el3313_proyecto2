#include <stdint.h>
#include <string.h>

#include "xparameters.h"
#include "xspi.h"
#include "xstatus.h"

#include "game/spi_game.h"
#include "game/game_packet.h"

#define SPI_GAME_SS_MASK 0x01U

static XSpi spi_instance;
static uint8_t spi_initialized = 0U;

static int spi_game_init_hw(void)
{
    int status;

    if (spi_initialized != 0U) {
        return XST_SUCCESS;
    }

#ifdef SDT
    XSpi_Config *config;

    config = XSpi_LookupConfig((UINTPTR)XPAR_XSPI_0_BASEADDR);
    if (config == NULL) {
        return XST_FAILURE;
    }

    status = XSpi_CfgInitialize(&spi_instance, config, config->BaseAddress);
    if (status != XST_SUCCESS) {
        return status;
    }
#else
    status = XSpi_Initialize(&spi_instance, XPAR_XSPI_0_DEVICE_ID);
    if (status != XST_SUCCESS) {
        return status;
    }
#endif

    status = XSpi_SetOptions(
        &spi_instance,
        XSP_MASTER_OPTION | XSP_MANUAL_SSELECT_OPTION
    );

    if (status != XST_SUCCESS) {
        return status;
    }

    XSpi_Start(&spi_instance);
    XSpi_IntrGlobalDisable(&spi_instance);

    status = XSpi_SetSlaveSelect(&spi_instance, SPI_GAME_SS_MASK);
    if (status != XST_SUCCESS) {
        return status;
    }

    spi_initialized = 1U;

    return XST_SUCCESS;
}

static uint8_t spi_game_transfer_bytes(
    const uint8_t *tx_buffer,
    uint8_t *rx_buffer,
    uint32_t length
)
{
    int status;

    if ((tx_buffer == NULL) || (rx_buffer == NULL) || (length == 0U)) {
        return 0U;
    }

    status = spi_game_init_hw();
    if (status != XST_SUCCESS) {
        return 0U;
    }

    status = XSpi_SetSlaveSelect(&spi_instance, SPI_GAME_SS_MASK);
    if (status != XST_SUCCESS) {
        return 0U;
    }

    status = XSpi_Transfer(
        &spi_instance,
        (uint8_t *)tx_buffer,
        rx_buffer,
        length
    );

    if (status != XST_SUCCESS) {
        return 0U;
    }

    return 1U;
}

void spi_game_stub_clear(void)
{
    spi_initialized = 0U;
}

void spi_game_send_player_input(
    player_input_t input,
    uint8_t frame_id
)
{
    game_input_packet_t packet;
    uint8_t rx_dummy[sizeof(game_input_packet_t)];

    game_packet_build_input(
        &packet,
        input,
        frame_id
    );

    (void)spi_game_transfer_bytes(
        (const uint8_t *)&packet,
        rx_dummy,
        sizeof(game_input_packet_t)
    );
}

uint8_t spi_game_receive_player_input(
    player_input_t *input
)
{
    game_input_packet_t packet;
    uint8_t tx_dummy[sizeof(game_input_packet_t)];

    if (input == NULL) {
        return 0U;
    }

    memset(tx_dummy, 0x00, sizeof(tx_dummy));
    memset(&packet, 0x00, sizeof(packet));

    if (!spi_game_transfer_bytes(
            tx_dummy,
            (uint8_t *)&packet,
            sizeof(game_input_packet_t)
        )) {
        return 0U;
    }

    if (!game_packet_validate_input(&packet)) {
        return 0U;
    }

    *input = game_packet_decode_input(&packet);

    return 1U;
}

void spi_game_send_state(
    const game_state_t *state
)
{
    game_state_packet_t packet;
    uint8_t rx_dummy[sizeof(game_state_packet_t)];

    if (state == NULL) {
        return;
    }

    game_packet_build_state(
        &packet,
        state
    );

    (void)spi_game_transfer_bytes(
        (const uint8_t *)&packet,
        rx_dummy,
        sizeof(game_state_packet_t)
    );
}

uint8_t spi_game_receive_state(
    game_state_t *state
)
{
    game_state_packet_t packet;
    uint8_t tx_dummy[sizeof(game_state_packet_t)];

    if (state == NULL) {
        return 0U;
    }

    memset(tx_dummy, 0x00, sizeof(tx_dummy));
    memset(&packet, 0x00, sizeof(packet));

    if (!spi_game_transfer_bytes(
            tx_dummy,
            (uint8_t *)&packet,
            sizeof(game_state_packet_t)
        )) {
        return 0U;
    }

    if (!game_packet_validate_state(&packet)) {
        return 0U;
    }

    game_packet_apply_state(state, &packet);

    return 1U;
}
