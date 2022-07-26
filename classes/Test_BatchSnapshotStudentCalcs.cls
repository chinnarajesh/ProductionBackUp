@isTest
private class Test_BatchSnapshotStudentCalcs {
	static Student__c defaultStudent;
	static Date defaultStart = date.newInstance(2011,08,01);
	static Date defaultEnd = date.newInstance(2012,07,31);
	static Boolean dataLoaded = false;
	static List<Attendance__c> attendanceList;
	static List<Session__c> defaultSessions;
	static List<Session__c> oldSessions;
	static Integer sectionAttendAdded = 0;
	static Integer attendAdded = 0;
	static Integer oldAdded = 0;
	static Integer inSchoolConsequences = 0;
	static Integer outSchoolConsequences = 0;
	static Integer inSchoolDays = 0;
	static Integer outSchoolDays = 0;
	static Integer currentConsequences = 0;
	static Integer oldConsequences = 0;
	static Integer currentStudentBehaviors = 0;
	static Integer oldStudentBehaviors = 0;
	static Integer negativeBehaviors = 0;
	static Integer neutralBehaviors = 0;
	static Integer positiveBehaviors = 0;
	static Integer freeBreakfasts = 0;
	static Integer fullBreakfasts = 0;
	static Integer reducedBreakfasts = 0;
	static Integer freeLunches = 0;
	static Integer fullLunches = 0;
	static Integer reducedLunches = 0;
	static Integer currentMeals = 0;
	static Integer oldMeals = 0;
	static Student__c freeStudent;
	static Student__c fullStudent;
	static Student__c reducedStudent;
	static Double attendanceTimeLost = 0;
	static Double sectionTimeLost = 0;
	static Double consequenceTimeLost = 0;
	static Map<String, Picklist_Value__c> pMap;
	static Section__c defaultSection;
	static Student_Section__c defaultStudentSection;

	static Attendance__c createAttendance(Picklist_Value__c pv, Boolean daily, Session__c session) {
		Long timeLost = 0;
		if (pv.Category__c.equals('Absent')){
			timeLost = (session.End_DateTime__c.getTime() - session.Start_DateTime__c.getTime()) / 60000;
		}

		Attendance__c attend = new Attendance__c(Student__c = defaultStudent.id,
													Picklist_Value__c = pv.id,
													Daily__c = daily,
													Session__c = session.id,
													Time_Lost_Rollup__c = timeLost);
		return attend;
	}

	static List<Session__c> createSessions(Session__c origSession, Date baseDate, Integer cnt){
		List<Session__c> sessions = new List<Session__c>();
		Session__c newSession;
		Datetime startDate = datetime.newInstance(baseDate, time.newInstance(08, 30, 2, 0));
		Datetime endDate = datetime.newInstance(baseDate, time.newInstance(17, 30, 2, 0));
		for (Integer i=0; i<cnt; i++){
			newSession = origSession.clone(false, true);
			newSession.Start_DateTime__c = startDate.addDays(i);
			newSession.End_DateTime__c = endDate.addDays(i);
			sessions.add(newSession);
		}

		return sessions;
	}

	static Integer createAttendanceRecords(Picklist_Value__c pv, Boolean daily, List<Attendance__c> aList, List<Session__c> sList, Integer cnt, Integer index) {
		for (Integer i=0; i<cnt; i++){
			aList.add(createAttendance(pv, daily, sList.get(i+index)));
		}
		return cnt;
	}

