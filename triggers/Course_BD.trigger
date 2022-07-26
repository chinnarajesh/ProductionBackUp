trigger Course_BD on Course__c (before delete, after insert, after update, before insert, before update) {
	if (!core_triggerUtils.bTriggersDisabled()){	
		 if (trigger.isInsert && trigger.isBefore){
	        	Course_Utils.processBeforeInsert(trigger.new); 
	        }
	         if (trigger.isInsert && trigger.isAfter){
	        		Course_Utils.processAfterInsert(trigger.newMap);
	        }
	         if (trigger.isUpdate && trigger.isBefore){
	        		Course_Utils.processBeforeUpdate(trigger.newMap, trigger.oldMap);
	        }
	         if (trigger.isUpdate && trigger.isAfter){
	        		Course_Utils.processAfterUpdate(trigger.newMap, trigger.oldMap);
	        }
	         if (trigger.isDelete && trigger.isBefore){
	        		Course_Utils.processBeforeDelete(trigger.oldMap);
	        }
	}
}