@isTest
private class Test_PicklistValue {

	static void setupData(){
		test_Gradebook.setupData();
		test_Gradebook.createAssignment();
	}
	
	static testMethod void testDeleteAssignmentTypeValidation(){
		setupData();
		test.startTest();
		try { 
			delete [select id from Picklist_Value__c where id =:test_Gradebook.testAssign.Assignment_Library__r.picklist_value__c];
		}
		catch (exception e){
			system.assert(e.getMessage().contains('Assignment Type is related to 1 or more Assignment Libraries, please update the Assignment Type on the Assignment Library records before deleting'));
		}
		test.stopTest();
	}
}