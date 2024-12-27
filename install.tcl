# Hey Emacs, use -*- Tcl -*- mode

package require tin 1.0

# Have to hard-code the package name here, since Tin uses temporary
# directories during installation.
set package_name logtable

set dir [tin mkdir -force $package_name 1.2]
file copy $package_name.tcl $dir
file copy pkgIndex.tcl $dir
