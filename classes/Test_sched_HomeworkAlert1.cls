@isTest
private class Test_sched_HomeworkAlert1 {
	@isTest static void testschedule() {
		Test.StartTest();
			sched_HomeworkAlert1 sh1 = new sched_HomeworkAlert1();
			String sch = '0 0 23 * * ?';
			string JobId = system.schedule('PGNHW1 Notify', sch, sh1);
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