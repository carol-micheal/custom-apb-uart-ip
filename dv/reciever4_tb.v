
module receiver4_tb;
  localparam CLK_PERIOD  = 10; 
  localparam DATA_BITS   = 8;  
  localparam SB_TICK=16;
  parameter DVSR = 651;

  reg clk;
  reg PRESETn;      
  reg rx_rst;
  reg rx_en;
  reg rx;
  wire [DATA_BITS-1:0] dout;
  wire rx_done_tick, rx_error_tick, rx_busy, s_tick;

  receiver4 #(
    .DBIT(DATA_BITS),
    .SB_TICK(SB_TICK)
  ) dut (
    .clk(clk),
    .PRESETn(PRESETn),
    .rx_en(rx_en),
    .rx_rst(rx_rst),
    .rx(rx),
    .s_tick(s_tick),
    .dout(dout),
    .rx_done_tick(rx_done_tick),
    .rx_error_tick(rx_error_tick),
    .rx_busy(rx_busy)
  );

     baud_generator #(
        .DVSR(DVSR)
    ) baud_gen (
        .clk(clk),
        .arst_n(PRESETn),
        .tick(s_tick)
    );


  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  task wait_s_ticks(input integer count);
    integer i;
    begin
      for (i=0; i<count; i=i+1)
        @(posedge s_tick);
    end
  endtask

  task pulse_rx_rst();
    begin
      rx_rst = 1'b1;
      @(posedge clk);
      rx_rst = 1'b0;
    end
  endtask

  // Send one bit
  task send_bit(input val);
    begin
      rx = val;
      wait_s_ticks(16);
    end
  endtask

  // Send a full byte LSB-first (standard UART)
  task send_byte(input [7:0] data);
    integer i;
    begin
      send_bit(0); // Start bit
      for (i=0; i<DATA_BITS; i=i+1) // LSB-first
        send_bit(data[i]);
      send_bit(1); // Stop bit
      wait_s_ticks(16); // hold stop long enough
      $display("[%0t] Sent byte 0x%0h", $time, data);
    end
  endtask

  task send_byte_bad_stop(input [7:0] data);
    integer i;
    begin
      send_bit(0);
      for (i=0; i<DATA_BITS; i=i+1)
        send_bit(data[i]);
      send_bit(0); // BAD STOP
      wait_s_ticks(16);
      $display("[%0t] Sent BAD-STOP byte 0x%0h", $time, data);
    end
  endtask

  // Scoreboard
  reg [7:0] exp_data;
  always @(posedge clk) begin
    if (rx_done_tick) begin
      if (dout === exp_data)
        $display("PASS: Expected 0x%0h, got 0x%0h", exp_data, dout);
      else
        $display("FAIL: Expected 0x%0h, got 0x%0h", exp_data, dout);
    end
    if (rx_error_tick)
      $display("ERROR detected at time %0t", $time);
  end

  initial begin
    rx      = 1'b1;
    rx_en   = 1'b1;
    PRESETn = 1'b0;
    rx_rst  = 1'b0;

    #(20*CLK_PERIOD);
    PRESETn = 1'b1;
    wait_s_ticks(32);

    exp_data = 8'h55; send_byte(8'h55);
    exp_data = 8'hF1; send_byte(8'hF1);
    exp_data = 8'hA3; send_byte(8'hA3);
    exp_data = 8'h3C; send_byte_bad_stop(8'h3C);

    #1000;
    $display("Testbench completed");
     $finish;
  end

endmodule 

