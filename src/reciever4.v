module receiver4 (
    input  wire       clk,         
    input  wire       PRESETn,     
    input  wire       rx_en,         
    input  wire       rx_rst,       
    input  wire       rx,           
    input  wire       s_tick,     
    output reg [7:0]  dout,         
    output reg        rx_done_tick,  
    output reg        rx_error_tick, 
    output reg        rx_busy       
);
    parameter DBIT    = 8;   // 8 data bits
    parameter SB_TICK = 16;  // ticks per bit

    localparam IDLE  = 3'b000,
               START = 3'b001,
               DATA  = 3'b010,
               STOP  = 3'b011,
               DONE  = 3'b100,
              ERROR = 3'b101;

    reg [2:0] cs, ns;
    reg [3:0] s_reg, s_next; // baud tick counter
    reg [2:0] n_reg, n_next; // bit counter
    reg [7:0] b_reg, b_next; // shift register
    reg rx_done_next, rx_error_next, rx_busy_next;
    reg [7:0] dout_next;


    reg rx_sync1, rx_sync2;
    always @(posedge clk or negedge PRESETn) begin
        if (!PRESETn) begin
            rx_sync1 <= 1;
            rx_sync2 <= 1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end
    always @(posedge clk or negedge PRESETn) begin
        if (!PRESETn || rx_rst) begin
            cs <= IDLE;
            s_reg  <= 0;
            n_reg  <= 0;
            b_reg <= 0;
            dout  <= 0;
            rx_busy  <= 0;
            rx_done_tick  <= 0;
            rx_error_tick <= 0;
        end else begin
            if (rx_en) begin
                cs  <= ns;
                s_reg  <= s_next;
                n_reg  <= n_next;
                b_reg  <= b_next;
                dout <= dout_next;
                rx_busy <= rx_busy_next;
                rx_done_tick  <= rx_done_next;
                rx_error_tick <= rx_error_next;
            end else begin
                cs  <= IDLE;
                s_reg   <= 0;
                n_reg  <= 0;
                b_reg <= 0;
                dout  <= 0;
                rx_busy <= 0;
                rx_done_tick  <= 0;
                rx_error_tick <= 0;
            end
        end
    end
    always @(*) begin
        ns  = cs;
        s_next = s_reg;
        n_next  = n_reg;
        b_next  = b_reg;
        dout_next = dout;
        rx_done_next  = 0;
        rx_error_next = 0;
        rx_busy_next  = (cs != IDLE) && rx_en;
        case (cs)
            IDLE: begin
                s_next = 0;
                n_next = 0;
                if (~rx_sync2) begin 
                    ns     = START;
                    s_next = 0;
                end
            end

            START: begin
                if (s_tick) begin
                    if (s_reg == (SB_TICK/2)) begin
                        ns = DATA;
                        s_next = 0;
                        n_next = 0;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            DATA: begin
                if (s_tick) begin
                    if (s_reg == SB_TICK-1) begin
                        s_next = 0;
                       b_next = {rx_sync2, b_reg[7:1]};
                        if (n_reg == DBIT-1) begin
                            ns = STOP;
                        end else begin
                            n_next = n_reg + 1;
                        end
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            STOP: begin
                if (s_tick) begin
                    if (s_reg == SB_TICK-1) begin
                        if (rx_sync2) begin
                            ns  = DONE;
                            dout_next = b_reg;
                            rx_done_next = 1;
                        end else begin
                            ns  = ERROR;
                            rx_error_next= 1;
                        end
                        s_next = 0;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end

            DONE: begin
                ns = IDLE;
            end

            ERROR: begin
                ns = IDLE;
            end
        endcase
    end

endmodule
