@IsTest
public without sharing class StudentUpdateBatchTest {

    public static testMethod void testBatch() {
        testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        List<Contact> studContactsList = testDataSetupUtil_v2.getContacts(5, 'Student', null);
        List<sObject> studentsList = testDataSetupUtil_v2.getStudentsWithLocalId('123abc', 5, 'Student', studContactsList);
        for (sObject stud : studentsList) {
            stud.put('External_Evaluation_ID__c','');
        }
        Test.StartTest();
            StudentUpdateBatch studentUpdateBatchJob = new StudentUpdateBatch();
            Database.QueryLocator ql = studentUpdateBatchJob.start(null);
            studentUpdateBatchJob.execute(null, studentsList);
            studentUpdateBatchJob.finish(null);
        Test.StopTest();

        System.AssertEquals(
                Database.countquery('SELECT COUNT()'
                        +' FROM Student__c WHERE External_Evaluation_ID__c = \'\''),
                0);
    }
}