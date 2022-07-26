@isTest
private class Test_EOYWiz {
	public static ID activeYear;

	public class testBatchContext implements Database.BatchableContext{
		public testBatchContext(){
			system.debug('In testBatchContext constructor.');
		}
		public Id getJobId(){
			return '0123456789ABCDEF01';
		}
		public Id getChildJobId(){
			return '0123456789ABCDEF01';
		}
	}
	public static void createTestData() {
		TestDataSetupUtil_v2.setUPCoreData(3);
		TestDataSetupUtil_v2.setUpStaffData(5);
		TestDataSetupUtil_v2.setUpStudentData(5);
		//need to mark this to represent an active year...
		TestDataSetupUtil_v2.masterYear.Current__c = true;
		update TestDataSetupUtil_v2.masterYear;
	}

	public static void EOYWiz_Landing() {
		EOYWiz_Landing EOY = new EOYWiz_Landing();
		EOY.orgWideSettingsComplete();
		PageReference pr = new PageReference('/apex/EOYWiz_Landing');
		Test.setCurrentPageReference(pr);
		//go to org Purge settings
		Test.setCurrentPageReference(EOY.gotoOrgPurgeSettings());
	}

	public static void EOYWiz_Landing2() {
		EOYWiz_Landing EOY = new EOYWiz_Landing();
		EOY.orgWideSettingsComplete();
		PageReference pr = new PageReference('/apex/EOYWiz_Landing');
		Test.setCurrentPageReference(pr);

		//call all of the redirects
		EOY.gotoOrgNextSchoolYear();
		EOY.gotoOrgExport();

		EOY.gotoSchoolGradeSpan();
		EOY.gotoSchoolStudentPromotional();
		EOY.gotoSchoolNextYearStudents();
		EOY.gotoSchoolSnapshots();
		EOY.gotoSchoolProcessData();
		EOY.gotoSchoolPurgeEOYData();
		EOY.gotoSchoolPurgeHistoricalData();

		EOY.deactivateCurrentYear();
	}

	public static void EOYWiz_PurgeSetting() {
		EOYWiz_OrgPurgeSettings OrgPurgeSettings = new EOYWiz_OrgPurgeSettings();
		//assume default selections are good, click the save button
		OrgPurgeSettings.dPurgeCustomSettings[0].Selected = true;
		OrgPurgeSettings.editSelected();
		OrgPurgeSettings.savePCS();
		//assume save successful, finalize decision
		OrgPurgeSettings.finalizePCS();
		//call on the next and previous for coverage purposes
		OrgPurgeSettings.gotoEOYLandingPage();
		Test.setCurrentPageReference(OrgPurgeSettings.gotoOrgNextYear());
	}

	public static void EOYWiz_PurgeSetting_Light() {
		EOYWiz_OrgPurgeSettings OrgPurgeSettings = new EOYWiz_OrgPurgeSettings();
		OrgPurgeSettings.finalizePCS();
		Test.setCurrentPageReference(OrgPurgeSettings.gotoOrgNextYear());
	}

	public static void EOYWiz_OrgNewYear() {
		EOYWiz_OrgNextYear OrgNextYear = new EOYWiz_OrgNextYear();
		OrgNextYear.populateYearInformation();

		//populate the values for the new year
		OrgNextYear.nextYear.Name__c = 'New Next Year Testing';
		OrgNextYear.nextYear.Date_Start_Date__c = testDataSetupUtil_v2.masterYear.Date_Start_Date__c.addYears(1);
		OrgNextYear.nextYear.End_Date__c = testDataSetupUtil_v2.masterYear.End_Date__c.addYears(1);

		//call on the save/finalize methods
		OrgNextYear.saveNextYear();
		OrgNextYear.fieldEditedMessage();
		OrgNextYear.fieldUnEditedMessage();
		OrgNextYear.finalizeNextYear();

		//call the previous and next for coverage purposes
		OrgNextYear.gotoOrgPurgeSettings();

		//go to next step export
		Test.setCurrentPage(OrgNextYear.gotoEOYExport());
	}

	public static void EOYWiz_OrgNewYear_Light() {
		EOYWiz_OrgNextYear OrgNextYear = new EOYWiz_OrgNextYear();
		OrgNextYear.populateYearInformation();

		//populate the values for the new year
		OrgNextYear.nextYear.Name__c = 'New Next Year Testing';
		OrgNextYear.nextYear.Date_Start_Date__c = testDataSetupUtil_v2.masterYear.Date_Start_Date__c.addYears(1);
		OrgNextYear.nextYear.End_Date__c = testDataSetupUtil_v2.masterYear.End_Date__c.addYears(1);

		OrgNextYear.finalizeNextYear();
	}

