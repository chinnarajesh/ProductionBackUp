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
private class CT_Test_SetupWizardSidebar {

	static testMethod void testSidebar() {
		TestDataSetupUtil_v2.setupCoreData(1);
		CT_SetupWizardSidebar sws = new CT_SetupWizardSidebar();
		Test.startTest();
			system.assertEquals(null,sws.schoolSetup);
			sws.cSetupId = TestDataSetupUtil_v2.activeSetup.id;
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,sws.schoolSetup.id);
			
			system.assertEquals(CT_SetupWizard_Utils.TERMS,sws.TERMS);
			system.assertEquals(CT_SetupWizard_Utils.SELECTIONS,sws.SELECTIONS);
			system.assertEquals(CT_SetupWizard_Utils.TEMPLATES,sws.TEMPLATES);
			system.assertEquals(CT_SetupWizard_Utils.CALENDAR,sws.CALENDAR);
			system.assertEquals(CT_SetupWizard_Utils.COURSE_CATALOG,sws.COURSE_CATALOG);
			system.assertEquals(CT_SetupWizard_Utils.ROOMS,sws.ROOMS);
			system.assertEquals(CT_SetupWizard_Utils.STAFF,sws.STAFF);
			system.assertEquals(CT_SetupWizard_Utils.GROUP_CONFIG,sws.GROUP_CONFIG);
			system.assertEquals(CT_SetupWizard_Utils.SCHEDULE,sws.SCHEDULE);
			system.assertEquals(CT_SetupWizard_Utils.STUDENT_SECTIONS,sws.STUDENT_SECTIONS);
			system.assertEquals(CT_SetupWizard_Utils.PUBLISH,sws.PUBLISH);
			system.assertEquals(CT_SetupWizard_Utils.ACTIVATION,sws.ACTIVATION);

			//chechk school sds activation
			sws.activateSDSSchool();
			Account acc = [SELECT Id, SDS_School__c FROM Account WHERE Id = :sws.schoolSetup.School__c LIMIT 1];
			System.assert(acc.SDS_School__c);			
		Test.stopTest();
	}
}