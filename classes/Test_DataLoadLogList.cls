@isTest
private class Test_DataLoadLogList {
	
	static DataLoadLogList dataLogs;
	static Setup__c setup;
	static String TYPE_A = 'Type A';
	static String TYPE_B = 'Type B';
	static Data_Load_Log__c aLog;
	static Data_Load_Log__c bLog;
	
	static void setupData() {
		testDataSetupUtil_v2.setUPCoreData(1);
		setup = testDataSetupUtil_v2.activeSetUp;
		dataLogs = new DataLoadLogList('SomeClassName', 
									setup.id, 
									new String[]{TYPE_A, TYPE_B});
		aLog = dataLogs.logs.get(TYPE_A);
		bLog = dataLogs.logs.get(TYPE_B);
	}
	
	static testMethod void testInitialize() {
		setupData();
		DataLoadLogList logs = new DataLoadLogList();
		logs.initialize('Test', setup.id, new String[]{'A', 'B'});
		List<Data_Load_Log__c> testList = logs.logs.values();
		List<Data_Load_Log__c> logList = [select Class_Name__c,
												Setup__c,
												Type__c,
												Status__c,
												Total_Records__c,
												Failed_Records__c
											from Data_Load_Log__c
											where id in :testList
											order by Type__c];
		system.assertNotEquals(null, logList);
		system.assertEquals(2, logList.size());
		
		system.assertEquals('Test', logList.get(0).Class_Name__c);
		system.assertNotEquals(null, logList.get(0).Setup__c);
		system.assertEquals('A', logList.get(0).Type__c);
		system.assertEquals('Pending', logList.get(0).Status__c);
		system.assertEquals(0, logList.get(0).Total_Records__c);
		system.assertEquals(0, logList.get(0).Failed_Records__c);

		system.assertEquals('Test', logList.get(1).Class_Name__c);
		system.assertNotEquals(null, logList.get(1).Setup__c);
		system.assertEquals('B', logList.get(1).Type__c);
		system.assertEquals('Pending', logList.get(1).Status__c);
		system.assertEquals(0, logList.get(1).Total_Records__c);
		system.assertEquals(0, logList.get(1).Failed_Records__c);
	}
	
	static testMethod void testStartLog() {
		setupData();
		dataLogs.startLog(TYPE_A);
		system.assertEquals('Running', aLog.Status__c);
		system.assertEquals('Pending', bLog.Status__c);
		system.assertNotEquals(null, aLog.Start_Time__c);
		system.assertNotEquals(null, aLog.Start_Time_Text__c);
	}
	
	static testMethod void testStartAll() {
		setupData();
		dataLogs.startAll();
		system.assertEquals('Running', aLog.Status__c);
		system.assertEquals('Running', bLog.Status__c);
		system.assertNotEquals(null, aLog.Start_Time__c);
		system.assertNotEquals(null, aLog.Start_Time_Text__c);
		system.assertNotEquals(null, bLog.Start_Time__c);
		system.assertNotEquals(null, bLog.Start_Time_Text__c);
	}
	
	static testMethod void testEndLog() {
		setupData();
		dataLogs.endLog(TYPE_B);
		system.assertEquals('Completed', bLog.Status__c);
		system.assertEquals('Pending', aLog.Status__c);
		system.assertNotEquals(null, bLog.End_Time__c);
		system.assertNotEquals(null, bLog.End_Time_Text__c);
	}
	
	static testMethod void testEndAll() {
		setupData();
		dataLogs.endAll();
		system.assertEquals('Completed', aLog.Status__c);
		system.assertEquals('Completed', bLog.Status__c);
		system.assertNotEquals(null, aLog.End_Time__c);
		system.assertNotEquals(null, aLog.End_Time_Text__c);
		system.assertNotEquals(null, bLog.End_Time__c);
		system.assertNotEquals(null, bLog.End_Time_Text__c);
	}
	
	static testMethod void testIncrTotal() {
		setupData();
		dataLogs.incrTotal(TYPE_A);
		system.assertEquals(1, aLog.Total_Records__c);
		system.assertEquals(0, bLog.Total_Records__c);
	}
	
	static testMethod void testIncrFailed() {
		setupData();
		dataLogs.incrTotal(TYPE_B);
		system.assertEquals(1, bLog.Total_Records__c);
		system.assertEquals(0, aLog.Total_Records__c);
	}
	
	static testMethod void testCountAllFailed() {
		setupData();
		dataLogs.incrFailed(TYPE_A);
		dataLogs.incrFailed(TYPE_A);
		dataLogs.incrTotal(TYPE_A);
		dataLogs.incrFailed(TYPE_B);
		system.assertEquals(3, dataLogs.countAllFailed());
	}
    
}