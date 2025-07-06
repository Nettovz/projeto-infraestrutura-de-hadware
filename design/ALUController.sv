`timescale 1ns / 1ps

module ALUController (
    input logic [1:0] ALUOp,   // 00:mem 01:branch 10:R/I-type
    input logic [6:0] Funct7,
    input logic [2:0] Funct3,
    output logic [3:0] Operation
);
/// implementacao da decodificacao da instrucao, utilizando da funcao 3 e 7 para refinar e ter como saida o bit operation da instrucao necessaria
always_comb begin
    casez ({ALUOp, Funct7, Funct3})
        // Operações de Load/Store (soma de endereço)
        {2'b00, 7'b???????, 3'b???}: Operation = 4'b0010; // ADD para LW/SW
        
        // Operações de Branch
        {2'b01, 7'b???????, 3'b000}: Operation = 4'b1010; // BEQ
        {2'b01, 7'b???????, 3'b001}: Operation = 4'b1011; // BNE
        
        // Operações R-type e I-type
        {2'b10, 7'b0000000, 3'b000}: Operation = 4'b0010; // ADD/ADDI
        {2'b10, 7'b0100000, 3'b000}: Operation = 4'b0011; // SUB
        {2'b10, 7'b0000000, 3'b111}: Operation = 4'b0000; // AND/ANDI
        {2'b10, 7'b0000000, 3'b110}: Operation = 4'b0001; // OR/ORI
        {2'b10, 7'b0000000, 3'b100}: Operation = 4'b0110; // XOR/XORI
        {2'b10, 7'b???????, 3'b011}: Operation = 4'b1100; // SLTU/SLTIU
        {2'b10, 7'b0000000, 3'b001}: Operation = 4'b0100; // SLL/SLLI
        {2'b10, 7'b0000000, 3'b101}: Operation = 4'b0111; // SRL/SRLI
        {2'b10, 7'b0100000, 3'b101}: Operation = 4'b1000; // SRA/SRAI
        {2'b10, 7'b0000000, 3'b010}: Operation = 4'b0101; // SLT/SLTI
        {2'b10, 7'b???????, 3'b???}: Operation = 4'b1001; // NOR (default para outras I-type)
        
        default: Operation = 4'b0000; // Default para AND (pode ser alterado)
    endcase
end

endmodule