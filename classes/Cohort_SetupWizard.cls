public with sharing class Cohort_SetupWizard{
	/*PAGE CONTROL */
	public boolean critError{get;set;}
	public boolean editMode{get;set;}
	public boolean newMode{get;set;}
	public boolean cohortPage{get;set;}
	public boolean studentPage{get;set;}
	public boolean bHome{get;set;}
	public boolean reqPage{get;set;}
	public boolean searchStudents{get;set;}
	public boolean isCreatingReq{get;private set;}
	public Student__c student{get;set;}
	public List<StudentWrapper> wrapper{get;set;}
	public List<Student__c> students{get;set;}
	public List<StudentWrapper> currentCohorts{get;set;}
	public List<CohortWrapper> searchedCohorts{get; private set;}
	public String selectedCohortId {get;set;}
	public String selectedSubjectId {get;set;}
	public List<CohortReqWrapper> gradRequirements{get;set;}
	public CohortReqWrapper cohReq{get;set;}
	public List <Course__c> subjectCourseList {get;set;}
	public Map <String, Id> courseRtMap;
	public String selectedCourseOption {get;set;}
	public Map <Id, CohortReqWrapper> crwMap {get;set;}
	public Set <Id> subjectsWithCourses;
	
	/* NEW/EDIT COHORT */
	public Cohort__c cohort{get;set;}
	public List<SelectOption> schools{get;set;}
	
	
	/* STUDENT SELECT */
	public Student_SearchStudent studentSearchInfo{get;set;}
	
	public Cohort_SetupWizard(ApexPages.StandardController stdCon){
		cohort = new Cohort__c();
		searchedCohorts = new List<CohortWrapper>();
		
		if (stdCon.getId() == null){
			cohort = (Cohort__c) stdCon.getRecord();
			searchCohorts();
			cohortPage=false;
			newMode=false;
			editMode=false;
			init();
		} else {
			editStudentsCall(stdCon.getId());
			init();
		}
	}
	
	private void init(){
		student = new Student__c();
		wrapper = new List<StudentWrapper>();
		currentCohorts = new List<StudentWrapper>();
		schools = new List<SelectOption>();
		courseRtMap = core_SoqlUtils.getRecordTypesBySobject('Course__c');
		isCreatingReq = false;
		gradRequirements = new List<CohortReqWrapper>();
		reqPage = false;
		getSchoolList();
		subjectsWithCourses = new Set <Id>();
		critError = schools.isEmpty();
	}
	
	public void editStudentsCall(String cohortId){
		selectedCohortId = cohortId;
		editStudents();
	}
	
	public void queryCohort(){
		cohort = [SELECT Required_Community_Service_Hours__c, School__c, Year__c,Exit_Year__c, Name, Credits_Required__c, Portfolio_Required__c, Projected_Graduation_Date__c FROM Cohort__c WHERE Id = :selectedCohortId];
	}
	
	public void editStudents(){
		queryCohort();
		getStudentCohorts();
		studentPage = true;
		cohortPage=false;
		bHome = false;
	}
	
	public void cancelAddToCohort(){
		searchStudents = false;
	}
	
	public void editCohort(){
		if (System.currentPageReference().getParameters().get('selectedCohortId')!=null){
			selectedCohortId = System.currentPageReference().getParameters().get('selectedCohortId');
			queryCohort();
		}
		cohortPage=true;
		editMode=true;
	}
	
	public void editRequirement(){
		getCourses();
		if (System.currentPageReference().getParameters().get('selectedSubjectId')!=null){
			selectedSubjectId = System.currentPageReference().getParameters().get('selectedSubjectId');
			cohReq  = crwMap.get(selectedSubjectId);
		}
		selectedCourseOption = '';
		for (Cohort_Requirement__c cr: cohReq.cohReqList){
			selectedCourseOption+=cr.course__c+',';
		}
		isCreatingReq = true;
	}
	
	public void deleteRequirement(){
		if (System.currentPageReference().getParameters().get('selectedSubjectId')!=null){
			selectedSubjectId = System.currentPageReference().getParameters().get('selectedSubjectId');
			cohReq  = crwMap.get(selectedSubjectId);
		}
		delete cohReq.cohReqList;
		getRequirements();
	}
	
	/*------------------ACTION METHODS------------------*/
	public void getStudentCohorts(){
		currentCohorts = new List<StudentWrapper>();
		for (Student__c stud: [SELECT Date_of_Birth__c, Exit_Date__c, Exit_Reason__c, Race_Multi__c,
					Individual__c, Individual__r.MailingStreet, Grade__c, Name, Primary_Schedule_Group__c,
					Reference_ID__c, School__c, Student_First_Name__c, Student_Last_Name__c, Student_Id__c,
					Individual__r.Original_Member_Of_Cohort__c
					FROM Student__c
					WHERE Cohort__c =: cohort.Id
					AND School__c =: cohort.School__c
					and active__c =true]){
			currentCohorts.add(new StudentWrapper(stud));
		}
		bHome=true;
	}
	
	public void createCohort(){
		cohort = new Cohort__c();
		cohortPage = true;
	}
	
	public void cancelCohort(){
		cohortPage = false;
	}
	
	public void createRequirement(){
		getCourses();
		cohReq = new cohortReqWrapper ();
		isCreatingReq = true;
	}
	
	public void cancelRequirement(){
		isCreatingReq = false;
	}
	
	public void saveRequirement(){
		List <Cohort_Requirement__c> upsertCrList = new List <Cohort_Requirement__c>();
		List <Cohort_Requirement__c> delCrList = new List <Cohort_Requirement__c>();
		if (selectedCourseOption!=null&selectedCourseOption!=''){
			Set <String> courseIds = new Set <String> ();
			for (string cId: selectedCourseOption.split(',')){
				system.debug('cId~'+cId);
				courseIds.add(cId);
			}
			
			Map <Id, Cohort_Requirement__c> courseByCrMap  = new Map <Id, Cohort_Requirement__c >();
			
			for (Cohort_Requirement__c cr: cohReq.cohReqList){
				if (!courseIds.contains(cr.course__c)){
					system.debug('delCourse~~~'+cr);
					delCrList.add(cr);
				}
				else{
					system.debug('newCourse~~~'+cr);
					courseByCrMap.put(cr.course__c, cr);
				}
			}
			for (Id courseId: courseIds){
				if (courseByCrMap.keySet().contains(courseId)){
					Cohort_Requirement__c tempCr = courseByCrMap.get(courseId);
					tempCr.Credits__c = double.valueOf(cohReq.dCredits);
					system.debug('upsert CrList~~~'+cohReq);
					upsertCrList.add(tempCr);
				}
				else {
					Cohort_Requirement__c tempCr = new Cohort_Requirement__c(Cohort__c=cohort.id, Subject_Area__c =cohReq.subjectId, Course__c=courseId);
					tempCr.Credits__c = double.valueOf(cohReq.dCredits);
					upsertCrList.add(tempCr);
				}
			}
		} else {
			//throw error
		}
		if (!upsertCrList.isEmpty()){
			system.debug('upsertCrList~~~'+upsertCrList);
			upsert upsertCrList;
		}
		if (!delCrList.isEmpty()){
			system.debug('delCrList~~~'+delCrList);
			delete delCrList;
		}
		isCreatingReq =false;
		getRequirements();
	}
	
	public void searchCohorts(){
		searchedCohorts.clear();
		for (Cohort__c coh: [SELECT Name, School__c, School__r.Name, Year__c, Exit_Year__c, Required_Community_Service_Hours__c,
							Credits_Required__c, Portfolio_Required__c, Projected_Graduation_Date__c 
							FROM Cohort__c 
							where name!=null]){
			searchedCohorts.add(new CohortWrapper(this, coh));
		}
		bHome = true;
	}
	
	public void saveCohort(){
		try{
			if (cohort.Name == null || cohort.Year__c == null || cohort.School__c == null){
				errorMessage('Year, Name, and School all must have a value.');
				return;
			}
			
			upsert cohort;
			
		} catch (Exception e){
			errorMessage('Unable to save cohort. Please check your information.');
			return;
		}

		cohortPage = false;
		searchCohorts();
	}
	
	public void changeCohort(){
		cohortPage = true;
		studentPage = false;
		reqPage = false;
		searchCohorts();
	}
	
	public void addCohorts(){
		swapStudents(wrapper, currentCohorts, true);
		searchStudents = false;
		getStudentCohorts();
	}
	
	public void removeCohorts()
	{
		swapStudents(currentCohorts, wrapper, false);
	}
	
	public List<SelectOption> getSubjectAreas(){
		List<SelectOption> options = new List<SelectOption>();
		for (Course__c subject: [SELECT Name FROM Course__c WHERE RecordTypeId = :courseRtMap.get('Subject_Area') and Id in:subjectsWithCourses]){
			options.add(new SelectOption(subject.id, subject.Name));
		}
		return options;
	}
	
	public void getCourses(){
		subjectCourseList = new List <Course__c>();

		for (Course__c course: [SELECT Id, Name, Subject_Area_Lookup__c FROM Course__c WHERE RecordTypeId != :courseRtMap.get('Subject_Area')])
		{
			subjectCourseList.add(course);
			subjectsWithCourses.add(course.subject_Area_Lookup__c);
		}
	}
	
	//When a student is removed from one list it gets added to the other
	private void swapStudents(List<StudentWrapper> fromWrap, List<StudentWrapper> toWrap, boolean isAdding){
		List<Student__c> swappedStudents = new List<Student__c>();
		List <Contact>      studContacts = new List <Contact>();
		integer i = 0;
		while (i < fromWrap.size()){
			StudentWrapper wrap = fromWrap.get(i);
			if (wrap.isSelected){
				wrap.isSelected = false;
				toWrap.add(fromWrap.remove(i));
				Contact studContact = new Contact(Id=wrap.student.Individual__c );
				if (isAdding){
					wrap.student.Cohort__c = cohort.Id;
					studContact.Cohort__c = cohort.Id;
					studContact.Original_Member_of_Cohort__c=wrap.student.Original_Member_of_Cohort__c;
				}
				else{
					studContact.Original_Member_of_Cohort__c=false;
					wrap.student.Original_Member_of_Cohort__c=false;
					wrap.student.Cohort__c = null;
					studContact.Cohort__c=null;
				}
				swappedStudents.add(wrap.student);
				studContacts.add(studContact);
			} else {
				i++;
			}
		}
		update swappedStudents;
		update studContacts;
	}
	
	public void changeStudents(){
		studentPage = false;
	}
	
	public void searchStuds(){
		searchStudents = true;
		
		Student_searchStudent searchStud= new Student_searchStudent();
		searchStud.student= student;
		searchStud.school = cohort.School__c;
		searchStud.student.Active__c=true;
		searchStud.searchStudents();
		
		wrapper.clear();
		for(Student__c stud: searchStud.studResults)
		{
			if (stud.individual__r.Cohort__c!=cohort.id&&stud.individual__c!=null){
				wrapper.add(new StudentWrapper(stud));
			}
		}
	}
	
	/*------------------HELPER METHODS------------------*/
	private void getSchoolList()
	{
		List<Setup__c> possibleSchools = Core_SoqlUtils.getOrgActiveSetups();
		if(possibleSchools.isEmpty())
		{
			errorMessage('There are no valid schools in your org. Please setup a school before creating a cohort.');
			return;
		}
		for(Setup__c s: possibleSchools)
		{
			schools.add(new SelectOption(s.School__c, s.School__r.Name));
		}
		schools.add(0, new SelectOption('', '--None--'));
	}
	
	private void errorMessage(string error)
	{
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
	}
	
	private void setBooleansFalse()
	{
		editMode = false;
		newMode = false;
		cohortPage = false;
		studentPage = false;
		bHome = false;
		reqPage = false;
		searchStudents = false;
	}
	
	public void getRequirements()
	{
		crwMap= new Map <Id, CohortReqWrapper>();
		for (Cohort_Requirement__c cr: [SELECT Name, Cohort__c, Credits__c, Subject_Area__c, subject_area__r.name, Course__c, course__r.name FROM Cohort_Requirement__c WHERE Cohort__c = :cohort.Id]){
			if (!crwMap.keySet().contains(cr.subject_area__c)){
				CohortReqWrapper crw = new CohortReqWrapper(cr);
				crwMap.put(cr.subject_area__c, crw);
			}
			else {
				CohortReqWrapper crw =crwMap.get(cr.subject_area__c);
				crw.cohReqList.add(cr);
				crw.courseString+=cr.course__r.name+'<br/>';
			}
		}
		gradRequirements = crwMap.values();
	}
	
	public class CohortWrapper
	{
		public Cohort__c coh{get;set;}
		private Cohort_SetupWizard wiz;
		
		public CohortWrapper(Cohort_SetupWizard wiz, Cohort__c coh)
		{
			this.wiz = wiz;
			this.coh = coh;
		}
		
		public void editCoh()
		{
			wiz.cohort = coh;
			wiz.setBooleansFalse();
			wiz.reqPage = true;
		}
		
		public void viewReqs()
		{
			wiz.reqPage = true;
			wiz.bHome = false;
			wiz.cohort = coh;
			wiz.getRequirements();
		}
	}
	
	public class StudentWrapper
	{
		public Student__c student{get;set;}
		public boolean isSelected{get;set;}

		public StudentWrapper(Student__c stu)
		{
			student = stu;
			isSelected = false;
		}
	}
	
	public class CohortReqWrapper
	{

		public List <Cohort_Requirement__c> cohReqList {get;set;}
		public string courseString {get;set;}
		public Id				subjectId {get;set;}
		public string 		subjectName {get;set;}
		public Cohort_Requirement__c newCohReq {get;set;}
		public Decimal	dCredits 	{get;set;}
		public CohortReqWrapper(){
			this.cohReqList = new List <Cohort_Requirement__c>();
		}
		
		public CohortReqWrapper(Cohort_Requirement__c cr){
			this.subjectId = cr.subject_area__c; 
			this.subjectName = cr.subject_area__r.name;
			this.cohReqList = new List <Cohort_Requirement__c>{cr};
			this.dCredits = cr.credits__c;
			this.courseString = cr.course__r.name+'<br/>';
		}
	}
}