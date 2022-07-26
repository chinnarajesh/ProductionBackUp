trigger Assignment_Library on Assignment_Lib__c (before update, before delete) {

	if (trigger.isBefore && trigger.isUpdate){
		Map <Id, Set <Id>> dawMap = new Map <Id, Set <Id>>();
		for (Assignment_Lib__c al : trigger.new){
			if (al.Picklist_Value__c!=trigger.oldMap.get(al.id).picklist_value__c){
				dawMap.put(al.course__c, new Set <Id>());
			}
		}
		if (!dawMap.isEmpty()){
			for (Default_Assignment_Weighting__c daw: [select id, Picklist_Value__c, course__c from Default_Assignment_Weighting__c where Course__c in :dawMap.keySet() ]){
				dawMap.get(daw.course__c).add(daw.picklist_value__c);
			}
		
			for (Assignment_Lib__c al : trigger.new){
				if (!dawMap.get(al.course__c).contains(al.picklist_Value__c)){
					al.addError(' You are only allowed to change the assignment type to a value configured for this course.  Please review the Default Assignment Weightings related list off of this course to view the valid assignment types');
				}
			} 
		}
	}

}