//! @title Sumador/Restador con signo
//! @file sumador_restador.v
//! @author Julian Krede
//! @brief Suma o resta dos operandos con signo de anchos parametrizables.
//!
//! Ambos operandos se extienden en signo a `WIDTH_OUT` bits antes de operar.
//! Si `WIDTH_OUT` es mayor que el ancho de los operandos se evita el desborde;
//! si es menor, el resultado se trunca.
//!
//! | `sub` | `res`   |
//! |-------|---------|
//! | `0`   | `a + b` |
//! | `1`   | `a - b` |
module sumador_restador #(
    parameter WIDTH_A   = 8,  //! Ancho en bits del operando `a`
    parameter WIDTH_B   = 8,  //! Ancho en bits del operando `b`
    parameter WIDTH_OUT = 9   //! Ancho en bits del resultado
) (
    input  signed [  WIDTH_A-1:0] a,    //! Primer operando (complemento a 2)
    input  signed [  WIDTH_B-1:0] b,    //! Segundo operando (complemento a 2)
    input                         sub,  //! Operacion: 0 suma, 1 resta
    output signed [WIDTH_OUT-1:0] res   //! Resultado de la operacion (complemento a 2)
);

    // Aplica estension de signo a las entradas antes de sumar/restar
    wire signed [WIDTH_OUT-1:0] a_ext = a;  //! `a` extendido en signo a `WIDTH_OUT` bits
    wire signed [WIDTH_OUT-1:0] b_ext = b;  //! `b` extendido en signo a `WIDTH_OUT` bits

    assign res = sub ? (a_ext - b_ext) : (a_ext + b_ext);

endmodule
