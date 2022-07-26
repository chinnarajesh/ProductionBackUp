@isTest
global class TestBatchStudentDaysEnrolled {

	global static Schedule_Day__c testScheduleDay;

	static void setupData(){
		testDataSetupUtil_v2.setUPCoreData(1);
		testDataSetupUtil_v2.setUpStaffData(5);
		testDataSetupUtil_v2.setUpStudentData(5);

		Schedule_Template__c testScheduleTemplate = new Schedule_Template__c(Setup__c = testDataSetupUtil_v2.activeSetUp.Id, Has_Class__c = true);
		insert testScheduleTemplate;

		Schedule_Day__c testScheduleDay1 = new Schedule_Day__c(Day__c=testDataSetupUtil_v2.semester.date_start_date__c.addDays(1), ReferenceId__c = '####');
		testScheduleDay1.Schedule_Template__c = testScheduleTemplate.Id;
		insert testScheduleDay1;

		Schedule_Day__c testScheduleDay2 = testScheduleDay1.clone(false);
		testScheduleDay2.Day__c=testDataSetupUtil_v2.semester.date_start_date__c.addDays(2);
		testScheduleDay2.ReferenceId__c = '####82';
		insert testScheduleDay2;
		testScheduleDay=testScheduleDay2;
	}

	@isTest static void testStart() {
		setupData();

		Test.startTest();
			BatchStudentDaysEnrolled batch = new BatchStudentDaysEnrolled();
			Database.Batchablecontext bc = new testBatchContext();
			Database.Querylocator locator = batch.start(bc);
			system.assertNotEquals(null, locator);
			system.debug([SELECT id, ReferenceId__c, s.Days_Elapsed__c FROM Schedule_Day__c s WHERE s.Id = :testScheduleDay.Id]);
			Schedule_Day__c scheduleDay = [SELECT s.Days_Elapsed__c FROM Schedule_Day__c s WHERE s.Id = :testScheduleDay.Id LIMIT 1];
			System.assert(scheduleDay.Days_Elapsed__c > 0);
		Test.stopTest();
	}
	
	@isTest static void testExecute() {
		setupData();

		Test.startTest();
			BatchStudentDaysEnrolled batch = new BatchStudentDaysEnrolled();
			batch.execute(new testBatchContext(), testDataSetupUtil_v2.studentsList);
		Test.stopTest();
	}

	@isTest static void testPopulateDaysEnrolled() {
		setupData();

		List<Schedule_Day__c> testList = new List<Schedule_Day__c>();
		testScheduleDay = new Schedule_Day__c(Day__c = testDataSetupUtil_v2.semester.date_start_date__c.addDays(1));
		testList.add(testScheduleDay);

		testScheduleDay = new Schedule_Day__c(Day__c = testDataSetupUtil_v2.semester.date_start_date__c.addDays(31));
		testList.add(testScheduleDay);

		testScheduleDay = new Schedule_Day__c(Day__c = testDataSetupUtil_v2.semester.date_start_date__c.addDays(61));
		testList.add(testScheduleDay);

		for(Integer i=0;i<3;i++){
			testDataSetupUtil_v2.studentsList[i].Exit_Date__c =  testDataSetupUtil_v2.semester.Date_start_date__c.addDays(2);
			testDataSetupUtil_v2.studentsList[i].Student_Exit_Reason__c = CT_core_triggerUtils.SECTIONEXITREASONBYTRIGGER;
			testDataSetupUtil_v2.studentsList[i].Active__c =  false;
		}
		testDataSetupUtil_v2.studentsList[0].Exit_date__c =   testDataSetupUtil_v2.semester.Date_start_date__c.addDays(55);
		update testDataSetupUtil_v2.studentsList;

		Date testDate1 = testDataSetupUtil_v2.semester.date_start_date__c.addDays(3);
		Date testDate2 = testDataSetupUtil_v2.semester2.date_start_date__c.addDays(1);
		Date testDate3 = testDataSetupUtil_v2.semester2.date_start_date__c.addDays(65);
		
		Test.startTest();			
			BatchStudentDaysEnrolled batch = new BatchStudentDaysEnrolled();  
						
			try {
				batch.populateDaysEnrolled(testList, new Student__c(), testDate1, null);
			} catch (Exception e) {
				System.assert(false);
			}
		
			Set <Id> studentIds = new Set <Id>();
			for (Student__c stu: testDataSetupUtil_v2.studentsList) studentIds.add(stu.id);
			Map <Id, List <Enrollment_Tracking__c>> etMap = CT_Student_Utils.getStudentEnrollmentMap(studentIds);

			//student deactivated, 2 ET, 2 days enrolled (start+1, start+31)
			system.assertEquals(2, etMap.get(testDataSetupUtil_v2.studentsList[0].id).size());
			batch.populateDaysEnrolled(testList, testDataSetupUtil_v2.studentsList[0], testDate3, etMap.get(testDataSetupUtil_v2.studentsList[0].id));
			System.assertEquals(2, testDataSetupUtil_v2.studentsList[0].Days_Enrolled__c);

			//student deactivated, 2 ET, only 1 day enrolled (start+1)
			system.assertEquals(2, etMap.get(testDataSetupUtil_v2.studentsList[1].id).size());
			batch.populateDaysEnrolled(testList, testDataSetupUtil_v2.studentsList[1], testDate3, etMap.get(testDataSetupUtil_v2.studentsList[1].id));
			System.assertEquals(1, testDataSetupUtil_v2.studentsList[1].Days_Enrolled__c);

			//student was never deactivated, 1 ET record, 3 days enrolled (start+1,+31,+61)
			system.assertEquals(1, etMap.get(testDataSetupUtil_v2.studentsList[3].id).size());
			batch.populateDaysEnrolled(testList, testDataSetupUtil_v2.studentsList[3], testDate3, etMap.get(testDataSetupUtil_v2.studentsList[3].id));
			System.assertEquals(3, testDataSetupUtil_v2.studentsList[3].Days_Enrolled__c);
		Test.stopTest();
	}

	@isTest static void testPopulateDaysElapsed() {
		List<Schedule_Day__c> testList = new List<Schedule_Day__c>();
		
		Test.startTest();
			BatchStudentDaysEnrolled batch = new BatchStudentDaysEnrolled();  
		
			try {
				batch.populateDaysElapsed(testList);
			} catch (Exception e) {
				System.assert(false);
			}
			
			testScheduleDay = new Schedule_Day__c(ReferenceId__c='****123');
			testList.add(testScheduleDay);
			
			batch.populateDaysElapsed(testList);
			System.assertEquals(1, testList[0].Days_Elapsed__c);
			
			testScheduleDay = new Schedule_Day__c(ReferenceId__c='****124');
			testList.add(testScheduleDay);
			testScheduleDay = new Schedule_Day__c(ReferenceId__c='****125');
			testList.add(testScheduleDay);
			
			batch.populateDaysElapsed(testList);
			System.assertEquals(3, testList[2].Days_Elapsed__c);
		Test.stopTest();
	}
	
	@isTest static void testFinish() {
		BatchStudentDaysEnrolled batch = new BatchStudentDaysEnrolled();
		try {
			batch.finish(new testBatchContext());
		} catch (Exception e) {
			system.assert(false);
		}
	}
	
	global class testBatchContext implements Database.BatchableContext{
		global testBatchContext(){
			system.debug('In testBatchContext constructor.');
		}
		global Id getJobId(){
			return '0123456789ABCDEF01';
		}
		global Id getChildJobId(){
			return '0123456789ABCDEF01';
		}
	}

}