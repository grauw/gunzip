ext debugdevice
set debugoutput stdout
debug set_watchpoint read_io 0x2E
#debug set_watchpoint write_mem 0x0000 {([debug read ioports 0xA8] & 0x0C) == 0x04}
#debug set_watchpoint read_mem 0x0000 {([debug read ioports 0xA8] & 0x0C) == 0x04}

diskmanipulator create /tmp/vgmplay.dsk 32M
virtual_drive /tmp/vgmplay.dsk
diskmanipulator format virtual_drive
diskmanipulator import virtual_drive bin/
virtual_drive eject
hda /tmp/vgmplay.dsk

set throttle off
after time 15 "set throttle on"


#
# Profiling utility
#
# Start profiling with out (2ch),a, end profiling with out (2dh),a.
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
