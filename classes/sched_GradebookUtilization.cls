global class sched_GradebookUtilization implements Schedulable{
	global void execute(SchedulableContext sc) {
   		GradebookUtilizationBatch gbu = new GradebookUtilizationBatch ();
		gbu.query = 'select Id, Name, of_Consecutive_Days_without_Grades__c from Section__c where Active__c = true and RecordType.DeveloperName=\'Published\'';
		gbu.email = 'email@test.com';
		ID batchprocessid = Database.executeBatch(gbu,1);
	}
}