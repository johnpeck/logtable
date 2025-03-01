# Hey Emacs, use -*- Tcl -*- mode

package require cmdline 1.5

namespace eval ::logtable {

}

proc ::logtable::intlist {args} {
    # Return a list of increasing integers starting with start with
    # length points
    #
    # Arguments:
    #   first -- First integer in the list
    #   length -- Number of integers in the list
    set myoptions {
	{first.arg 0 "First integer"}
	{length.arg 10 "Length of the list"}
    }
    array set arg [::cmdline::getoptions args $myoptions]

    set count 0
    set intlist [list]
    while { [llength $intlist] < $arg(length) } {
	    lappend intlist [expr $arg(first) + $count]
	    incr count
	}
    return $intlist
}

proc ::logtable::engineering_notation {args} {
    # Return a number with an SI prefix as a suffix
    #
    # See https://wiki.tcl-lang.org/page/Engineering+Notation
    # and https://www.tcl.tk/man/tcl8.6/TclCmd/format.htm#M20
    #
    # Arguments:
    #   number -- The full number you want to convert
    #   digits -- Maximum number of significant digits to keep
    set myoptions {
	{number.arg 0.0123 "Number to format"}
	{digits.arg 3 "Digits to keep in the formatted output"}
    }
    array set arg [::cmdline::getoptions args $myoptions]

    # Metric prefix symbols (power of 10 divided by 3)
    #
    # See https://www.nist.gov/pml/owm/metric-si-prefixes
    array set orders {
	-8 y -7 z -6 a -5 f -4 p -3 n -2 u -1 m 0 {} 1 k 2 M 3 G 4 T 5 P 6 E 7 Z 8 Y
    }

    set number_list  [split [format %e $arg(number)] e]
    set order [expr {[scan [lindex $number_list 1] %d] / 3}]
    if {[catch {set orders($order)} prefix]} {
	return [list $arg(number)]
    }
    set number [format %0.${arg(digits)}g [expr {$arg(number)/pow(10,3*$order)}]]
    if {$prefix eq ""} {
	# Include a space after the number so there will be a space between the number and the unit.
	return "$number "
    } else {
	return [list $number $prefix]
    }
}

proc ::logtable::dashline {args} {
    # Return a dashed line the length of all columns
    #
    # Arguments:
    #   collist -- Alternating list of column widths and column titles
    set myoptions {
	{collist.arg "10 title" "Alternating list of column widths and titles"}
    }
    array set arg [::cmdline::getoptions args $myoptions]

    foreach { width title } [join $arg(collist)] {
	incr line_length $width
    }
    foreach dash [intlist -length $line_length] {
	append dashline "-"
    }
    return $dashline
}

proc ::logtable::format_string {args} {
    # Return a format string for use with formatting table rows
    #
    # Arguments:
    #   collist -- Alternating list of column widths and column titles
    set myoptions {
	{collist.arg "10 title" "Alternating list of column widths and titles"}
    }
    array set arg [::cmdline::getoptions args $myoptions]
    foreach {width title} [join $arg(collist)] {
	# - means left justify
	# * means the next argument must be an integer field width
	# s means no conversion
	append fstring "%-*s"
	}
    return $fstring
}

proc ::logtable::header_line {args} {
    # Return the table header line (formatted list of column titles)
    #
    # Arguments
    #   collist -- List of alternating width and titles
    set myoptions {
	{collist.arg "10 title" "Alternating list of column widths and titles"}
    }
    array set arg [::cmdline::getoptions args $myoptions]
    foreach { width title } [join $arg(collist)] {
	set header_bit [format "%-*s" $width $title]
	append hline $header_bit
    }
    return $hline
}

proc ::logtable::table_row { args } {
    # Return the table header line (formatted list of column titles)
    #
    # Arguments
    #   collist -- List of alternating width and titles
    set myoptions {
	{collist.arg "10 title" "Alternating list of column widths and titles"}
	{vallist.arg "value" "List of column values"}
    }
    array set arg [::cmdline::getoptions args $myoptions]
    foreach { width title } [join $arg(collist)] {
	lappend width_list $width
    }
    foreach width $width_list value $arg(vallist) {
	append rstring [format "%-*s" $width $value]
    }
    return $rstring
}

proc ::logtable::colorputs { args } {
    # Print a string with one of a few ANSI colors
    #
    # Arguments:
    #   nonewline -- (flag) Do not put a newline at the end
    #   color -- red, green, yellow, blue, magenta, cyan, white
    set usage "usage: colorputs \[options\] string"
    set myoptions {
	{nonewline "Suppress the newline at the end of the string"}
	{color.arg "red" "red, green, yellow, blue, magenta, cyan, white"}
    }
    array set arg [::cmdline::getoptions args $myoptions]

    # After cmdline is done, args will point to the last argument
    if {[llength $args] == 1} {
	set string [join $args]
    } else {
	puts [cmdline::usage $myoptions $usage]
	exit 1
    }
    set colorlist [list black red green yellow blue magenta cyan white]
    set index 30
    foreach fgcolor $colorlist {
	set ansi(fg,$fgcolor) "\033\[1;${index}m"
	incr index
    }
    set ansi(reset) "\033\[0m"
    switch -nocase $arg(color) {
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
    if $arg(nonewline) {
	puts -nonewline $string$ansi(reset)
    } else {
	puts $string$ansi(reset)
    }
}

proc ::logtable::info_message { args } {
    # Print an informational message
    set usage "usage: info_message string"
    set myoptions {
    }
    array set arg [::cmdline::getoptions args $myoptions]

    # After cmdline is done, args will point to the last argument
    if {[llength $args] == 1} {
	set message [join $args]
    } else {
	puts [cmdline::usage $myoptions $usage]
	exit 1
    }
    puts -nonewline "\["
    colorputs -nonewline -color blue "info"
    puts -nonewline "\] "
    puts $message
}

proc ::logtable::fail_message { args } {
    # Print a message about a failure
    set usage "usage: fail_message string"
    set myoptions {
    }
    array set arg [::cmdline::getoptions args $myoptions]

    # After cmdline is done, args will point to the last argument
    if {[llength $args] == 1} {
	set message [join $args]
    } else {
	puts [cmdline::usage $myoptions $usage]
	exit 1
    }
    puts -nonewline "\["
    colorputs -nonewline -color red "fail"
    puts -nonewline "\] "
    puts $message
}

proc ::logtable::fail_message { args } {
    # Print a message about a failure
    set usage "usage: fail_message string"
    set myoptions {
    }
    array set arg [::cmdline::getoptions args $myoptions]

    # After cmdline is done, args will point to the last argument
    if {[llength $args] == 1} {
	set message [join $args]
    } else {
	puts [cmdline::usage $myoptions $usage]
	exit 1
    }
    puts -nonewline "\["
    colorputs -nonewline -color red "fail"
    puts -nonewline "\] "
    puts $message
}

proc ::logtable::warn_message { args } {
    # Print a message about a warning
    set usage "usage: warn_message string"
    set myoptions {
    }
    array set arg [::cmdline::getoptions args $myoptions]

    # After cmdline is done, args will point to the last argument
    if {[llength $args] == 1} {
	set message [join $args]
    } else {
	puts [cmdline::usage $myoptions $usage]
	exit 1
    }
    puts -nonewline "\["
    colorputs -nonewline -color yellow "warn"
    puts -nonewline "\] "
    puts $message
}

# Finally, provide the package
package provide logtable 1.3
