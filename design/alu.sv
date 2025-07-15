`timescale 1ns / 1ps

module alu #(
    parameter DATA_WIDTH = 32,
    parameter OPCODE_LENGTH = 4
)(
    input logic [DATA_WIDTH-1:0] SrcA,
    input logic [DATA_WIDTH-1:0] SrcB,
    input logic [OPCODE_LENGTH-1:0] Operation,
    output logic [DATA_WIDTH-1:0] ALUResult
);

always_comb begin
    case(Operation)
        // Operações Lógicas
        4'b0000: ALUResult = SrcA & SrcB;        // AND/ANDI
        4'b0001: ALUResult = SrcA | SrcB;        // OR/ORI
        4'b0110: ALUResult = SrcA ^ SrcB;        // XOR/XORI
        4'b1001: ALUResult = ~(SrcA | SrcB);     // NOR
        
        // Operações Aritméticas
        4'b0010: ALUResult = $signed(SrcA) + $signed(SrcB);  // ADD/ADDI
        4'b0011: ALUResult = $signed(SrcA) - $signed(SrcB);  // SUB
        
        // Shifts
        4'b0100: ALUResult = SrcA << (SrcB[4:0] & 5'b11111);  // SLL/SLLI
        4'b0111: ALUResult = SrcA >> (SrcB[4:0] & 5'b11111);  // SRL/SRLI
        4'b1000: ALUResult = $signed(SrcA) >>> (SrcB[4:0] & 5'b11111); // SRA/SRAI
        
        // Comparações
        4'b0101: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 1 : 0; // SLT/SLTI
        4'b1100: ALUResult = (SrcA < SrcB) ? 1 : 0;  // SLTU/SLTIU
        4'b1010: ALUResult = (SrcA == SrcB) ? 1 : 0; // BEQ
        4'b1011: ALUResult = (SrcA != SrcB) ? 1 : 0; // BNE
        4'b1101: ALUResult = ($signed(SrcA) < $signed(SrcB)) ? 1 : 0; // BLT  
        4'b1110: ALUResult = ($signed(SrcA) >= $signed(SrcB)) ? 1 : 0; // BGE
        
        default: ALUResult = 0;
    endcase

    //if (Operation == 4'b1010 || Operation == 4'b1011 || Operation == 4'b1101 || Operation == 4'b1110) begin
      // $display("[ALU ] Time=%0t | Operation=%b | SrcA=0x%08h (%0d) | SrcB=0x%08h (%0d) | ALUResult=%0d", 
         //  $time, Operation, SrcA, $signed(SrcA), SrcB, $signed(SrcB), ALUResult);
    //end
end

endmodule
