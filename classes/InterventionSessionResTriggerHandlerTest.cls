@IsTest
public class InterventionSessionResTriggerHandlerTest {

    @IsTest
    static void isBeforeInsertTest() {
        TestDataSetupUtil_v2.setUPCoreData(3);
        TestDataSetupUtil_v2.setUpStaffData(5);
        TestDataSetupUtil_v2.setUpStudentData(5);

        Test.startTest();
        List<Section__c> section = [SELECT Id, Name, Intervention_Primary_Staff__c From Section__c];
        List<Student_Section__c> studentSectionList = [SELECT Id, Name From Student_Section__c];

        Intervention_Session__c intervensionSession = TestDataUtil.createInterventionSession(
                section[0].Id,
                null,
                TestDataSetupUtil_v2.teachersList[0].Id
            );
        insert intervensionSession;

        Intervention_Session_Result__c intervensionSessionResult = new Intervention_Session_Result__c(Intervention_Session__c = intervensionSession.Id, Student_Section__c = studentSectionList[0].Id, Amount_of_Time__c = 1);
        insert intervensionSessionResult;
        Test.stopTest();

        List<Intervention_Session_Result__c> isr = [SELECT Id, Intervention_Session__c From Intervention_Session_Result__c];
        System.assertEquals(intervensionSession.Id, isr[0].Intervention_Session__c);

    }
}