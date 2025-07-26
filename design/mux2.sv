module mux2 #(
    parameter WIDTH = 32
) (
    input logic [WIDTH-1:0] A,
    input logic [WIDTH-1:0] B,
    input logic Sel,
    output logic [WIDTH-1:0] Out
);

  assign Out = Sel ? B : A;

endmodule
