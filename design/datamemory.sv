`timescale 1ns / 1ps

module datamemory #(
    parameter DM_ADDRESS = 9,
    parameter DATA_W = 32
) (
    input logic clk,
    input logic MemRead,   // control unit signal
    input logic MemWrite,  // control unit signal
    input logic [DM_ADDRESS - 1:0] a,  // address (9 bits)
    input logic [DATA_W - 1:0] wd,     // write data
    input logic [2:0] Funct3,           // funct3 bits from instruction
    output logic [DATA_W - 1:0] rd     // read data output
);

  logic [31:0] raddress;
  logic [31:0] waddress;
  logic [31:0] Datain;
  logic [31:0] Dataout;
  logic [ 3:0] Wr;

  Memoria32Data mem32 (
      .raddress(raddress),
      .waddress(waddress),
      .Clk(~clk),
      .Datain(Datain),
      .Dataout(Dataout),
      .Wr(Wr)
  );

  always_comb begin
    raddress = {{22{1'b0}}, a};
    waddress = {{22{1'b0}}, {a[8:2], 2'b00}};
    Datain = 32'b0;  // limpar antes de atribuições parciais
    Wr = 4'b0000;
    rd = 32'b0;

    if (MemRead) begin
      case (Funct3)
        3'b010: rd = Dataout;                   // LW  - Load Word (32 bits com sinal)
        3'b000: rd = $signed(Dataout[7:0]);    // LB  - Load Byte (8 bits com sinal)
        3'b001: rd = $signed(Dataout[15:0]);   // LH  - Load Halfword (16 bits com sinal)
        3'b100: rd = {24'b0, Dataout[7:0]};    // LBU - Load Byte Unsigned
        default: rd = Dataout;                  // default (pode ajustar se precisar)
      endcase
    end else if (MemWrite) begin
      case (Funct3)
        3'b010: begin                          // SW - Store Word (32 bits)
          Wr = 4'b1111;
          Datain = wd;
        end
        3'b000: begin                          // SB - Store Byte (8 bits)
          Wr = 4'b0001;
          Datain[7:0] = wd[7:0];
        end
        3'b001: begin                          // SH - Store Halfword (16 bits)
          Wr = 4'b0011;
          Datain[15:0] = wd[15:0];
        end
        default: begin
          Wr = 4'b1111;
          Datain = wd;
        end
      endcase
    end
  end

endmodule
