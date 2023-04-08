#ifndef [dict get $specdata underscore_name]_H   /* prevent circular inclusions */
#define [dict get $specdata underscore_name]_H

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

/* Register access macros */
#define ${ip_name}_In32     Xil_In32
#define ${ip_name}_Out32	Xil_Out32

#define ${ip_name}_ReadReg(BaseAddress, RegOffset)          ${ip_name}_In32((BaseAddress) + (RegOffset))
#define ${ip_name}_WriteReg(BaseAddress, RegOffset, Data)   ${ip_name}_Out32((BaseAddress) + (RegOffset), (Data))

#endif /* end of protection macro */
