public with sharing class CT_sched_RefreshSessionsAfterPublish {
	public static List<Schedule_Day__c> oldScheduleDays;
	public static List<Schedule_Day__c> newScheduleDays; 
	public static Map<Id, Setup__c> IdToSetUpMap;
	public static boolean firstRun = true; 
	
	public static Database.Deleteresult[]  deleteSessions(Set <Id> scheduleDayIds){
		List <Schedule_Day__c> sdList = new List <Schedule_Day__c>();
		Boolean isGroupBased;
		for(Schedule_Day__c sd : [SELECT Schedule_Template__r.Setup__r.Group_Based__c, Schedule_Template__c, day__c, Schedule_Template__r.Setup__r.School__c,Reporting_Period__c
								   , Schedule_Template__r.Setup__r.Published__c
								FROM Schedule_Day__c
								WHERE Id in : scheduleDayIds]){
			isGroupBased = sd.Schedule_Template__r.Setup__r.Group_Based__c;
			sdList.add(sd);
			system.debug('schedule Day list~~~'+sd);
		}
		
		CT_Scheduler_CreateSessions createSessions = new CT_Scheduler_CreateSessions(sdList,null);
		if (isGroupBased)			{
			createSessions.retrieveSessionsForScheduledSects(sdList);
		}else{
			createSessions.retrieveSessionsForPeriods(sdList);
		}
			
		if(createSessions.sessionList.size() > 0){
			Database.Deleteresult[] dr = database.delete(createSessions.sessionList.values(), false);
			return dr;
		}
		else return null;
	}
	
	@future
	public static void refreshSessions(Set <Id> scheduleDayIds){
		List <Schedule_Day__c> sdList = new List <Schedule_Day__c>();
		try{
			if(firstRun){
			IdToSetUpMap = new Map<Id,Setup__c>();
			Boolean isGroupBased;
			for(Schedule_Day__c sd : [SELECT Schedule_Template__r.Setup__r.Group_Based__c, Schedule_Template__c, day__c, Schedule_Template__r.Setup__r.School__c,Reporting_Period__c
									   , Schedule_Template__r.Setup__r.Published__c
									FROM Schedule_Day__c
									WHERE Id in : scheduleDayIds]){

				sdList.add(sd);
				IdToSetUpMap.put(sd.Schedule_Template__r.Setup__c, sd.Schedule_Template__r.Setup__r);
			}
		
			if(IdToSetUpMap.values().size() > 0){
				for(Setup__c setUp : IdToSetUpMap.values()) isGroupBased = setUp.Group_Based__c;
			}	

			CT_Scheduler_CreateSessions createSessions = new CT_Scheduler_CreateSessions(sdList,null);
			if (isGroupBased){
				createSessions.retrieveSessionsForScheduledSects(sdList);
				createSessions.createSessionsForScheduledSects(sdList);
			}else {
				createSessions.retrieveSessionsForPeriods(sdList);
				Database.UpsertResult[] dr=createSessions.createSessionsForPeriods(sdList);
			}
			}
		}
		catch(Exception e){
			List<String> links = new List<String>();
    		for(Schedule_Day__c s: sdList){
    			if(s.id != null){
    				links.add('New Schedule Day' + ',' + s.id);
    			}
    		}
    		Global_Error__c ge = CT_Error_Handling.handleError(String.join(links, ';'), 'Other', 'RefreshSessions after publish failed on ScheduleDay trigger after update', e);
			insert ge;   	
		}
	}
}