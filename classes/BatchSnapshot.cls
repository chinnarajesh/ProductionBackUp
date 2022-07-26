global class BatchSnapshot implements Database.Batchable<sObject>, Database.stateful{
	public static final String SELECT_CLAUSE = 'SELECT id,name,Total_Time_Lost__c,Sum_of_Time_Lost__c,' +
						'Sectional_Attendance_Time_Lost__c,Attendance_Time_Lost__c,' +
						'Setup__r.Use_Sectional_Attendance__c,Days_Enrolled__c,Student_Behavior_Score__c,' +
						'Entry_Date__c, Exit_Date__c, Exit_Reason__c,School__c,Active__c, ' +
						'Service_Hours_YTD__c,Final_GPA_Value__c,Setup__r.Passing_Grade_Threshold__c, Individual__c ';

	public static final Set<String> legalSectionRT = new Set<String>{'Gradebook Group', 'Published', 'Unpublished', 'Schedule Group'};

	public static Boolean isFinal = false;

	public Snapshot_Log__c snapshotLog {get; private set;}

	public Map<String,Id> summaryRecordTypes {get; private set;}

	public Map<String,Id> childRecordTypes {get; private set;}

	public Setup__c currentSetup {get; private set;}

	private DataLoadLogList dataLogs;
	private Decimal studentCount=0;

	public DataLoadLogList getDataLogs() {
		return dataLogs;
	}

	global BatchSnapshot(){}

	global BatchSnapshot(String setupId){
		Setup__c s = [SELECT Year__r.Date_Start_Date__c,Year__r.End_Date__c,Processed_Historical_Data__c,School__c FROM Setup__c WHERE Id =:setupId];
		initialize(s);
	}

	global void initialize(Setup__c s){
		currentSetup = s;
		snapshotLog = createSnapshotLog2('Yearly',
			currentSetup.School__c,
			currentSetup.Id,
			currentSetup.Year__r.Date_Start_Date__c,
			currentSetup.Year__r.End_Date__c,
			system.now());
		summaryRecordTypes = getSnapshotRecordTypes('Snapshot_Summary__c');
		childRecordTypes = getSnapshotRecordTypes('Snapshot_Child__c');
		dataLogs = new DataLoadLogList('BatchSnapshot', currentSetup.id,
									new String[]{DataLoadLogList.STUDENT_SUMMARY, DataLoadLogList.SCHOOL_SUMMARY, 
												DataLoadLogList.STUDENT_SECTION_SUMMARY, DataLoadLogList.SCHOOL_SECTION_SUMMARY});
	}

	global Snapshot_Log__c createSnapshotLog(String a, Id b, Date c, Date d, Datetime e){return null;}

	global Snapshot_Log__c createSnapshotLog2(String snapshotType, ID schoolId, ID setupId, Date startDate, Date endDate, DateTime taken){
		Snapshot_Log__c log;
		log = new Snapshot_Log__c(Snapshot_Type__c = snapshotType,
			Setup__c = setupId,
			School__c = schoolId,
			Period_Start__c = startDate,
			Period_End__c = endDate,
			Snapshot_Taken__c = taken,
			is_Final__c = isFinal);
		insert log;
		return log;
	}

	global Database.Querylocator start(Database.BatchableContext BC){
		try{
			String query = SELECT_CLAUSE +
						'from Student__c where Setup__c = \'' +
						String.escapeSingleQuotes(currentSetup.Id) + '\'';
			dataLogs.setLogBatchId(BC.getJobId());
			dataLogs.startAll();
			return Database.getQueryLocator(query); //yes we can return stuff here and still have finally called
		} catch (Exception e){
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SUMMARY,'Failure starting snapshot batch');
			insert Error_Handling.handleError('','BatchSnapshot','Failure in start method',e);
			system.debug(e);
		} finally{
			dataLogs.saveLogs();
		}
		//force the return of an empty set
		return Database.getQueryLocator('select id from Student__c where ID = null');
	}

	global void execute(Database.BatchableContext BC, List<Student__c> scope){
		List<Snapshot_Summary__c> summariesToInsert = new List<Snapshot_Summary__c>();
		List<Snapshot_Child__c>   summaryChildrenToInsert = new List<Snapshot_Child__c>();
		List<SummaryChildRelation> relationList = new List<SummaryChildRelation>();
		Integer i = 0;
		for(Student__c student : scope){
			try {
				studentCount++;
				BatchSnapshotStudentCalcs calcs = new BatchSnapshotStudentCalcs(student, snapshotLog.Period_Start__c, snapshotLog.Period_End__c);
				Snapshot_Summary__c summary = calculateStudentSummary(calcs, student, snapshotLog);
				summariesToInsert.add(summary);
				List<Student_Section__c> studentSections = getStudentSections(student);
				List<Standard_Grade__c> standardGrades = getStandardGrades(student);
				List<Snapshot_Child__c> children = calculateStudentChildren(calcs,student,studentSections,standardGrades,summary);

				summaryChildrenToInsert.addAll(children);
				relationList.add(new SummaryChildRelation(summary, children));
				dataLogs.incrTotal(DataLoadLogList.STUDENT_SUMMARY);
				dataLogs.incrTotal(DataLoadLogList.STUDENT_SECTION_SUMMARY, children.size());
			} catch(Exception e) {
				dataLogs.incrFailed(DataLoadLogList.STUDENT_SUMMARY);
				dataLogs.addLogMessage(DataLoadLogList.STUDENT_SUMMARY,'An error occured while processing students for student snapshots.');
				Error_Handling.handleMultiPartException('','BatchSnapshot','Exception processing student '+student.id+' for child snapshots',e);
			}
		}

		Error_Handling.insertMultiPartException();

		try{
			insert summariesToInsert;
			for(SummaryChildRelation s : relationList){
				for(Snapshot_Child__c c : s.childList){
					c.Snapshot_Summary__c = s.summary.id;
				}
			}
			insert summaryChildrenToInsert;
		} catch (Exception e){
			dataLogs.incrFailed(DataLoadLogList.STUDENT_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.STUDENT_SUMMARY,'An error occured while inserting student snapshots.');
			insert Error_Handling.handleError('','BatchSnapshot','Failure inserting student snapshot summary',e);
		} finally{
			dataLogs.saveLogs();
		}
		
	}

	global void finish(Database.BatchableContext BC){
		Snapshot_Summary__c schoolSummary;
		try {
			schoolSummary = calculateSchoolSummary(snapshotLog, currentSetup);
			insert schoolSummary;
			dataLogs.incrTotal(DataLoadLogList.SCHOOL_SUMMARY);

			Batch_SchoolSnapshotSessionCalc sessionBatch = new Batch_SchoolSnapshotSessionCalc(schoolSummary, dataLogs, currentSetup.ID, snapshotLog.Period_Start__c, snapshotLog.Period_End__c);
			Database.executeBatch(sessionBatch);
		} catch (Exception e) {
			dataLogs.incrFailed(DataLoadLogList.SCHOOL_SUMMARY);
			dataLogs.addLogMessage(DataLoadLogList.SCHOOL_SUMMARY,'Failure when processing snapshot finish process.');
			insert Error_Handling.handleError('','BatchSnapshot','Failure in finish method',e);
		} finally {
			dataLogs.saveLogs();
		}
	}

	/* START CALCULATION METHODS */
	global List<Snapshot_Child__c> calculateStudentChildren(
		BatchSnapshotStudentCalcs calcs,Student__c student,List<Student_Section__c> stuSections,List<Standard_Grade__c> standardGrades,Snapshot_Summary__c summary){
		
		List<Snapshot_Child__c> children = new List<Snapshot_Child__c>();
		for (Student_Section__c studentSection : stuSections) {
			Snapshot_Child__c child = new Snapshot_Child__c();
			child.Snapshot_Summary__c = summary.Id;
			child.RecordTypeId = childRecordTypes.get('Section');
			child.Section__c = studentSection.Section__c;
			child.Attendance_Percent__c = calcs.sectionalAttendancePercentage(new Section__c(id = studentSection.Section__c));
			if(studentSection.Section__r.Is_Section__c) {
				child.Grade__c = calcs.finalGrade(studentSection.Section__r.Course__c);
			}
			children.add(child);
		}
		for (Standard_Grade__c standardGrade : standardGrades){
			Snapshot_Child__c child = new Snapshot_Child__c();
			child.Snapshot_Summary__c = summary.id;
			child.RecordTypeId = childRecordTypes.get('Standard');
			child.Standard__c = standardGrade.Standard__c;
			child.Grade__c = standardGrade.Standard_Grade__c;
			children.add(child);
		}

		return children;
	}

	global Snapshot_Summary__c calculateStudentSummary(BatchSnapshotStudentCalcs calcs, Student__c student, Snapshot_Log__c log){
		Snapshot_Summary__c summary = new Snapshot_Summary__c();
		summary.Snapshot_ID__c = log.Id;
		summary.RecordTypeId = summaryRecordTypes.get('Student Summary');
		summary.Student__c = student.Id;
		summary.Contact__c = student.Individual__c;
		summary.School__c = currentSetup.School__c;

		summary.Excused_Absences__c = calcs.dailyExcusedAbsences();
		summary.Unexcused_Absences__c = calcs.dailyUnexcusedAbsences();
		summary.Excused_Tardies__c = calcs.dailyExcusedTardies();
		summary.Unexcused_Tardies__c = calcs.dailyUnexcusedTardies();
		summary.In_School_Suspensions__c = calcs.countInSchoolSuspension();
		summary.Out_School_Suspensions__c = calcs.countOutSchoolSuspension();
		summary.In_School_Suspension_Days__c = calcs.daysInSchoolSuspension();
		summary.Out_School_Suspension_Days__c = calcs.daysOutSchoolSuspension();
		summary.Negative_Behavior__c = calcs.countNegativeBehavior();
		summary.Neutral_Behavior__c = calcs.countNeutralBehavior();
		summary.Positive_Behavior__c = calcs.countPositiveBehavior();
		summary.Behavior_Points__c = calcs.getBehaviorPoints();
		summary.Free_Breakfasts__c = calcs.countFreeBreakfasts();
		summary.Free_Lunches__c = calcs.countFreeLunches();
		summary.Full_Price_Breakfasts__c = calcs.countFullBreakfasts();
		summary.Full_Price_Lunches__c = calcs.countFullLunches();
		summary.Reduced_Price_Breakfasts__c = calcs.countReducedBreakfasts();
		summary.Reduced_Price_Lunches__c = calcs.countReducedLunches();
		summary.Community_Service_Hours__c = calcs.getCommunityServiceHours();
		summary.Instructional_Time_Lost__c = calcs.getTotalTimeLost();
		summary.Daily_Attendance__c = calcs.dailyAttendancePercentage();
		summary.Average_GPA__c = student.Final_GPA_Value__c;
		summary.Credit_Earned_YTD__c = calcs.creditHoursEarned();
		summary.Credit_Earned_Career__c = careerCreditHoursEarned(createBatchCalcs(student));
		return summary;
	}

	global Double careerCreditHoursEarned(List<BatchSnapshotStudentCalcs> calcList) {
		Double credits = 0;
		for (BatchSnapshotStudentCalcs c : calcList){
			Double cr = c.creditHoursEarned();
			credits += cr;
		}
		return credits;
	}

	global Map<String,Id> getSnapshotRecordTypes(String sType) {
		Map<String,Id> rmap = core_SoqlUtils.getRecordTypesBySobject(sType);
		Map<String,Id> newMap = new Map<String,Id>();
		for (String key : rmap.keySet()) {
			newMap.put(key.replace('_', ' '), rmap.get(key));
		}

		return newMap;
	}

	global List<Student_Section__c> getStudentSections(Student__c student){
		List<Student_Section__c> ss = [select Section__c,
										Section__r.Course__c,
										Section__r.Is_Section__c
										from Student_Section__c
										where Student__c = :student.id and
										Section__r.Course__r.Include_in_section_snapshot__c = true and
										//US3508
										Section__r.RecordType.Name IN: legalSectionRT and
										Active__c = true];
		return ss;
	}

	global List<Standard_Grade__c> getStandardGrades(Student__c student){
		List<Standard_Grade__c> sg = [select id,Student__c,Standard__c,Standard_Grade__c
										from Standard_Grade__c
										where Student__c = :student.id];
		return sg;
	}

	global List<BatchSnapshotStudentCalcs> createBatchCalcs(Student__c student){
		String query = SELECT_CLAUSE +
						'from Student__c ' +
						'where Individual__c=\'' + String.escapeSingleQuotes(student.Individual__c) +
						'\'';
		List<Student__c> relatedStudentRecs = Database.query(query);
		List<BatchSnapshotStudentCalcs> calcs = new List<BatchSnapshotStudentCalcs>();
		for (Student__c s : relatedStudentRecs){
			BatchSnapshotStudentCalcs c = new BatchSnapshotStudentCalcs();
			c.initializeFinalSectionGrades(s, snapshotLog.Period_Start__c, snapshotLog.Period_End__c);
			calcs.add(c);
		}
		return calcs;
	}

	global Snapshot_Summary__c calculateSchoolSummary(Snapshot_Log__c log,
														Setup__c setup){
		BatchSnapshotSchoolCalcs schoolCalcs = new BatchSnapshotSchoolCalcs(log, setup, log.Period_Start__c, log.Period_End__c);
		Snapshot_Summary__c summary = new Snapshot_Summary__c();
		summary.Snapshot_ID__c = log.Id;
		summary.RecordTypeId = summaryRecordTypes.get('School Summary');
		summary.School__c = setup.School__c;

		if (schoolCalcs.studentAggregates.size() > 0) {
			AggregateResult ar = schoolCalcs.studentAggregates.get(0);
			summary.In_School_Suspensions__c = (Decimal)ar.get('inSchoolSusp');
			summary.Out_School_Suspensions__c = (Decimal)ar.get('outSchoolSusp');
			summary.In_School_Suspension_Days__c = (Decimal)ar.get('inSchoolDays');
			summary.Out_School_Suspension_Days__c = (Decimal)ar.get('outSchoolDays');
			summary.Negative_Behavior__c = (Decimal)ar.get('negativeIncidents');
			summary.Neutral_Behavior__c = (Decimal)ar.get('neutralIncidents');
			summary.Positive_Behavior__c = (Decimal)ar.get('positiveIncidents');
			summary.Free_Breakfasts__c = (Decimal)ar.get('freeBreakfasts');
			summary.Free_Lunches__c = (Decimal)ar.get('freeLunches');
			summary.Full_Price_Breakfasts__c = (Decimal)ar.get('fullBreakfasts');
			summary.Full_Price_Lunches__c = (Decimal)ar.get('fullLunches');
			summary.Reduced_Price_Breakfasts__c = (Decimal)ar.get('reducedBreakfasts');
			summary.Reduced_Price_Lunches__c = (Decimal)ar.get('reducedLunches');
		}
		 /*PU: Hitting Query row limits,will be fixed later
		summary.Daily_Attendance__c = schoolCalcs.avgDailyAttendance();
		summary.Excused_Absences__c = schoolCalcs.percentExcusedAbsences();
		summary.Unexcused_Absences__c = schoolCalcs.percentUnexcusedAbsences();
		summary.Excused_Tardies__c = schoolCalcs.percentExcusedTardies();
		summary.Unexcused_Tardies__c = schoolCalcs.percentUnexcusedTardies();*/
		summary.Average_Class_Size__c = schoolCalcs.avgClassSize();
		summary.Student_Teacher_Ratio__c = schoolCalcs.studentTeacherRatio(studentCount);

		return summary;
	}

	global List<Snapshot_Child__c> calculateSectionSummaries(Snapshot_Log__c log, Snapshot_Summary__c summary, List<Section__c> sections, Setup__c someSetup) {
		BatchSnapshotSectionCalcs calcs = new BatchSnapshotSectionCalcs(someSetup, log.Period_Start__c, log.Period_End__c);
		List<Snapshot_Child__c> children = new List<Snapshot_Child__c>();

		for (Section__c section : sections) {
			Snapshot_Child__c child = new Snapshot_Child__c();
			child.Snapshot_Summary__c = summary.Id;
			child.RecordTypeId = childRecordTypes.get('Section');
			child.Section__c = section.Id;
			child.Average_GPA__c = calcs.avgGPA(section.Id);
			child.Attendance_Percent__c = calcs.percentPresent(section.Id);
			child.Percent_Excused_Absence__c = calcs.percentExcusedAbsences(section.Id);
			child.Percent_Excused_Tardies__c = calcs.percentExcusedTardies(section.Id);
			child.Percent_Unexcused_Absence__c = calcs.percentUnexcusedAbsences(section.Id);
			child.Percent_Unexcused_Tardies__c = calcs.percentUnexcusedTardies(section.Id);
			child.Assigned_Staff__c = calcs.getStaff(section.Id);
			children.add(child);
		}

		return children;
	}

	global List<Section__c> getSectionsForSchool(ID schoolId) {
		List<Section__c> sections =
			[select id from Section__c where School__c = :schoolId and RecordType.Name IN: legalSectionRT and Course__r.Include_in_section_snapshot__c = true];
		return sections;
	}

	public class SummaryChildRelation {
		public Snapshot_Summary__c summary{get; private set;}
		public List<Snapshot_Child__c> childList{get; private set;}

		public SummaryChildRelation(Snapshot_Summary__c s, List<Snapshot_Child__c> l){
			summary = s;
			childList = l;
		}
	}
}