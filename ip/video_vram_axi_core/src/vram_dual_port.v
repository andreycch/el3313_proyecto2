`default_nettype none

//! @title VRAM de doble puerto
//! @author Grupo Maestro
//! @brief Memoria de video basada en BRAM para el sistema VGA.
//!
//! Este módulo implementa una memoria de video de doble puerto.
//! El puerto de escritura permite que una lógica externa, y luego el
//! procesador MicroBlaze V mediante AXI, escriba pixeles en memoria.
//! El puerto de lectura permite que el controlador VGA lea pixeles
//! continuamente para generar la imagen en pantalla.
//!
//! La memoria utiliza un estilo compatible con inferencia de BRAM.
//! Por defecto se propone una resolución lógica de 160x120 pixeles,
//! usando 12 bits por pixel: 4 bits rojo, 4 bits verde y 4 bits azul.

module vram_dual_port #(
    parameter DATA_WIDTH   = 12,    //! Bits por pixel.
    parameter ADDR_WIDTH   = 15,    //! Bits de dirección.
    parameter MEMORY_DEPTH = 19200  //! Cantidad total de pixeles.
)(
    input  wire                    clk,       //! Reloj principal.

    input  wire                    wr_en,     //! Habilitación de escritura.
    input  wire [ADDR_WIDTH-1:0]   wr_addr,   //! Dirección de escritura.
    input  wire [DATA_WIDTH-1:0]   wr_data,   //! Dato de escritura.

    input  wire [ADDR_WIDTH-1:0]   rd_addr,   //! Dirección de lectura.
    output reg  [DATA_WIDTH-1:0]   rd_data    //! Dato leído.
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] vram [0:MEMORY_DEPTH-1];

    //! @brief Puerto de escritura síncrono.
    always @(posedge clk) begin
        if (wr_en && (wr_addr < MEMORY_DEPTH)) begin
            vram[wr_addr] <= wr_data;
        end
    end

    //! @brief Puerto de lectura síncrono.
    always @(posedge clk) begin
        if (rd_addr < MEMORY_DEPTH) begin
            rd_data <= vram[rd_addr];
        end else begin
            rd_data <= {DATA_WIDTH{1'b0}};
        end
    end

endmodule

`default_nettype wire
