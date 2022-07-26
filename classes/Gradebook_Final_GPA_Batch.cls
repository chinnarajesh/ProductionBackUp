global class Gradebook_Final_GPA_Batch implements Database.Batchable<sObject>,Database.Stateful{
	global MAP<Id, Section__c> mSection;
	global Map<Id, Course__c> mCourse;
	global Map<String, Grade_Normalization__c> gtransform;
	global Map <Decimal, Grade_Normalization__c> detailedFinalGnMap;
	global Boolean isFinal=false;
	global boolean showInPortal = false;
	global string query;
	global Map<Id, Map <Decimal, Grade_Normalization__c>> masterGsNormMap;
	
	public static Set<String> getOverrideSettings(){
		return	gradebook_SoqlUtils.getAllowedNaValues();
	}
	
	public static void runSemesterGrades( Student__c student){
		Gradebook_Semester_Midterm_Controller calculate = new Gradebook_Semester_Midterm_Controller();
		calculate.calcSemesterMidtermGrades(new List<Student__c> {student}); 
	}
	
	public static void updateCurrentGpa( Id sId, boolean markFinal, Set <Id> validCourses){
		List <Final_Grade__c> fgList = new List <Final_Grade__c>();
		List <Final_Grade__c> invalidFgList = new List <Final_Grade__c>();
		Decimal totalGpaVal =0;
		Decimal totalCredits=0;

		for (Final_Grade__c fg: 
					[select id, final__c, grade_override__c, Exclude_Course_from_GPA__c, Unweighted_GPA__c, course_credits__c, course__c
						from Final_Grade__c 
						where Student__c =:sId 
						and course_credits__c !=null
						and Unweighted_GPA__c!=null ]){
			if (!getOverrideSettings().contains(fg.grade_override__c)){
				if (!fg.Exclude_Course_from_GPA__c){
					if (validCourses.contains(fg.course__c)||fg.Final__c){
						totalGpaVal+=fg.Unweighted_GPA__c*fg.course_credits__c;
						totalCredits+=fg.course_credits__c;
						}
					}
					if (validCourses.contains(fg.course__c)||fg.Final__c)
						fgList.add(fg);
					else 
						inValidFgList.add(fg);
				}
		}

		Student__c stud = new Student__c(Id=sId);
			if (totalCredits == 0)
				stud.current_GPA__c=null;
			else
					stud.current_GPA__c=totalGpaVal/totalCredits;

				upsert stud;
				if (!fgList.isEmpty())
					update fgList;
				if (!inValidFgList.isEmpty())
					delete inValidFgList;
	}

	global Gradebook_Final_GPA_Batch () {
		mCourse = new Map<Id, Course__c> ([Select Id, grade_scale__c, grade_scale_lookup__c, Exclude_from_GPA__c, GPA_Added_Value_Points__c, Multiply_GPA_Added_Value_Points__c, Credit_Hours__c from Course__c where Name !=null]);
		masterGsNormMap = new Map <Id, Map <Decimal, Grade_Normalization__c>>();
	}


	global database.querylocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){
		//Assumes one student per execution
		for(sObject s : scope){
			Student__c std = (Student__c) s;
			Setup__c setup = [select id, Term__c, GPA_By_Reporting_Period_Rolling__c from Setup__c where id =:std.setup__c];
			Map<Id, Decimal> mcvalues = new Map<Id, Decimal>();
			List<Final_Grade__c> finalgrades = new List<Final_Grade__c>();	//Final Grade selects all grades for the student and groups by course and time
			Set<Id> overriddenids = new Set<Id>();							//Get Overridden Courses from Final Grade to exclude
			Set<Id> markoverriddenids = new Set<Id>();						//Get Overridden Courses from Final Grade to exclude
			Set<String> allowSet = getOverrideSettings();					//Get valid override values based on custom setting
			Map<ID, Decimal> overriddenSectionGrades = new Map<ID, Decimal>();	//US1202: what happens now is that for the override values, the final_weighted_grade__c field is going to be null.; need to keep track of what section_grades are null for the course
			Set <Id> courseIds = new Set <Id>();								//Contains set of Courses that are valid or that student SHOULD have final grade for
			Set <Id> reportingPeriodIds = new Set <Id>();						//DE2582 set of reporting period ids used to ensure Student Reporting Period records get created
			Map<String,decimal> totalGrade = new Map<String, decimal>();
			 	Map<String,decimal> totalWeightings = new Map<String, decimal>();	
			 	Map <Id, Map <Id, Section_Grade__c>> courseByRpSgMap = new Map <Id, Map<Id, Section_Grade__c>>();
		 		Map <Id, Time_Element__c> rpMap = new Map <Id, Time_Element__c>();
			 	List <Student_Reporting_Period__c> srpList = new List <Student_Reporting_Period__c>();
			Map <Id, Boolean> courseCompletedMap = new Map <Id, Boolean>();
			 		
			for (Time_Element__c te: [select id, Name, Name__c, Date_Start_Date__c, Reporting_Period__c, Parent_Time_Element__c from Time_Element__c where Parent_time_element__c =:setup.Term__c OR Parent_Time_Element__r.Parent_Time_Element__c =:setup.Term__c]){
				if(te.Reporting_Period__c)
					reportingPeriodIds.add(te.id); //Add to reporting Period Id set to ensure that all Student Reporting Periods get created
				rpMap.put(te.id, te);
			}
			
			// Get the courses that final grades have been overridden for
			for (Final_Grade__c fg: 
					[Select Course__c 
					from Final_Grade__c 
					where Grade_Overridden__c = TRUE
					and Student__c =:std.id
					and Transfer_School__c = null]){
				overriddenids.add(fg.Course__c);
			} 
	
			for (Section_Grade__c sg:
						[Select Id,	Student_Section__r.Section__r.Course__r.Exclude_from_GPA__c, Time__r.Name, 
							Time__r.Name__c, Time__r.Date_Start_Date__c,Weighted_Final_Grade__c, Course_Weighting__r.Weighting__c,
							Student_Section__r.Section__r.Course__c, Grade_Overridden__c,	Student_section__c,	Grade__c,	Time__c,
							Grade_Override__c, Student_Section__r.Section__r.Completed__c
						FROM Section_Grade__c 
						WHERE Student_Section__r.Student__c = :std.Id
						AND Grade_Override__c NOT IN: allowSet
						AND Student_Section__r.Active__c = true
						AND Student_Section__r.Section__r.Active__c=true
						AND grade__c !=null
						AND (RecordTypeID = null OR RecordType.Name = 'Quarter')
						AND course_weighting__c !=null]){
				
				Id CourseId = sg.Student_Section__r.Section__r.Course__c;
				Id rpId = sg.Time__c;
				Decimal sgWeighting = sg.Course_Weighting__r.Weighting__c ==null ? 0 : sg.Course_Weighting__r.Weighting__c;
				Decimal sgGradeValWeight = sg.Course_Weighting__r.Weighting__c ==null ? 0 : sg.Grade__c * sg.Course_Weighting__r.Weighting__c;
				courseCompletedMap.put(courseId, sg.Student_Section__r.Section__r.Completed__c);
			
				if (sg.Student_Section__r.Section__r.Course__r.Exclude_from_GPA__c ==false){
					if (sg.Grade_Overridden__c == TRUE) {
						markoverriddenids.add(CourseId); //Set of Course Ids used later to mark grade as overridden @ FG level
					}
					if (courseByRpSgMap.containskey(CourseId)){
						courseByRpSgMap.get(CourseID).put(rpId, sg);
					} else {
						courseByRpSgMap.put(courseId, new Map <Id, Section_Grade__c>{rpId => sg});
					}
				}	

				/*Maps for Total GPA & Final Grades*/
				if (!overriddenIds.contains(sg.Student_Section__r.Section__r.Course__c )){ //DE2582
					if (totalGrade.containskey(CourseId)) {
						totalGrade.put(CourseId, totalGrade.get(CourseId) + sgGradeValWeight);
						totalWeightings.put(CourseId, totalWeightings.get(CourseId) + sgWeighting);
					} else {	
						totalGrade.put(CourseId, sgGradeValWeight);
						totalWeightings.put(CourseId, sgWeighting);
					}
				}
			} //end loop

			for (String fgs: totalGrade.keyset()){	//Since we have looped through all SGs we can set a valid raw final Grade
				if(totalWeightings.get(fgs)!=0){
					mcvalues.put(fgs,totalGrade.get(fgs)/totalWeightings.get(fgs));
					system.debug(LoggingLevel.info,'Grade Value: ' + fgs + ' ' + totalGrade.get(fgs)/totalWeightings.get(fgs));
				}
			}

			//now prepare to insert/update final grade records for each course
			//Loop back through map with final grade totals per course and apply credits, GPAs (from Grade Norms)
			//Key set looping through is Course ID (1 FG for each course/student)
			for (Id oId: overriddenIds){
				Final_Grade__c thisFg = new Final_Grade__c(Student__c = std.Id, Course__c=oId);
				thisFg.Key__c = string.valueof(std.Id) + string.valueof(oId);
				thisFg.show_in_portal__c = showInPortal; //Indicates whether final grade records created should be shown in portal
				thisFg.final__c	= courseCompletedMap.get(oId)==null ? false : courseCompletedMap.get(oId) ? true : (isFinal? true: false); // Completed course wins, otherwise only mark final if it is the 'final' batch				
				thisFg.Section_Grades_Overridden__c = true;	//If the section grade was overridden, update final grade to show that	
				finalGrades.add(thisFg);
			}
			
			for (Id fgs: mcvalues.keyset()){
				Decimal ccredit = 1.00; //Default credit	
				Decimal rawFgValue = mcvalues.get(fgs); //per Colorado we are no longer rounding this
				if (rawFgValue>100)
					rawFgValue = 100; //Grade cannot be more than 100 for transform purposes; extra credit or mistake entries when points possible was used was likely the cause of this						
				else
					rawFgValue = rawFgValue.divide(1,2);

				Course__c course= mCourse.get(fgs);
				Map <Decimal, Grade_Normalization__c> localGnMap;
				Id GsId = course.Grade_Scale_Lookup__c;
				if (masterGsNormMap.get(GsId)==null){	//ensure that the grade norms for this scale are already pulled
					masterGsNormMap.put(GsId, gradeBook_SoqlUtils.getNormalizationMap(GsId));
				}

				localGnMap = masterGsNormMap.get(GsId);
				Grade_Normalization__c gn =localGnMap.get(rawFgValue);			
				Decimal gpaAddedValuePoints = course.GPA_Added_Value_Points__c!=null ? course.GPA_Added_Value_Points__c : 0;

				Final_Grade__c thisFg = new Final_Grade__c (Student__c = std.Id, Course__c=fgs);
				thisFg.Key__c = string.valueof(std.Id) + string.valueof(fgs);
				thisFg.Final_Grade_Value__c = rawFgValue; 
				thisFg.Final_Grade_Letter_v2__c	= gn.Transformed_Grade__c;
				thisFg.Unweighted_GPA__c	=	gn.GP_Value__c;
				thisFg.Show_in_Portal__c	= showInPortal; //Indicates whether final grade records created should be shown in portal
				thisFg.Final__c				= courseCompletedMap.get(fgs)==null ? false : courseCompletedMap.get(fgs) ? true : (isFinal? true: false); // Completed course wins, otherwise only mark final if it is the 'final' batch

				//Need to check first if FG does not actually count towards GPA
				if (mCourse.containskey(fgs)){ 
					ccredit = course.Credit_Hours__c !=null ? course.Credit_Hours__c : 0;
					thisFg.Course_Credits__c=ccredit;
					thisFg.Exclude_Course_from_GPA__c = course.Exclude_from_GPA__c;

					//If the section grade was overridden, update final grade to show that
					thisFg.Section_Grades_Overridden__c = markoverriddenids.contains(fgs);
				
					if(thisFg.Unweighted_GPA__c != null) {
						if(course.Multiply_GPA_Added_Value_Points__c) {					
							thisFg.Weighted_GPA__c = thisFg.Unweighted_GPA__c*gpaAddedValuePoints;
						} else {
							thisFg.Weighted_GPA__c = thisFg.Unweighted_GPA__c + gpaAddedValuePoints;
						}
					}
						
					thisFg.Final_GPA_Value__c=	thisFg.Unweighted_GPA__c + gpaAddedValuePoints; 
					courseIds.add(fgs);
					finalGrades.add(thisFg);
				}
			}

			Set <Id> rpCheckSet = new Set <Id>();
			for (Student_Reporting_Period__c srp:
						[select id, time__c,time__r.name, time__r.date_start_date__c, student__c, gpa__c 
						from Student_Reporting_Period__c 
						where Student__c =:s.id]){
				srpList.add(srp);
				rpCheckSet.add(srp.time__c);
			}

			/*Need to check to make sure all SRPs needed are created */
			for (Id sgRpId: reportingPeriodIds){
				if (!rpCheckSet.contains(sgRpId)){
					srpList.add(new Student_Reporting_Period__c(Student__c =std.id, Time__c=sgRpId, Reporting_Period_Name__c=rpMap.get(sgRpId).Name__c));
				}
			}
			
			for (Student_Reporting_Period__c srp: srpList){
				srp.gpa__c =null;
				Time_Element__c srpRp = rpMap.get(srp.Time__c);//represents current SRP RP in focus
				if (srpRp!=null){
					Decimal totalgpaCreditNum =0;	//sum (gpa * credits)
					Decimal totalCreditDen =0;		//sum (credits)
					for (Id CourseId: courseByRpSgMap.keySet()){
						Course__c course = mCourse.get(courseId);
						Decimal gradeWghtVal =0; // sum (grade * weighting)
						Decimal weightingVal =0; // sum (weighting)
						boolean bValidSg=false;
						for (Id timeId : courseByRpSgMap.get(CourseId).keySet()){ //get all the section grades for that course by Rp
							if (rpMap.get(timeId)!=null){ // shouldn't be null but just in case 
								Time_Element__c summationRp = rpMap.get(timeId); //section grade reporting period
								if (!setup.GPA_By_Reporting_Period_Rolling__c && (summationRp.id == srpRp.id || (!summationRP.Reporting_Period__c && summationRp.Parent_Time_Element__c == srpRp.id))|| //IE not rolling and rp Ids match
										setup.GPA_By_Reporting_Period_Rolling__c && (summationRp.date_start_date__c <=srpRp.date_start_date__c )){ // is rolling and same or earlier
									Section_Grade__c thisSg = courseByRpSgMap.get(CourseId).get(timeId);
									bValidSg = true;
									gradeWghtVal+= thisSg.course_Weighting__r.weighting__c==null ? 0 : thisSg.grade__c * thisSg.course_Weighting__r.weighting__c;
									weightingVal +=	thisSg.course_Weighting__r.weighting__c==null ? 0 : thisSg.course_Weighting__r.weighting__c;
								}
							}
						}
						if (bValidSg){// In situation where course should not count in the given reporting period
							//done looping through all section grades and checking what is valid for srp
							decimal rawGradeValue = weightingVal == 0 ? 0 : gradeWghtVal.divide(weightingVal,2);
							system.debug(LoggingLevel.info, 'rawGradeValue~~~~'+rawGradeValue);
							rawGradeValue = rawGradeValue > 100 ? 100.00 : rawGradeValue;
					 		Map <Decimal, Grade_Normalization__c> localGnMap;
					 		Id GsId = course.Grade_Scale_Lookup__c;
							if (!masterGsNormMap.containsKey(GsID)){ //ensure that the grade norms for this scale are already pulled
								masterGsNormMap.put(GsId, gradeBook_SoqlUtils.getNormalizationMap(GsId));
							}

							localGnMap = masterGsNormMap.get(GsId);	
							Grade_Normalization__c gn =localGnMap.get( rawGradeValue);		
							decimal courseGpa =	rawGradeValue ==0 ? 0 : gn.GP_Value__c;
							totalgpaCreditNum +=course.credit_Hours__c ==null ? 0 :	course.credit_Hours__c * courseGpa;
							totalCreditDen += course.credit_Hours__c ==null	? 0 : course.credit_Hours__c;
						}
					}
					// do divide at the end.
					srp.gpa__c = totalCreditDen==0 ? null : totalgpaCreditNum/totalCreditDen; // only add the gpa if the reporting period has actually started
					system.debug(LoggingLevel.info, srp);
				}
			}
		 
			if (!finalGrades.isEmpty()){
				core_triggerUtils.recursiveHelper(true);
				upsert finalgrades key__c; //upsert based on key field ( Student + Course ) 
				//Set<Id> gradeoverride = new Set<Id>();
				//gradeoverride.add(std.Id);
				//Gradebook_ManageGradebook.checkforgradeoverride(gradeoverride);
			}
			if (!srpList.isEmpty())
				upsert srpList;
			updateCurrentGpa( std.Id, isFinal, courseIds); //updates student's current GPA nightly batch
			runSemesterGrades(std); //DE2085 
		}
	}// end execute	

	global void finish(Database.BatchableContext BC){
		//first get a list of the students we need to work on
		string studentQuery = 'Select id, Name, Individual__c, School__c, Grade__c, Weighted_GPA_To_Date__c, Class_Rank__c, Active__c, Setup__r.Calculate_Class_Rank__c FROM Student__c where ';
		if (query.containsIgnoreCase('where')) {
			integer substringLoc = query.indexOfIgnoreCase('where')+5;
			studentQuery+= '('+query.substring(substringLoc)+ ') AND Archived__c = false';
		} else{
			studentQuery +=' Archived__c = false';
		}

		system.debug(studentQuery); 
		List<Student__c> studentList = (List<Student__c>) Database.query(studentQuery);

		//now we want to get the contact sets out because we need to get the associated students out.
		Map<ID, Student__c> contactMap = new Map<ID, Student__c>();
		Map<ID, ID> contactSchoolMap = new Map<ID, ID>();
		for(Student__c s:studentList){
			contactMap.put(s.Individual__c, s);
			contactSchoolMap.put(s.Individual__c, s.School__c);
		}
		Set<Id> contactIdSet = contactMap.keySet();

		//get the fields we need and steal the school list from the batch query
		string allStudentQuery = 'SELECT id, Name, Grade__c, School__c, Individual__c, Active__c, Final_GPA_Value__c, Total_Credits_Earned__c, Combined_Final_Grade_Values__c, Combined_Weighted_Final_Grade_Values__c From Student__c where Individual__c in: contactIdSet';
		List<Student__c> allStudents = (List<Student__c>) Database.query(allStudentQuery);
		Map<Id, Decimal> GPAMap = new Map<Id, Decimal>();
		Map<Id, Decimal> WGPAMap = new Map<Id, Decimal>();
		Map<Id, Decimal> totalStudentMap = new Map<Id, Decimal>(); // this should be total credits not total students
		for(Student__c s:allStudents){
			if(contactSchoolMap.containsKey(s.Individual__c) && contactSchoolMap.get(s.Individual__c) == s.School__c){
				if(GPAMap.containsKey(s.Individual__c)){
					GPAMap.put(s.Individual__c, GPAMap.get(s.Individual__c) + s.Combined_Final_Grade_Values__c);
					WGPAMap.put(s.Individual__c, WGPAMap.get(s.Individual__c) + s.Combined_Weighted_Final_Grade_Values__c);
					totalStudentMap.put(s.Individual__c, totalStudentMap.get(s.Individual__c)+s.Total_Credits_Earned__c);
				} else {
					GPAMap.put(s.Individual__c, s.Combined_Final_Grade_Values__c);
					WGPAMap.put(s.Individual__c, s.Combined_Weighted_Final_Grade_Values__c);
					totalStudentMap.put(s.Individual__c, s.Total_Credits_Earned__c);
				}
			}
		}
	
		for(Student__c s:studentList){
			if(totalStudentMap.containsKey(s.Individual__c)){
				s.GPA_To_Date__c = totalStudentMap.get(s.Individual__c)==0? 0 : GPAMap.get(s.Individual__c)/totalStudentMap.get(s.Individual__c);
				s.Weighted_GPA_To_Date__c =	totalStudentMap.get(s.Individual__c)==0? 0 : WGPAMap.get(s.Individual__c)/totalStudentMap.get(s.Individual__c);
			} else {
				s.GPA_To_Date__c = 0;
				s.Weighted_GPA_To_Date__c = 0;
			}
		}

		update studentList;

		if(isFinal){
			studentList = (List<Student__c>) Database.query(studentQuery + ' AND Active__c = true AND Grade__c != null AND School__c != null ORDER BY School__c, Grade__c, Weighted_GPA_To_Date__c DESC');
	
			ID currentSchool;
			String currentGrade = '';
			Integer currentRank = 1;
			Decimal lastGPA = -1;
			Integer totalAtGPA = 0;
	
			for(Student__c s:studentList){
				if(!s.Setup__r.Calculate_Class_Rank__c){
					s.Class_Rank__c = 0;
				} else {
					if(currentSchool == null || s.School__c != currentSchool || currentGrade == '' || s.Grade__c != currentGrade){
						currentSchool = s.School__c;
						currentGrade = s.Grade__c;
						currentRank = 1;
						lastGPA = -1;
						totalAtGPA = 0;
					}
					if(totalAtGPA == 0){
						totalAtGPA = 1;
						s.Class_Rank__c = currentRank;
						lastGPA = s.Weighted_GPA_To_Date__c;
					} else if(totalAtGPA >= 1 && s.Weighted_GPA_To_Date__c != lastGPA){
						currentRank += totalAtGPA;
						s.Class_Rank__c = currentRank;
						totalAtGPA = 1;
						lastGPA = s.Weighted_GPA_To_Date__c;
					} else if(totalAtGPA >= 1 && s.Weighted_GPA_To_Date__c == lastGPA){
						s.Class_Rank__c = currentRank;
						totalAtGPA++;
					}
				}
			}
			update studentList;
		}
	}
}