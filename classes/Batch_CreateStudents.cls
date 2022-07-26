global class Batch_CreateStudents implements Database.Batchable<SObject>, Database.Stateful{
	global String	query;
	global String	oldSetupId;
	global Setup__c oldSetup;
	global Map<String,String> currentSetupGradesMap;
	global static Map<String,String> schoolToFirstGradeLevelMap;
	global static Map<String,Setup__c> schoolToNewSetupMap;
	global String nextYearId;
	global String dataLoadLogId;
	private List<Student__c> studentBatch;
	private Data_Load_Log__c log;

	global Batch_CreateStudents(){}

	global Batch_CreateStudents(String logID, String setupID, String yearID) {
		log = 
			new Data_Load_Log__c(
				Setup__c = setupID,
				Type__c = 'Student__c',
				Status__c = 'Pending',
				Class_Name__c = 'Batch_CreateStudents',
				Total_Records__c = 0,
				Processed_Records__c = 0,
				Failed_Records__c = 0,
				Messages__c = '',
				Start_Time__c = system.now(),
				Start_Time_Text__c = system.now().format('MM/dd/yyyy hh:mm a')
			);
		
		oldSetupId = setupID;
		nextYearId = yearID;

		if(setupId == null){
			throw new Error_Handling.SchoolForceException('You must provide the setup id you wish to process in order to run this batch.');
		}
		if(yearID == null){
			throw new Error_Handling.SchoolForceException('You must provide the year you wish to process in order to run this batch.');
		}

		try {
			oldSetup = core_SoqlUtils.getSetupById(oldSetupId);
			query = processQuery(oldSetupId);
			currentSetupGradesMap = generateCurrentGradesMap(oldSetup);
			insert log;
			dataLoadLogId = log.ID;
		} catch(Exception e) {
			//throw exception as the page can deal with it still
			throw e;
		}
	}

	global Database.QueryLocator start(Database.BatchableContext ctx) {
		try{
			log.Batch_ID__c = ctx.getJobId();
			log.Processed_Records__c = 0;
			log.Failed_Records__c = 0;
			log.Total_Records__c = 0;

			return Database.getQueryLocator(query);
		} catch(Exception e){
			addLogFailureMessage('Failure during batch start. Please contact support for assistance in resolving this issue.');
			insert Error_Handling.handleError('Setup, '+oldsetup.Id, 'Batch_CreateStudents', 'Error while starting batch run', e);
		} finally{
			update log;
		}
		return Database.getQueryLocator('select id from Student__c where ID = null');
	}

	global void execute(Database.BatchableContext ctx, List<SObject> scope) {
		try{
			studentBatch = (Student__c[])scope;

			log = [SELECT Id, Type__c, Setup__c, Status__c, Class_Name__c, Batch_Id__c,
						Total_Records__c, Failed_Records__c, Start_Time__c, Start_Time_Text__c, 
						End_Time__c, End_Time_Text__c, Messages__c, Processed_Records__c
					FROM Data_Load_Log__c 
					WHERE ID =: dataLoadLogID];
			processStudents();
		} catch(Exception e){
			insert Error_Handling.handleError('Setup, '+oldsetup.Id, 'Batch_CreateStudents', 'Error while processing students', e);
			addLogFailureMessage('Failure during batch execute. Please contact support for assistance in resolving this issue.');
		} finally {
			update log;
		}
	}

	global void finish(Database.BatchableContext ctx) {
		try {
			log = [SELECT ID, Status__c, End_Time__c, End_Time_Text__c, Messages__c FROM Data_Load_Log__c WHERE ID =: dataLoadLogId];
			log.End_Time__c = System.now();
			log.End_Time_Text__c = log.End_Time__c.format('MM/dd/yyyy hh:mm a');

			if(log.Status__c != 'Failed'){
				log.Status__c = 'Completed';

				Setup__c currentSetup = core_SoqlUtils.getSetupById(oldSetupId);
				currentSetup.Students_Created__c = true;
				update currentSetup;

				EOY_Progress__c progress = [select id, School_Next_Year_Students_Completed__c from EOY_Progress__c where Setup__c=:oldSetupID and Year__c=:currentSetup.Year__c and RecordType.Name = 'EOY' limit 1];
				progress.School_Next_Year_Students_Completed__c = true;
				update progress;
			}
		} catch(Exception e) {
			insert Error_Handling.handleError('Setup, '+oldsetup.Id, 'Batch_CreateStudents', 'Error while finishing batch run', e);
			addLogFailureMessage('Failure during batch finish process. Please contact support for assistance in resolving this issue.');
		} finally{
			update log;
		}
	}

	public static String processQuery(String oldSetupId){
		string queryToProcess;

		Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get('student__c').getDescribe().Fields.getMap();
		String fieldSet = '';
		if(fMap != null) { //probably should never happen
			for(Schema.SObjectField ft: fMap.values()) {
				Schema.DescribeFieldResult fd = ft.getDescribe();
				if(fd.isCreateable()) {
					fieldSet += ((fieldSet == '') ? '' : ',') + fd.getName();
				}
			}
		}
		queryToProcess = 'SELECT ' + fieldSet + ' FROM ' + ' Student__c ';

		queryToProcess+='  WHERE Setup__c=\''+oldSetupId+'\'';
		queryToProcess+='  AND Intent_to_Return_Following_Year__c = true ';
		queryToProcess+='  AND Final_Grade_Level__c = false ';
		queryToProcess+='  AND Created_Next_Year_Student__c = false ';
		queryToProcess+='  AND Active__c = true ';

		system.debug('*~*~* queryToProcess: ' + queryToProcess);
		return queryToProcess;
	}

	private static Map<String, String> generateCurrentGradesMap(Setup__c s) {
		Map<String, String> returnMap = new Map<String, String>();
		if(String.isBlank(s.Grade_Span__c)){
			throw new Error_Handling.SchoolForceException('The grade span for your current setup is null. Please set a grade span.');
		} else {
			//note the assumption here that the grades in the setup grade span will always be progressivly ordered.
			List<String> currentGrades = s.Grade_Span__c.split(';');
			for(Integer i = 0; i < currentGrades.size() - 1; i++) {
				returnMap.put(currentGrades[i], currentGrades[i+1]);
			}
			returnMap.put(currentGrades[currentGrades.size()-1], '');
		}

		return returnMap;
	}

	public Map<String, Map<String, String>> getGradeLevels(){
		Map<String, Map<String, String>> schoolToNewSetupGradeSpanMap = new Map<String, Map<String, String>>();

		schoolToFirstGradeLevelMap = new Map<String, String>();
		schoolToNewSetupMap = new Map<String, Setup__c>();
		boolean hasErrors = false;

		for(Setup__c s: [SELECT ID, Grade_Span__c, School__c,School__r.Name,Year__r.Name__c, Term__r.Date_Start_Date__c
						FROM Setup__c
						WHERE New_School_Year__c = true 
						AND Year__c =: nextYearId 
						AND School__r.RecordType.Name = 'School']){
			if(s.Grade_Span__c == null){
				hasErrors = true;
				addLogFailureMessage('The setup for school '+s.School__r.Name+' for the future year does not have a grade span. Please add a grade span for this school to create new students.');
				continue;
			}
			if(schoolToNewSetupMap.containsKey(s.School__c)){
				hasErrors = true;
				addLogFailureMessage('The system has identifed two setups for School '+s.School__r.Name+' for year '+s.Year__r.Name__c+'. Please check your data.');
				continue;
			}

			schoolToNewSetupMap.put(s.School__c,s);

			List<String> tGradeLevels = s.Grade_Span__c.split(';');
			Map<String, String> tCurrentGradeToNextGradeMap = new Map<String, String>();

			for(Integer i = 0;i < (tGradeLevels.size()-1);i++){
				tCurrentGradeToNextGradeMap.put(tGradeLevels[i],tGradeLevels[i+1]);
			}
			schoolToNewSetupGradeSpanMap.put(s.School__c, tCurrentGradeToNextGradeMap);
			schoolToFirstGradeLevelMap.put(s.School__c,tGradeLevels[0]);
		}
		return (hasErrors)?null:schoolToNewSetupGradeSpanMap;
	}

	private void processStudents() {
		Map<String, Student__c> currentStudentMap = new Map<String, Student__c>();
		Map<String, Student__c> nextYearStudentMap = new Map<String, Student__c>();
		
		Map<String,Map<String,String>> schoolToNewSetupGradeSpanMap;
		Set<ID> contactIds = new Set<ID>();

		log.Total_Records__c += studentBatch.size();

		try {
			schoolToNewSetupGradeSpanMap = getGradeLevels();
			if(schoolToNewSetupGradeSpanMap == null){
				addLogFailureMessage('An error occured when attempting to load grade spans for next year.');
				log.Failed_Records__c += studentBatch.size();
				return;
			}
		} catch(Exception e) {
			insert Error_Handling.handleError('','Batch_CreateStudents','Failure loading grade scale data.',e);
			addLogFailureMessage('An exception occured when attempting to load grade spans for next year:');
			log.Failed_Records__c += studentBatch.size();
			system.debug(e);
			return;
		}

		for(Student__c stu : studentBatch){
			if(stu.Student_Id__c == null) {
				addLogFailureMessage('Student '+stu.Name+' does not have a student ID. Please enter a student id for this student before continuing.');
				log.Failed_Records__c++;
				continue;
			}

			if(stu.Next_School__c == null){
				addLogFailureMessage('Student '+stu.Name+' does not have a future school. Please enter a future school before continuing.');
				log.Failed_Records__c++;
				continue;
			}

			Student__c s = cloneStudent(stu);

 			try{
 				s.Reference_Id__c = stu.Student_Id__c + '_' + schoolToNewSetupMap.get(stu.Next_School__c).Year__r.Name__c;
 				s.Entry_Date__c = schoolToNewSetupMap.get(stu.Next_School__c).Term__r.Date_Start_Date__c;
 				s.School_Year__c =  schoolToNewSetupMap.get(stu.Next_School__c).Year__c; 
 				s.Setup__c = schoolToNewSetupMap.get(stu.Next_School__c).Id;
				s.School__c = stu.Next_School__c;
				s.Next_School__c = stu.Next_School__c;

				//only grade depends on the promotional status, but we have to check for valid entry
				//In the event that you're in here looking for the cause of an error understand that this logic is not 100% right, it
				//will allow you to do odd things like promote 5th graders to 9th grade.
				//We need to define a "future grade" for this to work properly, because the "future grade" is ambiguous in the case of transfers.
				if(stu.Promoted__c){
					//1, going to an existing grade in a new school, 2 next grade not offered by current school, go to first grade of next school, 3 fail
					if(schoolToNewSetupGradeSpanMap.get(stu.Next_School__c).containsKey(stu.Grade__c)){ //students current grade exists in the mapping
						s.Grade__c = schoolToNewSetupGradeSpanMap.get(stu.Next_School__c).get(stu.Grade__c);
					} else { //their grade is not in the set, and it's not in their current school
						s.Grade__c = schoolToFirstGradeLevelMap.get(stu.Next_School__c);
					}
				} else {
					Set<String> allGrades = new Set<String>(schoolToNewSetupGradeSpanMap.get(stu.Next_School__c).keySet());
					allGrades.addAll(schoolToNewSetupGradeSpanMap.get(stu.Next_School__c).values());

					if(allGrades.contains(stu.Grade__c)){
						s.Grade__c = stu.Grade__c;
					} else {
						addLogFailureMessage('Student '+s.Name+' is being retained, but their grade is no longer offered by the school');
						log.Failed_Records__c++;
						continue;
					}
				}

				stu.Created_Next_Year_Student__c = true;
				currentStudentMap.put(stu.Student_Id__c,stu);
				nextYearStudentMap.put(s.Student_Id__c,s);
			} catch (Exception e){
				system.debug('*~*~* stu: ' + stu);
				system.debug('*~*~* s: ' + s);
				system.debug(e);

				addLogFailureMessage('Unexpected failure processing promotional status for student: '+stu.Name);
				addLogFailureMessage(e.getCause()+': '+e.getStackTraceString());
				log.Failed_Records__c++;
			}
		}

		if(!nextYearStudentMap.isEmpty()){
			try{
				insertStudents(currentStudentMap, nextYearStudentMap);
			} catch(Exception e){
				addLogFailureMessage('Failure trying to insert new students.');
				log.Failed_Records__c += studentBatch.size();
			}
		}
	}

	private Student__c cloneStudent(Student__c stu){
		Student__c s = stu.clone(false, true);
		//new records cannot be owned by inactive owners, so we need to reset this to the running user
		//s.OwnerID=UserInfo.getUserId();
		s.Active__c = false;
		s.Admission_code__c = null;
		s.Admission_Status__c = null;
		s.Advisory__c = null;
		s.Alternate_Lang_Comments__c = null;
		s.Archived__c = false;
		s.Campus__c = null;
		s.Car_Model__c = null;
		s.Class_Rank__c = null;
		s.Comments__c = null;
		s.Created_Next_Year_Student__c = false;
		s.Current_GPA__c = null;
		s.Current_School_Year__c = null;
		s.Days_Enrolled__c = null;
		s.Destination_School_Type__c = null;
		s.Destination_School__c = null;
		s.Detailed_Exit_Reason__c = null;
		s.ELL_Student_in_a_US_School_less_than_1_Y__c = false;
		s.ELL_test_Date__c = null;
		s.ELL_Test__c = null;
		s.Economically_Disadvantaged__c = false;
		s.Evaluated_For_Special_Education__c = false;
		s.Evaluated_For_Special_Education_But_Not__c = false;
		s.Evalauted_For_special_Education__c = false;
		s.Exit_Comments__c = null;
		s.Exit_date__c = null;
		s.Exit_Reason__c = null;
		s.Exit_Status__c = null;
		s.Exit_Type__c = null;
		s.Expiration_Date__c = null;
		s.Final_Grade_Level__c = false;
		s.Final_Reading_Level__c = null;
		s.Gifted__c = false;
		s.Grade_Name__c = null;
		s.Grade_Track__c = null;
		s.Grade__c = null;
		s.Grades_Overridden__c = false;
		s.Graduation_Indicator__c = false;
		s.Holding_Source__c = null;
		s.Homeroom__c = null;
		s.If_Free_Type__c = null;
		s.Immigrant_Program_Participant__c = false;
		s.Is_Active__c = false;
		s.LEP_Flag__c = null;
		s.License_Plate__c = null;
		s.Locker_Number__c = null;
		s.Lot_Access__c = null;
		s.Lunch_Status__c = null;
		s.Meals_Category__c = null;
		s.Meals_Sub_Category__c = null;
		s.Next_School__c = null;
		s.Non_Present_Daily_Attendance_v2__c = null;
		s.OSSE_code__c = null;
		s.Official_Exit_Type__c = null;
		s.Permission_For_Directory__c = null;
		s.Permit_Number__c = null;
		s.Photograph_Authorized__c = false;
		s.Previous_School_1_Type__c = null;
		s.Previous_School_1__c = null;
		s.Previous_School_2_Type__c = null;
		s.Previous_School_2__c = null;
		s.Primary_Car_Make__c = null;
		s.Primary_Schedule_Group__c = null;
		s.Promoted__c = true;
		s.Promotional_Status__c = null;
		s.RT_Picture__c = null;
		s.Reading_Level_Q1__c = null;
		s.Reading_Level_Q2__c = null;
		s.Reading_Level_Q3__c = null;
		s.Reading_Level_Q4__c = null;
		s.Recovery_Plan_Action_Items__c = null;
		s.Residence_After_Exiting_School__c = null;
		s.SPED_School__c = null;
		s.Schedule_Group__c = null;
		s.School_Bus_Route__c = null;
		s.School_Bus__c = false;
		s.School_Counseling__c = false;
		s.School_Year__c = null;
		s.School__c = null;
		s.Sec_Ed__c = false;
		s.Section__c = null;
		s.Service_Hours_YTD__c = null;
		s.Setup__c = null;
		s.Title_1_Status_Date__c = null;
		s.Title_1_Status__c = null;
		s.Today_S_Points_Balance__c = null;
		s.Transportation_Authorized__c = false;
		s.Transportation_Type__c = null;
		s.Video_Authorized__c = false;
		s.Week_To_Date_Points_Balance__c = null;
		s.X504_Plan__c = false;
		s.Years_at_School__c = null;
		s.Of_Assigned_Homework__c = null;
		s.Of_Completed_Homework__c = null;
		s.Of_Late_Homework__c = null;
		s.Of_Missing_Homework__c = null;

		if(stu.Next_School__c == stu.School__c){
			s.Cohort__c = stu.Cohort__c;
			s.Original_Member_Of_Cohort__c = stu.Original_Member_Of_Cohort__c;
		} else {
			//new schools have new cohorts, so we need to null this out.
			s.Cohort__c = null;
			s.Original_Member_Of_Cohort__c = false;
		}

		return s;
	}

	private void insertStudents(Map<String,Student__c> oldStudents, Map<String, Student__c> newStudents){
		Set<ID> contactIds = new Set<ID>();

		//for debugging
		for(Student__c s : newStudents.values()) {
			system.debug('*~*~* student: ' + s);
		}

		//deactivate trigger
		core_triggerUtils.mealsTrigger = true;
		core_triggerUtils.studentTrigger = false;

		List<Database.UpsertResult> nextYearStudentResults = database.upsert(newStudents.values(), Student__c.Reference_Id__c, false);

		for (Integer i = 0; i < nextYearStudentResults.size(); i++) {
			if (!nextYearStudentResults[i].isSuccess()) {
				addLogFailureMessage('Insert failure for student '+newStudents.values()[i].Name+': '+nextYearStudentResults[i].getErrors()[0].getMessage());
				log.Failed_Records__c++;
				oldStudents.remove(newStudents.values()[i].Student_Id__c);
			}
		}

		List<Database.UpsertResult> currentStudentResults = database.upsert(oldStudents.values(), Student__c.Reference_Id__c, false);

		for (Integer i = 0; i < currentStudentResults.size(); i++) {
			if (!currentStudentResults[i].isSuccess()) {
				addLogFailureMessage('Update failure for student '+oldStudents.values()[i].Name+': '+currentStudentResults[i].getErrors()[0].getMessage());
				//because only created students get to this point we can count these as failed too without getting dupes
				log.Failed_Records__c++;
			} else {
				//only process the student/pg records if both students go through
				contactIds.add(oldStudents.values()[i].Individual__c);
				log.Processed_Records__c++;
			}
		}

		try{
			List<Student_PG__c> updateStudentPG = new List<Student_PG__c>();
			for(Student_PG__c spg:[SELECT Student_c__c,Student__c,Student__r.Student_Id__c, Student__r.Name, Student_c__r.Name FROM Student_PG__c WHERE Student_c__c in:contactIds and Student__r.Student_Id__c != null]){
				if(newStudents.containsKey(spg.Student__r.Student_ID__c)) {
					spg.Student__c = newStudents.get(spg.Student__r.Student_Id__c).Id;
					if(spg.Student__c != null)
						updateStudentPG.add(spg);
				} else {
					addLogMessage('Found improperly linked Student/PG record: '+spg.id);
				}
			}

			if(updateStudentPG.size() > 0) {
				update updateStudentPG;
			}
		} catch(Exception e){
			addLogFailureMessage('Failure trying to update Student/PG records');
			log.Failed_Records__c += oldStudents.size();
		}
		
	}

	private void addLogFailureMessage(String message){
		addLogMessage(message);
		log.Status__c = 'Failed';
	}

	private void addLogMessage(String message){
		if(log.Messages__c == null){
			log.Messages__c = '';
		}
		log.Messages__c += message+'\n';
	}
}