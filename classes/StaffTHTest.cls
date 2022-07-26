@isTest
private class StaffTHTest {

	@isTest static void testDelete(){
		TestDataSetupUtil_v2.setupCoreData(5);
		TestDataSetupUtil_v2.setupStaffData(5);

		TestDataSetupUtil_v2.teachersList[0].Active__c = false;
		update TestDataSetupUtil_v2.teachersList[0];

		delete TestDataSetupUtil_v2.teachersList;
	}

	@isTest static void populateSectionsTest() {
		Set<String> setProgramNames = new Set<String>();
		Set<String> setSelectedSections = new Set<String>();
		Integer countSections = 0;
		for(StaffSectionsCreation__mdt mdt: [SELECT Id, Program_Name__c, In_After_School__c, Start_Date__c, End_Date__c, 
							Section_Frequency__c, Target_Dosage__c, Notes__c FROM StaffSectionsCreation__mdt]){
			setProgramNames.add(mdt.Program_Name__c);
			setSelectedSections.add(mdt.Program_Name__c + (mdt.In_After_School__c!=StaffTH.None? StaffTH.SEPARATORPROGRAM + mdt.In_After_School__c: ''));
			countSections++;
		}	
		TestDataSetupUtil_v2.setupCoreData(5);
		TestDataSetupUtil_v2.setupStaffData(5);
		TestDataSetupUtil_v2.setUPProgramData(new List<String>(setProgramNames), TestDataSetupUtil_v2.school);

		Test.startTest();
			TestDataSetupUtil_v2.teachersList[0].CreateSections__c = String.join(new List<String>(setSelectedSections), ';');
			update TestDataSetupUtil_v2.teachersList[0];
		Test.stopTest();

		List<Section__c> sections = [SELECT Id, Name FROM Section__c WHERE RecordType.Name = 'Intervention Section'];
		System.assertEquals(countSections, sections.size());
	}
	
}