public with sharing class Points_Matrix {
	/* PAGE CONTROLS */
	public boolean bFatalError		{get;set;}
	public boolean showMatrix		{get;set;}
	public boolean isManagedPackage	{get;set;}
	public boolean showRedeem		{get;set;}

	/* PAGE CONTAINERS */
	public List<SelectOption> schools				{get;set;}
	public List<SelectOption> grades				{get;set;}
	public List<SelectOption> sections				{get;set;}
	public List<Picklist_Value__c> currentCats		{get;set;}
	public string selectedSchool					{get;set;}
	public string selectedGrade						{get;set;}
	public string selectedSection					{get;set;}
	public Date selectedDate						{get;set;}
	public List<Points_MatrixWrapper> points		{get;set;}
	public List<Points_RedeemWrapper> redeemPoints	{get;set;}
	public String prettyDate						{get;set;}
	public String selectedSectionName				{get;set;}
	
	
	/* INTERNAL CONTAINERS */
	private List<Picklist_Value__c> categories;
	private List<Picklist_Value__c> catHolder;
	private Map<Id, List<SelectOption>> schoolSectionMap;
	private Map<Id, List<String>> schoolGradeMap;
	private Map<Id, List<Picklist_Value__c>> schoolCatMap;
	private Map<Id, String> sectionGradeMap;
	private Map<Id, String> sectionNameMap;
	private Map<ID, ID> sectionSchoolMap;
	private Map<ID, ID> schoolStaffMap;
	private Set<String> adminProfiles;
	private Date dateHolder;
	private boolean isAdmin;
	public Map<ID, Staff__c> staffMap;
	

	public Points_Matrix(){
		try{
			showMatrix = false;
			schools = new List<SelectOption>();
			grades = new List<SelectOption>();
			sections = new List<SelectOption>();
			currentCats = new List<Picklist_Value__c>();
			isManagedPackage = Schema.SObjectType.Points__c.getName().replace('__c', '').contains('__');
			
			//get the admin profile names from custom settings.
			adminProfiles = new Set<String>();
			Points_Settings_v2__c pointsSetting = Points_Settings_v2__c.getOrgDefaults();
			
			string adminString = Points_Settings_v2__c.getOrgDefaults().Admin_Profile__c;
			if(adminString != null){
				adminProfiles.addAll(StringUtils.splitAndTrim(adminString,','));
			} else {
				errorMessage('The points settings for this org has not been setup.');
			}
			
			schoolGradeMap = new Map<Id, List<String>>();
			schoolSectionMap = new Map<id, List<SelectOption>>();
			sectionNameMap = new Map<Id, String>();
			schoolStaffMap = new Map<Id, ID>();
			bFatalError = !loadCats();
			bFatalError = !loadStaffData();
			if(!bFatalError){
				selectedSchool = '--None--';
				selectedGrade = '--None--';
				selectedSection = '--None--';
				changeSchool();
			}
			selectedDate = system.today();
			dateHolder = system.today();
			prettyDate = system.today().month()+'/'+system.today().day()+'/'+system.today().year();
			showMatrix = false;
			if(ApexPages.currentPage().getParameters().get('goodSave') == 'true'){
				infoMessage('Changes were successfully saved.');
			}
			showRedeem = false;
		} catch (Exception e){
			errorMessage('A unexpected error occured. Please contact your system administrator.');
			bFatalError = true;
		}
	}
	
	public void changeSchool(){
		catHolder = new List<Picklist_Value__c>();
		grades = new List<SelectOption>();
		sections = new List<SelectOption>();
		//selectedGrade = '--None--';
		selectedSection = '--None--';
		if(selectedSchool == '--None--'){
			Set<string> gradeSet = new Set<string>();
			for(List<SelectOption> selectList: schoolSectionMap.values()){
				sections.addAll(selectList);
			}
			for(List<String> gradeList: schoolGradeMap.values()){
				gradeSet.addAll(gradeList);
			}
			for(String s:gradeSet){
				grades.add(new SelectOption(s,s));
			}
			catHolder.addAll(categories);
		} else {
			boolean resetGrade = true;
			for(String s:schoolGradeMap.get(selectedSchool)){
				grades.add(new SelectOption(s,s));
				if(selectedGrade == s){
					resetGrade = false;
				}
			}
			if(resetGrade){
				selectedGrade = '--None--';
			}
			if(schoolSectionMap.containsKey(selectedSchool)){
				sections.addAll(schoolSectionMap.get(selectedSchool));
			} else {
				infoMessage('There are no sections available for the school/grade you selected.');
			}
			
			if(schoolCatMap.containsKey(selectedSchool)){
				catHolder.addAll(schoolCatMap.get(selectedSchool));
			}
			if(schoolCatMap.containsKey(null)){
				catHolder.addAll(schoolCatMap.get(null));
			}
			if(catHolder.isEmpty()){
				errorMessage('There are no Points Categories for your school. Please contact your administrator.');
				bFatalError = true;
				return;
			}
		}
		
		sections = StringUtils.sortList(sections, false);
		grades = StringUtils.sortList(grades, true);
		if(!grades.isEmpty()){
			grades.add(0,new SelectOption('--None--', '--None--'));
		} else {
			grades.add(new SelectOption('--None--', '--None--'));
		}
		
		if(!sections.isEmpty()){
			sections.add(0,new SelectOption('--None--', '--None--'));
		} else{
			sections.add(new SelectOption('--None--', '--None--'));
			errorMessage('There are no sections available for the school/grade you selected.');
		}
	}
	
	public void changeGrade(){
		sections = new List<SelectOption>();
		catHolder = new List<Picklist_Value__c>();
		boolean resetSection = true;
		
		//school but no grade
		if(selectedGrade == '--None--' && selectedSchool != '--None--'){
			if(schoolSectionMap.containsKey(selectedSchool)){
				sections.addAll(schoolSectionMap.get(selectedSchool));
				resetSection = false;
				if(schoolCatMap.containsKey(selectedSchool))
					catHolder.addAll(schoolCatMap.get(selectedSchool));
				if(schoolCatMap.containsKey(null))
					catHolder.addAll(schoolCatMap.get(null));
			}
		//no school or grade
		} else if(selectedGrade == '--None--' && selectedSchool == '--None--'){
			for(List<SelectOption> selectList: schoolSectionMap.values()){
				sections.addAll(selectList);
				resetSection = false;
			}
			catHolder.addAll(categories);
			
		//grade, but no school
		} else if(selectedGrade != '--None--' && selectedSchool == '--None--'){
			for(List<SelectOption> selectList: schoolSectionMap.values()){
				for(SelectOption s: selectList){
					if(sectionGradeMap.get(s.getValue()).contains(selectedGrade+';')){
						sections.add(s);
						if(s.getvalue() == selectedSection){
							resetSection = false;
						}
					}
				}
			}
			for(Picklist_Value__c p:categories){
				string temp = ';'+p.Grade__c+';';
				if(temp.contains(';'+selectedGrade+';')){
					catHolder.add(p);
				}
			}
		//school and grade
		} else if(selectedGrade != '--None--' && selectedSchool != '--None--'){
			if(schoolSectionMap.containsKey(selectedSchool)){
				for(SelectOption s:schoolSectionMap.get(selectedSchool)){
					if(sectionGradeMap.get(s.getValue()).contains(selectedGrade+';')){
						sections.add(s);
						if(s.getvalue() == selectedSection){
							resetSection = false;
						}
					}
				}
			
			
				List<Picklist_Value__c> tempList = new List<Picklist_Value__c>();
				if(schoolCatMap.containsKey(selectedSchool))
					templist.addAll(schoolCatMap.get(selectedSchool));
				if(schoolCatMap.containsKey(null))
					tempList.addAll(schoolCatMap.get(null));
				for(Picklist_Value__c p:tempList){
					string temp = ';'+p.Grade__c+';';
					if(temp.contains(';'+selectedGrade+';')){
						catHolder.add(p);
					}
				}
			}
		}
		if(resetSection){
			selectedSection = '--None--';
		}
		sections = StringUtils.sortList(sections, false);
		if(!sections.isEmpty()){
			sections.add(0,new SelectOption('--None--', '--None--'));
		} else{
			sections.add(new SelectOption('--None--', '--None--'));
			infoMessage('There are no sections available for the school/grade you selected.');
		}
		if(catHolder.isEmpty()){
			errorMessage('There are no Points categories for the school/grade selected.');
		}
	}
	
	public void filterAndLoad(){
		currentCats = new List<Picklist_Value__c>();
		system.debug(selectedSection);
		system.debug(sectionSchoolMap);
		system.debug(schoolCatMap);
		if(selectedSchool == '--None--' && selectedSection != '--None--'){
			catHolder = new List<Picklist_Value__c>();
			if(schoolCatMap.containsKey(sectionSchoolMap.get(selectedSection))){
				catHolder.addAll(schoolCatMap.get(sectionSchoolMap.get(selectedSection)));
			}
			if(schoolCatMap.containsKey(null)){
				catHolder.addAll(schoolCatMap.get(null));
			}
		}
		
		currentCats.addAll(catHolder);
		selectedDate = dateHolder;
		Map<String ,Points__c> pointMap=new Map<String ,Points__c>();
		points = new List<Points_MatrixWrapper>();
		boolean hasSection = true;
		
		if(selectedSection == '--None--' && !isAdmin){
			errorMessage('You must select a section.');
			return;
		} else if(selectedSection == '--None--'){
			hasSection = false;
		}
		if(selectedSection != '--None--'){
			selectedSectionName = sectionNameMap.get(selectedSection);
		}
		Map<String ,Picklist_Value__c> cMap=new Map<String ,Picklist_Value__c>();
			for(Picklist_Value__c cc:currentCats){
				cMap.put(cc.Name,cc);
			}
			List<String> sorts=new List<String>(cMap.keySet());
			sorts.sort();
			
			List<Picklist_Value__c> NewcMap=new List<Picklist_Value__c>();
			for(String s:sorts){
				NewcMap.add(cMap.get(s));
			}
			currentCats=new List<Picklist_Value__c>();
			currentCats=NewcMap;
			Points_MatrixWrapper.cats = currentCats;
		
		//get the students we need first.
		if(hasSection){
			List<Student_Section__c> ssList = Points_SoqlUtils.getPointsByStudentSection(selectedSection, selectedDate);
			for(Student_Section__c s: ssList){
				points.add(new Points_MatrixWrapper(s));
			}
			List<Student_Section__c> reList=Points_SoqlUtils.getRedeemByStudentSection(selectedSection, selectedDate);
			redeemPoints=new List<Points_RedeemWrapper>();		
			for(Student_Section__c s: reList){
				redeemPoints.add(new Points_RedeemWrapper(s));
			}
		} else {
			List<Student__c> studentList = Points_SoqlUtils.getPointsByStudentGroup(selectedSchool, selectedGrade, selectedDate);
			for(Student__c s: studentList){
				points.add(new Points_MatrixWrapper(s));
			}
			List<Student__c> reList=Points_SoqlUtils.getRedeemByStudentGroup(selectedSchool, selectedGrade, selectedDate);
			redeemPoints=new List<Points_RedeemWrapper>();
			for(Student__c s: reList){
				redeemPoints.add(new Points_RedeemWrapper(s));
			}
		}
		
		showMatrix = true;
	}
	
	public void showRedeem(){
		showRedeem = true;
	}
	
	private boolean loadStaffData(){
		Contact staffContact = core_SoqlUtils.getLoggedInContact();
		if(staffContact == null){
			errorMessage('Your user is not associated with a contact.');
			return false;
		}
		List<Staff__c> staffList = [select id, Organization__c, Organization__r.Name from staff__c where Individual__c=:staffContact.id and Active__c = true order by Organization__r.Name];
		if(staffList.isEmpty()){
			errorMessage('No active staff records for logged in user.  Please contact your administrator.');
			return false;
		}
		Set<Id> staffIds = new Set<Id>();
		Set<ID> schoolIds = new Set<ID>();
		Map<Id, ID> staffSchoolMap = new Map<Id, Id>();
		sectionSchoolMap = new Map<Id, ID>();
		staffMap = new Map<Id, Staff__c>();
		
		//get school picklists
		for(Staff__c s:staffList){
			schools.add(new SelectOption(s.Organization__c, s.Organization__r.Name));
			staffIds.add(s.Id);
			schoolIds.add(s.Organization__c);
			schoolStaffMap.put(s.Organization__c, s.id);
		}
		schools = StringUtils.sortList(schools, false);
		schools.add(0, new SelectOption('--None--', '--None--'));
		
		for(Setup__c s: core_SoqlUtils.getActiveSetups(schoolIDs).values()){
			if(s.Grade_Span__c != null){
				for(String grade: s.Grade_Span__c.split(';')){
					if(schoolGradeMap.containsKey(s.School__c)){
						schoolGradeMap.get(s.School__c).add(grade);
					} else {
						schoolGradeMap.put(s.School__c, new List<String>{grade});
					}
				}
			} else {
				schoolGradeMap.put(s.School__c, new List<String>());
				infoMessage(s.school__r.Name+'\'s grade span is not set. Therefore no grade options will be available for that school.');
			}
		}
		
		Profile p = [select Name from Profile where id =: userinfo.getProfileId()];
		sectionGradeMap = new Map<Id, String>();
		if(adminProfiles.contains(p.Name)){
			//admin loadout
			isAdmin = true;
			for(Section__c s: [select id, Name, School__c, Grade_Level__c, All_Grades__c from Section__c where Active__c = true AND School__c IN: schoolIds and RecordType.DeveloperName='Published']){
				string grades = (s.Grade_Level__c != null)?(s.Grade_Level__c+';'):'';
				grades += (s.All_Grades__c != null)?(s.All_Grades__c + ';'):'';
				sectionGradeMap.put(s.id, grades);
				sectionNameMap.put(s.id, s.Name);
				if(schoolSectionMap.containsKey(s.School__c)){
					schoolSectionMap.get(s.School__c).add(new SelectOption(s.id, s.Name));
				} else {
					schoolSectionMap.put(s.School__c, new List<SelectOption>{new SelectOption(s.id, s.Name)});
				}
			}
		} else {
			isAdmin = false;
			// teacher loadout
			Map<Id, List<Section__c>> staffSecList = core_SoqlUtils.getSectionsbyStaffMap(staffIds);
			if(staffSecList.isEmpty()){
				errorMessage('You are not currently teaching any sections. Please contact your administrator.');
				return false;
			}
			for(Staff__c s:staffList){
				staffSchoolMap.put(s.organization__c, s.id);
				if(staffSecList.containsKey(s.id)){
					for(Section__c sec:staffSecList.get(s.id)){
						if(sec.Active__c){
							string grades = (sec.Grade_Level__c != null)?(sec.Grade_Level__c+';'):'';
							grades += (sec.All_Grades__c != null)?(sec.All_Grades__c + ';'):'';
							sectionGradeMap.put(sec.id, grades);
							sectionSchoolMap.put(sec.id,s.Organization__c);
							if(schoolSectionMap.containsKey(s.Organization__c)){
								schoolSectionMap.get(s.Organization__c).add(new SelectOption(sec.id, sec.Name));
							} else {
								schoolSectionMap.put(s.Organization__c, new List<SelectOption>{new SelectOption(sec.id, sec.Name)});
							}
						}
					}
				}
			}
		}
		
		for(ID sID: schoolIds){
			if(!schoolSectionMap.containsKey(sID)){
				schoolSectionMap.put(sid, new List<SelectOption>());
			}
		}
		
		return true;
	}
	
	private boolean loadCats(){
		categories = Points_SoqlUtils.getCats();
		if(categories == null || categories.isEmpty()){
			errorMessage('There are no Points Categories for your org. Please contact your administrator.');
			return false;
		}
		schoolCatMap = new Map<Id, List<Picklist_Value__c>>();
		for(Picklist_Value__c p:categories){
			//we want the null setups in the list as well.
			if(schoolCatMap.containsKey(p.Setup__r.School__c)){
				schoolCatMap.get(p.Setup__r.School__c).add(p);
			} else {
				schoolCatMap.put(p.Setup__r.School__c, new List<Picklist_Value__c>{p});
			}
		}
		return true;
	}
	
	public void changeDate(){
		try{
			date newDate = date.parse(prettyDate);
			if(newDate > system.today()){
				errorMessage('Entering points for future dates is not supported.');
				return;
			}
			dateHolder = newDate;
		} catch (Exception e) {
			errorMessage('Please enter a valid date.');
		}
	}
	
	public Pagereference SavePoints(){
		List<Points__c> toUpsert = new List<Points__c>();
		for(Points_MatrixWrapper mw:points){
			//only process the active students
			if(mw.isActive){
				for(Points__c p: mw.points){
					if(p.Points__c != null){
		   				p.Points_Date__c = selectedDate;
		   				p.Staff__c = schoolStaffMap.get(mw.SchoolID);
		   				if(p.id == null){
		   					p.Reference_Id__c = mw.studentID + '_' + p.Category__c + '_';
		   					if(selectedSection != '--None--'){
		   						p.Reference_Id__c += selectedSection + '_';
		   					}
		   					p.Reference_Id__c += prettyDate;
		   				}
		   				toUpsert.add(p);
					}
	   			}
			}
		}
		
		if(!toUpsert.isEmpty())
   			upsert toUpsert Reference_Id__c;
   		pageReference pref = Page.Points_Matrix;
   		pref.getParameters().put('goodSave', 'true');
   		pref.setRedirect(true);
   		return pref;
    }
    
    public PageReference RedeemPoints(){
   		List<Points__c> newPointsUpsert=new List<Points__c>();
   		for(Points_RedeemWrapper pm:redeemPoints){
   			if(pm.isActive && pm.redeemPoint.Points__c != null){
   				pm.redeemPoint.Points__c = ((pm.redeemPoint.Points__c > 0)?-1:1) * pm.RedeemPoint.Points__c;
   				pm.redeemPoint.Points_Date__c=selectedDate;
   				pm.redeemPoint.Reference_Id__c += '_'+prettyDate;
   				pm.redeemPoint.Staff__c = schoolStaffMap.get(pm.SchoolID);
   				newPointsUpsert.add(pm.redeemPoint);
   			}
   		}
   		if(!newPointsUpsert.isEmpty())
   			upsert newPointsUpsert Reference_Id__c;
   		return null;
    }
	
	private void errorMessage(string error){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
	}

	private void infoMessage(string message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
	}
}