	public static void EOYWiz_OptionalExport() {
		EOYWiz_OrgExport OrgExport = new EOYWiz_OrgExport();

		//not much in this step, call the next steps
		OrgExport.gotoOrgNextYear();

		//go back home
		Test.setCurrentPage(OrgExport.gotoEOYLanding());
		EOYWiz_Landing EOY2 = new EOYWiz_Landing();
		EOY2.getSchoolProgress();
		//set selectedProgress
		EOY2.selectedProgress = EOY2.dEOYProgress[0].ID;

		//go to the first school
		Test.setCurrentPage(EOY2.gotoSchoolGradeSpan());
	}

	public static void EOYWiz_SchoolGradeSpan() {
		EOYWiz_SchoolGradeSpan EOYGradeSpan = new EOYWiz_SchoolGradeSpan();
		EOYGradeSpan.saveNextSetup();
		EOYGradeSpan.finalizeNextSetup();

		//call the previous and next for coverage purposes
		EOYGradeSpan.gotoEOYLandingPage();

		//go to next step promotinal status
		Test.setCurrentPage(EOYGradeSpan.gotoSchoolStudentPromotional());
	}

	public static void EOYWiz_UpdateStudentInfo() {
		EOYWiz_SchoolStudentPromotional EOYStudentPromotional = new EOYWiz_SchoolStudentPromotional();
		EOYStudentPromotional.saveStudentUpdates();

		EOYStudentPromotional.thousandBlocks[0].students[0].Intent_to_Return_Following_Year__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[0].Eligible_For_Enrollment__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[0].Promoted__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[0].Next_School__c = EOYStudentPromotional.thousandBlocks[0].students[0].School__c;

		EOYStudentPromotional.thousandBlocks[0].students[1].Intent_to_Return_Following_Year__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[1].Eligible_For_Enrollment__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[1].Promoted__c = false;
		EOYStudentPromotional.thousandBlocks[0].students[1].Next_School__c = EOYStudentPromotional.thousandBlocks[0].students[0].School__c;

		EOYStudentPromotional.thousandBlocks[0].students[2].Intent_to_Return_Following_Year__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[2].Eligible_For_Enrollment__c = false;
		EOYStudentPromotional.thousandBlocks[0].students[2].Promoted__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[2].Next_School__c = EOYStudentPromotional.thousandBlocks[0].students[0].School__c;

		EOYStudentPromotional.thousandBlocks[0].students[3].Intent_to_Return_Following_Year__c = false;
		EOYStudentPromotional.thousandBlocks[0].students[3].Eligible_For_Enrollment__c = false;
		EOYStudentPromotional.thousandBlocks[0].students[3].Promoted__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[3].Next_School__c = EOYStudentPromotional.thousandBlocks[0].students[0].School__c;

		EOYStudentPromotional.thousandBlocks[0].students[4].Intent_to_Return_Following_Year__c = false;
		EOYStudentPromotional.thousandBlocks[0].students[4].Eligible_For_Enrollment__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[4].Promoted__c = true;
		EOYStudentPromotional.thousandBlocks[0].students[4].Next_School__c = EOYStudentPromotional.thousandBlocks[0].students[0].School__c;

		//update so the database reflects these changes
		update EOYStudentPromotional.thousandBlocks[0].students;

		EOYStudentPromotional.finalizeStudentUpdates();
		EOYStudentPromotional.downloadCSV();

		//create a blob for the upsert function
		EOYStudentPromotional.fileBlob = Blob.valueOf('Unit test attachment body');
		EOYStudentPromotional.uploadCSV();
		EOYStudentPromotional.finalizeStudentUpdates();

		//call the previous and next for coverage purposes
		EOYStudentPromotional.gotoSchoolGradeSpan();

		//go to the next step next year students
		Test.setCurrentPage(EOYStudentPromotional.gotoSchoolNextYearStudents());
	}

