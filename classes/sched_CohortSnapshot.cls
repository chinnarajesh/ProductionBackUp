global class sched_CohortSnapshot implements Schedulable {
	

	global void execute(SchedulableContext sc) {
		Set<Id> schoolIds = new Set<Id>();
			for(AggregateResult ag : [SELECT School__c a
						                FROM Cohort__c 
						                WHERE Expired__c = false
						                GROUP BY School__c]){
				schoolIds.add((ID)ag.get('a'));	
			}
			
			Batch_CohortSnapshot cs = new	Batch_CohortSnapshot(schoolIds);	
			ID batchprocessid =Database.executeBatch(cs, 1);
	}
}