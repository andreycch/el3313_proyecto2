`default_nettype none

//! @title Top del Proyecto 2 EL3313
//! @author Grupo Maestro
//! @brief Integra la salida VGA inicial con una escena estática tipo Pong.
//!
//! Este módulo superior conecta el generador de pixel_tick, el temporizador
//! VGA y el renderizador estático de Pong. Esta integración permite validar
//! una primera salida de video visible antes de incorporar VRAM y MicroBlaze V.
//!
//! La salida esperada es una pantalla negra con línea central, dos paletas
//! laterales y una pelota en el centro.

module el3313_proyecto2_top (
    input  wire       CLK100MHZ,  //! Reloj principal de 100 MHz de la Nexys A7.
    input  wire       CPU_RESETN, //! Reset físico activo en bajo.

    output wire [3:0] VGA_R,      //! Canal rojo VGA.
    output wire [3:0] VGA_G,      //! Canal verde VGA.
    output wire [3:0] VGA_B,      //! Canal azul VGA.
    output wire       VGA_HS,     //! Sincronización horizontal VGA.
    output wire       VGA_VS      //! Sincronización vertical VGA.
);

    wire reset_active_high;
    wire pixel_tick;
    wire video_active;
    wire frame_tick;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    assign reset_active_high = ~CPU_RESETN;

    //! @brief Generador de habilitación de pixel para VGA.
    pixel_tick_gen #(
        .DIVISOR(4)
    ) pixel_tick_gen_inst (
        .clk(CLK100MHZ),
        .rst(reset_active_high),
        .pixel_tick(pixel_tick)
    );

    //! @brief Temporizador VGA para resolución base 640x480.
    vga_timing vga_timing_inst (
        .clk(CLK100MHZ),
        .rst(reset_active_high),
        .pixel_tick(pixel_tick),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .video_active(video_active),
        .frame_tick(frame_tick),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );

    //! @brief Renderizador estático para validar la salida VGA.
    pong_static_renderer pong_static_renderer_inst (
        .video_active(video_active),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .vga_red(VGA_R),
        .vga_green(VGA_G),
        .vga_blue(VGA_B)
    );

endmodule

`default_nettype wire
