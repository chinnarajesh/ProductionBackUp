trigger Scheduled_Section on Scheduled_Section__c (before insert, before update) {
    if (!core_triggerUtils.bTriggersDisabled()){
		if (trigger.isInsert && trigger.isBefore){
       		Scheduled_Section_Utils.processBeforeInsert(trigger.new); 
        }
        // if (trigger.isInsert && trigger.isAfter){
        	//Scheduled_Section_Utils.processAfterInsert(trigger.newMap);
        //}
         if (trigger.isUpdate && trigger.isBefore){
        	Scheduled_Section_Utils.processBeforeUpdate(trigger.newMap, trigger.oldMap);
        }
         //if (trigger.isUpdate && trigger.isAfter){
        	//Scheduled_Section_Utils.processAfterUpdate(trigger.newMap, trigger.oldMap);
        //}
         //if (trigger.isDelete && trigger.isBefore){
        	//Scheduled_Section_Utils.processBeforeDelete(trigger.oldMap);
        //}
	}
}