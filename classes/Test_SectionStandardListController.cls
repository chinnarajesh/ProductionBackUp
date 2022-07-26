@isTest
private class Test_SectionStandardListController {
	static testMethod void TestConstructor() {
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);
		testDataSetupUtil_v2.setUpStandards();

		List<Section_standard__c> secStandards = new List<Section_standard__c>();
		secStandards.add(new Section_standard__c(Standard__c=testDataSetupUtil_v2.strandStandard.id, Section__c = testDataSetupUtil_v2.sectionsList[1].id));

		for(Standard__c s:testDataSetupUtil_v2.testStandards){
			secStandards.add(new Section_standard__c(Standard__c=s.id, Section__c = testDataSetupUtil_v2.sectionsList[1].id));
		}

		insert secStandards;
		
		Test.startTest();
			ApexPages.StandardController con = new ApexPages.StandardController(testDataSetupUtil_v2.sectionsList[1]);
			Section_StandardsListController controller = new Section_StandardsListController(con);
			 
			system.assertEquals(testDataSetupUtil_v2.sectionsList[1].id, controller.section.id, 'Section Ids do not match.');
			system.assertEquals(1, controller.standards.size(), 'There should only be 1 strand standard.');
			system.assertEquals(4, controller.standards[0].childStandards.size(), 'There should be 4 child standards.');
			 
			for(Standard__c s: controller.standards[0].childStandards){
				system.assertEquals(controller.standards[0].standard.id, s.Strand__c, 'Theses standards should have the strand as a parent.');
			}
		Test.stopTest();
	}
}