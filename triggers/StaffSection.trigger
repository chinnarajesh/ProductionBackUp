trigger StaffSection on Staff_Section__c (before insert, before update, after insert, after update) {
	if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)){
		for(Staff_Section__c ss: trigger.new){
			ss.Account__c = ss.School__c;
			ss.StaffUnique__c = String.valueOf(ss.Section__c) +'_'+ String.valueOf(ss.Staff__c);
		}
	}

	if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)) {
		TriggerUtils.AIAUStaffSection(trigger.new);
	}
	
}