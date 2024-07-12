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
    #
    # Arguments:
    #   number -- The full number you want to convert
    #   places -- Decimal places you want to keep in the returned value
    set myoptions {
	{number.arg 0.0123 "Number to format"}
	{places.arg 3 "Decimal places in the formatted output"}
    }
    array set arg [::cmdline::getoptions args $myoptions]

    # Metric prefix symbols (power of 10 divided by 3)
    #
    # See https://www.nist.gov/pml/owm/metric-si-prefixes
    array set orders {
	-8 y -7 z -6 a -5 f -4 p -3 n -2 u -1 m 0 {} 1 k 2 M 3 G 4 T 5 P 6 E 7 Z 8 Y
    }
 
    set numInfo  [split [format %e $arg(number)] e]
    set order [expr {[scan [lindex $numInfo 1] %d] / 3}]
    if {[catch {set orders($order)} prefix]} {
	return [list $arg(number)]
    }
    set number [format %0.${arg(places)}f [expr {$arg(number)/pow(10,3*$order)}]]
    if {$prefix eq ""} {
	return $number
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

# Finally, provide the package
package provide logtable 1.0