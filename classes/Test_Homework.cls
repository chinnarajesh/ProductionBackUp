@isTest
private class Test_Homework{
	
	private static testmethod void testConstructor(){
		testDataSetupUtil_v2 testUtil = new testDataSetupUtil_v2();
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUPStudentData(5);
		testDataSetupUtil_v2.setupSessiondata();
       	//testDataSetupUtil_v2.sessionsList = testDataSetupUtil_v2.getSessions(5, testDataSetupUtil_v2.period,testDataSetupUtil_v2.sectionsList[1].id,2);
        List<Picklist_Value__c> hwStatus = testDataSetupUtil_v2.createHomeworkPicklistValues();
        
        
        Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c.addDays(1);
        
        test.startTest();
			system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
	            Homework_HomeworkController controller = new Homework_HomeworkController();
                controller.dueDate.Due_Date__c = testdate;
                
                system.assertEquals(false, controller.bFatalError);
				system.assertEquals(4, controller.statusList.size());
            }
        test.stopTest();
	}
	
	private static testmethod void testGetData(){
		testDataSetupUtil_v2 testUtil = new testDataSetupUtil_v2();
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUPStudentData(5);
		testDataSetupUtil_v2.setupSessiondata();
       	//testDataSetupUtil_v2.sessionsList = testDataSetupUtil_v2.getSessions(5, testDataSetupUtil_v2.period,testDataSetupUtil_v2.sectionsList[1].id,2);
        List<Picklist_Value__c> hwStatus = testDataSetupUtil_v2.createHomeworkPicklistValues();
        
        
        Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c.addDays(1);
        
        test.startTest();
			system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
	            Homework_HomeworkController controller = new Homework_HomeworkController();
                controller.dueDate.Due_Date__c = testdate;
                
                system.assert(testDataSetupUtil_v2.sectionsList.size() >= 2);
                controller.section = testDataSetupUtil_v2.sectionsList[1].id;
                
                controller.gethwdata();
			}
		test.stopTest();
	}
	
	private static testmethod void testSave(){
		testDataSetupUtil_v2 testUtil = new testDataSetupUtil_v2();
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUPStudentData(5);
		testDataSetupUtil_v2.setupSessiondata();
       	//testDataSetupUtil_v2.sessionsList = testDataSetupUtil_v2.getSessions(5, testDataSetupUtil_v2.period,testDataSetupUtil_v2.sectionsList[1].id,2);
        List<Picklist_Value__c> hwStatus = testDataSetupUtil_v2.createHomeworkPicklistValues();
        
        
        Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c.addDays(1);
        
        test.startTest();
			system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
	            Homework_HomeworkController controller = new Homework_HomeworkController();
                controller.dueDate.Due_Date__c = testdate;
                
                system.assert(testDataSetupUtil_v2.sectionsList.size() >= 2);
                controller.section = testDataSetupUtil_v2.sectionsList[1].id;
                
                controller.gethwdata();
                //test adding a new homework
                controller.newsectionId = testDataSetupUtil_v2.sessionsList[0].id;
                controller.newhomework();
                
                
                controller.commentSave();
                controller.saverecords();
			}
		test.stopTest();
	}
	
	private static testmethod void testMangageHomework(){
		testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUPStudentData(5);
		testDataSetupUtil_v2.setupSessiondata();
        //testDataSetupUtil_v2.createSessions(5, testDataSetupUtil_v2.period,testDataSetupUtil_v2.sectionsList[1].id);
        List<Picklist_Value__c> hwStatus = testDataSetupUtil_v2.createHomeworkPicklistValues();
        Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c.addDays(1);
        
        test.startTest();
			system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
				List<HW_Tracker__c> hwList = new List<HW_Tracker__c>();
	            hwList.add(new HW_Tracker__c(Student__c = testDataSetupUtil_v2.studentsList[0].id,
	            							Picklist_Value__c = hwStatus[1].id));
				hwList.add(new HW_Tracker__c(Student__c = testDataSetupUtil_v2.studentsList[0].id,
	            							Picklist_Value__c = hwStatus[2].id));
	          	hwList.add(new HW_Tracker__c(Student__c = testDataSetupUtil_v2.studentsList[0].id,
	            							Picklist_Value__c = hwStatus[3].id));
	            									
                insert hwList;
                
                Student__c student = [select id, of_Completed_Homework__c, of_Assigned_Homework__c, of_Missing_Homework__c,
                							of_Late_Homework__c
                						From Student__c
                						where id =: testDataSetupUtil_v2.studentsList[0].id];
                system.assertEquals(0, student.of_Completed_Homework__c);
                system.assertEquals(3, student.of_Assigned_Homework__c);
                system.assertEquals(1, student.of_Missing_Homework__c);
                system.assertEquals(1, student.of_Late_Homework__c);
			}
		test.stopTest();
	}
	
	static testMethod void test_HomeworkController(){
        testDataSetupUtil_v2.setUPCoreData(5);
        testDataSetupUtil_v2.setUPStaffData(5);
        testDataSetupUtil_v2.setUPStudentData(5);
        
        testDataSetupUtil_v2.setupSessiondata();
        //testDataSetupUtil_v2.createSessions(5, testDataSetupUtil_v2.period,testDataSetupUtil_v2.sectionsList[1].id);
        
        Map <String, Id> rtMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c'); 
        
        List<Picklist_Value__c> pvl  =  new List<Picklist_Value__c>();
        pvl.add(new Picklist_Value__c(Setup__c = testDataSetupUtil_v2.activeSetUp.id,RecordTypeId = rtMap.get('Homework'),Type__c = 'Homework',Name = 'XXComplete',Category__c = 'Complete',order__c = 92, Set_as_Default__c = TRUE));
        pvl.add(new Picklist_Value__c(Setup__c = testDataSetupUtil_v2.activeSetUp.id,RecordTypeId = rtMap.get('Homework'),Type__c = 'Homework',Name = 'XXMissing',Category__c = 'Missing',order__c = 93));
        pvl.add(new Picklist_Value__c(Setup__c = testDataSetupUtil_v2.activeSetUp.id,RecordTypeId = rtMap.get('Homework'), Type__c = 'Homework',Name = 'XXLate',Category__c = 'Late',order__c = 94));
        pvl.add(new Picklist_Value__c(Setup__c = testDataSetupUtil_v2.activeSetUp.id,RecordTypeId = rtMap.get('Homework'),Type__c = 'Homework',Name = 'XXAbsent',Category__c = 'Absent',order__c = 95));
          
        insert pvl;
        
        
        
        test.startTest();
            Date testdate = testDataSetupUtil_v2.semester.date_start_Date__c.addDays(1);
            
            system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
        
	            PageReference p = Page.Homework;
	            test.setCurrentPage(p);
	         
	            Homework_HomeworkController controller = new Homework_HomeworkController ();
                controller.dueDate.Due_Date__c = testdate;
                
                section__c testsec = new section__c (Id = testDataSetupUtil_v2.sectionsList[1].Id, active__c = TRUE, has_homework__c = true);
                update testsec;
                
                controller.section = testDataSetupUtil_v2.sectionsList[1].id;
                
                controller.newsectionid = testDataSetupUtil_v2.sectionsList[1].id;
                controller.newhomework();
                controller.pagerefstudentId = testDataSetupUtil_v2.studentsList[0].Id;

                Set<ID> hwTrackIds = new Set<ID>();
                controller.saverecords();
                
                Map<id, HW_Tracker__c> hwTrackerList = new Map<id, HW_Tracker__c>([select id, PickList_Value__c from HW_Tracker__c where id IN :hwTrackIds]);
            }
        Test.stopTest();
    }
}