public class StudentInfoWrapper{
	public Student__c student							{get;set;}
	public Student_Section__c studentSection			{get;set;}
	public String name									{get;set;}
	public Boolean selected								{get;set;}
	public Date	dtIA									{get;set;}
	public String indicatorAreaDisplay					{get;set;}
	public String programsIADisplay						{get;set;}
	public List<Indicator_Area_Student__c> indicators 	{get;set;}
	public Map<Id, Indicator_Area_Student__c> areaIDs 	{get;set;}

	public StudentInfoWrapper(Student_Section__c studentSection){
		this.student = studentSection.Student__r == null? new Student__c(): studentSection.Student__r;
		this.studentSection = studentSection;
		this.selected = false;
	}

	public StudentInfoWrapper(Student__c student, Student_Section__c studentSection, Boolean selected){
		this.student = student;
		this.studentSection = studentSection;
		this.selected = selected;
		this.name = student.Student_First_Name__c+' '+student.Student_Last_Name__c;
	}

	public StudentInfoWrapper(Student__c student, Student_Section__c studentSection, List<Indicator_Area_Student__c> indicators){
		this.student = student;
		this.studentSection = studentSection;
		this.selected = false;
		updateStudentInfoWrapper(student, indicators);
	}

	public StudentInfoWrapper(Student__c student, List<Indicator_Area_Student__c> indicators){
		updateStudentInfoWrapper(student, indicators);
	}

	public void updateStudentInfoWrapper(Student__c student, List<Indicator_Area_Student__c> indicators){
		this.student = student;
		this.indicators = indicators;
		this.name = student.Student_First_Name__c+' '+student.Student_Last_Name__c;
		areaIDs = new Map<Id, Indicator_Area_Student__c>();
		for(Indicator_Area_Student__c ia_s : indicators){
			areaIDs.put(ia_s.Indicator_Area__r.id, ia_s);
			//dtIA = (dtIA==null || ia_s.IA_Effective_Date__c > dtIA)? ia_s.IA_Effective_Date__c: dtIA; //show last date
		}
		refreshIndicatorAreaDisplay();
		refreshProgramsIADisplay();
	}

	public void addArea(Indicator_Area_Student__c ia){
		Integer i;
		for(i = 0; i < indicators.size(); ++i ){
			if(indicators.get(i).Indicator_Area__r.name.compareTo(ia.Indicator_Area__r.name)>0){
				break;
			}
		}
		if(i == indicators.size()){
			indicators.add(ia);
		}else{
			indicators.add(i, ia);
		}
		areaIDs.put(ia.Indicator_Area__r.id, ia);
		this.refreshIndicatorAreaDisplay();
	}

	public void refreshIndicatorAreaDisplay(){
		List<String> iaNames = new List<String>();
		Integer iaAmt = indicators.size();
		for(Integer i = 0; i < iaAmt; ++i){
			if(indicators.get(i).Active__c){
				iaNames.add(indicators.get(i).Indicator_Area__r.Name);
			}
		}
		iaNames.sort();
		indicatorAreaDisplay = String.join(iaNames, ', ');
	}

	public void refreshProgramsIADisplay(){
		Set<String> pIANames = new Set<String>();
		for(Student_Section__c ss: student.Student_Section__r){
			if(String.isNotBlank(ss.Section__r.Program__r.Indicator_Area__r.Name)
					&& ss.Section_Exit_Reason__c!='Accidental Enrollment'){
				pIANames.add(ss.Section__r.Program__r.Indicator_Area__r.Name);
			}
		}
		programsIADisplay = String.join(new List<String>(pIANames), ', ');
	}
}