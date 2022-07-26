trigger Course_Weightings on Course_Weightings__c (after insert, after delete) {
if (!core_triggerUtils.bTriggersDisabled()){	
		 if (trigger.isInsert && trigger.isBefore){
	        	CT_Course_Weightings_Utils.processBeforeInsert(trigger.new);
	        }
	         if (trigger.isInsert && trigger.isAfter){
				 CT_Course_Weightings_Utils.processAfterInsert(trigger.newMap);
	        }
	         if (trigger.isUpdate && trigger.isBefore){
				 CT_Course_Weightings_Utils.processBeforeUpdate(trigger.newMap, trigger.oldMap);
	        }
	         if (trigger.isUpdate && trigger.isAfter){
				 CT_Course_Weightings_Utils.processAfterUpdate(trigger.newMap, trigger.oldMap);
	        }
	         if (trigger.isDelete && trigger.isAfter){
				 CT_Course_Weightings_Utils.processBeforeDelete(trigger.oldMap);
	        }
	}

}