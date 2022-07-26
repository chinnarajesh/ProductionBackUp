/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Test_SchoolSetup_Home {

	static testMethod void testConstructor() {
		Test.startTest();
			PageReference pr = Page.SchoolSetup_Home;
			Test.setCurrentPage(pr);
			SchoolSetup_Home ssh = new SchoolSetup_Home();
			system.assertEquals(SchoolSetup_Home.NO_SETUP_MSG,ApexPages.getMessages()[0].getSummary());
			
			pr.getParameters().put('setupId',null);
			Test.setCurrentPage(pr);
			ssh = new SchoolSetup_Home();
			system.assertEquals(SchoolSetup_Home.NO_SETUP_MSG,ApexPages.getMessages()[0].getSummary());
			
			TestDataSetupUtil_v2.setUPCoreData(1);
			pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetUp.id);
			Test.setCurrentPage(pr);
			ssh = new SchoolSetup_Home();
			system.assertEquals(TestDataSetupUtil_v2.activeSetUp.id,ssh.schoolSetup.id);
			system.assertEquals(null,ssh.progress.id);
		Test.stopTest();
	}
	
	static testMethod void testSaveModules(){
		SchoolSetup_Home ssh = createTestData();
		Test.startTest();
			ssh.schoolSetup.Using_Attendance__c = true;
			ssh.schoolSetup.Using_Gradebook__c = false;
			ssh.schoolSetup.Using_Student_Documents__c = true;
			ssh.saveModules();
			Setup__c setup = [SELECT id, Using_Attendance__c, Using_Gradebook__c, Using_Student_Documents__c FROM Setup__c WHERE id=:ssh.schoolSetup.id];
			system.assert(setup.Using_Attendance__c);
			system.assert(!setup.Using_Gradebook__c);
			//if gradebook not selected, documents not selected
			system.assert(!setup.Using_Student_Documents__c);
		Test.stopTest();
	}
	
	static testMethod void testRedirectToWizard(){
		SchoolSetup_Home ssh = createTestData();
		Test.startTest();
			PageReference testPR = ssh.redirectToWizard();
			system.assertEquals(null,testPR);
			
			PageReference pr = Page.SchoolSetup_Home;
			pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetUp.id);
			pr.getParameters().put('wizardName',SchoolSetup_Home.GRADEBOOK);
			Test.setCurrentPage(pr);
			testPR = ssh.redirectToWizard();
			system.assert(testPR.getURL().toLowerCase().contains('schoolsetup_gradebook'));
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,testPR.getParameters().get('setupId'));
			
			pr = Page.SchoolSetup_Home;
			pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetUp.id);
			pr.getParameters().put('wizardName',SchoolSetup_Home.ATTENDANCE);
			Test.setCurrentPage(pr);
			testPR = ssh.redirectToWizard();
			system.assert(testPR.getURL().toLowerCase().contains('schoolsetup_attendance'));
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,testPR.getParameters().get('setupId'));
			
			pr = Page.SchoolSetup_Home;
			pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetUp.id);
			pr.getParameters().put('wizardName',SchoolSetup_Home.BEHAVIOR);
			Test.setCurrentPage(pr);
			testPR = ssh.redirectToWizard();
			system.assert(testPR.getURL().toLowerCase().contains('schoolsetup_behavior'));
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,testPR.getParameters().get('setupId'));
			
			pr = Page.SchoolSetup_Home;
			pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetUp.id);
			pr.getParameters().put('wizardName',SchoolSetup_Home.DOCUMENTS);
			Test.setCurrentPage(pr);
			testPR = ssh.redirectToWizard();
			system.assert(testPR.getURL().toLowerCase().contains('schoolsetup_documents'));
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,testPR.getParameters().get('setupId'));
		Test.stopTest();
	}
	
	static SchoolSetup_Home createTestData(){
		TestDataSetupUtil_v2.setUPCoreData(1);
		PageReference pr = Page.SchoolSetup_Home;
		pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetUp.id);
		Test.setCurrentPage(pr);
		SchoolSetup_Home ssh = new SchoolSetup_Home();
		return ssh;
	}
}