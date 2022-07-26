public with sharing class Gradebook_CreateGroups {
	public List<Section__c> staffSections		{get;set;}
	public List<Section__c> existingGroups		{get;set;}
	public List<Student_Section__c> deleteList	{get;set;}
	public List<studentWrapper> wStudents		{get;set;}
	public String sectionID						{get;set;}
	public String groupID						{get;set;}
	public boolean sectionSelected				{get;set;}
	public boolean editExisting					{get;set;}
	public boolean bShowGroupSetup				{get;set;}
	public boolean studentsSelected				{get;set;}
	public String selectedSection				{get;set;}
	public String groupName						{get;set;}
	public String groupDescription				{get;set;}
	public List<ID> studentsToAdd				{get;set;}
	public String course;
	public String gradeLevel;
	public String userName						{get;set;}
	public Staff__c StaffID						{get;set;}
	public core_BaseInfo_v2.cSchool_BaseInfo	baseObj		{get;set;}
	public Map <String, Id> sectionRtMap {get;set;}
	
	public Gradebook_CreateGroups(){
		
		studentsToAdd = new List<ID>();
		deleteList	  = new List<Student_section__c>();
		existingGroups= new List<Section__c>();
		staffSections = new List<Section__c>();
		sectionRtMap = core_SoqlUtils.getRecordTypesBySobject('Section__c');
				core_BaseInfo_v2.initBaseInfo();
		baseObj = core_BaseInfo_v2.baseInfoObj;
		StaffID = baseObj.staff;
		sectionSelected	= false;	
		List<Section__c> tempList = new List<Section__c>();
		//DE2967
		for(Staff_Section__c s: [select Section__r.id, 
	    	 						   Section__r.Staff__c, 
	    	 						   Section__r.Reference_ID__c, 
	    	 						   Section__r.active__c, 
	    	 						   Section__r.Course__c,
	    	 						   Section__r.of_Students__c ,
	    	 						   Section__r.Period__c, 
	    	 						   Section__r.Description__c, 
	    	 						   Section__r.Daily_Attendance__c, 
       								   Section__r.Course__r.Name, 
       								   Section__r.Course__r.Type__c, 
       								   Section__r.Course__r.Grade_Scale__c, 
       								   Section__r.Section__c, 
       								   Section__r.Name, 
       								   Section__r.Is_Section__c, 
       								   Section__r.Section__r.Name, 
       								   Section__r.Record_Attendance__c from Staff_Section__c where Staff__c = :baseObj.staff.id AND View_Gradebook_as_Read_Only__c = false and (Section__r.REcordType.DeveloperName='Published' OR Section__r.REcordType.DeveloperName='Gradebook_Group')]){
       								   tempList.add(s.Section__r);
       								   }
		
		for(Section__c sect : tempList){
			if(!sect.is_Section__c){
				existingGroups.add(sect);
			}
			else{
				if(sect.Daily_Attendance__c){
					if(baseObj.activeSetup.Show_Attendance_Sections_in_Gradebook__c){
		       			staffSections.add(sect);
					}
				}
				else{
					staffSections.add(sect);
				}
			}
		}
		
	}
	
	public static List <Student_Section__c> getStudentsBySection(Id SectionId ){
		List <Student_Section__c> ssList = new List <Student_Section__c>();
		for (Student_Section__c ss:  [select id, Student__c, Student__r.Student_First_Name__c, Student__r.ELL__c, Student__r.Ethnicity__c, Student__r.Gifted__c, Student__r.Currently_evaluated_for_special_ed__c,Section__r.is_Section__c, Student__r.Student_Last_Name__c 
															from Student_Section__c 
															where Section__c = : sectionId
															and 		student__r.active__c = true
															and 		active__c=true]){
			ssList.add(ss);
		}
		return ssList;
	}
	public void editExisting(){
		
		selectedSection = ApexPages.currentPage().getParameters().get('selectedSection');
		groupID 		= ApexPages.currentPage().getParameters().get('groupID');
		sectionID 		= ApexPages.currentPage().getParameters().get('sectionID');
		course	  		= ApexPages.currentPage().getParameters().get('sectionCourse');
		groupDescription= ApexPages.currentPage().getParameters().get('description');
		groupName 		= selectedSection;
		bShowGroupSetup = true;
		groupDescription= ApexPages.currentPage().getParameters().get('selectedDescription');
		editExisting = true;
		wStudents = new List<studentWrapper>();
		map<ID, ID> deDupe = new Map<ID, ID>();
		for(Student_Section__c ss : getStudentsBySection(groupId)){
			studentWrapper temp = new studentWrapper();
			temp.useRecord = true;
			temp.studentSection = ss;
			wStudents.add(temp);
			deDupe.put(ss.Student__r.id, ss.Student__r.id);
		}
		for(Student_Section__c ss : getStudentsBySection(sectionId)){
			if(!deDupe.keyset().contains(ss.Student__r.id)){
				studentWrapper temp = new studentWrapper();
				temp.useRecord = false;
				temp.studentSection = ss;
				wStudents.add(temp);
			}
		}
		sectionSelected = wStudents.size()>0;
	
		
	}
	public void showStudents(){
		editExisting = false;
		bShowGroupSetup = true;
		selectedSection = ApexPages.currentPage().getParameters().get('selectedSection');
		sectionID 		= ApexPages.currentPage().getParameters().get('sectionID');
		course	  		= ApexPages.currentPage().getParameters().get('sectionCourse');

		wStudents = new List<studentWrapper>();
		for(Student_Section__c ss : getStudentsBySection(sectionId)){
			
			studentWrapper temp = new studentWrapper();
			temp.useRecord = false;
			temp.studentSection = ss;
			wStudents.add(temp);
		}
		sectionSelected = wStudents.size()>0;
	}
	
	public pageReference save(){
		studentsToAdd.clear();
		deleteList.clear();
		bShowGroupSetup = false;
		for(studentWrapper sw: wStudents){
			if(sw.useRecord && sw.studentSection.Section__r.ID!=groupID)
				studentsToAdd.add(sw.studentSection.Student__c);
			else if(!sw.useRecord && sw.studentSection.Section__r.ID==groupID){
				deleteList.add(sw.studentSection);
			}
		}
		studentsSelected=studentsToAdd.size()>0;
		List<Student_Section__c> sstoCreate	  = new List<Student_Section__c>();
		
		if(editExisting){
			for(ID sw: studentsToAdd){
				Student_Section__c temp = new Student_Section__c();
				temp.Active__c = true;
				temp.Student__c = sw;
				temp.Section__c = groupID;
				sstoCreate.add(temp);
			}
			Section__c upsertSection = new Section__c(id=groupID,Description__c = groupDescription,Name= groupName);
			
			try{
				upsert upsertSection;
				upsert sstoCreate;
				delete deleteList;
			}
			catch(exception e){
			}
			pageReference p = new pageReference('/' + groupID);
			p.setRedirect(true);
			return p;
		}
		else{
			Section__c newSection = new Section__c(RecordTypeId =sectionRtMap.get('Gradebook_Group'), Name=groupName, is_Section__c = false, Description__c=groupDescription, Staff__c = StaffID.id, Section__c = sectionID, active__c=true, Course__c = course, all_grades__c = gradeLevel, School__c=baseObj.activeSetup.School__c, Time__c=baseObj.activeSetup.Year__c);
			
			try{
				insert newSection;
				
				Staff_Section__c newStaffSection = new Staff_Section__c(Staff__c = StaffID.id, Section__c = newSection.id, is_active__c=true);
				insert newStaffSection;
			}
			catch(exception e){
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error creating content record.' + e));
			}
			for(ID sw: studentsToAdd){
				Student_Section__c temp = new Student_Section__c();
				temp.Active__c = true;
				temp.Student__c = sw;
				temp.Section__c = newSection.id;
				sstoCreate.add(temp);
			}
			try{
				insert sstoCreate;
			}
			catch(exception e){
				system.debug(e.getMessage());
			}
			pageReference p = new pageReference('/' + newSection.id);
			p.setRedirect(true);
			return p;
		}
		return null;
		
	}
	public pageReference cancel(){
		pageReference p = new pageReference('/home/home.jsp');
		p.setRedirect(true);
		return p;
	}
	public class studentWrapper{
		public boolean useRecord					{get;set;}
		public Student_Section__c studentSection	{get;set;}
		
		public studentWrapper(){				
		}
	}
	public static testMethod void testCreate(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setUPStaffData(5);
		testDataSetupUtil_v2.setUPStudentData(5);
        Test.setCurrentPage(Page.Gradebook_CreateGroups);
         
		system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
			test.startTest();
				core_changeSchoolController cs = new core_ChangeSchoolController();
				cs.change();
				
				Gradebook_CreateGroups testGC = new Gradebook_CreateGroups();
				testGC.selectedSection 	= ApexPages.currentPage().getParameters().put('selectedSection', testGC.staffSections[0].Name);
				testGC.groupID 			= ApexPages.currentPage().getParameters().put('groupID', testGC.staffSections[0].id);
				testGC.sectionID 		= ApexPages.currentPage().getParameters().put('sectionID', testGC.staffSections[0].id);
				testGC.course	  		= ApexPages.currentPage().getParameters().put('sectionCourse', testGC.staffSections[0].Course__c);
				testGC.groupDescription	= ApexPages.currentPage().getParameters().put('description', testGC.staffSections[0].Description__c);
				testGC.showStudents();
				system.assertEquals(1, testGC.wStudents.size());
				testGC.wStudents[0].useRecord = true;
				testGC.groupName = 'test';
				testGC.save();

				Gradebook_CreateGroups testGC1 = new Gradebook_CreateGroups();
				testGC1.selectedSection 	= ApexPages.currentPage().getParameters().put('selectedSection', testGC1.existingGroups[0].Name);
				testGC1.groupID 			= ApexPages.currentPage().getParameters().put('groupID', testGC1.existingGroups[0].id);
				testGC1.sectionID 			= ApexPages.currentPage().getParameters().put('sectionID', testGC1.staffSections[0].id);
				testGC1.course	  			= ApexPages.currentPage().getParameters().put('sectionCourse', testGC1.existingGroups[0].Course__c);
				testGC1.groupDescription	= ApexPages.currentPage().getParameters().put('description', testGC1.existingGroups[0].Description__c);
				system.assertEquals(testGC1.existingGroups.size(),1);
				testGC1.editExisting();
				testGC1.wStudents[0].useRecord = false;
				testGC1.cancel();
			test.stopTest();
		}
	}
}