`timescale 1ns / 1ps

module ALUController (
    input logic [1:0] ALUOp,   // 00:mem 01:branch 10:R/I-type
    input logic [6:0] Funct7,
    input logic [2:0] Funct3,
    output logic [3:0] Operation
);

// Bit 0: Controla operações OR, shifts right ou SUB
assign Operation[0] = 
    ((ALUOp == 2'b10) && (Funct3 == 3'b110)) ||  // OR/ORI
    ((ALUOp == 2'b10) && (Funct3 == 3'b101) && (Funct7 == 7'b0000000)) || // SRL/SRLI
    ((ALUOp == 2'b10) && (Funct3 == 3'b101) && (Funct7 == 7'b0100000)) || // SRA/SRAI
    ((ALUOp == 2'b10) && (Funct3 == 3'b000) && (Funct7 == 7'b0100000));   // SUB

// Bit 1: Controla operações ADD ou SRA
assign Operation[1] = 
    (ALUOp == 2'b00) ||                          // LW/SW (soma de endereço)
    ((ALUOp == 2'b10) && (Funct3 == 3'b000)) ||  // ADD/ADDI
    ((ALUOp == 2'b10) && (Funct3 == 3'b101) && (Funct7 == 7'b0100000)); // SRA/SRAI

// Bit 2: Controla shifts ou SLT
assign Operation[2] =  
    ((ALUOp == 2'b10) && (Funct3 == 3'b101) && (Funct7 == 7'b0000000)) || // SRL/SRLI
    ((ALUOp == 2'b10) && (Funct3 == 3'b101) && (Funct7 == 7'b0100000)) || // SRA/SRAI
    ((ALUOp == 2'b10) && (Funct3 == 3'b001)) ||  // SLL/SLLI
    ((ALUOp == 2'b10) && (Funct3 == 3'b010));    // SLT/SLTI

// Bit 3: Controla branches ou SLT
assign Operation[3] = 
    (ALUOp == 2'b01) ||                          // Branches
    ((ALUOp == 2'b10) && (Funct3 == 3'b010));    // SLT/SLTI
endmodule