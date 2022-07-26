trigger Student on Student__c (after insert, after update, before delete, before insert, before update) {
	if (!core_triggerUtils.bTriggersDisabled()){	
		if (trigger.isInsert && trigger.isBefore){
			CT_Student_Utils.processBeforeInsert(trigger.new); 
		}
		if (trigger.isInsert && trigger.isAfter){
			CT_Student_Utils.processAfterInsert(trigger.newMap);
		}
		if (trigger.isUpdate && trigger.isBefore){
			CT_Student_Utils.processBeforeUpdate(trigger.newMap, trigger.oldMap);
		}
		if (trigger.isUpdate && trigger.isAfter){
			CT_Student_Utils.processAfterUpdate(trigger.newMap, trigger.oldMap);
		}
		if (trigger.isDelete && trigger.isBefore){
			CT_Student_Utils.processBeforeDelete(trigger.oldMap);
		}
	}

}