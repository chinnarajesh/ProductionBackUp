@isTest
private class Test_sched_FinalGradeCalculation {
	@isTest static void testschedule() {
		Test.StartTest();
			sched_FinalGradeCalculation fgs = new sched_FinalGradeCalculation ();
			String sch = '0 0 23 * * ?';
			string JobId= system.schedule('Final Grade Refresh Test', sch, fgs);
			CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, 
			NextFireTime
			FROM CronTrigger WHERE id = :jobId];

			// Verify the expressions are the same  

			System.assertEquals(sch,
			ct.CronExpression);

			// Verify the job has not run  

			System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}	
	
}