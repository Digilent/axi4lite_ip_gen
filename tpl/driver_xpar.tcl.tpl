proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "<ip_name>" "NUM_INSTANCES" "DEVICE_ID"  "C_<interface>_BASEADDR" "C_<interface>_HIGHADDR"
}