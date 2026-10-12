`timescale 1ns / 100ps

// En una placa con un clk de 100MHz el periodo es 10ns
// (#n: n timescale de espera)

//! @title Testbench del Ejercicio 4
//! @file tb_top.v
//! @author Julian Krede
//! @brief Testbench del filtro IIR `top`.
//!
//! Genera un reloj de 10 ns (100 MHz), aplica un reset inicial y excita el
//! filtro con los siguientes casos, dejando al menos 1000 ns entre cada uno
//! para observar la respuesta:
//!
//! 1. Impulso unitario (`x = 1`).
//! 2. Impulso con el maximo valor positivo (`x = 127`).
//! 3. Impulso con el maximo valor negativo (`x = -128`).
//! 4. Escalon con el maximo valor positivo.
//! 5. Salto del maximo positivo al maximo negativo y viceversa.
//! 6. Secuencia que maximiza la parte izquierda (`127, 127, -128, 127`).
//! 7. Secuencia que minimiza la parte izquierda (`-128, -128, 127, -128`).
//! 8. Entrada alternada entre el maximo positivo y el maximo negativo.
//! 9. Reset con el filtro cargado: la salida debe volver a 0.
module tb_top ();

    // Salidas (siempre wire)
    wire signed [11:0] y;      //! Salida del filtro entregada por el DUT

    // Entradas (simpre reg)
    reg signed  [ 7:0] x;      //! Estimulo de entrada del filtro
    reg                clk;    //! Reloj de 10 ns de periodo
    reg                rst_n;  //! Reset asincronico, activo en bajo


    //! Secuencia de estimulos
    initial begin
        x     <= 8'sd0;
        clk   = 1'b0;
        rst_n = 1'b0;

        #50;
        @(posedge clk);
        rst_n = 1'b1;

        #50;
        @(posedge clk);

        // Impulso unitario
        x <= 8'sd1;
        @(posedge clk);
        x <= 8'sd0;

        #1000;
        @(posedge clk);

        // Impulso con el maximo valor positivo
        x <= 8'sd127;
        @(posedge clk);
        x <= 8'sd0;

        #1000;
        @(posedge clk);

        // Impulso con el maximo valor negativo
        x <= -8'sd128;
        @(posedge clk);
        x <= 8'sd0;

        #1000;
        @(posedge clk);

        // Escalon con el maximo valor positivo
        x <= 8'sd127;

        #1000;
        @(posedge clk);

        // Salto del maximo positivo al maximo negativo
        x <= -8'sd128;

        #1000;
        @(posedge clk);

        // Salto del maximo negativo al maximo positivo
        x <= 8'sd127;

        #1000;
        @(posedge clk);

        // Secuencia que maximiza la parte izquierda: x[n-3]=127, x[n-2]=127, x[n-1]=-128, x[n]=127
        x <= 8'sd0;

        #1000;
        @(posedge clk);

        x <= 8'sd127;
        @(posedge clk);
        x <= 8'sd127;
        @(posedge clk);
        x <= -8'sd128;
        @(posedge clk);
        x <= 8'sd127;
        @(posedge clk);
        x <= 8'sd0;

        #1000;
        @(posedge clk);

        // Secuencia que minimiza la parte izquierda: x[n-3]=-128, x[n-2]=-128, x[n-1]=127, x[n]=-128
        x <= -8'sd128;
        @(posedge clk);
        x <= -8'sd128;
        @(posedge clk);
        x <= 8'sd127;
        @(posedge clk);
        x <= -8'sd128;
        @(posedge clk);
        x <= 8'sd0;

        #1000;
        @(posedge clk);

        // Entrada alternada entre el maximo positivo y el maximo negativo
        x <= 8'sd127;
        @(posedge clk);
        x <= -8'sd128;
        @(posedge clk);
        x <= 8'sd127;
        @(posedge clk);
        x <= -8'sd128;
        @(posedge clk);
        x <= 8'sd127;
        @(posedge clk);
        x <= -8'sd128;
        @(posedge clk);
        x <= 8'sd127;
        @(posedge clk);
        x <= -8'sd128;
        @(posedge clk);
        x <= 8'sd0;

        #1000;
        @(posedge clk);

        // Reset con el filtro cargado, la salida deberia volver a 0
        x <= 8'sd127;

        #1000;
        @(posedge clk);

        rst_n = 1'b0;

        #50;
        @(posedge clk);

        rst_n = 1'b1;

        #1000;
        $finish;
    end

    //! Generacion del reloj (periodo de 10 ns)
    always #5 clk = ~clk;

    //! Dispositivo bajo prueba
    top u_top (
        .clk  (clk),
        .rst_n(rst_n),
        .x    (x),
        .y    (y)
    );

endmodule
