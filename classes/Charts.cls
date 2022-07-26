global with sharing class Charts {
	public static String bigAssString				{get;set;}//block of all assignment data compacted into one string
	public static String assignmentDataString		{get;set;}
	public static String bigStanString				{get;set;}//block of overall standard grade data
	public static String bigStudentString			{get;set;}//block of specific student data 
	public static List<SelectOption> students		{get;set;}	
	
	public Assignment__c startDate					{get;set;}
	public Assignment__c endDate					{get;set;}
	
	public string debugString						{get;set;}
	public boolean isAdmin							{get;set;}
	
	//print page variables
	public String currentChartData					{get;set;}
	public String currentChartType					{get;set;} 
	public String currentChartState					{get;set;}
	public String currentChartView					{get;set;}
	
	//students found via getStudents
	public List<studentWrapper> wrappedStudents		{get;set;}
	public List<studentWrapper> selectedStudents	{get;set;}
	public string selectedStudentsJsonString		{get;set;}
	public string selectedStandardsJsonString		{get;set;}
	
	public set<ID> studentIDs;
	public set<ID> standardIDs;
	//reports page variables	
	public List<SelectOption> availableSchools		{get;set;}
	public List<String> selectedSchool				{get;set;}
	public List<SelectOption> availableSections		{get;set;}
	public List<String> selectedSection				{get;set;}
	public List<SelectOption> availableGrades		{get;set;}
	public List<SelectOption> availableTeachers		{get;set;}
	//holds all student race options  
	public List<SelectOption> raceOptions			{get;set;}
	public Map<String, List<SelectOption>> schoolToTeachersOptionsMap;
	public Map<String, List<SelectOption>> teacherToSectionOptionsMap;		  
	public List<String> selectedTeacherIDs			{get;set;}
	public List<String> selectedGrade				{get;set;}
	public String selectedELL						{get;set;}
	public String selectedIEP						{get;set;}
	public String selectedCityWide					{get;set;}		  
	public Student__c dummyStudent					{get;set;}
	public Map<String, List<SelectOption>>  schoolToSectionOptionsMap;
	public Map<String, Set<ID>> schoolToSectionSetMap;
	public map<ID, Standard__c> infoMap;
	
	//constants
	public String TEACHER							{get{return 'TEACHER';}set;}
	public String SECTION							{get{return 'SECTION';}set;}
	
	//Standard Calculation variables
	public String None								{get{return '--None--';}set;}
	public String Most_Recent_Grade					{get{return 'Most Recent Grade';}set;}
	public String Highest_Grade						{get{return 'Highest Grade';}set;}
	public String Mean_Grade						{get{return 'Mean Grade';}set;}
	public String Law_of_Decaying_Average_Grade		{get{return 'Law of Decaying Average Grade';}set;}
	public String Power_Law_Grade					{get{return 'Power Law Grade';}set;}
	public List<SelectOption> calcType				{get{
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption(None, '--None--'));
		options.add(new SelectOption(Most_Recent_Grade, 'Most Recent Grade'));
		options.add(new SelectOption(Highest_Grade, 'Highest Grade'));
		options.add(new SelectOption(Mean_Grade, 'Mean Grade'));
		options.add(new SelectOption(Law_of_Decaying_Average_Grade, 'Law of Decaying Average Grade'));
		options.add(new SelectOption(Power_Law_Grade, 'Power Law Grade'));
		return options;
	}set;}
	public String selectedCalcType					{get;set;}	
	
	//reports page standard search variables
	public List<standardWrapper> wrappedStandards	{get;set;}
	public List<standardWrapper> selectedStandards	{get;set;}
	public Standard__c dummyStandard				{get;set;}
	public String standardCourseSearch				{get;set;}
	public String standardStrandSearch				{get;set;}
	public String standardSubjectSearch				{get;set;}
	public String standardParentStandardSearch		{get;set;}
	   
	///////new strings
	public String jSonString1 {get; set;} 
	public String jSonString2 {get; set;} 
	public String jSonString3 {get; set;} 
		
	public Charts(){
		bigAssString = '0';
		startDate = new Assignment__c();
		endDate   = new Assignment__c();
		infoMap = new Map<ID, Standard__c>();
		schoolToSectionOptionsMap = new Map<String, List<SelectOption>>();
		schoolToTeachersOptionsMap = new Map<String, List<SelectOption>>();
		teacherToSectionOptionsMap = new Map<String, List<SelectOption>>();			 
		schoolToSectionSetMap = new Map<String, Set<ID>>();
		selectedTeacherIDs = new List <String>();
		selectedSchool = new List<String> ();  
		currentChartType = '';
		currentChartData = '';
		currentChartState = ''; 
		currentChartView = '';
		selectedCalcType = '';
		
		if (ApexPages.currentPage().getParameters().get('currentChartType')!=null){
			currentChartType = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('currentChartType'));			   
		}
		if (ApexPages.currentPage().getParameters().get('currentChartData')!=null){
			currentChartData = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('currentChartData'));		   
		}
		if (ApexPages.currentPage().getParameters().get('currentChartState')!=null){
			currentChartState = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('currentChartState'));			 
		}
		if (ApexPages.currentPage().getParameters().get('currentChartView')!=null){
			currentChartView = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('currentChartView'));			 
		}
	}

	public void loadFilters(){
		selectedSection		 = new List<String>();
		dummyStandard		 = new Standard__c();
		wrappedStandards	 = new List<standardWrapper>();
		selectedStandards	 = new List<standardWrapper>();
		wrappedStudents		 = new List<studentWrapper>();
		selectedStudents	 = new List<studentWrapper>();
		dummyStudent		 = new Student__c();
		availableSchools	 = new List<SelectOption>();
		availableSections	 = new List<SelectOption>();
		availableGrades		 = new List<SelectOption>();
		availableTeachers	 = new List<SelectOption>();
		raceOptions			 = new List<SelectOption>(); 
		selectedGrade		 = new List<String>();
		Set<ID> staffIDs	 = new Set<ID>();
		
		Schema.DescribeFieldResult fieldResult = Student__c.Grade__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for(Schema.PicklistEntry f : ple) {
			availableGrades.add(new selectOption(f.getLabel(), f.getValue()));
		}
		
		//get all race options from student
		fieldResult = Student__c.Race_Multi__c.getDescribe();
		ple = fieldResult.getPicklistValues();
		for(Schema.PicklistEntry f : ple){
			raceOptions.add(new SelectOption(f.getLabel(), f.getValue()));
		}
		
		Contact con = core_SoqlUtils.getLoggedInContact();
		//if no contact record, throw error
		if(con==null){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.error,'Your user is not associated with a contact record.  Please contact your administrator.'));
		} else {
			for(Staff__c s:core_SoqlUtils.getContactStaffList(con.id)){
				staffIDs.add(s.id);
				if(s.Organization__c!=null){
					availableSchools.add(new SelectOption(s.organization__c, s.Organization__r.Name));
				}
				availableTeachers.add(new SelectOption(s.ID, s.Name));
				//map school to staff
				if(schoolToTeachersOptionsMap.containsKey(s.Organization__c)) schoolToTeachersOptionsMap.get(s.Organization__c).add(new SelectOption(s.ID, s.Name));
				else schoolToTeachersOptionsMap.put(s.Organization__c, new List<SelectOption>{new SelectOption(s.ID, s.Name)});
				
				for(Staff_Section__c ss : s.Staff_Section__r){
					availableSections.add(new SelectOption(ss.Section__c, ss.Section__r.Name));
					//map school to sections
					if(schoolToSectionOptionsMap.containsKey(s.Organization__c)){
						schoolToSectionOptionsMap.get(s.Organization__c).add(new SelectOption(ss.Section__c, ss.Section__r.Name));
						schoolToSectionSetMap.get(s.Organization__c).add(ss.Section__c);
					}
					else{
						schoolToSectionOptionsMap.put(s.Organization__c, new List<SelectOption>{new SelectOption(ss.Section__c, ss.Section__r.Name)});
						schoolToSectionSetMap.put(s.Organization__c, new Set<ID>{ss.Section__c});
					}
					//map staff record to sections
					if(teacherToSectionOptionsMap.containsKey(s.ID)){
						teacherToSectionOptionsMap.get(s.ID).add(new SelectOption(ss.Section__c, ss.Section__r.Name));
					}
					else{
						teacherToSectionOptionsMap.put(s.ID, new List<SelectOption>{new SelectOption(ss.Section__c, ss.Section__r.Name)});
					}
					
				}
			}
			
			if(staffIDs.size()==0){//no staff records, throw error
				ApexPages.addMessage(new apexpages.message(apexpages.severity.error,'Your contact record is not associated with any staff records.  Please contact your administrator.'));
			}
		}
		
		//figure out if a teacher is an admin
		isAdmin = false;
		User loggedInUser = [Select Id, Name, Profile.Name from User where id =:UserInfo.getUserId()];
		if(loggedInUser.Profile.Name == 'System Administrator' || loggedInUser.Profile.Name == 'DOE Admin') {
			isAdmin = true;
		}
		
		if(isAdmin){
			for(Account a :[Select ID, Name from Account WHERE (RecordType.Name='School' or RecordType.Name='Summer School')]){
				availableSchools.add(new SelectOption(a.ID, a.Name));
			}
			ApexPages.addMessage(new apexpages.message(apexpages.severity.info,'Please select the schools you would like to report on to populate Teacher and Section lists.'));
		}
		
		checkForOutOfBounds(availableSections,SECTION);
		checkForOutOfBounds(availableTeachers,TEACHER);
		List<String> schoolIDs = new List<String>();
		for(SelectOption so: availableSchools) schoolIDS.add(so.getValue());
		refreshDateRange(schoolIDs);
	}

	public void reRenderSections(){
		if(isAdmin){
			schoolToTeachersOptionsMap.clear();
			schooltoSectionOptionsMap.clear();
			teacherToSectionOptionsMap.clear();
			availableTeachers.clear();
			availableSections.clear();
			for(String str: selectedSchool){
				schoolToTeachersOptionsMap.put(str, new List<SelectOption>());
				schoolToSectionOptionsMap.put(str, new List<SelectOption>());
				schoolToSectionSetMap.put(str, new Set<ID>());
			}
			for(Staff__c s: [SELECT id, Name, Organization__c, (select Section__c, Section__r.Name from Staff_Section__r where Section__r.RecordType.DeveloperName = 'Published') FROM Staff__c WHERE Organization__c IN :selectedSchool]){
				schoolToTeachersOptionsMap.get(s.Organization__c).add(new SelectOption(s.id,s.Name));
				teacherToSectionOptionsMap.put(s.id, new List<SelectOption>());
				for(Staff_Section__c ss: s.Staff_Section__r){
					teacherToSectionOptionsMap.get(s.id).add(new SelectOption(ss.Section__c,ss.Section__r.Name));
				}
			}
			for(Section__c sec: [SELECT id, Name, School__c FROM Section__c WHERE School__c IN :selectedSchool AND RecordType.DeveloperName='Published']){
				schoolToSectionOptionsMap.get(sec.School__c).add(new SelectOption(sec.id,sec.Name));
				schoolToSectionSetMap.get(sec.School__c).add(sec.id);
			}
		}
		
		if(selectedTeacherIDs.size()==0 && selectedSchool.size()>0){//user only has selected schools
			availableSections = new List<SelectOption>();
			availableTeachers = new List<SelectOption>();
			for(String s : selectedSchool){
				system.debug('SelectedSchool ' + s);
				availableSections.addAll(schoolTosectionOptionsMap.get(s));
				availableTeachers.addAll(schoolToTeachersOptionsMap.get(s));
			}
		}
		else if(selectedTeacherIDs.size()>0 && selectedSchool.size()==0){//user only has selected teachers
			availableSections = new List<SelectOption>();
			for(String s : selectedTeacherIDs){
				system.debug('SelectedSchool ' + s);
				availableSections.addAll(teacherToSectionOptionsMap.get(s));
			}
		}
		else if(selectedTeacherIDs.size()>0 && selectedSchool.size()>0){
			//user has selected both teachers and schools
			//this is an incredibly inefficient way to reduce the choices of sections
			//the processing will only get excessive if you "select all" on both lists
			availableSections = new List<SelectOption>();
			availableTeachers = new List<SelectOption>();
			for(String school : selectedSchool){
				if (schoolToTeachersOptionsMap.get(school)!=null){
					availableTeachers.addAll(schoolToTeachersOptionsMap.get(school));
					for(String teachers : selectedTeacherIDs){
						for(SelectOption schoolGeneratedOptions : schoolTosectionOptionsMap.get(school)){
							for(SelectOption teacherGeneratedOptions : teacherToSectionOptionsMap.get(teachers)){
								if(schoolGeneratedOptions.getValue()==teacherGeneratedOptions.getValue()){
									availableSections.add(teacherGeneratedOptions);
								}
							}
						}
					}
				}
			}
		}
		
		//check for size limits
		checkForOutOFBounds(availableTeachers,TEACHER);
		checkForOutOfBounds(availableSections,SECTION);
		if(selectedSchool.size()>0) refreshDateRange(selectedSchool);
	}
	
	public void checkForOutOfBounds(List<SelectOption> checkList, String listType){
		if(checkList.size()>1000){
			List<SelectOption> temp = checkList.clone();
			checkList.clear();
			for(integer i=0;i<1000;i++) checkList.add(temp[i]);

			if(listType==SECTION) ApexPages.addMessage(new apexpages.message(apexpages.severity.info,'There is a 1,000 record display limit.  Only the first 1,000 sections are available for selection.  If you do not see your section, please narrow down your selection by school or teacher'));
			if(listType==TEACHER) ApexPages.addMessage(new apexpages.message(apexpages.severity.info,'There is a 1,000 record display limit.  Only the first 1,000 teachers are available for selection.  If you do not see your teacher, please narrow down your selection by school.'));
		}
	}
	
	public void refreshDateRange(List<String> schoolIDs){
		List<Setup__c> setups = [SELECT id, Year__r.Date_Start_Date__c, Year__r.End_Date__c FROM Setup__c WHERE Active__c=true and School__c IN :schoolIDs];
		Date tmpStartDate, tmpEndDate;
		for(Setup__c setup: setups){
			Date yearStart = setup.Year__r.Date_Start_Date__c;
			Date yearEnd = setup.Year__r.End_Date__c ;
			if(tmpStartDate==null || tmpStartDate > yearStart) tmpStartDate=yearStart;
			if(tmpEndDate==null || tmpEndDate < yearEnd) tmpEndDate=yearEnd;
		}
		startDate.Due_Date__c = tmpStartDate;
		endDate.Due_Date__c = tmpEndDate;
	}
			 
	public void searchStandards(){
		system.debug('selectedSection: ' + selectedSection);
		
		standardIDs = new Set<ID>();
				
		//set<id> studentIds = new set<id>();
		for(StandardWrapper s : selectedStandards){
		  standardIDs.add(s.standard.id);
		}
				
		wrappedStandards.clear();
		 //infoMap = new Map<ID, Standard__c>();
	
			string searchQuery ='Select Name, Level__c, Long_Text__c, Identifier__c, Id, Parent_Standard__c, Strand__c, Strand__r.Name, Subject__c, Attribute__c, Course__c, Course__r.Name From Standard__c ';
			string searchQueryWhere = 'where id!= null ';
			string idWild = '';
		  if(dummyStandard.Identifier__c!=null&&dummyStandard.Identifier__c!=''){
			if(dummyStandard.Identifier__c.contains('*')){
					idWild	 = dummyStandard.Identifier__c.replace('*', '');
			}
			else{
				idWild = dummyStandard.Identifier__c;
			}
			searchQueryWhere = searchQueryWhere + 'AND Identifier__c LIKE \'%'  +  String.escapeSingleQuotes(idWild) + '%\'';
		  }
		  if(standardCourseSearch!=null&&standardCourseSearch!=''){
			if(standardCourseSearch.contains('*')){
				standardCourseSearch=standardCourseSearch.replace('*', '');
			}
				searchQueryWhere = searchQueryWhere + 'AND Course__r.Name LIKE \'%' + String.escapeSingleQuotes(standardCourseSearch) + '%\'';
		  }
		  ////system.debug('where: '+searchQueryWhere);
		  if(standardStrandSearch!=null&&standardStrandSearch!=''){
			if(standardStrandSearch.contains('*')){
				standardStrandSearch = standardStrandSearch.replace('*', '');
			}
			searchQueryWhere = searchQueryWhere + 'AND Strand__r.Name LIKE \'%' + String.escapeSingleQuotes(standardStrandSearch) + '%\'';
		  }
		  ////system.debug('where: '+searchQueryWhere);
		  if(standardSubjectSearch!=null&&standardSubjectSearch!=''){
			if(standardParentStandardSearch.contains('*')){
				standardSubjectSearch   = standardSubjectSearch.replace('*', '');
			}
				searchQueryWhere = searchQueryWhere + 'AND Subject__c LIKE \'%' + String.escapeSingleQuotes(standardSubjectSearch) + '%\'';
		  }		  
		  ////system.debug('where: '+searchQueryWhere);
		  if(standardParentStandardSearch!=null&&standardParentStandardSearch!=''){
			if(standardParentStandardSearch.contains('*')){
				standardParentStandardSearch	= standardParentStandardSearch.replace('*', '');
			}
				searchQueryWhere = searchQueryWhere + 'AND Parent_Standard__r.Identifier__c LIKE \'%' + String.escapeSingleQuotes(standardParentStandardSearch) + '%\'';
		  }
		  
		//attributes
		Set<String> AttributeSet = new Set<String>();
		if(dummyStandard.Attribute__c !='None' && dummyStandard.Attribute__c !=null){
			for(String tempStr : dummyStandard.Attribute__c.split(',')){
				AttributeSet.add(tempStr);
			}
		searchQueryWhere += ' AND Attribute__c IN : AttributeSet ';			
		}

		//if(dummyStandard.Attribute__c !='None' && dummyStandard.Attribute__c !=null){
		//	searchQueryWhere += ' AND Attribute__c IN : AttributeSet ';
		//}		
				   
		  if(selectedCityWide != null && selectedCityWide == 'true'){
		  	searchQueryWhere += ' AND Citywide_Instructional_Expectation__c	 = true ';
		  }
		  if(selectedCityWide !=null && selectedCityWide == 'false'){
		  	searchQueryWhere += ' AND Citywide_Instructional_Expectation__c	 =  false ';
		  }		  
		  //system.debug('----------Standard Query up to city wide ------------> '+searchQueryWhere);
		  if(standardIDs.size() > 0){
		  	searchQueryWhere = searchQueryWhere  + ' AND ID NOT IN : standardIDs '; 
		  }		  
		  string query = searchQuery + searchQueryWhere + 'AND Strand__c != null order by Name, Level__c DESC, Name limit 1000';
		  for (Standard__c stan: Database.query(query)){
			
			if(stan.Long_Text__c != null){
				if(stan.Long_Text__c.contains('&')){
					stan.Long_Text__c = stan.Long_Text__c.replace('&', 'and');
				}
			}		   
				wrappedStandards.add(new standardWrapper(stan));
				infoMap.put(stan.id, stan);
		  }
	}
	public void selectStandards(){
		list<integer> indexes = new list<integer>();
		integer index = 0;
		
		//add to selected list
		list<standardWrapper> temp = new list<standardWrapper>();
		for(standardWrapper s : wrappedStandards){
			if(s.selected){
				////system.debug('SELECTED!'  + s);
				s.selected = false;
				selectedStandards.add(s);
				indexes.add(index);
			}
			else{
				temp.add(s);
			}
			index++;
		}

		wrappedStandards.clear();
		wrappedStandards.addAll(temp);
		selectedStandardsJsonString = '[';
		for(standardWrapper s : selectedStandards)
		{
			selectedStandardsJsonString += '{"id": "'+s.Standard.id+'", "name": "'+s.Standard.Name+' - ' + s.Standard.Long_text__c + '"},';
		}
		selectedStandardsJsonString = selectedStandardsJsonString.substring(0, selectedStandardsJsonString.length() - 1);
		selectedStandardsJsonString += ']';
		////system.debug('Selected Standards: ' + selectedStandards);
		
	}
	
	public pageReference removeSelectedStandards(){
		String commaSeperatedStandards = Apexpages.currentPage().getParameters().get('removedStandards');
		list<String> removedStandardIdsList = commaSeperatedStandards.split(',');
		Set<String> removedStandardIds = new set<String>();
		for (string sts : removedStandardIdsList)
		{
			removedStandardIds.add(sts);
		}
		list<integer> indexes = new list<integer>();
		integer index = 0;
		list<standardWrapper> temp = new list<standardWrapper>();
		for(standardWrapper s : selectedStandards){
			if(removedStandardIds.contains(s.standard.id)){
				////system.debug('SELECTED!'  + s);
				s.selected = false;
				wrappedStandards.add(s);
				indexes.add(index);
			}
			else{
				temp.add(s);
			}
			index++;
		}
		selectedStandards.clear();
		selectedStandards.addAll(temp);
		return null;		
	}	 
	
   
	public void getStudents(){
		system.debug('~~~~~RACE '+dummyStudent.Race_Multi__c);
		studentIDs = new Set<ID>();
		
		
		//set<id> studentIds = new set<id>();
		for(StudentWrapper s : selectedStudents){
		  studentIds.add(s.student.id);
		}
		wrappedStudents.clear();
		Set<String> schoolsSet = new Set<String>();
		set<String> sectionsSet = new Set<String>();
		sectionsSet.addAll(selectedSection);
		schoolsSet.addAll(selectedSchool);
		Set<String> grades = new Set<String>();
		//if the selected section is part of the school, do not use the overall school
		for(string section : selectedSection){
			for(string school : selectedSchool){
				if(schoolToSectionSetMap.get(school).contains(section)){
					schoolsSet.remove(school);//do not use the overall school in the where query 
				}
			}
		}
		Set<ID> sectionSetPostSS = new Set<ID>(); //there is no "Section" field on student, so we need to go thru the student sections
		for(Student_Section__c ss : [Select Student__c from Student_Section__c where Section__c IN :sectionsSet]){
			sectionSetPostSS.add(ss.Student__c);
		}
		//ethnicity
		Set<String> EthnicitySet = new Set<String>();
		if(dummyStudent.Ethnicity__c!='None' && dummyStudent.Ethnicity__c!=null){
			for(String tempStr : dummyStudent.Ethnicity__c.split(',')){
				EthnicitySet.add(tempStr);
			}
		}
		//race
		List<String> RaceSet = new List<String>();
		if(dummyStudent.Race_Multi__c!='None' && dummyStudent.Race_Multi__c!=null){
			for(String tempStr : dummyStudent.Race_Multi__c.split(',')){
				tempStr = tempStr.trim();
				if(tempStr.startsWith('[')) tempStr = tempStr.subString(1,tempStr.length()).trim();
				if(tempStr.endsWith(']')) tempStr = tempStr.subString(0,tempStr.length()-1).trim();
				if(tempStr!='') RaceSet.add(tempStr);
			}
		}	
		system.debug('~~~~~RACESET '+RaceSet);   
		//title status
		set<string> titleStatusSet = new set<String>();
		if(dummyStudent.Title_1_Status__c!='None' && dummyStudent.Title_1_Status__c!=null){
			for(String tempStr : dummyStudent.Title_1_Status__c.split(',')){
				titleStatusSet.add(tempStr);
			}
		}   
		
		List<Id> teacherStudentIds = new List<Id>();
		for(Student_Section__c SC : [Select Id, Name, Student__r.Id, Student__r.Name from Student_Section__c where Section__c in (select Section__c from Staff_Section__c where Staff__c in : selectedTeacherIds AND Section__r.RecordType.DeveloperName = 'Published')])
		{
			teacherStudentIds.add(SC.Student__r.Id);
		}
		
		string studentQuery = 'Select ID, Setup__r.Standard_Grade_Mastery_Threshold__c, Name from Student__c';
		string whereClause = 'where ID != null';//i use a redundant statement for the where clause so i can just use += and not have to check for the where
		
		if(dummyStudent.Ethnicity__c!='None' && dummyStudent.Ethnicity__c!=null){
			//whereClause+= ' AND Ethnicity__c in (\'' + dummyStudent.Ethnicity__c.split(',') +'\')';
			whereClause+= ' AND Ethnicity__c IN : EthnicitySet ';
		}
		if(raceSet.size()>0){
			//whereClause+= ' AND Race__c in (\'' + dummyStudent.Race__c.split(',') +'\')';
			whereClause+= ' AND Race_Multi__c '+StringUtils.buildMutliSelectQuery(RaceSet);
		}
		if(dummyStudent.Gender__c != null && dummyStudent.Gender__c!='None'){
			if(dummyStudent.Gender__c.contains('M') && !dummyStudent.Gender__c.contains('F'))
			{
				whereClause+= ' AND Gender__c = \'M\' ';
			}
			else if (dummyStudent.Gender__c.contains('F') && !dummyStudent.Gender__c.contains('M'))
			{
				whereClause+= ' AND Gender__c = \'F\' ';
			}
		}
		if(selectedELL != null && selectedELL == 'true'){
			whereClause+= ' AND ELL__c = true ';
		}
		if(selectedELL !=null && selectedELL == 'false'){
			whereClause+= ' AND ELL__c =  false ';
		}
		if(selectedIEP !=null && selectedIEP == 'true'){
			whereClause+= ' AND IEP__c =  true ';
		}	
		if(selectedIEP !=null && selectedIEP == 'false'){
			whereClause+= ' AND IEP__c =  false ';
		}		
		if(dummyStudent.Title_1_Status__c!='None' && dummyStudent.Title_1_Status__c!=null){
			//whereClause+= ' AND Title_1_Status__c in (\'' + dummyStudent.Title_1_Status__c.split() +'\')';
			whereClause+= ' AND Title_1_Status__c IN : titleStatusSet ';
		}
		if(sectionsSet.size()>0 && schoolsSet.size()==0){//they have added sections, but selected no schools
			whereClause += ' AND ID IN : sectionSetPostSS '; 
		}
		else if(sectionsSet.size()>0 && schoolsSet.size()>0){//they have added sections and schools
			whereClause += ' AND (ID IN : sectionSetPostSS OR School__c IN : schoolsSet) '; 
		}
		else if(sectionsSet.size()==0 && schoolsSet.size()>0){//they have selected schools, but no sections
			whereClause += ' AND School__c IN : schoolsSet '; 
		}
		if(studentIds.size() > 0)
		{
		  whereClause += ' AND ID NOT IN : studentIds '; 
		}
		if(selectedTeacherIds.size() > 0)
		{
			whereClause += ' AND ID IN : teacherStudentIds '; 
		}
		whereClause+= ' order by Student_Last_Name__c limit 40000 ';//just in case NYC DOE implements this bigtime, want to have at least 10k rows left for other queries
		system.debug('studentQuery+whereClause ' + studentQuery+' '+whereClause);
		for(Student__c s : database.query(studentQuery+' '+whereClause)){
		//for(Student__c s : [Select ID, Setup__r.Standard_Grade_Mastery_Threshold__c, Name from Student__c where ID IN : hardCodeLimit]){
			wrappedStudents.add(new studentWrapper(s));
			
		}
		
	}
	public void selectStudents(){
		list<integer> indexes = new list<integer>();
		integer index = 0;
		
		//add to selected list
		system.debug('wrappedStudents ' + wrappedStudents);
		list<studentWrapper> temp = new list<studentWrapper>();
		for(studentWrapper s : wrappedStudents){
			if(s.selected){
				////system.debug('SELECTED!'  + s);
				s.selected = false;
				selectedStudents.add(s);
				indexes.add(index);
			}
			else{
				temp.add(s);
			}
			index++;
		}
		selectedStudentsJsonString = '[';
		for(studentWrapper s : selectedStudents){
			selectedStudentsJsonString += '{"id": "'+s.Student.id+'", "name": "'+s.Student.Name+'"},';
		}
		selectedStudentsJsonString = selectedStudentsJsonString.substring(0, selectedStudentsJsonString.length() - 1);
		selectedStudentsJsonString += ']';
		//wrappedStudents.clear();
		wrappedStudents.addAll(temp);
		////system.debug('Selected students: ' + selectedStudents);
		
	}
	
	public pageReference removeSelectedStudents()
	{
		String commaSeperatedStudents = Apexpages.currentPage().getParameters().get('removedStudents');
		system.debug('$$$$$$$');		
		system.debug(commaSeperatedStudents);		
		list<String> removedStudentIdsList = commaSeperatedStudents.split(',');
		Set<String> removedStudentIds = new set<String>();
		for (string sts : removedStudentIdsList)
		{
			removedStudentIds.add(sts);
		}
		system.debug('$$$$$$$');		
		system.debug(removedStudentIds);
		list<integer> indexes = new list<integer>();
		integer index = 0;
		list<studentWrapper> temp = new list<studentWrapper>();
		for(studentWrapper s : selectedStudents){
			if(removedStudentIds.contains(s.student.id)){
				////system.debug('SELECTED!'  + s);
				s.selected = false;
				wrappedStudents.add(s);
				indexes.add(index);
			}
			else{
				temp.add(s);
			}
			index++;
		}
		selectedStudents.clear();
		selectedStudents.addAll(temp);
		return null;
	}
	
	public void generateReports2()
	{
		debugString = '';
		string tempString1 = '';
		string tempString2 = '';
		string tempString3 = '';
		string gradeValue1 = '';
		list<String> tempStringList = new List<String>();
		
		jSonString1 = '{';
		jSonString1 += '"cols": [{"id": "Standard", "label": "Standard", "type": "string"},';
		jSonString1 += '{"id": "", "label": "", "type": "string", "p":{"role": "annotation"}},';
		jSonString1 += '{"id": "", "label": "", "type": "string", "p":{"role": "annotationText"}},';
		jSonString1 += '{"id": "Mastered", "label": "Mastered", "type": "number"},';
		jSonString1 += '{"id": "", "label": "", "type": "string", "p":{"role": "tooltip"}},';
		jSonString1 += '{"id": "Not Mastered", "label": "Not Mastered", "type": "number"},';
		jSonString1 += '{"id": "", "label": "", "type": "string", "p":{"role": "tooltip"}},';
		jSonString1 += '{"id": "Not Assesseded", "label": "Not Assessed", "type": "number"},';
		jSonString1 += '{"id": "", "label": "", "type": "string", "p":{"role": "tooltip"}}';
		jSonString1 += '],';
		jSonString1 += '"rows": [';
		
		//replace the ~~~x~~~ with data and add to final string
		String jSonString1Format = '{"c":[{"v": "~~~1~~~"}, {"v": "~~~2~~~"}, {"v": "~~~3~~~"}, {"v": ~~~4~~~}, {"v": ~~~5~~~}, {"v": ~~~6~~~}, {"v": ~~~7~~~}, {"v": ~~~8~~~}, {"v": ~~~9~~~}]}';
		
		String jSonString2Format = '{"c":[{"v": "~~~SN~~~"},';
		jSonString2 = '{ "cols": [';
		jSonString2 += '{"id": "StudentName", "label": "Student", "type": "string"},';
		for(standardWrapper sw : selectedStandards){
			jSonString2 += '{"id": "' + sw.Standard.Id + '", "label": "' + sw.Standard.Name + '", "type": "number"},';
			jSonString2 += '{"id": "", "label": "", "type": "string", "p":{"role": "tooltip"}},';
			jSonString2 += '{"id": "", "label": "Mastery", "type": "string"},';
			jSonString2Format += '{"v": ~~~' + sw.Standard.Id + '_SCORE~~~},';
			jSonString2Format += '{"v": ~~~' + sw.Standard.Id + '_TIP~~~},';
			jSonString2Format += '{"v": "~~~' + sw.Standard.Id + '_MASTERY~~~"},';
		}
		jSonString2 += '{"id": "Student", "label": "Student Id", "type": "string"}';		
		jSonString2 += '],';
		jSonString2 += '"rows": [';
		jSonString2Format += '{"v": "~~~SID~~~"}]}';
		
		for(studentWrapper  stw : selectedStudents)
		{
			jSonString2 += jSonString2Format.replace('~~~SN~~~', stw.Student.Name)
											.replace('~~~SID~~~', stw.Student.Id)
											.replace('_SCORE~~~', '_' + stw.Student.Id + '_SCORE~~~')
											.replace('_TIP~~~', '_' + stw.Student.Id + '_TIP~~~')
											.replace('_MASTERY~~~', '_' + stw.Student.Id + '_MASTERY~~~') + ',';
		}
		jSonString2 = jSonString2.substring(0, jSonString2.length() - 1);
		jSonString2 += ']}';
		
		//3 temp decimals
		Decimal unassessed = 0.0;
		Decimal unmastered = 0.0;
		Decimal mastered = 0.0;
		
		//temp counter
		Integer counter = 0;
		
		
		studentIDS = new Set<id>();
		map<string, string> studentNames = new map<string, string>();
		set<id> standardsToProcess = new set<id>();
		map<String, List<integer>> r1finalcalc = new map<String, List<integer>>();
		map<String, List<String>> r2finalcalc = new map<String, List<String>>();
		
		List<integer> tempr1CalcList;
		List<string> tempr2CalcList;
		
		for(studentWrapper stw : selectedStudents){
			studentIds.add(stw.student.id);
			studentNames.put(stw.student.id, stw.student.name);
			//this is a nested loop so we can build all the possible combinations
			for(standardWrapper sw : selectedStandards){
				standardsToProcess.add(sw.standard.id);
				//r2finalcalc.put(stw.student.id+';'+sw.standard.id, new list<String>());
				tempStringList.add(sw.standard.id + '_' + stw.student.id + '_'); 
			}		   
		}
		
		map<id, List<Standard_Grade__c>> studentGrades = new map<id, List<Standard_Grade__c>>();
		map<id, List<Standard_Grade__c>> standardGrades = new map<id, List<Standard_Grade__c>>();
		
		List<Standard_Grade__c> sgs = new List<Standard_Grade__c>();
		sgs = [Select ID, Standard_Grade__c, 
						Student__r.Setup__r.Standard_Grade_Mastery_Threshold__c,
						Most_Recent_Grade__c,
						Highest_Grade__c,
						Mean_Grade__c,
						Law_of_Decaying_Average_Grade__c,
						Power_Law_Grade__c,
						Student__r.Name,
						Student__r.id,
						Standard__r.id,
						Standard__r.Name,
						Standard__c,
						Student__c
						from Standard_Grade__c 
						where Student__c IN :studentIDs AND
						Standard__c IN : standardsToProcess
						order by Standard__c ];
		//counter = 0;
		Decimal ScoreToBeUsed;
		for(Standard_Grade__c sg : sgs)
		{		   
			system.debug('############');
			system.debug('-----------------------selectedCalcType--------------->'+selectedCalcType);
			if(selectedCalcType.contains(Most_Recent_Grade)){
				ScoreToBeUsed = sg.Most_Recent_Grade__c;
			}
			else if (selectedCalcType.contains(Highest_Grade)){
				ScoreToBeUsed = sg.Highest_Grade__c;
			}
			else if (selectedCalcType.contains(Mean_Grade)){
				ScoreToBeUsed = sg.Mean_Grade__c;
			}
			else if (selectedCalcType.contains(Law_of_Decaying_Average_Grade)){
				ScoreToBeUsed = sg.Law_of_Decaying_Average_Grade__c;
			}
			else if (selectedCalcType.contains(Power_Law_Grade)){
				ScoreToBeUsed = sg.Power_Law_Grade__c;
			}
			else {
				ScoreToBeUsed = sg.Standard_Grade__c;
			}
			
			system.debug('-----------------------ScoreToBeUsed--------------->'+ScoreToBeUsed);					   
			tempString1 = '~~~' + sg.Standard__c + '_' + sg.Student__c + '_SCORE~~~';
			tempString2 = '~~~' + sg.Standard__c + '_' + sg.Student__c + '_MASTERY~~~';
			tempString3 = '~~~' + sg.Standard__c + '_' + sg.Student__c + '_TIP~~~';
			if(r1finalcalc.get(sg.Standard__c) == null)//first time
			{
				tempr1CalcList = new List<integer> {0,0,0}; //unassessed, unmastered, mastered
			}
			else
			{
				tempr1CalcList = new List<integer> {0,0,0};
				tempr1CalcList = r1finalcalc.get(sg.Standard__c);
			}
			if(ScoreToBeUsed == null)//unassessed
			{
				tempr1CalcList[0]++;
				debugString += tempString1;
				jSonString2 = jSonString2.replace(tempString1, '0').replace(tempString2, 'Not Assessed')
					.replace(tempString3, '\"Standard: ' + sg.Standard__r.Name + '\nCalculated Standard Grade: 0\"');
				//jSonString2 = jSonString2.replace(tempString3, '\"foo\"');				
			}
			else if (ScoreToBeUsed < sg.Student__r.Setup__r.Standard_Grade_Mastery_Threshold__c)//unmastered
			{
				tempr1CalcList[1]++;
				debugString += tempString1;
				gradeValue1 = String.valueOf(ScoreToBeUsed == null ? 0 : ScoreToBeUsed);
				jSonString2 = jSonString2.replace(tempString1, gradeValue1).replace(tempString2, 'Not Mastered')
					.replace(tempString3, '\"Standard: ' + sg.Standard__r.Name + '\nCalculated Standard Grade: ' + gradeValue1 + '\"');
			}
			else
			{
				System.debug('############');
				tempr1CalcList[2]++;
				debugString += tempString1;
				gradeValue1 = String.valueOf(ScoreToBeUsed == null ? 0 : ScoreToBeUsed);
				debugString += gradeValue1;
				jSonString2 = jSonString2.replace(tempString1, gradeValue1).replace(tempString2, 'Mastered')
					.replace(tempString3, '\"Standard: ' + sg.Standard__r.Name + '\nCalculated Standard Grade: ' + gradeValue1 + '\"');
			}
			r1finalcalc.put(sg.Standard__c, tempr1CalcList);		
		}
		system.debug('-----------------------r1finalcalc--------------->'+r1finalcalc);
		counter = 0;
		for(string str : tempStringList)
		{
			tempString1 = '~~~' + str + 'SCORE~~~';
			tempString2 = '~~~' + str + 'MASTERY~~~'; 
			tempString3 = '~~~' + str + 'TIP~~~'; 
			jSonString2 = jSonString2.replace(tempString1, '0').replace(tempString2, 'Not Assessed')
					.replace(tempString3, '\"Standard: -\nCalculated Standard Grade: 0\"');
		}

		//standards not found at all
		for(id stp : standardsToProcess)
		{
			if(r1finalcalc.get(stp) == null)
			{
				r1finalcalc.put(stp, new List<integer> {1, 0, 0});
			}
			else
			{
				integer total = r1finalcalc.get(stp)[0]+r1finalcalc.get(stp)[1]+r1finalcalc.get(stp)[2];
				if(total < selectedStudents.size())
				{
					r1finalcalc.get(stp)[0] = selectedStudents.size() - total;
				}
			}
		}

		//create json string for chart 1 (standards)
		string unassessedTip = '';
		string unmasteredTip = '';
		string masteredTip = '';
		counter = 0;
		for(string std : r1finalcalc.keyset())
		{
			counter++;
			decimal dn = Decimal.valueof(r1finalcalc.get(std)[0]) + Decimal.valueof(r1finalcalc.get(std)[1]) + Decimal.valueof(r1finalcalc.get(std)[2]);
			if(dn > 0)
			{
				unassessed = ((Decimal.valueof(r1finalcalc.get(std)[0]) * 100) / dn).setScale(2);
				unmastered = ((Decimal.valueof(r1finalcalc.get(std)[1]) * 100) / dn).setScale(2);
				mastered = ((Decimal.valueof(r1finalcalc.get(std)[2]) * 100) / dn).setScale(2);

				unassessedTip = '"' + infoMap.get(std).name + '\\nNot Assessed: ' + String.valueof(unassessed) + '% (' + String.valueof(r1finalcalc.get(std)[0]) + ')"'; 
				unmasteredTip = '"' + infoMap.get(std).name + '\\nNot Mastered: ' + String.valueof(unmastered) + '% (' + String.valueof(r1finalcalc.get(std)[1]) + ')"'; 
				masteredTip = '"' + infoMap.get(std).name + '\\nMastered: ' + String.valueof(mastered) + '% (' + String.valueof(r1finalcalc.get(std)[2]) + ')"'; 
			}
			else
			{
				unassessed = 100.00;
			}
			jSonString1 += jSonString1Format.replace('~~~1~~~', infoMap.get(std).name)
							.replace('~~~2~~~', '?')
							.replace('~~~3~~~', infoMap.get(std).Long_Text__c)
							.replace('~~~4~~~', String.valueof(mastered))
							.replace('~~~5~~~', String.valueof(masteredTip))
							.replace('~~~6~~~', String.valueof(unmastered))
							.replace('~~~7~~~', String.valueof(unmasteredTip))
							.replace('~~~8~~~', String.valueof(unassessed))
							.replace('~~~9~~~', String.valueof(unassessedTip));
			if(counter < r1finalcalc.size())
			{
				jSonString1 += ',';
			}
			else
			{
				jSonString1 += ']';
				jSonString1 += '}';
			}
		}
		generateReport3jSon(standardsToProcess, studentIDs);
		generateReport3jSon_LE(standardsToProcess, studentIDs);
	}
	
	private void generateReport3jSon_LE(set<id> standardsToProcess, set<id> studentIDs)
	{
		assignmentDataString		= '';
		
		Map<ID,Map<ID,Map<ID,Grade__c>>> assignToStandToStudentGrades = new Map<ID,Map<ID,Map<ID,Grade__c>>>();
		Map<ID,String> gradeToDetails		= new Map<ID,String>();
		Map<ID,Standard__c> idToStandard 	= new Map<ID,Standard__c>();
		Map<ID,Student__c> idToStudent		= new Map<ID,Student__c>();
		Map<ID,String> assignmentToName		= new Map<ID,String>();
		Map<Date,Set<ID>> dateToAssignment	= new Map<Date,Set<ID>>();
		
		String detailString = '';
		
		for(Assignment__c a : [Select ID, Name, Section__c, Section__r.Name, Due_Date__c, 
									(Select ID, Weighted_Grade_Value__c, Student__c, Assignment__c, Assignment__r.Name, Standard__r.Name, Name, 
									Student_Section__r.Student__r.Name, Student__r.Name, Student__r.Grade__c, Grade_Number__c, Entered_Grade__c, 
									Student_Section__r.Student__c, Possible_Points__c, Standard__r.Long_Text__c
									from Grades__r 
									where Standard__c IN :standardsToProcess AND student_section__c != null AND Student_Section__r.Student__r.Name != null AND Student__c IN : studentIDS order by Student__c)
							from Assignment__c where Name!= null AND Name!= '' AND Due_Date__c >= :startDate.Due_Date__c AND Due_Date__c <= :endDate.Due_Date__c]){
			system.debug('ASSIGNMENT : ' + a);
			assignmentToName.put(a.id,a.Name);
			
			if(!dateToAssignment.containsKey(a.Due_Date__c)) dateToAssignment.put(a.Due_Date__c,new Set<ID>());
			dateToAssignment.get(a.Due_Date__c).add(a.id);
			
			Map<ID,Map<ID,Grade__c>> standardToStudentGrades = new Map<ID,Map<ID,Grade__c>>();
			for(Grade__c g: a.Grades__r){
				if(g.Entered_Grade__c!=null){
					//populate maps--since these are static, overwriting isn't a concern (standards with the same id will always be the same)
					idToStandard.put(g.Standard__c,g.Standard__r);
					idToStudent.put(g.Student__c,g.Student__r);
					//if map doesn't contain standard, add it
					if(!standardToStudentGrades.containsKey(g.Standard__c))
						standardToStudentGrades.put(g.Standard__c,new Map<ID,Grade__c>());
					//if standard map doesn't contain this assignment, add it
					standardToStudentGrades.get(g.Standard__c).put(g.Student__c,g);
					//create hover detail string
					detailString = 'Section: ' + a.Section__r.Name+'\\n'
						+'Assignment Name: '+a.Name+'\\n'
						+'Due Date: '+a.Due_Date__c.format()+'\\n'
						+'Standard: '+g.Standard__r.Name+'\\n'
						+'Standard Score: '+g.Entered_Grade__c;
					gradeToDetails.put(g.id,detailString);
				}
			}
			assignToStandToStudentGrades.put(a.id,standardToStudentGrades);
		}
		//sort the data on due date
		List<Date> dueDates = new List<Date>();
		dueDates.addAll(dateToAssignment.keySet());
		dueDates.sort();
		
		assignmentDataString+='{ \n';
		assignmentDataString+='"assignments": { \n'; //start assignment map
		boolean firstAssignment=true;
		for(Date dd : dueDates){
			if(dateToAssignment.get(dd).size()>0){
				for(ID assignment : dateToAssignment.get(dd)){
					if(assignToStandToStudentGrades.get(assignment).size()>0){
						if(!firstAssignment) assignmentDataString+='}, \n';
						assignmentDataString+='"'+assignment+'": { \n';
						assignmentDataString+='"name": "'+assignmentToName.get(assignment)+'", \n';
						assignmentDataString+='"standards": { \n'; //start standard map
						boolean firstStandard=true;
						for(ID standard : assignToStandToStudentGrades.get(assignment).keyset()){
							//if not the first standard, needs an end bracket and comma
							if(!firstStandard) assignmentDataString+='], \n';
							assignmentDataString+='"'+standard+'": [ \n'; //begin standard grades
							boolean firstStudent=true;
							for(ID student : assignToStandToStudentGrades.get(assignment).get(standard).keyset()){
								//if not the first student, needs an end bracket and comma
								if(!firstStudent) assignmentDataString+='}, \n';
								assignmentDataString+='{ \n';
								Grade__c g = assignToStandToStudentGrades.get(assignment).get(standard).get(student);
								assignmentDataString+='"student_id": "'+student+'", \n';
								assignmentDataString+='"grade": '+g.Entered_Grade__c+', \n';
								assignmentDataString+='"tooltip": "'+gradeToDetails.get(g.id)+'" \n';
								firstStudent=false;
							}
							//end last student grade (no comma)
							assignmentDataString+='} \n';
							firstStandard=false;
						}
						assignmentDataString+='] \n'; //end last set of standard grades (no comma)
						assignmentDataString+='} \n'; //end standard map
						firstAssignment=false;
					}
				}
			}
		}
		assignmentDataString+='} \n'; //end last assignment
		assignmentDataString+='}, \n'; //end assignment map 
		assignmentDataString+='"standards": { \n'; //begin standard map
		boolean firstStandard=true;
		for(ID standard : idToStandard.keyset()){
			if(!firstStandard) assignmentDataString+='}, \n';
			assignmentDataString+='"'+standard+'": { \n';
			assignmentDataString+='"name": "'+idToStandard.get(standard).Name+'", \n';
			assignmentDataString+='"description": "'+idToStandard.get(standard).Long_Text__c+'" \n';
			firstStandard=false;
		}
		assignmentDataString+='} \n'; //end last standard
		assignmentDataString+='}, \n'; //end standard map
		assignmentDataString+='"students": { \n'; //begin student map
		boolean firstStudent=true;
		for(ID student : idToStudent.keyset()){
			if(!firstStudent) assignmentDataString+='}, \n';
			assignmentDataString+='"'+student+'": { \n';
			assignmentDataString+='"name": "'+idToStudent.get(student).Name+'", \n';
			assignmentDataString+='"grade": "'+idToStudent.get(student).Grade__c+'" \n';
			firstStudent=false;
		}
		assignmentDataString+='} \n'; //end last student
		assignmentDataString+='} \n'; //end student map
		assignmentDataString+='}'; //end json string
		system.debug('~~~~~assignmentDataString ' + assignmentDataString);
	}
				
	private void generateReport3jSon(set<id> standardsToProcess, set<id> studentIDs)
	{
		////system.debug('URLSTANDARD ' + URLStandard);
		
		string assignmentData = 'NOTHING';
		string assignmentNamesString	= 'NOTHING';//splitVariable= |A|
		string gradeString			  = 'NOTHING';//split Variable = |G|
		string studentNamesString	   = 'NOTHING';//split variable = |N|
		bigAssString					= 'NOTHING';
		
		
		set<ID> gradesOrderKeyset = new Set<ID>();
		//map to link student IDs to studentNames
		map<ID,String> studentIDMap	= new map<ID,String>();
		students	= new List<SelectOption>();
		map<String, String> gradesOrderMap = new Map<String,String>();
		//maps student ids to the assignment details to be used in the hover text
		//this map will be cleared after every assignment is processed
		Map<String, String> assignmentDetails = new Map<String,String>();
		
		List<String> studentOrderList = new List<String>();
		
		//system.debug('standard '+standard);
		//system.debug('studentIDS '+studentIDS);
		//system.debug('startDate.Due_Date__c '+startDate.Due_Date__c);
		//system.debug('endDate.Due_Date__c '+endDate.Due_Date__c);
		for(Assignment__c a : [Select ID, 
							Name, 
							Section__c, 
							Section__r.Name, 
							Due_Date__c, 
									(Select ID, Weighted_Grade_Value__c, 
									Student__c,
									Assignment__c,
									Assignment__r.Name,
									Standard__r.Name,
									Name,
									Student_Section__r.Student__r.Name,
									Student__r.Name,
									Student__r.Gender__c, 
									Grade_Number__c,
									Entered_Grade__c,
									Student_Section__r.Student__c,
									Possible_Points__c from Grades__r where Standard__c IN :standardsToProcess AND student_section__c != null AND Student_Section__r.Student__r.Name != null AND Student__c IN : studentIDS order by Student__c)
							from Assignment__c where Name!= null AND Name!= '' AND Due_Date__c >= :startDate.Due_Date__c AND Due_Date__c <= :endDate.Due_Date__c]){
			system.debug('ASSIGNMENT : ' + a);
				

			boolean assignmentContainsStandard = false;
			string tempGradeString = 'NOTHING';
			string currentStudent = '';
			
			boolean firstGrade = true;					  
			for(Grade__c g : a.Grades__r){
				assignmentContainsStandard = true;
				system.debug('Grade: ' + g);
				if(firstGrade){ 
					if(assignmentNamesString=='NOTHING'){
						assignmentNamesString = a.Name;
					}
					else{
						assignmentNamesString += 'XXXAXXX'+a.Name;//add to string with split variable included
					}
					//assignments.add(new SelectOption(string.valueOf(i), a.Name));
					firstGrade = false;
				}
			
				////system.debug('STUDENT: ' + g.Student__c);
				
				if(!studentIDMap.containsKey(g.Student_Section__r.Student__c)){
					//if(studentNamesString=='NOTHING'){
					//	studentNamesString = g.Student_Section__r.Student__r.Name;
					//} 
					//else{
					//	studentNamesString += 'XXXNXXX' + g.Student_Section__r.Student__r.Name;//add to string with seperator for client-side processing
					//}
					
					studentIDMap.put(g.Student__c,g.Student__r.Name);
					studentOrderList.add(g.Student__c);
				}
				string tempGrade;
				if(g.Entered_Grade__c == null){
					tempGrade = '~';
				}
				else{
					tempGrade = string.valueOf(g.Entered_Grade__c);
				}
				
				if(tempGradeString =='NOTHING'){
					gradesOrderMap.put(string.valueOf(g.Student__c),tempGrade);
					//tempGradeString = temp;
				}
				else{
					gradesOrderMap.put(string.valueOf(g.Student__c),tempGrade);
					tempGradeString+=','+tempGrade;
				}
				//set up assignment hover details for the student/grade combination
				assignmentDetails.put(g.Student__c,'Section: ' + a.Section__r.Name+'\\n'
					+ 'Assignment Name: '+a.Name+'\\n'
					+ 'Due Date: '+a.Due_Date__c.format()+'\\n'
					+'Standard: '+g.Standard__r.Name);
				
			}
			if(assignmentContainsStandard){
				if(gradeString=='NOTHING'){
					gradeString = '';
				}
				else{
					gradeString+='XXXGXXX';
				}
				for(ID key : studentOrderList) {
					string tempGrade;
					system.debug('Grades order map, student ID gets grades ' + gradesOrderMap.get(string.valueOf(key)));
					if(gradesOrderMap.get(string.valueOf(key)) == null){
						tempGrade = '~';
					}
					else{
						tempGrade = gradesOrderMap.get(string.valueOf(key));
					}
					boolean firstOfSet = false;
					if(gradeString.length()>7){
						firstOfSet = gradeString.subString(gradeString.length()-7, gradeString.length())=='XXXGXXX';
					}
					if(gradeString == '' || firstOfSet){
						gradeString += tempGrade;
					}
					else{
						gradeString += ',' + tempGrade;
					}
					//add assignment detail text
					if(assignmentData=='NOTHING'){
						assignmentData = assignmentDetails.get(key) +'\\nStandard Score: '+tempGrade;
					}
					else{
						if (!firstOfSet) {
							assignmentData += '|';
						}
						assignmentData += assignmentDetails.get(key) +'\\nStandard Score: '+tempGrade;
					}
				}
				gradesOrderMap.clear();
				assignmentDetails.clear();
				assignmentData+='XXXDXXX';
			}

		}
		for(ID key : studentOrderList) {
			if(studentNamesString=='NOTHING'){
				studentNamesString = studentIDMap.get(key);
			} 
			else{
				studentNamesString += 'XXXNXXX' + studentIDMap.get(key);//add to string with seperator for client-side processing
			}
		}
		//integer endIndex = gradeString.length();
		//gradeString = gradeString.subString(0, endIndex-7);
		integer endIndex = assignmentData.length();
		assignmentData= assignmentData.subString(0,endIndex-7);
		bigAssString = assignmentNamesString + 'XXXOXXX' + gradeString + 'XXXOXXX' + studentNamesString + 'XXXOXXX'+assignmentData;		   
	}								

	public class standardWrapper{
		public boolean selected				   {get;set;}
		public Standard__c standard {get;set;}
		
		public standardWrapper(Standard__c s){
			this.standard = s;
			selected = false;
		}
		
	}
	public class studentWrapper{
		public boolean selected				   {get;set;}
		public Student__c student {get;set;}
		
		public studentWrapper(Student__c s){
			this.student = s;
			selected = false;
		}
		
	}
	public class filterWrapper{
		public boolean selected {get;set;}
		public string ID		{get;set;}
		public string label	 {get;set;}
		
		public filterWrapper(){
			selected = false;
		}
	}
}