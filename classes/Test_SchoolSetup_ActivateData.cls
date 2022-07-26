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
private class Test_SchoolSetup_ActivateData {

	static testMethod void testConstructor() {
		PageReference pr = Page.SchoolSetup_ActivateData;
		Test.setCurrentPage(pr);
		Test.startTest();
			SchoolSetup_ActivateData ssad = new SchoolSetup_ActivateData();
			system.assertEquals(null,ssad.schoolSetup);
			system.assertEquals(SetupWizard_Utils.NO_SETUP_MESSAGE,ApexPages.getMessages()[0].getSummary());
			system.assert(!ssad.bDisable);
			system.assert(!ssad.bProcessing);
			
			pr.getParameters().put('setupId',null);
			Test.setCurrentPage(pr);
			ssad = new SchoolSetup_ActivateData();
			system.assertEquals(null,ssad.schoolSetup);
			system.assertEquals(SetupWizard_Utils.NO_SETUP_MESSAGE,ApexPages.getMessages()[0].getSummary());
			
			TestDataSetupUtil_v2.setUPCoreData(1);
			pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
			Test.setCurrentPage(pr);
			ssad = new SchoolSetup_ActivateData();
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,ssad.schoolSetup.id);
			system.assertEquals('School data must be activated before the setup process can be completed.',ApexPages.getMessages()[1].getSummary());
			
			TestDataSetupUtil_v2.activeSetup.Data_Activated__c = true;
			update TestDataSetupUtil_v2.activeSetup;
			ssad = new SchoolSetup_ActivateData();
			system.assertEquals('Your data has been activated.  No further action is required.',ApexPages.getMessages()[2].getSummary());
			
