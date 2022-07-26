//Programmer's Notes:
//this UI is to generate Courses for the incoming student.  
//requires the Transfer Course Name, Subject, Credit Value, 
//new needs: give options: create Transfer Course, search Transfer Course
//need to remember, one student at a time!!! do not worry about multi selecting students

public with sharing class Transfer_CourseWizard {
	public Course__c 			newCourse			{get; set;}
	public List<Course__c>		subjectCourses		{get; set;}
	public List<SelectOption> 	subjectSelections	{get; set;}	
	public ID					transferRecordType	{get; set;}
	public ID					subjectRecordType	{get; set;}
	public List<Course__c> 		relatedCourses		{get; set;}  //by subject
	public List<Course__c>		transferCourses		{get; set;}
	public List<SelectOption>	transferSelections	{get; set;}
	public List<SelectOption>	cohortSelections	{get; set;}
	public List<SelectOption>	gradeScaleOptionList	{get; set;}
	//for now trying string as a subject, but could switch to id
	//public ID				subject			{get; set;}
	
	//Page Controls
	public Boolean 				displayTransferCreateCourses 	{get; set;}
	public Boolean				displayTransferCourses			{get; set;}
	public Boolean				required						{get; set;}
	public Boolean				saving 				 			{get; set;}
	public Boolean				displaySearchResults			{get; set;}	
	public Boolean				displayStep1					{get; set;}
	public Boolean				displayStep2					{get; set;}
	public Boolean				displayCreateStudentRecord		{get; set;}
	public Boolean				displayEditStudentRecord		{get; set;}
	public Boolean				displayEditFinalGrade			{get; set;}
	public Boolean				displayAddFinalGrade			{get; set;}
		
	//Student Wizard part
	public Student_SearchStudent 	searchResults		{get; set;}
	public List<selectWrapper> 		fromSearchStudent	{get; set;}
	public selectWrapper 			chosenStudent		{get; set;}

	//public Transfer_StudentWizard	TSW					{get; set;}
	
	//Entering Grades part
	public List<SelectOption>	yearSelections			{get; set;}
	public String				selectedStudentID		{get; set;}
	public String				selectedRowID			{get; set;}
	public String				selectedStudentRowID	{get; set;}

	//empty constructor
	public Transfer_CourseWizard() {		
		subjectCourses = new List<Course__c>();
		subjectSelections = new List<SelectOption>();
		relatedCourses = new List<Course__c>();
		transferCourses = new List<Course__c>();
		transferSelections = new List<SelectOption>();
		cohortSelections = new List<SelectOption>();
		
		//Student Wizard parts
		searchResults = new Student_SearchStudent();
		fromSearchStudent = new List<selectWrapper>();		
		
		//Page Controls
		displayTransferCreateCourses = false;
		displayTransferCourses = false;
		required = false;
		saving = false;
		displaySearchResults = false;	
		displayStep1 = true;
		displayStep2 = false;	
		displayCreateStudentRecord = false;
		displayEditStudentRecord = false;
		displayEditFinalGrade = false;
		displayAddfinalGrade = false;
				
		//Entering Grades parts		
		yearSelections = new List<SelectOption>();		
		selectedStudentID = '';
		selectedRowID = '';
		selectedStudentRowID = '';
				
		Initialize();
	}
	
	public void Initialize() {
		//populate the subject selectOptions
		subjectRecordType = core_SoqlUtils.getRecordTypesBySobject('Course__c').get('Subject_Area');
		//system.debug('subjectRecordType: ' + subjectRecordType);
		for(Course__c c : [SELECT ID, Credit_Hours__c, Credits__c, Subject_Area__c, Subject_Area_Lookup__c, Subject_Area_Lookup__r.Name, Name, Grade_Scale_Lookup__r.Name FROM Course__c WHERE RecordTypeId =: subjectRecordType]) {
			subjectSelections.add(new SelectOption(c.ID, c.Name));
		}

		//populate the year selectOptions
		for(Time_Element__c t : [SELECT ID, Picklist_Value__c, School__c, Date_Start_Date__c, End_Date__c, Type__c, Name__c FROM Time_Element__c WHERE Picklist_Value__r.Name = 'Year' ORDER BY Name__c DESC]) {
			yearSelections.add(new SelectOption(t.ID, t.Name__c));
		}
		
		cohortSelections.add(new SelectOption('','--None--'));
		for(Cohort__c c : [SELECT ID, Name FROM Cohort__c ORDER BY Name DESC]) {
			cohortSelections.add(new SelectOption(c.ID, c.Name));
		}		
		
		gradeScaleOptionList = new List <SelectOption>();
		for (Picklist_Value__c plv: core_GradeScaleCatalogController.getAvailableGrade_Scales()){
			gradeScaleOptionList.add(new SelectOption(plv.id, plv.name));
		}
		
		//get the RecordType ID for Tranfer
		transferRecordType = core_SoqlUtils.getRecordTypesBySobject('Course__c').get('Transfer');
		system.debug('transferRecordType: ' + transferRecordType);
		newCourse = new Course__c(RecordTypeID = transferRecordType);
	}
	
	public void createTransferCourse() {
		//insert newCourse and re initialize it
		if(newCourse.Name != '' && newCourse.Name != null &&
			newCourse.Credit_Hours__c != null &&
			//newCourse.Transfer_School__c != '' && newCourse.Transfer_School__c != null &&
			newcourse.Subject_Area_Lookup__c != null) {
			newCourse.RecordTypeID = transferRecordType;
			newCourse.GPA_Added_Value_Points__c = 0.0;
			try{
				insert newCourse;
			}catch(System.DMLException e){
				Apexpages.addMessage(new apexpages.message(ApexPages.severity.ERROR, 'An error occured while trying to save your course.'));
				return;
			}
		}
		
		if(displayStep2) {
			transferSelections.clear();
			getTransferSelections();
		}
		
		newCourse = new Course__c(RecordTypeID = transferRecordType);
		required = false;
	}
	
	//go back?
	public void nextStep() {
		//if current step is...
		//there are not many steps, possible at most 2, so no need to create another page.
		if(displayStep1) {
			displayStep1 = !displayStep1;
			displayStep2 = !displayStep2;
		}
		else if(displayStep2) {
			displayStep2 = !displayStep2;
			displayStep1 = !displayStep1;
		}
	}
	
	public void getTransferCourses() {
		transferCourses = [SELECT ID, Credit_Hours__c, Credits__c, Subject_Area__c, Subject_Area_Lookup__c, Subject_Area_Lookup__r.Name, Name, Grade_scale_lookup__r.Name, Grade_scale_lookup__c FROM Course__c WHERE recordTypeID =: transferRecordType];
	}
	
	public void getTransferSelections() {
		List<Course__c> temp2 = [SELECT ID, Credit_Hours__c, Credits__c, Subject_Area__c, Subject_Area_Lookup__c, Subject_Area_Lookup__r.Name, Name, Grade_scale_lookup__r.Name, Grade_scale_lookup__c FROM Course__c WHERE recordTypeID !=: subjectRecordType ORDER BY Name ASC];
		for(Course__c c : temp2) {
			transferSelections.add(new SelectOption(c.ID, c.Name));
		}
	}	
	
	public void page2Transition() {
		//setting the data up, i.e. grabbing the student.
		try {
			chosenStudent = selectStudent();
			//given student, search for his student records!			
			chosenStudent.studentForYearX = chosenStudent.getStudentRecords();
			if(transferCourses.size() == 0) {
				getTransferCourses();
			}
			
			//populate the transferSelections for Final Grades
			
			//grab all the courses from this student's current school
			//ERRR! wrong, just grab all the courses existent in the system... could be alot
			//Map<ID, Course_Course_Catalog__c> temp0 = new Map<ID, Course_Course_Catalog__c>([SELECT ID, Course__c, Course_Catalog__c FROM Course_Course_Catalog__c WHERE Course_Catalog__c =: chosenStudent.student.Setup__r.Course_Catalog__c]);			
			//Set<ID> temp1 = new Set<ID>();
			//for(Course_Course_Catalog__c ccc : temp0.Values()) {
				//temp1.add(ccc.Course__c);
			//}			
			transferSelections.clear();
			getTransferSelections();			
			
			/*
			for(Course__c c : transferCourses) {
				transferSelections.add(new SelectOption(c.ID, c.Name));
			}
			*/
			nextStep();
		}
		catch(Exception e) {
			Apexpages.addMessage(new apexpages.message(ApexPages.severity.ERROR, 'Please select at least one student.' ));
		}
	}
	
	//Student Wizard parts
	public void searchStudents() {
		fromSearchStudent.clear();
		try {
			searchResults.mainQuery += ' and School__r.RecordType.Name = \'School\'';
			searchResults.searchStudents();
			for(Student__c s : searchResults.studResults) {
				fromSearchStudent.add(new selectWrapper(s, this));
			}
			if(fromSearchStudent.size() > 0) {
				displaySearchResults = true;
			}	
			if(searchResults.studResults.isEmpty()){
				Apexpages.addMessage(new apexpages.message(ApexPages.severity.ERROR, 'Search returned no results.'));
			}								
		}
		catch(Exception e) {
			//some bigger error
		}

	}
	
	public selectWrapper selectStudent() {
		selectWrapper temp = new selectWrapper(this);
		for(selectWrapper sw : fromSearchStudent) {
			if(sw.selected) {
				//populate the studentForYearX
				temp = sw;
				break;
			}
		}
		return temp;
	}	
	
	//=============================================================================//
	
	public void closeTransferCreateCourses() {
		displayTransferCreateCourses = false;
	}	
	
	public void openTransferCreateCourses() {
		requirements();
		newCourse = new Course__c(RecordTypeID = transferRecordType);
		displayTransferCreateCourses = true;
	}
	
	public void closeTransferCourses() {
		displayTransferCourses = false;
	}
	
	public void openTransferCourses() {
		displayTransferCourses = true;
	}
	
	public void closeCreateStudentRecord() {
		//delete chosenStudent.dummyStudent;
		chosenStudent.dummyStudent = new Student__c();
		displayCreateStudentRecord = false;
	}
	
	public void openCreateStudentRecord() {
		//gets around the trigger without writing a backdoor
		chosenStudent.dummyStudent = new Student__c();
		chosenStudent.dummyStudent.Active__c = false;
		chosenStudent.dummyStudent.School__c = chosenStudent.student.School__c;
		chosenStudent.dummyStudent.Student_First_Name__c = chosenStudent.student.Student_First_Name__c;
		chosenStudent.dummyStudent.Student_Last_Name__c = chosenStudent.student.Student_Last_Name__c;
		chosenStudent.dummyStudent.Student_Id__c = chosenStudent.student.Student_Id__c;
		//insert chosenStudent.dummyStudent;
		displayCreateStudentRecord = true;	
	}
	
	public void closeEditStudentRecord() {
		displayEditStudentRecord = false;
	}
	
	public void openEditStudentRecord() {
		displayEditStudentRecord = true;
	}
	
	public void closeEditFinalGrade() {
		displayEditFinalGrade = false;
	}
	
	public void openEditFinalGrade() {
		chosenStudent.dummyGrade = new Final_Grade__c();
		displayEditFinalGrade = true;		
	}
	
	public void closeAddFinalGrade() {
		displayAddFinalGrade = false;
	}
	
	public void openAddFinalGrade() {
		displayAddFinalGrade = true;
	}
	
	public void cancelingCourse() {
		required = false;
	}
	
	public void requirements() {
		required = true;
	}
	
	public void deleteRow() {
		selectedRowID = ApexPages.currentPage().getParameters().get('selectedRowID');
		for(Integer i = 0; i < chosenStudent.currentFinalGradeList.size(); i++) {
			if(chosenStudent.currentFinalGradeList[i].Key__c == selectedRowID ) {
				chosenStudent.temporaryFinalGradeList.remove(chosenStudent.currentFinalGradeList[i].ID);
				Final_Grade__c removing = chosenStudent.currentFinalGradeList.remove(i);				
				if (removing.id!=null) 
					delete removing;
			}
		}
	}
	
	public void deleteStudentRow() {
		selectedStudentRowID = ApexPages.currentPage().getParameters().get('selectedStudentRowID');
		for(Integer i = 0; i < chosenStudent.studentForYearX.size(); i++) {
			if(chosenStudent.studentForYearX[i].ID == selectedStudentRowID) {
				Student__c removing = chosenStudent.studentForYearX.remove(i);
				delete removing;
			}
		}
	}
	
	public pageReference enrollmentWizard() {
		PageReference pageRef = new PageReference('/apex/Scheduler_SectionWizard');
		pageRef.setRedirect(true);
		return pageRef;
	}

	//=============================================================================//
	//Wrapper classes	
	
	public class selectWrapper {
		public Boolean selected					{get; set;}
		public Student__c student				{get; set;}
		//populate place the inactive student records for the contact in the List
		public List<Student__c> studentForYearX	{get; set;}
		public Map<ID, List<Final_Grade__c>> studentToFinalGrades	{get; set;}
		public Student__c dummyStudent								{get; set;}
		public List<Final_Grade__c> currentFinalGradeList			{get; set;}
		//public Set<Final_Grade__c> temporaryFinalGradeList	{get; set;}
		public Map<ID, Final_Grade__c> temporaryFinalGradeList		{get; set;}
		public Final_Grade__c dummyGrade	{get; set;}
		public String selectedStudentID		{get; set;}
		private Transfer_CourseWizard tcw;
		public Boolean saveFGError			{get; set;}
		public Boolean saveSRError			{get; set;}
		
		public selectWrapper(Transfer_CourseWizard tcw) {
			selected = false;
			//student = new Student__c();
			studentForYearX = new List<Student__c>();
			studentToFinalGrades = new Map<ID, List<Final_Grade__c>>();
			dummyStudent = new Student__c();
			currentFinalGradeList = new List<Final_Grade__c>();
			//temporaryFinalGradeList	= new Set<Final_Grade__c>();
			temporaryFInalGradeList = new Map<ID, Final_Grade__c>();
			dummyGrade = new Final_Grade__c();
			selectedStudentID = '';
			this.tcw = tcw;
			saveFGError = false;
			saveSRError = false;
		}
		
		public selectWrapper(Student__c s, Transfer_CourseWizard tcw) {
			selected = false;
			student = s;
			studentForYearX = new List<Student__c>();
			studentToFinalGrades = new Map<ID, List<Final_Grade__c>>();
			dummyStudent = new Student__c();
			currentFinalGradeList = new List<Final_Grade__c>();
			//temporaryFinalGradeList	= new Set<Final_Grade__c>();
			temporaryFinalGradeList = new Map<ID, Final_Grade__c>();
			dummyGrade = new Final_Grade__c();
			selectedStudentID = '';
			this.tcw = tcw;
			saveFGError = false;
			saveSRError	= false;
		}

		public List<Student__c> getStudentRecords() {
			//required! student ID is unique, if not then there's a major problem with the data
			List<Student__c> temp = new List<Student__c>();
			if(student.Student_Id__c != null) {
				temp = [SELECT ID, Active__c, Grade__c, Date_of_Birth__c, Gender__c, Race_Multi__c, Cohort__c, School__c, Student_Id__c,
					School_Year__r.Name__c, School_Year__c 
				FROM Student__c 
				WHERE Student_Id__c =: student.Student_Id__c
				AND School__r.RecordType.Name='School' 
				ORDER BY School_Year__r.Date_Start_Date__c DESC];
			}
			return temp;		
		}

		public void populateStudentToFinalGradeMap() {
			if(studentForYearX.size() == 0) {
				studentForYearX = getStudentRecords();
			}
			
			for(Student__c s : studentForYearX) {
				if(!studentToFinalGrades.containsKey(s.ID)) {
					studentToFinalGrades.put(s.ID, new List<Final_Grade__c>());
				}
			}
			
			for(Final_Grade__c fg:
						[SELECT ID, Credit_Earned_Override__c, Student__c, Grade_Overridden__c, Grade_Override__c, Course__c, Course_Credits__c, Key__c,
							Final_GPA_Value__c, Final_Grade_Value__c, Final_Grade_Letter_v2__c, Transfer_School__c, Weighted_GPA__c, Unweighted_GPA__c, Name
						FROM Final_Grade__c 
						WHERE Student__c in: StudentForYearX]){
				if(!studentToFinalGrades.containsKey(fg.Student__c)){
					studentToFinalGrades.put(fg.Student__c, new List<Final_Grade__c>{fg});
				}
				else {
					Set<Final_Grade__c> test = new Set<Final_Grade__c>();
					test.addAll(studentToFinalGrades.get(fg.Student__c));
					if(!test.contains(fg)) {
						studentToFinalGrades.get(fg.Student__c).add(fg);
					}
					test.clear();
				}
			}
			
		}
		public void editFinalGrade() {
			currentFinalGradeList.clear();
			populateStudentToFinalGradeMap();
			selectedStudentID = ApexPages.currentPage().getParameters().get('selectedStudentID');
			if(studentToFinalGrades.containsKey(selectedStudentID)) {
				currentFinalGradeList = studentToFinalGrades.get(selectedStudentID);
			}
		}
		
		public void addFinalGrade() {
			Final_Grade__c dummyFG1 = new Final_Grade__c(Student__c = selectedStudentID);
			dummyFG1.Transfer_School__c = 'temp';
			dummyFG1.Course__c = tcw.transferSelections[0].getValue();
			dummyFg1.final__c = true;
			dummyFg1.Key__c = 'temp'+DateTime.now().getTime(); //make a (mostly) unique key (doubt anyone could click fast enough to get this to dual key)
			currentFinalGradeList.add(dummyFG1);

		}
		
		public void saveFinalGrade() {
			//grab the credit hour from the course and apply it to the final grade
			Set<ID> courseIDs = new Set<ID>();
			for(Final_Grade__c fg: currentFinalGradeList) courseIDs.add(fg.Course__c);
			Map<ID,Course__c> courses = new Map<ID,Course__c>([SELECT id, Credit_Hours__c FROM Course__c WHERE id IN :courseIDs]);
			Apexpages.getMessages().clear();
				saveFGError = false;
				List <Final_Grade__c> transferGradeList = new List <Final_Grade__c>();
				for(Final_Grade__c fg : currentFinalGradeList) {
					//removing Final_Grade_Value__c from required
					if (fg.transfer_School__c !=null){
						fg.Course_Credits__c = courses.get(fg.Course__c).Credit_Hours__c;
						transferGradeList.add(fg);
					}					
				}
				if (!saveFGError ){
					try {		
						upsert transferGradeList;		
					}
					catch (exception e){
						saveFGError =true;
					}
				}
				
		}

		public void addStudentRecord() {
			saveSRError = false;
			system.debug('what is dummyStudent school year: ' + dummyStudent.School_Year__c);
			for(Student__c s : studentForYearX) {
				if(s.School_Year__c == dummyStudent.School_Year__c ) {
					saveSRError = true;
					return;
				}
			}

			Setup__c setup;
			List<Setup__c> setupForYear = [select id, Year__r.Name__c, Term__r.Date_Start_Date__c, Year__r.Date_Start_Date__c from Setup__c where Year__c =: dummyStudent.School_Year__c AND School__c =: dummyStudent.School__c LIMIT 1];
			if(setupForYear.isEmpty()){
				Error_Handling.errorMessage('The system was unable to locate the setup for the selected school for that year. Please verify your data and try again.');
				return;
			} else {
				setup = setupForYear[0];
			}
			dummyStudent.Setup__c = setup.ID;
			dummyStudent.Cohort__c = student.Cohort__c;
			dummyStudent.Date_of_Birth__c = student.Date_of_Birth__c;
			dummyStudent.Race_Multi__c = student.Race_Multi__c;
			dummyStudent.Entry_Date__c = setup.Term__r.Date_Start_Date__c != null? setup.Term__r.Date_Start_Date__c:setup.Year__r.Date_Start_Date__c;
			dummyStudent.Reference_Id__c = dummyStudent.Student_Id__c+'_'+setup.Year__r.Name__c;
			dummyStudent.Gender__c = student.Gender__c;
			dummyStudent.Individual__c = student.Individual__c;
			dummyStudent.Name = student.Name;
			
			insert dummyStudent;

			//requery student records
			studentForYearX = getStudentRecords();
			dummyStudent = new Student__c();
			tcw.displayCreateStudentRecord = false;
		}
	}	
}