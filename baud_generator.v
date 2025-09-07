module baud_generator #(
    parameter DVSR = 651
) (
    input  wire       clk,
    input  wire       arst_n,
    output reg        tick
);

    reg [15:0] r_reg;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            r_reg <= 0;
            tick  <= 0;
        end else begin
            if (r_reg == DVSR - 1) begin
                r_reg <= 0;
                tick  <= 1;
            end else begin
                r_reg <= r_reg + 1;
                tick  <= 0;
            end
        end
    end
endmodule 