			Time_Element__c prevYear = new Time_Element__c(Name__c='Previous Year',
															Picklist_Value__c=TestDataSetupUtil_v2.YearPickVal.id,
															Date_Start_Date__c=TestDataSetupUtil_v2.masterYear.Date_Start_Date__c.addYears(-1),
															End_Date__c=TestDataSetupUtil_v2.masterYear.End_Date__c.addYears(-1));
			insert prevYear;
			ssad = new SchoolSetup_ActivateData();
			system.assert(ssad.bDisable);
			system.assertEquals('Your school has not completed the EOY process for the '+prevYear.Name__c+' school year.  Please complete this process before activating your data.',ApexPages.getMessages()[3].getSummary());
		Test.stopTest();
	}
	
	static testMethod void testPrevEOYComplete(){
		SchoolSetup_ActivateData ssad = createTestData();
		Test.startTest();
			boolean returned = ssad.prevEOYComplete(null);
			system.assert(returned);
			Time_Element__c prevYear = new Time_Element__c(Name__c='Previous Year',
																Picklist_Value__c=TestDataSetupUtil_v2.YearPickVal.id,
																Date_Start_Date__c=TestDataSetupUtil_v2.masterYear.Date_Start_Date__c.addYears(-1),
																End_Date__c=TestDataSetupUtil_v2.masterYear.End_Date__c.addYears(-1));
			insert prevYear;
			//no EOY data, but setup should be created, so EOY not complete
			returned = ssad.prevEOYComplete(prevYear);
			system.assert(!returned);
			
			Setup__c setup = [SELECT id, School__c, Year__c FROM Setup__c WHERE School__c=:TestDataSetupUtil_v2.activeSetUp.School__c AND Year__c=:prevYear.id];
			EOY_Progress__c progress = new EOY_Progress__c(Year__c=setup.Year__c, RecordTypeId=core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY'), Module_Name__c = 'SchoolForce');
			insert progress;
			//EOY data, but not marked complete
			returned = ssad.prevEOYComplete(prevYear);
			system.assert(!returned);
			
			progress.School_Purge_Historical_Data_Completed__c=true;
			progress.Is_Complete__c = true;
			update progress;
			//now considered complete
			returned = ssad.prevEOYComplete(prevYear);
			system.assert(returned);
			
			//if setup doesn't exist for previous year, consider EOY complete
			delete setup;
			returned = ssad.prevEOYComplete(prevYear);
			system.assert(returned);
		Test.stopTest();
	}
	
	static testMethod void testGetLogs(){
		SchoolSetup_ActivateData ssad = createTestData();
		Test.startTest();
			List<Data_Load_Log__c> dll = new List<Data_Load_Log__c>();
			for(integer i=0;i<=5;i++){
				Data_Load_Log__c log = new Data_Load_Log__c(Type__c=i+'',Setup__c=ssad.schoolSetup.id,Class_Name__c='Batch_ProcessEOYData');
				dll.add(log);
			}
			insert dll;
			ssad.getLogs();
			//should be sorted by type
			String oldType = '';
			for(Data_Load_Log__c log: ssad.logs){
				if(oldType!='') system.assert(log.Type__c >= oldType);
				oldType = log.Type__c;
			}
			
			Data_Load_Log__c newLog = new Data_Load_Log__c(Type__c='1',Setup__c=ssad.schoolSetup.id,Class_Name__c='Batch_ProcessEOYData');
			insert newLog;
			ssad.getLogs();
			//should only keep the newest log
			//for(Data_Load_Log__c log: ssad.logs){
			//	if(log.Type__c=='1') system.assertEquals(newLog.id,log.id);
			//}
		Test.stopTest();
	}
	
	static testMethod void testContinueBatch(){
		SchoolSetup_ActivateData ssad = createTestData();
		Test.startTest();
			List<Global_Error__c> ge = [SELECT id FROM Global_Error__c];
			PageReference pr = ssad.continueBatch();
			system.assertEquals('There was an error while checking the status of the batch.',ApexPages.getMessages()[1].getSummary());
			system.assertEquals(ge.size()+1,[SELECT count() FROM Global_Error__c]);
			system.assertEquals(null,pr);
		Test.stopTest();
	}
	
	static testMethod void testProcessData(){
		SchoolSetup_ActivateData ssad = createTestData();
		Test.startTest();
			ssad.schoolSetup.Active__c = false;
			update ssad.schoolSetup;
			Setup__c testSetup = [SELECT Active__c FROM Setup__c WHERE id=:TestDataSetupUtil_v2.activeSetup.id];
			system.assert(!testSetup.Active__c);
			
			ssad.processData();
			testSetup = [SELECT Active__c FROM Setup__c WHERE id=:TestDataSetupUtil_v2.activeSetup.id];
			system.assert(testSetup.Active__c);
			
			ssad.schoolSetup = null;
			List<Global_Error__c> ge = [SELECT id FROM Global_Error__c];
			ssad.processData();
			system.assertEquals(ge.size()+1,[SELECT count() FROM Global_Error__c]);
		Test.stopTest();
	}
	
	static testMethod void testPrev(){
		SchoolSetup_ActivateData ssad = createTestData();
		Test.startTest();
			PageReference pr = ssad.prev();
			system.assert(pr.getURL().toLowerCase().contains('core_publishsetup'));
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,pr.getParameters().get('setupId'));
		Test.stopTest();
	}
	
	static testMethod void testNext(){
		SchoolSetup_ActivateData ssad = createTestData();
		Test.startTest();
			PageReference pr = ssad.next();
			system.assertEquals(null,pr);
			system.assertEquals('School data must be activated before the setup process can be completed.',ApexPages.getMessages()[0].getSummary());
			
			ssad.schoolSetup.Data_Activated__c = true;
			update ssad.schoolSetup;
			pr = ssad.next();
			system.assert(pr.getURL().toLowerCase().contains('schoolsetup_home'));
			system.assertEquals(TestDataSetupUtil_v2.activeSetup.id,pr.getParameters().get('setupId'));
		Test.stopTest();
	}
	
	static SchoolSetup_ActivateData createTestData(){
		TestDataSetupUtil_v2.setupCoreData(1);
		PageReference pr = Page.SchoolSetup_ActivateData;
		pr.getParameters().put('setupId',TestDataSetupUtil_v2.activeSetup.id);
		Test.setCurrentPage(pr);
		return new SchoolSetup_ActivateData();
	}
}