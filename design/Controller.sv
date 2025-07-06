`timescale 1ns / 1ps

module Controller (
    //Input
    input logic [6:0] Opcode,
    //7-bit opcode field from the instruction

    //Outputs
    output logic ALUSrc,
    //0: The second ALU operand comes from the second register file output (Read data 2); 
    //1: The second ALU operand is the sign-extended, lower 16 bits of the instruction.
    output logic MemtoReg,
    //0: The value fed to the register Write data input comes from the ALU.
    //1: The value fed to the register Write data input comes from the data memory.
    output logic RegWrite, //The register on the Write register input is written with the value on the Write data input 
    output logic MemRead,  //Data memory contents designated by the address input are put on the Read data output
    output logic MemWrite, //Data memory contents designated by the address input are replaced by the value on the Write data input.
    output logic [1:0] ALUOp,  //00: LW/SW; 01:Branch; 10: Rtype
    output logic Branch  //0: branch is not taken; 1: branch is taken
);

  logic [6:0] R_TYPE, I_TYPE_LOAD, I_TYPE_ARITH, S_TYPE, B_TYPE;

// Definições de opcodes
assign R_TYPE      = 7'b0110011;  // add, sub, and, or, etc.
assign I_TYPE_LOAD = 7'b0000011;  // lw
assign I_TYPE_ARITH= 7'b0010011;  // addi, andi, ori, etc.
assign S_TYPE      = 7'b0100011;  // sw
assign B_TYPE      = 7'b1100011;  // beq, bne, etc.

// Sinais de controle
assign ALUSrc   = (Opcode == I_TYPE_LOAD || Opcode == S_TYPE || Opcode == I_TYPE_ARITH);
assign MemtoReg = (Opcode == I_TYPE_LOAD);
assign RegWrite = (Opcode == R_TYPE || Opcode == I_TYPE_LOAD || Opcode == I_TYPE_ARITH);
assign MemRead  = (Opcode == I_TYPE_LOAD);
assign MemWrite = (Opcode == S_TYPE);  // Corrigido para S_TYPE
assign ALUOp[0] = (Opcode == B_TYPE);
assign ALUOp[1] = (Opcode == R_TYPE || Opcode == I_TYPE_ARITH);
assign Branch   = (Opcode == B_TYPE);


endmodule