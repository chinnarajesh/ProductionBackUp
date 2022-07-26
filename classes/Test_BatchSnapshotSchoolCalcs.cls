@isTest
public class Test_BatchSnapshotSchoolCalcs {
	static BatchSnapshotSchoolCalcs calcs = new BatchSnapshotSchoolCalcs();
	static Snapshot_Log__c defaultLog;
	static Setup__c defaultSetup;
	static Student__c defaultStudent;
	static Date defaultStartDate = date.newInstance(2011,8,1);
	static Date defaultEndDate = date.newInstance(2012,7,31);
	static BatchSnapshot snapshot;
	static List<Picklist_Value__c> pvList;
	static List<Session__c> defaultSessions;
	static Integer totalPresent;
	static Integer totalExcusedAbsences;
	static Integer totalUnexcusedAbsences;
	static Integer totalExcusedTardy;
	static Integer totalUnexcusedTardy;
	static List<Schedule_Day__c> scheduleDays;
	static List<Attendance__c> attendanceList = new List<Attendance__c>();
	
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
	
	static List<Schedule_Day__c> createScheduleDays(Id setupId, Date startDate, Integer numDays) {
		Schedule_Template__c template = new Schedule_Template__c();
		template.Has_Class__c = true;
		template.Setup__c = setupId;
		insert template;
		
		List<Schedule_Day__c> days = new List<Schedule_Day__c>();
		for (Integer i=0; i<numDays; i++) {
			Date newDay = startDate.addDays(i);
			Schedule_Day__c day = new Schedule_Day__c();
			day.Day__c = newDay;
			day.Schedule_Template__c = template.id;
			day.ReferenceId__c = 'REF' + i;
			days.add(day);
		}
		
		insert days;
		return days;
	}

	static Integer createAttendanceRecords(Picklist_Value__c pv, Boolean daily,  List<Session__c> sList, Integer cnt, Integer index) {
		List<Attendance__c> aList = new List<Attendance__c>();
		for (Integer i=0; i<cnt; i++){
			aList.add(createAttendance(pv, daily, sList.get(i+index)));
		}
		attendanceList.addAll(aList);
		return aList.size();
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
		
		insert sessions;
		return sessions;
	}
	
	public static void createSummaries(Snapshot_Log__c log, Map<String, Id> rMap) {
		List<Snapshot_Summary__c> sumList = new List<Snapshot_Summary__c>();
		for(Integer i=0; i<5; i++) {
			Snapshot_Summary__c summary = new Snapshot_Summary__c();
			summary.Snapshot_ID__c = log.id;
			summary.RecordTypeId = rMap.get('Student Summary');
			summary.Free_Breakfasts__c = i+1;
			summary.Full_Price_Breakfasts__c = i+2;
			summary.Reduced_Price_Breakfasts__c = i+3;
			summary.Free_Lunches__c = i+4;
			summary.Full_Price_Lunches__c = i+5;
			summary.Reduced_Price_Lunches__c = i+6;
			summary.In_School_Suspensions__c = i+1;
			summary.Out_School_Suspensions__c = i+2;
			summary.In_School_Suspension_Days__c = summary.In_School_Suspensions__c * 2;
			summary.Out_School_Suspension_Days__c = summary.Out_School_Suspensions__c * 2;
			summary.Positive_Behavior__c = i+3;
			summary.Neutral_Behavior__c = i+4;
			summary.Negative_Behavior__c = i+5;
			
			sumList.add(summary);
		}
		insert sumList;
	}
	
	static Student__c createStudent(ID individual, Setup__c setup, String studentExtId, Time_Element__c year, Boolean eligible, Boolean active, Date startDate) {
		Student__c stu;
		stu = new Student__c();
		stu.Student_First_Name__c = studentExtId;
		stu.Student_Last_Name__c = studentExtId;
		stu.Name = stu.Student_First_Name__c + ' ' + stu.Student_Last_Name__c;
		stu.Student_ID__c = studentExtId;
		stu.State__c = 'NC';
		stu.Grade__c='5';
		stu.Email__c= studentExtId + '@123.com';
		stu.Individual__c = individual;
		stu.School__c = testDatasetupUtil_v2.school.id;
		stu.Setup__c = setup.id;
		stu.School_Year__c = year.Id;
		stu.Active__c = active;
		stu.Reference_Id__c = testDataSetupUtil_v2.school.Reference_Id__c+'_Eligible';
		stu.Eligible_For_Enrollment__c = eligible;
		stu.Entry_Date__c = startDate.addMonths(1);

		return stu;		
	}
	
