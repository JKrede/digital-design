//! @title Multiplexor 3 a 1
//! @file mux_3a1.v
//! @author Julian Krede
//! @brief Multiplexor combinacional de 3 entradas con salida de 4 bits.
//!
//! Las entradas de 3 bits se extienden con ceros a 4 bits.
//!
//! | `i_sel` | `o_out`            |
//! |---------|--------------------|
//! | `00`    | `{1'b0, i_in0}`    |
//! | `01`    | `i_in1`            |
//! | `10`    | `{1'b0, i_in2}`    |
//! | `11`    | `0000`             |
module mux_3a1 (

    input      [1:0] i_sel,  //! Seleccion de la entrada
    input      [2:0] i_in0,  //! Entrada 0 (3 bits), seleccionada con `i_sel = 00`
    input      [3:0] i_in1,  //! Entrada 1 (4 bits), seleccionada con `i_sel = 01`
    input      [2:0] i_in2,  //! Entrada 2 (3 bits), seleccionada con `i_sel = 10`
    output reg [3:0] o_out   //! Salida seleccionada (4 bits)
);

    localparam SEL_0 = 2'b00;  //! Codigo de seleccion de `i_in0`
    localparam SEL_1 = 2'b01;  //! Codigo de seleccion de `i_in1`
    localparam SEL_2 = 2'b10;  //! Codigo de seleccion de `i_in2`

    //! Seleccion de la salida segun `i_sel`. Cualquier otro codigo
    //! (`11`) pone la salida en cero.
    always @(*) begin

        case (i_sel)
            SEL_0: o_out = {1'b0, i_in0};
            SEL_1: o_out = i_in1;
            SEL_2: o_out = {1'b0, i_in2};

            default: o_out = {4{1'b0}};

        endcase

    end

endmodule
