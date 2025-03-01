# Hey Emacs, use -*- Tcl -*- mode

if {![package vsatisfies [package provide Tcl] 8.6]} {return}
package ifneeded logtable 1.3 [list source [file join $dir logtable.tcl]]
