@isTest
private class CT_Test_BatchWrapper {
	@isTest static void test_BatchWrapper(){
		TestDataSetupUtil_v2.setUpCoreData(1);
		Test.startTest();
			CT_Scheduler_HoldingProcessor shp = new CT_Scheduler_HoldingProcessor();
			shp.continueBatch = false;
			shp.cSetup = TestDataSetupUtil_v2.activeSetup;//new CT_core_SetupWrapper(TestDataSetupUtil_v2.activeSetup,'test'); 
			shp.mode = 'Staff';
			shp.reportingPeriod = TestDataSetupUtil_v2.semester.id;
			Id batchId = database.executeBatch(shp);
			
			CT_BatchWrapper batch = new CT_BatchWrapper(batchId,TestDataSetupUtil_v2.activeSetup.id);
			batch.rpId = TestDataSetupUtil_v2.semester.id;
			batch.continueBatch();
		Test.stopTest();
		batch.continueBatch();
//		batch.checkForLogs('CT_Scheduler_HoldingProcessor',false,system.now());
//		batch.checkForLogs('CT_Scheduler_HoldingProcessor',true,system.now());
//		batch.setupWaitingMessage();
	}
	
}