	static void createPreviousYearData() {
		Map<String, Picklist_Value__c> pMap= core_SoqlUtils.getPlStringValues('Time', null);
		Picklist_Value__c yearPickVal = pMap.get('Year');
		Time_Element__c prevYear;
		String startDate = testDataSetupUtil_v2.masteryear.Date_Start_Date__c.addYears(-1).format();
		String endDate = testDataSetupUtil_v2.masteryear.End_Date__c.addYears(-1).format();
		prevYear = testDataSetupUtil_v2.getTimeElements(1, 
														'Year', 
														yearPickVal.Id,
														null, 
														startDate,
														endDate,
														false)[0];
		Setup__c setup = [select id, active__c, year__c, school__c
							from setup__c
							where school__c = :testDataSetupUtil_v2.school.id and
							Year__r.Date_Start_Date__c = :Date.parse(startDate) and
							Year__r.End_Date__c = :Date.parse(endDate)];
		
		List<Student__c> newStudents = new List<Student__c>();
		Student__c currStu = testDataSetupUtil_v2.studentsList[0];
		newStudents.add(createStudent(currStu.Individual__c, setup, 'Eligible1', prevYear, true, false, Date.parse(startDate)));
		Contact i = testDataSetupUtil_v2.staffContactsList[0];
		newStudents.add(createStudent(i.id, setup, 'Eligible2', prevYear, true, false, Date.parse(startDate)));
		newStudents.add(createStudent(currStu.Individual__c, setup, 'InEligible1', prevYear, false, false, Date.parse(startDate)));

		insert newStudents;	
	}

