trigger AccountAI on Account (after insert) {
	if (!core_triggerUtils.bTriggersDisabled()){
		List<Account> schools = new List<Account>();
		Map<String,ID> accountRTs = core_SoqlUtils.getRecordTypesBySobject('Account');
		for(Account a: trigger.new){
			if(a.RecordTypeId==accountRTs.get('School') || a.RecordTypeId==accountRTs.get('Summer_School')) schools.add(a);
		}
		core_triggerUtils.createSetupRecords(schools);
	}
}