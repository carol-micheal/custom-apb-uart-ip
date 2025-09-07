module transmitter (
    input  clk,        
    input  arst_n,      // active-low global reset
    input rst,         // soft reset (from CTRL_REG)
    input tx_en,       
    input   [7:0] din,       
    input   tx_start,    
    input s_tick,      
    output reg tx,          
    output reg  tx_done_tick,
    output reg  tx_busy    
);
    parameter DBIT = 8;   
    parameter SB_TICK = 16;  
    parameter STOP_BITS = 1;   

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] cs, ns;
    reg [3:0] s_reg, s_next;       // baud tick counter
    reg [2:0] n_reg, n_next;       // data bit counter
    reg [7:0] b_reg, b_next;       // shift register
    reg  tx_next;

    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            cs <= IDLE;
            s_reg  <= 0;
            n_reg <= 0;
            b_reg <= 0;
            tx <= 1'b1;
            tx_busy  <= 1'b0;
            tx_done_tick<= 1'b0;
        end else if (rst) begin
            cs  <= IDLE;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_done_tick<= 1'b0;
        end else if (tx_en) begin
            cs  <= ns;
            s_reg  <= s_next;
            n_reg <= n_next;
            b_reg  <= b_next;
            tx  <= tx_next;
            tx_busy  <= (ns != IDLE);
            tx_done_tick<= (cs == STOP && s_tick && 
                            (s_reg == SB_TICK*STOP_BITS - 1));
        end else begin
            cs <= IDLE;
            s_reg <= 0;
            n_reg  <= 0;
            b_reg  <= 0;
            tx <= 1'b1;
            tx_busy <= 1'b0;
            tx_done_tick<= 1'b0;
        end
    end
    always @(*) begin
        ns  = cs;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;
        tx_next= tx;

        case (cs)
            IDLE: begin
                tx_next = 1'b1;
                if (tx_start) begin
                    ns  = START;
                    s_next = 0;
                    b_next = din;
                end
            end

            START: begin
                tx_next = 1'b0; // start bit
                if (s_tick) begin
                    if (s_reg == SB_TICK-1) begin
                        ns  = DATA;
                        s_next = 0;
                        n_next = 0;
                    end else s_next = s_reg + 1;
                end
            end

            DATA: begin
                tx_next = b_reg[0]; 
                if (s_tick) begin
                    if (s_reg == SB_TICK-1) begin
                        s_next = 0;
                        b_next = b_reg >> 1;
                        if (n_reg == DBIT-1)
                            ns = STOP;
                        else
                            n_next = n_reg + 1;
                    end else s_next = s_reg + 1;
                end
            end

            STOP: begin
                tx_next = 1'b1; 
                if (s_tick) begin
                    if (s_reg == (SB_TICK*STOP_BITS - 1)) begin
                        ns     = IDLE;
                        s_next = 0;
                    end else s_next = s_reg + 1;
                end
            end
        endcase
    end

endmodule



