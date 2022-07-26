trigger Schedule_Template on Schedule_Template__c (before delete) {
	Set <Id> stIds = new Set <Id>();
	for (Schedule_Template__c st: trigger.old){
		stIds.add(st.id);
	}
	
	List<Schedule_Day__c> sDays = [SELECT id, Schedule_Template__c FROM Schedule_Day__c WHERE Schedule_Template__c IN :stIds];
	if(sDays.size()>0){
		for(Schedule_Day__c sd : sDays){
			trigger.oldMap.get(sd.Schedule_Template__c).addError('Schedule templates that are currently scheduled on the school calendar cannot be deleted.'
				+'  You may replace '+trigger.oldMap.get(sd.Schedule_Template__c).Name+' with a new template on the calendar to delete it.');
		}
	}
	
	List <Scheduled_Section__c> ssList = new List <Scheduled_Section__c>();
	for (Scheduled_Section__c st: [select id, Schedule_Template__c from Scheduled_Section__c where Schedule_Template__c in :stIds]){
		ssList.add(st);
	}
	if (!ssList.isEmpty()){
		delete ssList;
	}

}