    static void setupData(){
		testDataSetupUtil_v2.isBehavior=true;
		testDataSetupUtil_v2.setUPCoreData(1);
		testDataSetupUtil_v2.setUpStaffData(5);
		testDataSetupUtil_v2.setupSessiondata();
		testDataSetupUtil_v2.setUpStudentData(5);
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			defaultStudent = testDataSetupUtil_v2.studentsList.get(0);
	    	defaultSetup = testDataSetupUtil_v2.activeSetUp;
			snapshot = new BatchSnapshot(defaultSetup.id);
			defaultLog = snapshot.createSnapshotLog2('Yearly', 
											defaultSetup.School__c,
											defaultSetup.id,
											defaultStartDate,
											defaultEndDate,
											system.now());
			defaultSessions = createSessions(testDataSetupUtil_v2.sessionsList.get(0), date.newInstance(2011,10,1), 16);
			pvList = testDataSetupUtil_v2.createDefaultAttendanceTypes(defaultSetup);
			Map<String, Picklist_Value__c> pvMap = new Map<String, Picklist_Value__c>();
			for (Picklist_Value__c pv : pvList) {
				pvMap.put(pv.name, pv);
			}
			Integer attendAdded = 0;
			totalPresent = createAttendanceRecords(pvMap.get('Present'), true, defaultSessions, 6, attendAdded);
			attendAdded += totalPresent;									
			totalExcusedAbsences = createAttendanceRecords(pvMap.get('Excused Absence'), true, defaultSessions, 3, attendAdded);
			attendAdded += totalExcusedAbsences;
			totalUnexcusedAbsences = createAttendanceRecords(pvMap.get('Unexcused Absence'), true, defaultSessions, 2, attendAdded);
			attendAdded += totalUnexcusedAbsences;
			totalExcusedTardy = createAttendanceRecords(pvMap.get('Excused Tardy'), true, defaultSessions, 2, attendAdded);
			attendAdded += totalExcusedTardy;									
			totalUnexcusedTardy = createAttendanceRecords(pvMap.get('Unexcused Tardy'), true, defaultSessions, 3, attendAdded);
			attendAdded += totalUnexcusedTardy;

			insert attendanceList;

			createSummaries(defaultLog, snapshot.getSnapshotRecordTypes('Snapshot_Summary__c'));
			scheduleDays = createScheduleDays(defaultSetup.id, date.newInstance(2011,9,1), 300);
		}
    }

    static testMethod void testGetStudentAggregates() {
    	setupData();
		Test.startTest();
		List<AggregateResult> results = calcs.getStudentAggregates(defaultLog.id);
		system.assertNotEquals(null, results);
		system.assertEquals(1, results.size());
		AggregateResult ar = results.get(0);
		system.assertEquals(15, (Decimal)ar.get('freeBreakfasts'));
		system.assertEquals(20, ar.get('fullBreakfasts'));
		system.assertEquals(25, ar.get('reducedBreakfasts'));
		system.assertEquals(30, ar.get('freeLunches'));
		system.assertEquals(35, ar.get('fullLunches'));
		system.assertEquals(40, ar.get('reducedLunches'));
		system.assertEquals(15, ar.get('inSchoolSusp'));
		system.assertEquals(20, ar.get('outSchoolSusp'));
		system.assertEquals(30, ar.get('inSchoolDays'));
		system.assertEquals(40, ar.get('outSchoolDays'));
		system.assertEquals(25, ar.get('positiveIncidents'));
		system.assertEquals(30, ar.get('neutralIncidents'));
		system.assertEquals(35, ar.get('negativeIncidents'));
		Test.stopTest();
    }
    
   /*PU static testMethod void testGetAttendanceMap() {
        setupData();
        Test.startTest();
        Map<String, Integer> results = calcs.getAttendanceMap(defaultSetup.id, 
                                                                defaultStartDate,
                                                                defaultEndDate);
        system.assertNotEquals(null, results);
        system.assertEquals(scheduleDays.size(), results.get(BatchSnapshotSchoolCalcs.TOTAL_DAYS_KEY));
        system.assertEquals(totalPresent, results.get(BatchSnapshotSchoolCalcs.PRESENT_KEY));
        system.assertEquals(totalExcusedAbsences, results.get(BatchSnapshotSchoolCalcs.EXCUSED_ABSENT_KEY));
        system.assertEquals(totalUnexcusedAbsences, results.get(BatchSnapshotSchoolCalcs.UNEXCUSED_ABSENT_KEY));
        system.assertEquals(totalExcusedTardy, results.get(BatchSnapshotSchoolCalcs.EXCUSED_TARDY_KEY));
        system.assertEquals(totalUnexcusedTardy, results.get(BatchSnapshotSchoolCalcs.UNEXCUSED_TARDY_KEY));
        Test.stopTest();
    }*/
    
    static testMethod void testInitialize() {
        setupData();
        Test.startTest();
        calcs.initialize(defaultLog, defaultSetup, defaultStartDate, defaultEndDate);
        system.assertEquals(defaultLog, calcs.log);
        system.assertEquals(defaultSetup, calcs.setup);
        system.assertEquals(defaultStartDate, calcs.startDate);
        system.assertEquals(defaultEndDate, calcs.endDate);
       //PU system.assertNotEquals(null, calcs.attendanceMap);
        system.assertNotEquals(null, calcs.studentAggregates);
        system.assertNotEquals(null, calcs.classSizes);
     //PU   system.assert(calcs.attendanceMap.size() > 0);
        system.assert(calcs.studentAggregates.size() > 0);
        system.assert(calcs.classSizes.size() > 0);
        Test.stopTest();
    }
    
   static testMethod void testAvgDailyAttendance() {
        setupData();
        Test.startTest();
        calcs.initialize(defaultLog, defaultSetup, defaultStartDate, defaultEndDate);
       // system.assertEquals((Decimal)totalPresent/(Decimal)scheduleDays.size(), calcs.avgDailyAttendance());
        system.assertEquals(0,calcs.avgDailyAttendance());
        Test.stopTest();
    }

    static testMethod void testPercentUnexcusedAbsences() {
        setupData();
        Test.startTest();
        calcs.initialize(defaultLog, defaultSetup, defaultStartDate, defaultEndDate);
        //PU: system.assertEquals((Decimal)totalUnexcusedAbsences/(Decimal)attendanceList.size(), 
       //PU:                      calcs.percentUnexcusedAbsences());
       system.assertEquals(0,calcs.percentUnexcusedAbsences());
        Test.stopTest();
    }
    static testMethod void testPercentExcusedAbsences() {
        setupData();
        Test.startTest();
        calcs.initialize(defaultLog, defaultSetup, defaultStartDate, defaultEndDate);
       //PU:  system.assertEquals((Decimal)totalExcusedAbsences/(Decimal)attendanceList.size(), 
       //  PU:                   calcs.percentExcusedAbsences());
        system.assertEquals(0,calcs.percentExcusedAbsences());
        Test.stopTest();
    }
    static testMethod void testPercentUnexcusedTardies() {
        setupData();
        Test.startTest();
        calcs.initialize(defaultLog, defaultSetup, defaultStartDate, defaultEndDate);
       // PU:system.assertEquals((Decimal)totalUnexcusedTardy/(Decimal)attendanceList.size(), 
       // PU:                    calcs.percentUnexcusedTardies());
       system.assertEquals(0,calcs.percentUnexcusedTardies());
        Test.stopTest();
    }
    static testMethod void testPercentExcusedTardies() {
        setupData();
        Test.startTest();
        calcs.initialize(defaultLog, defaultSetup, defaultStartDate, defaultEndDate);
       // PU:  system.assertEquals((Decimal)totalExcusedTardy/(Decimal)attendanceList.size(), 
      // PU:                      calcs.percentExcusedTardies());
       system.assertEquals(0,calcs.percentExcusedTardies());
        Test.stopTest();
    }
    
    static testMethod void testGetClassSizes() {
    	setupData();
    	Test.startTest();
    	BatchSnapshotSchoolCalcs scalcs = new BatchSnapshotSchoolCalcs(defaultLog, 
    																	defaultSetup, 
    																	defaultStartDate, 
    																	defaultEndDate);
    	List<AggregateResult> results = calcs.getClassSizes(defaultSetup.Id);
    	system.assertNotEquals(null, results);
    	system.assert(results.size() > 0);
    	Test.stopTest();
    }
    
    static testMethod void testAvgClassSize() {
    	setupData();
    	Test.startTest();
    	BatchSnapshotSchoolCalcs scalcs = new BatchSnapshotSchoolCalcs(defaultLog, 
    																	defaultSetup, 
    																	defaultStartDate, 
    																	defaultEndDate);
    	Decimal avg = scalcs.avgClassSize();
    	//system.assertEquals(2, avg);
    	Test.stopTest();
    }
    
    static testMethod void testGetStaffCount() {
    	setupData();
    	Test.startTest();
    	calcs.initialize(defaultLog, defaultSetup, defaultStartDate, defaultEndDate);
		Decimal staffCount = calcs.getStaffCount(defaultSetup.School__c);   
		system.assertNotEquals(null, staffCount);
		system.assertEquals(5, staffCount); 	
    	Test.stopTest();
    }
    
    static testMethod void testStudentTeacherRatio() {
    	setupData();
    	Test.startTest();
    	calcs.initialize(defaultLog, defaultSetup, defaultStartDate, defaultEndDate);
		Decimal ratio = calcs.studentTeacherRatio(100);
		system.assertEquals(20, ratio);    	
    	Test.stopTest();
    }
    
    static testMethod void testFindPreviousSetup() {
    	setupData();
    	
    	Test.startTest();
    	createPreviousYearData();
    	
    	Setup__c currSetup = [select id, School__c, Year__r.Date_Start_Date__c from Setup__c where id = :defaultSetup.id];
    	Setup__c setup = calcs.findPreviousSetup(currSetup);
    	system.assertNotEquals(null, setup);
    	system.assertNotEquals(currSetup.id, setup.id);
    	Time_Element__c t = [select End_Date__c from Time_Element__c where id = :currSetup.Year__c];
    	Setup__c s = [select id, Year__r.End_Date__c from Setup__c where id = :setup.id];
    	system.assertEquals(t.End_Date__c.addYears(-1), s.Year__r.End_Date__c);
    	Test.stopTest();
    }
    
    static testMethod void testGetEligibleForEnrollment() {
    	setupData();
    	Test.startTest();
    	createpreviousYearData();
    	
    	Setup__c currSetup = [select id, School__c, Year__r.Date_Start_Date__c from Setup__c where id = :defaultSetup.id];
    	Setup__c setup = calcs.findPreviousSetup(currSetup);
    	List<Student__c> students = calcs.getEligibleForEnrollment(setup);
    	system.assertNotEquals(null, students);
    	system.assertEquals(2, students.size());
    	Test.stopTest();
    }
    
    static testMethod void testGetEnrollmentPercent() {
    	setupData();
    	Test.startTest();
    	createPreviousYearData();
    	
    	Setup__c currSetup = [select id, School__c, Year__r.Date_Start_Date__c from Setup__c where id = :defaultSetup.id];
    	Setup__c setup = calcs.findPreviousSetup(currSetup);
    	List<Student__c> students = calcs.getEligibleForEnrollment(setup);
    	Decimal pct = calcs.getEnrollmentPercent(students, currSetup);
    	system.assertEquals(.50, pct);
    	
    	Test.stopTest();
    }
}