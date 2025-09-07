`timescale 1ns/1ps
module tb_uart_apb;

  reg clk;
  reg rst_n;


  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_n = 0;
    #50 rst_n = 1;
  end
  reg  [31:0] PADDR;
  reg PSEL;
  reg  PENABLE;
  reg  PWRITE;
  reg  [31:0] PWDATA;
  wire [31:0] PRDATA;
  wire PREADY;
  wire  PSLVERR;
  wire uart_tx;

  uart_apb dut (
    .PCLK    (clk),
    .PRESETn (rst_n),
    .PADDR   (PADDR),
    .PSEL    (PSEL),
    .PENABLE (PENABLE),
    .PWRITE  (PWRITE),
    .PWDATA  (PWDATA),
    .PRDATA  (PRDATA),
    .PREADY  (PREADY),
    .PSLVERR (PSLVERR),
    .rx (uart_tx),
    .tx (uart_tx)
  );
  task do_write;
    input [31:0] addr;
    input [31:0] data;
    begin
      @(posedge clk);
      PADDR   = addr;
      PWDATA  = data;
      PWRITE  = 1;
      PSEL    = 1;
      PENABLE = 0;

      @(posedge clk);
      PENABLE = 1;

      @(posedge clk);
      while (!PREADY) @(posedge clk);

      PSEL    = 0;
      PENABLE = 0;
      PWRITE  = 0;

      $display("[%0t] WRITE 0x%0h = 0x%0h", $time, addr, data);
    end
  endtask

  task do_read;
    input  [31:0] addr;
    output [31:0] data;
    begin
      @(posedge clk);
      PADDR   = addr;
      PWRITE  = 0;
      PSEL    = 1;
      PENABLE = 0;

      @(posedge clk);
      PENABLE = 1;

      @(posedge clk);
      while (!PREADY) @(posedge clk);

      data = PRDATA;

      PSEL    = 0;
      PENABLE = 0;

      $display("[%0t] READ  0x%0h -> 0x%0h", $time, addr, data);
    end
  endtask

  localparam integer DVSR     =651; 
  localparam integer SB_TICK  = 16;
  localparam integer DATA_BITS= 8;
  localparam integer STOP_BITS= 1;
  localparam integer BIT_CLKS = DVSR * SB_TICK;  // 256 sysclks per bit
  localparam integer FRAME_CLKS = BIT_CLKS * (1 + DATA_BITS + STOP_BITS); // 2560 sysclks per frame

  reg [31:0] rdata;

  initial begin
    // Init APB signals
    PADDR=0; PWDATA=0; PWRITE=0; PSEL=0; PENABLE=0;
    @(posedge rst_n);
    repeat (5) @(posedge clk);

    // 1. Read CTRL and STATS at reset
    do_read(32'h0, rdata); // CTRL_REG
    do_read(32'h4, rdata); // STATS_REG

    // 2. Enable TX and RX
    do_write(32'h0, 32'h3); // CTRL_REG: TX_EN=1, RX_EN=1

    // 3. Transmit byte 0xA5
    do_write(32'h8, 32'hA5); // TX_DATA

    // 4. Wait for ~1.5 frames
    repeat (FRAME_CLKS*2) @(posedge clk);

    // 5. Read STATS
    do_read(32'h4, rdata);

    // 6. Read RX_DATA
    do_read(32'hC, rdata);
    if (rdata[7:0] == 8'hA5)
      $display("PASS: RX got expected 0xA5");
    else
      $display("FAIL: RX got 0x%0h, expected 0xA5", rdata[7:0]);
      $finish;
  end

endmodule

