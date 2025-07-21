`timescale 1ns / 1ps

module BranchUnit #(
    parameter PC_W = 9  // largura do PC (bits)
) (
    input  logic [PC_W-1:0]   Cur_PC,     // PC atual (ex: 9 bits)
    input  logic signed [31:0] Imm,       // Immediate com sinal
    input  logic              Branch,     // Instrução de branch ativa
    input  logic [31:0]       AluResult,  // Resultado da ALU (1 = condição satisfeita)
    output logic [31:0]       PC_Imm,     // PC + offset (alvo do salto)
    output logic [31:0]       PC_Four,    // PC + 4 (próxima instrução normal)
    output logic [31:0]       BrPC,       // Endereço efetivo do salto
    output logic              PcSel       // Seleciona PC entre PC_Four (0) ou BrPC (1)
);

  logic [31:0] PC_Full;
  logic signed [31:0] Imm_shifted;
  logic        Branch_Taken;

  // Extensão zero do PC para 32 bits
  assign PC_Full = { {(32-PC_W){1'b0}}, Cur_PC };

  // PC + 4 bytes
  assign PC_Four = PC_Full + 32'd4;

  // Shift aritmético preservando o sinal (multiplica Imm por 2)
  assign Imm_shifted = Imm <<< 1;

  // PC + Imm (deslocamento em bytes)
  assign PC_Imm = PC_Full + Imm_shifted;

  // Branch é tomado se Branch ativo e ALU indicar condição verdadeira (ex: rs1==rs2)
  assign Branch_Taken = Branch && (AluResult == 32'd1);

  // Endereço de salto válido só se branch tomado
  assign BrPC = Branch_Taken ? PC_Imm : 32'b0;

  // Sinal para multiplexar PC
  assign PcSel = Branch_Taken;

  // Debug para mostrar salto
  //always @(*) begin
 //   if (Branch_Taken) begin
    //  $display("[BRANCH] PC atual       : 0x%08h", PC_Full);
   //   $display("[BRANCH] Offset (Imm)   : %0d (0x%08h)", Imm, Imm);
   //   $display("[BRANCH] Alvo do salto  : 0x%08h", PC_Imm);
  //  end
 // end

endmodule
