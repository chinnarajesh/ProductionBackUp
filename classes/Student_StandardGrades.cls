public class Student_StandardGrades {
 		
	public  ApexPages.StandardController controller {get; set;}
	public  List<subjectWrapper> subjectWrappers {get; set;}
	public  ID studentID {get; set;}
	public  Student__c currentStudent {get; set;}
	public  List<Time_Element__c> orderedReportingPeriods {get; set;}
	
	private  Map<String, List<standardWrapper>> standardSubjectMap = new Map<String, List<standardWrapper>>();
	private  List<Standard_Grade__c> standardGrades = new List<Standard_Grade__c>();
	
	public Student_StandardGrades(ApexPages.StandardController controller){
		
		//initialize
		subjectWrappers = new List<subjectWrapper>();
		orderedReportingPeriods = new List<Time_Element__c>();
		
		if (System.currentPageReference().getParameters().containsKey('id')!=null) {
			studentID = System.currentPageReference().getParameters().get('id');
			currentStudent = core_SoqlUtils.getStudentById(studentID)[0];
			getStandardGrades();			
		}
	}

	private void getStandardGrades() {
		//we only care about getting the standard grades for the student.
		//we need rp order? requires section-reporting-periods, standard/strand grades
		//are not section tied, so cannot really rely on srp.
		//first get all the standard grades.  Figure out what is the latest rp.  Then build off of it
		//reason is because of the possibility that there could be a standard grade on a final rp.
		//Loop through standardGrades to find the F-RP Filters.
		standardGrades = [SELECT ID, Standard_Grade__c, Grade_Overridden__c, Grade_Override__c, Standard__r.Name, 
				Standard__r.Description_Spanish__c, 
				Standard__r.Subject__c, Standard__r.Strand__r.Subject__c, 
				Standard__r.Strand__r.Name, 
				Standard__r.Long_Text__c,
				Reporting_Period__c, Standard__c,
				Reporting_Period__r.Reporting_Period__c
				FROM Standard_Grade__c 
				WHERE student__c = :studentId 
				AND (Grade_Overridden__c = FALSE OR (Grade_Overridden__c=TRUE AND Grade_Override__c != NULL))
				AND Standard__c != null
				AND Standard__r.Strand__c != null
				AND Reporting_Period__c != null
				ORDER BY Standard__r.Name, Reporting_Period__r.End_Date__c, Reporting_Period__r.Reporting_Period__c DESC];
		Set<ID> includeRP = new Set<ID>();
		for(Standard_Grade__c sg : standardGrades) {
			if(!sg.Reporting_Period__r.Reporting_Period__c) {
				includeRP.add(sg.Reporting_Period__c);
			}
		}

		orderedReportingPeriods = Gradebook_ReportCard_Utils.getReportingPeriods(currentStudent.Setup__r.Term__c);
		
		for(Integer i = 0; i < orderedReportingPeriods.size(); i++) {
			if(!(orderedReportingPeriods[i].Reporting_Period__c || includeRP.contains(orderedReportingPeriods[i].ID))) {
				orderedReportingPeriods.remove(i);
				i--;
			}
		}

		for(Integer i=0; i < standardGrades.size(); i++){
					
			String standard = standardGrades[i].Standard__c;
			standardWrapper sw = new standardWrapper();
			sw.subject = (standardGrades[i].Standard__r.Strand__r.Subject__c != null) ? standardGrades[i].Standard__r.Strand__r.Subject__c : (standardGrades[i].Standard__r.Subject__c != null) ? standardGrades[i].Standard__r.Subject__c : '';			
			
			sw.Name = standardGrades[i].Standard__r.Name;
			sw.strandName = standardGrades[i].Standard__r.Strand__r.Name;
			sw.Description = standardGrades[i].Standard__r.long_text__c;
			
			for(Time_Element__c rp : orderedReportingPeriods){
				if(i < standardGrades.size()){
					Standard_Grade__c sg = standardGrades[i];
					String sgSubject = (standardGrades[i].Standard__r.Strand__r.Subject__c != null) ? standardGrades[i].Standard__r.Strand__r.Subject__c : (standardGrades[i].Standard__r.Subject__c != null) ? standardGrades[i].Standard__r.Subject__c : '';
					if(sgSubject == sw.subject && sg.Standard__c == standard && sg.Reporting_Period__c == rp.id) {
						if(i > 0){
							Standard_Grade__c lastProcessed = standardGrades[i-1];
							String lpSubject = (standardGrades[i-1].Standard__r.Strand__r.Subject__c != null) ? standardGrades[i-1].Standard__r.Strand__r.Subject__c : (standardGrades[i-1].Standard__r.Subject__c != null) ? standardGrades[i-1].Standard__r.Subject__c : '';
							if(sg.Reporting_Period__c == lastProcessed.Reporting_Period__c && sgSubject == lpSubject && sg.Standard__c == lastProcessed.Standard__c && (sgSubject != null)){
								throw new Gradebook_ReportCard_Utils.DocumentRuntimeException('FATAL:Duplicate standard grades where detected (IDs'+lastProcessed.id+' and '+sg.id+'). Please delete the duplicate.');
							}
						}
						if(sg.Standard_Grade__c == null || (sg.Grade_Overridden__c && sg.Grade_Override__c == null)){
							sw.Grade.add('');
						} else {
							sw.Grade.add(String.valueOf(((sg.Grade_Overridden__c) ? sg.Grade_Override__c : sg.Standard_Grade__c).divide(1,1)));
						}
						i++;
					}
					else{
						sw.Grade.add('');
					}
				} 
				else {
					sw.Grade.add('');
				}
			}
			i--;
			//sorting standards due to conditional subject?
			if(standardSubjectMap.containsKey(sw.subject)){
				standardSubjectMap.get(sw.subject).add(sw);
			}
			else{
				standardSubjectMap.put(sw.subject, new List<StandardWrapper>{sw});
			}
		}	
	
		List<String> subjects = new List<String>(standardSubjectMap.keySet());
		subjects.sort();
		for(String subject:subjects){
			subjectWrappers.add(new subjectWrapper(standardSubjectMap.get(subject)));   
		}

	}
	
	public class subjectWrapper{
		public  List<standardWrapper> standards	{get;set;} //can be strands too
		public  String subject					{get;set;}
		
		public subjectWrapper(List<standardWrapper> standards){
			this.standards = standards;
			this.subject = this.standards[0].subject;
		}
	}
	
	public class standardWrapper{
		public  List<String> grade	{get; set;}
		public  String description	{get; set;}
		public  String strandName	{get; set;}
		public  String Name			{get; set;}
		public  String cssClass		{get; set;}		
		public  String subject 		{get; set;}
		
		public standardWrapper(){
			grade = new List<String>();
		}
	}
}