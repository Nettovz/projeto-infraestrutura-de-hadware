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
    input logic [1:0] WBSel,   //  usando no mux final
    input logic [1:0] Jump,     // usando na passagem de estagios do pipeline
    input logic [1:0] Jalr,    // usando na passagem dos estagios do pipeline
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

  // Sinais intermediários
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

  // IF: Determina se o estágio ID deve ser limpo
  assign flush_ID_EX = PcSel;

  // Registradores de pipeline
  if_id_reg A;     // IF/ID
  id_ex_reg B;     // ID/EX
  ex_mem_reg C;    // EX/MEM
  mem_wb_reg D;    // MEM/WB

  // === IF (Instruction Fetch) ===
  adder #(9) pcadd (PC, 9'b100, PCPlus4);  // PC + 4
  mux2 #(9) pcmux (PCPlus4, BrPC[PC_W-1:0], PcSel, Next_PC);  // Escolhe próximo PC
  flopr #(9) pcreg (clk, reset, Next_PC, Reg_Stall, PC);      // Atualiza PC
  instructionmemory instr_mem (clk, PC, Instr);               // Busca instrução

  // Delay para flush do estágio ID
  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      PcSel_dly <= 1'b0;
    else
      PcSel_dly <= PcSel;
  end

  // IF/ID pipeline register
  always @(posedge clk) begin
    if (reset || PcSel_dly) begin
      A.Curr_Pc <= 0;
      A.Curr_Instr <= 0;
    end else if (!Reg_Stall) begin
      A.Curr_Pc <= PC;
      A.Curr_Instr <= Instr;
    end
  end

  // Detecção de hazards
  HazardDetection detect (
    A.Curr_Instr[19:15],
    A.Curr_Instr[24:20],
    B.rd,
    B.MemRead,
    Reg_Stall
  );

  // Extrai opcode para o controle
  assign opcode = A.Curr_Instr[6:0];

  // === ID (Instruction Decode) ===
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

  // Geração de imediato
  imm_Gen Ext_Imm (A.Curr_Instr, ExtImm);
    
  

  // ID/EX pipeline register
  always @(posedge clk) begin
    if (reset || Reg_Stall || flush_ID_EX) begin
      B.ALUSrc    <= 0;
      B.MemtoReg  <= 0;
      B.RegWrite  <= 0;
      B.MemRead   <= 0;
      B.MemWrite  <= 0;
      B.ALUOp     <= 0;
      B.Branch    <= 0;
      B.WBSel  <= 0;/////
      B.Jump    <= 0;/////
      B.Jalr   <= 0;/////
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
      B.WBSel  <= WBSel;/////
      B.Jump    <= Jump;  /////
      B.Jalr   <= Jalr;  /////
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

  // Encaminhamento (forwarding)
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

  // === EX (Execute) ===
  mux4 #(32) FAmux (B.RD_One, WrmuxSrc, C.Alu_Result, B.RD_One, FAmuxSel, FAmux_Result);
  mux4 #(32) FBmux (B.RD_Two, WrmuxSrc, C.Alu_Result, B.RD_Two, FBmuxSel, FBmux_Result);
  mux2 #(32) srcbmux (FBmux_Result, B.ImmG, B.ALUSrc, SrcB);

  alu alu_module (FAmux_Result, SrcB, ALU_CC, ALUResult);

BranchUnit #(9) brunit (
    B.Curr_Pc,       // .Cur_PC
    B.ImmG,          // .Imm
    B.Branch,        // .Branch
    B.Jump,           // .Jump. // pq tem essas entradas sendo q ja recebo input do controller dos sinais de Jump e Jalr
    B.Jalr,          // .Jalr. 
    ALUResult,       // .AluResult
    BrImm,           // .PC_Imm
    Old_PC_Four,     // .PC_Four
    BrPC,            // .BrPC
    PcSel            // .PcSel
);

  // EX/MEM pipeline register
  always @(posedge clk) begin
    if (reset) begin
     C.WBSel  <= 0;/////
      C.Jump    <= 0;/////
      C.Jalr   <= 0;/////
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
     C.WBSel  <= B.WBSel;/////
      C.Jump    <= B.Jump;/////
      C.Jalr   <= B.Jalr;/////
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

  // === MEM (Memory Access) ===
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

  // MEM/WB pipeline register
  always @(posedge clk) begin
    if (reset) begin
      D.WBSel        <= 0;///
       D.Jump          <= 0;///
      D.Jalr         <= 0; //
      D.RegWrite      <= 0;
      D.MemtoReg      <= 0;
      D.Pc_Imm        <= 0;
      D.Pc_Four       <= 0;
      D.Imm_Out       <= 0;
      D.Alu_Result    <= 0;
      D.MemReadData   <= 0;
      D.rd            <= 0;
    end else begin
      D.WBSel        <= C.WBSel;///
      D.Jump          <= C.Jump;//
      D.Jalr         <= C.Jalr;///
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

  // === WB (Write Back) ===
  // Sinais intermediários
logic [31:0] muxA_out;


// Primeiro mux: escolhe entre ALUResult e MemReadData
mux2 #(32) mux_A (
    .A(D.Alu_Result),
    .B(D.MemReadData),
    .Sel(D.WBSel[0]),    // bit menos significativo
    .Out(muxA_out)
);

// Segundo mux: escolhe entre resultado anterior e PC+4
mux2 #(32) mux_B (
    .A(muxA_out),
    .B(D.Pc_Four),
    .Sel(D.WBSel[1]),    // bit mais significativo
    .Out(WrmuxSrc)
);

// Atribuição final ao dado que será escrito no banco de registradores
assign WB_Data = WrmuxSrc;

// Debug IF/ID
always_ff @(posedge clk) begin
  if (!reset) begin
   // $display("[IF/ID] Time=%0t PC=0x%h Instr=0x%h Opcode=0x%h", $time, A.Curr_Pc, A.Curr_Instr, A.Curr_Instr[6:0]);
  end
end

// Debug ID/EX
always_ff @(posedge clk) begin
  if (!reset) begin
  //  $display("[ID/EX] Time=%0t ALUSrc=%b WBSel=%b Jump=%b Jalr=%b rd=%0d Imm=0x%h", $time,
   //          B.ALUSrc, B.WBSel, B.Jump, B.Jalr, B.rd, B.ImmG);
  end
end

// Debug EX/MEM
always_ff @(posedge clk) begin
  if (!reset) begin
   // $display("[EX/MEM] Time=%0t RegWrite=%b MemRead=%b MemWrite=%b AluRes=0x%h rd=%0d", $time,
   //          C.RegWrite, C.MemRead, C.MemWrite, C.Alu_Result, C.rd);
  end
end

// Debug MEM/WB
always_ff @(posedge clk) begin
  if (!reset) begin
  //  $display("[MEM/WB] Time=%0t WBSel=%b Jump=%b Jalr=%b RegWrite=%b MemtoReg=%b rd=%0d WB_Data=0x%h", $time,
 //            D.WBSel, D.Jump, D.Jalr, D.RegWrite, D.MemtoReg, D.rd, WB_Data);
  end
end

endmodule
