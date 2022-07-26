@isTest
private class Test_BatchResetPoints {

     public static void createTestData(){
        
        TestDataSetupUtil_v2.setUPCoreData(3);
        TestDataSetupUtil_v2.setUpStaffData(5);
        TestDataSetupUtil_v2.setUpStudentData(5);
        TestDataSetupUtil_v2.activeSetUp.Schedule_Start_Date__c = TestDataSetupUtil_v2.term.Date_Start_Date__c;
        TestDataSetupUtil_v2.activeSetUp.Schedule_End_Date__c = TestDataSetupUtil_v2.term.End_Date__c;
        TestDataSetupUtil_v2.activeSetUp.Points_Frequency__c = 'Monthly';
        TestDataSetupUtil_v2.activeSetUp.Points_Reset_Value__c = 0;
        TestDataSetupUtil_v2.activeSetUp.Days__c = '1';
        update TestDataSetupUtil_v2.activeSetUp;
       
    }
    
   static testMethod void testCreateWeeklyResetPointsSchedules() {
        createTestData();
        TestDataSetupUtil_v2.activeSetUp.Schedule_Start_Date__c = System.today();
     	TestDataSetupUtil_v2.activeSetUp.Schedule_End_Date__c = System.today().addYears(1); 
     	TestDataSetupUtil_v2.activeSetUp.Points_Frequency__c = 'Weekly';
     	TestDataSetupUtil_v2.activeSetUp.Days__c = 'Sun;Mon;';
     	update TestDataSetupUtil_v2.activeSetUp;
     	Integer scheduledays = [SELECT COUNT() FROM Schedule__c WHERE Setup__c =: TestDataSetupUtil_v2.activeSetUp.Id];
     	System.assertNotEquals(0, scheduledays);
    }
    static testMethod void testCreateMonthlyResetPointsSchedules() {
        createTestData();
        TestDataSetupUtil_v2.activeSetUp.Schedule_Start_Date__c = System.today();
     	TestDataSetupUtil_v2.activeSetUp.Schedule_End_Date__c = System.today().addYears(1); 
     	TestDataSetupUtil_v2.activeSetUp.Points_Frequency__c = 'Monthly';
     	TestDataSetupUtil_v2.activeSetUp.Days__c = '1;2;';
     	update TestDataSetupUtil_v2.activeSetUp;
     	Integer scheduledays = [SELECT COUNT() FROM Schedule__c WHERE Setup__c =: TestDataSetupUtil_v2.activeSetUp.Id];
     	System.assertNotEquals(0, scheduledays);
     	Setup__c setup = [SELECT Points_Reset_Date__c FROM Setup__c WHERE Id =: TestDataSetupUtil_v2.activeSetUp.Id];
     	System.assertNotEquals(null, setup.Points_Reset_Date__c);
    }
    
     static testMethod void testScheduleResetPoints() {
        createTestData();
        List<Picklist_Value__c> cats = testDataSetupUtil_v2.createPointsCats(null);
        string refID = (String)testDataSetupUtil_v2.studentsList[0].id+(String)cats[0].id+String.valueOf(system.today())+'';
        Points__c point = new Points__c(Student__c = testDataSetupUtil_v2.studentsList[0].id
                                        ,Points_Date__c = system.today()
                                        ,Points__c = 35
                                        ,Staff__c = testDataSetupUtil_v2.teachersList[0].id
                                        ,Category__c = cats[0].id
                                        ,Reference_Id__c = refID);
        
        insert point;
        
        Notification__c notification = new Notification__c(Module__c = 'Points'
                                        ,Setup__c = testDataSetupUtil_v2.activeSetUp.id
                                        ,Start_Date__c = system.today().addDays(-7)
                                        ,End_Date__c = system.today().addDays(7)
                                        ,Grade__c = '1;2;3;4;5;6;7;8;9;10;11;12');
        
        insert notification;
        
        Threshold__c thresh = new Threshold__c(Notification__c = notification.id
                                        ,Cumulative__c = 30);
                                        
        insert thresh;
        TestDataSetupUtil_v2.activeSetUp.Schedule_Start_Date__c = System.today();
        TestDataSetupUtil_v2.activeSetUp.Schedule_End_Date__c = System.today().addYears(1); 
        TestDataSetupUtil_v2.activeSetUp.Points_Frequency__c = 'Weekly';
        TestDataSetupUtil_v2.activeSetUp.Days__c = 'Sun;Mon;Tue;Wed;Thur;Fri;Sat';
        update TestDataSetupUtil_v2.activeSetUp;
        //Integer scheduledays = [SELECT COUNT() FROM Schedule__c WHERE Setup__c =: TestDataSetupUtil_v2.activeSetUp.Id];
     
        sched_Points sc = new sched_Points();
        String CRON_EXP = '0 0 13 * * ?';
         Test.startTest(); 
        System.schedule('testCreateWeeklyResetPointsSchedules',CRON_EXP , sc);
         Test.stopTest(); 
     	
    }
    
     static testMethod void testResetPoints() {
        createTestData();
        TestDataSetupUtil_v2.activeSetUp.Schedule_Start_Date__c = System.today();
     	TestDataSetupUtil_v2.activeSetUp.Schedule_End_Date__c = System.today().addYears(1); 
     	TestDataSetupUtil_v2.activeSetUp.Points_Frequency__c = 'Weekly';
     	TestDataSetupUtil_v2.activeSetUp.Days__c = 'Sun;Mon;Tue;Wed;Thur;Fri;Sat';
     	update TestDataSetupUtil_v2.activeSetUp;
     	//Integer scheduledays = [SELECT COUNT() FROM Schedule__c WHERE Setup__c =: TestDataSetupUtil_v2.activeSetUp.Id];
     	 Set<String> setupIds = new Set<String>();
     	 setupIds.add(TestDataSetupUtil_v2.activeSetUp.Id);
     	 Batch_ResetPoints brp = new Batch_ResetPoints ();
		 brp.setupIds = setupIds;
		  System.debug('$$$$$$$BRP'+brp.setupIds);
     	 List<Student__c> studs =[SELECT Id FROM Student__c WHERE Setup__c = : TestDataSetupUtil_v2.activeSetUp.Id AND Setup__r.Active__c = true AND Active__c = true];
     	 System.debug('$$$$$$$$$$$$STUDS$$$$$$$$$$$'+studs);
     	 Test.startTest(); 
         Database.executeBatch(brp,200) ;
     	 Test.stopTest(); 
     	
    }
}