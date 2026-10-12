`timescale 1ns / 100ps

// En una placa con un clk de 100MHz el periodo es 10ns
// (#n: n timescale de espera)

//! @title Testbench del Ejercicio 1
//! @file tb_top.v
//! @author Julian Krede
//! @brief Testbench del acumulador `top`.
//!
//! Genera un reloj de 10 ns (100 MHz), aplica un reset inicial y recorre
//! distintas combinaciones de entradas, manteniendo cada una durante 10 us:
//!
//! 1. `i_data1 = 1`, `i_data2 = 1`, `i_sel = 01`: medicion de ciclos hasta el overflow.
//! 2. `i_data2 = 2`, `i_sel = 10`: mitad del rango de `i_data2`.
//! 3. `i_data1 = 2`, `i_sel = 00`: mitad del rango de `i_data1`.
//! 4. `i_data1 = 7`, `i_sel = 00`: maximo valor de `i_data1`.
//! 5. `i_data2 = 7`, `i_sel = 10`: maximo valor de `i_data2`.
//! 6. `i_sel = 11`: el valor sumado es 0 y la salida se mantiene.
module tb_top ();

    // Salidas (siempre wire)
    wire [5:0] o_data;      //! Valor acumulado entregado por el DUT
    wire       o_overflow;  //! Bandera de overflow entregada por el DUT

    // Entradas (simpre reg)
    reg  [2:0] i_data1;     //! Estimulo del primer dato
    reg  [2:0] i_data2;     //! Estimulo del segundo dato
    reg  [1:0] i_sel;       //! Estimulo de la seleccion
    reg        clk;         //! Reloj de 10 ns de periodo
    reg        i_rst_n;     //! Reset asincronico, activo en bajo


    //! Secuencia de estimulos
    initial begin
        i_data1 <= 3'b000;
        i_data2 <= 3'b000;
        i_sel   <= 2'b00;
        clk     = 1'b0;
        i_rst_n = 1'b0;

        #50;  // Holdea 5 ciclos de clk
        @(posedge clk);  // Sincroniza para continuar junto con el flanco ascendente del clk
        i_rst_n = 1'b1;  // Desactivo el reset

        // Prueba para ver cuantos ciclos de reloj tarda en llegar al overflow
        // con los data y el sel en 1
        #50;
        @(posedge clk);

        i_data1 <= 3'b001;
        i_data2 <= 3'b001;
        i_sel   <= 2'b01;

        // Desde la mitad de data 2
        #10000;
        @(posedge clk);

        i_data1 <= 3'b000;
        i_data2 <= 3'b010;
        i_sel   <= 2'b10;

        // Desde la mitad de data 1
        #10000;
        @(posedge clk);

        i_data1 <= 3'b010;
        i_data2 <= 3'b000;
        i_sel   <= 2'b00;

        // Maximo valor en data 1
        #10000;
        @(posedge clk);

        i_data1 <= 3'b111;
        i_data2 <= 3'b001;
        i_sel   <= 2'b00;

        // Maximo valor en data 2
        #10000;
        @(posedge clk);

        i_data1 <= 3'b001;
        i_data2 <= 3'b111;
        i_sel   <= 2'b10;

        // sel en 11 la salida deberia ser 0
        #10000;
        @(posedge clk);

        i_data1 <= 3'b001;
        i_data2 <= 3'b001;
        i_sel   <= 2'b11;

        #10000;
        $finish;
    end

    //! Generacion del reloj (periodo de 10 ns)
    always #5 clk = ~clk;

    //! Dispositivo bajo prueba
    top u_top (

        .i_data1   (i_data1),
        .i_data2   (i_data2),
        .i_sel     (i_sel),
        .clk       (clk),
        .i_rst_n   (i_rst_n),
        .o_data    (o_data),
        .o_overflow(o_overflow)
    );

endmodule
