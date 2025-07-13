`timescale 1ns / 1ps

module HazardDetection (
    input logic [4:0] IF_ID_RS1,
    input logic [4:0] IF_ID_RS2,
    input logic [4:0] ID_EX_rd,
    input logic ID_EX_MemRead,
    output logic stall
);
 // para evitar stall desnecessário, qd o reg destino for x0
  assign stall = (ID_EX_MemRead) ? 
               (((ID_EX_rd == IF_ID_RS1) || (ID_EX_rd == IF_ID_RS2)) && (ID_EX_rd != 0)) : 
               0;

endmodule
