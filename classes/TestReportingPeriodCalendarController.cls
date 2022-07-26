@isTest
private class TestReportingPeriodCalendarController {
	
	static testMethod void myUnitTest() {
		TestDataSetupUtil_v2.setUPCoreData(5);
		
		Schedule_Template__c st = new Schedule_Template__c(Setup__c=TestDataSetupUtil_v2.activeSetUp.id, has_class__c = true,Reporting_Period__c= TestDataSetupUtil_v2.semester.id, Is_Master__c=true ,color__c='#ff0000' );
		st.start_time__c =  dateTime.newInstance(system.today().year(), system.today().addmonths(1).month(), system.today().day(), 9,0,0);
		st.end_time__c =  st.start_time__c.addHours(8);
		insert st;
	
		Schedule_Template__c st2 = new Schedule_Template__c(Setup__c=TestDataSetupUtil_v2.activeSetUp.id, has_class__c = true,Reporting_Period__c= TestDataSetupUtil_v2.semester2.Id, Is_Master__c=true ,color__c='#ff0000' );
		st.start_time__c =  dateTime.newInstance(system.today().year(), system.today().addmonths(1).month(), system.today().day(), 9,0,0);
		st.end_time__c =  st.start_time__c.addHours(8);
		insert st2;
		
		PageReference testPage = new PageReference('/apex/ReportingPeriodCalendarView?setupid='+TestDataSetupUtil_v2.activeSetUp.id);

		Test.setCurrentPage(testPage);
		ReportingPeriodCalendarController controller = new ReportingPeriodCalendarController();
		//system.debug('~~~~~' +controller.repPeriodCal);
		controller.save();
		date d= TestDataSetupUtil_v2.semester.Date_Start_Date__c;
		integer dayCount = 0;
		while (d <= TestDataSetupUtil_v2.semester.End_Date__c){
			if (d.daysBetween(d.toStartOfWeek())!=0&&d.daysBetween(d.toStartOfWeek())!=-6){
				dayCount++;
				system.debug(d.daysBetween(d.toStartOfWeek()));
				system.debug(d);
			}
			d = d.addDays(1);
		}
		system.assertEquals(dayCount,controller.scheduleDaysList.size());
		system.debug(controller.repPeriodCal.repPeriodIdToName.values());
		system.assertEquals(2,controller.repPeriodCal.repPeriodIdToName.values().size());
		
		

	}
}