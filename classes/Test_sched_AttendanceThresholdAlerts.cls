@isTest
private class Test_sched_AttendanceThresholdAlerts {
	@isTest static void testschedule() {
		Test.StartTest();
			sched_AttendanceThresholdAlerts sh1 = new sched_AttendanceThresholdAlerts();
			String sch = '0 0 23 * * ?';
			string JobId = system.schedule('Threshold Alerts', sch, sh1);
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