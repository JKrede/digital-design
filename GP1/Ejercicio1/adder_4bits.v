//! @title Sumador de 4 bits
//! @file adder_4bits.v
//! @author Julian Krede
//! @brief Sumador sin signo de dos operandos de 3 bits.
//!
//! Extiende con ceros ambas entradas a 4 bits antes de sumar, de forma que
//! el bit mas significativo de `o_res` actua como acarreo de salida y el
//! resultado nunca desborda.
//!
//! **Ecuacion:** `o_res = i_data1 + i_data2`
module adder_4bits (
    input  [2:0] i_data1,  //! Primer operando (3 bits, sin signo)
    input  [2:0] i_data2,  //! Segundo operando (3 bits, sin signo)
    output [3:0] o_res     //! Resultado de la suma (4 bits, incluye el acarreo)
);

    wire [3:0] data1;  //! `i_data1` extendido con ceros a 4 bits
    wire [3:0] data2;  //! `i_data2` extendido con ceros a 4 bits
    assign data1 = {1'b0, i_data1};
    assign data2 = {1'b0, i_data2};
    assign o_res = data1 + data2;

endmodule
