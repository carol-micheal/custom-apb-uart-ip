
module uart_apb #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DVSR=651
)(
    input   PCLK,
    input   PRESETn,   // active-low
    input  [ADDR_WIDTH-1:0] PADDR,
    input  PSEL,
    input  PENABLE,
    input  PWRITE,
    input  [DATA_WIDTH-1:0] PWDATA,
    output [DATA_WIDTH-1:0] PRDATA,
    output  PREADY,
    output  PSLVERR,

    input rx,        // external serial input
    output tx         // external serial output
);


    wire  reg_wr_en;
    wire [31:0] reg_wr_addr;
    wire [31:0] reg_wr_data;
    wire   reg_rd_en;
    wire [31:0] reg_rd_addr;
    wire [31:0] reg_rd_data;
    wire [7:0]  rf_tx_data;
    wire rf_tx_en;
    wire  rf_rx_en;
    wire  rf_tx_rst;
    wire rf_rx_rst;
    wire [15:0] rf_baud_dvsr;
    wire  rf_tx_start;
    wire [7:0]  rf_rx_data;
    wire rf_tx_busy;
    wire rf_tx_done;
    wire rf_rx_busy;
    wire rf_rx_done;
    wire rf_rx_error;
    wire rf_rx_data_ready;
    wire s_tick;
    APB #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) apb_if (
        .PCLK (PCLK),
        .PRESETn (PRESETn),
        .PADDR (PADDR),
        .PSEL (PSEL),
        .PENABLE (PENABLE),
        .PWRITE (PWRITE),
        .PWDATA (PWDATA),
        .PRDATA (PRDATA),
        .PREADY (PREADY),
        .PSLVERR (PSLVERR),

        .reg_wr_en   (reg_wr_en),
        .reg_wr_addr (reg_wr_addr),
        .reg_wr_data (reg_wr_data),
        .reg_rd_en   (reg_rd_en),
        .reg_rd_addr (reg_rd_addr),
        .reg_rd_data (reg_rd_data)
    );

    register_file reg_file (
        .clk (PCLK),
        .arst_n (PRESETn),
        .tx_busy (rf_tx_busy),
        .tx_done (rf_tx_done),
        .rx_busy (rf_rx_busy),
        .rx_done (rf_rx_done),
        .rx_error (rf_rx_error),
        .rx_data (rf_rx_data),
        .tx_data (rf_tx_data),
        .tx_en (rf_tx_en),
        .rx_en (rf_rx_en),
        .tx_rst (rf_tx_rst),
        .rx_rst (rf_rx_rst),
        .baud_dvsr (rf_baud_dvsr),
        .tx_start (rf_tx_start),
        .reg_wr_en (reg_wr_en),
        .reg_wr_addr (reg_wr_addr),
        .reg_wr_data (reg_wr_data),
        .reg_rd_en (reg_rd_en),
        .reg_rd_addr (reg_rd_addr),
        .reg_rd_data (reg_rd_data),
        .rx_data_ready(rf_rx_data_ready)
    );


    baud_generator#(.DVSR(651)) baud_gen_inst (
        .clk (PCLK),
        .arst_n (PRESETn),
        .tick (s_tick)
    );

    transmitter tx_inst (
        .clk  (PCLK),
        .arst_n (PRESETn),
        .rst (rf_tx_rst),
        .tx_en (rf_tx_en),
        .din (rf_tx_data),
        .tx_start  (rf_tx_start),
        .s_tick (s_tick),
        .tx  (tx),
        .tx_done_tick (rf_tx_done),
        .tx_busy   (rf_tx_busy)
    );

    receiver4 rx_inst (
        .clk (PCLK),
        .PRESETn (PRESETn),
        .rx_en  (rf_rx_en),
        .rx_rst (rf_rx_rst),
        .rx  (rx),
        .s_tick (s_tick),
        .dout (rf_rx_data),
        .rx_done_tick (rf_rx_done),
        .rx_error_tick(rf_rx_error),
        .rx_busy (rf_rx_busy)
    );

endmodule

