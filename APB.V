
module APB #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input PCLK,
    input PRESETn,
    input  [ADDR_WIDTH-1:0] PADDR,
    input  PSEL,
    input  PENABLE,
    input  PWRITE,
    input [DATA_WIDTH-1:0]  PWDATA,
    output  [DATA_WIDTH-1:0] PRDATA,
    output   PREADY,
    output   PSLVERR,

    output   reg_wr_en,
    output  [31:0]  reg_wr_addr,
    output   [31:0]  reg_wr_data,
    output   reg_rd_en,
    output  [31:0]  reg_rd_addr,
    input  [31:0]  reg_rd_data
);

    // Local FSM states
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    reg  [1:0] cs;
    reg  pready_reg;
    reg [DATA_WIDTH-1:0] prdata_reg;
    reg  wr_en_reg, rd_en_reg;
    reg [ADDR_WIDTH-1:0] addr_reg;

always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            cs  <= IDLE;
            pready_reg <= 1'b0;
            wr_en_reg  <= 1'b0;
            rd_en_reg  <= 1'b0;
            prdata_reg <= {DATA_WIDTH{1'b0}};
            addr_reg   <= {ADDR_WIDTH{1'b0}};
        end 
        else begin
            wr_en_reg  <= 1'b0;
            rd_en_reg  <= 1'b0;
            pready_reg <= 1'b0;

            case (cs)
                IDLE: begin
                    if (PSEL && !PENABLE) begin
                    cs <= SETUP;
                    addr_reg <= PADDR;       // latch address
                    end
                end
                SETUP: begin
                    if (PSEL && !PWRITE) begin
                        rd_en_reg <= 1'b1;       // prime the regfile read
                    end
                    if (PSEL && PENABLE) begin
                        cs <= ACCESS;
                    end else if (!PSEL) begin
                        cs <= IDLE;
                    end
                end

                ACCESS: begin
                    if (PSEL && PENABLE) begin
                    pready_reg <= 1'b1;      // one-cycle ready
                        if (PWRITE) begin
                            wr_en_reg <= 1'b1;   // VALID write
                        end else begin
                                prdata_reg <= reg_rd_data;
                        end
                    cs <= IDLE;  // zero-wait-state
                    end else begin
                        cs <= IDLE;
                    end
                end
                default: cs <= IDLE;
            endcase
        end
    end

    // APB outputs
    assign PREADY  = pready_reg;
    assign PSLVERR = 1'b0;
    assign PRDATA  = prdata_reg;

    // Regfile connections
    assign reg_wr_en   = wr_en_reg;
    assign reg_wr_addr = addr_reg;
    assign reg_wr_data = PWDATA;
    assign reg_rd_en   = rd_en_reg;
    assign reg_rd_addr = addr_reg;

endmodule


