public with sharing class Gradebook_AssignmentWrapper_v2 {
	
	//control options on assignment wrapper, these values should be set upon construction throught the assignment Controller
	public Boolean standardBased {get; set;}
	public Boolean standardOnly {get; set;}
	public Boolean addLibraryOnly {get; set;}
	
	public ID gradeScale {get; set;}
	public ID standardGradeScale {get; set;}
	
	//for quick create
	public ID assignmentID {get; set;}
	
	public Map<ID, ID> sectionToAssignmentIDs {get; set;}
	public String assignmentName {get; set;}
	public String gradebookName {get; set;}  //5 character limitation
	public String courseName {get; set;}
	public ID assignmentCourse {get; set;}
	
	//placed in the assignmentLibrary, expose it in the wrapper for easier usage
	public Assignment_Lib__c assignmentLibrary {get; set;}
	public ID assignmentType {get; set;}  //this value is a picklist value on the Default Assignment Weighting, that can be read from the assignmentLibrary
	public ID assignmentAssessmentType {get; set;}  //this is a NYC GB specific feature, No code references this in the product other than populating this list.
	public String assignmentShortDescription {get; set;}
	public String assignmentLongDescription {get; set;}
	
	//standard
	public List<Standard__c> assignmentStandards {get; set;}
	
	//Section Assignment Details
	public Integer assignmentWeighting {get; set;} 
	public String assignmentPossiblePoints {get; set;}
	public String mediaName {get; set;}  //need to understand exactly what this does
	public String mediaSource {get; set;}  //need to understand exactly what this does
	public String color {get; set;}
	public Boolean includeInFinalGrade {get; set;}  //alternatively this means include in Section Grade, this rolls up to the final grade
	public Boolean showInPortal {get; set;}
	public Boolean attachAssignment {get; set;}
	
	//make function calls to populate this
	//Section.ID -> ReportingPeriod
	//Section.ID -> DueDates
	//group.ID -> parentSection.ID
	//Section.ID -> Include in standard grade calculations
	public Map<ID, ID> sectionToReportingPeriods {get; set;}
	public Map<ID, Date> sectionToDueDate {get; set;}
	public Map<ID, ID> groupToParentSection {get; set;}
	public Map<ID, Boolean> standardToUse {get; set;}
	
	//Assignment Search feature will be housed here...
	public String assignmentNameSearch {get; set;}
	public String courseSearch {get; set;}  //housed in the assignmentController
	public String assignmentTypeSearch {get; set;}  //housed in the assignmentController
	public String createdBySearch {get; set;}
	
	public ID searchAssignmentSelected {get; set;}
	public List<Assignment_Lib__c> searchAssignmentResults {get; set;}
	
	//Assignment Search result states
	public Boolean showAssignmentResults {get; set;}
	public Boolean noResults {get; set;}
	public Boolean over50 {get; set;}
	
	//empty constructor
	public Gradebook_AssignmentWrapper_v2() {
		initialize();
	}
	
	//the constructor that should be used most often
	public Gradebook_AssignmentWrapper_v2(Boolean SB, Boolean SO) {
		standardBased = SB;
		standardOnly = SO;
		initialize();
	}
	
	private void initialize() {
		//at a minimum initialize the maps
		assignmentLibrary = new Assignment_Lib__c();
		sectionToReportingPeriods = new Map<ID, ID>();
		sectionToDueDate = new Map<ID, Date>();
		groupToParentSection = new Map<ID, ID>();
		standardToUse = new Map<ID, Boolean>();
		assignmentStandards = new List<Standard__c>();
		sectionToAssignmentIDs = new Map<ID, ID>();
		
		//initialization logic that always should seem true???
		includeInFinalGrade = true;
		showInPortal = true;
		
		//Assignment Search
		searchAssignmentResults = new List<Assignment_Lib__c>();
		showAssignmentResults = false;
		noResults = true;
		over50 = false;
	}
	
	//should add to assignmentStandards before making this call
	public void createAssignmentLibrary() {
		assignmentLibrary.Name = assignmentName;
		assignmentLibrary.Picklist_Value__c = assignmentType;
		assignmentLibrary.Course__c = assignmentCourse;
		assignmentLibrary.Description__c = assignmentShortDescription;
		assignmentLibrary.Assignment_Description__c = assignmentLongDescription;
		//need to set assignment_standard__c records
		insert assignmentLibrary;
		List<Assignment_Standard__c> insertStandards = new List<Assignment_Standard__c>();
		for(Standard__c standard : assignmentStandards) {
			insertStandards.add(new Assignment_Standard__c(Assignment_Library__c = assignmentLibrary.ID, Standard__c = standard.ID));
		}
		insert insertStandards;
	}
	
	public void createNewLibraryFromExisting() {
		Assignment_Lib__c newLibrary = new Assignment_Lib__c();
		newLibrary.Name = assignmentLibrary.Name;
		newLibrary.Picklist_Value__c = assignmentLibrary.Picklist_Value__c;
		newLibrary.Course__c = assignmentLibrary.Course__c;
		newLibrary.Description__c = assignmentLibrary.Description__c;
		newLibrary.Assignment_Description__c = assignmentLibrary.Assignment_Description__c;
		//need to set assignment_standard__c records
		insert newLibrary;
		List<Assignment_Standard__c> insertStandards = new List<Assignment_Standard__c>();
		for(Standard__c standard : assignmentStandards) {
			insertStandards.add(new Assignment_Standard__c(Assignment_Library__c = newLibrary.ID, Standard__c = standard.ID));
		}
		insert insertStandards;		
	}
	
	public void createAssignments() {
		Map<ID, Assignment__c> assignments = new Map<ID, Assignment__c>();
		
		if(assignmentWeighting == null) {
			assignmentWeighting = 1;
		}
		
		//doesn't matter which key set, just use one of them
		for(ID section : sectionToDueDate.KeySet()) {
			Assignment__c newAssignment = new Assignment__c();
			//the same for all assignments
			newAssignment.Name = assignmentName;
			newAssignment.Name_in_Gradebook__c = gradebookName;
			newAssignment.Assignment_Library__c = assignmentLibrary.ID;
			newAssignment.Color__c = color;
			newAssignment.Description__c = assignmentShortDescription;
			newAssignment.Assignment_Description__c = assignmentLongDescription;
			newAssignment.Media_Name__c = mediaName;
			newAssignment.Media_Source__c = mediaSource;
			newAssignment.Show_in_portal__c = showInPortal;
			newAssignment.Include_in_Final_Grade__c = includeInFinalGrade;
			newAssignment.Picklist_Value__c = gradeScale;
			newAssignment.Standard_Scale__c = standardGradeScale;
			newAssignment.Weighting_Value__c = assignmentWeighting;
			if(String.isNotEmpty(assignmentPossiblePoints)) {
				newAssignment.Possible_Points__c = Integer.valueOf(assignmentPossiblePoints);
			}
			//what's unique about each one...
			if(groupToParentSection.containsKey(section)) {
				//if group, give parent section instead
				newAssignment.Section__c = groupToParentSection.get(section);
			}
			else {
				newAssignment.Section__c = section;
			}
			
			newAssignment.Due_Date__c = sectionToDueDate.get(section);
			newAssignment.Time__c = sectionToReportingPeriods.get(section);
			assignments.put(section, newAssignment);  //keep track for what section it is assoicated to
		}
		
		//insert the new assignments
		insert assignments.Values();
		assignmentID = assignments.Values()[0].ID;
		for(ID section : assignments.KeySet()) {
			if(assignments.containsKey(section)) {
				sectionToAssignmentIDs.put(section, assignments.get(section).ID);
			}
		}
		
		
		Map<ID, Set<Student_Section__c>> sectionToStudentSections = new Map<ID, Set<Student_Section__c>>();  //eventually modified such that groups with point to parent student/section
		Map<Id, Set<Student_Section__c>> groupToNotInStudentSections = new Map<ID, Set<Student_Section__c>>();  //for that section, these student/section need grades
		Map<ID, Set<ID>> sectionToStudents = new Map<ID, Set<ID>>();  //contains all the section and groups
		Set<Student_Section__c> allStudents = new Set<Student_Section__c>();
		
		//helper containers
		Set<String> studentsInGroup = new Set<String>();
		Map<String, Student_Section__c> keyToStudentSections = new Map<String, Student_Section__c>();  //final map of replace groups student/section
		//where key is equal to group/section
		Map<ID, Set<ID>> groupToStudents = new Map<ID, Set<ID>>();  //just the group
		Map<ID, Set<ID>> parentSectionToGroups = new Map<ID, Set<ID>>();
		
		//first pass, the student sections that are from the sections (group and main sections)
		for(Student_Section__c ss : [SELECT ID, Student__c, Section__c, Section__r.Section__c, Section__r.Course__c FROM Student_Section__c WHERE Active__c = TRUE AND Student__r.Active__c = TRUE AND Section__c IN: sectionToDueDate.KeySet()]) {
			allStudents.add(ss);
			
			if(!sectionToStudentSections.containsKey(ss.Section__c)) {
				sectionToStudentSections.put(ss.Section__c, new Set<Student_Section__c>{ss});
			}
			else {
				sectionToStudentSections.get(ss.Section__c).add(ss);
			}
			
			//build parentSectionToGroups
			if(ss.Section__r.Section__c != null) {
				if(!parentSectionToGroups.containsKey(ss.Section__r.Section__c)) {
					parentSectionToGroups.put(ss.Section__r.Section__c, new Set<ID> {ss.Section__c});
				}
				else {
					parentSectionToGroups.get(ss.Section__r.Section__c).add(ss.Section__c);
				}
			}			
			
			//generate the list for passing to the methods
			String Key = string.valueOf(ss.Student__c) + string.valueOf(ss.Section__c);
			if(!sectionToStudents.containsKey(ss.Section__c)) {
				sectionToStudents.put(ss.Section__c, new Set<ID>{ss.Student__c});
				if(ss.Section__r.Section__c != null) {
					groupToStudents.put(ss.Section__c, new Set<ID>{ss.Student__c});
					studentsInGroup.add(Key);
				}
			}
			else {
				sectionToStudents.get(ss.Section__c).add(ss.Student__c);
				if(ss.Section__r.Section__c != null) {
					groupToStudents.get(ss.Section__c).add(ss.Student__c);		
					studentsInGroup.add(Key);
				}
			}
		}
		
		//get the parent studentSections for the groups
		for(Student_Section__c ss : [SELECT ID, Student__c, Section__c, Section__r.Section__c, Section__r.Course__c FROM Student_Section__c WHERE Active__c = TRUE AND Student__r.Active__c = TRUE AND Section__c IN: groupToParentSection.Values()]) {
			
			//in case the student belongs to multiple groups
			if(parentSectionToGroups.containsKey(ss.Section__c)) {
				for(ID grp : parentSectionToGroups.get(ss.Section__c)) {
				
					//String Key = string.valueOf(ss.Student__c) + string.valueOf(ss.Section__c);
					String Key = string.valueOf(ss.Student__c) + string.valueOf(grp);
					if(studentsInGroup.contains(Key)) {		
						if(!keyToStudentSections.containsKey(key)) {
							keyToStudentSections.put(key, ss);
						}
					}
					else {
						if(!groupToNotInStudentSections.containsKey(grp)) {
							groupToNotInStudentSections.put(grp, new Set<Student_Section__c>{ss});
						}
						else {
							groupToNotInStudentSections.get(grp).add(ss);
						}
					}
				}
			}
		}
		
		//generate the mapping between group->studentSection(parent studentSection), not the group's normal studentSection
		for(ID section : groupToStudents.KeySet()) {
			if(groupToParentSection.containsKey(section)) {
				Set<Student_Section__c> temp = new Set<Student_Section__c>();
				for(ID student : groupToStudents.get(section)) {
					//found it! 8/6/2013: built the key wrong here
					String key = string.valueOf(student) + string.valueOf(section);
					//String key = string.valueOf(student) + string.valueOf(groupToParentSection.get(section));
					if(keyToStudentSections.containsKey(key)) {
						temp.add(keyToStudentSections.get(key));
					}
				}
				//overwrite the original mapping
				sectionToStudentSections.put(section, temp);
			}
		}
		
		Map<String, Strand_Grade__c> keyToStrandGrade = new Map<String, Strand_Grade__c>();
		if(standardBased && standardOnly) {
			//ugh, insert the strand grades first... needs to be associated to the grade records later (if any)
			Set<Strand_Grade__c> upsertStrandGrades = new Set<Strand_Grade__c>();
			
			//first pass, just upsert the strandgrades...
			for(ID section : sectionToReportingPeriods.KeySet()) {
				upsertStrandGrades.addAll(createStrandGrades(sectionToReportingPeriods.get(section), sectionToStudents.get(section)));
			}
			if(upsertStrandGrades.size() > 0) {
				List<Strand_Grade__c> workAround = new List<Strand_Grade__c>();
				workAround.addAll(upsertStrandGrades);
				upsert workAround;
				
				//second pass, generate the map, key->strand_Grade__c
				for(Strand_Grade__c sg : upsertStrandGrades) {
					String key = string.valueOf(sg.Student__c) + string.valueOf(sg.Strand__c) + string.valueOf(sg.Reporting_Period__c);
					keyToStrandGrade.put(key, sg);
				}			
			}
		}
		
		if(standardBased) {
			//upsert the standard grades (if any)
			List<Standard_Grade__c> upsertStandardGrades = createStandardGrades(allStudents);
			if(upsertStandardGrades.size() > 0) {
				upsert upsertStandardGrades;
			}
		}
		
		//finally start creating the grades
		List<Grade__c> upsertGrades = new List<Grade__c>();
		for(ID section : sectionToStudentSections.KeySet()) {
			Set<Student_Section__c> temp = new Set<Student_Section__c>();
			if(groupToParentSection.containsKey(section)) {
				//get the subset of students of the group
				if(groupToNotInStudentSections.containsKey(section)) {
					temp = groupToNotInStudentSections.get(section);
				}
			}
			upsertGrades.addAll(createGrades(assignments.get(section), sectionToStudentSections.get(section), temp, keyToStrandGrade));
		}
		upsert upsertGrades;
		
		if(standardBased && standardOnly) {
			//crete faux grades...sigh
			List<Grade__c> upsertFauxGrades = new List<Grade__c>();
			for(Grade__c g : upsertGrades) {
				Grade__c fauxGrade = new Grade__c(
				Student__c = g.Student__c,
				Course__c = g.Course__c,
				Time__c = g.Time__c,
				Assignment__c = g.Assignment__c,
				Student_Section__c = g.Student_Section__c,
				Assignment_Weighting__c = g.Assignment_Weighting__c,
				Standard_Times_Assignment__c = g.Standard_Times_Assignment__c,
				exclude_From_Section_Grade__c = !includeInFinalGrade,
				Standards_Only_Grading__c = g.Standards_Only_Grading__c,
				Include_In_Standard_Grade__c = false,
				Entered_Grade__c = g.Entered_Grade__c,
				Locked_for_Final__c = g.Locked_for_Final__c,
				Standard_Gradebook_Grade__c = g.ID
				);
				upsertFauxGrades.add(fauxGrade);
			}
			upsert upsertFauxGrades;
		}	
	}
	
	//pull the reportingPeriod, assignmentID, section
	//notStudentSections is for the fake grades of groups
	private List<Grade__c> createGrades(Assignment__c assignment, Set<Student_Section__c> studentSections, Set<Student_Section__c> notStudentSections, Map<String, Strand_Grade__c> keyToStrandGrade) {
		List<Grade__c> returnList = new List<Grade__c>();
		
		if(standardBased && !standardOnly) {  //hybrid
			for(Student_Section__c ss : studentSections) {
				if(assignmentStandards.size() > 0) {
					for(Standard__c standard : assignmentStandards) {
						Grade__c newGrade = new Grade__c(
						Student__c = ss.Student__c,
						Course__c = ss.Section__r.Course__c,
						Time__c = assignment.Time__c,
						Assignment__c = assignment.ID,
						Student_Section__c = ss.ID,
						Assignment_Weighting__c = assignment.Weighting_Value__c,
						Standard_Times_Assignment__c = 1.0 * assignment.Weighting_Value__c,
						Standard__c = standard.ID,
						Include_In_Standard_Grade__c = standardToUse.get(standard.ID)
						);
						returnList.add(newGrade);
					}
				}
				//create the hybrid grade
				Grade__c newGrade = new Grade__c(
				Student__c = ss.Student__c,
				Course__c = ss.Section__r.Course__c,
				Time__c = assignment.Time__c,
				Assignment__c = assignment.ID,
				Student_Section__c = ss.ID,
				Assignment_Weighting__c = assignment.Weighting_Value__c,
				Standard_Times_Assignment__c = 1.0 * assignment.Weighting_Value__c,
				Possible_Points__c = assignment.Possible_Points__c,
				Include_In_Standard_Grade__c = false,
				Exclude_From_Section_Grade__c = !includeInFinalGrade
				);
				returnList.add(newGrade);		
			}
			//for students not in the group (fake grade)
			for(Student_Section__c ss : notStudentSections) {
				if(assignmentStandards.size() > 0) {
					for(Standard__c standard : assignmentStandards) {
						Grade__c newGrade = new Grade__c(
						Student__c = ss.Student__c,
						Course__c = ss.Section__r.Course__c,
						Time__c = assignment.Time__c,
						Assignment__c = assignment.ID,
						Student_Section__c = ss.ID,
						Assignment_Weighting__c = assignment.Weighting_Value__c,
						Standard_Times_Assignment__c = 1.0 * assignment.Weighting_Value__c,
						Standard__c = standard.ID,
						Include_In_Standard_Grade__c = false,
						Entered_Grade__c = 'N/A',
						Locked_for_Final__c = true
						);
						returnList.add(newGrade);
					}
				}				
				Grade__c newGrade = new Grade__c(
				Student__c = ss.Student__c,
				Course__c = ss.Section__r.Course__c,
				Time__c = assignment.Time__c,
				Assignment__c = assignment.ID,
				Student_Section__c = ss.ID,
				Assignment_Weighting__c = assignment.Weighting_Value__c,
				Standard_Times_Assignment__c = 1.0 * assignment.Weighting_Value__c,
				Possible_Points__c = assignment.Possible_Points__c,
				Include_In_Standard_Grade__c = false,
				Exclude_From_Section_Grade__c = !includeInFinalGrade,
				Entered_Grade__c = 'N/A',
				Locked_for_Final__c = true
				);
				returnList.add(newGrade);			
			}
		}
		else if(standardBased && standardOnly) {  //SO
			for(Student_Section__c ss : studentSections) {
				if(assignmentStandards.size() > 0) {
					for(Standard__c standard : assignmentStandards) {
						String key = string.valueOf(ss.Student__c) + string.valueOf(standard.Strand__c) + string.valueOf(assignment.Time__c);
						Grade__c newGrade = new Grade__c(
						exclude_From_Section_Grade__c = !includeInFinalGrade,
						Standards_Only_Grading__c = true,
						//Summer 2014: iteration 2 - System now does need this for strand grade calculations
						//Strand_Grade__c = keyToStrandGrade.get(key).ID,
						Student__c = ss.Student__c,
						Course__c = ss.Section__r.Course__c,
						Time__c = assignment.Time__c,
						Assignment__c = assignment.ID,
						Student_Section__c = ss.ID,
						Assignment_Weighting__c = assignment.Weighting_Value__c,
						Standard_Times_Assignment__c = 1.0 * assignment.Weighting_Value__c,
						Standard__c = standard.ID,
						Include_In_Standard_Grade__c = standardToUse.get(standard.ID)
						);
						returnList.add(newGrade);
					}
				}		
			}
			//for students not in the group (fake grade)
			for(Student_Section__c ss : notStudentSections) {
				if(assignmentStandards.size() > 0) {
					for(Standard__c standard : assignmentStandards) {
						String key = string.valueOf(ss.Student__c) + string.valueOf(standard.Strand__c) + string.valueOf(assignment.Time__c);
						Grade__c newGrade = new Grade__c(
						exclude_From_Section_Grade__c = false,
						Standards_Only_Grading__c = true,
						//Summer 2014: iteration 2 - System now does need this for strand grade calculations
						//Strand_Grade__c = keyToStrandGrade.get(key).ID,
						Student__c = ss.Student__c,
						Course__c = ss.Section__r.Course__c,
						Time__c = assignment.Time__c,
						Assignment__c = assignment.ID,
						Student_Section__c = ss.ID,
						Assignment_Weighting__c = assignment.Weighting_Value__c,
						Standard_Times_Assignment__c = 1.0 * assignment.Weighting_Value__c,
						Standard__c = standard.ID,
						Include_In_Standard_Grade__c = false,
						Entered_Grade__c = 'N/A',
						Locked_for_Final__c = true
						);
						//found another defect in correcting groups...
						if(keyToStrandGrade.containsKey(key)) {
							//newGrade.Strand_Grade__c = keyToStrandGrade.get(key).ID;
						}		
						returnList.add(newGrade);
					}
				}						
			}
		}
		else if(!standardBased && !standardOnly) {  //traditional
			for(Student_Section__c ss : studentSections) {
				//create the hybrid grade
				Grade__c newGrade = new Grade__c(
				Student__c = ss.Student__c,
				Course__c = ss.Section__r.Course__c,
				Time__c = assignment.Time__c,
				Assignment__c = assignment.ID,
				Student_Section__c = ss.ID,
				Assignment_Weighting__c = assignment.Weighting_Value__c,
				Standard_Times_Assignment__c = 1.0 * assignment.Weighting_Value__c,
				Possible_Points__c = assignment.Possible_Points__c,
				Include_In_Standard_Grade__c = false,
				Exclude_From_Section_Grade__c = !includeInFinalGrade
				);
				returnList.add(newGrade);		
			}
			//for students not in the group (fake grade)
			for(Student_Section__c ss : notStudentSections) {				
				Grade__c newGrade = new Grade__c(
				Student__c = ss.Student__c,
				Course__c = ss.Section__r.Course__c,
				Time__c = assignment.Time__c,
				Assignment__c = assignment.ID,
				Student_Section__c = ss.ID,
				Assignment_Weighting__c = assignment.Weighting_Value__c,
				Standard_Times_Assignment__c = 1.0 * assignment.Weighting_Value__c,
				Possible_Points__c = assignment.Possible_Points__c,
				Include_In_Standard_Grade__c = false,
				Entered_Grade__c = 'N/A',
				Locked_for_Final__c = true
				);
				returnList.add(newGrade);			
			}			
		}
		else {
			//problem
		}
		return returnList;
	}
	
	private List<Standard_Grade__c> createStandardGrades(Set<Student_Section__c> students) {
		//for each student
			//for each standard
				//check if the standard grade exists
					//if it does not, create the standard grade and insert it		
		
		Map<String, Standard_Grade__c> existingStandardGrades = new Map<String, Standard_Grade__c>();
		Map<String, Standard_Grade__c> insertMap = new Map<String, Standard_Grade__c>();
		
		Set<ID> tStudents = new Set<ID>();
		for(Student_Section__c ss : students) {
			tStudents.add(ss.Student__c);
		}
		
		for(Standard_Grade__c sg : [SELECT ID, Student__c, Standard__c, Reporting_Period__c FROM Standard_Grade__c WHERE Student__c IN: tStudents AND Standard__c IN: assignmentStandards AND Reporting_Period__c IN: sectionToReportingPeriods.Values() ]) {
			existingStandardGrades.put(string.valueOf(sg.Student__c) + string.valueOf(sg.Standard__c) + sg.Reporting_Period__c, sg);
		}
		for(Student_Section__c student : students) {
			for(Standard__c standard : assignmentStandards) {
				String key = string.valueOf(student.Student__c) + string.valueOf(standard.ID) + sectionToReportingPeriods.get(student.Section__c);
				if(!existingStandardGrades.containsKey(key)) {
					Standard_Grade__c insertSG = new Standard_Grade__c(Student__c = student.Student__c, Standard__c = standard.ID, Reporting_Period__c = sectionToReportingPeriods.get(student.Section__c), Key__c = key);
					insertMap.put(key,insertSG);
				}
			}
		}
		return insertMap.Values();
	}
	
	//Map studentID -> strandGradeID
	private List<Strand_Grade__c> createStrandGrades(ID reportingPeriod, Set<ID> students) {
		//Programmer Notes:
		//for each student
			//for each standard
				//check if the strand grade exists for this student + standard
					//if it does, add it to the returnMap,
					//else create the strandgrade and then put it into the returnMap		
		
		Map<String, Strand_Grade__c> existingStrandGrades = new Map<String, Strand_Grade__c>();
		Set<ID> Strands = new Set<ID>();
		for(Standard__c s : assignmentStandards) {
			if(s.Strand__c != null) {
				strands.add(s.Strand__c);
			}
		}
					
		for(Strand_Grade__c sg : [SELECT ID, Student__c, Strand__c, Reporting_Period__c FROM Strand_Grade__c WHERE Student__c IN: students AND Strand__c IN: Strands]) {
			existingStrandGrades.put(string.valueOf(sg.Student__c) + string.valueOf(sg.Strand__c) + string.valueOf(sg.Reporting_Period__c), sg);
		}
		
		for(ID student : students) {
			for(Standard__c standard : assignmentStandards) {
				//create key
				String key = string.valueOf(student) + string.valueOf(standard.Strand__c) + string.valueOf(reportingPeriod);
				if(!existingStrandGrades.containsKey(key)) {
					//create the strand grade
					Strand_Grade__c insertSG = new Strand_Grade__c(Key__c = key, Strand__c = standard.Strand__c, Student__c = student, Reporting_Period__c = reportingPeriod);
					existingStrandGrades.put(key, insertSG);
				}
			}
		}
		
		return existingStrandGrades.Values();
	}
	
	public void searchMethod() {
		String searchQuery = 'SELECT ID, Name, Picklist_Value__c, Picklist_Value__r.Name, Course__c, Course__r.Name, Description__c, Assignment_Description__c, Objective_Skill__c, Related_Outside_Source__c, Curriculum__c, Instructional_Approach__c, CreatedDate, CreatedBy.FirstName, CreatedBy.LastName, CreatedById FROM Assignment_Lib__c WHERE isdeleted = FALSE ';
		String whereClause = '';
		String searchWild = '';
		searchAssignmentResults.clear();
		
		//clear the fields
		try {
			assignmentName = null;
			gradebookName = null;
			assignmentType = null;
			assignmentCourse = null;
			assignmentWeighting = null;
			gradeScale = null;
			standardGradeScale = null;
			assignmentPossiblePoints = null;
			assignmentStandards = new List<Standard__c>();
		}
		catch(Exception e) {
			system.debug('*~*~* Failed to clear assignment fields');
		}
		
		//Programmer's Note: this needs to be fleshed out, it's very weak as an assignment Library tool...
		if(String.isNotEmpty(assignmentNameSearch)) {
			searchWild = '\'%' + string.escapeSingleQuotes(assignmentNameSearch) + '%\' ';
			searchWild.replace('*', '');
			whereClause += 'AND Name LIKE ' + searchWild + ' ';
		}
		
		if(courseSearch != 'All') {
			whereClause += 'AND Course__r.id = '+ '\'' + string.escapeSingleQuotes(courseSearch)  + '\' ';
		}
		
		if(assignmentTypeSearch != 'Any') {
			whereClause += 'AND Picklist_Value__c = ' + '\'' + string.escapeSingleQuotes(assignmentTypeSearch) + '\' ';
		}
		
		if(String.isNotEmpty(createdBySearch)) {
			searchWild = '\'' + string.escapeSingleQuotes(createdBySearch) + '%\' ';
			searchWild.replace('*', '');
			whereClause += 'AND CreatedBy.Name LIKE ' + searchWild + ' ';
		}
		
		system.debug('*~*~* final WHERE: ' + whereClause);
		string query = searchQuery + whereClause + ' LIMIT 50';
		
		try {
			searchAssignmentResults = Database.query(query);
			if(searchAssignmentResults.size() > 0) {
				noResults = false;
				showAssignmentResults = true;
			}
			else {
				noResults = true;
				showAssignmentResults = false;
			}
			if(searchAssignmentResults.size() == 50) {
				over50 = true;
			}
			else {
				over50 = false;
			}
		}
		catch(Exception e) {
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Failed assignment query search! ' + e.getMessage()));
		}
	}
	
	public void selectAssignmentMethod(ID assignmentLibraryID) {
		searchAssignmentSelected = assignmentLibraryID;
		try {
			Assignment_Lib__c tempLib = [SELECT ID, (SELECT ID, Standard__c FROM Assignment_Standards__r), Name, Picklist_Value__c, Course__c, Course__r.Name, Description__c, Assignment_Description__c, Curriculum__c, Instructional_Approach__c, Objective_Skill__c, Related_Outside_Source__c FROM Assignment_Lib__c WHERE ID =: searchAssignmentSelected];
			assignmentName = tempLib.Name;
			courseName = tempLib.Course__r.Name;
			assignmentCourse = tempLib.Course__c;
			assignmentLibrary = tempLib;
			
			//added this, was the only way this could be populated?
			assignmentLibrary.Curriculum__c = tempLib.Curriculum__c;
			assignmentLibrary.Instructional_Approach__c = tempLib.Instructional_Approach__c;
			assignmentLibrary.Objective_Skill__c = tempLib.Objective_Skill__c;
			assignmentLibrary.Related_Outside_Source__c = tempLib.Related_Outside_Source__c;
			
			assignmentType = tempLib.Picklist_Value__c;
			assignmentShortDescription = tempLib.Description__c;
			assignmentLongDescription = tempLIb.Assignment_Description__c;
			
			//generate a set of standardIDs to query for the actual Standard
			Set<ID> standardIDs = new Set<ID>();
			for(Assignment_Standard__c aStandard : tempLib.Assignment_Standards__r) {
				standardIDs.add(aStandard.Standard__c);
			}
			
			assignmentStandards = [SELECT Name, Citywide_Instructional_Expectation__c, Level__c, Long_Text__c, Attribute__c, Identifier__c, Id, Parent_Standard__c, Strand__c, Strand__r.Name, Subject__c, Course__c, Course__r.Name, Standard_Subject__c, Standard_Subject__r.Name FROM Standard__c WHERE ID IN: standardIDs];
		}
		catch(Exception e) {
			
		}
	}
}