@isTest
private class StudentProgramUtilsTest {
	private static final Integer COUNT = 3;

	@isTest static void updateFieldsTest() {
		testDataSetupUtil_v2.setUPCoreData(COUNT);
		testDataSetupUtil_v2.setUPStaffData(COUNT);
		testDataSetupUtil_v2.setUPStudentData(COUNT);
		testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
		List<Student_Section__c> listSS = [SELECT Id, Student__c, Program__c, Amount_of_Time__c, Student_Program__c, Active__c FROM Student_Section__c];

		Test.startTest();
			update listSS;
		Test.stopTest();

		for(Student_Program__c sp: [SELECT Id, Student__c, Program1__c, Reference__c FROM Student_Program__c]){
			System.assertEquals(sp.Reference__c, sp.Student__c+'#'+sp.Program1__c);
		}
	}
	
}