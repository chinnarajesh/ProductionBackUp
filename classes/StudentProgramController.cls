public with sharing class StudentProgramController {
	public List<SelectOption> indicatorAreas	{get;set;}
	public String selectedIndicatorArea			{get;set;}
	public List<SelectOption> grades			{get;set;}
	public String selectedGrade					{get;set;}
	public List<SelectOption> filterSections	{get;set;}
	public String selectedFilterSection			{get;set;}
	public List<SelectOption> programs			{get;set;}
	public String selectedProgram				{get;set;}
	public List<SelectOption> staff				{get;set;}
	public String selectedStaff					{get;set;}

	private Set<ID> selectedStudentIDs;

	public String programName {get; private set;}
	public String programDescription {get; private set;}
	public String indicatorArea {get; private set;}
	public String recFreq {get; private set;}
	public String recTimeSess {get; private set;}
	public String recTimeDos {get; private set;}

	private Map<Id,Program__c> programMap;
	private Map<ID, ID> programToAccountProgramMap;
	private Map<ID, Staff__c> staffMap;

	private Map<String, Map<String, studentWrapper>> activeMapAvailable; 
	private Map<String, Map<String, studentWrapper>> allStudentsWrapper; 
	private Map<String, studentWrapper> activeMapSelected = new Map<String, studentWrapper>();
	private Map<Id, Student__c> studentsInSite;
	private Map<ID, List<SelectOption>> schoolGradeMap = new Map<ID, List<SelectOption>>();
	
	private List<String> programIds = new List<String>();
	private List<Indicator_Area__c> areas;
	private List<Section__c> sections = new List<Section__c>();
	private Map<Id, Map<String, studentWrapper>> studentsInOtherSections = new Map<Id, Map<String, studentWrapper>>();
	public List<studentWrapper> availableStudents {get; private set;}
	public List<studentWrapper> selectedStudents {get; private set;}
	public List<Account> schools;
	public String activeSchoolID {get;set;}
	public String activeIAId {get; public set;}
	
	public Boolean isMultipleSchools {get; private set;}
	public Boolean isRerenderDetails {get; private set;}
	public String activeSchoolName {get; private set;}
	public Section__c sectionHolder {get; set;}
	public List<String> freqChecks {get; set;}
	public String sentIds {get; set;}
	public Student_Section__c stuSecHolder {get; set;}
	public String activeSectionId {get; public set;}
	private ApexPages.StandardController cont;
	
	public string prevProg {get; private set;}
	public Boolean isAvailableStudents {get; private set;}
	public Boolean isSelectedStudents {get; private set;}
	public Boolean isChange {get; private set;}
	public Boolean isClone {get; private set;}

	private String interventionsPackageNamespace = (Schema.SObjectType.Account_Program__c.getName().replace('__c', '').contains('__'))?'Interventions__':'';
	public Map<String, String> mapRTNameToId {get; private set;} 
	
	public StudentProgramController(ApexPages.StandardController controller){ 
		cont = controller; 
		freqChecks = new List<String>();
		availableStudents = new List<studentWrapper>();
		selectedStudents = new List<studentWrapper>();
		selectedStudentIDs = new Set<ID>();
		mapRTNameToId = new Map<String, String>{
			'Intervention Section' => CT_core_SoqlUtils.getRecordTypeIdBySobject('Section__c', 'Intervention Section'),
			'Curriculum' => CT_core_SoqlUtils.getRecordTypeIdBySobject('Section__c', 'Curriculum')
		};

		sectionHolder = new Section__c(RecordTypeID = mapRTNameToId.get('Intervention Section'));
		stuSecHolder = new Student_Section__c();
		selectedFilterSection = selectedIndicatorArea = selectedGrade = 'null';
		grades = new List<SelectOption>();

		loadSchools();

		isClone = Apexpages.currentPage().getParameters().get('clone') != null;
		if(isClone) {
			getSectionToClone();
		}
			
		changeSchool();

		if(isClone){
			if(programMap.containsKey(sectionHolder.Program__c)){
				selectedProgram = sectionHolder.Program__c;
			} else {
				
			}
			
		}
	}

	public void changeSchool(){
		selectedGrade = 'null';
		selectedIndicatorArea = 'null';
		selectedFilterSection = 'null';

		loadSchoolInfo();
		loadAvailableStudents();
	}

	public void addStudents(){
		List<studentWrapper> tempWrapper = new List<StudentWrapper>();
		for(StudentWrapper sw:availableStudents){
			if(selectedStudents.size()+tempWrapper.size() >= 1000){
				CyUtil.errorMessage('You have already selected 1000 students for addition. Please finalize this addition before adding more students');
				break;
			} else if(sw.checked){
				sw.checked = false;
				selectedStudents.add(sw);
				selectedStudentIds.add(sw.studentId);
			} else {
				tempWrapper.add(sw);
			}
		}
		availableStudents = tempWrapper;
	}

	public void removeStudents(){
		List<studentWrapper> tempWrapper = new List<StudentWrapper>();
		for(StudentWrapper sw:selectedStudents){
			if(!sw.checked){
				tempWrapper.add(sw);
			} else {
				selectedStudentIDs.remove(sw.studentId);
			}
		}
		selectedStudents = tempWrapper;
		loadAvailableStudents();
	}

	public void changeSection(){
		selectedIndicatorArea = 'null';
		loadAvailableStudents();
	}

	public void changeIndicatorArea(){
		loadAvailableStudents();
	}

	public void changeGrade(){
		loadAvailableStudents();
	}

	private void loadSchools(){
		schools = CYUtil.getAllActiveSchools();
		if(schools.isEmpty()){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.error,'No schools are available for your user.'));

			schools = new List<Account>();
			areas = new List<Indicator_Area__c>();
		} else {
			activeSchoolName = schools[0].Name;
			activeSchoolID = schools[0].Id;
		}

		isMultipleSchools = (schools.size() > 1);
	}

	private void loadSchoolInfo(){
		if(activeSchoolID != null){
			availableStudents = new List<studentWrapper>();
			loadPrograms(activeSchoolID);
			if(programMap.isEmpty()){
				CyUtil.errorMessage('There are no active programs for this school.');
			} else {
				if(!programMap.containsKey(sectionHolder.Program__c)){
					selectedProgram = programMap.values()[0].id;
					if(isClone){
						CYUtil.warningMessage('The program for the section you are cloning is not available. You will have to select a different program.');
					}
				} else {
					selectedProgram = sectionHolder.Program__c;
				}
				
				setProgramDetails();
			}
			loadStaffMembers(activeSchoolID);
			if(staff.isEmpty()){
				CyUtil.errorMessage('There are no active staff for this school.');
			}
		}		
	}

	private void loadPrograms(String schoolId) {
		List<Account_Program__c> accountPrograms = [SELECT ID, Program__c, Program__r.Name, Program__r.Program_Description__c, Program__r.Indicator_Area__r.Name, Program__r.Indicator_Area__c,
			Program__r.Recommended_Weekly_Frequency__c, Program__r.Recommended_Time_per_Session__c, Program__r.Overall_Target_Dosage__c   
			FROM Account_Program__c where School__c = :schoolId AND Active__c = true order by Program__r.Name];

		programMap = new Map<ID, Program__c>();
		programs = new List<SelectOption>();
		programToAccountProgramMap = new Map<ID, ID>();
		for(Account_Program__c ap: accountPrograms){
			if(!programMap.containsKey(ap.Program__r.ID)){
				programs.add(new SelectOption(ap.Program__c, ap.Program__r.Name));
				programMap.put(ap.Program__c, ap.Program__r);
				programToAccountProgramMap.put(ap.Program__c, ap.ID);
			}
		}
	}

	private void loadAvailableStudents(){
		availableStudents = new List<studentWrapper>();
		Boolean isUnfiltered = selectedFilterSection == 'null' && selectedGrade == 'null' && selectedIndicatorArea == 'null';
		try{
			DMLManager.checkFieldAccessability('Student__c', new Set<String>{'Student_Last_Name__c','Student_First_Name__c','Grade__c'});
			DMLManager.checkFieldAccessability(interventionsPackageNamespace+'Indicator_Area_Student__c', new Set<String>{'Name'});
		} catch(DMLManager.FLSException e){
			CyUtil.errorMessage(e.getMessage());
			return;
		}

		string query='select id, Student_Last_Name__c, Student_First_Name__c, Grade__c, Student_Id__c'+
						',(select Indicator_Area__c, Indicator_Area__r.Name from Indicator_Area_Student__r where Active__c = true order by Indicator_Area__r.Name)';


		if(selectedFilterSection != 'null'){
			query += ',(select ID, Section__c, Section__r.Name from Student_Section__r where Active__c = true and Section__c=\''+String.escapeSingleQuotes(selectedFilterSection)+'\')';
		} else {
			query += ',(select ID, Section__c, Section__r.Name from Student_Section__r where Active__c = true)';
		}

		query += ' FROM Student__c'+
				' where School__c = \''+String.escapeSingleQuotes(activeSchoolID)+'\''+
				' and Active__c = true'+
				' and ID NOT IN: selectedStudentIDs';

		if(selectedGrade != 'null' && selectedGrade != null){
			query += ' and Grade__c = \''+String.escapeSingleQuotes(selectedGrade)+'\'';
		}

		query += ' order by Grade__c, Student_Last_Name__c, Student_First_Name__c';
		system.debug(query);

		Map<ID, SelectOption> indicatorAreaMap = new Map<ID, SelectOption>();
		Map<ID, SelectOption> sectionMap = new Map<ID, SelectOption>();
		Set<String> studentGrades = new Set<String>();
		Integer studentVolume = 0;

		for(Student__c student:Database.query(query)){
			if(isUnfiltered){
				studentGrades.add(student.Grade__c);
				for(Student_Section__c ss:student.Student_Section__r){
					sectionMap.put(ss.Section__c, new SelectOption(ss.Section__c, ss.Section__r.Name));
				}
			} else if(selectedFilterSection != 'null' && student.Student_Section__r.isEmpty()){
				continue;
			}
			
			studentVolume++;
			Boolean foundExpected = selectedIndicatorArea == 'null';
			Set<String> studentIndicatorAreas = new Set<String>();
			for(Indicator_Area_Student__c ias: student.Indicator_Area_Student__r){
				foundExpected = foundExpected || ias.Indicator_Area__c == selectedIndicatorArea;
				studentIndicatorAreas.add(ias.Indicator_Area__r.Name);
				if(isUnfiltered){
					indicatorAreaMap.put(ias.Indicator_Area__c, new SelectOption(ias.Indicator_Area__c, ias.Indicator_Area__r.Name));
				}
			}

			if(foundExpected && studentVolume<1001){
				String studentName = student.Student_Last_Name__c+', '+student.Student_First_Name__c;
				List<String> siaHolder = new List<String>(studentIndicatorAreas);
				siaHolder.sort();
				availableStudents.add(new studentWrapper(student, String.join(siaHolder,'; '), null));
				//availableStudents.add(new studentWrapper(student, '', null));
			}
		}

		if(studentVolume>1000){
			CYUtil.infoMessage('There are more than 1000 students in this school. Please use the grade filter to view the students you wish to add.');
//			if(!availableStudents.isEmpty()){
//				selectedGrade = availableStudents[0].gradeLevel;
//			}
			List<StudentWrapper> singleGradeList = new List<StudentWrapper>();

			Integer i=0;
			for(StudentWrapper s:availableStudents){
				if(i>1000){
					break;
				}
				singleGradeList.add(s);
				i++;
//				if(s.gradeLevel == selectedGrade){
//					singleGradeList.add(s);
//				} else {
//					break;
//				}
			}
			availableStudents = singleGradeList;
		}

		if(isUnfiltered){
			grades = new List<SelectOption>();
//			if(studentVolume < 1000){
				grades.add(new SelectOption('null', 'Choose a grade'));
//			}

			indicatorAreas = indicatorAreaMap.values();
			filterSections = sectionMap.values();

			List<SelectOption> allGrades = new List<SelectOption>();

			if(!schoolGradeMap.containsKey(activeSchoolID)){
				for(Schema.PicklistEntry val: Schema.sObjectType.Student__c.fields.Grade__c.getPicklistValues()){
					if(studentGrades.contains(val.getLabel())){
						allGrades.add(new SelectOption(val.getLabel(),val.getLabel()));
					}
				}

				grades.addAll(allGrades);
				schoolGradeMap.put(activeSchoolID, grades);
			} else {
				grades = schoolGradeMap.get(activeSchoolID);
			}

			indicatorAreas.sort();
			filterSections.sort();
		}
	}

	@testVisible
	private void getSectionToClone(){
		try{
			DMLManager.checkFieldAccessability('Section__c', new Set<String>{'Name','Section_Frequency__c'});
			DMLManager.checkFieldAccessability(interventionsPackageNamespace+'Program__c', new Set<String>{'Name','Program_Description__c',
				'Recommended_Weekly_Frequency__c','Recommended_Time_per_Session__c','Overall_Target_Dosage__c'});
			DMLManager.checkFieldAccessability(interventionsPackageNamespace+'Indicator_Area__c', new Set<String>{'Name'});
		} catch(DMLManager.FLSException e){
			CYUtil.errorMessage(e.getMessage());
			return;
		}

		Section__c section = new Section__c();
		Section__c queriedSection = new Section__c();
		List<Section__c> query  = [SELECT s.Target_Dosage_Section_Goal__c,s.Target_Dosage_Org_Goal__c, s.Start_Date__c, 
												s.Section_Frequency__c, s.Recommended_Time_per_Session__c, s.Program__c, s.Name, 
												s.Intervention_Primary_Staff__c, s.Notes__c, s.Indicator_Area__c, s.In_After_School__c, s.School__c, 
												s.Id, s.End_Date__c, s.Additional_Information__c, s.Account_Program__c From Section__c s  
												WHERE s.ID = :cont.getId()];
												
		if(query.size() > 0) queriedSection = query[0];
		else return;
		
		activeSchoolID = queriedSection.School__c;

		section = queriedSection.clone(false, true);
		system.debug('cloning section with program:'+section.Program__c);

		//set up the frequency string
		if(queriedSection.Section_Frequency__c!=null){
			freqChecks	= queriedSection.Section_Frequency__c.split(';');
		}else{
			CYUtil.errorMessage('The section to clone ('+queriedSection.Name+') does not have a section frequency.  This field is required.  Please fill out a section frequency for this section.');
		}
		sectionHolder = section;
		sectionHolder.Program__c = queriedSection.Program__c;
	}

	public void changeProgram(){
		setProgramDetails();
	}

	private void setProgramDetails(){
		try{
			DMLManager.checkFieldAccessability(interventionsPackageNamespace+'Program__c', new Set<String>{'Name','Program_Description__c',
				'Recommended_Weekly_Frequency__c','Recommended_Time_per_Session__c',
				'Overall_Target_Dosage__c'});
		} catch(DMLManager.FLSException e){
			CYUtil.errorMessage(e.getMessage());
			return;
		}

		freqChecks.clear();
		sectionHolder = new Section__c();
		stuSecHolder = new Student_Section__c();
		if(selectedProgram != null && programMap != null){
			Program__c currentProgram = programMap.get(selectedProgram);
			programName = currentProgram.Name;
			programDescription = (currentProgram.Program_Description__c != '' && currentProgram.Program_Description__c != null)?currentProgram.Program_Description__c:'Description is not Available';
			indicatorArea = (currentProgram.Indicator_Area__c != null)?currentProgram.Indicator_Area__r.Name:'Indicator Area is not Available';
			recFreq = (currentProgram.Recommended_Weekly_Frequency__c != null)?currentProgram.Recommended_Weekly_Frequency__c:'Recommeneded Frequency per Week is not Available';
			recTimeSess = (currentProgram.Recommended_Time_per_Session__c != null)?String.valueOf(currentProgram.Recommended_Time_per_Session__c)+' minutes':'Recommended Time is not Available';
			recTimeDos = (currentProgram.Overall_Target_Dosage__c != null)?String.valueOf(currentProgram.Overall_Target_Dosage__c)+' minutes':'Recommended Total Dosage is not Available';
		}
	}

	public List<SelectOption> getFreqOptions() {
		List<SelectOption> options = new List<SelectOption>();
		Schema.DescribeFieldResult days = Schema.sObjectType.Section__c.fields.Section_Frequency__c;
		Schema.PicklistEntry [] values = days.getPickListValues();
		
		for(Schema.PicklistEntry val : values){
			options.add(new SelectOption(val.getValue(), val.getLabel().substring(0,3)));
		}
		
		return options;
	}

	public List<SelectOption> getSchoolList() {
		List<SelectOption> options = new List<SelectOption>();
		for(Account a :schools) options.add(new SelectOption(a.Id, a.Name));
		return options;
	}

	private void loadStaffMembers(string schoolId) {
		staff = new List<SelectOption>();
		staffMap = new Map<Id, Staff__c>();
		for(Staff__c s: [SELECT Id, Name, Staff_Last_Name__c FROM Staff__c
				WHERE Active__c = true AND Organization__c = :schoolId
				ORDER BY Name]){
			staff.add(new SelectOption(s.Id, s.Name));
			staffMap.put(s.ID, s);
		}
		selectedStaff = staff.isEmpty()? null: staff[0].getValue();
	}

	private String createSection() {
		if(!validateForm()){
			return null;
		}

		String freq = '';
		for(String f :freqChecks) {
			freq+=f+';';
		}
		Section__c section = new Section__c(
			Name = 'Section', 
			School__c = activeSchoolID,
			Program__c = programMap.get(selectedProgram).ID,
			Time__c = CYUtil.getSchoolYearID(activeSchoolID),
			RecordTypeId = sectionHolder.In_After_School__c=='Curriculum'? mapRTNameToId.get('Curriculum'): mapRTNameToId.get('Intervention Section'),
			Start_Date__c = sectionHolder.Start_Date__c,
			End_Date__c = sectionHolder.End_Date__c,
			Intervention_Primary_Staff__c = staffMap.get(selectedStaff).ID,
			In_After_School__c = sectionHolder.In_After_School__c,
			Notes__c = sectionHolder.Notes__c,
			Section_Frequency__c = freq,
			Target_Dosage_Section_Goal__c = sectionHolder.Target_Dosage_Section_Goal__c,
			Account_Program__c = programToAccountProgramMap.get(selectedProgram),
			Active__c = true
		);
		
		section.name = programMap.get(selectedProgram).Name+staffMap.get(selectedStaff).Staff_Last_Name__c;
			
		try {
			DMLManager.upsertAsUser(new Section__c[]{section});
		} catch(DMLManager.CRUDException e){
			CyUtil.errorMessage('User lacks permissions to create section records.');
			return null;
		} catch(DMLManager.FLSException e){
			CyUtil.errorMessage('User lacks permissions to key fields on section.');
			return null;
		} catch(System.DMLException e){
			CyUtil.errorMessage(e.getDmlMessage(0));
			return null;
		}

		addStudents(section.Id);
		
		system.debug('section id: '+section.id);
		return section.id;
	}

	public Pagereference saveSection() {
		String insertedID = createSection();
		if(insertedID == null) {
			return null;
		}

		return new Pagereference('/'+insertedID);
	}

	public Pagereference saveAndNewSection() {
		String insertedID = createSection();
		if(insertedID == null) {
			return null;
		}

		PageReference pageRef =new Pagereference('/apex/IM_AddStudentsToPrograms'); //reload page after inserting(for Save and New button)
		pageRef.setRedirect(true);
		return pageRef;
	}

	private void addStudents(String programId) {
		List<Student_Section__c> stuSecList = new List<Student_Section__c>();
		if(selectedStudents.isEmpty())
			return;
		for(studentWrapper s :selectedStudents) {
			Student_Section__c ss = new Student_Section__c();
			ss.Section__c = programId;
			ss.Student__c = s.studentId;
			ss.Enrollment_Start_Date__c = stuSecHolder.Enrollment_Start_Date__c;
			ss.Intervention_Enrollment_Start_Date__c = stuSecHolder.Enrollment_Start_Date__c;
			ss.Section_Exit_Reason__c = null;
			ss.Active__c = true;
			stuSecList.add(ss);
		}
		
		try{
			DMLManager.insertAsUser(stuSecList);
		} catch(DMLManager.CRUDException e){
			CyUtil.errorMessage('User lacks permissions to create student/section records.');
		} catch(DMLManager.FLSException e){
			CyUtil.errorMessage('User lacks permissions to key fields on student/section.');
		} catch(System.DMLException e){
			CyUtil.errorMessage('Unexpected exception while creating student/sections.');
		}
	}

	public void hasChange(){
		isChange = sectionHolder.Start_Date__c != null;
		system.debug('CHANGE IS '+isChange);
	}

	public boolean validateForm() {
		List<String> errors = new List<String>();
		if(selectedStaff == 'null'){
			errors.add('Intervention Primary Staff is required');
		}
		if(sectionHolder.Start_Date__c == null){
			errors.add('Start date is required');
		}
		if(sectionHolder.End_Date__c == null){
			errors.add('End date is required');
		}
//		if(freqChecks == null || freqChecks.size() == 0){
//			errors.add('Section Frequency is required');
//		}
		if(sectionHolder.In_After_School__c == null){
			errors.add('In School/Extended Learning/Curriculum is required');
		}		
//		if(sectionHolder.Target_Dosage_Section_Goal__c == null){
////			errors.add('Target Dosage (Section Goal) is required');
////		}
		if(selectedStudents.size() > 0) {
			if(stuSecHolder.Enrollment_Start_Date__c == NULL){
				errors.add('Enrollment date is required');
			} else if(stuSecHolder.Enrollment_Start_Date__c < sectionHolder.Start_Date__c || stuSecHolder.Enrollment_Start_Date__c > sectionHolder.End_Date__c){
				errors.add('The enrollment date must be between the start and end dates of the section.');
			}
		}
		
		if (errors.size() > 0) {
			for (String errorMsg: errors) {
				CyUtil.errorMessage(errorMsg);
			}
			return false;
		}
		return true;
	}
}