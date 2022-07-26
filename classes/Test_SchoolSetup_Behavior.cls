@isTest
private class Test_SchoolSetup_Behavior {
	private static void setupData(){
		TestDataSetupUtil_v2.setupCoreData(5);

		PageReference p = Page.SchoolSetup_Behavior;
		p.getParameters().put('setupId', TestDataSetupUtil_v2.activeSetup.id);
		Test.setCurrentPage(p);

		TestDataSetupUtil_v2.createBehaviorPicklistValues();
	}


	@isTest static void Test_Edit() {
		setupData();
		Test.startTest();
			SchoolSetup_Behavior controller = new SchoolSetup_Behavior();
			system.assertNotEquals(0, controller.behaviorTypes.size());
			system.assertNotEquals(0, controller.consequences.size());

			controller.selectedValue = controller.behaviorTypes[0].id;
			controller.editValue();
			controller.editHolder.Name = 'Something unique';
			controller.saveValue();
			system.assertEquals('Something unique', controller.behaviorTypes[0].Name);
			system.assertEquals('Something unique', [select Name from Picklist_Value__c where ID =: controller.behaviorTypes[0].id].Name);

			//test the save options here too
			controller.saveOptions();
		Test.stopTest();
	}

	@isTest static void Test_New() {
		setupData();
		Test.startTest();
			SchoolSetup_Behavior controller = new SchoolSetup_Behavior();
			system.assertNotEquals(0, controller.behaviorTypes.size());
			system.assertNotEquals(0, controller.consequences.size());

			Integer preAddSize = controller.behaviorTypes.size();

			controller.newValue();
			controller.editHolder = controller.behaviorTypes[0];
			controller.editHolder.id = null;
			controller.editHolder.Name = 'New copy';
			controller.saveValue();
			System.assertEquals(preAddSize+1,controller.behaviorTypes.size());

			//test the cancel here really quick too
			controller.newValue();
			controller.cancelEdit();
		Test.stopTest();
	}

	@isTest static void Test_Delete(){
		setupData();
		Test.startTest();
			SchoolSetup_Behavior controller = new SchoolSetup_Behavior();
			system.assertNotEquals(0, controller.behaviorTypes.size());
			system.assertNotEquals(0, controller.consequences.size());

			Integer preDeleteSize = controller.behaviorTypes.size();

			controller.selectedValue = controller.behaviorTypes[0].id;
			controller.deleteValue();
			system.assertEquals(preDeleteSize-1, controller.behaviorTypes.size());
			system.assertEquals(preDeleteSize-1, [select id from Picklist_Value__c where RecordTypeId =: core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Behavior_Type')].size());
			system.assertEquals(0, [select id from Picklist_Value__c where ID=: controller.selectedValue].size());
		Test.stopTest();
	}
}