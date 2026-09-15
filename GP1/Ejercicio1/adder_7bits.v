//! @title Sumador de 7 bits
//! @file adder_7bits.v
//! @author Julian Krede
//! @brief Sumador sin signo de un operando de 4 bits y otro de 6 bits.
//!
//! El resultado se entrega en 7 bits: los 6 bits menos significativos son la
//! suma y el bit 6 indica el desborde respecto de 6 bits.
//!
//! **Ecuacion:** `o_res = i_data1 + i_data2`
module adder_7bits (
    input  [3:0] i_data1,  //! Primer operando (4 bits, sin signo)
    input  [5:0] i_data2,  //! Segundo operando (6 bits, sin signo)
    output [6:0] o_res     //! Resultado de la suma (7 bits, el bit 6 es el acarreo)
);

    assign o_res = i_data1 + i_data2;


endmodule
