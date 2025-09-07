vlib work
vlog reciever4.v reciever4_tb.v baud_generator.v 
vsim -voptargs=+acc work.receiver4_tb
add wave *
run -all
#quit -sim