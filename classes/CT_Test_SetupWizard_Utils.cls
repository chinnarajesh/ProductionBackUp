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
private class CT_Test_SetupWizard_Utils {

	static testMethod void testQuerySchools() {
		Test.startTest();
			List<Account> schools = CT_SetupWizard_Utils.querySchools();
			system.assertEquals(0,schools.size());
			
			TestDataSetupUtil_v2.setupCoreData(1);
			schools = CT_SetupWizard_Utils.querySchools();
			system.assertEquals(1,schools.size());
		Test.stopTest();
	}
	
	static testMethod void testQueryYears(){
		Test.startTest();
			List<Time_Element__c> years = CT_SetupWizard_Utils.queryYears();
			system.assertEquals(0,years.size());
			
			TestDataSetupUtil_v2.setupCoreData(1);
			years = CT_SetupWizard_Utils.queryYears();
			system.assertEquals(1,years.size());
		Test.stopTest();
	}
	
	static testMethod void testGetSetupById(){
		Test.startTest();
			TestDataSetupUtil_v2.setupCoreData(1);
			Setup__c setup = CT_SetupWizard_Utils.getSetupById(TestDataSetupUtil_v2.activeSetup.id);
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,setup.id);
		Test.stopTest();
	}
	
	static testMethod void testGetEOYProgressRecord(){
		Test.startTest();
			TestDataSetupUtil_v2.setupCoreData(1);
			EOY_Progress__c progress = CT_SetupWizard_Utils.getEOYProgressRecord(TestDataSetupUtil_v2.activeSetup);
			system.assertEquals(null,progress.id);
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,progress.Setup__c);
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.Year__c,progress.Year__c);
			system.assertEquals(CT_SetupWizard_Utils.SW_RECORD_TYPE,progress.RecordTypeId);
			
			insert progress;
			EOY_Progress__c newProgress = CT_SetupWizard_Utils.getEOYProgressRecord(TestDataSetupUtil_v2.activeSetup);
			system.assertEquals(progress.id,newProgress.id);
			
		Test.stopTest();
	}
}