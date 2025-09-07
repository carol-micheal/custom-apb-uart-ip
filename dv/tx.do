vlib work
vlog transmitter.v 
vlog transmitter_tb.v 
vlog baud_generator.v 
vsim -voptargs=+acc work.transmitter_tb
add wave *
run -all
#quit -sim