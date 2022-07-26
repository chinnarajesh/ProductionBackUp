/**
 * Created by YuriyRudenko on 10/7/2020.
 */
@IsTest
public with sharing class CT_Batch_ProcessEOYDataTest{
    private static final Integer COUNT = 5;
    private static final Integer AMOUNT = 30;
    private static Setup__c setup;

    private static void setupData(){
        testDataSetupUtil_v2.setUPCoreData(COUNT);
        testDataSetupUtil_v2.setUPStaffData(COUNT);
        testDataSetupUtil_v2.setUPStudentData(COUNT);
        testDataSetupUtil_v2.setUPProgramData(testDataSetupUtil_v2.sectionsList, testDataSetupUtil_v2.school);
        testDataSetupUtil_v2.setUPExistingSessionResults(AMOUNT);

        setup = [SELECT id, Active__c
        FROM Setup__c
        LIMIT 1];

    }

    static testMethod void testBatch() {
        setupData();
        
        Test.startTest();
        Database.executeBatch(new CT_Batch_ProcessEOYData('Student__c', setup.Id));
        Test.stopTest();
    }
}