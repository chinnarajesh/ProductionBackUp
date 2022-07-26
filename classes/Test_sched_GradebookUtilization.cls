@isTest
private class Test_sched_GradebookUtilization {
	@isTest static void testschedule(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		TestDataSetupUtil_v2.setUPStaffData(5);
		TestDataSetupUtil_v2.setUpStudentData(5);

		Test.StartTest();
			sched_GradebookUtilization sgb = new sched_GradebookUtilization();
			String sch = '0 0 23 * * ?';
			string JobId = system.schedule('Test GBU', sch, sgb);
			CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

			// Verify the expressions are the same  
			System.assertEquals(sch, ct.CronExpression);

			// Verify the job has not run  
			System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}
}