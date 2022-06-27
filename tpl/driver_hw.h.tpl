% set ip_name [dict get $specdata ip_name]
% set protection_macro [string toupper ${ip_name}]_H_
#ifndef ${protection_macro}
#define ${protection_macro}

#include "xil_types.h"
#include "xil_io.h"

% set prefix [dict get $specdata underscore_name]

/* Register offsets */
#define ${prefix}_CONTROL_REG_OFFSET 						    0x00
#define ${prefix}_GIE_REG_OFFSET 		    					0x04
#define ${prefix}_IP_INTR_EN_REG_OFFSET 			    		0x08
#define ${prefix}_IP_INTR_STS_REG_OFFSET 			    		0x0C

% set offset 16
% foreach register [dict get $specdata registers] {

#define ${prefix}_[dict get ${register} name]_REG_OFFSET [format 0x%x $offset]

%   set offset [expr $offset + 4]
% }

% foreach register [dict get $specdata registers] {
%   set register_name [dict get ${register} name]

/* ${register_name} register bitfields */

%   foreach bitfield [dict get $register bitfields] {
%     set bitfield_name [dict get ${bitfield} name]
%     set bitfield_name [dict get ${bitfield} name]
%     set high [dict get $bitfield high_bit]
%     set low [dict get $bitfield low_bit]

#define ${prefix}_${register_name}_${bitfield_name}_MASK [range2mask $high $low]

%   }
% }

#endif /* end of protection macro */