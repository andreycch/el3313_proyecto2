#include <stdint.h>

#include "game/input_driver.h"

#ifdef __has_include
#  if __has_include("xparameters.h")
#    include "xparameters.h"
#  endif
#endif

/*
 * AXI GPIO input register.
 * The current block design maps axi_gpio_0 at 0x40000000 and exposes
 * INPUT_DRIVER[7:0] as an 8-bit input bus connected to Nexys A7 switches.
 */
#define INPUT_GPIO_DATA_OFFSET 0x00000000U

#ifndef INPUT_DRIVER_BASE_ADDR
#  ifdef XPAR_INPUT_DRIVER_BASEADDR
#    define INPUT_DRIVER_BASE_ADDR ((uintptr_t)XPAR_INPUT_DRIVER_BASEADDR)
#  elif defined(XPAR_AXI_GPIO_0_BASEADDR)
#    define INPUT_DRIVER_BASE_ADDR ((uintptr_t)XPAR_AXI_GPIO_0_BASEADDR)
#  else
#    define INPUT_DRIVER_BASE_ADDR ((uintptr_t)0x40000000U)
#  endif
#endif

/*
 * Reads the raw input word from AXI GPIO.
 */
static uint32_t input_read_raw(void)
{
    volatile uint32_t *gpio_data;

    gpio_data = (volatile uint32_t *)(INPUT_DRIVER_BASE_ADDR + INPUT_GPIO_DATA_OFFSET);

    return (*gpio_data) & 0x000000FFU;
}

/*
 * Converts a raw 32-bit input word into player 1 input.
 */
player_input_t input_decode_player1(uint32_t raw_input)
{
    player_input_t input;

    input.up    = (raw_input & INPUT_BIT_P1_UP)    ? 1U : 0U;
    input.down  = (raw_input & INPUT_BIT_P1_DOWN)  ? 1U : 0U;
    input.start = (raw_input & INPUT_BIT_P1_START) ? 1U : 0U;
    input.reset = (raw_input & INPUT_BIT_P1_RESET) ? 1U : 0U;

    return input;
}

/*
 * Converts a raw 32-bit input word into player 2 input.
 */
player_input_t input_decode_player2(uint32_t raw_input)
{
    player_input_t input;

    input.up    = (raw_input & INPUT_BIT_P2_UP)    ? 1U : 0U;
    input.down  = (raw_input & INPUT_BIT_P2_DOWN)  ? 1U : 0U;
    input.start = (raw_input & INPUT_BIT_P2_START) ? 1U : 0U;
    input.reset = (raw_input & INPUT_BIT_P2_RESET) ? 1U : 0U;

    return input;
}

/*
 * Reads player 1 input from the current hardware input register.
 */
player_input_t input_read_player1(void)
{
    return input_decode_player1(input_read_raw());
}

/*
 * Reads player 2 input from the current hardware input register.
 */
player_input_t input_read_player2(void)
{
    return input_decode_player2(input_read_raw());
}
