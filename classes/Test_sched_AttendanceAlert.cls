@isTest
private class Test_sched_AttendanceAlert {
	
	@isTest static void testschedule() {
		Test.StartTest();
			sched_AttendanceAlert sh1 = new sched_AttendanceAlert();
			sh1.bUnexcused = true;
			String sch = '0 0 23 * * ?';
			string JobId = system.schedule('PGNUA1 Notify', sch, sh1);
			CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, 
			NextFireTime
			FROM CronTrigger WHERE id = :jobId];

			// Verify the expressions are the same  

			System.assertEquals(sch, ct.CronExpression);

			// Verify the job has not run  

			System.assertEquals(0, ct.TimesTriggered);
		test.StopTest();
	} 
}