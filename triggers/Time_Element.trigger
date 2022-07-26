trigger Time_Element on Time_Element__c (before insert, before update, after insert, after update, after delete, before delete) {
	if (!CT_core_triggerUtils.bTriggersDisabled()){
			/* Start Time Validation Logic*/
		if (trigger.isBefore && !trigger.isDelete){
				CT_core_ManageTimeElements.time_Validation(trigger.new, trigger.isInsert);
		} 
		/* End Time Validation Logic*/
	
		//try{
			/*Start Logic to copy the setups based on year being created*/
			if (trigger.isAfter && trigger.isInsert){
				CT_core_ManageTimeElements.isInsert(trigger.newMap);
			}
			/* End of the Year specific Logic*/
	
			/*Start logic to create/update/delete Final Time Elements*/
	
			if (trigger.isAfter && (trigger.isUpdate||trigger.isInsert)){
				CT_core_ManageTimeElements.manage_FinalTimeElements(trigger.newMap);
			}
			
			if (trigger.isBefore && trigger.isUpdate){
				CT_core_ManageTimeElements.checkReportingPeriodUpdates(trigger.newMap, trigger.oldMap);
				CT_core_ManageTimeElements.checkChildDates(trigger.new);
			}
	
			if (trigger.isDelete){
				CT_core_ManageTimeElements.manage_DeleteChildTimeElements(trigger.oldMap);
				if (trigger.isBefore){
					CT_core_ManageTimeElements.checkReportingPeriodDelete(trigger.oldMap);//call method to check for any sections, prevent deletion
				}
			}
	}
}