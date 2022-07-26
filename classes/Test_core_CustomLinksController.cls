@isTest
private class Test_core_CustomLinksController {
	@isTest static void test_core_CustomLinksController(){
		core_CustomLinksController controller = new core_CustomLinksController();
		insertValuesForRelease();
		test.StartTest();
		core_CustomLinksController c = new core_CustomLinksController();
			test.StopTest();
	}
	
	private static void insertValuesForRelease(){
		List <Link_Settings__c> lsList = new List <Link_Settings__c>();
		for (Profile p: [select id, name from Profile]){
			Boolean isAdmin= false;
			Boolean isFrontOffice = false;
			Boolean isTeacher = false;
			system.debug(p.name);
			if (p.name.contains('Office')) isFrontOffice=true;
			else if (p.name.contains('Teacher')) isTeacher = true;
			else if (p.name.contains('Administrator')) isAdmin = true;
			if (isAdmin||isFrontOffice||isTeacher){
			system.debug(isAdmin+'|'+isFrontOffice+'|'+isTeacher);
			Link_Settings__c ls= new Link_Settings__c(SetupOwnerId=p.id);
			if (isTeacher) ls.Overall_Comments__c=true;
			if (isFrontOffice||isAdmin) ls.ProActive_Processor__c=true;
			if (isFrontOffice||isAdmin) ls.Run_Report_Cards__c=true;
			if (isFrontOffice||isAdmin) ls.Section_Wizard__c=true;
			if (isFrontOffice||isAdmin) ls.Attendance_Wizard__c=true;
			ls.Print_Schedule__c=true;
			if (isFrontOffice||isAdmin) ls.Assessment_Wizard__c=true;
			ls.Community_Service_Wizard__c=true;
			if (isAdmin)ls.Year_Close_Wizard__c=true;
			lsList.add(ls);
			}
		}
		upsert lsList;
	}	
}