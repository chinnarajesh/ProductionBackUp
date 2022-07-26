@isTest
private class Test_sched_StudentDaysEnrolled {
	@isTest static void testschedule() {
		Test.StartTest();
			sched_StudentDaysEnrolled bsde = new sched_StudentDaysEnrolled ();
			String sch = '0 0 23 * * ?';
			string JobId= system.schedule('Batch Student Days Enrolled Test', sch, bsde);
			CronTrigger ct = [
				SELECT 
					id, CronExpression, TimesTriggered, NextFireTime
				FROM 
					CronTrigger 
				WHERE 
					id = :jobId];
			// Verify the expressions are the same  
			System.assertEquals(sch,ct.CronExpression);
			// Verify the job has not run
			System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}
}