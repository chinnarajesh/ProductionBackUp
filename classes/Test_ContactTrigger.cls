@isTest
private class Test_ContactTrigger {
	public static void createTestData(){
		testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUPStudentData(5);
	}
    static testMethod void testOnDelete() {
    	createTestData();

    	
    	
    	Contact c=testDataSetupUtil_v2.studContactsList[1];
    	Student__c s = testDataSetupUtil_v2.studentsList[1];
        
        Test.startTest();
	        delete c;
	        integer k = [SELECT count() FROM Student__c WHERE id =: s.id];
	        system.assertEquals(k , 0);
	    Test.stopTest();
    }

    static testMethod void testChangeActivation() {
        createTestData();
        Contact c=testDataSetupUtil_v2.studContactsList[2];
    	Student__c s = testDataSetupUtil_v2.studentsList[2];
        Test.startTest();
            c.Active__c = false;
            c.Exit_Date__c = testDataSetupUtil_v2.semester.date_start_date__c.addMonths(2);
            update c;
            system.assert(![SELECT id, Active__c FROM Student__c WHERE id =: s.id].Active__c);
            
            c.Active__c = true;
            update c;
            system.assert([SELECT id, Active__c FROM Student__c WHERE id =: s.id].Active__c);
            
        Test.stopTest();
    }
    
    static testMethod void testUpdateRefId() {
        createTestData();
          Contact c=testDataSetupUtil_v2.studContactsList[0];
    	Student__c s = testDataSetupUtil_v2.studentsList[0];
        Test.startTest();
            c.Reference_Id__c = 'newRefID';
            update c;
            
            Student__c student = [SELECT id, Student_Id__c, School_Reference_Id__c, Reference_Id__c FROM Student__c WHERE id =: s.id];
            system.assert(student.Reference_Id__c == 'newRefID'+'_'+student.School_Reference_Id__c+'_'+testDataSetupUtil_v2.activeSetup.year__r.name__c);
            system.assert(student.Student_Id__c == 'newRefID');
             
        Test.stopTest();
    }
}