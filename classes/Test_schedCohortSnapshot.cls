@isTest
private class Test_schedCohortSnapshot {
    @isTest static void Test_schedSnapshot() {
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);    	
	    Test.StartTest();
	        sched_CohortSnapshot s = new sched_CohortSnapshot();
	        String sch = '0 0 23 * * ?';
	        string JobId = system.schedule('Cohort Snapshot', sch, s);
	        CronTrigger ct = [SELECT id
	                                 ,CronExpression
	                                 ,TimesTriggered 
	                                 ,NextFireTime
	                          FROM CronTrigger 
	                          WHERE id = :jobId]; 
	        System.assertEquals(sch, ct.CronExpression);
	        System.assertEquals(0, ct.TimesTriggered);
	    test.StopTest();	
	} 
}