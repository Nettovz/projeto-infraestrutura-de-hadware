`timescale 1ns / 1ps

module riscv #(
    parameter DATA_W = 32
) (
    input  logic clk,
    input  logic reset,

    output logic [31:0] WB_Data,
    output logic [4:0]  reg_num,
    output logic [31:0] reg_data,
    output logic        reg_write_sig,
    output logic        wr,
    output logic        reade,
    output logic [8:0]  addr,
    output logic [DATA_W-1:0] wr_data,
    output logic [DATA_W-1:0] rd_data
);

  // Sinais de controle
  logic ALUSrc, MemtoReg, RegWrite, MemRead, MemWrite, Branch;
  logic [1:0] ALUop;
  logic [1:0] ALUop_Reg;
  logic [6:0] opcode;
  logic [6:0] Funct7;
  logic [2:0] Funct3;
  logic [3:0] Operation;
  logic       Jump;     // corrigido: 1 bit
  logic       Jalr;     // corrigido: 1 bit
  logic [1:0] WBSel;

  // Instância do Controller
  Controller c (
    .Opcode(opcode),
    .ALUSrc(ALUSrc),
    .MemtoReg(MemtoReg),
    .RegWrite(RegWrite),
    .MemRead(MemRead),
    .MemWrite(MemWrite),
    .ALUOp(ALUop),
    .Branch(Branch),
    .Jump(Jump),
    .Jalr(Jalr),
    .WBSel(WBSel)
  );

  // ALU Controller
  ALUController ac (
    .ALUOp(ALUop_Reg),
    .Funct7(Funct7),
    .Funct3(Funct3),
    .Operation(Operation)
  );

  // Datapath
  Datapath dp (
    .clk(clk),
    .reset(reset),
    .RegWrite(RegWrite),
    .MemtoReg(MemtoReg),
    .ALUsrc(ALUSrc),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .Branch(Branch),
    .WBSel(WBSel),
    .Jump(Jump),
    .Jalr(Jalr),
    .ALUOp(ALUop),
    .ALU_CC(Operation),
    .opcode(opcode),
    .Funct7(Funct7),
    .Funct3(Funct3),
    .ALUOp_Current(ALUop_Reg),
    .WB_Data(WB_Data),
    .reg_num(reg_num),
    .reg_data(reg_data),
    .reg_write_sig(reg_write_sig),
    .wr(wr),
    .reade(reade),
    .addr(addr),
    .wr_data(wr_data),
    .rd_data(rd_data)
  );

endmodule
