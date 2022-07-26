trigger Section on Section__c (before insert, after insert, before update, after update, before delete) {
	if (!CT_core_triggerUtils.bTriggersDisabled()){
		if (Trigger.isBefore && Trigger.isInsert){
			CT_Section_Utils.processBeforeInsert(trigger.new);
			CT_core_TriggerUtils.updateSectionRefIds(trigger.new);	// to stamp Reference Id on Section//Do not handle this with try/catch PN 11/23
		}
		
		/* Begin old Section.trigger*/
		if(Trigger.isAfter && Trigger.isInsert){
			if(!core_triggerUtils.b){
				CT_Section_Utils.processAfterInsert(trigger.newMap);
			}
		}
	
		if(Trigger.isBefore && Trigger.isDelete){
			CT_Section_Utils.processBeforeDelete(trigger.old);
		}
		/* End old Section.trigger*/
	
		/*Begin old Section_BUBD.trigger*/
		if(Trigger.isBefore && Trigger.isUpdate){
			CT_Section_Utils.processBeforeUpdate(trigger.newMap, trigger.oldMap);
		}
		/*end old Section_BUBD.trigger*/
		if(Trigger.isAfter && Trigger.isUpdate){
			CT_Section_Utils.processAfterUpdate(trigger.newMap, trigger.oldMap);
		}

		if(trigger.isBefore && trigger.isDelete){
			StudentSectionUtils.removeStudentPrograms(trigger.old);
		}		
	}
		
	if(trigger.isAfter) {
		if(trigger.isUpdate) {
			TriggerUtils.AUSectionStaffSectionCreate(trigger.new, trigger.oldMap);
		}
		
		if(trigger.isInsert) {
			TriggerUtils.AISectionStaffSectionCreate(trigger.new);
		}
	}
	
}