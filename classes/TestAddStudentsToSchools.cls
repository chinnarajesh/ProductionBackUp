@isTest
private class TestAddStudentsToSchools {
	static testMethod void myUnitTest() {
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW1 = TestDataUtil.testData[0];
		List<Student__c> students = SW1.students;
			
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		
		List<Indicator_Area_Student__c> iaStuList = TestDataUtil.createIAStudents (students,ia.Id);
		
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		
		Account_Program__c ap = TestDataUtil.createAccountProgram(SW1.school, program);
		insert ap;
		
		Test.setCurrentPage(Page.IM_AddStudentsToPrograms);
		test.startTest();
			Section__c sec = new Section__c();
			ApexPages.StandardController sc = new ApexPages.standardController(sec);
			StudentProgramController controller = new StudentProgramController(sc);	

			for(studentWrapper s :controller.availableStudents) {
				s.checked = true;
			}
			controller.addStudents();
			controller.selectedStaff = controller.staff[0].getValue();
			
			controller.sectionHolder.Name = 'TestSection';
			controller.sectionHolder.Start_Date__c = system.today();
			controller.sectionHolder.End_Date__c = system.today().addDays(5);
			controller.freqChecks.add('Monday');
			controller.sectionHolder.In_After_School__c = 'In School';
			controller.stuSecHolder.Enrollment_Start_Date__c = system.today();
			controller.sectionHolder.Target_Dosage_Section_Goal__c = 500;

			PageReference returnRef = controller.saveSection();
			system.assertNotEquals(null, returnRef);
			system.assertNotEquals(Page.IM_AddStudentsToPrograms.getURL(), returnRef.getURL());
		test.stopTest();
	}
}