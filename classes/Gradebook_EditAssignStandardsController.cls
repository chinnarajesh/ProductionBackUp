//Programmer's Notes:  the objective is to create a custom button on the assignment layout that redirects to a page 
//that will display all the standards associated to the previous page's assignment.  From that page, users will be 
//able to see the current standards, add new standards and delete standards available to them (standards with no 
//grades).  This controller will need to know the Id of the assignment, that way we query for the grades.  from 
//grades, we can get standards.  To make the connection a standard is associated to the an assignment, there needs 
//to be a grade object linking the assignment and the standard.

public without sharing class Gradebook_EditAssignStandardsController {
			
	//Wrapper class to help in selecting the standards in the page.
	public class standardWrapper {
		public Boolean selected {get; set;}
		public Boolean includeStandardGrade	{get; set;}
		public Boolean doNotTouch {get; set;}
		public Standard__c standard {get; set;}
		
		public standardWrapper(Standard__c s) {
			selected = false;
			includeStandardGrade = true;
			//as a requirement, standards with grades on assignments are not allowed to be removed.
			doNotTouch = false;
			standard = s;
		}
	}			
			
	public Assignment__c assignment  {get; set;}
	private List<Grade__c> grades {get; set;}
	private Set<ID> doNotTouchStandards {get; set;}	
	private Map<ID, Set<Grade__c>> standardIDToGrades {get; set;}
	private Map<ID, ID> studentToStudentSection {get; set;}
	
	private Map<ID, Boolean> standardGradeIncluded	{get; set;}
	
	//determine adding standard functionality
	//for standardonly gradebook, there must be a faux grade and a strand grade
	//where in hybrid, there's only a grades and standard grades to worry about 
	public Boolean StandardOnly {get; set;}
	
	//when creating a grade record
	public ID course {get; set;} 	
	private String courseGradeScale {get; set;}
	private String courseStandardScale {get; set;}
	private double STA {get; set;}		//short for standard Times Assignment
	private Boolean EFSG {get; set;}	//short for Exclude From Section Grade
	private decimal standardWeighting {get; set;}

	//testing assignment, used for page display
	public String assignmentName {get; set;}
	public List<standardWrapper> standardList {get; set;}
	public List<standardWrapper> generalList {get; set;}
	public List<standardWrapper> searchList {get; set;}
	
	//for search method
	public Boolean bLimitReached {get; set;}
	public Boolean bNoStandards {get; set;}
	public Boolean bNoStandardsSelected {get; set;}
	public String standardIdentifierSearch {get; set;}
	public String standardCourseSearch {get; set;}
	public String standardStrandSearch {get; set;}
	public String standardParentStandardSearch {get; set;}
	public String standardSubjectSearch {get; set;}
	
	//error messaging
	public Boolean noStandardScale {get; set;}
	
	//DE931: Standards Search Enhancement 
	public Boolean displayModal {get; set;}
	public Boolean displaySearchBar {get; set;}
	public Boolean displayAddButton {get; set;}
	public Boolean displaySearchResults {get; set;}
	
	//need a way to test majority of code, so created this constructor.
	public Gradebook_EditAssignStandardsController(ID assignmentID) {
		settingUp();
		initialize(assignmentID);
	}	
	
	//this is the constructor when there is no id provided... 
	public Gradebook_EditAssignStandardsController() {
		settingUp();		
		initialize(ApexPages.currentPage().getParameters().get('assignmentID'));
	}
	
	private void settingUp() {
		grades = new List<Grade__c>();
		doNotTouchStandards = new Set<ID>();		
		standardIDToGrades = new Map<ID, Set<Grade__c>>();
		studentToStudentSection = new Map<ID, ID>();
		standardGradeIncluded = new Map<ID, Boolean>();

		standardList = new List<standardWrapper>();
		generalList = new List<standardWrapper>();
		searchList = new List<standardWrapper>();
		
		bNoStandards = true;
		bNoStandardsSelected = false;
		noStandardScale = false;
			
		displayModal = false;
		displaySearchBar = false;
		displayAddButton = true;
		displaySearchResults = false;			
	}

	private void initialize(ID i) {
		//this query can be placed somewhere else later, but it's here for now
		assignment = [	SELECT Weighting_Value__c, Time__c, Time__r.Name__c, Standard_Scale__c, Standard_Scale__r.Name, Show_in_portal__c, 
						Section__c, Section__r.Name, Related_Outside_Source__c, Possible_Points__c, Picklist_Value__c, Picklist_Value__r.Name, 
						Objective_Skill__c, Name_in_Gradebook__c, Name, Media_Source__c, Section__r.School__c,
						Media_Name__c, Instructional_Approach__c, Include_in_Final_Grade__c, Id, 
						External_Id__c, Due_Date_for_Gradebook__c, Due_Date__c, Display_Code__c, 
						Description__c, Curriculum__c, Color__c, Assignment_Library__c, Assignment_Library__r.Name, Assignment_Description__c
						
						 FROM Assignment__c WHERE ID =: i LIMIT 1];

		Setup__c setup = core_SoqlUtils.getActiveSetups(new Set<ID>{assignment.Section__r.School__c}).get(assignment.Section__r.School__c);
		standardOnly = setup.Standards_ONLY_Gradebook__c;
		
		//populate the list of grades from assignment
		//EE 1/3 DE2708
		//Seems an issue came up in Spring 11 that hates nested queries like this
		//Not sure what the workaround is, so included a second query
		grades = [SELECT Id, Name, Assignment_Weighting__c, Assignment__c, Comment__c, Course__c, Course__r.grade_scale__c, Course__r.Grade_Scale_Lookup__c, Course__r.Grade_Scale_Lookup__r.Category__c, 
						 Entered_Grade__c, Grade_Number__c, Grading_Type__c, Locked_for_Final__c, Publish_Comment__c, Standard__c, Student_Section__c,
						 Student__c, Time__c, Weighted_Grade_Value__c, Possible_Points__c, Reporting_Period_Name__c, 
						 Standard_Gradebook_Grade__c, Standard_Times_Assignment__c, Standard_Weighting__c, Standards_Only_Grading__c, 
						 Strand_Grade__c, exclude_From_Section_Grade__c, External_Id__c, Faux_Grade__c, Grade_Update__c, 
						 Grade_With_Standard__c, Points_Grade__c, Valid_Grade__c, Include_In_Standard_Grade__c From Grade__c WHERE Student__r.Active__c = TRUE AND Assignment__c=:i];	
		assignmentName = assignment.Name;	
		
		for(Grade__c g : grades) {
			if(g.Standard__c != null) {			
				//generate the mapping between standards and grades
				if(!standardIDToGrades.containsKey(g.Standard__c)) {
					standardIDToGrades.put(g.Standard__c, new Set<Grade__c>{g});
				}
				else {
					standardIDToGrades.get(g.Standard__c).add(g);
				}
				
				//check the Entered Grade, if it is not empty or null, then you cannot delete the associated standard
				if(!(g.Entered_Grade__c == null || g.Entered_Grade__c == '' || g.Entered_Grade__c.equalsIgnoreCase('N/A'))) {
					if(!doNotTouchStandards.contains(g.Standard__c)) {
						doNotTouchStandards.add(g.Standard__c);
					}
				}
			}
			
			//populate the student to student/section mapping
			if(g.Student__c != null && g.Student_Section__c != null) {
				if(!studentToStudentSection.containsKey(g.Student__c)) {
					studentToStudentSection.put(g.Student__c, g.Student_Section__c);
				}
			}
			
			//these values should remain the same for similar grades
			if(course == null) {
				course = g.Course__c;
			}
			if(courseGradeScale == null) {
				if (g.course__r.Grade_Scale_Lookup__c!=null) courseGradeScale = g.course__r.Grade_Scale_Lookup__r.Category__c=='Standards'? 'Standard':'Default';
				else courseGradeScale = g.course__r.Grade_Scale__c;
			}
			if(STA == null) {
				STA = g.Standard_Times_Assignment__c;
			}
			if(EFSG == null) {
				EFSG = g.Exclude_From_Section_Grade__c;
			}
			if(standardWeighting == null) {
				standardWeighting = g.Standard_Weighting__c;
			} 
		}
		
		//after the grade set is created, check those grades for Include_In_Standard_Grade
		//make assumption that either all or none are checked, so check the first one
		for(ID t : standardIDToGrades.KeySet()) {
			for(Grade__c g : standardIDToGrades.get(t)) {
				standardGradeIncluded.put(g.Standard__c, g.Include_In_Standard_Grade__c);
				break;
			}
		}
		
		
		//populate the list of standardWrapper from the Grade set
		for(Standard__c standard : [SELECT Subject__c, Strand__c, Strand__r.Name, Standard_Subject__c, Parent_Standard__c, Name, 
									Long_Text__c, Level__c, Identifier__c, Id, Grade_Level__c, Description_Spanish__c, 
									Department__c, Course__c FROM Standard__c WHERE ID =: standardIDToGrades.keySet()] ) 
		{
			standardWrapper temp = new standardWrapper(standard);
			if(doNotTouchStandards.contains(temp.standard.ID)) {
				temp.doNotTouch = true;
			}
			temp.includeStandardGrade = standardGradeIncluded.get(standard.ID);
			standardList.add(temp);
			
			
				
		}	
		
		if(assignment.Standard_Scale__c == null) {
			//validation, there have to be at least one grade_scale that can be used for Standards
			//or force a 'standard standard' scale if there is one to pick from.  this is needed to grade standards
			//never mind make the user change it!
			
			noStandardScale = true;
			//ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Please add a Standard Scale to this asssignment if adding standard(s).');
			assignment.addError('Please add a Standard Scale to this asssignment if adding standard(s).');
		}		
	}
	
	public void searchStandardMethods() {
		//need similar search functionality from addAssignment in gradebook for consistency
			bLimitReached = false;
			//clear the search list before searching
			searchList.clear();

		  	string searchQuery ='Select Name, Long_Text__c, Identifier__c, Id, Parent_Standard__c, Strand__c, Strand__r.Name, Subject__c From Standard__c ';
			string searchQueryWhere = 'where id!= null ';
			string idWild = '';

		  	if(standardIdentifierSearch != null && standardIdentifierSearch != '') {
		  		if(standardIdentifierSearch.contains('*')) {
					idWild = standardIdentifierSearch.replace('*', '');
		  		}
		  		else{
		  			idWild = standardIdentifierSearch;
		  		}
				searchQueryWhere = searchQueryWhere + 'AND Identifier__c LIKE \'%'  +  String.escapeSingleQuotes(idWild) + '%\'';
		  		system.debug('where: '+searchQueryWhere);
		  	
		  	}
		  	
		  	/*
	  	if(standardCourseSearch!=null&&standardCourseSearch!=''){
	  		if(standardCourseSearch.contains('*')){
	  			standardCourseSearch=standardCourseSearch.replace('*', '');
	  		}
			searchQueryWhere = searchQueryWhere + 'AND Course__r.Name LIKE \'%' + String.escapeSingleQuotes(standardCourseSearch) + '%\'';
	  	}
	  	system.debug('where: '+searchQueryWhere);
	  	*/
	  	
	  	if(standardStrandSearch!=null&&standardStrandSearch!=''){
	  		if(standardStrandSearch.contains('*')){
	  			standardStrandSearch = standardStrandSearch.replace('*', '');
	  		}
			searchQueryWhere = searchQueryWhere + 'AND Strand__r.Name LIKE \'%' + String.escapeSingleQuotes(standardStrandSearch) + '%\'';
	  	}
	  	system.debug('where: '+searchQueryWhere);
	  
	  	if(standardSubjectSearch!=null&&standardSubjectSearch!=''){
	  		if(standardParentStandardSearch.contains('*')){
				standardSubjectSearch	= standardSubjectSearch.replace('*', '');
	  		}
				searchQueryWhere = searchQueryWhere + 'AND Subject__c LIKE \'%' + String.escapeSingleQuotes(standardSubjectSearch) + '%\'';
	  	}
	  	system.debug('where: '+searchQueryWhere);
	  
	  	if(standardParentStandardSearch!=null&&standardParentStandardSearch!=''){
	  		if(standardParentStandardSearch.contains('*')){
				standardParentStandardSearch	= standardParentStandardSearch.replace('*', '');
	  		}
				searchQueryWhere = searchQueryWhere + 'AND Parent_Standard__r.Identifier__c LIKE \'%' + String.escapeSingleQuotes(standardParentStandardSearch) + '%\'';
	  	}
	  	system.debug('where: '+searchQueryWhere);
	  
	  	string query = searchQuery + searchQueryWhere + 'AND Strand__c != null order by Level__c DESC, Name Limit 1200';
	 		        
	  	for (Standard__c stan: Database.query(query)){
	  		if (searchList.size() < 1000) {
	  			if(!standardIDToGrades.containsKey(stan.ID)) {
	  				searchList.add(new standardWrapper(stan));
	  			}
	  		}
	  		else if(searchList.size() > 1001) {
	  			break;
	  		}
	  	}
	  	if (searchList.size() >= 1000) {
	  		 blimitReached = true;
	  	}
	  	if(searchList.size() <= 0) {
	  		bNoStandards = true;
	  	}
	  	else {
	  		bNoStandards = false;
	  	}
	}
	
	public void cancel() {
		//place holders
		bNoStandards = true;
		showAddButton();
		hideSearchBar();
		hideSearchResults();
	}
	
	public void addStandards() {
		//determines what students have which standards
		Map<ID, Set<ID>> standardToStudents = new Map<ID, Set<ID>>();
		//determines what students have which strands	
		Map<ID, Set<ID>> strandToStudents = new Map<ID, Set<ID>>();	
			
		Map<ID, Map<ID, ID>> standardToStudentToStrandGrade = new Map<ID, Map<ID, ID>>();
		
		//helper maps
		Map<ID, Set<ID>> strandToStandard = new Map<ID, Set<ID>>();
		Map<ID, ID> strandToStrandGrade = new Map<ID, ID>();
		
		//keep track of user standard selection(s)
		Set<ID> selectedStandards = new Set<ID>();
		Set<ID> potentialNewStrands = new Set<ID>();
		
		//Map to check if standard is Include_In_Standard_Grade__c
		Map<ID, Boolean> standardIncluded = new Map<ID, Boolean>();
		
		//generate the set of selected standards to create new grades, standard grades, and strand grades
		//need to generate 2 grades, a regular one and a grade
		for(standardWrapper sw : searchList) {
			if(sw.selected && !sw.doNotTouch) {
				selectedStandards.add(sw.standard.ID);
				potentialNewStrands.add(sw.standard.Strand__c);
				
				standardIncluded.put(sw.standard.ID, sw.includeStandardGrade);
				
				//add the new strandToStandard connection to the map
				if(!strandToStandard.containsKey(sw.standard.Strand__c)) {
					strandToStandard.put(sw.standard.Strand__c, new Set<ID>{sw.standard.ID});
				}				
				else {
					strandToStandard.get(sw.standard.Strand__c).add(sw.standard.ID);
				}
			}
		}	
		if(selectedStandards.size() <= 0) {
			bNoStandardsSelected = true;
		}	
		else {
			bNoStandardsSelected = false;
			//generate the mapping between student and standard grades to see 
			//if a standard grade has to be created for that standard 
			for(Standard_Grade__c sg : [SELECT ID, Student__c, Standard__c, Standard__r.Strand__c, Key__c, Reporting_Period__c 
										FROM Standard_Grade__c WHERE Student__c IN: studentToStudentSection.keySet() AND Reporting_Period__c =: assignment.Time__c]) {
				
				if(!standardToStudents.containsKey(sg.Standard__c)) {
					standardToStudents.put(sg.Standard__c, new Set<ID>{sg.Student__c});
				}
				else {
					standardToStudents.get(sg.Standard__c).add(sg.Student__c);			
				}
				
				if(!strandToStandard.containsKey(sg.Standard__r.Strand__c)) {
					strandToStandard.put(sg.Standard__r.Strand__c, new Set<ID>{sg.Standard__c});
				}
				else {
					strandToStandard.get(sg.Standard__r.Strand__c).add(sg.Standard__c);
				}
			}
			
			//generate existing strand grades for THIS PERIOD! (epiphany) to compare to the potential to create new strands
			for(Strand_Grade__c strand : [SELECT ID, Student__c, Reporting_Period__c, Strand__c, Key__c FROM Strand_Grade__c 
										  WHERE Student__c IN: studentToStudentSection.keySet() AND Reporting_Period__c =: assignment.Time__c]) {
	
				if(!strandToStudents.containsKey(strand.Strand__c)) {
					strandToStudents.put(strand.Strand__c, new Set<ID>{strand.Student__c});
					
					//create this mapping to use the current strand grade if it exists
					if(!strandToStrandGrade.containsKey(strand.Strand__c)) {
						strandToStrandGrade.put(strand.Strand__c, strand.ID);
					}
					
					//creates association for a standard to a student to a strand grade
					if(strandToStandard.get(strand.Strand__c) != null) {
						if(strandToStandard.get(strand.Strand__c).size() > 0) {
							
							for(ID ss : strandToStandard.get(strand.Strand__c)) {
								if(!standardToStudentToStrandGrade.containsKey(ss)) {
									Map<ID, ID> temp = new Map<ID, ID>();
									temp.put(strand.Student__c, strand.ID);
									standardToStudentToStrandGrade.put(ss, temp);
								}
							}
						}
					}
				}
				//strandToStudents.containsKey(strand.Strand__c)
				else {
					strandToStudents.get(strand.Strand__c).add(strand.Student__c);
					if(strandToStandard.get(strand.Strand__c) != null) {
						if(strandToStandard.get(strand.Strand__c).size() > 0) {
							
							for(ID ss : strandToStandard.get(strand.Strand__c)) {
								if(standardToStudentToStrandGrade.containsKey(ss)) {
									standardToStudentToStrandGrade.get(ss).put(strand.Student__c, strand.ID);
								}
							}
						}
					}
				}
			}
			
			//objects to insert later.
			List<Grade__c> creatingGrades = new List<Grade__c>();
			List<Grade__c> creatingAssignmentGrades	= new List<Grade__c>();
			List<Standard_Grade__c> creatingStandardGrades = new List<Standard_Grade__c>();
			List<Strand_Grade__c> creatingStrandGrades = new List<Strand_Grade__c>();		
			
	
			//for each student...depending if so or non-so, create the strand grade if there is none.
			//always create the standard grade if there is none, else don't create one.
			for(ID i : studentToStudentSection.keySet()) {	
				for(ID j : selectedStandards) {		
					if(!standardToStudents.containsKey(j)) {
						String key = (String)i + (String)j + (String)assignment.Time__c;
						Standard_Grade__c temp = new Standard_Grade__c(Standard__c = j, 
																	Student__c = i, 
																	Key__c = key,
																	Reporting_Period__c = assignment.Time__c);
																	
						creatingStandardGrades.add(temp);
						standardToStudents.put(j,new Set<ID>{i});
					}
					else if(standardToStudents.containsKey(j)) {
						//if for some reason this student doesn't have a standard grade for this, create one
						if(!standardToStudents.get(j).contains(i)) {
							String key = (String)i + (String)j + (String)assignment.Time__c;
							Standard_Grade__c temp = new Standard_Grade__c(Standard__c = j, 
																	Student__c = i, 
																	Key__c = key, 
																	Reporting_Period__c = assignment.Time__c);
																	
							creatingStandardGrades.add(temp);
							standardToStudents.get(j).add(i);						
						}	
						//else do nothing because this student has a standard grade		
					}
				}
				
				//	
				if(standardOnly) {	
					//create the strand grade record if necessary
					for(ID k : potentialNewStrands) {
						if(!strandToStudents.containsKey(k)) {
							String key = String.valueOf(i) + String.valueOf(k) + String.valueOf(assignment.Time__c);
							Strand_Grade__c temp = new Strand_Grade__c(Strand__c = k, Student__c = i, Reporting_Period__c = assignment.Time__c, Key__c = key);					
							creatingStrandGrades.add(temp);
							strandToStudents.put(k, new Set<ID>{i});
							
							//adds the newly created strand_grade for the standard
							for(ID ss : strandToStandard.get(k)) {
								if(!standardToStudentToStrandGrade.containsKey(ss)) {
									Map<ID, ID> temp2 = new Map<ID, ID>();
									temp2.put(i, temp.ID);
									standardToStudentToStrandGrade.put(ss, temp2);
								}
								else if(standardToStudentToStrandGrade.containsKey(ss)) {
									standardToStudentToSTrandGrade.get(ss).put(i, temp.ID);
								}					
							}
						}
						else if(strandToStudents.containsKey(k)){
							if(!strandToStudents.get(k).contains(i)) {
								String key = String.valueOf(i) + String.valueOf(k) + String.valueOf(assignment.Time__c);
								Strand_Grade__c temp = new Strand_Grade__c(Strand__c = k, Student__c = i, Reporting_Period__c = assignment.Time__c, Key__c = key);				
								creatingStrandGrades.add(temp);
								strandToStudents.get(k).add(i);	
		
								for(ID ss : strandToStandard.get(k)) {
									if(standardToStudentToStrandGrade.containsKey(ss)) {
										if(!standardToStudentToStrandGrade.get(ss).containsKey(i)) {
											standardToStudentToStrandGrade.get(ss).put(i, temp.ID);
										}
									}	
								}												
							}
							else {
								for(ID ss : strandToStandard.get(k)) {
									if(standardToStudentToStrandGrade.containsKey(ss)) {
										if(!standardToStudentToStrandGrade.get(ss).containsKey(i)) {
											standardToStudentToStrandGrade.get(ss).put(i, strandToStrandGrade.get(k));
										}
									}	
								}							
							}							
						}
					}
				}
			}	
	
			//insert the standard grades and strand grades as necessary	
			if(standardOnly) {				
				upsert creatingStrandGrades Key__c;
			}
			insert creatingStandardGrades;			
				
			if(standardOnly) {	
				//get the newly created strand grades' IDs, 	
				List<Strand_Grade__c> justCreated = [SELECT ID, Student__c, Strand__c, Reporting_Period__c, Key__c FROM Strand_Grade__c 
													 WHERE ID IN: creatingStrandGrades];
				//then populate with the missing strand_Grade__c IDs	
				for (Strand_Grade__c sg : justCreated) {
					if(strandToStandard.get(sg.Strand__c) != null) {
						if(strandToStandard.get(sg.Strand__c).size() > 0) {
							for(ID ss : strandToStandard.get(sg.Strand__c)) {
								//in general i want to write over regardless if there is one or not
								if(standardToStudentToStrandGrade.get(ss).containsKey(sg.Student__c)) {
									standardToStudentToStrandGrade.get(ss).put(sg.Student__c, sg.ID);
								}
							}
						}
					}						
				}
			}	
					
			//create the grade record, and create the faux grade record for SO-Gradebook
			//the so and non-so gradebook have different representations of the grade record
			//for grade records for standards.  			
			for(ID i : studentToStudentSection.keySet()) {			
				for(ID l : selectedStandards) {
					if(standardOnly) {
						if(courseGradeScale == 'Standard') {
							if(studentToStudentSection.get(i) != null) {
								if( standardToStudentToStrandGrade.get(l).get(i) != null) {
									Grade__c sGrade = new Grade__c( Standards_Only_Grading__c = true, 
																	Possible_points__c = assignment.Possible_Points__c, 
																	Student__c = i,
																	Course__c = course, 
																	Time__c = assignment.Time__c, 
																	Assignment__c = assignment.id,
																	Student_Section__c = studentToStudentSection.get(i), 
																	Standard_Times_Assignment__c = STA,
																	Standard_Weighting__c = standardWeighting,
																	Assignment_Weighting__c = assignment.Weighting_Value__c,
																	Standard__c = l, 
																	//Strand_Grade__c = standardToStudentToStrandGrade.get(l).get(i), 
																	Exclude_From_Section_Grade__c = EFSG,  
																	Grade_With_Standard__c = true,
																	Include_In_Standard_Grade__c = standardIncluded.get(l)
																	);					
									creatingGrades.add(sGrade);
								}
							}
						}
						else {
							//need to determine what exactly goes here
							//actually nothing goes here
						}
					}
					//for non-so gradebook
					else {
						Grade__c sGrade = new Grade__c( Possible_Points__c = assignment.Possible_Points__c,
														Student__c = i,
														Course__c = course,
														Time__c = assignment.Time__c,
														Assignment__c = assignment.id,
														Student_Section__c = studentToStudentSection.get(i),
														Assignment_Weighting__c = assignment.Weighting_Value__c,
														Standard__c = l,
														Include_in_Standard_Grade__c = standardIncluded.get(l)
														);
						creatingGrades.add(sGrade);
					}
				}
			}
			
			//for non-so gradebook, you are done here
			//for so gradebook, need to create the faux grades
			insert creatingGrades;	
			
			//creating the faux grades
	 		if(standardOnly){
				for(Grade__c g : creatingGrades) {
					if(courseGradeScale == 'Standard') {				
						//creating faux grade.
						Grade__c aGrade = new Grade__c( Standards_Only_Grading__c = true, Student__c = g.Student__c, Course__c = g.Course__c, Time__c = g.Time__c,
														Assignment__c = g.Assignment__c, Student_Section__c = g.Student_Section__c, Assignment_Weighting__c = g.Assignment_Weighting__c,
														Standard_Gradebook_Grade__c = g.ID, Possible_Points__c = g.Possible_Points__c, Standard_Times_Assignment__c = g.Standard_Times_Assignment__c, Exclude_From_Section_Grade__c = g.Exclude_From_Section_Grade__c, Faux_Grade__c = true);
						creatingAssignmentGrades.add(aGrade);			
					}
					else {
						//it is not meant for any other course grade scale			
					}	
				}			
				
				//finally insert the faux grades for so gradebook
				if(standardOnly) {
					insert creatingAssignmentGrades;	
				}
	 		}
	 		
			//need to reinitialize for display purposes
			grades.clear();
			doNotTouchStandards.clear();
			standardIDToGrades.clear();
			standardList.clear();
			initialize(assignment.ID);	
			if(!bNoStandards) {
				searchStandardMethods(); 
			}
		}
	}
	
	public void removeStandards() {
		//need a delete Grade somewhere here
		Set<ID> deleteStandards = new Set<ID>();
		List<Grade__c> deleteGrades = new List<Grade__c>();
		for(standardWrapper sw : standardList) {
			if(sw.selected) {
				deleteStandards.add(sw.standard.ID);
			}
		}
		
		//get all the grades associated to the selected standards
		for(ID i : deleteStandards) {
			deleteGrades.addAll(standardIDToGrades.get(i));
		}
		List<Grade__c> otherGrades = [SELECT ID FROM Grade__c WHERE Standard_Gradebook_Grade__c IN: deleteGrades];
		deleteGrades.addAll(otherGrades);
		//finish by deleting those grades
		core_triggerUtils.gradeDeletionAllowed = true;
		core_triggerUtils.gradeStandardTrigger = true;
		delete deleteGrades;
		core_triggerUtils.gradeStandardTrigger = false;
		core_triggerUtils.gradeDeletionAllowed = false;
		
		//need to reinitialize
		grades.clear();
		doNotTouchStandards.clear();
		standardIDToGrades.clear();
		standardList.clear();		
		
		initialize(assignment.ID);
		if(!bNoStandards) {
			searchStandardMethods(); 
		}
	}
	
	public void editSaveStandards() {
		Set<ID> updateIDs = new Set<ID>();
		List<Grade__c> updateGrades = new List<Grade__c>();
		Map<ID, Boolean> updateIncludeStandardGrades = new Map<ID, Boolean>();
		for(standardWrapper sw : standardList) {
			updateIDs.add(sw.standard.ID);
			updateIncludeStandardGrades.put(sw.standard.ID, sw.includeStandardGrade);
		}
		for(ID i : updateIDs) {
			updateGrades.addAll(standardIDToGrades.get(i));
		}
		
		//if necessary, attemp to recalculate the standard grades
		Set<ID> students = new Set<ID>();
		Set<ID> standards = new Set<ID>();
		
		for(Grade__c g : updateGrades) {
			if(g.Standard__c != null) {
				g.Include_In_Standard_Grade__c = updateIncludeStandardGrades.get(g.Standard__c); 
			}
			if(g.Student__c != null && g.Standard__c != null) {
				students.add(g.Student__c);
				standards.add(g.Standard__c);
			}
		}
		
		update updateGrades;
		
		if(updateGrades.size() > 0) {
			Gradebook_CalculationTypes.triggerCalcNow(students, standards, new Set<ID>{assignment.Time__c});
			Gradebook_CalculationTypes.triggerCalculateLater(students, standards, new Set<ID>{assignment.Time__c});
		}
		
	}
	
	public pageReference returnToAssignment() {
		return new pageReference('/'+ assignment.id);
	}
	
    public void hideModal() {
    	displayModal = false;
    }
    
    public void showModal() {
    	displayModal = true;
    }	
    
    public void hideAddButton() {
    	displayAddButton = false;
    }
    
    public void showAddButton() {
    	displayAddButton = true;
    }
    
    public void showSearchBar() {
    	displaySearchBar = true;
    	hideAddButton();
    }
    
    public void hideSearchBar() {
    	displaySearchBar = false;
    }
    
    public void showSearchResults() {
    	displaySearchResults = true;
    }
    
    public void hideSearchResults() {
    	displaySearchResults = false;
    }
	
}