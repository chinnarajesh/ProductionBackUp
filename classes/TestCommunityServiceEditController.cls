@isTest
private class TestCommunityServiceEditController {

    static testMethod void myUnitTest() {
        TestDataSetupUtil_v2.setUPCoreData(0);
        TestDataSetupUtil_v2.setUpStaffData(1);
        TestDataSetupUtil_v2.setUPStudentData(1);
        
        PageReference pref = Page.CommunityServiceEdit;
        pref.getParameters().put('sid',TestDataSetupUtil_v2.studentsList[0].id);
        Test.setCurrentPage(pref);
        
        Test.startTest();
        ApexPages.StandardController con = new ApexPages.StandardController(new Community_Service__c());
        CommunityServiceEditController controller = new CommunityServiceEditController(con);
        
        controller.communityService.Service_Hours_Completed__c = 24;
        controller.communityService.Organization_Name__c = 'test';
        controller.communityService.Service_Start_Date__c = system.today();
        controller.saveNewCommunityService();
        controller.saveCommunityService();
        controller.cancelCommunityService();
        
    }
}