trigger Picklist_Value on Picklist_Value__c (before delete) {
	if (!core_triggerUtils.bTriggersDisabled()){
			Set <Id> assignmentTypeIds = new Set <Id>();
			Set <Id> dontDeleteIds = new Set <Id>();
			Map<String, ID> rtMap= core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
	         if (trigger.isDelete && trigger.isBefore){
	        	for (Picklist_Value__c pv: trigger.old){
	        		if (pv.RecordTypeId == rtMap.get('Assignment_Type')){
	        			assignmentTypeIds.add(pv.id);
	        		}
	        	}
	        	if (!assignmentTypeIds.isEmpty()){
	        		for (Assignment_Lib__c al : [select id, picklist_value__c from Assignment_Lib__c where picklist_value__c in :assignmentTypeIds]){
	        			dontDeleteIds.add(al.picklist_value__c);
	        		}
	        	}
	        	if (!dontDeleteIds.isEmpty()){
		        	for (Picklist_Value__c pv: trigger.old){
		        		if (dontDeleteIds.contains(pv.id)){
		        			pv.addError(' Assignment Type is related to 1 or more Assignment Libraries, please update the Assignment Type on the Assignment Library records before deleting');
		        		}
		        	}  
	        	}
	        }
	}
}