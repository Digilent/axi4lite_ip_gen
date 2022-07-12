% set ip_name [dict get $specdata ip_name]
OPTION psf_version = 2.1;

BEGIN DRIVER ${ip_name}
	OPTION supported_peripherals = (${ip_name});
	OPTION copyfiles = all;
	OPTION VERSION = 1.0;
	OPTION NAME = ${ip_name};
END DRIVER
