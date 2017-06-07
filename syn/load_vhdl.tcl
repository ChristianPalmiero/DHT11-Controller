# Adapt the list of source files to your own project. List *only* the
# synthesizable files. Do *not* list simulation source files.

set source_files { 
	dht11_pkg_syn.vhd
	CU.vhd
	datapath.vhd
	debouncer.vhd
	dht11_ctrl.vhd
	dht11_sa.vhd
	dht11_sa_top.vhd
}

foreach f $source_files {
	add_files $rootdir/$f
}

