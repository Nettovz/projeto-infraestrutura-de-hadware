`timescale 1ns / 1ps

module BranchUnit #(
    parameter PC_W = 9
) (
    input  logic [PC_W-1:0] Cur_PC,
    input  logic [31:0]     Imm,
    input  logic            Branch,    // desvio condicional
    input  logic            Jump,      // salto incondicional jal
    input  logic            Jalr,      // salto incondicional jalr
    input  logic [31:0]     AluResult, // resultado da ALU (para branch e jalr)
    output logic [31:0]     PC_Imm,
    output logic [31:0]     PC_Four,
    output logic [31:0]     BrPC,
    output logic            PcSel
);

  logic Branch_Sel;
  logic Jump_Sel;
  logic [31:0] PC_Full;

  assign PC_Full  = {23'b0, Cur_PC};
  assign PC_Imm   = PC_Full + Imm;
  assign PC_Four  = PC_Full + 32'd4;

  // Seleciona branch se sinal de branch ativo e ALU indicar condição verdadeira
  assign Branch_Sel = Branch && AluResult[0];

  // Sinal para salto incondicional (jal ou jalr)
  assign Jump_Sel = Jump || Jalr;

  // BrPC é o próximo PC de salto: ou branch ou jump
  assign BrPC = Branch_Sel ? PC_Imm :
               Jump_Sel ? PC_Imm : 32'b0;

  // PcSel habilita mudança do PC (se salto ou branch tomado)
  assign PcSel = Branch_Sel || Jump_Sel;

  // Debug
  always_comb begin
    if (Jump || Jalr) begin
      $display("[BranchUnit] PC=%h | Imm=%h | ALU=%h | Branch=%b | Jump=%b | Jalr=%b | PcSel=%b | PC_Imm=%h | PC+4=%h | BrPC=%h",
               PC_Full, Imm, AluResult, Branch, Jump, Jalr, PcSel, PC_Imm, PC_Four, BrPC);
    end
  end

endmodule  