	public static void EOYWiz_CreateNextYearStudents() {
		EOYWiz_SchoolNextYearStudents EOYNextYearStudents = new EOYWiz_SchoolNextYearStudents();

		try {
			EOYNextYearStudents.processNextYearStudent();
		}
		catch(Exception e) {
			//means another batch is running and can only execute one at a time
		}
		EOYNextYearStudents.getDataLogs();
		//call the previous and next for coverage purposes
		EOYNextYearStudents.gotoSchoolStudentPromotional();

		//go to the next step snapshots, incomplete in Tremblant 1
		Test.setCurrentPage(EOYNextYearStudents.gotoSchoolSnapshots());
	}

	public static void EOYWiz_Snapshots_Light() {
		EOYWiz_SchoolSnapshots EOYSnapshots = new EOYWiz_SchoolSnapshots();
		EOYSnapshots.deletePreviousSnapshots();
		EOYSnapshots.setLastModified();

		EOYSnapshots.getDataLogs();

		//call the previous and next for coverage purposes
		EOYSnapshots.gotoSchoolNextYearStudents();

		//go to the next step process data
		Test.setCurrentPage(EOYSnapshots.gotoSchoolProcessData());
	}

	public static void EOYWiz_Snapshots() {
		EOYWiz_SchoolSnapshots EOYSnapshots = new EOYWiz_SchoolSnapshots();

		try {
			//Temblant2 functionality

			BatchSnapshot firstBatch = new BatchSnapshot(EOYSnapshots.schoolProgress.Setup__c);
			Database.Batchablecontext bc = new testBatchContext();
			Database.Querylocator firstLocator = firstBatch.start(bc);
			firstBatch.execute(null, testDataSetupUtil_v2.studentsList);

			//this does fire off additional batches.
			firstBatch.finish(bc);
		}
		catch(Exception e) {
			//means another batch is running and can only execute one at a time
		}

		//call the previous and next for coverage purposes
		EOYSnapshots.gotoSchoolNextYearStudents();

		//go to the next step process data
		Test.setCurrentPage(EOYSnapshots.gotoSchoolProcessData());
	}

	public static void EOYWiz_ProcessData() {
		EOYWiz_SchoolProcessData EOYProcessData = new EOYWiz_SchoolProcessData();

		try {
			EOYProcessData.processData();
		}
		catch(Exception e) {
			//means another batch is running and can only execute one at a time
		}
		EOYProcessData.getDataLogs();
		EOYProcessData.gotoSchoolSnapshots();
		Test.setCurrentPage(EOYProcessData.gotoSchoolPurgeEOYData());
	}

	public static void EOYWiz_PurgeEOYData() {
		EOYWiz_SchoolPurgeEOYData PurgeEOYData = new EOYWiz_SchoolPurgeEOYData();
		//try {
			PurgeEOYData.purgeEOYData();
		//}
		//catch(Exception e) {

		//}
		PurgeEOYData.getDataLogs();
		PurgeEOYData.gotoSchoolProcessData();
		Test.setCurrentPage(PurgeEOYData.gotoSchoolPurgeHistoricalData());
	}

	public static void EOYWiz_PurgeHistoricalDataBatch(Integer mode, Data_Load_Log__c purgeLog) {
			EOYWiz_SchoolPurgeHistoricalData purgeHistoricalData = new EOYWiz_SchoolPurgeHistoricalData();

			List<SObject> scope;

			if(mode == 0) scope = new List<Alert__c>();
			else if(mode == 1) scope = new List<Assesment__c>();
			else if(mode == 2) scope = new List<Assignment__c>();
			else if(mode == 3) scope = new List<Attendance__c>();
			else if(mode == 4) scope = new List<Attendance_Tracking__c>();
			else if(mode == 5) scope = new List<Awards__c>();
			else if(mode == 6) scope = new List<Consequence__c>();
			//else if(mode == 7) results = database.delete((List<Student_Behavior__c>)scope);
			else if(mode == 8) scope = new List<Behavior_Incident__c>();
			else if(mode == 9) scope = new List<Daily_Meal_Summary__c>();
			else if(mode == 10) scope = new List<External_Resources__c>();
			else if(mode == 11) scope = new List<Grade__c>();
			else if(mode == 12) scope = new List<HW_Tracker__c>();
			else if(mode == 13) scope = new List<HW_Assignment__c>();
			else if(mode == 14) scope = new List<Meal_Transaction__c>();
			else if(mode == 15) scope = new List<Media__c>();
			else if(mode == 16) scope = new List<Period__c>();
			else if(mode == 17) scope = new List<Points__c>();
			else if(mode == 18) scope = new List<Proactive_Attendance__c>();
			else if(mode == 19) scope = new List<Proactive_Demographics__c>();
			else if(mode == 20) scope = new List<Schedule_Day__c>();
			else if(mode == 21) scope = new List<Schedule_Group__c>();
			else if(mode == 22) scope = new List<Schedule_Template__c>();
			else if(mode == 23) scope = new List<Scheduled_Section__c>();
			else if(mode == 24) scope = new List<Session__c>();
			else if(mode == 25) scope = new List<Standard_Grade__c>();
			else if(mode == 26) scope = new List<Strand_Grade__c>();
			else {
				//we are in trouble!
			}

			Batch_SchoolPurgeHistoricalData firstBatch = new Batch_SchoolPurgeHistoricalData((String)testDataSetupUtil_v2.activeSetUp.ID, null, 0);
			Database.Batchablecontext bc = new testBatchContext();
			Database.Querylocator firstLocator = firstBatch.start(bc);
			firstBatch.execute(null, scope);
			firstBatch.finish(bc);
	}

