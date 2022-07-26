trigger Program on Program__c (after insert, after update) {
	if(trigger.isInsert){
		List<Account> schools = CYUtil.getAllActiveSchools();
		
		//create account programs
		TriggerUtils.createAccountPrograms(schools, Trigger.new);
	}
	if(trigger.isUpdate){
		Set<ID> deactivateIds = new Set<ID>();
		for(Program__c p: trigger.newMap.values()){
			if(!p.Active__c && trigger.oldMap.get(p.id).Active__c) deactivateIds.add(p.id); 
		}
		//deactivate account/programs
		TriggerUtils.deactivateAccountPrograms(deactivateIds);
	}
}