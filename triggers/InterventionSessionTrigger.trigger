trigger InterventionSessionTrigger on Intervention_Session__c (before update, after update) {
	if(trigger.isUpdate && trigger.isBefore){
		InterventionSessionUtils.validateCountISR(trigger.new, trigger.oldMap);
	}
	if(trigger.isAfter){
		if(trigger.isUpdate){
			InterventionSessionUtils.runRemoveISs(trigger.new, trigger.oldMap);
		}
	}
}