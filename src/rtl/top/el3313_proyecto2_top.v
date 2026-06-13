`default_nettype none

//! @title EL3313 Proyecto 2 Top
//! @author Grupo Maestro
//! @brief Marcador de posición de nivel superior para la integración de MicroBlaze V, VGA y VRAM.
//!
//! Este módulo es el punto de entrada de nivel superior para el proyecto de FPGA.
//! Posteriormente integrará el subsistema MicroBlaze V, el controlador VGA,
//! la interfaz VRAM y las E/S locales.

module el3313_proyecto2_top (
    input  wire CLK100MHZ, //! Reloj de placa de 100 MHz de Nexys A7.
    input  wire CPU_RESETN, //! Entrada de reinicio activa en bajo desde Nexys A7.

    output wire [3:0] VGA_R,  //! VGA canal rojo.
    output wire [3:0] VGA_G,  //! VGA canal verde.
    output wire [3:0] VGA_B,  //! VGA canal azul.
    output wire       VGA_HS,  //! VGA sync horizontal.
    output wire       VGA_VS  //! VGA sync vertical.
);

    wire reset_sync;

    assign reset_sync = ~CPU_RESETN;

    assign VGA_R  = 4'b0000;
    assign VGA_G  = 4'b0000;
    assign VGA_B  = 4'b0000;
    assign VGA_HS = 1'b1;
    assign VGA_VS = 1'b1;

endmodule

`default_nettype wire
