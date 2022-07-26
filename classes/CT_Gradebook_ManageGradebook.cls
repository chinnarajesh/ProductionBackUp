/* Developer's Notes: Summer 2014: iteration 2 - 2/20/2014

	Refactor needed.  Goal is to maintain current functionality and add flexibility for the new features of Standard Grades.
	Standard Grades are now reporting period specific and have either a rolling / non-rolling definition.  Need to also improve
	batch capability, improve valdiation, clear and concise business logic definitions.    

*/

public class CT_Gradebook_ManageGradebook {

	public static CT_Gradebook_GradeUtils gradeUtils {get; set;}
	
	static {
		gradeUtils = new CT_Gradebook_GradeUtils();
		gradeUtils.setOverrideValues();
	}

//Helper Methods
//======================================================================================================//

	public static Boolean bGradeChange(Grade__c nGrade, Grade__c oGrade) {
		return (nGrade.Entered_Grade__c != oGrade.Entered_Grade__c ||
				nGrade.Assignment_Weighting__c != oGrade.Assignment_Weighting__c ||
				nGrade.Possible_Points__c != oGrade.Possible_Points__c ||
				nGrade.Exclude_From_Section_Grade__c != oGrade.Exclude_From_Section_Grade__c ||
				nGrade.Include_In_Standard_Grade__c != oGrade.Include_In_Standard_Grade__c ||
				
				nGrade.Grade_Update__c != oGrade.Grade_Update__c ||
				
				nGrade.Locked_for_Final__c != oGrade.Locked_for_Final__c ||
				UserInfo.getFirstName() == 'SchoolForce' ||
				core_TriggerUtils.calculateGrades );
				
				//oldMethod checked for these differences, but why?
				//g.Comment__c
				//g.Publish_Comment__c
				//g.Standard_Weighting__c - not fully functional
	}

	//method to return the gradescales of the incoming grades to pass to the
	//gradeUtils method in settingGradeScales(get normalizations and picklist values)
	public static Boolean checkAssignmentGradeScales(List<Grade__c> grades) {
		Boolean isCorrect = true;
		for(Grade__c g : grades) {
			if(g.Grading_Type__c == null) {
				g.addError('Grade is missing a lookup on assignment Grade Scale');
				system.debug('addError - Grade is misssing a lookup on assignment Grade Scale; grade: ' + g);
				isCorrect = false;
			}
		}
		return isCorrect;
	}
	
	public static List<Grade__c> getCourseGradeScales(List<Grade__c> grades) {
		List<Grade__c> returnSet = new List<Grade__c>();
		//have to get course grade scales
		for(Grade__c g : grades) {			
			if(g.Course__c == null){
				g.addError('Grade record does not have a Course Lookup ' + g.ID);
				system.debug('addError - Grade record does not have a Course Lookup: ' + g);
				continue;
			}
			if(g.Grade_Scale_Id__c == null) {
				g.addError('Course must have a Grade_Scale_Lookup__c! Grade_Scale__c has been retired and is no longer supported');
				system.debug('addError - Course must have a Grade_Scale_Lookup__c!  Grade_Scale__c has been retired and is no longer supported');
				continue;
			}
			returnSet.add(g);
		}
		
		return returnSet;
	}
	
	public static Section_Grade__c createSectionGrade(ID ss, Section_ReportingPeriod__c srp) {
		Section_Grade__c sc = new Section_Grade__c();
		sc.Course_Weighting__c = srp.Course_Weighting__c;
		sc.Student_Section__c = ss;
		sc.Time__c = srp.Time__c;
		sc.Reference_Id__c = ss + '-' + srp.Time__c;
		return sc;
	}
 
//======================================================================================================// 
 
	public static void isBeforeInsert(List<Grade__c> nList) {
		//per method, try to set the gradeScales if it's empty
		if(gradeUtils.bAssignmentGradeScalesEmpty() && checkAssignmentGradeScales(nList)) {
			gradeUtils.setAssignmentGradeScales(nList);
		}
		
		//method for validation
	}

