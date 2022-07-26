@isTest
private class TestStudentDetailComponent {
	//KC: This is the test class from Interventions. It can be deleted.
	/*static testMethod void myUnitTest() {
		TestDataUtil.setupData(1);
		TestDataUtil.SchoolWrapper SW = TestDataUtil.testData[0];
		
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		List<Indicator_Area_Student__c> iaStuList = TestDataUtil.createIAStudents(SW.students,ia.Id);
		insert iaStuList;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		Account_Program__c ap = TestDataUtil.createAccountProgram(SW.school, program);
		insert ap;
		List<Section__c> sections = TestDataUtil.createSections(1, SW.school,ap,new List<List<Student__c>>{SW.students},SW.cmDirect.staffRecord,program);
		
		Test.setCurrentPage(Page.IM_StudentDetail);
		ApexPages.currentPage().getParameters().put('StudentId',SW.students[0].id);

		Test.startTest();
			StudentDetailComponent controller = new StudentDetailComponent();
			system.assertEquals(1,controller.sectionList.size());
			controller.selectedSectionId = controller.sectionList[0].getValue();
			controller.changeSection();

			controller.sessionHolder.Date__c = TestDataUtil.masterYear.Date_Start_Date__c;
			controller.sessionHolder.Skills__c = 'Test Skills';
			controller.resultHolder.Amount_of_Time__c = 10;

			controller.saveTime();
			system.assertEquals(1, controller.sessions.size());
			system.assertEquals(true, controller.hasSessions);
			controller.selectedSessionID = controller.sessions[0].session.ID;
			controller.editSession();

			controller.resultHolder.Amount_of_Time__c = 20;
			controller.saveTime();
			system.assertEquals(1, controller.sessions.size());
			system.assertEquals(20, controller.sessions[0].studentResults[0].Amount_of_Time__c);
		Test.stopTest();
	}*/
}