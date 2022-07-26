global class BatchSnapshotStudentCalcs {
	private Map<String, ID> rtMapBehavior = core_SoqlUtils.getRecordTypesBySobject('Behavior_Incident__c');
	
	global Student__c student{
		get; private set;
	}
	
	global Date startDate{
		get; private set;
	}
	
	global Date endDate{
		get; private set;
	}
	
	global List<Attendance__c> attendanceRecords{
		get; private set;
	}
	
	global List<Consequence__c> consequenceRecords{
		get; private set;
	}
	
	global List<Student_Behavior__c> studentBehaviorRecords{
		get; private set;
	}
	
	global List<Meal_Transaction__c> mealRecords{
		get; private set;
	}
	
	global Map<Id, Section_Grade__c> finalSectionGrades{
		get; private set;
	}
	
	public Map<ID, Final_Grade__c> finalGrades {get; private set;}
	
	global BatchSnapshotStudentCalcs() {
		
	}
	
	global BatchSnapshotStudentCalcs(Student__c someStudent, Date startDt, Date endDt){
		initialize(someStudent, startDt, endDt);
	}
	
	global void initialize(Student__c someStudent, Date startDt, Date endDt){
		student = someStudent;
		startDate = startDt;
		endDate = endDt;
		attendanceRecords = getAttendanceRecords(student.id, startDate, endDate);
		consequenceRecords = getConsequenceRecords(student.id, startDate, endDate);
		studentBehaviorRecords = getStudentBehaviorRecords(student.id, startDate, endDate);
		mealRecords = getMealRecords(student.Id, startDate, endDate);
		finalSectionGrades = getFinalSectionGrades(student.Id);
		finalGrades = getFinalGrades(student.ID);
	}
	
	global void initializeFinalSectionGrades(Student__c someStudent, Date startDt, Date endDt) {
		student = someStudent;
		startDate = startDt;
		endDate = endDt;
		finalSectionGrades = getFinalSectionGrades(student.Id);
		finalGrades = getFinalGrades(student.ID);
	}
	
	global List<Attendance__c> getAttendanceRecords(Id studentId, Date someStartDate, Date someEndDate){
		List<Attendance__c> aList;
		aList = [select id, Daily__c, Time_Lost_Rollup__c, Session__r.Section__c, 
				Picklist_Value__r.Category__c, Picklist_Value__r.name,
				Picklist_Value__r.Is_Early_Departure__c, Picklist_Value__r.Is_Tardy__c,
				Picklist_Value__r.Is_Unexcused__c 
				from Attendance__c
				where Student__c = :studentId and
				Session_Date__c >= :someStartDate and
				Session_Date__c <= :someEndDate];
		return aList;	
	}
	
	global List<Consequence__c> getConsequenceRecords(Id studentId, Date someStartDate, Date someEndDate){
		List<Consequence__c> cList;
		cList = [select id, Picklist_Value__c, Picklist_Value__r.name, Picklist_Value__r.Category__c, Days_Suspended__c 
				from Consequence__c
				where Student_Consequence__c = :studentId and
				Incident_Date_Formula__c >= :someStartDate and
				Incident_Date_Formula__c <= :someEndDate];
		return cList;	
	}
	
	global List<Student_Behavior__c> getStudentBehaviorRecords(Id studentId, Date someStartDate, Date someEndDate){
		List<Student_Behavior__c> sbList;
		sbList = [select id, Behavior_Incident__r.RecordTypeId,Consequence_Time_Lost__c
				from Student_Behavior__c
				where Student__c = :studentId and
				Behavior_Incident__r.Incident_Date__c >= :someStartDate and
				Behavior_Incident__r.Incident_Date__c <= :someEndDate];
		return sbList;	
	}
	
	global List<Meal_Transaction__c> getMealRecords(Id studentId, Date someStartDate, Date someEndDate) {
		List<Meal_Transaction__c> mealList;
		mealList = [select id,Cost_Type__c,Meal_Type__c,Transaction_Type__c
					from Meal_Transaction__c
					where Student__c = :studentId and
					Transaction_Date__c >= :someStartDate and
					Transaction_Date__c <= :someEndDate and
					(Void__c = null or Void__c = false) and
					Transaction_Type__c = 'Sale'];
		return mealList;
	}
	
	global Map<Id,Section_Grade__c> getFinalSectionGrades(Id studentId) {
		//US1284 quarters
		List<Section_Grade__c> grades = [select id, Student_Section__r.Section__c, Student_Section__r.Student__c, 
										Weighted_Final_Grade__c, Course_Weighting__r.Course__r.Credit_Hours__c, 
										Grade__c, Course_Weighting__r.Weighting__c
										from Section_Grade__c
										where Student_Section__r.Student__c = :studentId and
										isFinal__c = true AND (RecordTypeID = null OR RecordType.Name = 'Quarter')];
		Map<Id, Section_Grade__c> gradeMap = new Map<Id, Section_Grade__c>();
		for (Section_Grade__c sg : grades) {
			gradeMap.put(sg.Student_Section__r.Section__c, sg);
		}
		
		return gradeMap;
	}
	
	public Map<ID, Final_Grade__c> getFinalGrades(ID studentID) {
		Map<ID, Final_Grade__c> gradeMap = new Map<ID, Final_Grade__c>();
		for(Final_Grade__c fg : [SELECT ID, Course__c, Credits_Earned__c, Final_Grade_Value__c, Student__c FROM Final_Grade__c WHERE Student__c =: studentID]) {
			gradeMap.put(fg.Course__c, fg);
		}
		return gradeMap;
	}
	
	global Boolean matchFlags(Picklist_Value__c pv,
								Map<String, Boolean> boolMap) {
		if (boolMap == null) {
			return true;
		}
		
		String pkgName = null;
		if (Schema.SObjectType.Assesment__c.getName().startsWith('SchoolForce__')) {
			pkgName = 'SchoolForce__';
		}
		
		for (String key : boolMap.keySet()) {
			String flag;
			if (pkgName != null) {
				flag = pkgName + key;
			}
			else {
				flag = key;
			}
			Boolean pvFlag = (Boolean)pv.get(flag);
			Boolean passedFlag = boolMap.get(key);
			
			if (pvFlag != passedFlag) {
				return false;
			}			
		}
		
		return true;
	}
	
	global Integer countDailyAttendance(String attendanceType,
										Map<String, Boolean> boolMap) {
		Integer aCount = 0;
		for(Attendance__c a : attendanceRecords){
			if (a.Daily__c) {
				if (attendanceType==null) {
					aCount++;
				}
				else {
					if (a.Picklist_Value__r.Category__c == attendanceType &&
						matchFlags(a.Picklist_Value__r, boolMap)) {
						aCount++;
					}
				}
			}
		}
		return aCount;
	}
	
	global Integer countSectionalAttendance(String attendanceType, 
											Map<String, Boolean> boolMap,
											Section__c section) {
		Integer aCount = 0;
		for(Attendance__c a : attendanceRecords){
			if (!a.Daily__c && (section == null ||
								a.Session__r.Section__c == section.id)) {
				if (attendanceType==null) {
					aCount++;
				}
				else {
					if (a.Picklist_Value__r.Category__c == attendanceType &&
						matchFlags(a.Picklist_Value__r, boolMap)) {
						aCount++;
					}
				}
			}
		}
		return aCount;
	}
	
	global Integer getStudentBehaviorCount(String behaviorType) {
		Integer bCount = 0;
		Id bId = rtMapBehavior.get(behaviorType);
		for (Student_Behavior__c sb : studentBehaviorRecords) {
			if (sb.Behavior_Incident__r.RecordTypeId == bId) {
				bCount++;
			}
		}
		
		return bCount;
	}
	
	global Integer getConsequenceCount(String consequenceCategory) {
		Integer cCount = 0;
		for(Consequence__c c : consequenceRecords){
			if (c.Picklist_Value__r.Category__c == consequenceCategory) {
				cCount++;
			}
		}
		return cCount;
	}
	
	global Decimal getConsequenceDays(String consequenceCategory) {
		Decimal dayCount = 0;
		for(Consequence__c c : consequenceRecords){
			if (c.Picklist_Value__r.Category__c == consequenceCategory) {
				dayCount += c.Days_Suspended__c;
			}
		}
		return dayCount;
	}
	
	global Integer getMealCount(String mealType, String costType) {
		Integer mealCount = 0;
		for (Meal_Transaction__c meal: mealRecords){
			if (meal.Meal_Type__c == mealType && 
				meal.Cost_Type__c == costType){
				mealCount++;
			}
		}
		return mealCount;
	}
	
	global Integer dailyExcusedAbsences(){
		Map<String, Boolean> bMap = new Map<String, Boolean>();
		bMap.put('Is_Unexcused__c', false);
		return countDailyAttendance('Absent', bMap);
	}
	
	global Integer dailyUnexcusedAbsences(){
		Map<String, Boolean> bMap = new Map<String, Boolean>();
		bMap.put('Is_Unexcused__c', true);
		return countDailyAttendance('Absent', bMap);
	}
	
	global Integer dailyExcusedTardies(){
		Map<String, Boolean> bMap = new Map<String, Boolean>();
		bMap.put('Is_Unexcused__c', false);
		bMap.put('Is_Tardy__c', true);
		return countDailyAttendance('Partial', bMap);
	}

	global Integer dailyUnexcusedTardies(){
		Map<String, Boolean> bMap = new Map<String, Boolean>();
		bMap.put('Is_Unexcused__c', true);
		bMap.put('Is_Tardy__c', true);
		return countDailyAttendance('Partial', bMap);
	}
	
	global Integer countInSchoolSuspension(){
		return getConsequenceCount('In School Suspension');
	}
	
	global Integer countOutSchoolSuspension(){
		return getConsequenceCount('Out of School Suspension');
	}
	
	global Decimal daysInSchoolSuspension(){
		return getConsequenceDays('In School Suspension');
	}
	
	global Decimal daysOutSchoolSuspension(){
		return getConsequenceDays('Out of School Suspension');
	}
	
	global Integer countNegativeBehavior(){
		return getStudentBehaviorCount('Negative');
	}
	
	global Integer countNeutralBehavior(){
		return getStudentBehaviorCount('Neutral');
	}
	
	global Integer countPositiveBehavior(){
		return getStudentBehaviorCount('Positive');
	}
	
	global Double getBehaviorPoints(){
		return student.Student_Behavior_Score__c;
	}
	
	global Integer countFreeBreakfasts(){
		return getMealCount('Breakfast','Free');
	}
	
	global Integer countFreeLunches(){
		return getMealCount('Lunch','Free');
	}
	
	global Integer countFullBreakfasts(){
		return getMealCount('Breakfast','Full-Priced');
	}
	
	global Integer countFullLunches(){
		return getMealCount('Lunch','Full-Priced');
	}
	
	global Integer countReducedBreakfasts(){
		return getMealCount('Breakfast','Reduced');
	}
	
	global Integer countReducedLunches(){
		return getMealCount('Lunch','Reduced');
	}
	
	global Double getCommunityServiceHours(){
		return student.Service_Hours_YTD__c;
	}
	
	global Double getTotalTimeLost() {
		Double attendanceTimeLost = 0;
		Double consequenceTimeLost = 0;
		Double sectionalTimeLost = 0;
		for (Attendance__c a : attendanceRecords){
			if (a.Daily__c) {
				attendanceTimeLost += a.Time_Lost_Rollup__c;
			}
			else {
				sectionalTimeLost += a.Time_Lost_Rollup__c;
			}
		}
		
		for (Student_Behavior__c sb : studentBehaviorRecords){
			if (sb.Consequence_Time_Lost__c != null) {
				consequenceTimeLost += sb.Consequence_Time_Lost__c;
			}
		}
		
		if (student.Setup__r.Use_Sectional_Attendance__c) {
			return sectionalTimeLost + consequenceTimeLost;
		}
		else {
			return attendanceTimeLost + consequenceTimeLost;
		}
	}
	
	global Double dailyAttendancePercentage() {
		if (student.Days_Enrolled__c == null || student.Days_Enrolled__c == 0) {
			return 0;
		}
		else {
			return (countDailyAttendance('Present', null)/student.Days_Enrolled__c)*100;
		}
	}
	
	global Double sectionalAttendancePercentage(Section__c section) {
		Integer presentCount = countSectionalAttendance('Present', null, section);
		Integer totalCount = countSectionalAttendance(null, null, section);
		
		if (totalCount == 0) {
			return 0;
		}
		else {
			return (presentCount/(Double)totalCount)*100;
		}
	}
	
	//this is the wrong calculation
	global Double finalSectionGrade(Id sectionId) {
		Double finalGrade = 0;
		Section_Grade__c grade = finalSectionGrades.get(sectionId);
		if (grade != null) {
			system.debug(LoggingLevel.INFO, '+++Grade__c:' + grade.Grade__c);
			system.debug(LoggingLevel.INFO, '+++Weighting:' + grade.Course_Weighting__r.Weighting__c);
			finalGrade = grade.Weighted_Final_Grade__c;
		}
		return finalGrade;
	}
	
	public Double finalGrade(ID courseID) {
		Double finalGrade = 0;
		if(finalGrades.containsKey(courseID)) {
			finalGrade = finalGrades.get(courseID).Final_Grade_Value__c;
		}
		return finalGrade;
	}
	
	global Double creditHoursEarned() {
		Double creditsEarned = 0;
		Double passingGrade = student.Setup__r.Passing_Grade_Threshold__c;
		system.debug(LoggingLevel.INFO,'+++passingGrade:' + passingGrade);
		/*
		for (Section_Grade__c grade : finalSectionGrades.values()) {
			system.debug(LoggingLevel.INFO, '+++finalgrade:' + grade.Weighted_Final_Grade__c);
			system.debug(LoggingLevel.INFO, '+++credithours:' + grade.Course_Weighting__r.Course__r.Credit_Hours__c);
			if (grade.Weighted_Final_Grade__c > passingGrade) {
				creditsEarned += grade.Course_Weighting__r.Course__r.Credit_Hours__c;
			}
		}
		*/
		for(Final_Grade__c fg : finalGrades.values()) {
			creditsEarned += fg.Credits_Earned__c;
		}
		return creditsEarned;
	}
}