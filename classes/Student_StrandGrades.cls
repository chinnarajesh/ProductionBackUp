public class Student_StrandGrades {
	
	public  ApexPages.StandardController controller {get; set;}
	public  List<subjectWrapper> subjectWrappers {get; set;}
	public  ID studentID {get; set;}
	public  Student__c currentStudent {get; set;}
	public  List<Time_Element__c> orderedReportingPeriods {get; set;}
	
	private  List<Strand_Grade__c> strandGrades = new List<Strand_Grade__c>();
	
	public Student_StrandGrades(ApexPages.StandardController controller){
		
		//initialize
		subjectWrappers = new List<subjectWrapper>();
		orderedReportingPeriods = new List<Time_Element__c>();
		
		if (System.currentPageReference().getParameters().containsKey('id')!=null) {
			studentID = System.currentPageReference().getParameters().get('id');
			currentStudent = core_SoqlUtils.getStudentById(studentID)[0];
			getStrandGrades();			
		}
	}

	private void getStrandGrades() {
		//we only care about getting the standard grades for the student.
		//we need rp order? requires section-reporting-periods, standard/strand grades
		//are not section tied, so cannot really rely on srp.
		
		//first get all the standard grades.  Figure out what is the latest rp.  Then build off of it
		//reason is because of the possibility that there could be a standard grade on a final rp.
		
		//unfortunately need to loop twice through strandGrades, to find the F-RP Filters.			
		strandGrades = [SELECT ID, Grade_Overridden__c, Grade_Override__c, Strand__r.Standard_Subject__c, 
				Strand__r.Standard_Subject__r.Name, Reporting_Period__c, Grade__c, Strand__r.Subject__c, 
				Strand__r.Description_Spanish__c, Reporting_Period__r.Name__c, Name, Strand__r.Name, 
				Strand__r.Long_Text__c, Strand__c,Reporting_Period__r.Reporting_Period__c
				FROM Strand_Grade__c 
				WHERE student__c = :studentId
				AND Reporting_Period__c != null
				ORDER BY Strand__r.Subject__c, Strand__r.Name, Reporting_Period__r.End_Date__c, Reporting_Period__r.Reporting_Period__c DESC, Name ASC];
		
		//so much work for a filter...
		Set<ID> includeRP = new Set<ID>();
		for(Strand_Grade__c sg : strandGrades) {
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
		
		List<standardWrapper> strands = new List<standardWrapper>();
		for(Integer i=0; i < strandGrades.size(); i++){				
			String strand = strandGrades[i].Strand__c;
			standardWrapper sw = new standardWrapper();
			sw.subject = strandGrades[i].Strand__r.Subject__c;
			sw.Name = strandGrades[i].Strand__r.Name;
			sw.Description = strandGrades[i].Strand__r.long_text__c;
			
			for(Time_Element__c rp : orderedReportingPeriods){
				if(i < strandGrades.size()){
					Strand_Grade__c sg = strandGrades[i];
					if(sg.Strand__r.Subject__c == sw.subject && sg.Strand__c == strand && sg.Reporting_Period__c == rp.id) {
						if(i > 0){
							Strand_Grade__c lastProcessed = strandGrades[i-1];
						}
						if(sg.Grade__c == null || (sg.Grade_Overridden__c && sg.Grade_Override__c == null)){
							sw.Grade.add('');
						} else {
							sw.Grade.add(String.valueOf(((sg.Grade_Overridden__c) ? sg.Grade_Override__c : sg.Grade__c).divide(1,1)));
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
			strands.add(sw);
			if(i>=strandGrades.size()-1 || sw.subject != strandGrades[i+1].Strand__r.Subject__c){
				subjectWrappers.add(new subjectWrapper(strands));
				strands = new List<standardWrapper>();
			}
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