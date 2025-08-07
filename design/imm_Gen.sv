`timescale 1ns / 1ps

module imm_Gen (
    input  logic [31:0] inst_code,
    output logic signed [31:0] Imm_out
);

always_comb begin
    case (inst_code[6:0])  // Opcode
        7'b0000011, // LW
        7'b1100111: // JALR
            begin
                Imm_out = {{20{inst_code[31]}}, inst_code[31:20]};
                $display("[IMM_GEN] LW/JALR Imm gerado: %08x", Imm_out);
            end

        7'b0010011: begin // I-type (ex: ADDI, SLTI, SLLI, SRLI, etc)
            case (inst_code[14:12]) // funct3
                3'b001, // SLLI
                3'b101: // SRLI, SRAI
                    begin
                        Imm_out = {{27{1'b0}}, inst_code[24:20]};
                        $display("[IMM_GEN] SHIFT Imm gerado: %08x", Imm_out);
                    end
                default:
                    begin
                        Imm_out = {{20{inst_code[31]}}, inst_code[31:20]};
                        $display("[IMM_GEN] I-type Imm gerado: %08x", Imm_out);
                    end
            endcase
        end

        7'b0100011: // S-type (ex: SW, SB)
            begin
                Imm_out = {{20{inst_code[31]}}, inst_code[31:25], inst_code[11:7]};
                $display("[IMM_GEN] SW Imm gerado: %08x", Imm_out);
            end

        7'b1100011: begin // B-type (ex: BEQ, BNE, etc)
            Imm_out = {{20{inst_code[31]}}, inst_code[7], inst_code[30:25], inst_code[11:8], 1'b0};
            $display("[IMM_GEN] B-type Imm gerado: %08x, Opcode: %07b, funct3: %03b", Imm_out, inst_code[6:0], inst_code[14:12]);
        end

        7'b1101111: begin // J-type (ex: JAL)
            Imm_out = {{11{inst_code[31]}}, inst_code[31], inst_code[19:12], inst_code[20], inst_code[30:21], 1'b0};
            $display("[IMM_GEN] J-type Imm gerado: %08x, Opcode: %07b", Imm_out, inst_code[6:0]);
        end

        7'b0110111, // LUI
        7'b0010111: // AUIPC
            begin
                Imm_out = {inst_code[31:12], 12'b0};
                $display("[IMM_GEN] U-type Imm gerado: %08x", Imm_out);
            end

        7'b0110011: begin // R-type (ex: ADD, SUB, AND, etc)
            Imm_out = 32'd0;  // Não possui imediato
            $display("[IMM_GEN] R-type sem Imm, Opcode: %07b", inst_code[6:0]);
        end

        default: begin
            Imm_out = 32'd0;  // Evita indefinido
            //$display("[IMM_GEN] Opcode desconhecido: %07b", inst_code[6:0]);
        end
    endcase
end

endmodule
