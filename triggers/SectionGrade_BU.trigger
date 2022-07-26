trigger SectionGrade_BU on Section_Grade__c (before insert, before update, after update, before delete) {
	if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)){
		for(Section_Grade__c sg: Trigger.new){
			if(trigger.oldMap==null || sg.Student_Section__c != trigger.oldMap.get(sg.Id).Student_Section__c ){
				sg.Section__c = sg.Section_Id__c;
			}
		}
	}

	if (!core_triggerUtils.bTriggersDisabled()){	
		CT_Gradebook_GradeUtils gradeUtils = new CT_Gradebook_GradeUtils();
		
		if(!core_triggerUtils.b){           // make sure a trigger execution isn't causing a trigger execution.
	        if(Trigger.isBefore && Trigger.isUpdate) {
	        	gradeUtils.setOverrideValues();
				if(gradeUtils.bCourseGradeScalesEmpty()) {
					gradeUtils.setCourseGradeScalesFromSObject(trigger.new);
				}		        	
	        	gradeUtils.SG_processBeforeUpdate(trigger.newMap, trigger.oldMap);
	    	} //end of before update
		} //!core_triggerUtils.b

		//Always run this, so don't move it back inside the core_triggerUils if
		//US2619
		if(Trigger.isAfter && Trigger.isUpdate) {			
			gradeUtils.setOverrideValues();
			if(gradeUtils.bCourseGradeScalesEmpty()) {
				gradeUtils.setCourseGradeScalesFromSObject(trigger.new);
			}				
			gradeUtils.SG_processAfterUpdate(trigger.newMap, trigger.oldMap);
		}
		if (trigger.isBefore && trigger.isDelete){ //DE2369
			if (!core_TriggerUtils.gradeDeletionAllowed){
				for (Section_Grade__c sg: trigger.old){
					sg.addError(' You cannot delete individual Section Grades; Please delete all assignments for the appropriate section and reporting period to purge Section Grades');
				}
			}
		}
	} //!core_triggerUtils.bTriggersDisabled()
	
}