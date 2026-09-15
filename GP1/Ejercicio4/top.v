//! @title Filtro IIR
//! @file top.v
//! @author Julian Krede
//! @brief Top level del Ejercicio 4: filtro IIR de orden 3 con coeficientes potencia de 2.
//!
//! ![Diagrama del filtro](filtro.png)
//!
//! **Ecuacion en diferencias:**
//!
//! `y[n] = x[n] - x[n-1] + x[n-2] + x[n-3] + 0.5 y[n-1] + 0.25 y[n-2]`
//!
//! - **Parte izquierda (FIR):** tres registros forman la linea de retardo de
//!   la entrada y tres sumadores/restadores calculan `x[n] - x[n-1] + x[n-2] + x[n-3]`.
//!   Cada etapa crece un bit para evitar desbordes.
//! - **Parte derecha (realimentacion):** dos registros retardan la salida,
//!   que se escala por `0.5` y `0.25` con desplazamientos aritmeticos y se suma.
//! - **Suma final:** combina ambas partes en `NB_Y + 1` bits; la salida se
//!   trunca a `NB_Y` bits.
//!
//! El camino de `x` a `y` es combinacional (sin latencia); solo las muestras
//! pasadas estan registradas.
module top #(
    parameter NB_X = 8,  //! Ancho en bits de la entrada `x`
    parameter NB_Y = 12  //! Ancho en bits de la salida `y`
) (
    input  wire                   clk,    //! Reloj del sistema, activo por flanco ascendente
    input  wire                   rst_n,  //! Reset asincronico, activo en bajo
    input  wire signed [NB_X-1:0] x,      //! Muestra de entrada `x[n]` (complemento a 2)
    output wire signed [NB_Y-1:0] y       //! Muestra de salida `y[n]` (complemento a 2)
);

    // --- Parte izquierda ---

    // Retardos de la entrada
    wire signed [NB_X-1:0] x1;  //! Entrada retardada una muestra `x[n-1]`
    wire signed [NB_X-1:0] x2;  //! Entrada retardada dos muestras `x[n-2]`
    wire signed [NB_X-1:0] x3;  //! Entrada retardada tres muestras `x[n-3]`

    // Sumas
    wire signed [  NB_X:0] s1;  //! `x[n] - x[n-1]`
    wire signed [NB_X+1:0] s2;  //! `x[n] - x[n-1] + x[n-2]`
    wire signed [NB_X+2:0] ff_sum;  //! Resultado de la parte izquierda: `x[n] - x[n-1] + x[n-2] + x[n-3]`


    //! Primera etapa: `x[n] - x[n-1]`
    sumador_restador #(
        .WIDTH_A  (NB_X),
        .WIDTH_B  (NB_X),
        .WIDTH_OUT(NB_X + 1)
    ) u_s1 (
        .a  (x),
        .b  (x1),
        .sub(1'b1),
        .res(s1)
    );

    //! Segunda etapa: `s1 + x[n-2]`
    sumador_restador #(
        .WIDTH_A  (NB_X + 1),
        .WIDTH_B  (NB_X),
        .WIDTH_OUT(NB_X + 2)
    ) u_s2 (
        .a  (s1),
        .b  (x2),
        .sub(1'b0),
        .res(s2)
    );

    //! Tercera etapa: `s2 + x[n-3]`
    sumador_restador #(
        .WIDTH_A  (NB_X + 2),
        .WIDTH_B  (NB_X),
        .WIDTH_OUT(NB_X + 3)
    ) u_s3 (
        .a  (s2),
        .b  (x3),
        .sub(1'b0),
        .res(ff_sum)
    );

    //! Retardo de la entrada: `x[n-1]`
    registro #(
        .WIDTH(NB_X)
    ) u_x1 (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (1'b1),
        .in   (x),
        .out  (x1)
    );

    //! Retardo de la entrada: `x[n-2]`
    registro #(
        .WIDTH(NB_X)
    ) u_x2 (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (1'b1),
        .in   (x1),
        .out  (x2)
    );

    //! Retardo de la entrada: `x[n-3]`
    registro #(
        .WIDTH(NB_X)
    ) u_x3 (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (1'b1),
        .in   (x2),
        .out  (x3)
    );
    // --- Fin parte izquierda ---


    // --- Parte derecha ---

    // Retardos de la salida
    wire signed [NB_Y-1:0] y1;  //! Salida retardada una muestra `y[n-1]`
    wire signed [NB_Y-1:0] y2;  //! Salida retardada dos muestras `y[n-2]`

    // Retardos de la salida escalados
    wire signed [NB_Y-1:0] half_y1;  //! `0.5 y[n-1]`
    wire signed [NB_Y-1:0] quarter_y2;  //! `0.25 y[n-2]`

    //sumas
    wire signed [  NB_Y:0] fb_sum;  //! Resultado de la parte derecha: `0.5 y[n-1] + 0.25 y[n-2]`

    //! Coeficiente 0.5 sobre `y[n-1]`
    mult_pot2 #(
        .WIDTH(NB_Y),
        .SHIFT(1)
    ) u_mul_05 (
        .in (y1),
        .out(half_y1)
    );

    //! Coeficiente 0.25 sobre `y[n-2]`
    mult_pot2 #(
        .WIDTH(NB_Y),
        .SHIFT(2)
    ) u_mul_025 (
        .in (y2),
        .out(quarter_y2)
    );

    //! Suma de la realimentacion: `half_y1 + quarter_y2`
    sumador_restador #(
        .WIDTH_A  (NB_Y),
        .WIDTH_B  (NB_Y),
        .WIDTH_OUT(NB_Y + 1)
    ) u_fb (
        .a  (half_y1),
        .b  (quarter_y2),
        .sub(1'b0),
        .res(fb_sum)
    );

    //! Retardo de la salida: `y[n-1]`
    registro #(
        .WIDTH(NB_Y)
    ) u_y1 (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (1'b1),
        .in   (y_next[NB_Y-1:0]),
        .out  (y1)
    );

    //! Retardo de la salida: `y[n-2]`
    registro #(
        .WIDTH(NB_Y)
    ) u_y2 (
        .clk  (clk),
        .rst_n(rst_n),
        .en   (1'b1),
        .in   (y1),
        .out  (y2)
    );
    // --- Fin parte derecha ---


    // Suma final
    wire signed [NB_Y:0] y_next;  //! Salida sin truncar: `ff_sum + fb_sum`

    //! Suma final de la parte izquierda y la parte derecha
    sumador_restador #(
        .WIDTH_A  (NB_X + 3),
        .WIDTH_B  (NB_Y + 1),
        .WIDTH_OUT(NB_Y + 1)
    ) u_final (
        .a  (ff_sum),
        .b  (fb_sum),
        .sub(1'b0),
        .res(y_next)
    );

    // Salida
    assign y = y_next[NB_Y-1:0];
endmodule