	public static void EOYWiz_PurgeHistoricalData() {
		EOYWiz_SchoolPurgeHistoricalData purgeHistoricalData = new EOYWiz_SchoolPurgeHistoricalData();
		try{
			PurgeHistoricalData.purgeHistoricalData();
		}catch(Exception e) {

		}
		purgeHistoricalData.getDataLogs();
		purgeHistoricalData.gotoSchoolPurgeEOYData();
		Test.setCurrentPage(purgeHistoricalData.gotoEOYLanding());
	}


	static testMethod void testEOYWiz_Landing() {
		createTestData();
		test.startTest();
		//delete the custom settings, the class finds it alredy
		delete [SELECT ID FROM Purged_Object__c];
		EOYWiz_Landing();
		test.stopTest();
	}

	static testMethod void testEOYWiz_PurgeSetting() {
		createTestData();
		test.startTest();
		//delete the custom settings, the class finds it alredy
		delete [SELECT ID FROM Purged_Object__c];
		EOYWiz_Landing();
		EOYWiz_PurgeSetting();
		EOY_Progress__c eoyP = [SELECT ID, EOY_Purge_Settings_Completed__c FROM EOY_Progress__c WHERE School__c = null LIMIT 1];
		system.assertEquals(eoyP.EOY_Purge_Settings_Completed__c, true);
		test.stopTest();
	}

	static testMethod void testEOYWiz_OrgNewYear() {
		createTestData();
		test.startTest();
		//delete the custom settings, the class finds it alredy
		delete [SELECT ID FROM Purged_Object__c];
		EOYWiz_Landing();
		EOYWiz_PurgeSetting();
		EOYWiz_OrgNewYear();
		EOY_Progress__c eoyP = [SELECT ID, EOY_Next_School_Year_Completed__c FROM EOY_Progress__c WHERE School__c = null LIMIT 1];
		system.assertEquals(eoyP.EOY_Next_School_Year_Completed__c, true);
		test.stopTest();
	}

	static testMethod void testEOYWiz_OptionalExport() {
		createTestData();
		test.startTest();
		//delete the custom settings, the class finds it alredy
		delete [SELECT ID FROM Purged_Object__c];
		EOYWiz_Landing();
		EOYWiz_PurgeSetting();
		EOYWiz_OrgNewYear();
		EOYWiz_OptionalExport();
		test.stopTest();
	}

	static testMethod void testEOYWiz_SchoolGradeSpan() {
		createTestData();
		test.startTest();
		//delete the custom settings, the class finds it alredy
		delete [SELECT ID FROM Purged_Object__c];
		EOYWiz_Landing();
		EOYWiz_PurgeSetting();
		EOYWiz_OrgNewYear();
		EOYWiz_OptionalExport();
		EOYWiz_SchoolGradeSpan();
		//should only be one school that has an EOY_Progress
		EOY_Progress__c eoyP = [SELECT ID, School_Grade_Span_Completed__c FROM EOY_Progress__c WHERE School__c != null LIMIT 1];
		system.assertEquals(eoyP.School_Grade_Span_Completed__c, true);
		test.stopTest();
	}

