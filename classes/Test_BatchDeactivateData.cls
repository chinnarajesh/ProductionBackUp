@isTest
private class Test_BatchDeactivateData {
	
	@isTest static void Test_EOYDataDeactivation() {
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
		
		Test.setCurrentPage(Page.EOYWiz_InterventionsLanding);
		Test.StartTest();
			EOY_InterventionsLanding controller = new EOY_InterventionsLanding();
			controller.checkForEOYProgress();

			controller.startDeactivation();
			List<Data_Load_Log__c> logs = [select id from Data_Load_Log__c where Type__c = 'Interventions Data Deactivation'];
			system.assertEquals(1, logs.size());

			controller.finalizeBatch();
		Test.stopTest();
	}
	
	
}