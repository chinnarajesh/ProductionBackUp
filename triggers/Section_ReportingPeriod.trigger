trigger Section_ReportingPeriod on Section_ReportingPeriod__c (before delete, before insert, before update, after insert, after update) {
    if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
    	CT_Section_Utils.prefillFlagFromSectionReportingPeriod(trigger.new, trigger.oldMap);
    }
    
    if (!core_triggerUtils.bTriggersDisabled()){
		 if (Trigger.isBefore && Trigger.isDelete){
	     	CT_Section_Utils.checkSectionReportingPeriodDeletion(trigger.oldMap);
	     }
         if (Trigger.isAfter){
         	if(Trigger.isInsert){
         		CT_Scheduler_TriggerUtils.processAfterInsert(trigger.newMap);
         	}            	
			if(Trigger.isUpdate){
				CT_Scheduler_TriggerUtils.processAfterUpdate(trigger.newMap,trigger.oldMap);
			}
        }
    }
}