	static testMethod void testEOYWiz_UpdateStudentInfo() {
		createTestData();
		test.startTest();
		//delete the custom settings, the class finds it alredy
		delete [SELECT ID FROM Purged_Object__c];
		EOYWiz_Landing();
		EOYWiz_PurgeSetting();
		EOYWiz_OrgNewYear();
		EOYWiz_OptionalExport();
		EOYWiz_SchoolGradeSpan();
		EOYWiz_UpdateStudentInfo();
		//should only be one school that has an EOY_Progress
		EOY_Progress__c eoyP = [SELECT ID, School_Student_Promotional_Completed__c FROM EOY_Progress__c WHERE School__c != null LIMIT 1];
		system.assertEquals(eoyP.School_Student_Promotional_Completed__c, true);
		test.stopTest();
	}

	static testMethod void testEOYWiz_CreateNextYearStudents() {
		createTestData();
		test.startTest();
		EOYWiz_Landing();
		EOYWiz_PurgeSetting();
		EOYWiz_OrgNewYear();
		EOYWiz_OptionalExport();
		EOYWiz_SchoolGradeSpan();
		EOYWiz_UpdateStudentInfo();
		EOYWiz_CreateNextYearStudents();
		test.stopTest();
	}

	static testMethod void testEOYWiz_Snapshots() {
		createTestData();

		Cohort__c c = new Cohort__c(School__c = TestDataSetupUtil_v2.school.id);
		insert c;

		for(Student__c s:TestDataSetupUtil_v2.studentsList){
			s.Cohort__c = c.id;
		}

		update TestDataSetupUtil_v2.studentsList;

		EOYWiz_Landing();
		EOYWiz_PurgeSetting_Light();
		

		test.startTest();
			EOYWiz_OrgNewYear_Light();
			EOYWiz_Landing EOY = new EOYWiz_Landing();
			EOY.orgWideSettingsComplete();

			EOY.selectedProgress = EOY.dEOYProgress[0].ID;
			Test.setCurrentPage(EOY.gotoSchoolSnapshots());

		
			EOYWiz_Snapshots();
		test.stopTest();
	}

	static testMethod void testEOYWiz_ProcessData() {
		createTestData();

		//delete the custom settings, the class finds it alredy
		delete [SELECT ID FROM Purged_Object__c];
		EOYWiz_Landing();
		EOYWiz_PurgeSetting();
		test.startTest();

		EOYWiz_OrgNewYear();
		EOYWiz_OptionalExport();
		EOYWiz_SchoolGradeSpan();
		EOYWiz_UpdateStudentInfo();

		EOYWiz_SchoolNextYearStudents EOYNextYearStudents = new EOYWiz_SchoolNextYearStudents();
		Test.setCurrentPage(EOYNextYearStudents.gotoSchoolSnapshots());

		EOYWiz_Snapshots_Light();

		EOYWiz_ProcessData();

		test.stopTest();
	}

	static testMethod void testEOYWiz_PurgeEOYData() {
		createTestData();

		//delete the custom settings, the class finds it alredy
		delete [SELECT ID FROM Purged_Object__c];
		EOYWiz_Landing();
		test.startTest();
		EOYWiz_PurgeSetting();
		EOYWiz_OrgNewYear();
		EOYWiz_OptionalExport();
		EOYWiz_SchoolGradeSpan();
		EOYWiz_UpdateStudentInfo();

		EOYWiz_SchoolNextYearStudents EOYNextYearStudents = new EOYWiz_SchoolNextYearStudents();
		Test.setCurrentPage(EOYNextYearStudents.gotoSchoolSnapshots());

		EOYWiz_Snapshots_Light();

		EOYWiz_SchoolProcessData EOYProcessData = new EOYWiz_SchoolProcessData();
		Test.setCurrentPage(EOYProcessData.gotoSchoolPurgeEOYData());

		EOYWiz_PurgeEOYData();

		test.stopTest();
	}

