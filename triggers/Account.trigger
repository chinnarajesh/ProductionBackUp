trigger Account on Account (after insert) {
	
	//get list of required programs
	List<Program__c> requiredPrograms = [select id, name, Required_Program__c from Program__c where Required_Program__c = true and Status__c = 'Approved'];
	
	List<Account> schools = new List<Account>();
	Id schoolRecord = [SELECT id FROM RecordType WHERE DeveloperName='School' AND sObjectType='Account'].id;
	for(Account a: trigger.new){
		if(a.RecordTypeId==schoolRecord) schools.add(a);
	}
	//create account programs
	if(schools.size() > 0){
		core_triggerUtils.createSetupRecords(schools);
		if(requiredPrograms.size() > 0) TriggerUtils.createAccountPrograms(schools, requiredPrograms);
	}
	
}