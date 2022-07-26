@isTest
private class Test_StudentTrigger {

	public static void createTestData(){
		testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUPStudentData(5);
	}
	
    static testMethod void testOnDelete() {
        createTestData();
        
        Test.startTest();
            delete TestDataSetupUtil_v2.studentsList[0];
            
            List<Student_Section__c> ss = [select id from Student_Section__c where Student__c =:TestDataSetupUtil_v2.studentsList[0].id];
            system.assert(ss.size() == 0);
        Test.stopTest();
    }
     
    static testMethod void testIdUpdateOnContacts() {
     createTestData();       
       Test.startTest();
       TestDataSetupUtil_v2.studentsList[0].Reference_Id__c = 'something random';
       TestDataSetupUtil_v2.studentsList[0].Student_Id__c = 'NCC1701';
       update TestDataSetupUtil_v2.studentsList[0];
    
       Contact c = [select id, Reference_Id__c from Contact where id =: TestDataSetupUtil_v2.studentsList[0].Individual__c];
       Student__c s = [select id, Student_Id__c, Reference_Id__c, School_Reference_Id__c, Setup_Year_Name__c from Student__c where id =: TestDataSetupUtil_v2.studentsList[0].id];
       system.assertEquals('NCC1701'+'_'+s.School_Reference_Id__c+'_'+s.Setup_Year_Name__c, s.Reference_Id__c);
       system.assertEquals(s.Student_Id__c, c.Reference_Id__c);

       Test.stopTest();
    }
  
    static testMethod void testStudentSectionActivation() {
        createTestData();
        Test.startTest();
            TestDataSetupUtil_v2.studentsList[0].Active__c = false;
            TestDataSetupUtil_v2.studentsList[0].exit_date__c = TestDataSetupUtil_v2.semester.date_start_date__c.addMonths(1);
            TestDataSetupUtil_v2.studentsList[0].Student_Exit_Reason__c = CT_core_triggerUtils.SECTIONEXITREASONBYTRIGGER;
            update TestDataSetupUtil_v2.studentsList[0];
            
            List<Student_Section__c> ss = [select id, Active__c from Student_Section__c where Student__c =: TestDataSetupUtil_v2.studentsList[0].id];
            system.assert(ss.size()>0);
            system.assert(!ss[0].Active__c);
            
            TestDataSetupUtil_v2.studentsList[0].Active__c = true;
            TestDataSetupUtil_v2.studentsList[0].Entry_Date__c = TestDataSetupUtil_v2.semester.date_start_date__c.addMonths(1);
            update TestDataSetupUtil_v2.studentsList[0];
            
            ss = [select id, Active__c from Student_Section__c where Student__c =: TestDataSetupUtil_v2.studentsList[0].id];
            system.assert(ss.size()>0);
            system.assert(!ss[0].Active__c);
    }
    
    static testMethod void testIdAndFieldUpdateOnContacts() {
    	createTestData();
        
        Test.startTest();
            TestDataSetupUtil_v2.studentsList[0].Reference_Id__c = 'something random';
            TestDataSetupUtil_v2.studentsList[0].Student_Id__c = 'NCC1701';
            
            system.assert(TestDataSetupUtil_v2.studentsList[0].Gender__c != 'Male');
            system.assert(TestDataSetupUtil_v2.studentsList[0].Active__c);
            TestDataSetupUtil_v2.studentsList[0].Gender__c = 'Male';
            update TestDataSetupUtil_v2.studentsList[0];
            
            Contact c = [select id, Reference_Id__c, Gender__c from Contact where id =: TestDataSetupUtil_v2.studentsList[0].Individual__c];
	       Student__c s = [select id, Student_Id__c, Reference_Id__c, School_Reference_Id__c, Setup_Year_Name__c from Student__c where id =: TestDataSetupUtil_v2.studentsList[0].id];
       		system.assertEquals('NCC1701'+'_'+s.School_Reference_Id__c+'_'+s.Setup_Year_Name__c, s.Reference_Id__c);
            system.assertEquals('NCC1701', c.Reference_Id__c);
            system.assertEquals('Male', c.Gender__c);
        Test.stopTest();
    }

    static testMethod void testExternalEvaluatedProcessEndsWithError() {
        testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        List<Contact> studContactsList = testDataSetupUtil_v2.getContacts(5, 'Student', null);
        Test.startTest();
            List<Student__c> studentsList = testDataSetupUtil_v2.getStudentsWithLocalId('!!!!!!', 5, 'Student', studContactsList);
        Test.stopTest();
        studentsList = [SELECT External_Evaluation_ID__c, CY_YOY_Student_EEID__c
                        FROM Student__c WHERE Id IN:studentsList];
        for(Student__c student : studentsList) {
            System.assertEquals('Invalid - Local Student ID is not valid, unable to calculate', student.External_Evaluation_ID__c);
            System.assertEquals('Invalid - Local Student ID is not valid, unable to calculate', student.CY_YOY_Student_EEID__c);
        }
    }

    static testMethod void testExternalEvaluatedProcessEndsWithErrorNotEnoughCharacters() {
        testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        List<Contact> studContactsList = testDataSetupUtil_v2.getContacts(5, 'Student', null);
        Test.startTest();
            List<Student__c> studentsList = testDataSetupUtil_v2.getStudentsWithLocalId('123', 5, 'Student', studContactsList);
        Test.stopTest();
        studentsList = [SELECT External_Evaluation_ID__c, CY_YOY_Student_EEID__c
                        FROM Student__c WHERE Id IN:studentsList];
        for(Student__c student : studentsList) {
            System.assertEquals('767778767778', student.External_Evaluation_ID__c);
            System.assertEquals('Invalid - Local Student ID Less Than 5 characters', student.CY_YOY_Student_EEID__c);
        }
    }

    static testMethod void testExternalEvaluatedProcessSuccess() {
        testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        List<Contact> studContactsList = testDataSetupUtil_v2.getContacts(5, 'Student', null);
        Test.startTest();
        List<Student__c> studentsList = testDataSetupUtil_v2.getStudentsWithLocalId('123abc', 5, 'Student', studContactsList);
        Test.stopTest();
        studentsList = [SELECT External_Evaluation_ID__c, CY_YOY_Student_EEID__c
        FROM Student__c WHERE Id IN:studentsList];
        for(Student__c student : studentsList) {
            System.assertEquals('77785051527677785051', student.External_Evaluation_ID__c);
            System.assertEquals('7141717171717171717171715357585871717171526949505154', student.CY_YOY_Student_EEID__c);
        }
    }
    
	 
}