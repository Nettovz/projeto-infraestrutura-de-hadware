  `timescale 1ns / 1ps

  module BranchUnit #(
      parameter PC_W = 9  // largura do PC (bits)
  ) (
      input  logic [PC_W-1:0]   Cur_PC,     // PC atual (ex: 9 bits)
      input  logic signed [31:0] Imm,       // Immediate com sinal
      input  logic              Branch,     // Instrução de branch ativa
      input  logic              jal,        // Indica salto jal
      input  logic              jalr,       // Indica salto jalr
      input  logic [31:0]       AluResult,  // Resultado da ALU
                                          // - Para branch: flag 1 (condição verdadeira)
                                          // - Para jalr: endereço calculado (rs1+imm)
      output logic [31:0]       PC_Imm,     // PC + offset (alvo do salto)
      output logic [31:0]       PC_Four,    // PC + 4 (próxima instrução sequencial)
      output logic [31:0]       BrPC,       // Endereço efetivo do salto (branch/jal/jalr)
      output logic              PcSel       // Sinal que seleciona entre PC_Four (0) ou BrPC (1)
  );

    // Expande PC curto para 32 bits (com zeros à esquerda)
    logic [31:0] PC_Full;
    assign PC_Full = { {(32-PC_W){1'b0}}, Cur_PC };

    // PC + 4 (próximo endereço sequencial)
    assign PC_Four = PC_Full + 32'd4;

    // Immediate deslocado à esquerda por 1 (multiplica por 2 para byte offset)
    logic signed [31:0] Imm_shifted;
    assign Imm_shifted = Imm <<< 1;

    // Cálculo do endereço do salto para branch e jal
    assign PC_Imm = PC_Full + Imm_shifted;

    // Condição para branch: deve estar ativo o sinal Branch e ALU sinalizar condição verdadeira (flag == 1)
    logic Branch_Taken;
    assign Branch_Taken = Branch && (AluResult == 32'd1);

    // Endereço do salto efetivo:
    // Para jalr: usa AluResult alinhado (bit 0 sempre zero)
    // Para jal e branch: usa PC + immediate (PC_Imm)
    assign BrPC = (jalr) ? {AluResult[31:1], 1'b0} : PC_Imm;

    // Sinal para escolher o PC:
    // PcSel = 1 quando qualquer salto ou branch for tomado
    assign PcSel = Branch_Taken | jal | jalr;

    // Debug (imprime informações durante simulação)
    always @(*) begin
      if (Branch_Taken) begin
        $display("[BRANCH] PC atual       : 0x%08h", PC_Full);
        $display("[BRANCH] Offset (Imm)   : %0d (0x%08h)", Imm, Imm);
        $display("[BRANCH] Alvo do salto  : 0x%08h", PC_Imm);
      end
      if (jal) begin
        $display("[JAL   ] PC atual       : 0x%08h", PC_Full);
      $display("[JAL   ] Offset (Imm)   : %0d (0x%08h)", Imm, Imm);
      $display("[JAL   ] Alvo do salto  : 0x%08h", PC_Imm);
      end
      if (jalr) begin
      $display("[JALR  ] rs1 + Imm (ALU): 0x%08h", AluResult);
        $display("[JALR  ] Alvo alinhado  : 0x%08h", {AluResult[31:1], 1'b0});
      end
    end

  endmodule
