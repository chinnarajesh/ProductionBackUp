public  with sharing class CT_core_GroupConfiguration {
	public string 					setupId				{get;set;}
	public CT_core_SetupWrapper		cSetup 				{get;set;}
	public List <Section__c>		availableGroups		{get;set;} 
	public Map <Id, Section__c>		groupsMap 			{get;set;} 
	public String					selectedGroupId 	{get;set;}
	public Section__c				selectedGroup 		{get;set;}
	public boolean					bShowGroupsDetails  {get;set;}
	public boolean					bConfigureGroup 	{get;set;}
	public List<List<cStudent>>		availableStudents 	{get;set;}
	public List<List<cStudent>>		studentsInGroup 	{get;set;}
	public Id						groupRecordTypeId	{get;set;}
	public boolean					bCalledAutoEdit		{get;set;}
	public boolean					isManaged			{get;set;}
	//EE 6/3 DE2935 changed list structure, need some integers to hold # of students in group/not in group
	//temporary fix--this should be revisited later
	public integer					numStudentsInGroup	{get;set;}
	public integer					numStudentsNotInGroup	{get;set;}
	public static final string		NO_GROUPS_MSG = 'At least one schedule group must be created before moving on to the next step.';

	/* CONSTRUCTOR */
	public CT_core_GroupConfiguration(){
		try{
			isManaged = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
			bCalledAutoEdit=false;
			groupRecordTypeId = CT_core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Schedule_Group');  //US1254; gets the Record Type ID for Schedule Group off Section object
			if (System.currentPageReference().getParameters().containsKey('setupid')!=null) {
				 setupId = System.currentPageReference().getParameters().get('setupid');  //Invoked upon 'New' from Setup
				 cSetup = new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'group');
			}
			if (System.currentPageReference().getParameters().containsKey('id')!=null){
				 selectedGroupId = System.currentPageReference().getParameters().get('id'); //Standard Edit for Schedule Group overriden
				 System.currentPageReference().getParameters().put('selectedGroupId', selectedGroupId);
			}
			groupsMap = new Map <Id, Section__c>();
			availableGroups = new List <Section__c>(); //Main list of available groups
			returnAvailableGroups();
			if(CT_SetupWizard_Utils.checkGroups(cSetup.setup))
				CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,NO_GROUPS_MSG);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred during initialization.'));
		}  
	}	 
	
 
	
	public void initSetup(){
		cSetup.refreshScheduleGroups();
		availableGroups = cSetup.scheduleGroupList;
	}
  
	/* Method returns all the groups for the current active setup Year and school associated with the logged in user*/
	public void returnAvailableGroups(){ 
		availableGroups.clear();
		bConfigureGroup=false;
		if (setupId!=null){  //Ensure that all configuration is related to a setup record
			setupId = System.currentPageReference().getParameters().get('setupId');
			initSetup();
		}
		if (selectedGroupId!=null){
			Section__c sect = CT_core_SoqlUtils.getSectionById(selectedGroupId);
			setupId = CT_core_SoqlUtils.getSetupBySchoolYear(sect.school__c,sect.time__c).id;
			initSetup();
			if (System.currentPageReference().getParameters().containsKey('add')) 			editGroup();
			else if (!bCalledAutoEdit) editGroupInfo();
		}
	}
	/*Called from page when user clicks the Add Group Button*/
	public void addGroup(){
		try{
			bShowGroupsDetails=false;
			bConfigureGroup=true;
			selectedGroup = new Section__c(school__c=cSetup.school.id, time__c=cSetup.setup.year__c, RecordTypeId =groupRecordTypeId, Active__c = true); 		//Initializes new group to add for selected Year
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while adding a group.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId, 'Core (Group Config)', 'error adding group', e);
			insert ge;
		}  
	}
	
	/*Called from page when user clicks the Edit Group Link*/
	public void editGroupInfo(){
		try{
			bShowGroupsDetails=false;
			bConfigureGroup=true;
			bCalledAutoEdit = true;
			selectedGroupId=System.currentPageReference().getParameters().get('selectedGroupId');
			selectedGroup =CT_core_SoqlUtils.getSectionById(selectedGroupId);
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while retrieving the selected group.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Schedule Group, '+selectedGroupId, 'Core (Group Config)', 'error retrieving group', e);
			insert ge;
		}  
	}
	
	public List <Student_Section__c> getStudentsInGroup(Id SelectedGroupId){
		List <Student_Section__c> sslist = new List <Student_Section__c>();
			for (Student_Section__c ss: [select id,student__r.Race__c, student__r.Primary_Schedule_Group__c,student__r.IEP__c, student__r.ELL__c,student__r.Grade__c, student__r.Gender__c, student__r.Special_Ed__c, student__r.name, student__c, section__c from Student_Section__c where section__c =:SelectedGroupId and active__c=true]){
				sslist.add(ss);
			}
			return sslist;
	}
	
	public List <Student__c> getStudentsNotInGroup(string gradeLevel, Set <Id> studIds){
		List <Student__c> studList = new List <Student__c>();
		String[] grades = gradeLevel.split(';');
		String query = 'select id,Race__c, IEP__c, ELL__c,School__r.reference_id__c,School_Year__r.name__c, Student_Id__c, '
						+ 'Grade__c, Gender__c, Special_Ed__c, name, student__c, section__c , primary_schedule_group__c '
						+ 'from Student__c '
						+ 'WHERE Setup__c = \''+cSetup.setup.id+'\' '
						+ 'AND Grade__c IN: grades ';
		//DE1241
		if(cSetup.setup.Data_Activated__c) query += 'AND Active__c = true';
		for (Student__c s: database.query(query)){
			if (!studIds.contains(s.id)) studList.add(s);
		}
		return studList;
	}
	
	public void deleteGroup(){
		if (selectedGroupId!=null||selectedGroupId!=''){  
				selectedGroup =CT_core_SoqlUtils.getSectionById(selectedGroupId);
				delete selectedGroup;
				initSetup();
		}
	}
	
	/*Method called when user clicks the radio button next to a configured group*/
	public void editGroup(){
		try{
			//Initializes new group to add for selected Year
			studentsInGroup = new List<List<cStudent>>();
			availableStudents = new List<List<cStudent>>();
			numStudentsInGroup = 0;
			numStudentsNotInGroup = 0;
			if (selectedGroupId!=null||selectedGroupId!=''){  
				selectedGroup =CT_core_SoqlUtils.getSectionById(selectedGroupId);
				if (csetup==null){
					initSetup();
				}
				Set <Id> studentIdsInGroup = new Set <Id>();
				for (Student_Section__c stud:  getStudentsInGroup(selectedGroupId)){
					if(studentsInGroup.isEmpty()||studentsInGroup[studentsInGroup.size()-1].size() > 900){
						studentsInGroup.add(new List<cStudent>{new cStudent(stud)});
					} else {
						studentsInGroup[studentsInGroup.size()-1].add(new cStudent(stud));
					}
					studentIdsInGroup.add(stud.student__c);
					numStudentsInGroup++;
				}
				if(selectedGroup.All_Grades__c!=null){
					for (Student__c stud: getStudentsNotInGroup(selectedGroup.all_grades__c, studentIdsInGroup)){
						if(availableStudents.isEmpty()||availableStudents[availableStudents.size()-1].size() > 900){
							availableStudents.add(new List<cStudent>{new cStudent(stud, selectedGroup)});
						} else {
							availableStudents[availableStudents.size()-1].add(new cStudent(stud, selectedGroup));
						}
						numStudentsNotInGroup++;
					} 
				}
				bShowGroupsDetails=true;
				bConfigureGroup=false;	
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while retrieving student records.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Schedule Group, '+selectedGroupId, 'Core (Group Config)', 'error retrieving students', e);
			insert ge;
		}  							
	}
	
	public void goBack(){
		bShowGroupsDetails = false;
		bConfigureGroup = false;
	}
	

	/*Saves new group for selected year*/
	public void saveGroup(){
		try{
			Set<String> setupSpan = new Set<String>(cSetup.setup.Grade_Span__c.split(';'));
			Set<String> groupSpan = new Set<String>(selectedGroup.All_Grades__c.split(';'));

			if(!setupSpan.containsAll(groupSpan)){
				selectedGroup.All_Grades__c.addError('All grades within the group grade span must be within the grade span of the school setup.');
				return;
			}

			upsert selectedGroup;
			returnAvailableGroups();
			goBack();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the group.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Schedule Group, '+selectedGroup.id, 'Core (Group Config)', 'error saving group', e);
			insert ge;
		}  
	}	
	
	public void saveStudentList(){
		try{
			//Saves selected students to group selected
			List <Student_Section__c> ssList = new List <Student_Section__c>();
			List <Student__c> studentsList = new List <Student__c>();
			for (List<cStudent> sList: availableStudents){
				for(cStudent cStud: sList){
					if (cStud.bSelected) {
						//PU DE 1789 cStud.student.Section__c=selectedGroupId;
						if (cStud.student.Primary_schedule_group__c==null){
							 cStud.student.Primary_Schedule_Group__c =selectedGroupId;
							 studentsList.add(cStud.student);
						}
						else ssList.add(cStud.studentSection);
					}
				}
			}
			if (!studentsList.isEmpty())	upsert studentsList;
			if (!ssList.isEmpty())	 	upsert ssList reference_Id__c;
			
			editGroup();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while saving the student list.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Schedule Group, '+selectedGroupId, 'Core (Group Config)', 'error saving student list', e);
			insert ge;
		}  
	}
	
	public void removeStudentsFromGroup(){
		try{
			//Removes selected students from group selected
			List <Student_Section__c> ssList = new List <Student_Section__c>();
			//PU DE 1789
			List <Student__c> studentsList = new List <Student__c>();
			for (List<cStudent> sList: studentsInGroup){
				for(cStudent cStud:sList){
					if (cStud.bSelected) {
						
						//PU DE 1789
						if (cStud.student.primary_schedule_group__c==selectedGroup.id){
							cStud.student.primary_schedule_group__c = null;
							studentsList.add(cStud.student);
						}
						else {
							cStud.studentSection.active__c=false;
							cStud.studentSection.Section_Exit_Reason__c = core_triggerUtils.SECTIONEXITREASONBYSCHEDULER;
							ssList.add(cStud.studentSection);
						}
					}
				}
			}
			if (!studentsList.isEmpty()){
				update studentsList;	
			}
			if (!ssList.isEmpty()){
				update ssList;	
			}
		//	PU DE 1789 delete ssList;
			
			editGroup();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'An error occurred while removing students from the selected group.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Schedule Group, '+selectedGroupId, 'Core (Group Config)', 'error removing students from group', e);
			insert ge;
		}  
	}
	
	public PageReference prev(){
		return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.STAFF,false,cSetup.setup);
	}
	
	public PageReference next(){
		if(!CT_SetupWizard_Utils.checkGroups(cSetup.setup)) return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.SCHEDULE,true,cSetup.setup);
		else{
			CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,NO_GROUPS_MSG);
			return null;
		}
	}
		
/* Start of Wrapper Classes*/
	public class cStudent {
		public boolean bSelected {get;set;}
		public Student_Section__c studentSection {get;set;}
		public Student__c 				student					{get;set;}
		public  cStudent(Student_Section__c s){
			this.studentSection= s;
			this.bSelected = false;
		}	
		public cStudent(Student__c stud, Section__c sect){
			this.student =stud;
			this.studentSection = new Student_Section__c(Active__c=true, Reference_Id__c=CT_Student_Section_Utils.generateStudentSectionReference(student, sect), student__c=student.id, section__c=sect.id );//to do reference id to be populated by trigger
			this.bSelected = false;
		}
	}
}