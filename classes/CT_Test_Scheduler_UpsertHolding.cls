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
private class CT_Test_Scheduler_UpsertHolding {

	static testMethod void testUpsertHoldingRecordsForPeriods() {
		List<Scheduled_Section__c> ss = setupData(false);
		Test.startTest();
			CT_Scheduler_UpsertHolding suh = new CT_Scheduler_UpsertHolding(new CT_core_SetupWrapper(TestDataSetupUtil_v2.activeSetup,'test'));
			suh.upsertHoldingRecordsForPeriods(ss);
			List<HoldingObj__c> ho = [SELECT id FROM HoldingObj__c WHERE School_DBN__c=:TestDataSetupUtil_v2.school.Reference_Id__c];
			system.assertEquals(ss.size(),ho.size());
		Test.stopTest();
	}
	
	static List<Scheduled_Section__c> setupData(boolean groupBased){
		TestDataSetupUtil_v2.setUPCoreData(5);
		if(groupBased)
			TestDataSetupUtil_v2.activeSetup.Group_Based__c = true;
		else
			TestDataSetupUtil_v2.activeSetup.Group_Based__c = false;
		update TestDataSetupUtil_v2.activeSetup;
		TestDataSetupUtil_v2.setUpStaffData(5);
		List<Scheduled_Section__c> ss = new List<Scheduled_Section__c>();
		List<Section_ReportingPeriod__c> secRP = [SELECT id, Time__c, section__r.time__r.Name__c FROM Section_ReportingPeriod__c];
		for(integer i = 0; i<TestDataSetupUtil_v2.teachersList.size(); i++){
			Scheduled_Section__c s = new Scheduled_Section__c(
				Staff__c = TestDataSetupUtil_v2.teachersList[i].id,
				Staff__r = TestDataSetupUtil_v2.teachersList[i],
				Account__r = TestDataSetupUtil_v2.school,
				Room__c = TestDataSetupUtil_v2.roomList[i].id,
				Needs_Publish__c = true
			);
			if(!groupBased){
				Section_ReportingPeriod__c srp = secRp[Integer.valueOf(math.floor(math.random()*secRP.size()))];
				s.Period_Key__c = ''+i;
				s.Section_ReportingPeriod__c = srp.id;
				s.Section_ReportingPeriod__r = srp;
			}
			ss.add(s);
		}
		insert ss;
		return ss;
	}
}