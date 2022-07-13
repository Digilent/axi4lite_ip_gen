% set ip_name [dict get $specdata ip_name]
% set protection_macro [string toupper ${ip_name}]_H_
#ifndef ${protection_macro}
#define ${protection_macro}

#include "xil_types.h"
#include "xil_io.h"

% set prefix [dict get $specdata underscore_name]

/* Register offsets */
#define [dict get $specdata underscore_name]_AP_CTRL_REG_OFFSET 0x00
#define [dict get $specdata underscore_name]_GIE_REG_OFFSET 0x04
#define [dict get $specdata underscore_name]_IP_INTR_EN_REG_OFFSET 0x08
#define [dict get $specdata underscore_name]_IP_INTR_STS_REG_OFFSET 0x0C

% set registers [get_register_addresses $specdata]
% foreach register $registers {
#define ${prefix}_[string toupper [dict get $register name]]_REG_OFFSET [dict get $register offset]

% }

/* Control Register bitfields */
#define [string toupper ${ip_name}]_AP_START_MASK 0x01
#define [string toupper ${ip_name}]_AP_DONE_MASK 0x02
#define [string toupper ${ip_name}]_AP_IDLE_MASK 0x04
#define [string toupper ${ip_name}]_AP_READY_MASK 0x08
#define [string toupper ${ip_name}]_AUTO_RESTART_MASK 0x80

/* Global interrupt enable register bitfields */
#define [string toupper ${ip_name}]_GIE_ENABLE_MASK 0x01

/* IP interrupt enable register bitfields */
#define [string toupper ${ip_name}]_IP_INTR_EN_CHANNEL_0_MASK 0x1
#define [string toupper ${ip_name}]_IP_INTR_EN_CHANNEL_1_MASK 0x2
#define [string toupper ${ip_name}]_IP_INTR_EN_ALL_MASK 0x3

/* IP interrupt status register bitfields */
#define [string toupper ${ip_name}]_IP_INTR_STS_CHANNEL_0_MASK 0x1
#define [string toupper ${ip_name}]_IP_INTR_STS_CHANNEL_1_MASK 0x2

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