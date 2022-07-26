global class BatchSnapshotSchoolCalcs {
	
	global Snapshot_Log__c log {
		get; private set;
	}
	
	global Setup__c setup {
		get; private set;
	}
	
	global Date startDate {
		get; private set;
	}
	
	global Date endDate {
		get; private set;
	}
	
	global List<AggregateResult> studentAggregates {
		get; private set;
	}
	
	global Map<String, Integer> attendanceMap {
		get; private set;
	}
	
	global List<AggregateResult> classSizes {
		get; private set;
	}
	
	global static final String TOTAL_DAYS_KEY = 'totalDays';
	global static final String PRESENT_KEY = 'present';
	global static final String UNEXCUSED_ABSENT_KEY = 'unexcusedAbsences';
	global static final String EXCUSED_ABSENT_KEY = 'excusedAbsences';
	global static final String UNEXCUSED_TARDY_KEY = 'unexcusedTardies';
	global static final String EXCUSED_TARDY_KEY = 'excusedTardies';
	global static final String TOTAL_ATTENDANCE = 'totalAttendance';
	
	//US3508
	public static final Set<String> legalSectionRT = new Set<String>{'Gradebook Group', 'Published', 'Unpublished', 'Schedule Group'};
	
	global BatchSnapshotSchoolCalcs(){
	}
	
	global BatchSnapshotSchoolCalcs(Snapshot_Log__c someLog,
									Setup__c someSetup, 
									Date someStartDate, 
									Date someEndDate) {
		initialize(someLog, someSetup, someStartDate, someEndDate);
	}
	
	global void initialize(Snapshot_Log__c someLog,
							Setup__c someSetup, 
							Date someStartDate, 
							Date someEndDate) {
		log = someLog;
		setup = someSetup;
		startDate = someStartDate;
		endDate = someEndDate;
		studentAggregates = getStudentAggregates(log.id);
		classSizes = getClassSizes(setup.Id);	
		 //PU: Hitting Query row limits,will be fixed later
        //attendanceMap = getAttendanceMap(setup.id, startDate, endDate);	
	}
	
	global List<AggregateResult> getClassSizes(Id setupId) {
		List<AggregateResult> results = [select 
											count(Id) studentCount, 
											Section__c section
										from Student_Section__c 
										where 
											Student__r.Setup__c = :setupId and 
											Section__r.Course__r.Include_in_section_snapshot__c = true and
											//US3508
											section__r.RecordType.Name IN: legalSectionRT and
											Active__c = true
										group by Section__c];
		return results;
	}
	
	global List<AggregateResult> getStudentAggregates(ID logId) {
		List<AggregateResult> results = [SELECT 
											SUM(Free_Breakfasts__c) freeBreakfasts,
											SUM(Full_Price_Breakfasts__c) fullBreakfasts,
											SUM(Reduced_Price_Breakfasts__c) reducedBreakfasts,
											SUM(Free_Lunches__c) freeLunches,
											SUM(Full_Price_Lunches__c) fullLunches,
											SUM(Reduced_Price_Lunches__c) reducedLunches,
											SUM(In_School_Suspensions__c) inSchoolSusp,
											SUM(Out_School_Suspensions__c) outSchoolSusp,
											SUM(In_School_Suspension_Days__c) inSchoolDays,
											SUM(Out_School_Suspension_Days__c) outSchoolDays,
											SUM(Positive_Behavior__c) positiveIncidents,
											SUM(Neutral_Behavior__c) neutralIncidents,
											SUM(Negative_Behavior__c) negativeIncidents
										FROM Snapshot_Summary__c
										WHERE Snapshot_ID__c = :logId];
	    return results;
	}
	
	global Map<String, Integer> getAttendanceMap(ID setupId, 
														Date someStartDate,
														Date someEndDate) {
		/*PU Code hitting no. of query rows limits 
		Integer totalAttendance = 0;
		Map<String, Integer> results = new Map<String, Integer>();
		List<AggregateResult> dayCount = [select count(id) days
											from Schedule_Day__c 
											where Schedule_Template__r.Has_Class__c = true and 
												Schedule_Template__r.Setup__c = :setupId and 
												Day__c >= :someStartDate and
												Day__c <= :someEndDate];
		if (dayCount.size() > 0) {
			results.put(TOTAL_DAYS_KEY, (Integer)dayCount.get(0).get('days'));
		}												

		List<AggregateResult> attend = [select Picklist_Value__r.Category__c cat, 
												Picklist_Value__r.Is_Unexcused__c unexcused, 
												Picklist_Value__r.Is_Tardy__c tardy, 
												count(id) cnt 
										from Attendance__c
										where Student__r.Setup__c = :setupId and
												Session_Date__c >= :someStartDate and
												Session_Date__c <= :someEndDate and
												Daily__c = true and 
												isDeleted = false
										group by Picklist_Value__r.Category__c, 
												Picklist_Value__r.Is_Unexcused__c, 
												Picklist_Value__r.Is_Tardy__c];

		for (AggregateResult ar : attend) {
			Integer cnt = (Integer)ar.get('cnt');
			String cat = (String) ar.get('cat');
			Boolean unexcused = (Boolean) ar.get('unexcused');
			Boolean tardy = (Boolean) ar.get('tardy');
			totalAttendance += cnt;
			if (cat == 'Present') {
				results.put(PRESENT_KEY, cnt);
			} else if (cat == 'Absent') {
				if (unexcused == true) {
					results.put(UNEXCUSED_ABSENT_KEY, cnt);
				}
				else {
					results.put(EXCUSED_ABSENT_KEY,  cnt);
				}
			} else if (cat == 'Partial') {
				if (tardy == true) {
					if (unexcused == true) {
						results.put(UNEXCUSED_TARDY_KEY, cnt);
					}
					else {
						results.put(EXCUSED_TARDY_KEY, cnt);
					}
				}				
			}
		}
		results.put(TOTAL_ATTENDANCE, totalAttendance);
		return results;			*/
		return null;									
	}
	
	global Decimal zeroIfNull(Decimal num) {
		if (num == null) {
			return 0;
		}
		else {
			return num;
		}
	}
	
	
	global Decimal getStaffCount(Id schoolId) {
		List<AggregateResult> results = [select count(id) staffCount
										from Staff__c
										where Organization__c = :schoolId and
										Active__c = true and
										Instructional_Staff__c = true];
		if (results != null && results.size() > 0) {
			return zeroIfNull((Decimal)results.get(0).get('staffCount'));
		}
		else {
			return 0;
		}
	}
	
	global Decimal avgDailyAttendance() {
		/*PU Code hitting no. of query rows limits
		Decimal present = zeroIfNull(attendanceMap.get(PRESENT_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_DAYS_KEY));
		if (total > 0) {
			return present/total;
		}
		else {
			return 0;
		}*/
		return 0;
		
	}
	
	global Decimal percentUnexcusedAbsences() {
		/*PU Code hitting no. of query rows limits
		Decimal unexcused = zeroIfNull(attendanceMap.get(UNEXCUSED_ABSENT_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_ATTENDANCE));
		if (total > 0) {
			return unexcused/total;
		}
		else {
			return 0;
		}*/
		return 0;
	}

	global Decimal percentExcusedAbsences() {
		/*PU Code hitting no. of query rows limits
		Decimal excused = zeroIfNull(attendanceMap.get(EXCUSED_ABSENT_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_ATTENDANCE));
		if (total > 0) {
			return excused/total;
		}
		else {
			return 0;
		}*/
		return 0;
	}

	global Decimal percentUnexcusedTardies() {
		/*PU Code hitting no. of query rows limits
		Decimal unexcused = zeroIfNull(attendanceMap.get(UNEXCUSED_TARDY_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_ATTENDANCE));
		if (total > 0) {
			return unexcused/total;
		}
		else {
			return 0;
		}*/
		return 0;
	}

	global Decimal percentExcusedTardies() {
		/*PU Code hitting no. of query rows limits
		Decimal excused = zeroIfNull(attendanceMap.get(EXCUSED_TARDY_KEY));
		Decimal total = zeroIfNull(attendanceMap.get(TOTAL_ATTENDANCE));
		if (total > 0) {
			return excused/total;
		}
		else {
			return 0;
		}*/
		return 0;
	}
	
	global Decimal avgClassSize() {
		Decimal students = 0;
		
		for (AggregateResult ar : classSizes) {
			students += zeroIfNull((Decimal)ar.get('studentCount'));
		}
		
		if (classSizes != null && classSizes.size() > 0) {
			return students/classSizes.size();
		}
		else {
			return 0;
		} 
	}
	
	global Decimal studentTeacherRatio(Decimal studentCount) {
		Decimal staffCount = getStaffCount(setup.School__c);
		if (staffCount == 0) {
			return 0;
		}
		else {
			return studentCount/staffCount;
		}
	}
	
	global Setup__c findPreviousSetup(Setup__c currentSetup) {
		Setup__c prevSetup = [select Id 
								from Setup__c 
								where School__c = :currentSetup.School__c and
								Year__r.End_Date__c <> null and 
								Year__r.End_Date__c < :currentSetup.Year__r.Date_Start_Date__c 
								order by Year__r.End_Date__c desc limit 1];
		return prevSetup;
	}
	
	global List<Student__c> getEligibleForEnrollment(Setup__c setup) {
		List<Student__c> students = [select Individual__c
									from Student__c
									where Eligible_For_Enrollment__c = true and
									Setup__c = :setup.id];
		return students;
	}
	
	global Decimal getEnrollmentPercent(List<Student__c> students, Setup__c currSetup) {
		Decimal enrollment = 0;

		if (students != null && students.size() > 0) {
			List<ID> ids = new List<ID>();
			for (Student__c s : students) {
				ids.add(s.Individual__c);
			} 
			
			AggregateResult ar = [select count(id) c
									from Student__c 
									where Setup__c = :currSetup.id and
									Active__c = true and
									Individual__c in :ids];
			Decimal reenrollCount = (Decimal)ar.get('c');
			enrollment = reenrollCount/students.size();
		}
		
		return enrollment;
	}

}