	public static void testEOYWiz_Setup() {
		testDataSetupUtil_v2.setupCustomSettings();
		testDataSetupUtil_v2.createDefaultTimeValues();
		//create more years

		SchoolForce_Settings__c sfs = SchoolForce_Settings__c.getOrgDefaults();
		sfs.Triggers_Disabled__c = true;
		upsert sfs;

		Picklist_Value__c yearPLV = [SELECT ID FROM Picklist_Value__c WHERE Type__c = 'Time' AND Name='Year' AND RecordType.Name='Time' LIMIT 1];

		List<Time_Element__c> addYears = new List<Time_Element__c>();
		Time_Element__c ay = new Time_Element__c(Picklist_Value__c = testDataSetupUtil_v2.YearPickVal.ID, New_School_Year__c = false);
		Integer month = system.today().month();
		Integer year = system.today().year()+30;
		String yearStart = '08/01/' + String.valueOf(year);
		String yearEnd = '07/31/' + String.valueOf(year+1);
		String termStart = yearStart;
		String termEnd  = yearEnd;
		Date startDate = date.parse(yearStart);
		Date endDate = date.parse(yearEnd);
		ay.End_Date__c = startDate.addYears(-1);
		ay.Date_Start_Date__c = endDate.addYears(-1);
		addYears.add(ay);

		Time_Element__c ay2 = new Time_Element__c(Picklist_Value__c = testDataSetupUtil_v2.YearPickVal.ID, New_School_Year__c = false);
		ay2.End_Date__c = startDate.addYears(-2);
		ay2.Date_Start_Date__c = endDate.addYears(-2);
		addYears.add(ay2);
		addYears[0].New_School_Year__c = false;
		addYears[0].Current__c = false;
		addYears[0].Previous_Year__c = true;
		addYears[0].Name__c = 'year 0';
		addYears[1].New_School_Year__c = false;
		addYears[1].Current__c = false;
		addYears[1].Previous_Year__c = true;
		addYears[1].Name__c = 'year 1';
		insert addYears;

		sfs.Triggers_Disabled__c = false;
		upsert sfs;

		TestDataSetupUtil_v2.school = TestDataSetupUtil_v2.getSchools(1)[0];
		TestDataSetupUtil_v2.setupTimeElements(30);
		TestDataSetupUtil_v2.setupCourses(3);
		TestDataSetupUtil_v2.setupSetupRecord();

		TestDataSetupUtil_v2.masterYear.Current__c = true;
		update TestDataSetupUtil_v2.masterYear;

		activeYear = TestDataSetupUtil_v2.masterYear.id;
	}

	static testMethod void testEOYWiz_PurgeHistoricalData() {
		testEOYWiz_Setup();
		Test.startTest();
			EOYWiz_Landing();
			EOYWiz_PurgeSetting();
			EOYWiz_OrgNewYear();

			List<EOY_Progress__c> progresses = [select id from EOY_Progress__c where School__c =: TestDataSetupUtil_v2.school.id];
			system.assertEquals(1, progresses.size());

			Time_Element__c nextYear = [select id from Time_Element__c where New_School_Year__c = true];

			PageReference pr = new PageReference('/apex/EOYWiz_SchoolPurgeHistoricalData');
			pr.getParameters().put('selectedProgress',progresses[0].id);
			pr.getParameters().put('nextYear',nextYear.id);
			pr.getParameters().put('activeYear', activeYear);
			Test.setCurrentPage(pr);
		
			EOYWiz_PurgeHistoricalData();
		Test.stopTest();
	}

	static testMethod void testEOYWiz_FinalizeEOYLanding(){
		testEOYWiz_Setup();
		Test.startTest();
			EOYWiz_Landing();
			EOYWiz_PurgeSetting();
			EOYWiz_OrgNewYear();

			List<EOY_Progress__c> progresses = [select id from EOY_Progress__c where School__c =: TestDataSetupUtil_v2.school.id];
			system.assertEquals(1, progresses.size());
			Time_Element__c nextYear = [select id from Time_Element__c where New_School_Year__c = true];

			PageReference pr = new PageReference('/apex/EOYWiz_SchoolPurgeHistoricalData');
			pr.getParameters().put('selectedProgress',progresses[0].id);
			pr.getParameters().put('nextYear',nextYear.id);
			pr.getParameters().put('activeYear', activeYear);
			Test.setCurrentPage(pr);

			EOYWiz_SchoolPurgeHistoricalData controller = new EOYWiz_SchoolPurgeHistoricalData();
			controller.updateEOYProgress();

			EOYWiz_Landing2();
	}

	static testMethod void testEOYWiz_PurgeHistoricalData0() {
		testEOYWiz_Setup();
		Test.startTest();
			EOYWiz_Landing();
			EOYWiz_PurgeSetting();
			EOYWiz_OrgNewYear();


			EOYWiz_SchoolProcessData EOYProcessData = new EOYWiz_SchoolProcessData();
			Test.setCurrentPage(EOYProcessData.gotoSchoolPurgeEOYData());

			PageReference pr = new PageReference('/apex/EOYWiz_SchoolPurgeHistoricalData');
			Test.setCurrentPage(pr);
			EOYWiz_PurgeHistoricalDataBatch(0, null);
		test.stopTest();
	}
}