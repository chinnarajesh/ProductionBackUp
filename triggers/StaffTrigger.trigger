trigger StaffTrigger on Staff__c (before insert, after insert, after update, before delete) {
	
	if (!core_triggerUtils.bTriggersDisabled()){	
		if(trigger.isBefore && trigger.isInsert){
			StaffTH.ProcessBeforeInsert(trigger.new);
		}
		
		if(trigger.isAfter && trigger.isUpdate){
			StaffTH.ProcessAfterUpdate(trigger.newMap,trigger.oldMap);
		}
		
		if(trigger.isBefore && trigger.isDelete){
			StaffTH.ProcessBeforeDelete(trigger.old);
		}

		if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
			StaffTH.populateSections(trigger.new, trigger.oldMap);
		}
	}
	
	if(!trigger.isDelete){
		for(Staff__c staff: trigger.new){
			if(staff.Reference_Id__c==null || staff.Reference_Id__c==''){
				staff.Reference_Id__c.addError('Staff records can not have an empty reference id.  Please make sure that the reference id is populated and unique.');
			}
		}
	}

}