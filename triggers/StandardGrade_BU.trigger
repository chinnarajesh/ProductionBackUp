trigger StandardGrade_BU on Standard_Grade__c (before update, after update) {
	if (!core_triggerUtils.bTriggersDisabled()){
		if(!core_triggerUtils.b){
        	if(trigger.isBefore && trigger.isUpdate) {
	        	//check overrides
	        	for(Standard_Grade__c sg : trigger.newMap.Values()) {
	        		if(sg.Grade_Override__c != trigger.oldMap.get(sg.ID).Grade_Override__c) {
	        			sg.Grade_Overridden__c = true;
	        		}
	        	}	        	
	        }
	        
	        if(trigger.isAfter && trigger.isUpdate) {
	        	Set<ID> students = new Set<ID>();
	        	Set<ID> strands = new Set<ID>();
	        	
	        	for(Standard_Grade__c sg : trigger.newMap.Values()) {
	        		if(sg.Student__c != null) {
	        			students.add(sg.Student__c);
	        		}
	        		if(sg.Strand_Id__c != null) {
	        			strands.add(sg.Strand_Id__c);
	        		}
	        	}
	        	
	        	upsert CT_Gradebook_CalculationTypes.calculateStrandGrades(students, strands).Values() Key__c;      	
	        }	        
	    }
	}
}