	public static void isAfterInsert(List<Grade__c> nList) {
		//upserts the section grade record for the grade (based on key and srp).  Most of the code is maintained from the original
		Map<String, Section_ReportingPeriod__c> srpMap = new Map<String, Section_ReportingPeriod__c>();  //Map of SRP to help create
		Set<Section_Grade__c> sgList = new Set<Section_Grade__c>();
		
		//build the srp map
		for(Grade__c g : nList) {			
			if(g.Student_Section__c == null){
				g.addError('Grade ' + g.ID + ' does not have a Student_Section__c');
				system.debug('addError - Grade: ' + g + ' does not have a Student_Section__c');
			}

			//build the srpMap Map, excludes gradebook group sections? why?  because gradebook groups do not have section grades, those grades
			//are applied to the parent section grade.
			if(!Section_Utils.nonSectionRTSet.contains(g.Section_RT__c)) {
				//srp map should only have parent sections
				srpMap.put(g.Section__c + '-' + g.Time__c, null);
			}

		}
		
		//create the srp map
		if(!srpMap.isEmpty()) {
			for(Section_ReportingPeriod__c srp : [SELECT ID, ReferenceID__c, time__c, Course_Weighting__c FROM Section_ReportingPeriod__c WHERE ReferenceID__c IN: srpMap.KeySet()]) {
				srpMap.put(srp.ReferenceID__c, srp);
			}
			
			for(Grade__c g : nList) {
				String Key = g.Section__c + '-' + g.Time__c;
				if(srpMap.containsKey(Key) && srpMap.get(key)!=null ) {
					Section_Grade__c sg = createSectionGrade(g.Student_Section__c, srpMap.get(Key));
					system.debug('*~*~* afterInsert Grade: generating section grade: ' + sg);
					sgList.add(sg);
				}
			}
			
			if(!sgList.isEmpty()) {
				upsert new List<Section_Grade__c>(sgList) Reference_Id__c;
			}
		}
	}
	
	public static void isBeforeUpdate(Map<ID, Grade__c> oMap, Map<ID, Grade__c> nMap) {
		//per method, try to set the gradeScales if it's empty
		if(gradeUtils.bAssignmentGradeScalesEmpty() && checkAssignmentGradeScales(nMap.Values())) {
			gradeUtils.setAssignmentGradeScales(nMap.Values());
		}		
		
		//method for validation and set the weighted grade value, the grade number and the assignment weightings: validateGrade(g)
		for(Grade__c g : nMap.Values()) {
			try {	
				if(bGradeChange(g, oMap.get(g.ID))) {
					gradeUtils.validateGrade(g);
				}

			}
			catch(Exception e) {
				g.addError('An error occurred when attempting to set the wgv, grade_number__c, or assignment weighting on grade ' + g.ID);
				system.debug('addError - An error occurred when attempting to set the wgv, grade_number__c, or assignment weighting on grade: ' + g);
			}
		}
	}
	
	public static void isAfterUpdate(Map<ID, Grade__c> oMap, Map<ID, Grade__c> nMap) {
		//this method's goal is to calculate the section grades and generate standard/strand grades.
		
		//sets the grade scales for section grade calculations
		if(gradeUtils.bCourseGradeScalesEmpty()) {
			gradeUtils.setCourseGradeScalesFromSObject(getCourseGradeScales(nMap.Values()));
		}
		
		//previous implementation assumes the concept of only passing one section at a time, this is no longer the case
		//for this enhancement.  What it used to do with the assumption is that it simplified the process of allowing
		//aggregate results to caluclate the section grades.  We will have to do this more manually in the code by
		//querying the grade records and organizing it appropriately to reporting period and student/section.  So we will
		//need a set of student/section and a set of reporting periods to pass to the method that will organize the information
		//and generate the section grades. 
		
		Set<ID> studentSections = new Set<ID>();
		Set<ID> parentReportingPeriods = new Set<ID>();
		Set<ID> students = new Set<ID>();
		Set<ID> standards = new Set<ID>();
		List<Grade__c> grades = new List<Grade__c>();

		for(Grade__c g : nMap.Values()) {
			//only want to update section grades where a grade has changed for it.
			if(bGradeChange(g, oMap.get(g.ID))) {
				grades.add(g);
				studentSections.add(g.Student_Section__c);
				parentReportingPeriods.add( g.Reporting_Period_Is__c? g.Reporting_Period_Parent__c: g.Reporting_Period_Parent_Parent__c );
				students.add(g.Student__c);
				if(g.Standard__c != null) {
					standards.add(g.Standard__c);
				}
			}		
		}
		parentReportingPeriods.remove(null);
		
		try {
			upsert gradeUtils.aggregateGrades(grades) Reference_ID__c;
			
			CT_gradebook_CalculationTypes.determineCalculationNow(students, standards, parentReportingPeriods);

			//should only be true when running a batch update which does not allow @future method calls - using the calculateGrades boolean to control
			if(!core_triggerUtils.calculateGrades) {
				CT_gradebook_CalculationTypes.triggerCalculateLater(students, standards, parentReportingPeriods);
			}
			else {
				CT_gradebook_CalculationTypes.calculateLater(students, standards, parentReportingPeriods, false);
			}
		}
		catch(Exception e) {
			//provide some form of error handling here
			system.debug('*~*~* e: ' + e);
		}
	}


//================================== Old static methods from Gradebook_ManageGradebook =========================================//
	
