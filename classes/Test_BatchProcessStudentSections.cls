@isTest
private class Test_BatchProcessStudentSections {
	private static final Integer COUNT = 3;	
	private static final Integer AMOUNT = 30;

	static testMethod void test_BatchProcessStudentSections() {
		testDataSetupUtil_v2.setUPCoreData(COUNT);
		testDataSetupUtil_v2.setUPStaffData(COUNT);
		testDataSetupUtil_v2.setUPStudentData(COUNT);
		testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
		testDataSetupUtil_v2.setUPExistingSessionResults(AMOUNT);
     	BatchProcessStudentSections bpsc = new BatchProcessStudentSections ();

     	Test.startTest(); 
        	Database.executeBatch(bpsc, 50) ;
     	Test.stopTest();		

    	List<Student_Program__c> studentPrograms = new List<Student_Program__c>([SELECT Id, Student__c, Amount_of_Time__c FROM Student_Program__c]);
    	System.assertEquals(COUNT + 1, studentPrograms.size());     	
	}
}