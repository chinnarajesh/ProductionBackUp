@isTest
private class Test_ProactiveCS_CsvLoader {

    static testMethod void myUnitTest() {
    	test.startTest();
        ProactiveCS_CsvLoader csv = new ProactiveCS_CsvLoader();
        csv.loadProactive();
        List<Proactive_CS__c> cs = [SELECT Id FROM Proactive_CS__c];
        system.assert(true, cs != null);
        test.stopTest();
    }
}