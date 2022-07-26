@isTest
private class TestCommunityServiceWizardController {

	static void setupTest() {
		
		testDataSetupUtil_v2.setUPCoreData(0);
		testDataSetupUtil_v2.setUpStaffData(0);
		testDataSetupUtil_v2.setUpStudentData(1);
		
		CommunityServiceWizardController controller = new CommunityServiceWizardController();
		controller.communityService.Name = 'TestCommunityServiceWizard';
		controller.communityService.Contact__c = testDataSetupUtil_v2.studContactsList[0].Id;
		controller.communityService.Student__c = testDataSetupUtil_v2.studentsList[0].Id;
		controller.communityService.Service_Hours_Completed__c = 2;
		controller.communityService.Service_Start_Date__c = Date.newInstance(2012, 9, 1);
		insert controller.communityService;
		
		controller.searchStudents();
		System.assert(true, controller.showSearchResults);
		controller.addStudents();
		controller.removeStudents();
		controller.addCommunityService();
		controller.saveCommunityService();
		
	}

    static testMethod void testController() {
		setupTest();
    }
}