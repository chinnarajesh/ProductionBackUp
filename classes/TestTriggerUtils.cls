@isTest
private class TestTriggerUtils {
	
	static testMethod void testDeactivateAccountPrograms(){
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		Account_Program__c ap = TestDataUtil.createAccountProgram(SW.school, program);
		insert ap;
		Test.startTest();
			program.Active__c = false;
			update program;
			
			ap = [SELECT id, Active__c FROM Account_Program__c WHERE id=:ap.id];
			system.assert(!ap.Active__c);
		Test.stopTest();
	}
	
	static testMethod void testCreateContact(){
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW = TestDataUtil.testData[0];
		Test.startTest();
			Student__c student = SW.students[0];
			Contact contact = TriggerUtils.createContact(student,SW.school);
			system.assertEquals(student.Student_Last_Name__c,contact.LastName);
			system.assertEquals(student.Student_First_Name__c,contact.FirstName);
			system.assertEquals(student.Date_of_Birth__c,contact.Date_of_Birth__c);
			system.assertEquals(student.Gender__c,contact.Gender__c);
			system.assertEquals(student.Ethnicity__c,contact.Ethnicity__c);
			system.assertEquals(student.Active__c,contact.Active__c);
		Test.stopTest();
	}
	
	static testMethod void testCheckSectionsToInactivate(){
		TestDataUtil.setupData(1);
		TestDataUtil.schoolWrapper SW1 = TestDataUtil.testData[0];
		List<Student__c> students = SW1.students;
		// create an indicator area
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;
		List<Indicator_Area_Student__c> iaStuList = TestDataUtil.createIAStudents (students,ia.Id);
		insert iaStuList;
		Program__c program = TestDataUtil.createPrograms(1,true,ia)[0];
		insert program;
		Account_Program__c ap = TestDataUtil.createAccountProgram(SW1.school, program);
		insert ap;
		List<Section__c> sections = TestDataUtil.createSections(1,SW1.school, ap, new List<List<Student__c>>{students}, SW1.cmDirect.staffRecord, program);
		
		Test.startTest();
			System.runAs(SW1.sysAdmin.userRecord){
				List<Student_Section__c> studentSections = [SELECT id, Active__c FROM Student_Section__c WHERE Section__c=:sections[0].id];
				for(Student_Section__c ss: studentSections) {
					ss.Active__c = false;
					ss.Section_Exit_Reason__c = core_triggerUtils.SECTIONEXITREASONBYTRIGGER;
				}
				update studentSections;
			}
			
			Section__c section = [SELECT id, Active__c FROM Section__c WHERE id=:sections[0].id];
			system.assertEquals(false, section.Active__c,'The section did not deactivate as expected.');
		Test.stopTest();
	}
}