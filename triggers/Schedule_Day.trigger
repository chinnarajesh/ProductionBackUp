trigger Schedule_Day on Schedule_Day__c (before update, after update) {
	if (!core_triggerUtils.bTriggersDisabled()){
 	// trigger executes because of an update operation
		Set <Id> ScheduleDayIds =  new Set<Id>();
 		for(Integer i = 0; i < trigger.new.size(); i ++){
			if(trigger.new[i].Published__c && trigger.old[i].Schedule_Template__c != trigger.new[i].Schedule_Template__c ){
				if (trigger.isBefore){
					ScheduleDayIds.add(trigger.old[i].id);
				}
				else {
					ScheduleDayIds.add(trigger.new[i].id);
				}		
			}
		}
		if (!scheduleDayIds.isEmpty()){ 
			if (trigger.isBefore){
				try {
					Database.Deleteresult[]  dr = sched_RefreshSessionsAfterPublish.deleteSessions(scheduleDayIds);
					if(dr != null){
						for (Database.Deleteresult result: dr){
							if (!result.isSuccess()){
								trigger.newMap.get(result.getId()).addError('Session Deletion Error');
							}
						}
					}
				}
				catch (exception e){
	    			for(Schedule_Day__c s: trigger.new){
	    				s.addError('Schedule Day Update Error '+e.getMessage());
	    			}
				}	
			}
			else {
				sched_RefreshSessionsAfterPublish.refreshSessions(ScheduleDayIds);
			}
		}
	}
}