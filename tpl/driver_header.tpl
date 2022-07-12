% set ip_name [dict get $specdata ip_name]
% set protection_macro [string toupper ${ip_name}]_H_
#ifndef ${protection_macro}
#define ${protection_macro}

#include "xil_types.h"
#include "xil_io.h"

% set prefix [dict get $specdata underscore_name]

/* Register offsets */
% set registers [get_register_addresses $specdata]
% foreach register $registers {
#define ${prefix}_[string toupper [dict get $register name]]_REG_OFFSET [dict get $register offset]

% }

% foreach register [dict get $specdata registers] {
%   set register_name [string toupper [dict get ${register} name]]
/* ${register_name} register bitfields */

%   foreach bitfield [dict get $register bitfields] {
%     set bitfield_name [string toupper [dict get ${bitfield} name]]
%     set high [dict get $bitfield high_bit]
%     set low [dict get $bitfield low_bit]
#define ${prefix}_${register_name}_${bitfield_name}_MASK [format 0x%x [range2mask $high $low]]

%   }
% }

#endif /* end of protection macro */