@isTest
private class InterventionSessionUtilsTest {
	private static final Integer COUNT = 5;
	private static final Integer AMOUNT = 30;

	@testSetup
	private static void setupData(){
		testDataSetupUtil_v2.setUPCoreData(COUNT);
		testDataSetupUtil_v2.setUPStaffData(COUNT);
		testDataSetupUtil_v2.setUPStudentData(COUNT);
		testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
		testDataSetupUtil_v2.setUPExistingSessionResults(AMOUNT);
	}

	@isTest static void validateCountISRTest() {
		List<Student_Section__c> listSS = [SELECT Id FROM Student_Section__c];
		
		String msg = '';
    	Test.startTest();
    		try{
    			delete listSS;
    		}catch(Exception e){
    			msg = e.getMessage();
    		}
    	Test.stopTest();

    	System.assert(msg.contains(System.Label.Validation_Intervention_Session));
	}

	@isTest static void removeISTest() {
		List<Student__c> listS = [SELECT Id FROM Student__c];

		Test.startTest();
		delete listS;
		Test.stopTest();

		List<Intervention_Session__c> listISs = [SELECT Id FROM Intervention_Session__c];
		System.assert(listISs.isEmpty());
	}

}