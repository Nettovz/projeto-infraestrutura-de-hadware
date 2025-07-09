`timescale 1ns / 1ps

module mux2 #(
    parameter WIDTH = 32
) (
    input logic signed[WIDTH-1:0] d0,
    d1,
    input logic s,
    output logic signed[WIDTH-1:0] y
);

  assign y = s ? d1 : d0;

endmodule
