`timescale 1ns / 1ps

module imm_Gen (
    input  logic [31:0] inst_code,
    output logic [31:0] Imm_out
);

  always_comb begin
    case (inst_code[6:0])  // Opcode
      // I-type (loads, ops imediatas, jalr, shift imediato)
      7'b0000011, // LW
      7'b1100111: // JALR
        Imm_out = {{20{inst_code[31]}}, inst_code[31:20]};
      
      7'b0010011: begin // I-type: ADDI, ANDI, ORI, SLTI, SLLI, SRLI, SRAI
        case (inst_code[14:12]) // funct3
          3'b001, // SLLI
          3'b101: // SRLI, SRAI
            Imm_out = {{27{1'b0}}, inst_code[24:20]}; // shamt (zero-extended)
          default:
            Imm_out = {{20{inst_code[31]}}, inst_code[31:20]}; // padrão I-type
        endcase
      end

      // S-type (stores)
      7'b0100011: // SW
        Imm_out = {{20{inst_code[31]}}, inst_code[31:25], inst_code[11:7]};
      
      // B-type (branches)
      7'b1100011: // BEQ, BNE, BLT, BGE, etc.
        Imm_out = {{19{inst_code[31]}}, inst_code[31], inst_code[7], 
                   inst_code[30:25], inst_code[11:8], 1'b0};
      
      // J-type (jump)
      7'b1101111: // JAL
        Imm_out = {{11{inst_code[31]}}, inst_code[31], inst_code[19:12], 
                   inst_code[20], inst_code[30:21], 1'b0};
      
      // U-type (upper immediate)
      7'b0110111, // LUI
      7'b0010111: // AUIPC
        Imm_out = {inst_code[31:12], 12'b0};
      
      default: begin
        Imm_out = 32'hxxxxxxxx;  // Valor inválido para debug
        $display("Warning: Unknown instruction opcode in imm_Gen: %b", inst_code[6:0]);
      end
    endcase
  end

endmodule