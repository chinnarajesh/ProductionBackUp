@isTest
global class Test_BatchSnapshot {
	static Boolean dataLoaded = false;
	static Date defaultStart = date.newInstance(2011,08,01);
	static Date defaultEnd = date.newInstance(2012,07,31);
	static Setup__c defaultSetup;
	static Student__c defaultStudent;
	static Student_Section__c defaultStudentSection;
	
	static void setupData(){
		testDataSetupUtil_v2.setUPCoreData(1);
		testDataSetupUtil_v2.setUpStaffData(5);
		testDataSetupUtil_v2.setUpStudentData(5);
		defaultSetup = getSetupObject(defaultStart, defaultEnd);
		defaultStudentSection = testDataSetupUtil_v2.studSectionsList.get(0); 
		for (Student__c st : testDataSetupUtil_v2.studentsList){
			if (st.id == defaultStudentSection.Student__c) {
				defaultStudent = st;
			}
		}
		String query = BatchSnapshot.SELECT_CLAUSE +
				'from Student__c ' +
				'where id = \'' +
				String.escapeSingleQuotes(defaultStudent.id) +
				'\' LIMIT 1';
		List<Student__c> slist = Database.query(query);
		defaultStudent = slist.get(0);
		dataLoaded = true;
	}
	
	static void setupGrades(){
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			Section_Grade__c sectionGrade = new Section_Grade__C();
			sectionGrade.Student_Section__c = defaultStudentSection.id;
			sectionGrade.Grade__c = 3.1;
			sectionGrade.isFinal__c = true;
			Course__c course = testDataSetupUtil_v2.coursesList.get(0);
			system.debug('+++ coursesList.get(0):' + course);
			List<Course_Weightings__c> cw = [select id from Course_Weightings__c where Course__c = :course.id];
			sectionGrade.Course_Weighting__c = cw.get(0).id;
			
			insert sectionGrade;
		
			Standard__c gradeStandard = new Standard__c(Name = 'Grade', Level__c = 0);
			insert gradeStandard;
			
			Standard_Grade__c standardGrade = new Standard_Grade__c();
			standardGrade.Standard__c = gradeStandard.id;
			standardGrade.Student__c = defaultStudent.id;
			standardGrade.Weighted_Average_Grade__c = 3.5;
			standardGrade.Mean_Grade__c = 3.5;
			insert standardGrade;
		}
	}

	static Setup__c getSetupObject(Date startDate, Date endDate){
		Setup__c s = testDataSetupUtil_v2.activeSetUp; 
		Time_Element__c t = new Time_Element__c(Date_Start_Date__c = date.newInstance(2011,08,01),
												End_Date__c = date.newInstance(2012,07,31));
		s.Year__r = t;
		return s;		
	}
	
	static List<Student__c> getSomeStudents() {
		Account school = testDataSetupUtil_v2.school;
		String query = BatchSnapshot.SELECT_CLAUSE +
						'from Student__c ' +
						'where School__r.id = \'' +
						String.escapeSingleQuotes(school.id) +
						'\'';
		
		List<Student__c> students = Database.query(query);
		return students;
	}

	static testMethod void testCreateSnapshotLog() {
		setupData();
		Snapshot_Log__c snapShot;
		BatchSnapshot batch = new BatchSnapshot();
		snapShot = batch.createSnapshotLog2('Yearly',
			defaultSetup.School__c,
			defaultSetup.id,
			date.newInstance(2011,08,01),
			date.newInstance(2012,07,31),
			system.now());
		system.assertNotEquals(null, snapShot);
		List<Snapshot_Log__c> l = [select id from Snapshot_Log__c where id=:snapShot.Id];
		system.assertEquals(1, l.size());
		system.assertEquals('Yearly', snapShot.Snapshot_Type__c);
		system.assertEquals(date.newInstance(2011,08,01), snapShot.Period_Start__c);
		system.assertEquals(date.newInstance(2012,07,31), snapShot.Period_End__c);
		system.assertNotEquals(null, snapShot.Snapshot_Taken__c);
	}
	
	static testMethod void testInitialize() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot();
		batch.initialize(defaultSetup);
		system.assertNotEquals(null, batch.snapshotLog);
		system.assertNotEquals(null, batch.summaryRecordTypes);
		system.assertNotEquals(null, batch.childRecordTypes);
		system.assertNotEquals(null, batch.currentSetup);
		system.assertEquals(defaultStart, batch.snapshotLog.Period_Start__c);
		system.assertEquals(defaultEnd, batch.snapshotLog.Period_End__c);
	}
	
	static testMethod void testCalculateStudentSummary() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		List<Student__c> students = getSomeStudents();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(students.get(0), defaultStart, defaultEnd);
		Snapshot_Summary__c summary = batch.calculateStudentSummary(calcs, students.get(0), batch.snapshotLog);
		system.assertNotEquals(null, summary);
		system.assertEquals(batch.summaryRecordTypes.get('Student Summary'), summary.RecordTypeId);
		system.assertEquals(students.get(0).id, summary.Student__c);
		system.assertNotEquals(null, summary.Excused_Absences__c);
		system.assertNotEquals(null, summary.Unexcused_Absences__c);
		system.assertNotEquals(null, summary.Excused_Tardies__c);
		system.assertNotEquals(null, summary.Unexcused_Tardies__c);
		system.assertNotEquals(null, summary.In_School_Suspensions__c);
		system.assertNotEquals(null, summary.Out_School_Suspensions__c);
		system.assertNotEquals(null, summary.In_School_Suspension_Days__c);
		system.assertNotEquals(null, summary.Out_School_Suspension_Days__c);
		system.assertNotEquals(null, summary.Negative_Behavior__c);
		system.assertNotEquals(null, summary.Neutral_Behavior__c);
		system.assertNotEquals(null, summary.Positive_Behavior__c);
		system.assertNotEquals(null, summary.Free_Breakfasts__c);
		system.assertNotEquals(null, summary.Free_Lunches__c);
		system.assertNotEquals(null, summary.Full_Price_Breakfasts__c);
		system.assertNotEquals(null, summary.Full_Price_Lunches__c);
		system.assertNotEquals(null, summary.Reduced_Price_Breakfasts__c);
		system.assertNotEquals(null, summary.Reduced_Price_Lunches__c);
		system.assertNotEquals(null, summary.Behavior_Points__c);
		system.assertNotEquals(null, summary.Community_Service_Hours__c);
		system.assertNotEquals(null, summary.Instructional_Time_Lost__c);
		system.assertNotEquals(null, summary.Daily_Attendance__c);
		//system.assertNotEquals(null, summary.Average_GPA__c);
		system.assertNotEquals(null, summary.Credit_Earned_YTD__c);
		system.assertNotEquals(null, summary.Credit_Earned_Career__c);
	}
	
	static testMethod void testCalculateSchoolSummary() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		Test_BatchSnapshotSchoolCalcs.createSummaries(batch.snapshotLog, batch.getSnapshotRecordTypes('Snapshot_Summary__c'));
		Snapshot_Summary__c summary = batch.calculateSchoolSummary(batch.snapshotLog, batch.currentSetup);
		system.assertNotEquals(null, summary);
		system.assertEquals(batch.summaryRecordTypes.get('School Summary'), summary.RecordTypeId);
		system.assertNotEquals(null, summary.In_School_Suspensions__c);
		system.assertNotEquals(null, summary.Out_School_Suspensions__c);
		system.assertNotEquals(null, summary.In_School_Suspension_Days__c);
		system.assertNotEquals(null, summary.Out_School_Suspension_Days__c);
		system.assertNotEquals(null, summary.Negative_Behavior__c);
		system.assertNotEquals(null, summary.Neutral_Behavior__c);
		system.assertNotEquals(null, summary.Positive_Behavior__c);
		system.assertNotEquals(null, summary.Free_Breakfasts__c);
		system.assertNotEquals(null, summary.Free_Lunches__c);
		system.assertNotEquals(null, summary.Full_Price_Breakfasts__c);
		system.assertNotEquals(null, summary.Full_Price_Lunches__c);
		system.assertNotEquals(null, summary.Reduced_Price_Breakfasts__c);
		system.assertNotEquals(null, summary.Reduced_Price_Lunches__c);
	}
	
	static testMethod void testGetSnapshotRecordTypes() {
		BatchSnapshot batch = new BatchSnapshot();
		Map<String,Id> rmap = batch.getSnapshotRecordTypes('Snapshot_Summary__c');

		system.debug(LoggingLevel.INFO, '+++rmap: ' + rmap);    	
		system.assertNotEquals(null, rmap);
		system.assert(rmap.size() > 0);
	}
	
	static testMethod void testExecute() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		List<Student__c> students = getSomeStudents();
		Test.startTest();
		batch.execute(null, students);
		List<Snapshot_Summary__c> summaries = [select id from Snapshot_Summary__c
												where Snapshot_ID__c = :batch.snapshotLog.ID];
		system.assertNotEquals(null, summaries);
		system.assertEquals(5, summaries.size());
		try {
			batch.execute(null, new List<Student__c>());
			system.assert(true);
		}    											
		catch (Exception e) {
			system.assert(false);
		}
		Test.stopTest();
	}
	
	global class testBatchContext implements Database.BatchableContext{
		global testBatchContext(){
			system.debug('In testBatchContext constructor.');
		}
		global Id getJobId(){
			//don't change these, or the test start will start failing
			return '707d000000bQXs7';
		}
		global Id getChildJobId(){
			return '707d000000bQXs7';
		}
	}
	
	static testMethod void testStart() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		Database.Batchablecontext bc = new testBatchContext();
		Database.Querylocator locator = batch.start(bc);
		system.assertNotEquals(null, locator);
	}
	
	static testMethod void testFinish() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		try {
			batch.finish(new testBatchContext());
			system.assert(true);
		}
		catch (Exception e) {
			system.assert(false);
		}
	}

	static testMethod void testGetStudentSections() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot();
		List<Student__c> students = getSomeStudents();
		Student__c student;
		for (Student__c s : students) {
			if (s.id == testDataSetupUtil_v2.studSectionsList.get(0).Student__c) {
				student = s;
			}
		}
		List<Student_Section__c> ss = batch.getStudentSections(student);
		system.assertNotEquals(null, ss);
		system.assertEquals(1, ss.size());
	}
	
	static testMethod void testCalculateStudentChildren() {
		setupData();
		setupGrades();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		Snapshot_Summary__c summary = new Snapshot_Summary__c();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		List<Snapshot_Child__c> children = batch.calculateStudentChildren(calcs, 
																		defaultStudent, 
																		batch.getStudentSections(defaultStudent),
																		batch.getStandardGrades(defaultStudent), 
																		summary);
		system.assertNotEquals(null, children);
		system.assertEquals(2, children.size());
		system.assertNotEquals(null, children.get(0).Attendance_Percent__c);
		system.assertNotEquals(null, children.get(0).Grade__c);
		system.assertNotEquals(null, children.get(1).Grade__c);
	}
	
	static testMethod void testGetStandardGrades(){
		setupData();
		setupGrades();
		BatchSnapshot batch = new BatchSnapshot();
		List<Standard_Grade__c> sg = batch.getStandardGrades(defaultStudent);
		system.assertNotEquals(null, sg);
		system.assertEquals(1, sg.size());
	}
	
	static testMethod void testCreateBatchCalcs() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		List<BatchSnapshotStudentCalcs> calcs = batch.createBatchCalcs(defaultStudent);
		system.assertNotEquals(null, calcs);
		system.assert(calcs.size() > 0);    	
	}
	
	static testMethod void testCareerCreditHoursEarned() {
		setupData();
		setupGrades();
		Test.startTest();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		List<BatchSnapshotStudentCalcs> calcs = batch.createBatchCalcs(defaultStudent);
		for (BatchSnapshotStudentCalcs c : calcs) {
			c.student.Setup__r.Passing_Grade_Threshold__c = 1;
		}
		Double credits = batch.careerCreditHoursEarned(calcs);
		system.assertNotEquals(null, credits);
		//system.assert(credits > 0);
		Test.stopTest();
	}
	
 
	static testMethod void testCalculateSectionSummaries() {
		setupData();
		setupGrades();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		Snapshot_Summary__c summary = new Snapshot_Summary__c();
		List<Snapshot_Child__c> children = batch.calculateSectionSummaries(batch.snapshotLog, 
																			summary, 
																			batch.getSectionsForSchool(defaultSetup.School__c), 
																			defaultSetup);
		system.assertNotEquals(null, children);
		system.assertEquals(1, children.size());
		Snapshot_Child__c child = children.get(0);
		system.assertNotEquals(null, child.RecordTypeId);
		system.assertNotEquals(null, child.Section__c);
		//system.assertNotEquals(null, child.Average_Attendance__c);
		system.assertNotEquals(null, child.Average_GPA__c);
		system.assertNotEquals(null, child.Attendance_Percent__c);
		system.assertNotEquals(null, child.Percent_Excused_Absence__c);
		system.assertNotEquals(null, child.Percent_Excused_Tardies__c);
		system.assertNotEquals(null, child.Percent_Unexcused_Absence__c);
		system.assertNotEquals(null, child.Percent_Unexcused_Tardies__c);
		system.assertNotEquals(null, child.Assigned_Staff__c);
	}
	
	static testMethod void testGetSectionsForSchool() {
		setupData();
		BatchSnapshot batch = new BatchSnapshot(defaultSetup.id);
		List<Section__c> sections = batch.getSectionsForSchool(defaultSetup.School__c);
		system.assertNotEquals(null, sections);
		system.assertEquals(1, sections.size());
	}
}