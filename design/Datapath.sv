`timescale 1ns / 1ps

import Pipe_Buf_Reg_PKG::*;

module Datapath #(
    parameter PC_W = 9,
    parameter INS_W = 32,
    parameter RF_ADDRESS = 5,
    parameter DATA_W = 32,
    parameter DM_ADDRESS = 9,
    parameter ALU_CC_W = 4
) (
    input  logic clk,
    reset,
    RegWrite,
    MemtoReg,
    ALUsrc,
    MemWrite,
    MemRead,
    Branch,
    input  logic [1:0] ALUOp,
    input  logic [ALU_CC_W -1:0] ALU_CC,
    output logic [6:0] opcode,
    output logic [6:0] Funct7,
    output logic [2:0] Funct3,
    output logic [1:0] ALUOp_Current,
    output logic [DATA_W-1:0] WB_Data,
    output logic [4:0] reg_num,
    output logic [DATA_W-1:0] reg_data,
    output logic reg_write_sig,
    output logic wr,
    output logic reade,
    output logic [DM_ADDRESS-1:0] addr,
    output logic [DATA_W-1:0] wr_data,
    output logic [DATA_W-1:0] rd_data
);

  logic [PC_W-1:0] PC, PCPlus4, Next_PC;
  logic [INS_W -1:0] Instr;
  logic [DATA_W-1:0] Reg1, Reg2;
  logic [DATA_W-1:0] ReadData;
  logic signed [DATA_W-1:0] SrcB, ALUResult;
  logic [DATA_W-1:0] ExtImm, BrImm, Old_PC_Four, BrPC;
  logic [DATA_W-1:0] WrmuxSrc;
  logic PcSel;
  logic PcSel_dly;
  logic flush_ID_EX;
  logic [1:0] FAmuxSel, FBmuxSel;
  logic [DATA_W-1:0] FAmux_Result, FBmux_Result;
  logic Reg_Stall;

  assign flush_ID_EX = PcSel;

  if_id_reg A;
  id_ex_reg B;
  ex_mem_reg C;
  mem_wb_reg D;

  adder #(9) pcadd (PC, 9'b100, PCPlus4);
  mux2 #(9) pcmux (PCPlus4, BrPC[PC_W-1:0], PcSel, Next_PC);
  flopr #(9) pcreg (clk, reset, Next_PC, Reg_Stall, PC);

  instructionmemory instr_mem (clk, PC, Instr);

  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      PcSel_dly <= 1'b0;
    else
      PcSel_dly <= PcSel;
  end

  always @(posedge clk) begin
    if (reset || PcSel_dly) begin
      A.Curr_Pc <= 0;
      A.Curr_Instr <= 0;
    end else if (!Reg_Stall) begin
      A.Curr_Pc <= PC;
      A.Curr_Instr <= Instr;
    end
  end

  HazardDetection detect (
    A.Curr_Instr[19:15],
    A.Curr_Instr[24:20],
    B.rd,
    B.MemRead,
    Reg_Stall
  );

  assign opcode = A.Curr_Instr[6:0];

  RegFile rf (
    clk,
    reset,
    D.RegWrite,
    D.rd,
    A.Curr_Instr[19:15],
    A.Curr_Instr[24:20],
    WrmuxSrc,
    Reg1,
    Reg2
  );

  assign reg_num = D.rd;
  assign reg_data = WrmuxSrc;
  assign reg_write_sig = D.RegWrite;

  imm_Gen Ext_Imm (A.Curr_Instr, ExtImm);

  always @(posedge clk) begin
    if (reset || Reg_Stall || flush_ID_EX) begin
      B.ALUSrc    <= 0;
      B.MemtoReg  <= 0;
      B.RegWrite  <= 0;
      B.MemRead   <= 0;
      B.MemWrite  <= 0;
      B.ALUOp     <= 0;
      B.Branch    <= 0;
      B.Curr_Pc   <= 0;
      B.RD_One    <= 0;
      B.RD_Two    <= 0;
      B.RS_One    <= 0;
      B.RS_Two    <= 0;
      B.rd        <= 0;
      B.ImmG      <= 0;
      B.func3     <= 0;
      B.func7     <= 0;
      B.Curr_Instr <= 0;
    end else begin
      B.ALUSrc    <= ALUsrc;
      B.MemtoReg  <= MemtoReg;
      B.RegWrite  <= RegWrite;
      B.MemRead   <= MemRead;
      B.MemWrite  <= MemWrite;
      B.ALUOp     <= ALUOp;
      B.Branch    <= Branch;
      B.Curr_Pc   <= A.Curr_Pc;
      B.RD_One    <= Reg1;
      B.RD_Two    <= Reg2;
      B.RS_One    <= A.Curr_Instr[19:15];
      B.RS_Two    <= A.Curr_Instr[24:20];
      B.rd        <= A.Curr_Instr[11:7];
      B.ImmG      <= ExtImm;
      B.func3     <= A.Curr_Instr[14:12];
      B.func7     <= A.Curr_Instr[31:25];
      B.Curr_Instr <= A.Curr_Instr;
    end
  end

  ForwardingUnit forunit (
    B.RS_One,
    B.RS_Two,
    C.rd,
    D.rd,
    C.RegWrite,
    D.RegWrite,
    FAmuxSel,
    FBmuxSel
  );

  assign Funct7 = B.func7;
  assign Funct3 = B.func3;
  assign ALUOp_Current = B.ALUOp;

  mux4 #(32) FAmux (B.RD_One, WrmuxSrc, C.Alu_Result, B.RD_One, FAmuxSel, FAmux_Result);
  mux4 #(32) FBmux (B.RD_Two, WrmuxSrc, C.Alu_Result, B.RD_Two, FBmuxSel, FBmux_Result);
  mux2 #(32) srcbmux (FBmux_Result, B.ImmG, B.ALUSrc, SrcB);

  alu alu_module (FAmux_Result, SrcB, ALU_CC, ALUResult);

  BranchUnit #(9) brunit (
    B.Curr_Pc,
    B.ImmG,
    B.Branch,
    ALUResult,
    BrImm,
    Old_PC_Four,
    BrPC,
    PcSel
  );

  always @(posedge clk) begin
    if (reset) begin
      C.RegWrite    <= 0;
      C.MemtoReg    <= 0;
      C.MemRead     <= 0;
      C.MemWrite    <= 0;
      C.Pc_Imm      <= 0;
      C.Pc_Four     <= 0;
      C.Imm_Out     <= 0;
      C.Alu_Result  <= 0;
      C.RD_Two      <= 0;
      C.rd          <= 0;
      C.func3       <= 0;
      C.func7       <= 0;
    end else begin
      C.RegWrite    <= B.RegWrite;
      C.MemtoReg    <= B.MemtoReg;
      C.MemRead     <= B.MemRead;
      C.MemWrite    <= B.MemWrite;
      C.Pc_Imm      <= BrImm;
      C.Pc_Four     <= Old_PC_Four;
      C.Imm_Out     <= B.ImmG;
      C.Alu_Result  <= ALUResult;
      C.RD_Two      <= FBmux_Result;
      C.rd          <= B.rd;
      C.func3       <= B.func3;
      C.func7       <= B.func7;
      C.Curr_Instr  <= B.Curr_Instr;
    end
  end

  datamemory data_mem (
    clk,
    C.MemRead,
    C.MemWrite,
    C.Alu_Result[8:0],
    C.RD_Two,
    C.func3,
    ReadData
  );

  assign wr       = C.MemWrite;
  assign reade    = C.MemRead;
  assign addr     = C.Alu_Result[8:0];
  assign wr_data  = C.RD_Two;
  assign rd_data  = ReadData;

  always @(posedge clk) begin
    if (reset) begin
      D.RegWrite      <= 0;
      D.MemtoReg      <= 0;
      D.Pc_Imm        <= 0;
      D.Pc_Four       <= 0;
      D.Imm_Out       <= 0;
      D.Alu_Result    <= 0;
      D.MemReadData   <= 0;
      D.rd            <= 0;
    end else begin
      D.RegWrite      <= C.RegWrite;
      D.MemtoReg      <= C.MemtoReg;
      D.Pc_Imm        <= C.Pc_Imm;
      D.Pc_Four       <= C.Pc_Four;
      D.Imm_Out       <= C.Imm_Out;
      D.Alu_Result    <= C.Alu_Result;
      D.MemReadData   <= ReadData;
      D.rd            <= C.rd;
      D.Curr_Instr    <= C.Curr_Instr;
    end
  end

  mux2 #(32) resmux (D.Alu_Result, D.MemReadData, D.MemtoReg, WrmuxSrc);

  assign WB_Data = WrmuxSrc;

endmodule