	static Map<String, Picklist_Value__c> createPicklistValues() {
		Map<String, Picklist_Value__c> pickList = new Map<String, Picklist_Value__c>();
		Map<String, Id > rtMap= core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
		Id consRecordType = rtMap.get('Behavior_Consequence');
		Id attendRecordType = rtMap.get('Attendance');

		pickList.put('Suspension (In School)',new Picklist_Value__c(Name = 'Suspension (In School)'
											,recordTypeId = consRecordType
											,setup__c = testDataSetupUtil_v2.activeSetUp.id
											,set_as_default__c=false
											,Is_Suspension__c = true
											,Is_Tardy__c = false
											,Is_Early_Departure__c = false
											,corresponding_value__c = 5
											,notify_Admin__c = false
											,order__c = 3
											,Category__c = 'In School Suspension'
											));
		pickList.put('Suspension (Out of School)', new Picklist_Value__c(Name = 'Suspension (Out of School)'
											,recordTypeId = consRecordType
											,setup__c = testDataSetupUtil_v2.activeSetUp.id
											,set_as_default__c=false
											,Is_Suspension__c = true
											,Is_Tardy__c = false
											,Is_Early_Departure__c = false
											,corresponding_value__c = 900
											,notify_Admin__c = false
											,order__c = 4
											,Category__c = 'Out of School Suspension'
											));
		pickList.put('Excused Absence', new Picklist_Value__c(Name = 'Excused Absence'
											,recordTypeId = attendRecordType
											,setup__c = testDataSetupUtil_v2.activeSetUp.id
											,set_as_default__c=false
											,Category__c = 'Absent'
											,Is_Unexcused__c = false
											,Is_Tardy__c = false
											,Is_Early_Departure__c = false
											));
		pickList.put('Unexcused Absence', new Picklist_Value__c(Name = 'Unexcused Absence'
											,recordTypeId = attendRecordType
											,setup__c = testDataSetupUtil_v2.activeSetUp.id
											,set_as_default__c=false
											,Category__c = 'Absent'
											,Is_Unexcused__c = true
											,Is_Tardy__c = false
											,Is_Early_Departure__c = false
											));
		pickList.put('Excused Tardy', new Picklist_Value__c(Name = 'Excused Tardy'
											,recordTypeId = attendRecordType
											,setup__c = testDataSetupUtil_v2.activeSetUp.id
											,set_as_default__c=false
											,Category__c = 'Partial'
											,Is_Unexcused__c = false
											,Is_Tardy__c = true
											,Is_Early_Departure__c = false
											));
		pickList.put('Unexcused Tardy', new Picklist_Value__c(Name = 'Unexcused Tardy'
											,recordTypeId = attendRecordType
											,setup__c = testDataSetupUtil_v2.activeSetUp.id
											,set_as_default__c=false
											,Category__c = 'Partial'
											,Is_Unexcused__c = true
											,Is_Tardy__c = true
											,Is_Early_Departure__c = false
											));
		pickList.put('Present', new Picklist_Value__c(Name = 'Present'
											,recordTypeId = attendRecordType
											,setup__c = testDataSetupUtil_v2.activeSetUp.id
											,set_as_default__c=false
											,Category__c = 'Present'
											,Is_Tardy__c = false
											,Is_Early_Departure__c = false
											));
		return pickList;
	}

	static List<Behavior_Incident__c> createBehaviorRecords(Date incidentDate, String behaviorRecordType, Integer cnt) {
		List<Picklist_Value__c> plList = testDataSetupUtil_v2.behaviorPicklistVals;
		List<Behavior_Incident__c> bList = new List<Behavior_Incident__c>();
		Map<String, Id> rtMapBehavior = core_SoqlUtils.getRecordTypesBySobject('Behavior_Incident__c');
		for (Integer i=0; i<cnt; i++){
			Behavior_Incident__c bi;
			bi = new Behavior_Incident__c(Incident_Type__c = 'Negative'
											,Incident_Date__c = incidentDate.addDays(i)
											,Incident_Description__c = 'This is a test incident #' + i + ' day ' + incidentDate.dayOfYear()
											,Incident_Title__c = 'Test Incident' + i + ' day ' + incidentDate.dayOfYear()
											,Incident_Time__c = '0730'
											,Context_Time__c = 'EDP-BeforeSchool'
											,Context_Location__c = 'Sidewalk/Street'
											,Weapon_Type__c = 'Bomb'
											,Other__c = true
											,Incident_Status__c = 'Draft'
											,Other_Notes__c = 'Test'
											,Selected_Behavior_Incident_Type__c = plList[2].id
											,Selected_Behavior_Category__c = 'Disruptive / Disrespectful'
											,RecordTypeId = rtMapBehavior.get(behaviorRecordType)
											);
			bList.add(bi);
		}
		return bList;
	}

	static List<Student_Behavior__c> createStudentBehaviorRecords(Student__c student, List<Behavior_Incident__c> bList) {
		List<Student_Behavior__c> sbList = new List<Student_Behavior__c>();
		Integer i = 1;
		for (Behavior_Incident__c bi : bList){
			Student_Behavior__c sb;
			sb = new Student_Behavior__c(Student__c = student.id,
										Incident_Role__c = 'Instigator',
										Behavior_Incident__c = bi.Id,
										Behavior_Weighting__c = i * 15);
			i++;
			sbList.add(sb);
		}
		return sbList;
	}

