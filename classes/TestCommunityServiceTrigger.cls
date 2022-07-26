@isTest
private class TestCommunityServiceTrigger {

	static Community_Service__c testCommunityService = new Community_Service__c();
	
	static void setupTest(){
		
		testDataSetupUtil_v2.setUPCoreData(0);
		testDataSetupUtil_v2.setUpStaffData(0);
		testDataSetupUtil_v2.setUpStudentData(1);
		testDataSetupUtil_v2.studentsList[0].Service_Hours_YTD__c = null;
		
		testCommunityService.Name = 'Test Project';
		testCommunityService.Contact__c = testDataSetupUtil_v2.studContactsList[0].Id;
		testCommunityService.Student__c = testDataSetupUtil_v2.studentsList[0].Id;
		testCommunityService.Service_Hours_Completed__c = 0;
		insert testCommunityService;
		
	}

	static testMethod void testCommunityServiceInsert() {
		setupTest();
    }
    
    static testMethod void testCommunityServiceUpdate() {
    	setupTest();
		testCommunityService.Service_Hours_Completed__c += 4;
		update testCommunityService;
    }
    
    static testMethod void testCommunityServiceDelete() {
    	setupTest();
		delete testCommunityService;
    }

}