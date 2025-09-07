vlib work
vlog uart_apb_tb.v uart_apb.v
vsim -voptargs=+acc work.tb_uart_apb
add wave *
run -all
#quit -sim