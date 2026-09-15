//! @title Registro de acumulacion
//! @file latch.v
//! @author Julian Krede
//! @brief Registro sincronico que almacena la suma y la bandera de overflow.
//!
//! Separa la entrada de 7 bits en el dato (bits 5..0) y el overflow (bit 6)
//! y los registra en el flanco ascendente de `clk`. Posee reset asincronico
//! activo en bajo que pone ambas salidas en cero.
//!
//! **Nota:** a pesar del nombre, el elemento de memoria es un flip-flop
//! sensible a flanco, no un latch sensible a nivel.
//!
//! {signal: [
//!   {name: 'clk',        wave: 'p.....'},
//!   {name: 'i_rst_n',    wave: '01....'},
//!   {name: 'i_sum',      wave: 'x3.4.5', data: ['A', 'B', 'C']},
//!   {name: 'o_data',     wave: '0.3.4.', data: ['A[5:0]', 'B[5:0]']},
//!   {name: 'o_overflow', wave: '0.3.4.', data: ['A[6]', 'B[6]']}
//! ]}
module latch (
    input      [6:0] i_sum,      //! Suma a registrar (bit 6: overflow, bits 5..0: dato)
    input            clk,        //! Reloj del sistema, activo por flanco ascendente
    input            i_rst_n,    //! Reset asincronico, activo en bajo
    output reg [5:0] o_data,     //! Dato registrado (6 bits)
    output reg       o_overflow  //! Bandera de overflow registrada
);
    reg [5:0] sum;  //! Parte de dato de `i_sum` (bits 5..0)
    reg       ovf;  //! Bit de overflow de `i_sum` (bit 6)

    //! Logica combinacional: separa la entrada en dato y overflow.
    always @(*) begin

        sum = i_sum[5:0];
        ovf = i_sum[6];
    end

    //! Logica secuencial: registra el dato y el overflow en cada flanco
    //! ascendente de `clk`. El reset asincronico limpia ambas salidas.
    always @(posedge clk or negedge i_rst_n) begin

        if (~i_rst_n) begin
            o_data     <= {6{1'b0}};
            o_overflow <= 1'b0;
        end else begin
            o_data     <= sum;
            o_overflow <= ovf;
        end
    end

endmodule
