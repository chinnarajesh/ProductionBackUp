public   class Student_SectionGrades {

 		public ApexPages.StandardController 			controller 				{get; set;}
		public List<SectionGradeWrapper> sectionGradeWrapperList	{get;set;}
	 	public Id														studentId				{get;set;}
 	  	public Student__c											currstudent					{get;set;}
		public transient List<Student_Section__c> studentSections	{get;set;}
		public Map <String, String>	sectionGradeMap 				{get; set;}
		public List<Student_Reporting_Period__c> srpList			{get;set;}
		public List<Time_Element__c> reportingPeriodList			{get;set;}
		public Student_SectionGrades(ApexPages.StandardController controller){
			if (System.currentPageReference().getParameters().containsKey('id')!=null) studentId = System.currentPageReference().getParameters().get('id');
 	  		currstudent = core_SoqlUtils.getStudentById(studentId)[0]; 
			sectionGradeWrapperList=	getsectionGrades();
		}
	

		public List<SectionGradeWrapper> getsectionGrades(){
			reportingPeriodList = new List<Time_Element__c>();
			srpList = new List <Student_Reporting_Period__c>();
			sectionGradeWrapperList = new List<SectionGradeWrapper>();
			Map<String, Section_Grade__c> keyToRpSecGradesMap = new Map<String, Section_Grade__c>();
			Map<String, Student_Reporting_Period__c> keyToSrpMap = new Map<String, Student_Reporting_Period__c>();
			Set<String> cIds = new  Set<String>();
			List<Course__c> courseList = new List<Course__c>();
			Map<Id, Final_Grade__c> courseIdToFinalGradeMap = new Map<Id, Final_Grade__c>();
			Map<Id,Section__c> courseIdToSectionMap = new Map<Id,Section__c>();
			List<Section_Grade__c> secGradesList;
			Set <Id>	sectionids = new Set <Id>();
			Set <Id> rpIds			= new Set <Id>();
			Map <Id, String> sectionToTeacherMap = new Map <Id, String>();
			
		 	Set <String> allow = gradebook_SoqlUtils.getAllowedNaValues();
			Double currRPGrade = -1;
			OverrideSettings__c os = gradebook_SoqlUtils.os;
			
			for (Student_Section__c ss: [select id, section__c, section__r.course__r.name, section__r.course__r.id, section__r.course__r.Grade_Scale_Lookup__r.Name, section__r.course__c, section__r.course__r.grade_scale__c 
																from Student_Section__c 
																where Active__c = true 
																and Student__c=:currStudent.id
																and Section__r.RecordType.DeveloperName ='Published'
																and Section__r.Course__c !=null]){
				if(!cIds.contains(ss.Section__r.Course__c)){
					cIds.add(ss.Section__r.Course__c);
					courseList.add(ss.Section__r.Course__r);
					sectionids.add(ss.Section__c);
					courseIdToSectionMap.put(ss.Section__r.Course__c,ss.Section__r);
				}
			}

			/*Get Section Reporting periods to serve as snippet headers*/
			for (Section_ReportingPeriod__c srp: [select time__r.name__c, time__c 
													from Section_ReportingPeriod__c 
													where Section__c in :sectionIds
													order by time__r.date_start_date__c]){
				if (!rpIds.contains(srp.time__c)){
					rpIds.add(srp.time__c);
					reportingPeriodList.add(srp.time__r);
				}
			}
			//build a map of final grades for the student
			for(Final_Grade__c fg :[SELECT  Final__c, Course__r.Name, course__r.grade_scale__c, Course__r.Grade_Scale_Lookup__r.Name, Final_Grade_Letter_v2__c, Final_Grade_Value__c, Course__c, Display_Final_Grade_Formula__c
				FROM Final_Grade__c
				WHERE Student__c =: currstudent.Id 
			]){
				if(!cIds.contains(fg.Course__c)){
					cIds.add(fg.Course__c);
					courseList.add(fg.Course__r);
				}
				courseIdToFinalGradeMap.put(fg.Course__c,fg);
			}

		for(Section_Grade__c sg : [SELECT Id
										,Grade__c
										,Letter_Grade__c
										,Time__r.Name__c
										,Student_Section__c
										,Student_Section__r.Section__r.Course__r.Name
										,Student_Section__r.Section__r.Course__c
										,Student_Section__r.Section__r.Name
										,Student_Section__r.Section__r.Homework_based__c
										,Standard_Section_Grade_v2__c
										,Display_Grade_Formula__c 
									FROM Section_Grade__c
									WHERE Student_Section__r.Active__c = true
									AND Student_Section__r.Section__r.Active__c = true
									//AND Time__r.Reporting_Period__c = true
									AND Student_Section__r.Section__r.Course__r.Exclude_on_RC_Transcripts__c = false
									AND RecordType.DeveloperName !='Semester'
									AND Student_Section__r.Student__c =:currStudent.id
									order by Time__r.Date_start_date__c]){
			keyToRpSecGradesMap.put(sg.Student_Section__r.Section__r.Course__c+'-'+sg.Time__c,sg);
		}
		
		 for (Student_Reporting_Period__c srp: [select id, time__c,time__r.name, time__r.date_start_date__c, student__c, gpa__c from Student_Reporting_Period__c where Student__c =:currstudent.id ]){
	    	keyToSrpMap.put(srp.Time__c,srp);
		 }
		 if (!sectionids.isEmpty()){
		 	for (Staff_Section__c ss: [select id, staff__r.name, section__r.Course__c from Staff_Section__c where Section__c in :sectionids and Display_Teacher_On_RC_PR__c=true]){
		 		sectionToTeacherMap.put(ss.section__r.course__c, ss.Staff__r.name);
		 	}
		 }
		 
		 system.debug('courseList~~~'+courseList);
		for(Course__c c: courseList){
			secGradesList = new List<Section_Grade__c>();
				system.debug('id~~~'+c.id);
			system.debug('set~~'+courseIdToFinalGradeMap.keySet());
			//if (courseIdToFinalGradeMap.keySet().contains(c.id)){
				Final_Grade__c fg = courseIdToFinalGradeMap.get(c.id);
				for(Time_Element__c te : reportingPeriodList){
					/* For Section Grades*/
					if (keyToRpSecGradesMap.get(c.id+'-'+te.id)!=null){
						secGradesList.add(keyToRpSecGradesMap.get(c.id+'-'+te.id));
					}
					else {
						secGradesList.add(new Section_Grade__c());
					}
				}
				sectionGradeWrapperList.add(new SectionGradeWrapper(c,secGradesList,fg, sectionToTeacherMap.get(c.id)));
			//}
		}
		
		for(Time_Element__c te : reportingPeriodList){
				/* For GPAs*/
				if (keyToSrpMap.get(te.id)!=null){
					srpList.add(keyToSrpMap.get(te.id));
				}
				else {
					srpList.add(new Student_Reporting_Period__c());
				}
			}
		
		return sectionGradeWrapperList;
	}
	
	public with sharing class SectionGradeWrapper {
			public Course__c course				{get;set;}
			public List<Section_Grade__c> rpGrades		{get;set;}
			public string					teacherName		{get;set;}
			public Final_Grade__c finalGrade		  	{get;set;}
			public Double currentGrade			{get;set;}
			public boolean hasOneSectionGrade	{get;set;}
			public string 		scaleName 			{get;set;}
	
			public SectionGradeWrapper(Course__c c, List<Section_Grade__c> grd,Final_Grade__c fg, string teacher){
				this.course = c;
				this.rpGrades = grd;
				this.finalGrade = fg;
				this.hasOneSectionGrade = false;
				this.teacherName = teacher;
				this.scaleName = c.grade_scale_lookup__c !=null ? c.grade_scale_lookup__r.name : c.grade_scale__c;
				for(Section_grade__c s:grd){
					if(s.Letter_Grade__c!=''){
						this.hasOneSectionGrade = true;
						break;
					}
				}
			}
		}
		
		static testMethod void testStudent_SectionGrades(){
			Test_Gradebook_Overrides.setupData();
			system.runAs(testDataSetupUtil_v2.staffUsersList[1]){ 
				Test_Gradebook_Overrides.setupGbData('Letter Grade', 'B','X',null);
	           	PageReference p = Page.Student_SectionGrades;
	           	test.setCurrentPage(p); 
			   	ApexPages.currentPage().getParameters().put('id', testDataSetupUtil_v2.studentsList[0].id);
			    ApexPages.StandardController con = new ApexPages.StandardController( testDataSetupUtil_v2.studentsList[0]);
			    Student_SectionGrades s = new Student_SectionGrades(con);
	            system.assertEquals(1, s.sectionGradeWrapperList.size());
			}
		}

}