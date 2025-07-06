`timescale 1ns / 1ps

module imm_Gen (
    input  logic [31:0] inst_code,
    output logic [31:0] Imm_out
);

  always_comb begin
    case (inst_code[6:0])  // Opcode
      // I-type (loads, immediate ops, jalr)
      7'b0000011, // LW
      7'b1100111: // JALR
        Imm_out = {{20{inst_code[31]}}, inst_code[31:20]};
      
     7'b0010011: begin // I-type
    case (inst_code[14:12])
      3'b001: // SLLI
        Imm_out = {27'b0, inst_code[24:20]};
      3'b101: // SRLI/SRAI
        // Distingue SRLI (funct7=0000000) de SRAI (funct7=0100000)
        Imm_out = {27'b0, inst_code[24:20]};
      default: // Outras I-type
        Imm_out = {{20{inst_code[31]}}, inst_code[31:20]};
    endcase
end

      // S-type (stores)
      7'b0100011: // SW
        Imm_out = {{20{inst_code[31]}}, inst_code[31:25], inst_code[11:7]};
      
      // B-type (branches)
      7'b1100011: // BEQ, BNE, etc.
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
        Imm_out = 32'b0;  // Default to 0 instead of 'x' for synthesis
        $display("Warning: Unknown instruction opcode in imm_Gen: %07b", inst_code[6:0]);
      end
    endcase
  end

endmodule