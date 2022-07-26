@isTest
private class Test_IndicatorAreaTrigger {
	
	@isTest static void test_method_one() {
		TestDataUtil.setupData(1);
		Indicator_Area__c ia = TestDataUtil.createIndicatorAreas(1)[0];
		insert ia;

		Test.startTest();
			ia.Active__c = false;
			update ia;
		Test.stopTest();

		ia = [select id, Active__c from Indicator_Area__c where ID =: ia.id];
		system.assertEquals(false, ia.Active__c);
	}
}