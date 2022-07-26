@isTest
private class Test_sched_HomeworkAlert2 {
		@isTest static void testschedule() {
			Test.StartTest();
				sched_HomeworkAlert2 sh1 = new sched_HomeworkAlert2();
				String sch = '0 0 23 * * ?';
				String JobId = system.schedule('PGNHW2 Notify', sch, sh1);
				CronTrigger ct = [
					SELECT 
						id ,CronExpression, TimesTriggered, NextFireTime
					FROM 
						CronTrigger 
					WHERE 
						id = :jobId];
				System.assertEquals(sch, ct.CronExpression);
				System.assertEquals(0, ct.TimesTriggered);
			Test.StopTest();
		}
}