@isTest
private class Test_sched_CurrentCourseGradeCalculation {
	@isTest static void testschedule(){
		Test.StartTest();
			sched_CurrentCourseGradeCalculation fgs = new sched_CurrentCourseGradeCalculation ();
		        String sch = '0 0 23 * * ?';
		        String JobId = system.schedule('Current Grade Refresh Test', sch, fgs);
		        	CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, 
		        	NextFireTime
		        	FROM CronTrigger WHERE id = :jobId];
		
	   // Verify the expressions are the same  
	    
	      System.assertEquals(sch,ct.CronExpression);
	
	   // Verify the job has not run  
	    
	    System.assertEquals(0, ct.TimesTriggered);
		Test.stopTest();
	}	
	
}