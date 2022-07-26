public with sharing class GradebookWrapper {

	public string		sectionName						{get;set;}
	public Map<String, Grade__c> StudentGradeMap;
	transient public cStudentWrapper header 						{get;set;}
	transient public List<cStudentWrapper> studentWrapperList 	{get;set;}			
   	public Map<Id, Assignment__c> assignmentMap;
   	public Map<Id, Standard__c> standardMap;
	public Map<Id, cStudentWrapper> swMap;
	public Map<Id, Section_Grade__c> sectGradeMap;
	public Map<Id, String> singleAssignmentMap;
	public Map<Id, String> singleStandardMap;
	public string 	sectionId;
	public string   timeId;
	public string 	assignmentTypeId;
	public string	selectedAssignmentID 				{get;set;}
	public string	selectedStandardID					{get;set;}
	public string	selectedStudentId					{get;set;}
	public boolean bHasStandards						{get;set;}
	


	
	public GradebookWrapper(){
		this.bHasStandards = false;
		this.assignmentMap = new Map<Id, Assignment__c>();
		this.standardMap = new Map<Id, Standard__c>();
		this.swMap = new Map<Id, cStudentWrapper>();	
		this.selectedAssignmentID = 'All';
		this.selectedStandardID = 'All';
		this.AssignmentTypeId = 'All';
		this.header = new cStudentWrapper();
		this.studentWrapperList = new List<cStudentWrapper>();
		this.sectGradeMap = new Map<Id, Section_Grade__c>();
		this.singleAssignmentMap = new Map<Id, String>();
		this.singleStandardMap = new Map<Id, String>();

	}
	public class cStudentWrapper{
		transient public Student__c		student								{get;set;}
		transient public Section_Grade__c sectionGrade						{get;set;}
		transient public List<cStandardWrapper> standardWrapperList			{get;set;}
		transient public Map<String, cStandardWrapper> standardMap			{get;set;}
		transient public List<cAssignmentWrapper> assignmentWrapperList		{get;set;}
		transient public Map<String, cAssignmentWrapper> assignmentMap		{get;set;}
		transient public integer gradeListSize								{get;set;}
		transient public string	rowStyle									{get;set;}
		transient public string	sectGradeStyle								{get;set;}
		transient public integer totalSessions {get;set;}
		transient public integer absentSessions {get;set;}
		transient public integer tardySessions{get;set;}
		
		public cStudentWrapper(Grade__c grade, Standard__c standard, Section_Grade__c sectgrade){
			init(grade, sectGrade);
			
			if(standard==null){
				this.standardMap = new Map<String, cStandardWrapper>{null=>new cStandardWrapper(grade, standard)};
			}
			else{
				this.standardMap = new Map<String, cStandardWrapper>{standard.Id=>new cStandardWrapper(grade, standard)};
			}
			
			this.standardWrapperList = new List<cStandardWrapper>();
		}
	
		public cStudentWrapper(Grade__c grade, Assignment__c assignment, String nebel, Section_Grade__c sectgrade){
			init(grade, sectGrade);
			this.assignmentMap = new Map<String, cAssignmentWrapper>{assignment.Id=>new cAssignmentWrapper(grade, assignment)};
			this.assignmentWrapperList = new List<cAssignmentWrapper>();
		}
		
		private void init(Grade__c grade, Section_Grade__c sectGrade)
		{
			this.gradeListSize = 0;
			this.student = grade.Student_Section__r.Student__r;
			if (sectGrade==null) sectGrade = new Section_Grade__c(Student_Section__c=grade.Student_Section__c, Time__c=grade.Time__c);
			this.sectionGrade = sectGrade;
			totalSessions = 0;
			absentSessions = 0;
			tardySessions = 0;
		}
	
		public cStudentWrapper(){
			this.gradeListSize = 0;
			this.standardWrapperList = new List<cStandardWrapper>();
			this.standardMap = new Map<String, cStandardWrapper>();
			this.assignmentWrapperList = new List<cAssignmentWrapper>();
			this.assignmentMap = new Map<String, cAssignmentWrapper>();
		}
	}

public List<cStudentWrapper> sortDisplayData(List<cStudentWrapper> pList, Boolean standardDisp){
        // utility lists
        List<String> names                  = new List<String>();               // list of student names
        List<cStudentWrapper> retList   = new List<cStudentWrapper>();  // sorted list ready to be returned
        Map <String, cStudentWrapper> studentWrapperMap = new Map<String, cStudentWrapper>();
      		
        
        // obtain the student's name 
        for(cStudentWrapper h : pList){
        	string key  = h.student.student_last_name__c+h.student.student_first_Name__c+h.student.id;
            names.add(key);         // add the student's name to the list for sorting purposes
             if (h.student.name.length() >= 25) h.student.name = h.student.student_first_Name__c.substring(0,1)+'. '+h.student.student_last_name__c;
            studentWrapperMap.put(key, h);
        }
        
        names.sort();       // sort the list of names
        
        // prepare the output data list to match the order of sorted name list
        for(String s : names) {
            retList.add(studentWrapperMap.get(s));
        }
        
        if(!standardDisp){
	        for(cStudentWrapper sw: retList){
	        	List<String> awKeyList = new List<String>();
	        	Map <String, cAssignmentWrapper> swMap = new Map<String, cAssignmentWrapper>();
	        	List<cAssignmentWrapper> tempList = new List <cAssignmentWrapper>();
	        	for(cAssignmentWrapper aw: sw.assignmentMap.values()){
	        		string swKey = aw.assignment.Due_Date__c+'-'+aw.assignment.id;
	        		awKeyList.add(swKey);
	        		swMap.put(swKey, aw);	        		
	        	}
	        	
	        	awKeyList.sort();
	        	
	        	
	        	for(String key: awKeyList){
		      	tempList.add(swMap.get(key));		      	
	        	}
	        	sw.assignmentWrapperList.clear();
	        	sw.assignmentWrapperList = tempList;
	        }
        }
        return retList;
    }
    
public class cStandardWrapper{
	public ID assignmentID			{get;set;}
	public Standard__c standard 	{get;set;}
	public String standardName		{get;set;}
	public List<Grade__c> gradeList {get;set;}
	public Integer gradeListSize;	
	
	public cStandardWrapper(Grade__c grade, Standard__c standard){
		this.assignmentID = grade.Assignment__c;
	 	if (standard==null){
	 		this.standardName='';
	 	}
	 	else {
	 		this.standard=standard;
	 		this.standardName=standard.Name;
	 	}
	 	this.gradeList = new List <Grade__c>{grade};
		this.gradeListSize=1;
	}
	
	public cStandardWrapper(){
		
		this.gradeList = new List <Grade__c>();
		this.standard = new Standard__c();
		this.gradeListSize=0;
	}
	
	public integer getgradeListSize(){
		gradeListSize = gradeList.size();
		return gradeListSize;
	}
}

public class cAssignmentWrapper{
	public Assignment__c assignment {get;set;}
	public String assignmentName;
	public List<Grade__c> gradeList {get;set;}
	public Integer gradeListSize;
	

	public cAssignmentWrapper(Grade__c grade, Assignment__c assignment){
	 		this.assignment=assignment;
	 		this.assignmentName=assignment.Name;
	 		this.gradeList = new List <Grade__c>{grade};
	 		this.gradeListSize=0;
	}
	
	public cAssignmentWrapper(){
		this.gradeList = new List <Grade__c>();
		this.assignment = new Assignment__c();
		this.gradeListSize=0;
	}
	
	public integer getgradeListSize(){
		gradeListSize = gradeList.size();
		return gradeListSize;
	}
	
		
}

}