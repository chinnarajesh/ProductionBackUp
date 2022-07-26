/**
 * Created by TarasTorubka on 04.11.2020.
 */
@isTest
private class CT_UpdateSObjectsTest {

    @TestSetup
    private static void init() {
        Account acc = new Account(
                Name = 'Test'
        );
        insert acc;
    }

    @isTest static void test_NoSObjectName() {
        Test.startTest();
        CT_UpdateSObjects.usingSObjectAPIName('');
        Test.stopTest();
    }

    @isTest static void test_IncorrectBatchSize() {
        Test.startTest();
        CT_UpdateSObjects.usingSObjectAPIName('Account', 9000);
        Test.stopTest();
    }

    @isTest static void test_SObjectName() {
        Test.startTest();
        CT_UpdateSObjects.usingSObjectAPIName('Account');
        Test.stopTest();
    }

    @isTest static void test_SObjectNameWithBatchSize() {
        Test.startTest();
        CT_UpdateSObjects.usingSObjectAPIName('Account', 1);
        Test.stopTest();
    }

    @isTest static void test_SOQL() {
        Test.startTest();
        CT_UpdateSObjects.usingSOQL('SELECT Id FROM Account');
        Test.stopTest();
    }

    @isTest static void test_SOQLWithBatchSize() {
        Test.startTest();
        CT_UpdateSObjects.usingSOQL('SELECT Id FROM Account', 1);
        Test.stopTest();
    }

    @isTest static void test_runBatch() {
        Test.startTest();
        CT_UpdateSObjects.runBatch('SELECT Id FROM Account', 1);
        Test.stopTest();
    }
}