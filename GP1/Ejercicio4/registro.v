//! @title Registro con habilitacion
//! @file registro.v
//! @author Julian Krede
//! @brief Registro parametrizable con signo, habilitacion y reset asincronico.
//!
//! Implementa el retardo unitario `z^-1` del filtro. Captura `in` en el
//! flanco ascendente de `clk` cuando `en` esta en alto; si `en` esta en bajo
//! mantiene el valor anterior.
//!
//! {signal: [
//!   {name: 'clk',   wave: 'p......'},
//!   {name: 'rst_n', wave: '01.....'},
//!   {name: 'en',    wave: '1...0.1'},
//!   {name: 'in',    wave: 'x345.6.', data: ['A', 'B', 'C', 'D']},
//!   {name: 'out',   wave: '0.345..', data: ['A', 'B', 'C']}
//! ]}
module registro #(
    parameter WIDTH = 8  //! Ancho en bits del registro
) (
    input                         clk,    //! Reloj del sistema, activo por flanco ascendente
    input                         rst_n,  //! Reset asincronico, activo en bajo
    input                         en,     //! Habilitacion de escritura
    input  signed     [WIDTH-1:0] in,     //! Dato de entrada
    output reg signed [WIDTH-1:0] out     //! Dato registrado
);

    //! Actualizacion del registro: reset asincronico a cero y carga de `in`
    //! en el flanco ascendente de `clk` cuando `en` esta activo.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) out <= {WIDTH{1'b0}};
        else if (en) out <= in;
    end

endmodule