	public static void createSectionGradesForStudents (List<Section_ReportingPeriod__c> srpList) {
		Set <Id> sectionIds = new Set <Id>();
		Map <Id, Student_Section__c> ssMap = new Map <Id, Student_Section__c>();
		Map<String, Section_Grade__c> existingSectionGrades = new Map<String, Section_Grade__c>();
		Map<String, Section_Grade__c> upsertSectionGrades = new Map<String, Section_Grade__c>();
		for (Section_reportingPeriod__c srp: srpList){
			sectionIDs.add(srp.section__c);
		}
		
		if(!sectionIDs.isEmpty()) {	
			for (Student_Section__c ss: [SELECT id, Student__c, Section__c,
					(SELECT Id, Student_Section__c, Student_Section__r.Section__c, 
						Reference_ID__c, Time__c, Course_Weighting__c FROM Section_Grades__r) 
					FROM Student_Section__c WHERE Section__c IN :sectionIds]){
				ssMap.put(ss.id, ss);
				for(Section_Grade__c sg :ss.Section_Grades__r){
					existingSectionGrades.put(sg.Reference_Id__c, sg);
				}
			}

			if(!ssMap.isEmpty()){
		 		for(Section_ReportingPeriod__c srp : srpList) {
			 		for(Student_Section__c ss : ssMap.Values()) {
			 			if(ss.Section__c == srp.Section__c){
				 			//Key, get the rp from the srp
				 			String key = string.valueOf(ss.ID) + '-' + string.valueOf(srp.Time__c);
				 			if(!existingSectionGrades.containsKey(key)) {
				 				upsertSectionGrades.put(key, createSectionGrade(ss.ID, srp));
				 			}
				 		}
			 		}
		 		}

		 		upsert upsertSectionGrades.Values() Reference_ID__c;
			}
	 	}
	}
	
	public static void createSectionGradesForStudents (Map<ID, Student_Section__c> studentSections) {
		//have to make an assumption that srps are properly created for the section.
		//if I don't then there's no way of determining what rps were scheduled for the section
		//To note, srp are generated during scheduling (assumption and from my knowledge)
		
		//?? question, why not populate the course_weighting__c??? seems important
		
 		Map<String, Section_Grade__c> existingSectionGrades = new Map<String, Section_Grade__c>();
 		Map<String, Section_ReportingPeriod__c> sectionReportingPeriods = new Map<String, Section_ReportingPeriod__c>();
 		Set<ID> sections = new Set<ID>();	
 		Map<String, Section_Grade__c> upsertSectionGrades = new Map<String, Section_Grade__c>();
 		
 		for(Student_Section__c ss : studentSections.Values()) {
 			sections.add(ss.Section__c);	
 		}
 		
 		if(!sections.isEmpty()) {
	 		for(Section__c s: [SELECT Id, 
	 					(SELECT ID, Student_Section__c, Student_Section__r.Section__c, Reference_ID__c, Time__c, Course_Weighting__c 
	 						FROM Section_Grades__r WHERE Student_Section__c IN: studentSections.KeySet()),
	 					(SELECT ID, Course_Weighting__c, Time__c, Section__c, ReferenceId__c 
	 						FROM Section_ReportingPeriod__r )
	 				FROM Section__c WHERE Id IN :sections]){
		 		//generate existingSectionGrades
		 		//String key = studentSection + '-' + Time__c
		 		for(Section_Grade__c sg: s.Section_Grades__r) {
		 			existingSectionGrades.put(sg.Reference_Id__c, sg);
		 		}
		 		//query for the sectio reporting periods
		 		//String Key = Section + '-' + time
		 		for(Section_ReportingPeriod__c srp: s.Section_ReportingPeriod__r) {
		 			sectionReportingPeriods.put(srp.ReferenceID__c, srp);
		 		}
	 		}

	 		
	 		for(Section_ReportingPeriod__c srp : sectionReportingPeriods.Values()) {
		 		for(Student_Section__c ss : studentSections.Values()) {
		 			if(ss.Section__c == srp.Section__c){
			 			//Key, get the rp from the srp
			 			String key = string.valueOf(ss.ID) + '-' + string.valueOf(srp.Time__c);
			 			if(!existingSectionGrades.containsKey(key)) {
			 				upsertSectionGrades.put(key, createSectionGrade(ss.ID, srp));
			 			}
			 		}
		 		}
	 		}
	 		
	 		upsert upsertSectionGrades.Values() Reference_ID__c;
 		}
	}	

//================================== From original Gradebook_ManageGradebook ===================================================//
//Note: If it's not broken don't fix it.  So far there are no complains of this feature not working.  leave the code intact.
//3/31/2014:  Correction, Need modification because of the change in standard/strand grade relationship and keys

