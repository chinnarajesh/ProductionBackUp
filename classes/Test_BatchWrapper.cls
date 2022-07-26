@isTest
private class Test_BatchWrapper {
	@isTest static void test_BatchWrapper(){
		TestDataSetupUtil_v2.setUpCoreData(1);
		Test.startTest();
			Scheduler_HoldingProcessor shp = new Scheduler_HoldingProcessor();
			shp.continueBatch = false;
			shp.cSetup = new core_SetupWrapper(TestDataSetupUtil_v2.activeSetup,'test'); 
			shp.mode = 'Staff';
			shp.reportingPeriod = TestDataSetupUtil_v2.semester.id;
			Id batchId = database.executeBatch(shp);
			
			BatchWrapper batch = new BatchWrapper(batchId,TestDataSetupUtil_v2.activeSetup.id);
			batch.rpId = TestDataSetupUtil_v2.semester.id;
			batch.continueBatch();
		Test.stopTest();
		batch.checkForLogs('Scheduler_HoldingProcessor',false,system.now());
		batch.checkForLogs('Scheduler_HoldingProcessor',true,system.now());
		batch.setupWaitingMessage();
	}
	
}