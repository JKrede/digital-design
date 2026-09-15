//! @title Switch-controlled shift register - Top
//! @file top.v

//! - **i_reset** is the system reset (**active low**), which resets the counter and initializes the shift register (SR).
//! - **sw[0]** controls the enable (1) of the counter. The value (0) stops the system without changing the state of the counter and the SR.
//! - **sw[2:1]** chooses the limit **R0-R3** of the counter. The SR is moved only when the counter reaches it.
//! - **sw[3]** chooses the color of the RGB LEDs.
//! - The VIO output **selMux** chooses where the switches and reset come from: (0) board, (1) VIO.

module top #(
    // Parameters
    parameter N_LEDS   = 4,   //! Number of leds (4)
    parameter NB_SEL   = 2,   //! Number of bits of the selectors (2)
    parameter NB_COUNT = 32,  //! Number of bits of the counter (32)
    parameter NB_SW    = 4    //! Number of bits of the switch (4)
) (
    // Ports
    output [N_LEDS - 1 : 0] o_led,    //! Leds
    output [N_LEDS - 1 : 0] o_led_b,  //! RGB Leds - Color Blue
    output [N_LEDS - 1 : 0] o_led_g,  //! RGB Leds - Color Green
    input  [NB_SW  - 1 : 0] i_sw,     //! Switchs
    input                   i_reset,  //! Reset **active low**
    input                   clock     //! System clock
);

    // Vars
    wire [NB_SW  - 1 : 0] sw_w;  //! Switch wire (board or VIO)
    wire                  reset;  //! Internal Reset (active high)
    wire                  connect_valid;  //! Counter -> SR
    wire [N_LEDS - 1 : 0] connect_leds;  //! SR state
    wire [N_LEDS - 1 : 0] led_b;  //! Intermediate variable
    wire [N_LEDS - 1 : 0] led_g;  //! Intermediate variable

    wire [NB_SW  - 1 : 0] sw_from_VIO;  //! Switchs from VIO
    wire                  reset_from_VIO;  //! Reset from VIO **active low**
    wire                  selMux;  //! Board (0) / VIO (1)


    //! Mux board / VIO and reverse reset
    assign sw_w  = (selMux) ? sw_from_VIO : i_sw;
    assign reset = (selMux) ? ~reset_from_VIO : ~i_reset;

    //! Counter instance
    count #(
        .NB_SEL    (NB_SEL),
        .NB_COUNTER(NB_COUNT)
    ) u_count (
        .o_valid (connect_valid),
        .i_enable(sw_w[0]),
        .i_sel   (sw_w[(NB_SW-1)-1-:NB_SEL]),
        .i_reset (reset),
        .clock   (clock)
    );

    //! Shift register instance
    shiftreg #(
        .N_LEDS(N_LEDS)
    ) u_shiftreg (
        .o_led  (connect_leds),
        .i_valid(connect_valid),
        .i_reset(reset),
        .clock  (clock)
    );


    //! Output to RGB leds
    assign led_b   = (sw_w[NB_SW-1] == 1'b0) ? connect_leds : {N_LEDS{1'b0}};
    assign led_g   = (sw_w[NB_SW-1] == 1'b1) ? connect_leds : {N_LEDS{1'b0}};

    //! Output to leds
    assign o_led   = connect_leds;
    assign o_led_g = led_g;
    assign o_led_b = led_b;

    //! VIO instance
    vio u_vio (
        .clk_0       (clock),
        .probe_in0_0 (connect_leds),
        .probe_in1_0 (led_b),
        .probe_in2_0 (led_g),
        .probe_out0_0(selMux),
        .probe_out1_0(reset_from_VIO),
        .probe_out2_0(sw_from_VIO)
    );

    //! ILA Instance
    ila u_ila (
        .clk_0   (clock),
        .probe0_0(connect_leds),
        .probe1_0(led_b),
        .probe2_0(led_g)
    );


endmodule
