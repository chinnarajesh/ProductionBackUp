@isTest
public class Test_BatchSnapshotSectionCalcs {
	static BatchSnapshotSectionCalcs calcs = new BatchSnapshotSectionCalcs();
	static Setup__c defaultSetup;
	static Student__c defaultStudent;
	static Date defaultStartDate = date.newInstance(2011,8,1);
	static Date defaultEndDate = date.newInstance(2012,7,31);
	static List<Picklist_Value__c> pvList;
	static List<Session__c> defaultSessions;
	static Integer totalPresent;
	static Integer totalExcusedAbsences;
	static Integer totalUnexcusedAbsences;
	static Integer totalExcusedTardy;
	static Integer totalUnexcusedTardy;
	static List<Schedule_Day__c> scheduleDays;
	static List<Attendance__c> attendanceList = new List<Attendance__c>();
	static List<Section_Grade__c> sectionGrades;
	
	static void setupGrades(){
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]) {
			sectionGrades = new List<Section_Grade__c>();
			Course__c course = testDataSetupUtil_v2.coursesList.get(0);
			List<Course_Weightings__c> cw = [select id from Course_Weightings__c where Course__c = :course.id];
			Decimal d = 2.0;
			
			for (Student_Section__c ss : testDataSetupUtil_v2.studSectionsList) {
				Section_Grade__c sectionGrade = new Section_Grade__C();
				sectionGrade.Student_Section__c = ss.id;
				sectionGrade.Grade__c = d;
				sectionGrade.isFinal__c = true;
				sectionGrade.Course_Weighting__c = cw.get(0).id;
				sectionGrade.Time__c = defaultSetup.Year__c;
				d = d + .1;
				sectionGrades.add(sectionGrade);
			}
			
			insert sectionGrades;
		}
	}
	
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
	
	static List<Session__c> createSessions(Session__c origSession, Date baseDate, List<Section__c> sectionList, Integer cnt){
		List<Session__c> sessions = new List<Session__c>();
		Session__c newSession;
		Datetime startDate = datetime.newInstance(baseDate, time.newInstance(08, 30, 2, 0));
		Datetime endDate = datetime.newInstance(baseDate, time.newInstance(17, 30, 2, 0));
		Integer sectionIndex=0;
		for (Integer i=0; i<cnt; i++){
			newSession = origSession.clone(false, true);
			newSession.Start_DateTime__c = startDate.addDays(i);
			newSession.End_DateTime__c = endDate.addDays(i);
			if (sectionIndex > sectionList.size() - 1) {
				sectionIndex = 0;
			}
			newSession.Section__c = sectionList.get(sectionIndex).id;
			sessions.add(newSession);
			sectionIndex++;
		}
		
		insert sessions;
		return sessions;
	}
	
    static void setupData(){
		testDataSetupUtil_v2.isBehavior=true;
		testDataSetupUtil_v2.setUPCoreData(4);
		testDataSetupUtil_v2.setUpStaffData(5);
		testDataSetupUtil_v2.setupSessiondata();
		testDataSetupUtil_v2.setUpStudentData(5);

		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			defaultStudent = testDataSetupUtil_v2.studentsList.get(0);
	    	defaultSetup = testDataSetupUtil_v2.activeSetUp;
			defaultSessions = createSessions(testDataSetupUtil_v2.sessionsList.get(0), date.newInstance(2011,10,1), testDataSetupUtil_v2.sectionsList, 16);
			pvList = testDataSetupUtil_v2.createDefaultAttendanceTypes(defaultSetup);
			Map<String, Picklist_Value__c> pvMap = new Map<String, Picklist_Value__c>();
			for (Picklist_Value__c pv : pvList) {
				pvMap.put(pv.name, pv);
			}
			Integer attendAdded = 0;
			totalPresent = createAttendanceRecords(pvMap.get('Present'), false, defaultSessions, 6, attendAdded);
			attendAdded += totalPresent;									
			totalExcusedAbsences = createAttendanceRecords(pvMap.get('Excused Absence'), false, defaultSessions, 3, attendAdded);
			attendAdded += totalExcusedAbsences;
			totalUnexcusedAbsences = createAttendanceRecords(pvMap.get('Unexcused Absence'), false, defaultSessions, 2, attendAdded);
			attendAdded += totalUnexcusedAbsences;
			totalExcusedTardy = createAttendanceRecords(pvMap.get('Excused Tardy'), false, defaultSessions, 2, attendAdded);
			attendAdded += totalExcusedTardy;									
			totalUnexcusedTardy = createAttendanceRecords(pvMap.get('Unexcused Tardy'), false, defaultSessions, 3, attendAdded);
			attendAdded += totalUnexcusedTardy;

			insert attendanceList;

			scheduleDays = createScheduleDays(defaultSetup.id, date.newInstance(2011,9,1), 300);
			
			Staff_Section__c ss = new Staff_Section__c();
			ss.Section__c = testDataSetupUtil_v2.sectionsList.get(0).id;
			ss.Staff__c = testDataSetupUtil_v2.teachersList.get(1).id;
			insert ss;
		}
    }
    
    static Decimal countSessions(Id sectionId) {
    	Integer c = 0;
    	for (Session__c s : defaultSessions) {
    		if (s.Section__c == sectionId) {
    			c++;
    		}
    	}
    	
    	return (Decimal)c;
    }
    
    static testMethod void testCalcAttendanceMap() {
    	setupData();
    	Test.startTest();
    	system.debug(LoggingLevel.INFO, '+++defaultSessions: ' + defaultSessions);
    	Section__c section = testDataSetupUtil_v2.sectionsList.get(0);
    	Map<ID, List<AggregateResult>> dcmap = calcs.getSplitDayCount(defaultSetup.School__c,
    																	defaultStartDate,
    																	defaultEndDate);
    	system.debug(LoggingLevel.INFO, '+++dcmap: ' + dcmap);
    	Map<ID, List<AggregateResult>> atmap = calcs.getSplitAttendance(defaultSetup.id,
    																	defaultStartDate,
    																	defaultEndDate);
    	system.debug(LoggingLevel.INFO, '+++atmap: ' + atmap);
    	Map<String, Integer> results = calcs.calcAttendanceMap(dcmap.get(section.id), atmap.get(section.id));
		system.assertNotEquals(null, results);
		system.assertEquals(4, results.get(BatchSnapshotSectionCalcs.TOTAL_DAYS_KEY));
		system.assertEquals(2, results.get(BatchSnapshotSectionCalcs.PRESENT_KEY));
		system.assertEquals(1, results.get(BatchSnapshotSectionCalcs.EXCUSED_ABSENT_KEY));
		system.assertEquals(null, results.get(BatchSnapshotSectionCalcs.UNEXCUSED_ABSENT_KEY));
		system.assertEquals(1, results.get(BatchSnapshotSectionCalcs.EXCUSED_TARDY_KEY));
		system.assertEquals(null, results.get(BatchSnapshotSectionCalcs.UNEXCUSED_TARDY_KEY));
    	Test.stopTest();
    }

    static testMethod void testGetAttendanceMap() {
    	setupData();
    	Test.startTest();
    	Id sectionId = testDataSetupUtil_v2.sectionsList.get(0).id;
    	Map<ID, Map<String, Integer>> results = calcs.getAttendanceMap(defaultSetup,
    																	defaultStartDate,
    																	defaultEndDate);
		system.assertNotEquals(null, results);
    	Test.stopTest();
    }

    static testMethod void testAvgAttendance() {
    	setupData();
    	Id sectionId = testDataSetupUtil_v2.sectionsList.get(0).id;
    	Test.startTest();
    	calcs.initialize(defaultSetup, defaultStartDate, defaultEndDate);
    	system.assertEquals(2/countSessions(sectionId), calcs.avgAttendance(sectionId));
    	Test.stopTest();
    }

    static testMethod void testPercentUnexcusedAbsences() {
    	setupData();
    	Id sectionId = testDataSetupUtil_v2.sectionsList.get(0).id;
    	Test.startTest();
    	calcs.initialize(defaultSetup, defaultStartDate, defaultEndDate);
    	system.assertEquals(0, calcs.percentUnexcusedAbsences(sectionId));
    	Test.stopTest();
    }
    static testMethod void testPercentExcusedAbsences() {
    	setupData();
    	Id sectionId = testDataSetupUtil_v2.sectionsList.get(0).id;
    	Test.startTest();
    	calcs.initialize(defaultSetup, defaultStartDate, defaultEndDate);
    	system.assertEquals(1/countSessions(sectionId)*100, 
    						calcs.percentExcusedAbsences(sectionId));
    	Test.stopTest();
    }
    static testMethod void testPercentUnexcusedTardies() {
    	setupData();
    	Id sectionId = testDataSetupUtil_v2.sectionsList.get(0).id;
    	Test.startTest();
    	calcs.initialize(defaultSetup, defaultStartDate, defaultEndDate);
    	system.assertEquals(0, calcs.percentUnexcusedTardies(sectionId));
    	Test.stopTest();
    }
    static testMethod void testPercentExcusedTardies() {
    	setupData();
    	Id sectionId = testDataSetupUtil_v2.sectionsList.get(0).id;
    	Test.startTest();
    	calcs.initialize(defaultSetup, defaultStartDate, defaultEndDate);
    	system.assertEquals(1/countSessions(sectionId)*100, 
    						calcs.percentExcusedTardies(sectionId));
    	Test.stopTest();
    }
    
    static testMethod void testPercentPresent() {
    	setupData();
    	Id sectionId = testDataSetupUtil_v2.sectionsList.get(0).id;
    	Test.startTest();
    	calcs.initialize(defaultSetup, defaultStartDate, defaultEndDate);
    	system.assertEquals(2/countSessions(sectionId)*100, 
    						calcs.percentPresent(sectionId));
    	Test.stopTest();
    }
    
    static testMethod void testGetGPAMap() {
    	setupData();
    	Test.startTest();
    	setupGrades();
    	
    	Map<ID, Decimal> gmap = calcs.getGPAMap(defaultSetup.id, defaultStartDate, defaultEndDate);
    	system.assertNotEquals(null, gmap);
    	system.assert(gmap.size() > 0);
    	Test.stopTest();
    }

    static testMethod void testAvgGPA() {
    	setupData();
    	Test.startTest();
 		setupGrades();
    	
    	calcs.initialize(defaultSetup, defaultStartDate, defaultEndDate);
    	Decimal gpa = calcs.avgGPA(testDataSetupUtil_v2.sectionsList.get(0).id);
    	system.assertNotEquals(null, gpa);
    	
    	Decimal totalGPA = 0;
    	for (Section_Grade__c sg : sectionGrades) {
    		if (sg.Section_Weighted_GPA__c != null) {
    			totalGPA = totalGPA + sg.Section_Weighted_GPA__C;
    		}
    	}
    	system.assertEquals(totalGPA/sectionGrades.size(), gpa);
    	Test.stopTest();
    }
    
	static testMethod void testGetAssignedStaff() {
		setupData();
		Test.startTest();
		Map<ID, List<Staff_Section__c>> smap = calcs.getAssignedStaff(defaultSetup.School__c);
		system.assertNotEquals(null, smap);
		system.assertEquals(testDataSetupUtil_v2.sectionsList.size(), smap.size());
		Test.stopTest();
	}    
	
	static testMethod void testGetStaff() {
    	setupData();
    	Test.startTest();
 		setupGrades();
    	
    	calcs.initialize(defaultSetup, defaultStartDate, defaultEndDate);
		String staff = calcs.getStaff(testDataSetupUtil_v2.sectionsList.get(0).id);
		system.assertNotEquals(null, staff);
		system.assertEquals('Staff StafflastName0, Staff StafflastName1', staff);
		system.debug(LoggingLevel.INFO, '+++staff: ' + staff);
		Test.stopTest();		
	}
}