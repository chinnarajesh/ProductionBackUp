@isTest
private class Test_PointsLedger {
    public static Points_StudentLedger sl;
    public static PageReference pr;
    public static Picklist_Value__c categories;
    public static void createTestData(){
        
        TestDataSetupUtil_v2.setUPCoreData(3);
        TestDataSetupUtil_v2.setUpStaffData(5);
        TestDataSetupUtil_v2.setUpStudentData(5);
        TestDataSetupUtil_v2.createPointsSettings(true);
        TestDataSetupUtil_v2.staffContactsList[0].user__c = userinfo.getUserId();
        update TestDataSetupUtil_v2.staffContactsList[0];
         Test_PointsLedger.createCategories();
        pr = new PageReference('/apex/Points_StudentLedger?id='+TestDataSetupUtil_v2.studentsList[0].Id);
        Test.setCurrentPage(pr);
        sl = new Points_StudentLedger();
        TestDataSetupUtil_v2.activeSetUp.Schedule_Start_Date__c = TestDataSetupUtil_v2.term.Date_Start_Date__c;
        TestDataSetupUtil_v2.activeSetUp.Schedule_End_Date__c = TestDataSetupUtil_v2.term.End_Date__c;
        TestDataSetupUtil_v2.activeSetUp.Points_Frequency__c = 'Monthly';
        TestDataSetupUtil_v2.activeSetUp.Points_Reset_Value__c = 0;
        TestDataSetupUtil_v2.activeSetUp.Days__c = '1';
        update TestDataSetupUtil_v2.activeSetUp;
        
    }
    
    public static void createCategories(){
    	Id pointsCats = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Points_Category');
    	categories = new Picklist_Value__c(Name='Category1', Setup__c=TestDataSetupUtil_v2.activeSetUp.Id,Default_Points__c=40,RecordTypeId=pointsCats);
    	insert categories;
    }
    static testMethod void testPointsLedgerController() {  
        createTestData();
    }
    
     static testMethod void testAddNewPoints() {
        createTestData();
        Points_StudentLedger.submitPoints(TestDataSetupUtil_v2.studentsList[0].Id,'10',categories.id ,TestDataSetupUtil_v2.studSectionsList[0].Id,'Test New points 1',TestDataSetupUtil_v2.teachersList[0].Id,System.today().format(), 'false','true','');
    }
    
     static testMethod void testRedeemPoints() {
        createTestData();
        Points_StudentLedger.submitPoints(TestDataSetupUtil_v2.studentsList[0].Id,'10','--None--','--None--','Test Redeem points 1',TestDataSetupUtil_v2.teachersList[0].Id,System.today().format(), 'true','true','');
    }
    
    static testMethod void testDeletePoints() {
        createTestData();
        Points__c p = new Points__c(Student__c = TestDataSetupUtil_v2.studentsList[0].Id,Points__c=10,Category__c = categories.id ,Student_Section__c = TestDataSetupUtil_v2.studSectionsList[0].Id,Comments__c = 'New Points',Staff__c = TestDataSetupUtil_v2.teachersList[0].Id,Points_Date__c = System.today());
    	p.Reference_Id__c = p.Student__c+'_'+p.Student_Section__c+'_'+p.Category__c+'_'+p.Points_Date__c.format();
    	insert p;
    	Apexpages.currentPage().getParameters().put('pId',p.Id);
    		sl.deletePoints();
    }
}