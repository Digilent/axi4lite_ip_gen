#include "${ip_name}.h"

% set underscore_name [dict get $specdata underscore_name]
void ${ip_name}_IssueApStart (${ip_name} *InstPtr) {
	// Send the new stuff to hardware
	${ip_name}_WriteReg(InstPtr->BaseAddr, ${underscore_name}_AP_CTRL_REG_OFFSET, ${underscore_name}_AP_CTRL_START_MASK);

	// Wait until ap_done interrupt goes high
	u32 Ctrl;
	do {
		Ctrl = ${ip_name}_ReadReg(InstPtr->BaseAddr, ${underscore_name}_IP_INTR_STS_REG_OFFSET);
	} while (!(${underscore_name}_IP_INTR_STS_AP_DONE_MASK & Ctrl));

    // write to the interrupt bit to clear it
	${ip_name}_WriteReg(InstPtr->BaseAddr, ${underscore_name}_IP_INTR_STS_REG_OFFSET, ${underscore_name}_IP_INTR_STS_AP_DONE_MASK);
}

void ${ip_name}_Initialize (${ip_name} *InstPtr, u32 BaseAddr) {
	InstPtr->BaseAddr = BaseAddr;
	
	${ip_name}_WriteReg(InstPtr->BaseAddr, ${underscore_name}_GIE_REG_OFFSET, ${underscore_name}_GIE_ENABLE_MASK);
	${ip_name}_WriteReg(InstPtr->BaseAddr, ${underscore_name}_IP_INTR_EN_REG_OFFSET, ${underscore_name}_IP_INTR_EN_AP_DONE_MASK);
}
