`timescale 1ns / 1ps

module imm_Gen (
    input  logic [31:0] inst_code,
    output logic signed [31:0] Imm_out
);

 always_comb begin
  case (inst_code[6:0])  // Opcode
    7'b0000011, // LW
    7'b1100111: // JALR
      Imm_out = {{20{inst_code[31]}}, inst_code[31:20]};
    
    7'b0010011: begin // I-type
      case (inst_code[14:12]) // funct3
        3'b001, // SLLI
        3'b101: // SRLI, SRAI
          Imm_out = {{27{1'b0}}, inst_code[24:20]};
        default:
          Imm_out = {{20{inst_code[31]}}, inst_code[31:20]};
      endcase
    end

    7'b0100011: // S-type (stores)
      Imm_out = {{20{inst_code[31]}}, inst_code[31:25], inst_code[11:7]};
    
    7'b1100011: // B-type (branches)
      Imm_out = {{19{inst_code[31]}}, inst_code[31], inst_code[7], 
                 inst_code[30:25], inst_code[11:8], 1'b0};
    
    7'b1101111: // J-type (jump)
      Imm_out = {{11{inst_code[31]}}, inst_code[31], inst_code[19:12], 
                 inst_code[20], inst_code[30:21], 1'b0};
    
    7'b0110111, // LUI
    7'b0010111: // AUIPC
      Imm_out = {inst_code[31:12], 12'b0};

    7'b0110011: // R-type (add, sub, xor, or, and...)
      Imm_out = 32'd0;  // Sem imediato
    
    default: begin
      Imm_out = 32'd0;  // Melhor evitar indefinido
      $display("Warning: Unknown instruction opcode in imm_Gen: %b", inst_code[6:0]);
    end
  endcase
end


endmodule