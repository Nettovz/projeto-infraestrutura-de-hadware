`timescale 1ns / 1ps

module HazardDetection (
    // Entradas dos registradores
    input logic [4:0] IF_ID_RS1,    // Registrador fonte 1 (estágio IF/ID)
    input logic [4:0] IF_ID_RS2,    // Registrador fonte 2 (estágio IF/ID)
    
    // Entradas dos destinos
    input logic [4:0] ID_EX_rd,     // Registrador destino (estágio ID/EX)
    input logic [4:0] EX_MEM_rd,    // Registrador destino (estágio EX/MEM)
    input logic [4:0] MEM_WB_rd,    // Registrador destino (estágio MEM/WB)
    
    // Sinais de controle
    input logic ID_EX_MemRead,      // Indica load instruction
    input logic ID_EX_RegWrite,     // Indica se escreve em registrador (ID/EX)
    input logic EX_MEM_RegWrite,    // Indica se escreve em registrador (EX/MEM)
    input logic MEM_WB_RegWrite,    // Indica se escreve em registrador (MEM/WB)
    
    // Saídas
    output logic stall,             // Sinal de stall
    output logic [1:0] forwardA,    // Controle do MUX para operando A
    output logic [1:0] forwardB     // Controle do MUX para operando B
);

    // 1. Detecção de Load-Use Hazard (stall necessário)
    assign stall = (ID_EX_MemRead && ID_EX_rd != 0) ? 
                  ((ID_EX_rd == IF_ID_RS1) || (ID_EX_rd == IF_ID_RS2)) : 
                  1'b0;

    // 2. Lógica de Forwarding para operandos A e B
    assign forwardA = (EX_MEM_RegWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == IF_ID_RS1)) ? 2'b10 :
                     (MEM_WB_RegWrite && (MEM_WB_rd != 0) && (MEM_WB_rd == IF_ID_RS1)) ? 2'b01 :
                     2'b00;

    assign forwardB = (EX_MEM_RegWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == IF_ID_RS2)) ? 2'b10 :
                     (MEM_WB_RegWrite && (MEM_WB_rd != 0) && (MEM_WB_rd == IF_ID_RS2)) ? 2'b01 :
                     2'b00;

endmodule