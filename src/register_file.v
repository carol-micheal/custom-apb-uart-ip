
module register_file (
    input clk,
    input  arst_n,
    input  tx_busy, tx_done,
    input rx_busy, rx_done, rx_error,
    input  [7:0]  rx_data,
    output [7:0]  tx_data,
    output   tx_en, rx_en, rx_rst, tx_rst,
    output [15:0] baud_dvsr,
    output  tx_start,
    input   reg_wr_en,
    input  [31:0] reg_wr_addr,
    input  [31:0] reg_wr_data,

    input reg_rd_en,
    input  [31:0] reg_rd_addr,
    output [31:0] reg_rd_data,
    output   rx_data_ready
);

    // Register map
    localparam integer CTRL_REG   = 3'd0;
    localparam integer STATS_REG  = 3'd1;
    localparam integer TX_DATA    = 3'd2;
    localparam integer RX_DATA    = 3'd3;
    localparam integer BAUDIV     = 3'd4;

    // Internal registers
    reg [31:0] ctrl_reg;
    reg [31:0] stats_reg;
    reg [7:0]  tx_data_reg;
    reg [7:0]  rx_data_reg;
    reg [31:0] baudiv_reg;

    // CTRL bits
    localparam CTRL_TX_EN   = 0;
    localparam CTRL_RX_EN   = 1;
    localparam CTRL_TX_RST  = 2;
    localparam CTRL_RX_RST  = 3;

    // STATS bits
    localparam STATS_RX_BUSY  = 0;
    localparam STATS_TX_BUSY  = 1;
    localparam STATS_RX_DONE  = 2;
    localparam STATS_TX_DONE  = 3;
    localparam STATS_RX_ERROR = 4;

    // Address decode
    wire [2:0] wr_addr = reg_wr_addr[4:2];
    wire [2:0] rd_addr = reg_rd_addr[4:2];

   
    reg tx_start_reg;
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n)
            tx_start_reg <= 1'b0;
        else if (reg_wr_en && (wr_addr == TX_DATA) && ctrl_reg[CTRL_TX_EN])
            tx_start_reg <= 1'b1;
        else
            tx_start_reg <= 1'b0;
    end
    assign tx_start = tx_start_reg;

   
    always @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin
            ctrl_reg    <= 32'h0;
            tx_data_reg <= 8'h0;
            rx_data_reg <= 8'h0;
            baudiv_reg  <= 32'd651; 
            stats_reg   <= 32'h0;
        end else begin
            if (reg_wr_en) begin
                case (wr_addr)
                    CTRL_REG: ctrl_reg <= reg_wr_data;
                    TX_DATA:  tx_data_reg <= reg_wr_data[7:0];
                    BAUDIV: baudiv_reg <= reg_wr_data;
                endcase
            end
            stats_reg[STATS_RX_BUSY] <= rx_busy;
            stats_reg[STATS_TX_BUSY] <= tx_busy;

            if (rx_done) begin
                stats_reg[STATS_RX_DONE] <= 1'b1;
                rx_data_reg <= rx_data;
            end
            if (tx_done)
                stats_reg[STATS_TX_DONE] <= 1'b1;
            if (rx_error)
                stats_reg[STATS_RX_ERROR] <= 1'b1;

            // === auto clear TX/RX reset bits ===
            if (ctrl_reg[CTRL_RX_RST])
                ctrl_reg[CTRL_RX_RST] <= 1'b0;
            if (ctrl_reg[CTRL_TX_RST])
                ctrl_reg[CTRL_TX_RST] <= 1'b0;
        end
    end

    assign reg_rd_data =
            (rd_addr == CTRL_REG)  ? ctrl_reg :
            (rd_addr == STATS_REG) ? stats_reg :
            (rd_addr == TX_DATA)   ? {24'h0, tx_data_reg} :
            (rd_addr == RX_DATA)   ? {24'h0, rx_data_reg} :
            (rd_addr == BAUDIV)    ? baudiv_reg : 32'h0;

    assign tx_en   = ctrl_reg[CTRL_TX_EN];
    assign rx_en   = ctrl_reg[CTRL_RX_EN];
    assign tx_rst  = ctrl_reg[CTRL_TX_RST];
    assign rx_rst  = ctrl_reg[CTRL_RX_RST];
    assign tx_data = tx_data_reg;
    assign baud_dvsr = baudiv_reg[15:0];
    assign rx_data_ready = stats_reg[STATS_RX_DONE];

endmodule
