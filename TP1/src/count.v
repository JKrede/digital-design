//! @title Counter with selectable limit
//! @file count.v

//! - Counter enabled by **i_enable**. With (0) the counter holds its current value.
//! - **i_sel** chooses the limit **R0-R3** at any time during operation.
//! - **o_valid** is high during the clock cycle in which the counter reaches the limit.
//! - **i_reset** is an asynchronous reset, **active high**.

module count #(
    // Parameters
    parameter NB_SEL     = 2,   //! Number of bits of the selector (2)
    parameter NB_COUNTER = 32   //! Number of bits of the counter (32)
) (
    // Ports
    output                  o_valid,   //! Counter reached the limit
    input                   i_enable,  //! Counter enable
    input  [NB_SEL - 1 : 0] i_sel,     //! Limit selector
    input                   i_reset,   //! Reset **active high**
    input                   clock      //! System clock
);

    // Localparam
    localparam R0   = (2 ** (NB_COUNTER - 10)) - 1;  //! Limit of counter
    localparam R1   = (2 ** (NB_COUNTER - 9)) - 1;   //! Limit of counter
    localparam R2   = (2 ** (NB_COUNTER - 8)) - 1;   //! Limit of counter
    localparam R3   = (2 ** (NB_COUNTER - 7)) - 1;   //! Limit of counter

    localparam SEL0 = 2'h0;                          //! Select R0
    localparam SEL1 = 2'h1;                          //! Select R1
    localparam SEL2 = 2'h2;                          //! Select R2
    localparam SEL3 = 2'h3;                          //! Select R3

    // Vars
    wire [NB_COUNTER - 1 : 0] ref_limit;  //! Limit value from constants
    reg  [NB_COUNTER - 1 : 0] counter;    //! Counter

    //! Mux for limits
    assign ref_limit = (i_sel == SEL0) ? R0 : (i_sel == SEL1) ? R1 : (i_sel == SEL2) ? R2 : R3;

    //! Describes the behavior of the counter
    always @(posedge clock or posedge i_reset) begin : counterBlock
        if (i_reset) begin
            counter <= {NB_COUNTER{1'b0}};
        end else if (i_enable) begin
            if (counter >= ref_limit) begin
                counter <= {NB_COUNTER{1'b0}};
            end else begin
                counter <= counter + {{NB_COUNTER - 1{1'b0}}, {1'b1}};
            end
        end else begin
            counter <= counter;
        end
    end

    //! Valid when the counter reaches the limit (same cycle as the original design)
    assign o_valid = i_enable & (counter >= ref_limit);

endmodule  // count