	//use to generate the necessary sets of ID's needed, needs to waste a single query here.
	//use assignment grades to determine what is needed for deletion, do not rely on the assignment!
	public static void isBeforeDelete(Map<ID, Grade__c> oMap, Map<ID, Grade__c> nMap) {
		Set<ID> grades = new Set<ID>();
		Set<ID>	students = new Set<ID>();
		Set<ID> standards = new Set<ID>();
		Set<ID> strands = new Set<ID>();
		Set<ID> reportingPeriods = new Set<ID>();
		Set<ID> sections = new Set<ID>();
		Set<ID> studentSections = new Set<ID>();
		
		Set<String> sectionGradeKeys = new Set<String>();
		Set<String> standardGradeKeys = new Set<String>();
		Set<String> strandGradeKeys = new Set<String>();
		
		for(Grade__c g :oMap.values()) {
			grades.add(g.ID);
			students.add(g.Student__c);
			reportingPeriods.add(g.Time__c);
			if(g.Student_Section__c != null) {
				sections.add(g.Section__c);
				studentSections.add(g.Student_Section__c);
				sectionGradeKeys.add(string.valueOf(g.Student_Section__c) + '-' + string.valueOf(g.Time__c));
			}
			if(g.Standard__c != null) {
				standards.add(g.Standard__c);
				standardGradeKeys.add(string.valueOf(g.Student__c) + string.valueOf(g.Standard__c) + string.valueOf(g.Time__c));
				if(g.Standard__r.Strand__c != null) {
					strands.add(g.Standard_Strand__c);
					strandGradeKeys.add(string.valueOf(g.Student__c) + string.valueOf(g.Standard_Strand__c) + string.valueOf(g.Time__c));
				}
			}
		}
		
		if(!strands.isEmpty()) {
			deleteStrandGrades(students, strands, reportingPeriods, grades, strandGradeKeys);
		}
		
		if(!standards.isEmpty()) {
			deleteStandardGrades(students, standards, reportingPeriods, grades, standardGradeKeys);
			if(!sections.isEmpty()) {
				deleteSectionStandards(sections, standards, grades);
			}
		}
		
		//always check and do
		deleteSectionGrades(studentSections, reportingPeriods, grades, sectionGradeKeys);
	}
	
	//recalculate grades
	public static void isAfterDelete(Map<ID, Grade__c> oMap, Map<ID, Grade__c> nMap) {
		//sets the grade scales for section grade calculations
		if(gradeUtils.bCourseGradeScalesEmpty()) {
			gradeUtils.setCourseGradeScalesFromSObject(getCourseGradeScales(oMap.Values()));
		}
		
		Set<ID> studentSections = new Set<ID>();
		Set<ID> parentReportingPeriods = new Set<ID>();
		Set<ID> students = new Set<ID>();
		Set<ID> standards = new Set<ID>();
		
		for(Grade__c g : oMap.Values()) {
			studentSections.add(g.Student_Section__c);
			parentReportingPeriods.add( g.Reporting_Period_Is__c? g.Reporting_Period_Parent__c: g.Reporting_Period_Parent_Parent__c );
			students.add(g.Student__c);
			if(g.Standard__c != null) {
				standards.add(g.Standard__c);
			}
		}
		parentReportingPeriods.remove(null);
		
		try {
			//upsert gradeUtils.aggregateGrades(oMap.Values()) Reference_ID__c;
			
			CT_gradebook_CalculationTypes.determineCalculationNow(students, standards, parentReportingPeriods);
			
			//should only be true when running a batch update which does not allow @future method calls - using the calculateGrades boolean to control
			if(!core_triggerUtils.calculateGrades) {
				CT_gradebook_CalculationTypes.triggerCalculateLater(students, standards, parentReportingPeriods);
			}
			else {
				//it's batched and should call the calculateLater method
				CT_gradebook_CalculationTypes.calculateLater(students, standards, parentReportingPeriods, false);
			}
		}
		catch(Exception e) {
			//provide some form of error handling here
			system.debug('*~*~* e: ' + e);
		}			
	}
	
