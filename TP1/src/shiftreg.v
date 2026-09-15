//! @title Shift register
//! @file shiftreg.v

//! - Circular shift register of **N_LEDS** bits.
//! - **i_reset** initializes the shift register (SR) to 0...01. Asynchronous, **active high**.
//! - The SR is moved only when **i_valid** is high.

module shiftreg #(
    // Parameters
    parameter N_LEDS = 4  //! Number of leds (4)
) (
    // Ports
    output [N_LEDS - 1 : 0] o_led,    //! Shift register state
    input                   i_valid,  //! Shift enable
    input                   i_reset,  //! Reset **active high**
    input                   clock     //! System clock
);

    // Vars
    reg [N_LEDS - 1 : 0] shiftreg;  //! Shift Register

    //! Describes the behavior of the SR
    always @(posedge clock or posedge i_reset) begin
        if (i_reset) begin
            shiftreg <= {{N_LEDS - 1{1'b0}}, {1'b1}};
        end else if (i_valid) begin
            shiftreg <= {shiftreg[N_LEDS-2-:N_LEDS-1], shiftreg[N_LEDS-1]};
        end else begin
            shiftreg <= shiftreg;
        end
    end

    //! Output
    assign o_led = shiftreg;

endmodule  // shiftreg
