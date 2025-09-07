
module transmitter_tb;
  localparam CLK_PERIOD = 10;
  localparam DATA_BITS  = 8;
  localparam SB_TICK    = 16;
  localparam DVSR       = 651; // For baud generator (100MHz / (9600*16))

  reg clk;
  reg arst_n;
  reg rst;
  reg tx_en;
  reg tx_start;
  reg [7:0] din;
  wire tx;
  wire tx_done_tick, tx_busy;
  wire s_tick;

  transmitter #(
    .DBIT(DATA_BITS),
    .SB_TICK(SB_TICK),
    .STOP_BITS(1)
  ) dut (
    .clk(clk),
    .arst_n(arst_n),
    .rst(rst),
    .tx_en(tx_en),
    .din(din),
    .tx_start(tx_start),
    .s_tick(s_tick),
    .tx(tx),
    .tx_done_tick(tx_done_tick),
    .tx_busy(tx_busy)
  );

  baud_generator #(
    .DVSR(DVSR)
  ) baud_gen (
    .clk(clk),
    .arst_n(arst_n),
    .tick(s_tick)
  );


  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Utility: wait n s_ticks
  task wait_s_ticks(input integer count);
    integer i;
    begin
      for (i=0; i<count; i=i+1)
        @(posedge s_tick);
    end
  endtask

  // Scoreboard: reconstruct frame
  task check_tx_frame(input [7:0] exp_data);
    integer i;
    reg [7:0] rx_data;
    begin
      // Expect start bit
      wait_s_ticks(1); // align
      if (tx !== 0)
        $display("FAIL: Expected START=0, got %b at time %0t", tx, $time);

      // Sample data bits LSB-first
      rx_data = 0;
      for (i=0; i<DATA_BITS; i=i+1) begin
        wait_s_ticks(SB_TICK); // move one bit period
        rx_data[i] = tx;
      end

      // Sample stop bit
      wait_s_ticks(SB_TICK);
      if (tx !== 1)
        $display("FAIL: Expected STOP=1, got %b at time %0t", tx, $time);

      // Compare received data
      if (rx_data === exp_data)
        $display("PASS: Sent 0x%0h, observed 0x%0h at time %0t", exp_data, rx_data, $time);
      else
        $display("FAIL: Sent 0x%0h, observed 0x%0h at time %0t", exp_data, rx_data, $time);
    end
  endtask

  // Send a byte
  task send_byte(input [7:0] data);
    begin
      din      = data;
      tx_start = 1'b1;
      @(posedge clk);
      tx_start = 1'b0;
      check_tx_frame(data);
      @(posedge tx_done_tick);
    end
  endtask


  initial begin
    arst_n   = 0;
    rst      = 0;
    tx_en    = 1;
    tx_start = 0;
    din      = 8'h00;

    #(20*CLK_PERIOD);
    arst_n = 1;
    rst    = 0;

    wait_s_ticks(32);

    send_byte(8'h55);
    send_byte(8'hF1);
    send_byte(8'hA3);

    #1000;
    $display("TX Testbench completed");
    $finish;
  end

endmodule
