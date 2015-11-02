#
# Profiling utility
#
# Start profiling with out (2ch),a, end profiling with out (2dh),a.
# Run the profile command in the openMSX console to see the result.
#
variable profile_time 0
variable profile_start_time -1
variable profile_count 0
variable profile_ignored 0
debug set_watchpoint write_io 0x2C {} {profile_start}
debug set_watchpoint write_io 0x2D {} {profile_stop}

proc profile_start {} {
	variable profile_start_time
	variable profile_ignored
	variable profile_out_overhead
	set out_cycles [expr {"[cpuregs::get_active_cpu]" eq "z80"} ? 12.0 : 5.0]
	set overhead [expr $out_cycles / 3579545]
	if {$profile_start_time == -1} {
		set profile_start_time [expr [machine_info time] + $overhead]
	} else {
		set profile_start_time [expr $profile_start_time + $overhead]
		incr profile_ignored
	}
}

proc profile_stop {} {
	variable profile_time
	variable profile_start_time
	variable profile_count
	variable profile_ignored
	if {$profile_start_time != -1} {
		set profile_time [expr [machine_info time] - $profile_start_time + $profile_time]
		set profile_start_time -1
		incr profile_count
	} else {
		incr profile_ignored
	}
}

proc profile {} {
	variable profile_time
	variable profile_count
	variable profile_ignored
	puts "Time: $profile_time, count: $profile_count, ignored: $profile_ignored"
}
