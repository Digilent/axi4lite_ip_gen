% set driver_name [dict get $specdata name]
OPTION psf_version = 2.1;

BEGIN DRIVER $driver_name
	OPTION supported_peripherals = (${driver_name});
	OPTION copyfiles = all;
	OPTION VERSION = 1.0;
	OPTION NAME = $driver_name;
END DRIVER
