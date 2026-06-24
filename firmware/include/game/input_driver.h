#ifndef INPUT_DRIVER_H
#define INPUT_DRIVER_H

#include <stdint.h>
#include "player_input.h"

/*
 * Raw input bit mapping.
 *
 * These masks represent the physical input bits that may come from:
 * - AXI GPIO
 * - switches
 * - push buttons
 * - test software
 *
 * The mapping can be changed later depending on the final FPGA pinout.
 */
#define INPUT_BIT_P1_UP       0x00000001U
#define INPUT_BIT_P1_DOWN     0x00000002U
#define INPUT_BIT_P1_START    0x00000004U
#define INPUT_BIT_P1_RESET    0x00000008U

#define INPUT_BIT_P2_UP       0x00000010U
#define INPUT_BIT_P2_DOWN     0x00000020U
#define INPUT_BIT_P2_START    0x00000040U
#define INPUT_BIT_P2_RESET    0x00000080U

/*
 * Converts a raw 32-bit input word into player 1 input.
 */
player_input_t input_decode_player1(uint32_t raw_input);

/*
 * Converts a raw 32-bit input word into player 2 input.
 */
player_input_t input_decode_player2(uint32_t raw_input);

/*
 * Hardware-level input functions.
 *
 * For now, these are stubs.
 * Later, in Vitis, their internal implementation can read AXI GPIO.
 */
player_input_t input_read_player1(void);
player_input_t input_read_player2(void);

#endif