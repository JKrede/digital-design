//! @title Multiplicador por potencia de 2
//! @file mult_pot2.v
//! @author Julian Krede
//! @brief Escala una senal con signo por `2^-SHIFT` mediante un desplazamiento aritmetico.
//!
//! Implementa la multiplicacion por un coeficiente `0.5`, `0.25`, etc. sin
//! usar multiplicadores: desplaza la entrada `SHIFT` bits a la derecha
//! conservando el signo. Los bits descartados se truncan (redondeo hacia -inf).
//!
//! **Ecuacion:** `out = in >>> SHIFT = floor(in / 2^SHIFT)`
module mult_pot2 #(
    parameter WIDTH = 12,  //! Ancho en bits de la entrada y la salida
    parameter SHIFT = 1    //! Cantidad de bits a desplazar (coeficiente `2^-SHIFT`)
) (
    input  signed [WIDTH-1:0] in,  //! Senal de entrada (complemento a 2)
    output signed [WIDTH-1:0] out  //! Senal escalada (complemento a 2)
);

    assign out = in >>> SHIFT;

endmodule
