`default_nettype none

//! @title Escritor AXI-Lite hacia VRAM
//! @author Grupo Maestro
//! @brief Convierte escrituras AXI-Lite en escrituras hacia la VRAM.
//!
//! Este módulo implementa una interfaz AXI4-Lite básica para permitir que
//! un procesador, como MicroBlaze V, escriba pixeles en la memoria de video.
//!
//! Cada pixel se mapea como una palabra de 32 bits desde el punto de vista
//! del procesador, pero solo se usan los 12 bits bajos:
//!
//! bits [11:8]  = rojo
//! bits [7:4]   = verde
//! bits [3:0]   = azul
//! bits [31:12] = reservado
//!
//! La dirección AXI se interpreta como dirección en bytes:
//!
//! offset = pixel_index * 4
//! pixel_index = y * 160 + x
//!
//! Este módulo genera una escritura válida hacia VRAM cuando recibe una
//! transacción AXI-Lite de escritura dentro del rango permitido.

module axi_lite_vram_writer #(
    parameter C_S_AXI_DATA_WIDTH = 32,    //! Ancho de datos AXI-Lite.
    parameter C_S_AXI_ADDR_WIDTH = 17,    //! Ancho de dirección AXI-Lite. 17 bits = 128 KiB.
    parameter VRAM_ADDR_WIDTH    = 15,    //! Ancho de dirección interna de VRAM.
    parameter VRAM_DATA_WIDTH    = 12,    //! Bits útiles por pixel.
    parameter VRAM_MEMORY_DEPTH  = 19200  //! Cantidad de pixeles de VRAM.
)(
    input  wire                                  S_AXI_ACLK,    //! Reloj AXI.
    input  wire                                  S_AXI_ARESETN, //! Reset AXI activo en bajo.

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]         S_AXI_AWADDR,  //! Dirección de escritura.
    input  wire [2:0]                            S_AXI_AWPROT,  //! Protección AXI.
    input  wire                                  S_AXI_AWVALID, //! Dirección de escritura válida.
    output reg                                   S_AXI_AWREADY, //! Interfaz lista para dirección.

    input  wire [C_S_AXI_DATA_WIDTH-1:0]         S_AXI_WDATA,   //! Dato de escritura.
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]     S_AXI_WSTRB,   //! Máscara de bytes.
    input  wire                                  S_AXI_WVALID,  //! Dato de escritura válido.
    output reg                                   S_AXI_WREADY,  //! Interfaz lista para dato.

    output reg  [1:0]                            S_AXI_BRESP,   //! Respuesta de escritura.
    output reg                                   S_AXI_BVALID,  //! Respuesta de escritura válida.
    input  wire                                  S_AXI_BREADY,  //! Maestro listo para respuesta.

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]         S_AXI_ARADDR,  //! Dirección de lectura.
    input  wire [2:0]                            S_AXI_ARPROT,  //! Protección AXI.
    input  wire                                  S_AXI_ARVALID, //! Dirección de lectura válida.
    output reg                                   S_AXI_ARREADY, //! Interfaz lista para dirección de lectura.

    output reg  [C_S_AXI_DATA_WIDTH-1:0]         S_AXI_RDATA,   //! Dato leído.
    output reg  [1:0]                            S_AXI_RRESP,   //! Respuesta de lectura.
    output reg                                   S_AXI_RVALID,  //! Dato de lectura válido.
    input  wire                                  S_AXI_RREADY,  //! Maestro listo para lectura.

    output reg                                   vram_wr_en,    //! Escritura hacia VRAM.
    output reg  [VRAM_ADDR_WIDTH-1:0]            vram_wr_addr,  //! Dirección interna de VRAM.
    output reg  [VRAM_DATA_WIDTH-1:0]            vram_wr_data   //! Pixel RGB444.
);

    localparam [1:0] AXI_RESP_OKAY   = 2'b00;
    localparam [1:0] AXI_RESP_SLVERR = 2'b10;

    wire [VRAM_ADDR_WIDTH-1:0] axi_word_addr;
    wire                       write_addr_valid;
    wire                       write_strobe_valid;
    wire                       write_transfer;

    wire unused_axi_signals;

    assign axi_word_addr = S_AXI_AWADDR[VRAM_ADDR_WIDTH+1:2];

    assign write_addr_valid =
        (axi_word_addr < VRAM_MEMORY_DEPTH);

    assign write_strobe_valid =
        S_AXI_WSTRB[0] && S_AXI_WSTRB[1];

    assign write_transfer =
        S_AXI_AWVALID &&
        S_AXI_WVALID &&
        !S_AXI_BVALID;

    assign unused_axi_signals = &{
        1'b0,
        S_AXI_AWPROT,
        S_AXI_ARADDR,
        S_AXI_ARPROT
    };

    //! @brief Canal de escritura AXI-Lite hacia VRAM.
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BRESP   <= AXI_RESP_OKAY;
            S_AXI_BVALID  <= 1'b0;

            vram_wr_en    <= 1'b0;
            vram_wr_addr  <= {VRAM_ADDR_WIDTH{1'b0}};
            vram_wr_data  <= {VRAM_DATA_WIDTH{1'b0}};
        end else begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            vram_wr_en    <= 1'b0;

            if (write_transfer) begin
                S_AXI_AWREADY <= 1'b1;
                S_AXI_WREADY  <= 1'b1;
                S_AXI_BVALID  <= 1'b1;

                if (write_addr_valid && write_strobe_valid) begin
                    S_AXI_BRESP  <= AXI_RESP_OKAY;

                    vram_wr_en   <= 1'b1;
                    vram_wr_addr <= axi_word_addr;
                    vram_wr_data <= S_AXI_WDATA[VRAM_DATA_WIDTH-1:0];
                end else begin
                    S_AXI_BRESP  <= AXI_RESP_SLVERR;

                    vram_wr_en   <= 1'b0;
                    vram_wr_addr <= {VRAM_ADDR_WIDTH{1'b0}};
                    vram_wr_data <= {VRAM_DATA_WIDTH{1'b0}};
                end
            end else if (S_AXI_BVALID && S_AXI_BREADY) begin
                S_AXI_BVALID <= 1'b0;
                S_AXI_BRESP  <= AXI_RESP_OKAY;
            end
        end
    end

    //! @brief Canal de lectura AXI-Lite básico.
    //!
    //! Por ahora este módulo solo implementa escritura hacia VRAM.
    //! Las lecturas devuelven cero con respuesta OKAY.
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RDATA   <= {C_S_AXI_DATA_WIDTH{1'b0}};
            S_AXI_RRESP   <= AXI_RESP_OKAY;
            S_AXI_RVALID  <= 1'b0;
        end else begin
            S_AXI_ARREADY <= 1'b0;

            if (S_AXI_ARVALID && !S_AXI_RVALID) begin
                S_AXI_ARREADY <= 1'b1;
                S_AXI_RDATA   <= {C_S_AXI_DATA_WIDTH{1'b0}};
                S_AXI_RRESP   <= AXI_RESP_OKAY;
                S_AXI_RVALID  <= 1'b1;
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
                S_AXI_RRESP  <= AXI_RESP_OKAY;
            end
        end
    end

endmodule

`default_nettype wire
