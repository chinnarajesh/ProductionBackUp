@isTest
private class Test_BatchCloneSetupData {

	private static Meals_Setup__c mealsSetup;
	private static Value__c testValue;
	private static void setupData(){
		TestDataSetupUtil_v2.setUPCoreData(5);

		TestDataSetupUtil_v2.activeSetup.Published__c = true;
		update TestDataSetupUtil_v2.activeSetup;

		mealsSetup = new Meals_Setup__c(Setup__c = TestDataSetupUtil_v2.activeSetup.ID, Active__c = true);
		insert mealsSetup;

		testValue = new Value__c(Language__c = 'English',Type__c='Targy Alerts',Text_Alert__c='This is a test value.', Setup__c = TestDataSetupUtil_v2.activeSetup.ID);
		insert testValue;
		List<Picklist_Value__c> assignmentTypes = TestDataSetupUtil_v2.createDefaultAssignmentTypes();
		for(Picklist_Value__c assignmentType: assignmentTypes){
			assignmentType.Setup__c = TestDataSetupUtil_v2.activeSetup.ID;
		}
		update assignmentTypes;

		TestDataSetupUtil_v2.createDefaultAssignmentWeightings(TestDataSetupUtil_v2.coursesList, assignmentTypes);
	}
	
	@isTest static void Test_DataCloning() {
		setupData();
		Time_Element__c newYear;
		Test.startTest();
			newYear = TestDataSetupUtil_v2.getTimeElements_NoInsert(
				1,
				'Year',
				TestDataSetupUtil_v2.masterYear.Picklist_Value__c,
				null,
				TestDataSetupUtil_v2.masterYear.Date_Start_Date__c.addYears(1).format(),
				TestDataSetupUtil_v2.masterYear.End_Date__c.addYears(1).format(),
				false
			)[0];
			newYear.New_School_Year__c = true;
			newYear.Current__c = false;

			insert newYear;
		Test.stopTest();

		Setup__c newSetup = [select id from Setup__c where Year__c=: newYear.ID and School__c =: TestDataSetupUtil_v2.school.ID];
		
		System.assertEquals(1, [select id from Meals_Setup__c where Setup__c=: newSetup.ID].size());
		System.assertEquals(1, [select id from Value__c where Setup__c=: newSetup.ID].size());
		System.assertEquals([select id from Picklist_Value__c where Setup__c =: TestDataSetupUtil_v2.activeSetup.ID].size(), 
			[select id from Picklist_Value__c where Setup__c =: newSetup.ID].size());

		ID courseID  =TestDataSetupUtil_v2.coursesList[0].ID;
		System.assertEquals([select id from Default_Assignment_Weighting__c where Picklist_Value__r.Setup__c=:TestDataSetupUtil_v2.activeSetup.ID and Course__c =: courseID].size(),
			[select id from Default_Assignment_Weighting__c where Picklist_Value__r.Setup__c =:newSetup.ID and Course__c =: courseID].size());

	}
}