//! @title Acumulador con seleccion de entrada
//! @file top.v
//! @author Julian Krede
//! @brief Top level del Ejercicio 1.
//!
//! En cada flanco ascendente de `clk` suma al valor acumulado (`o_data`) la
//! entrada elegida por `i_sel`:
//!
//! | `i_sel` | Valor sumado          |
//! |---------|-----------------------|
//! | `00`    | `i_data1`             |
//! | `01`    | `i_data1 + i_data2`   |
//! | `10`    | `i_data2`             |
//! | `11`    | `0` (se mantiene)     |
//!
//! La suma se realiza en 7 bits: los 6 bits inferiores se realimentan como
//! nuevo valor acumulado y el bit 6 se registra en `o_overflow`.
//!
//! **Camino de datos:**
//! `adder_4bits` -> `mux_3a1` -> `adder_7bits` -> `latch` -> (realimentacion a `adder_7bits`)
module top (

    input  [2:0] i_data1,    //! Primer dato de entrada (3 bits, sin signo)
    input  [2:0] i_data2,    //! Segundo dato de entrada (3 bits, sin signo)
    input  [1:0] i_sel,      //! Seleccion del valor a acumular
    input        clk,        //! Reloj del sistema, activo por flanco ascendente
    input        i_rst_n,    //! Reset asincronico, activo en bajo
    output [5:0] o_data,     //! Valor acumulado (6 bits)
    output       o_overflow  //! Indica que la ultima suma desbordo los 6 bits
);

    wire [3:0] o_sum1;   //! Salida del sumador de 4 bits (`i_data1 + i_data2`)
    wire [3:0] o_mux;    //! Valor seleccionado por el multiplexor
    wire [5:0] o_latch;  //! Valor acumulado realimentado al sumador de 7 bits
    wire [6:0] o_sum2;   //! Nuevo valor acumulado con el bit de overflow

    assign o_latch = o_data;

    //! Suma de las dos entradas de datos
    adder_4bits u_adder_4bits (
        .i_data1(i_data1),
        .i_data2(i_data2),
        .o_res  (o_sum1)
    );

    //! Seleccion del valor a acumular
    mux_3a1 u_mux_3a1 (
        .i_sel(i_sel),
        .i_in0(i_data1),
        .i_in1(o_sum1),
        .i_in2(i_data2),
        .o_out(o_mux)
    );

    //! Suma del valor seleccionado con el valor acumulado
    adder_7bits u_adder_7bits (
        .i_data1(o_mux),
        .i_data2(o_latch),
        .o_res  (o_sum2)
    );

    //! Registro del valor acumulado y del overflow
    latch u_latch (
        .i_sum     (o_sum2),
        .clk       (clk),
        .i_rst_n   (i_rst_n),
        .o_data    (o_data),
        .o_overflow(o_overflow)
    );

endmodule
