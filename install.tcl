# Hey Emacs, use -*- Tcl -*- mode

package require tin 2.0

# Have to hard-code the package name here, since Tin uses temporary
# directories during installation.
set package_name logtable

set OS [lindex $tcl_platform(os) 0]
if { $OS == "Windows" } {
    # Let Tcl put things wherever it wants.  We don't have to worry
    # about root access.
    set dir [tin mkdir -force $package_name 1.5]
} else {
    # We're on Linux, and we want to avoid installing into directories
    # requiring root access.
    set dir [tin mkdir -force ~/.local/share/tcltk $package_name 1.5]
}

file copy $package_name.tcl $dir
file copy pkgIndex.tcl $dir