	//requires key generation: studentSection + '-' + reportingPeriod; Note this is the Reference_ID__c, there is a key but it is not always populated
	//reminder that this is the case to delete the SectionGrades when the grade record is the last grade record for that SectionGrade.
	public static void deleteSectionGrades(Set<ID> ssIDs, Set<ID> rpIDs, Set<ID> gIDs, Set<String> allKeys) {
		Map<String, Section_Grade__c> deleteSectionGrades = new Map<String, Section_Grade__c>();
		Set<String>	doNotDelete = new Set<String>();
		
		
		//if there are aggregate results, do not delete them!
		for(Grade__c g : [SELECT ID, Student_Section__c, Time__c FROM Grade__c WHERE Student_Section__c IN: ssIDs AND Time__c IN: rpIDs ORDER BY Student_Section__c, Time__c]) {
			if(!gIDs.contains(g.ID)) {
				String key = string.valueOf(g.Student_Section__c) + '-' + string.valueOf(g.Time__c);
				doNotDelete.add(key);
			}
		}
		
		//exclude overridden
		allKeys.removeAll(doNotDelete);
		if(allKeys.size() > 0) {
			for(Section_Grade__c sg : [Select ID, Reference_ID__c FROM Section_Grade__c WHERE Reference_ID__c IN: allKeys AND Grade_Overridden__c = FALSE]) {
				deleteSectionGrades.put(sg.Reference_ID__c, sg);
			}
			
			if(!deleteSectionGrades.isEmpty()) {
				delete deleteSectionGrades.Values();
			}
		}
	}
	
	//requires key generation: student + standard + reportingPeriod
	//reminder that this is the case to delete the StandardGrades when the grade record is the last grade record for that StandardGrade.
	public static void deleteStandardGrades(Set<Id> sIDs, Set<ID> standardIDs, Set<ID> rpIDs, Set<ID> gIDs, Set<String> allKeys) {
		Map<String, Standard_Grade__c> deleteStandardGrades = new Map<String, Standard_Grade__c>();
		Set<String> doNotDelete = new Set<String>();

		//if there are records do not delete them!
		for(Grade__c g : [SELECT ID, Student__c, Standard__c, Time__c FROM Grade__c WHERE Student__c IN: sIDs AND Standard__c IN: standardIDs AND Time__c IN: rpIDs ORDER BY Student__c, Standard__c, Time__c]) {
			if(!gIDs.contains(g.ID)) {
				String key = string.valueOf(g.Student__c) + string.valueOf(g.Standard__c) + string.valueOf(g.Time__c);
				doNotDelete.add(key);
			}
		}
		
		//exclude overridden
		allKeys.removeAll(doNotDelete);
		if(allKeys.size() > 0) {
			for(Standard_Grade__c sg : [Select ID, Key__c FROM Standard_Grade__c WHERE Key__c IN: allKeys AND Grade_Overridden__c = FALSE]) {
				deleteStandardGrades.put(sg.Key__c, sg);
			}
			
			if(!deleteStandardGrades.isEmpty()) {
				delete deleteStandardGrades.Values();
			}
		}
	}
	
	//requires key generation: student + strand + reportingPeriod
	//reminder that this is the case to delete the strandGrades when the grade record is the last grade for the StrandGrade.
	public static void deleteStrandGrades(Set<ID> sIDs, Set<ID> strandIDs, Set<ID> rpIDs, Set<ID> gIDs, Set<String> allKeys) {
		Map<String, Strand_Grade__c> deleteStrandGrades = new Map<String, Strand_Grade__c>();
		Set<String> doNotDelete = new Set<String>();

		//if there are records do not delete them!
		for(Grade__c g : [SELECT ID, Student__c, Standard__r.Strand__c, Time__c FROM Grade__c WHERE Student__c IN: sIDs AND Standard__r.Strand__c IN: strandIDs AND Time__c IN: rpIDs ORDER BY Student__c, Strand_Grade__r.Strand__c, Time__c]) {
			if(!gIDs.contains(g.ID)) {
				String key = string.valueOf(g.Student__c) + string.valueOf(g.Standard__r.Strand__c) + string.valueOf(g.Time__c);
				doNotDelete.add(key);
			}
			else {
				system.debug('*~*~* found grade not deleted yet in before deletion');
			}
		}
		
		system.debug('*~*~* allKeys: ' + allKeys);
		system.debug('*~*~* doNotDelete: ' + doNotDelete);
		
		//exclude the section grades that are overridden
		allKeys.removeAll(doNotDelete);
		if(allKeys.size() > 0) {
			system.debug('*~*~* allKeys post removeAll: ' + allKeys.size());
			for(Strand_Grade__c sg : [Select ID, Key__c FROM Strand_Grade__c WHERE Key__c IN: allKeys AND Grade_Overridden__c = FALSE]) {
				deleteStrandGrades.put(sg.Key__c, sg);
			}
			
			if(!deleteStrandGrades.isEmpty()) {
				delete deleteStrandGrades.Values();
			}
		}
	}
	
