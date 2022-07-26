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
private class Test_SchoolSetup_StudentSections {

	static testMethod void testConstructor() {
		PageReference pr = Page.SchoolSetup_StudentSections;
		Test.setCurrentPage(pr);
		Test.startTest();
			SchoolSetup_StudentSections ssss = new SchoolSetup_StudentSections();
			system.assertEquals(null,ssss.setupId);
			system.assertEquals(SetupWizard_Utils.NO_SETUP_MESSAGE,ApexPages.getMessages()[0].getSummary());
			
			pr.getParameters().put('setupId',null);
			Test.setCurrentPage(pr);
			ssss = new SchoolSetup_StudentSections();
			system.assertEquals(SetupWizard_Utils.NO_SETUP_MESSAGE,ApexPages.getMessages()[0].getSummary());
			
			TestDataSetupUtil_v2.setUPCoreData(1);
			pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
			Test.setCurrentPage(pr);
			ssss = new SchoolSetup_StudentSections();
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,ssss.setupId);
			system.assertEquals('Student/Section',ssss.csvLoader.selectedLoadType);
			system.assert(!ssss.csvLoader.bNeedsType);
		Test.stopTest();
	}
	
	static testMethod void testPrev(){
		SchoolSetup_StudentSections ssss = createTestData();
		Test.startTest();
			PageReference pr = ssss.prev();
			if(TestDataSetupUtil_v2.activeSetup.Group_Based__c)
				system.assert(pr.getURL().toLowerCase().contains('groupagendaview'));
			else
				system.assert(pr.getURL().toLowerCase().contains('scheduler_grid'));
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,pr.getParameters().get('setupId'));
		Test.stopTest();
	}
	
	static testMethod void testNext(){
		SchoolSetup_StudentSections ssss = createTestData();
		Test.startTest();
			PageReference pr = ssss.next();
			system.assert(pr.getURL().toLowerCase().contains('core_publishsetup'));
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,pr.getParameters().get('setupId'));
		Test.stopTest();
	}
	
	static SchoolSetup_StudentSections createTestData(){
		TestDataSetupUtil_v2.setUPCoreData(1);
		PageReference pr = Page.SchoolSetup_StudentSections;
		pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
		Test.setCurrentPage(pr);
		return new SchoolSetup_StudentSections();
	}
}