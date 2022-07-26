public with sharing class YOY_SectionGradesAndFinalGrades {
	public List<Time_Element__c> years					{get;set;}
	public List<Selectoption> yearOptions				{get;set;}
	public List<StudentWrapper> studentWrapperList		{get;set;}
	public List<Time_Element__c> reportingPeriodList	{get;set;}
	public string selectedYear							{get;set;}
	public string contactId;
	public Map<String,Setup__c> setupMap;
	public static Map<String,Course__c> courseIdToCourseMap;

	public YOY_SectionGradesAndFinalGrades(ApexPages.StandardController stdCon){
		setupMap = new Map<String,Setup__c>();
		Map<String,Student__c> setupStudentMap = new Map<String,Student__c>();
		Set<String> yearIds = new Set<String>();
		yearOptions = new List<selectoption>();
		
		Contact con = (Contact) stdCon.getRecord();
		if(con != null) {
			contactId = con.Id;
			for(Student__c stu:
					[SELECT Setup__c ,Id,Setup__r.Year__c,Setup__r.Standards_ONLY_Gradebook__c,Setup__r.Term__c,School_Year__r.Name__c,School_Year__c 
					FROM Student__c 
					WHERE Individual__c = :contactId 
					order by School_Year__r.Date_Start_Date__c desc]){
				setupStudentMap.put(stu.Setup__c,stu);
				setupMap.put(stu.Setup__r.Term__c,stu.Setup__r);
				yearOptions.add(new Selectoption(stu.Setup__r.Term__c+'_'+stu.Id,stu.School_Year__r.Name__c));
			}
		} else {
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'No contact information was provided.'));
		}
	}
	
	public static Map<ID, String> getFinalGradeMap(ID studId){
		Map<ID,String> courseIdToFinalGradeMap = new Map<ID,String>();
		courseIdToCourseMap = new Map<String,Course__c>();
		//Collect all the Final Grades and add into CourseIdToFinalGradeMap
		for(Final_Grade__c fg:
				[SELECT Final_Grade_Value__c, Final_Grade_Letter_v2__c, Course__c,Course__r.Name, Course__r.Display_Numerical_Values_On_Report_Card__c,
					Display_Final_Grade_Formula__c
				FROM Final_Grade__c
				WHERE Student__c =: studId]){ 
			String finalGrade;
			if(fg.Course__r.Display_Numerical_Values_On_Report_Card__c){
				finalGrade = string.valueOf(fg.Final_Grade_Value__c);
			} else {
				finalGrade = fg.Display_Final_Grade_Formula__c;
			}
		 	courseIdToFinalGradeMap.put(fg.Course__c,finalGrade);
		 	courseIdToCourseMap.put(fg.Course__c, fg.Course__r);
		}
		return courseIdToFinalGradeMap;
	}
	
	public Pagereference retrieveGrades(){
		if(selectedYear != null && selectedYear!=''){
			String termId = selectedYear.split('_')[0];
			String currentStudent = selectedYear.split('_')[1];
			getReportingPeriods(termId);
			getSectionGradesPerRP(termId,currentStudent);
		}
		return null;
	}
	
	public void getReportingPeriods(String termId){
		if(reportingPeriodList == null){
			try{
				reportingPeriodList = Gradebook_ReportCard_Utils.getPrimaryReportingPeriods(termId);
			} catch (exception e){
				reportingPeriodList = new List<Time_Element__c>();
			}
		}
	}
	
	public void getSectionGradesPerRP(String TermId,String studentId){
		Map<ID, String> courseToFinalGrade = getFinalGradeMap(studentID);
		//holds section grades, Section ID to RP ID to grade value
		Map<ID,Map<ID,String>> sectionGradeMap = new Map<ID,Map<ID,String>>();
		Map<ID,Course__c> sectionToCourse = new Map<ID,Course__c>();
		for(Section_Grade__c sg :
				[SELECT Id, Grade__c, Letter_Grade__c, Student_Section__c, Standard_Section_Grade_v2__c,
					Time__c,Student_Section__r.Section__r.Course__c, Student_Section__r.Section__r.Course__r.Special_Subject__c,
					Student_Section__r.Section__r.Homework_based__c, Student_Section__r.Section__r.Course__r.Name,
					Student_Section__r.Section__r.Course__r.Reporting_Course_Name__c, Student_Section__r.Section__r.Name,
					Comments_Next_Steps__c, Alternate_Lang_Comments__c, Student_Section__r.Section__c,
					Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c, Display_Grade_Formula__c
				FROM Section_Grade__c
				WHERE Student_Section__r.Student__c =: studentId
				AND ((Student_Section__r.Active__c = true AND Student_Section__r.Archived__c = false) OR (Student_Section__r.Active__c = false AND Student_Section__r.Archived__c = true))
				AND Student_Section__r.Section__r.Course__r.Exclude_on_RC_Transcripts__c = false
				AND Time__r.Parent_Time_Element__c = :TermId
				order by Student_Section__r.Section__r.Course__r.Name,Student_Section__r.Section__r.Name,Time__r.Date_Start_Date__c]){
			//get grade value
			String grade = '';
			if(sg.Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c){
				grade = String.valueOf(sg.Grade__c);
			} else {
				grade = sg.Display_Grade_Formula__c;
			}

			if(grade != null){
				if(sectionGradeMap.containsKey(sg.Student_Section__r.Section__c)){
					sectionGradeMap.get(sg.Student_Section__r.Section__c).put(sg.Time__c,grade);
				} else {
					sectionGradeMap.put(sg.Student_Section__r.Section__c, new Map<ID,String>{sg.Time__c=>grade});
					sectionToCourse.put(sg.Student_Section__r.Section__c,sg.Student_Section__r.Section__r.Course__r);
				}
			}
			
		}
		studentWrapperList = new List<StudentWrapper>();
		for(ID sectionID:sectionToCourse.keySet()){
			system.debug(sectionID);
			Course__c course = sectionToCourse.get(sectionID);
			system.debug(course);
			List<String> grades = new List<String>();
			for(Time_ELement__c rp:reportingPeriodList){
				if(sectionGradeMap.get(sectionId).containsKey(rp.id)){
					grades.add(sectionGradeMap.get(sectionId).get(rp.id));
				} else {
					grades.add('');
				}
			}

			studentWrapperList.add(new StudentWrapper(course.Name,grades,courseToFinalGrade.get(course.Id)));	
		}
	}

	public class StudentWrapper{
		public String course 			{get;set;}
		public List<String> rpGrades	{get;set;}
		public String finalGrade 		{get;set;}

 		public StudentWrapper(String c, List<String> grd,String fg){
			this.course = c;
			this.rpGrades = grd;
			this.finalGrade = fg;
		}
	}
}