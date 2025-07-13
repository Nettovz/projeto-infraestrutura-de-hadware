`timescale 1ns / 1ps

module BranchUnit #(
    parameter PC_W = 9
) (
    input  logic [PC_W-1:0] Cur_PC,
    input  logic [31:0]     Imm,
    input  logic            Branch,
    input  logic [31:0]     AluResult,
    output logic [31:0]     PC_Imm,
    output logic [31:0]     PC_Four,
    output logic [31:0]     BrPC,
    output logic            PcSel
);

  logic [31:0] PC_Full;
  logic        Branch_Taken;


 assign PC_Imm = Cur_PC + (Imm << 1);

  assign PC_Four  = PC_Full + 32'd4;

  assign Branch_Taken = Branch && (AluResult == 32'd1);
  assign PcSel = Branch_Taken; 
  assign BrPC  = Branch_Taken ? PC_Imm : 32'b0;

  // DEBUG: Mostra o alvo do salto quando ocorrer
  //always @(*) begin
    //if (Branch_Taken) begin
      //$display("[BRANCH] PC atual: %h | Alvo do salto: %h", PC_Full, PC_Imm);
      //$display("         (Offset do salto: %h)", Imm);
    //end
 // end
 

endmodule