	//these records get inserted upon assignment insertion
	public static void deleteSectionStandards(Set<ID> sectionIDs, Set<ID> standardIDs, Set<ID> gIDs) {
		List<Section_Standard__c> deleteSectionStandards = new List<Section_Standard__c>();
		Set<ID> getSections = new Set<ID>();
		Set<ID> getStandards = new Set<ID>();
		
		//if there are records do not delete them!
		for(Grade__c g : [SELECT ID, Student_Section__r.Section__c, Standard__c FROM Grade__c WHERE Student_Section__r.Section__c IN: sectionIDs AND Standard__c IN: standardIDs ORDER BY Student_Section__r.Section__c, Standard__c]) {
			if(!gIDs.contains(g.ID)) {
				getSections.add(g.Student_Section__r.Section__c);
				getStandards.add(g.Standard__c);
			}
		}
		
		//exclude the section grades that are overridden
		if(sectionIDs.removeAll(getSections) && standardIDs.removeAll(getStandards)) {
			for(Section_Standard__c ss : [Select ID, Section__c, Standard__c FROM Section_Standard__c WHERE Section__c IN: sectionIDs AND Standard__c IN: standardIDs]) {
				deleteSectionStandards.add(ss);
			}
			
			if(deleteSectionStandards.size() > 0) {
				delete deleteSectionStandards;
			}
		}
	}

	
	//Summer 2014 - iteration 2: no time to fix this.  Hard to fix due to the relationship of standard grades, faux grades to assignments.  
	//really not part of the iteration.
	public static void isafterinsert_onss(Map<Id, Student_Section__c> newssmap, Map<Id, Student_Section__c> oldssmap ) {
		try{
		    Set<String> existingGradeKey = new Set<String>();
		    Set<String> gradeDeDupe = new Set<String>();
		    Set<String> studentIDs = new Set<String>();
		    Set<String> sIDs = new Set<String>();
		    List<Grade__c> gradesToInsert = new List<Grade__c>(); 
			Map<String, List<Grade__c>> sectionToGradeListMap = new Map<String, List<Grade__c>>();//its a map of lists, not a list

		    //build a list of sections to grab grades from
		    for(Student_Section__c ss: newssmap.values()){
		        sIDs.add(ss.Student__c);
		        if(ss.Active__c == true && ss.Is_Section__c == true && ss.Section_RT__c == 'Published'){
		        	studentIDs.add(ss.Student__c);
		        }
		    }

		    //Summer 2014: iteration 2 - no point in going forward.  Save on SOQL Limitation		    
		    for(Grade__c g: [SELECT Id, Standards_Only_Grading__c,
                                    Strand_Grade__c,
                                    Strand_Grade__r.Strand__c,
                                    Exclude_From_Section_Grade__c,
                                    Standard_Gradebook_Grade__c,
                                    Student__c,
                                    Student_section__c,
                                    Student_Section__r.Section__c, 
                                    Student_Section__r.Active__c,
                                    Course__c,
                                    Time__c,
                                    Time__r.Parent_Time_Element__c, 
                                    Time__r.Picklist_Value__r.Name, 
                                    Assignment__c,
                                    Assignment__r.Name,
                                    Assignment__r.Include_In_Final_Grade__c,
                                    Assignment_Weighting__c, 
                                    Standard__c, 
                                    Standard_Weighting__c,
                                    Standard_Times_Assignment__c,
                                    Possible_Points__c,
                                    Assignment__r.Section__r.Course__c,
                                    Include_In_Standard_Grade__c,
                                    Locked_for_Final__c,
                                    Entered_Grade__c
                                    FROM Grade__c WHERE (Student__c IN :studentIDs AND Student_Section__r.Active__c = true) 
                                    	OR Student_section__c IN :newssmap.keyset()]){
		    	
		    	if(studentIDs.contains(g.Student__c) && g.Student_Section__r.Active__c){
			    	//by using a key of AssignmentID + StandardID OR 'Null' + 'TRUE'(if there is a grade lookup) OR 'FALSE' (no grade lookup) 
			    	//we ensure that no duplicate grades are created, we need the standardID/standard_gradebook_grade field check in order 
			    	//added && Assignment__c != null to keep null lookup grades to duplicate and break gradebooks - JW 1/30
			    	//to have a unique list that contains all the grades/grades with standards/standards-only gradebook clones for each student added
			    	String standardNullProtection = g.Standard__c==null? 'null': String.valueOf(g.Standard__c);			    	
			    	String keyDeDupe = String.valueOf(g.Assignment__c) + standardNullProtection + String.valueOf(g.standard_gradebook_Grade__c==null);
			    	if((!gradeDeDupe.contains(keyDeDupe)) && g.Assignment__c!=null){                                      
				        if(sectionToGradeListMap.containsKey(g.Student_Section__r.Section__c)){
				            sectionToGradeListMap.get(g.Student_Section__r.Section__c).add(g); 
				        }
				        else{
				            sectionToGradeListMap.put(g.Student_Section__r.Section__c, new List<Grade__c>{g});
				        }
				        gradeDeDupe.add(keyDeDupe);
			    	}
		    	}
		    	if(newssmap.containsKey(g.Student_section__c)){
		    		//make sure we don't make existing grades over again   		
		 			existingGradeKey.add(string.valueOf(g.Student_Section__c) + string.valueOf(g.Assignment__c) + string.valueOf(g.Standard__c));
		    	}		        
		    }
			    
		    if(sectionToGradeListMap.keyset().size()>0){
		        Map<String, Strand_Grade__c> strandMap  = new Map<String, Strand_Grade__c>();
		        Map<String, Standard_Grade__c> standardMap = new Map<String, Standard_Grade__c>();
		        
		        //Summer 2014: iteration 2/3 - uniform key!  strand Grade key is: student + strand + reporting period, or the Key
		        for(Student__c s: [SELECT Id, 
		        			(SELECT Id, Strand__c, Reporting_Period__c, Student__c, Key__c FROM Strand_Grades__r), 
		        			(SELECT Id, Standard__c, Student__c, Reporting_Period__c, Key__c FROM Standard_Grades__r WHERE Standard__c != null) 
		        		FROM Student__c WHERE Id IN :sIDs]){
			        for(Strand_Grade__c sg: s.Strand_Grades__r){
			        	//generate the key just in case
			        	String key = string.valueOf(sg.Student__c) + string.valueOf(sg.Strand__c) + string.valueOf(sg.Reporting_Period__c);
			            strandMap.put(key, sg);
			        }
		            for(Standard_Grade__c sg: s.Standard_Grades__r){
		                String key = string.valueOf(sg.Student__c) + string.valueOf(sg.Standard__c) + string.valueOf(sg.Reporting_Period__c);
		                standardMap.put(key, sg);
		            }
		        }

		        List<Strand_Grade__c> strandgradestoupsert = new List<Strand_Grade__c>();
		        for(Student_Section__c ss: newssmap.values()){
		            if(sectionToGradeListMap.get(ss.section__c)!=null){
		                for(Grade__c g: sectionToGradeListMap.get(ss.section__c)){
		                	String key = string.valueOf(ss.Student__c) + string.valueOf(g.Strand_Grade__r.Strand__c) + string.valueOf(g.Time__c);
		                    if((!Strandmap.keyset().contains(key)) && (g.Strand_Grade__r.Strand__c!=null)) {
		                        Strand_Grade__c temp = new Strand_Grade__c(Strand__c = g.Strand_Grade__r.Strand__c, Student__c = ss.student__c, Reporting_Period__c = g.Time__c, Key__c = key);
		                        Strandmap.put(string.valueOf(temp.Student__c)+string.valueOf(temp.Strand__c)+string.valueOf(g.Time__c), temp);
		                        strandgradestoupsert.add(temp);
		                    }
		                }
		            }
		        } 
		        List<Standard_Grade__c> standardgradestoupsert = new List<Standard_Grade__c>();
		        for(Student_Section__c ss: newssmap.values()) {
		            if(sectionToGradeListMap.get(ss.section__c)!=null) {
		                for(Grade__c g: sectionToGradeListMap.get(ss.section__c)) {
		                	if(ss.Student__c != null && g.Standard__c != null && g.Time__c != null) {
			                	String key = string.valueOf(ss.Student__c) + string.valueOf(g.Standard__c) + string.valueOf(g.Time__c);
			                    if(!standardMap.keyset().contains(key)) {
			                        Standard_Grade__c temp = new Standard_Grade__c(Standard__c = g.Standard__c, Student__c = ss.Student__c, Key__c = key, Reporting_Period__c = g.Time__c);
			                        standardMap.put(key, temp);
			                        standardgradestoupsert.add(temp);
			                    }
		                	}
		                }
		            }
		        }
		        try{
		            insert strandgradestoupsert;
		            insert standardgradestoupsert;
		        }
		        catch (Exception e) {
				    Global_Error__c ge = Error_Handling.handleError('', 'Gradebook', 'Strand grades failure for new student section', e);
				    newssmap.values()[0].addError('There was a problem updating grades for the student. Please check your data before trying again.');
					insert ge;
		    	}
		    
		        String course;
		        String timeID;
		        boolean finalRepPeriod;
		        for(Student_Section__c ss: newssmap.values()){
		            if(sectionToGradeListMap.get(ss.section__c)!=null){
		                
		                    for(Grade__c g: sectionToGradeListMap.get(ss.section__c)){
		                            if((!existingGradeKey.contains(string.valueOf(ss.id)+string.valueOf(g.assignment__c)+string.valueOf(g.Standard__c)))&&(g.Standard_Gradebook_Grade__c==null)&&(g.Assignment__c!=null)){
		                            Grade__c temp = new Grade__c();
		                            temp.Standards_Only_Grading__c = g.Standards_Only_Grading__c;
		                            
		                            //DE3676
		                            temp.exclude_From_Section_Grade__c = !g.Assignment__r.Include_In_Final_Grade__c;
		                            temp.Course__c = g.Course__c;
		                            temp.Time__c = g.Time__c;
		                            finalRepPeriod = (g.Time__r.Picklist_Value__r.Name=='Final');
		                            temp.Assignment__c = g.Assignment__c;
		                            temp.Assignment_Weighting__c = g.Assignment_Weighting__c;
		                            temp.standard__c = g.Standard__c;
		                            temp.Standard_Weighting__c = g.Standard_Weighting__c;
		                            temp.Standard_Times_Assignment__c = g.Standard_Times_Assignment__c;
		                            temp.Possible_Points__c = g.Possible_Points__c;
		                            temp.Student_Section__c = ss.id;
		                            temp.Student__c = ss.Student__c;
		                            temp.entered_Grade__c = null;
		                            temp.Include_In_Standard_Grade__c = g.Include_In_Standard_Grade__c;
									if(g.Locked_for_Final__c && g.Entered_Grade__c == 'N/A') {
										temp.Locked_for_Final__c = true;
										temp.Entered_Grade__c = 'N/A';
									}
		                            gradesToInsert.add(temp);
		                            course = g.Course__c;
		                            timeID = g.time__c;
		                    }
		                }
		            }
		        }
		        
		        try{
		        	system.debug(gradesToInsert.size());
		            insert gradesToInsert;
		            if(core_TriggerUtils.setupBaseInfo().activeSetup.Standards_ONLY_Gradebook__c){
		            	List<Grade__c> fauxGradesToInsert = new List<Grade__c>();
			            for(Grade__c g: gradesToInsert){
			            	if(g.Standard__c!=null){
			            		fauxGradesToInsert.add(new Grade__c(Standards_Only_Grading__c = true,  Entered_Grade__c = g.Entered_Grade__c, 
		                											Standard_Times_Assignment__c = g.Standard_Times_Assignment__c,
		                											Student__c = g.Student__c, 
		                											Course__c = g.Course__c,
		                											Time__c = g.Time__c,
		                											Locked_For_Final__c = g.Locked_For_Final__c, 
		                											Assignment__c = g.Assignment__c,  
		                											Student_Section__c = g.Student_Section__c, 
		                											Assignment_Weighting__c = g.Assignment_Weighting__c, 
		                											Standard_Gradebook_Grade__c = g.id,
		                											Faux_Grade__c = true,
		                											Possible_Points__c = g.Possible_Points__c,
		                											exclude_From_Section_Grade__c = g.exclude_From_Section_Grade__c
		                											));
			            	}
		            	}
		            	insert fauxGradesToInsert;
		            }
		        }
		        catch (Exception e) {
				    	Global_Error__c ge = Error_Handling.handleError('', 'Gradebook', 'Grade insert failure for new student section', e);
				    	newssmap.values()[0].addError('There was a problem updating grades for the student. Please check your data before trying again.');
						insert ge;
		        }
		    }
		    
		}
	    catch (Exception e) {
			    Global_Error__c ge = Error_Handling.handleError('', 'Gradebook', 'Grade insert failure for new student section', e);
			    newssmap.values()[0].addError('There was a problem updating grades for the student. Please check your data before trying again.');
				insert ge;
		}	
	}
}