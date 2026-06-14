`timescale 1ns/1ps
`default_nettype none

module tb_el3313_proyecto2_top;

    localparam CLK_PERIOD_NS = 10;

    reg CLK100MHZ;
    reg CPU_RESETN;

    wire [3:0] VGA_R;
    wire [3:0] VGA_G;
    wire [3:0] VGA_B;
    wire       VGA_HS;
    wire       VGA_VS;

    integer error_count;
    integer center_ball_detected;
    integer left_paddle_detected;
    integer right_paddle_detected;

    el3313_proyecto2_top dut (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B),
        .VGA_HS(VGA_HS),
        .VGA_VS(VGA_VS)
    );

    always #(CLK_PERIOD_NS / 2) CLK100MHZ = ~CLK100MHZ;

    initial begin
        CLK100MHZ = 1'b0;
        CPU_RESETN = 1'b0;

        error_count = 0;
        center_ball_detected = 0;
        left_paddle_detected = 0;
        right_paddle_detected = 0;

        repeat (10) @(posedge CLK100MHZ);
        CPU_RESETN = 1'b1;

        repeat (800 * 525 * 4) begin
            @(posedge CLK100MHZ);

            if (dut.video_active &&
                dut.pixel_x == 10'd320 &&
                dut.pixel_y == 10'd240) begin

                center_ball_detected = 1;

                if ((VGA_R !== 4'hF) || (VGA_G !== 4'hF) || (VGA_B !== 4'hF)) begin
                    $display("ERROR: pelota central no es blanca. RGB=%h%h%h tiempo=%0t",
                        VGA_R, VGA_G, VGA_B, $time);
                    error_count = error_count + 1;
                end
            end

            if (dut.video_active &&
                dut.pixel_x == 10'd45 &&
                dut.pixel_y == 10'd240) begin

                left_paddle_detected = 1;

                if ((VGA_R !== 4'hF) || (VGA_G !== 4'hF) || (VGA_B !== 4'hF)) begin
                    $display("ERROR: paleta izquierda no es blanca. RGB=%h%h%h tiempo=%0t",
                        VGA_R, VGA_G, VGA_B, $time);
                    error_count = error_count + 1;
                end
            end

            if (dut.video_active &&
                dut.pixel_x == 10'd595 &&
                dut.pixel_y == 10'd240) begin

                right_paddle_detected = 1;

                if ((VGA_R !== 4'hF) || (VGA_G !== 4'hF) || (VGA_B !== 4'hF)) begin
                    $display("ERROR: paleta derecha no es blanca. RGB=%h%h%h tiempo=%0t",
                        VGA_R, VGA_G, VGA_B, $time);
                    error_count = error_count + 1;
                end
            end
        end

        if (!center_ball_detected) begin
            $display("ERROR: no se detectó el pixel de la pelota central.");
            error_count = error_count + 1;
        end

        if (!left_paddle_detected) begin
            $display("ERROR: no se detectó el pixel de la paleta izquierda.");
            error_count = error_count + 1;
        end

        if (!right_paddle_detected) begin
            $display("ERROR: no se detectó el pixel de la paleta derecha.");
            error_count = error_count + 1;
        end

        if (error_count == 0) begin
            $display("TEST PASSED: integración VGA estática funciona correctamente.");
        end else begin
            $display("TEST FAILED: errores detectados = %0d", error_count);
        end

        $finish;
    end

endmodule

`default_nettype wire
