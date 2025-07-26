`timescale 1ns / 1ps

module Controller (
    input logic [6:0] Opcode,

    output logic ALUSrc,
    output logic MemtoReg,
    output logic RegWrite,
    output logic MemRead,
    output logic MemWrite,
    output logic [1:0] ALUOp,
    output logic Branch,
   output logic Jump,  // 1 bit apenas
    output logic Jalr,s  // 1 bit apenas
    output logic [1:0] WBSel
);

  localparam R_TYPE      = 7'b0110011;
  localparam I_TYPE_LOAD = 7'b0000011;
  localparam I_TYPE_ARITH= 7'b0010011;
  localparam S_TYPE      = 7'b0100011;
  localparam B_TYPE      = 7'b1100011;
  localparam J_TYPE      = 7'b1101111;
  localparam JALR_TYPE   = 7'b1100111;

  assign ALUSrc   = (Opcode == I_TYPE_LOAD || Opcode == S_TYPE || Opcode == I_TYPE_ARITH || Opcode == JALR_TYPE);
  assign MemtoReg = (Opcode == I_TYPE_LOAD);
  assign RegWrite = (Opcode == R_TYPE || Opcode == I_TYPE_LOAD || Opcode == I_TYPE_ARITH || Opcode == J_TYPE || Opcode == JALR_TYPE);
  assign MemRead  = (Opcode == I_TYPE_LOAD);
  assign MemWrite = (Opcode == S_TYPE);
  assign ALUOp[0] = (Opcode == B_TYPE);
  assign ALUOp[1] = (Opcode == R_TYPE || Opcode == I_TYPE_ARITH);
  assign Branch   = (Opcode == B_TYPE);
  assign Jump     = (Opcode == J_TYPE);
  assign Jalr     = (Opcode == JALR_TYPE);
  assign WBSel = (Opcode == I_TYPE_LOAD) ? 2'b01 :
                 ((Opcode == J_TYPE || Opcode == JALR_TYPE) ? 2'b10 : 2'b00);

  // Bloco separado só para debug (imprime sempre que Opcode mudar)
  always_comb begin
    case (Opcode)
      7'b1101111:  // jal
        $display("[Controller] Time=%0t | Detected JAL  | WBSel=%b", $time, WBSel);
      7'b1100111:  // jalr
        $display("[Controller] Time=%0t | Detected JALR | WBSel=%b", $time, WBSel);
      default: ;
    endcase
  end

endmodule
