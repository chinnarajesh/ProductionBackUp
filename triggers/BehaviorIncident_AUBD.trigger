trigger BehaviorIncident_AUBD on Behavior_Incident__c (before insert, before update, after update, before delete) {
	if (!core_triggerUtils.bTriggersDisabled()){    
		Set<ID> incidentIDSet = new Set<ID>();
	    if(trigger.isDelete){
	        for(Behavior_Incident__c bi:trigger.old){
	            incidentIDSet.add(bi.Id);
	        }
	    } else {
	        for(Behavior_Incident__c bi:trigger.new){
	            incidentIDSet.add(bi.Id);
	        }
	    }
	
	    //Update student behaviors, because they need to pull info from the incident.
	    List<Student_Behavior__c> sbList = behavior_SoqlUtils.getStudentBehaviorListByIncident(incidentIDSet);
	    if (sbList!=null && !trigger.isDelete && !trigger.isBefore){
	        try{
	            update sbList;
	        } catch(exception e){
	            string linkString = '';
	            for(Student_Behavior__c a: sbList){
	                linkString += string.valueOf('Student Behavior') + ',' + string.valueOf(a.id);
	            }
	            Global_Error__c ge = Error_Handling.handleError(linkString, 'Behavior', 'BI trigger SB update failure', e);
	            insert ge;
	        }
	    }
	
	    //If deleting the incident, delete the student behaviors too
	    if(sbList != null && trigger.isDelete){
	        try{
	            delete sbList;
	        } catch(exception e){
	            string linkString = '';
	            for(Student_Behavior__c a: sbList){
	                linkString += string.valueOf('Student Behavior') + ',' + string.valueOf(a.id);
	            }
	            Global_Error__c ge = Error_Handling.handleError(linkString, 'Behavior', 'BI trigger SB update failure', e);
	            insert ge;
	        }
	    }
	}
}