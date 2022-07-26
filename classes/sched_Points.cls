global class sched_Points implements Schedulable{
	
	global void execute(SchedulableContext sc) { 
		Set<String> setupIds;
		List<Setup__c> setupsUpdated = new List<Setup__c>();
		CronTrigger ct = [SELECT Id, OwnerID FROM CronTrigger WHERE Id = :sc.getTriggerId()];
		Points_Utils.pointsNotifications(ct.OwnerID);
		
		setupIds = Points_Utils.getSetupsForReset();  
		if(setupIds != null){
			for(Setup__c s: [SELECT Points_Reset_Value__c FROM Setup__c WHERE Id in: setupIds]){
				s.Points_Reset_Date__c = System.today();
				setupsUpdated.add(s); 
			}
			
			update setupsUpdated; 
			System.debug('SETUP$$$$$$'+setupsUpdated);
	   		Batch_ResetPoints brp = new Batch_ResetPoints ();
	   		brp.setupIds = setupIds;  
			ID batchprocessid = Database.executeBatch(brp);
		}
	}
	
}