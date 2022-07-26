@isTest
private class CT_Test_SchoolSetup_Staff {
	static testMethod void testInit(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);  
		PageReference staffSetupPage = Page.CT_SchoolSetup_Staff;
		Test.setCurrentPageReference(staffSetupPage);
		ApexPages.currentPage().getParameters().put('setupid',testDataSetupUtil_v2.activeSetUp.Id);
		Test.startTest();
		{
			CT_SchoolSetup_Staff init = new CT_SchoolSetup_Staff();
		}
		Test.stopTest();
		
	}
	static testMethod void testPublish(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);  
		PageReference staffSetupPage = Page.CT_SchoolSetup_Staff;
		Test.setCurrentPageReference(staffSetupPage);
		ApexPages.currentPage().getParameters().put('setupid',testDataSetupUtil_v2.activeSetUp.Id);
		Test.startTest();
		{
			CT_SchoolSetup_Staff init = new CT_SchoolSetup_Staff();
			init.publishData();	
		}
		Test.stopTest();
	}
	static testMethod void testNext(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);  
		PageReference staffSetupPage = Page.CT_SchoolSetup_Staff;
		Test.setCurrentPageReference(staffSetupPage);
		ApexPages.currentPage().getParameters().put('setupid',testDataSetupUtil_v2.activeSetUp.Id);
		Test.startTest();
		{
			CT_SchoolSetup_Staff init = new CT_SchoolSetup_Staff();
			init.next();	
		}
		Test.stopTest();
	}
	static testMethod void testPrev(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);  
		PageReference staffSetupPage = Page.CT_SchoolSetup_Staff;
		Test.setCurrentPageReference(staffSetupPage);
		ApexPages.currentPage().getParameters().put('setupid',testDataSetupUtil_v2.activeSetUp.Id);
		Test.startTest();
		{
			CT_SchoolSetup_Staff init = new CT_SchoolSetup_Staff();
			init.prev();	
		}
		Test.stopTest();
	}	
}