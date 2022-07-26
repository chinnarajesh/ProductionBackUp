trigger AccountProgram on Account_Program__c (before insert, before update, before delete) {
	if(trigger.isInsert){
		TriggerUtils.assignSchoolYear(trigger.new);
		TriggerUtils.checkReferenceId(trigger.new);
	}
	
	if(trigger.isUpdate){
		for(Account_Program__c ap: trigger.new){
			if(trigger.oldMap.get(ap.id).Current_Year_ID__c != trigger.newMap.get(ap.id).Current_Year_ID__c)
				ap.addError('School year on Account/Program cannot be changed.');
		}
		TriggerUtils.checkReferenceId(trigger.new);
	}
	
	if(trigger.isDelete){
		map<Id, Program__c> idToProgram = new map<Id,Program__c>([select id from Program__c where Required_Program__c = true and Status__c = 'Approved']);
		
		for (Account_Program__c connection : Trigger.old){
			if(connection.School__c!= null && connection.Program__c != null){
				if(idToProgram.get(connection.Program__c)!=null){
					connection.addError('Programs that are required and approved cannot be deleted from schools.  Please de-activate this record.');
				}
			}
		}
	}
	
}