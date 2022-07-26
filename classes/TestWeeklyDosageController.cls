@isTest
private class TestWeeklyDosageController{

	//KC: This test is from interventions. It can be deleted.
	//static testMethod void myUnitTest(){
		//TestDataUtil.setupData(2);
		/*TestDataUtil.schoolWrapper SW1 = TestDataUtil.testData[0];
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		Staff__c cm1 = SW1.cmDirect.staffRecord;
		User cm1Usr	=	SW1.cmDirect.userRecord;
		Staff__c schAdmin1 = SW1.schoolAdmin.staffRecord;
		User schAdmin1Usr	=	SW1.schoolAdmin.userRecord;
		User siteAdmin1Usr = SW1.siteAdmin.userRecord;
		User hq1Usr = SW1.networkAdmin.userRecord;
		List<Student__c> students1 = SW1.students;
		List<Indicator_Area_Student__c> iaStu =  TestDataUtil.createIAStudents (students1,ia.Id);
		Id profID = cm1Usr.ProfileId;

		Account school1	=	SW1.school;
		update school1;

		insert iaStu;

		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;

		List<Account_Program__c> accProgs = new List<Account_Program__c>();
		accProgs.add(TestDataUtil.createAccountProgram(school1, program));
		insert accProgs;

		List<Section__c> sections = TestDataUtil.createSections(1, school1, accProgs[0], new List<List<Student__c>>{students1}, cm1, program);

		Test.startTest();
			WeeklyDosageController controller = new WeeklyDosageController();

			controller.selectedSchool = controller.schools[0].getValue();
			controller.changeSchool();
			controller.selectedSection = controller.sections[0].getValue();
			controller.changeSection();
			controller.selectedStaff = controller.staff[0].getValue();
			controller.changeStaff();



			/*List<SelectOption> tstSect = wdc.sections;
			wdc.chooseSession();
			wdc.changeWeek();
			wdc.lastWeek();
			wdc.nextWeek();
			wdc.setSchool();
			wdc.loadSection(sections[0].id);
			wdc.getStaffAndSections(school1.id);
			wdc.selectedSection = sections[0].id;
			wdc.saveChanges();
			wdc.throwNoDateMessage();
			wdc.checkSkills();
			wdc.toggleSortDirection();
			wdc.currentSection.getSessionsToSave();
			wdc.currentSection.saveSection();
		Test.stopTest();*/
	//}
}