	static List<Consequence__c> createConsequenceRecords(String consequenceType, List<Student_Behavior__c> sbList) {
		List<Consequence__c> cList = new List<Consequence__c>();
		for (Student_Behavior__c sb : sbList){
			Consequence__c cons;
			Id someId;
			Picklist_Value__c pv = pMap.get(consequenceType);
			if (pv != null) {
				someId = pv.id;
			}
			cons = new Consequence__c(Student__c = sb.Id,
										Picklist_Value__c = someId,
										Final_Consequence__c = true,
										Time_Lost__c = 8,
										Student_Consequence__c = sb.Student__c,
										Days_Suspended__c = 2);
			cList.add(cons);
		}
		return cList;
	}

	static List<Meal_Transaction__c> createMealRecords(Student__c student,
														String mealType,
														Date tranDate,
														Integer cnt) {
		List<Meal_Transaction__c> meals = new List<Meal_Transaction__c>();
		Meal_Transaction__c meal;

		for(Integer i=0; i<cnt; i++){
			meal = new Meal_Transaction__c(Student__c = student.id,
											Meal_Type__c = mealType,
											Transaction_Date__c = tranDate.addDays(i),
											Transaction_Type__c = 'Sale');
			meals.add(meal);
		}
		return meals;
	}

	static void setupAttendance(){
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			testDataSetupUtil_v2.createDefaultAttendanceTypes(testDataSetupUtil_v2.activeSetup);
			attendanceList = new List<Attendance__c>();
			attendAdded += createAttendanceRecords(pMap.get('Present'), true, attendanceList, defaultSessions, 6, attendAdded);
			attendAdded += createAttendanceRecords(pMap.get('Excused Absence'), true, attendanceList, defaultSessions, 3, attendAdded);
			attendAdded += createAttendanceRecords(pMap.get('Unexcused Absence'), true, attendanceList, defaultSessions, 2, attendAdded);
			attendAdded += createAttendanceRecords(pMap.get('Excused Tardy'), true, attendanceList, defaultSessions, 2, attendAdded);
			attendAdded += createAttendanceRecords(pMap.get('Unexcused Tardy'), true, attendanceList, defaultSessions, 3, attendAdded);
			sectionAttendAdded += createAttendanceRecords(pMap.get('Excused Absence'), false, attendanceList, defaultSessions, 3, 0);
			sectionAttendAdded += createAttendanceRecords(pMap.get('Present'), false, attendanceList, defaultSessions, 7, 0);
			for(Attendance__c a : attendanceList){
				if (a.Daily__c){
					attendanceTimeLost += a.Time_Lost_Rollup__c;
				}
				else {
					sectionTimeLost += a.Time_Lost_Rollup__c;
				}
			}

			oldAdded += createAttendanceRecords(pMap.get('Excused Absence'), true, attendanceList, oldSessions, 10, oldAdded);

			insert attendanceList;
		}
	}

	static void setupConsequences(){
		List<Consequence__c> cList = new List<Consequence__c>();
		List<List<Behavior_Incident__c>> bList = new List<List<Behavior_Incident__c>>();
		List<Behavior_Incident__c> allBList = new List<Behavior_Incident__c>();
		List<List<Student_Behavior__c>> sbList = new List<List<Student_Behavior__c>>();
		List<Student_Behavior__c> allSBList = new List<Student_Behavior__c>();

		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			bList.add(createBehaviorRecords(date.newInstance(2011,12,15), 'Negative', 3));
			bList.add(createBehaviorRecords(date.newInstance(2012,1,15), 'Negative', 1));
			bList.add(createBehaviorRecords(date.newInstance(2012,2,15), 'Negative', 1));
			bList.add(createBehaviorRecords(date.newInstance(2012,3,15), 'Neutral', 2));
			bList.add(createBehaviorRecords(date.newInstance(2012,4,15), 'Positive', 1));
			bList.add(createBehaviorRecords(date.newInstance(2010,12,15), 'Negative', 3));
			for (List<Behavior_Incident__c> bl : bList) {
				allBList.addAll(bl);
			}
			insert allBList;
			negativeBehaviors = bList.get(0).size() +
								bList.get(1).size() +
								bList.get(2).size();
			neutralBehaviors = bList.get(3).size();
			positiveBehaviors = bList.get(4).size();

			sbList.add(createStudentBehaviorRecords(defaultStudent, bList.get(0)));
			sbList.add(createStudentBehaviorRecords(defaultStudent, bList.get(1)));
			sbList.add(createStudentBehaviorRecords(defaultStudent, bList.get(2)));
			sbList.add(createStudentBehaviorRecords(defaultStudent, bList.get(3)));
			sbList.add(createStudentBehaviorRecords(defaultStudent, bList.get(4)));
			sbList.add(createStudentBehaviorRecords(defaultStudent, bList.get(5)));
			for (List<Student_Behavior__c> sbl : sbList) {
				allSBList.addAll(sbl);
			}
			insert allSBList;

			currentStudentBehaviors = sbList.get(0).size() +
										sbList.get(1).size() +
										sbList.get(2).size() +
										sbList.get(3).size() +
										sbList.get(4).size();
			oldStudentBehaviors = sbList.get(5).size();

			cList.addAll(createConsequenceRecords('Suspension (In School)', sbList.get(0)));
			inSchoolConsequences = sbList.get(0).size();
			cList.addAll(createConsequenceRecords('Suspension (Out of School)', sbList.get(1)));
			outSchoolConsequences = sbList.get(1).size();
			cList.addAll(createConsequenceRecords('Other', sbList.get(2)));
			cList.addAll(createConsequenceRecords('Other', sbList.get(3)));
			cList.addAll(createConsequenceRecords('Other', sbList.get(4)));
			currentConsequences = cList.size();
			cList.addAll(createConsequenceRecords('Suspension (In School)', sbList.get(5)));
			oldConsequences  = sbList.get(5).size();
			insert cList;
			List<Student_Behavior__c> currentSBList = new List<Student_Behavior__c>();
			for (Integer i=0; i<5; i++) {
				currentSBList.addAll(sbList.get(i));
			}
			List<Student_Behavior__c> newSBList = [select id, Consequence_Time_Lost__c
													from Student_Behavior__c
													where id in :currentSBList];
			for (Student_Behavior__c sb : newSBList){
				consequenceTimeLost += sb.Consequence_Time_Lost__c;
			}

		}
	}

	static void setupMeals(){
		List<Meal_Transaction__c> mealList = new List<Meal_Transaction__c>();
		List<Meal_Transaction__c> meals;

		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			Meals_Setup__c mealSetup = new Meals_Setup__c(Setup__c = testDataSetupUtil_v2.activeSetUp.id,
															Active__c = true);
			insert mealSetup;
			meals = createMealRecords(freeStudent, 'Breakfast', date.newInstance(2011,09,1), 3);
			freeBreakfasts = meals.size();
			mealList.addAll(meals);
			meals = createMealRecords(fullStudent, 'Breakfast', date.newInstance(2011,09,5), 2);
			fullBreakfasts = meals.size();
			mealList.addAll(meals);
			meals = createMealRecords(reducedStudent, 'Breakfast', date.newInstance(2011,09,10), 1);
			reducedBreakfasts = meals.size();
			mealList.addAll(meals);
			meals = createMealRecords(freeStudent, 'Lunch', date.newInstance(2011,10,15), 4);
			freeLunches= meals.size();
			mealList.addAll(meals);
			meals = createMealRecords(fullStudent, 'Lunch', date.newInstance(2011,10,20), 3);
			fullLunches = meals.size();
			mealList.addAll(meals);
			meals = createMealRecords(reducedStudent, 'Lunch', date.newInstance(2011,10,25), 2);
			reducedLunches = meals.size();
			mealList.addAll(meals);
			currentMeals = mealList.size();
			meals = createMealRecords(freeStudent, 'Lunch', date.newInstance(2010,12,1), 6);
			mealList.addAll(meals);
			oldMeals = meals.size();
			insert mealList;
		}
	}

	static void setupGrades(){
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			Section_Grade__c sectionGrade = new Section_Grade__C();
			sectionGrade.Student_Section__c = defaultStudentSection.id;
			sectionGrade.Grade__c = 3.1;
			sectionGrade.isFinal__c = true;
			Course__c course = testDataSetupUtil_v2.coursesList.get(0);
			List<Course_Weightings__c> cw = [select id from Course_Weightings__c where Course__c = :course.id];
			sectionGrade.Course_Weighting__c = cw.get(0).id;

			insert sectionGrade;
		}
	}

	static void setupData(){
		testDataSetupUtil_v2.isBehavior=true;
		testDataSetupUtil_v2.setUPCoreData(1);
		testDataSetupUtil_v2.setUpStaffData(5);
		testDataSetupUtil_v2.setupSessiondata();
		testDataSetupUtil_v2.setUpStudentData(5);

		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			Session__c session = testDataSetupUtil_v2.sessionsList.get(0);
			defaultSection = session.Section__r;
			List<Student__c> students = testDataSetupUtil_v2.studentsList;
			defaultSessions = createSessions(session, date.newInstance(2011,10,1), 16);
			oldSessions = createSessions(session, date.newInstance(2010,11,1), 10);

			List<Session__c> toInsert = new List<Session__c>();
			toInsert.addAll(oldSessions);
			toInsert.addAll(defaultSessions);
			insert toInsert;

			students.get(0).Service_Hours_YTD__c = 41.25;
			students.get(0).Meals_Category__c = 'Free';
			students.get(1).Meals_Category__c = 'Full-Priced';
			students.get(2).Meals_Category__c = 'Reduced';
			update students;
			defaultStudentSection = testDataSetupUtil_v2.studSectionsList.get(0);
			for (Student__c st : students){
				if (st.id == defaultStudentSection.Student__c) {
					defaultStudent = st;
				}
			}
			freeStudent = students.get(0);
			fullStudent = students.get(1);
			reducedStudent = students.get(2);
			pMap = createPicklistValues();
			insert pMap.values();
		}
	}

	static testMethod void testInitialize() {
		setupData();

		Test.startTest();
			setupAttendance();
			setupConsequences();
			setupMeals();
			BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs();
			calcs.initialize(defaultStudent, defaultStart, defaultEnd);
			system.assertNotEquals(null, calcs.student);
			system.assertEquals(defaultStudent, calcs.student);
			system.assertNotEquals(null, calcs.startDate);
			system.assertEquals(date.newInstance(2011,08,01), calcs.startDate);
			system.assertNotEquals(null, calcs.endDate);
			system.assertEquals(date.newInstance(2012,07,31), calcs.endDate);
			List<Attendance__c> aRecs = calcs.attendanceRecords;
			system.assertNotEquals(null, aRecs);
			List<Consequence__c> cRecs = calcs.consequenceRecords;
			system.assertNotEquals(null, cRecs);
			List<Student_Behavior__c> sbRecs = calcs.studentBehaviorRecords;
			system.assertNotEquals(null, sbRecs);
			List<Meal_Transaction__c> mealRecs = calcs.mealRecords;
			system.assertNotEquals(null, mealRecs);
		Test.stopTest();
	}

	static testMethod void testInitializeFinalSectionGrades() {
		setupData();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs();
		calcs.initializeFinalSectionGrades(defaultStudent, defaultStart, defaultEnd);
		system.assertNotEquals(null, calcs.student);
		system.assertEquals(defaultStudent, calcs.student);
		system.assertNotEquals(null, calcs.startDate);
		system.assertEquals(date.newInstance(2011,08,01), calcs.startDate);
		system.assertNotEquals(null, calcs.endDate);
		system.assertEquals(date.newInstance(2012,07,31), calcs.endDate);
		Map<Id, Section_Grade__c> finalGrades = calcs.finalSectionGrades;
		system.assertNotEquals(null, finalGrades);
		Test.stopTest();
	}

	static testMethod void testGetAttendanceRecords() {
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs();
		List<Attendance__c> aList = calcs.getAttendanceRecords(defaultStudent.id, defaultStart, defaultEnd);
		system.assertEquals(attendAdded+sectionAttendAdded, aList.size());
		aList = calcs.getAttendanceRecords(defaultStudent.id, date.newInstance(2010,08,01), defaultEnd);
		system.assertEquals(attendAdded+sectionAttendAdded+oldAdded, aList.size());
		Test.stopTest();
	}

	static testMethod void testGetConsequenceRecords() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs();
		List<Consequence__c> cList = calcs.getConsequenceRecords(defaultStudent.id, defaultStart, defaultEnd);
		system.assertEquals(currentConsequences, cList.size());
		cList = calcs.getConsequenceRecords(defaultStudent.id, date.newInstance(2010,08,01), defaultEnd);
		system.assertEquals(currentConsequences+oldConsequences, cList.size());
		Test.stopTest();
	}

	static testMethod void testGetStudentBehaviorRecords() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs();
		List<Student_Behavior__c> sbList = calcs.getStudentBehaviorRecords(defaultStudent.id, defaultStart, defaultEnd);
		system.assertEquals(currentStudentBehaviors, sbList.size());
		sbList = calcs.getStudentBehaviorRecords(defaultStudent.id, date.newInstance(2010,08,01), defaultEnd);
		system.assertEquals(currentStudentBehaviors+oldStudentBehaviors, sbList.size());
		Test.stopTest();
	}

	static testMethod void testGetMealRecords() {
		setupData();
		setupMeals();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs();
		List<Meal_Transaction__c> mealList = calcs.getMealRecords(freeStudent.id, defaultStart, defaultEnd);
		mealList.addAll(calcs.getMealRecords(fullStudent.id, defaultStart, defaultEnd));
		mealList.addAll(calcs.getMealRecords(reducedStudent.id, defaultStart, defaultEnd));
		system.assertEquals(currentMeals, mealList.size());
		mealList = calcs.getMealRecords(freeStudent.id, date.newInstance(2010,08,01), defaultEnd);
		mealList.addAll(calcs.getMealRecords(fullStudent.id, date.newInstance(2010,08,01), defaultEnd));
		mealList.addAll(calcs.getMealRecords(reducedStudent.id, date.newInstance(2010,08,01), defaultEnd));
		system.assertEquals(currentMeals+oldMeals, mealList.size());
		Test.stopTest();
	}

	static testMethod void testDailyAttendance() {
		Map<String,Boolean> bMap = new Map<String, Boolean>();
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer days;
		days = calcs.countDailyAttendance('Present', null);
		system.assertEquals(6, days);
		bMap.clear();
		bMap.put('Is_Unexcused__c', false);
		days = calcs.countDailyAttendance('Absent', bMap);
		system.assertEquals(3, days);
		bMap.clear();
		bMap.put('Is_Unexcused__c', true);
		days = calcs.countDailyAttendance('Absent', bMap);
		system.assertEquals(2, days);
		Test.stopTest();
	}

	static testMethod void testDailyExcusedAbsences() {
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer days;
		days = calcs.dailyExcusedAbsences();
		system.assertEquals(3, days);
		Test.stopTest();
	}

	static testMethod void testDailyUnexcusedAbsences() {
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer days;
		days = calcs.dailyUnexcusedAbsences();
		system.assertEquals(2, days);
		Test.stopTest();
	}

	static testMethod void testDailyExcusedTardies() {
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer days;
		days = calcs.dailyExcusedTardies();
		system.assertEquals(2, days);
		Test.stopTest();
	}

	static testMethod void testDailyUnexcusedTardies() {
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer days;
		days = calcs.dailyUnexcusedTardies();
		system.assertEquals(3, days);
		Test.stopTest();
	}

	static testMethod void testGetConsequenceCount() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer cCount = calcs.getConsequenceCount('In School Suspension');
		system.assertEquals(3, cCount);
		cCount = calcs.getConsequenceCount('Out of School Suspension');
		system.assertEquals(1, cCount);
		Test.stopTest();
	}

	static testMethod void testGetConsequenceDays() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Decimal dayCount = calcs.getConsequenceDays('In School Suspension');
		system.assertEquals(6, dayCount);
		dayCount = calcs.getConsequenceDays('Out of School Suspension');
		system.assertEquals(2, dayCount);
		Test.stopTest();
	}

	static testMethod void testCountInSchoolSuspension() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer cnt;
		cnt = calcs.countInSchoolSuspension();
		system.assertEquals(3, cnt);
		Test.stopTest();
	}

	static testMethod void testCountOutSchoolSuspension() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer cnt;
		cnt = calcs.countOutSchoolSuspension();
		system.assertEquals(1, cnt);
		Test.stopTest();
	}

	static testMethod void testDaysInSchoolSuspension() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Decimal days;
		days = calcs.daysInSchoolSuspension();
		system.assertEquals(6, days);
		Test.stopTest();
	}

	static testMethod void testDaysOutSchoolSuspension() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Decimal days;
		Days = calcs.daysOutSchoolSuspension();
		system.assertEquals(2, days);
		Test.stopTest();
	}

	static testMethod void testGetStudentBehaviorCount() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer bCount = calcs.getStudentBehaviorCount('Negative');
		system.assertEquals(negativeBehaviors, bCount);
		bCount = calcs.getStudentBehaviorCount('Neutral');
		system.assertEquals(neutralBehaviors, bCount);
		bCount = calcs.getStudentBehaviorCount('Positive');
		system.assertEquals(positiveBehaviors, bCount);
		Test.stopTest();
	}

	static testMethod void testCountNegativeBehavior() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer cnt = calcs.countNegativeBehavior();
		system.assertEquals(negativeBehaviors, cnt);
		Test.stopTest();
	}

	static testMethod void testCountNeutralBehavior() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer cnt = calcs.countNeutralBehavior();
		system.assertEquals(neutralBehaviors, cnt);
		Test.stopTest();
	}

	static testMethod void testCountPositiveBehavior() {
		setupData();
		setupConsequences();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer cnt = calcs.countPositiveBehavior();
		system.assertEquals(positiveBehaviors, cnt);
		Test.stopTest();
	}

	static testMethod void testGetBehaviorPoints() {
		setupData();
		setupConsequences();
		Student__c newStudent = [select id,name,Student_Behavior_score__c
								from Student__c
								where id = :defaultStudent.id limit 1];
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(newStudent, defaultStart, defaultEnd);
		Double points = calcs.getBehaviorPoints();
		system.assertNotEquals(null, points);
		Test.stopTest();
	}

	static testMethod void testGetMealCount() {
		setupData();
		setupMeals();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(freeStudent, defaultStart, defaultEnd);
		system.assertEquals(freeBreakfasts,calcs.getMealCount('Breakfast', 'Free'));
		system.assertEquals(freeLunches,calcs.getMealCount('Lunch', 'Free'));
		calcs = new BatchSnapshotStudentCalcs(fullStudent, defaultStart, defaultEnd);
		system.assertEquals(fullBreakfasts,calcs.getMealCount('Breakfast', 'Full-Priced'));
		system.assertEquals(fullLunches,calcs.getMealCount('Lunch', 'Full-Priced'));
		calcs = new BatchSnapshotStudentCalcs(reducedStudent, defaultStart, defaultEnd);
		system.assertEquals(reducedBreakfasts,calcs.getMealCount('Breakfast', 'Reduced'));
		system.assertEquals(reducedLunches,calcs.getMealCount('Lunch', 'Reduced'));
		Test.stopTest();
	}

	static testMethod void testCountFreeBreakfasts() {
		setupData();
		setupMeals();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(freeStudent, defaultStart, defaultEnd);
		system.assertEquals(freeBreakfasts,calcs.countFreeBreakfasts());
		Test.stopTest();
	}

	static testMethod void testCountFreeLunches() {
		setupData();
		setupMeals();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(freeStudent, defaultStart, defaultEnd);
		system.assertEquals(freeLunches,calcs.countFreeLunches());
		Test.stopTest();
	}

	static testMethod void testCountFullBreakfasts() {
		setupData();
		setupMeals();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(fullStudent, defaultStart, defaultEnd);
		system.assertEquals(fullBreakfasts,calcs.countFullBreakfasts());
		Test.stopTest();
	}

	static testMethod void testCountFullLunches() {
		setupData();
		setupMeals();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(fullStudent, defaultStart, defaultEnd);
		system.assertEquals(fullLunches,calcs.countFullLunches());
		Test.stopTest();
	}

	static testMethod void testCountReducedBreakfasts() {
		setupData();
		setupMeals();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(reducedStudent, defaultStart, defaultEnd);
		system.assertEquals(reducedBreakfasts,calcs.countReducedBreakfasts());
		Test.stopTest();
	}

	static testMethod void testCountReducedLunches() {
		setupData();
		setupMeals();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(reducedStudent, defaultStart, defaultEnd);
		system.assertEquals(reducedLunches,calcs.countReducedLunches());
		Test.stopTest();
	}

	static testMethod void testGetCommunityServiceHours() {
		setupData();
		Student__c newStudent = [select id,name,Service_Hours_YTD__c
								from Student__c
								where id = :defaultStudent.id limit 1];
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(newStudent, defaultStart, defaultEnd);
		system.assertEquals(41.25, calcs.getCommunityServiceHours());
		Test.stopTest();
	}

	static testMethod void testGetTotalTimeLost() {
		setupData();

		Test.startTest();
			setupAttendance();
			setupConsequences();
			Student__c newStudent = [select id,name,Total_Time_Lost__c,
										Sum_of_Time_Lost__c,Sectional_Attendance_Time_Lost__c,
										Attendance_Time_Lost__c,Setup__r.Use_Sectional_Attendance__c
									from Student__c
									where id = :defaultStudent.id limit 1];

			BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(newStudent, defaultStart, defaultEnd);
			system.assertEquals(attendanceTimeLost + consequenceTimeLost, calcs.getTotalTimeLost());
		Test.stopTest();
	}

	static testMethod void testCountDailyAttendance() {
		Map<String, Boolean> bMap = new Map<String, Boolean>();
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer days;
		days = calcs.countDailyAttendance('Present', null);
		system.assertEquals(6, days);
		bMap.clear();
		bMap.put('Is_Unexcused__c', false);
		days = calcs.countDailyAttendance('Absent', bMap);
		system.assertEquals(3, days);
		bMap.clear();
		bMap.put('Is_Unexcused__c', true);
		days = calcs.countDailyAttendance('Absent', bMap);
		system.assertEquals(2, days);
		days = calcs.countDailyAttendance(null, null);
		system.assertEquals(attendAdded, days);
		Test.stopTest();
	}

	static testMethod void testCountSectionalAttendance() {
		Map<String, Boolean> bMap = new Map<String, Boolean>();
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Integer days;
		bMap.clear();
		bMap.put('Is_Unexcused__c', false);
		days = calcs.countSectionalAttendance('Absent', bMap, defaultSection);
		system.assertEquals(3, days);
		days = calcs.countSectionalAttendance('Present', null, defaultSection);
		system.assertEquals(7, days);
		days = calcs.countSectionalAttendance(null, null, defaultSection);
		system.assertEquals(sectionAttendAdded, days);
		Test.stopTest();
	}

	static testMethod void testDailyAttendancePercentage() {
		setupData();
		setupAttendance();
		Test.startTest();
		Student__c newStudent = [select id,name,Total_Time_Lost__c,
									Sum_of_Time_Lost__c,Sectional_Attendance_Time_Lost__c,
									Attendance_Time_Lost__c,Setup__r.Use_Sectional_Attendance__c,
									Days_Enrolled__c
								from Student__c
								where id = :defaultStudent.id limit 1];
		newStudent.Days_Enrolled__c = attendAdded;
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(newStudent, defaultStart, defaultEnd);
		Double percent;
		percent = calcs.dailyAttendancePercentage();
		system.assertEquals(6/(Double)attendAdded*100, percent);
		Test.stopTest();
	}

	static testMethod void testSectionalAttendancePercentage() {
		setupData();
		setupAttendance();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Double percent;
		percent = calcs.sectionalAttendancePercentage(defaultSection);
		system.assertEquals(7/(Double)sectionAttendAdded*100, percent);
		Test.stopTest();
	}

	static testMethod void testGetFinalSectionGrades(){
		setupData();
		setupGrades();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Map<Id, Section_Grade__c> gradeMap = calcs.getFinalSectionGrades(defaultStudent.id);
		system.assertNotEquals(null, gradeMap);
		system.assertEquals(1, gradeMap.size());
		Test.stopTest();
	}


	static testMethod void testFinalSectionGrade() {
		setupData();
		setupGrades();
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(defaultStudent, defaultStart, defaultEnd);
		Double finalGrade = calcs.finalSectionGrade(defaultStudentSection.Section__c);
		system.assertEquals(1.55, finalGrade);
		Test.stopTest();
	}


	static testMethod void testCreditHoursEarned() {
		setupData();
		setupGrades();
		Student__c newStudent = [select id,name,Total_Time_Lost__c,
									Sum_of_Time_Lost__c,Sectional_Attendance_Time_Lost__c,
									Attendance_Time_Lost__c,Setup__r.Use_Sectional_Attendance__c,
									Days_Enrolled__c,Setup__r.Passing_Grade_Threshold__c
								from Student__c
								where id = :defaultStudent.id limit 1];
		newStudent.Setup__r.Passing_Grade_Threshold__c = 1;
		Test.startTest();
		BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(newStudent, defaultStart, defaultEnd);
		Double credits = calcs.creditHoursEarned();
		system.assertNotEquals(null, credits);
		//system.assert(credits > 0);
		Test.stopTest();
	}
}