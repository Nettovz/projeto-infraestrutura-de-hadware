`timescale 1ns / 1ps

module datamemory #(
    parameter DM_ADDRESS = 9,
    parameter DATA_W = 32
) (
    input  logic clk,
    input  logic MemRead,   // Sinal de leitura da unidade de controle
    input  logic MemWrite,  // Sinal de escrita da unidade de controle
    input  logic [DM_ADDRESS - 1:0] a,      // Endereço de acesso à memória
    input  logic [DATA_W - 1:0]     wd,     // Dado a ser escrito
    input  logic [2:0]              Funct3, // Campo funct3 da instrução
    output logic [DATA_W - 1:0]     rd      // Saída de leitura
);

  logic [31:0] raddress;
  logic [31:0] waddress;
  logic [31:0] Datain;
  logic [31:0] Dataout;
  logic [ 3:0] Wr;

  // Deslocamento dentro da palavra (para acesso byte/halfword)
  logic [1:0] byte_offset;
  assign byte_offset = a[1:0];

  // Instância da memória de dados (palavra de 32 bits)
  Memoria32Data mem32 (
      .raddress(raddress),
      .waddress(waddress),
      .Clk(~clk),       // Clock invertido para memória (caso necessário)
      .Datain(Datain),
      .Dataout(Dataout),
      .Wr(Wr)
  );

  always_comb begin
    raddress = {{22{1'b0}}, a[8:2]};  // Alinha para palavra de 32 bits (endereço dividido por 4)
    waddress = raddress;
    Datain   = 32'b0;
    Wr       = 4'b0000;
    rd       = 32'b0;

    // --- LEITURA ---
    if (MemRead) begin
      case (Funct3)
        3'b010: rd = Dataout; // LW

        3'b000: begin // LB
          case (byte_offset)
            2'b00: rd = $signed(Dataout[7:0]);
            2'b01: rd = $signed(Dataout[15:8]);
            2'b10: rd = $signed(Dataout[23:16]);
            2'b11: rd = $signed(Dataout[31:24]);
          endcase
        end

        3'b001: begin // LH
          case (byte_offset[1])
            1'b0: rd =  $signed(Dataout[15:0]);
            1'b1: rd = $signed(Dataout[31:16]);
          endcase
        end

        3'b100: begin // LBU
          case (byte_offset)
            2'b00: rd = {24'b0, Dataout[7:0]};
            2'b01: rd = {24'b0, Dataout[15:8]};
            2'b10: rd = {24'b0, Dataout[23:16]};
            2'b11: rd = {24'b0, Dataout[31:24]};
          endcase
        end

        default: rd = Dataout; // fallback
      endcase

    end

    // --- ESCRITA ---
    else if (MemWrite) begin
      case (Funct3)
        3'b010: begin // SW
          Wr     = 4'b1111;
          Datain = wd;
        end

        3'b000: begin // SB
          case (byte_offset)
            2'b00: Wr = 4'b0001;
            2'b01: Wr = 4'b0010;
            2'b10: Wr = 4'b0100;
            2'b11: Wr = 4'b1000;
          endcase
          Datain = {4{wd[7:0]}}; // Replica o byte para toda a palavra (evita lixo)
        end

        3'b001: begin // SH
          case (byte_offset[1])
            1'b0: Wr = 4'b0011;
            1'b1: Wr = 4'b1100;
          endcase
          Datain = {2{wd[15:0]}};
        end

        default: begin 
          Wr     = 4'b1111;
          Datain = wd;
        end
      endcase
    end
  end
endmodule
