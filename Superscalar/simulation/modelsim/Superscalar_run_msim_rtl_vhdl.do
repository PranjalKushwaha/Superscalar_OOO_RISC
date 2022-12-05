transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -93 -work work {/home/pranjal/CS232/Superscalar/Regfile.vhd}
vcom -93 -work work {/home/pranjal/CS232/Superscalar/Reg.vhd}
vcom -93 -work work {/home/pranjal/CS232/Superscalar/Decode.vhd}
vcom -93 -work work {/home/pranjal/CS232/Superscalar/Superscalar.vhd}
vcom -93 -work work {/home/pranjal/CS232/Superscalar/Memory.vhd}
vcom -93 -work work {/home/pranjal/CS232/Superscalar/Fetch.vhd}

