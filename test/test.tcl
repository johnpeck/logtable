# Hey Emacs, use -*- Tcl -*- mode

set thisfile [file normalize [info script]]

set test_directory [file dirname $thisfile]

set invoked_directory [pwd]

set test_directory_parts [file split $test_directory]
set package_directory [file join {*}[lrange $test_directory_parts 0 end-1]]

set OS [lindex $tcl_platform(os) 0]
if { $OS == "Windows" } {
    # Let Tcl put things wherever it wants.  We don't have to worry
    # about root access.
} else {
    # We're on Linux, and we want to avoid installing into directories
    # requiring root access.
    lappend auto_path ~/.local/share/tcltk
}

# Finally, we can search in the local package directory if everything
# else fails.
lappend auto_path $package_directory

proc intlist {start points} {
    # Return a list of increasing integers starting with start with
    # length points
    set count 0
    set intlist [list]
    while {$count < $points} {
	lappend intlist [expr $start + $count]
	incr count
    }
    return $intlist
}

######################## Command line parsing ########################
#
# Get cmdline from tcllib
package require cmdline

set usage "usage: [file tail $argv0] \[options]"
set options {
    {v.arg 0.0 "Version to test"}
    {n.arg "mypackage" "Name of the package"}
}

try {
    array set params [::cmdline::getoptions argv $options $usage]
} trap {CMDLINE USAGE} {message optdict} {
    # Trap the usage signal, print the message, and exit the application.
    # Note: Other errors are not caught and passed through to higher levels!
    puts $message
    exit 1
}

proc colorputs {newline text color} {

    set colorlist [list black red green yellow blue magenta cyan white]
    set index 30
    foreach fgcolor $colorlist {
	set ansi(fg,$fgcolor) "\033\[1;${index}m"
	incr index
    }
    set ansi(reset) "\033\[0m"
    switch -nocase $color {
	"red" {
	    puts -nonewline "$ansi(fg,red)"
	}
	"green" {
	    puts -nonewline "$ansi(fg,green)"
	}
	"yellow" {
	    puts -nonewline "$ansi(fg,yellow)"
	}
	"blue" {
	    puts -nonewline "$ansi(fg,blue)"
	}
	"magenta" {
	    puts -nonewline "$ansi(fg,magenta)"
	}
	"cyan" {
	    puts -nonewline "$ansi(fg,cyan)"
	}
	"white" {
	    puts -nonewline "$ansi(fg,white)"
	}
	default {
	    puts "No matching color"
	}
    }
    switch -exact $newline {
	"-nonewline" {
	    puts -nonewline "$text$ansi(reset)"
	}
	"-newline" {
	    puts "$text$ansi(reset)"
	}
    }

}

proc listns {{parentns ::}} {
    set result [list]
    foreach ns [namespace children $parentns] {
        lappend result {*}[listns $ns] $ns
    }
    return $result
}

proc fail_message { message } {
    # Print a fail message
    puts -nonewline "\["
    colorputs -nonewline "fail" red
    puts -nonewline "\] "
    puts $message
}

proc pass_message { message } {
    # Print a pass message
    puts -nonewline "\["
    colorputs -nonewline "pass" green
    puts -nonewline "\] "
    puts $message
}

proc info_message { message } {
    # Print an informational message
    puts -nonewline "\["
    colorputs -nonewline "info" blue
    puts -nonewline "\] "
    puts $message
}

proc indented_message { message } {
    # Print a message indented to the end of a pass/fail block
    foreach character [intlist 0 7] {
	puts -nonewline " "
    }
    puts $message
}

proc test_require_tin {} {
    # Test if Tin is installed
    info_message "Test Tin installation"
    try {
	set version [package require tin]
    } trap {} {message optdict} {
	fail_message "Failed to load Tin package"
	indented_message "$message"
	exit
    }

    pass_message "Loaded Tin version $version"
    set action_script [package ifneeded tin $version]
    indented_message "Action script is:"
    foreach line [split $action_script "\n"] {
	indented_message $line
    }
    return
}

proc test_require_package {} {
    # Test requiring the package and the package version
    global params
    info_message "Test loading package"
    try {
	set version [package require -exact $params(n) $params(v)]
    } trap {} {message optdict} {
	fail_message "Failed to load $params(n) package"
	indented_message "$message"
	exit
    }
    if {$version eq $params(v)} {
	pass_message "Loaded $params(n) version $version"
	set action_script [package ifneeded $params(n) $version]
	indented_message "Action script is:"
	foreach line [split $action_script "\n"] {
	    indented_message $line
	}
	return
    } else {
	fail_message "Failed to load correct $params(n) version"
	indented_message "Expected $params(v), got $version"
	exit
    }
}

proc test_intlist_length { length } {
    # Test the length of the list produced with intlist
    # Arguments:
    #   length -- Target length
    info_message "Test length of list made by intlist"
    set output_list [::logtable::intlist -length $length]
    if { [llength $output_list] == $length } {
	pass_message "intlist length is correct"
	return
    } else {
	fail_message "Expected length of $length, got [llength $output_list]"
	exit
    }
}

proc test_engineering_notation_suffix { number expected_suffix} {
    # Test the suffix applied by engineering notation
    info_message "Test suffix applied by engineering_notation"
    set formatted_number [::logtable::engineering_notation -number $number]
    set suffix [lindex $formatted_number end]
    if { $suffix eq $expected_suffix } {
	pass_message "engineering_notation suffix is correct"
	return
    } else {
	fail_message "Expected suffix of $expected_suffix for $number, $suffix"
	exit
    }
}

proc test_header_line { collist } {
    # Tests that header_line produces a header with the correct length and contents
    info_message "Test header line"
    set hline [::logtable::header_line -collist $collist]
    # Indenpendent calculation of the line length
    set found_length 0
    foreach { width title } [join $collist] {
	set found_length [expr $found_length + $width]
    }
    set header_line_length [string length $hline]
    if { $found_length eq $header_line_length } {
	pass_message "Header line length is correct"
    } else {
	fail_message "Header line expected $found_length, got $header_line_length"
	exit
    }
}

proc test_table_row { collist vallist} {
    # Tests table row length and contents
    info_message "Test table row"
    set rline [::logtable::table_row -collist $collist -vallist $vallist]
    # Independent calculation of the line length
    set found_length [string length $rline]
    set target_length 0
    foreach { width title } [join $collist] {
	set target_length [expr $target_length + $width]
    }
    if { $found_length eq $target_length } {
	pass_message "Table row length is correct"
    } else {
	fail_message "Table row expected $target_length, got $found_length"
	exit
    }
    # Test string contents
    foreach value $vallist {
	if { [string first $value $rline] == -1 } {
	    fail_message "Expected $value not found in $rline"
	}
    }
    pass_message "Table row has correct contents"
}

########################## Main entry point ##########################

test_require_package

test_intlist_length 5

test_engineering_notation_suffix 0.0123 m

set column_list [list 5 "foo" 23 "bar" 12 "baz"]

test_header_line $column_list

set value_list [list 3 23.5 "stew"]

test_table_row $column_list $value_list

