#ifndef [dict get $specdata underscore_name]_H_   /* prevent circular inclusions */
#define [dict get $specdata underscore_name]_H_

#include "xil_types.h"
#include "xil_io.h"
#include "[file tail $hwheader_path]"

typedef struct {
	u32 BaseAddr;
} ${ip_name};

#define ${ip_name}_In32     Xil_In32
#define ${ip_name}_Out32	Xil_Out32

#define ${ip_name}_ReadReg(BaseAddress, RegOffset)          ${ip_name}_In32((BaseAddress) + (RegOffset))
#define ${ip_name}_WriteReg(BaseAddress, RegOffset, Data)   ${ip_name}_Out32((BaseAddress) + (RegOffset), (Data))

void ${ip_name}_Initialize (${ip_name} *InstPtr, u32 BaseAddr);
void ${ip_name}_IssueApStart (${ip_name} *InstPtr);

#endif /* end of protection macro */
