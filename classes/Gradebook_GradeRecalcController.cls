public with sharing class Gradebook_GradeRecalcController {
	public List<SelectOption> schoolSelect					{get;set;}
	public List<SelectOption> sectionSelect					{get;set;}
	public List<SelectOption> timeSelect					{get;set;}
	public String schoolID									{get;set;}
	public String sectionID									{get;set;}
	public String timeID									{get;set;}
	public String email										{get;set;}
	public Map <Id, List<SelectOption>> sectionMap;
	public Map <Id, List<SelectOption>> timeMap;
	public Set<ID> timeSet;
	public Set<ID> schoolIDSet;
	public Map<String,String> schoolTermMap;

	public Gradebook_GradeRecalcController(){
		sectionMap = new Map<Id,List<SelectOption>>();
		timeMap = new Map<Id,List<SelectOption>>();
		sectionSelect = new List<SelectOption>();
		timeSelect = new List<SelectOption>();
		schoolSelect = new List<SelectOption>();
		timeSet = new Set<ID>();
		schoolIDSet = new Set<ID>();
		schoolTermMap = new  Map<String,String>();
		User tempuser = [select Email from User where Id = :system.Userinfo.getUserId()];
		email = tempuser.Email;
		
		integer x=0;
		for(Account sch : [select Id, Name from Account where RecordType.Name = 'School' OR RecordType.Name='Summer School' order by Name asc]){
			schoolSelect.add(new SelectOption(sch.Id, sch.Name));
			schoolIDSet.add(sch.Id);
			if(x==0){
				schoolID = sch.Id;
			}
			x++;
		}
		
		for(Setup__c s:[select Id, Term__c, Active__c, School__c from Setup__c where Active__c = true AND School__c IN :schoolIDSet]){
			for(Time_Element__c t:core_SoqlUtils.getTimeElementsByTermGB(s.Term__c)){
				if(timeMap.containskey(s.Term__c)){
					timeMap.get(s.Term__c).add(new SelectOption(t.Id, t.Name__c));
				}
				else{
					timeMap.put(s.Term__c, new List<SelectOption>{new SelectOption('All','All'), new SelectOption(t.Id, t.Name__c)});
				}
			}
			schoolTermMap.put(s.School__c, s.Term__c);
		}
		
		for(Section__c s:[select Id, Name, School__c from Section__c where (School__r.RecordType.Name  = 'School' OR School__r.RecordType.Name='Summer School') and RecordType.DeveloperName='Published']){
			if(sectionMap.containskey(s.School__c)){
				sectionMap.get(s.School__c).add(new SelectOption(s.Id, s.Name));
			}
			else{
				sectionMap.put(s.School__c,new List<SelectOption>{new SelectOption('All','All'), new SelectOption(s.Id, s.Name)});
			}
		}
		
		reloadFilters();
	}
	
	public void reloadFilters(){
		
		if(sectionMap.containskey(schoolID)){
			sectionSelect = sectionMap.get(schoolID);
		} else {
			sectionSelect = new List<SelectOption>{new SelectOption('All','All')};
		}
		
		if(timeMap.containskey(schoolTermMap.get(schoolID))){
			timeSelect = timeMap.get(schoolTermMap.get(schoolID));
		}
		else{
			timeSelect = new List<SelectOption>{new SelectOption('All','All')};
		}
	}
	
	public void recalcGrades(){
		String query = 'select Id, Name, Grade_Update__c from Grade__c where Student__r.School__c = \''+schoolID+'\'';
		
		if(timeID!='All'){
			query += ' AND Time__c = \''+timeID+'\'';
		}
		
		if(sectionID!='All'){
			query += ' AND Student_Section__r.Section__c = \''+sectionID+'\'';
		}
		
		Batch_GradeRecalc bg = new Batch_GradeRecalc();
		bg.query = query;
		ID batchprocessid = Database.executeBatch(bg);
		Apexpages.addMessage(new apexpages.message(apexpages.severity.info,'An email with the results of the recalculation will be sent to '+email));
	}
	
	static testMethod void testGbRecalc(){
		testDataSetupUtil_v2.setUPCoreData(5);
		testDataSetupUtil_v2.setupStaffData(5);
		testDataSetupUtil_v2.setupStudentData(5);
		test.startTest();
			system.runAs(testDataSetupUtil_v2.staffUsersList[1]){
				Gradebook_GradeRecalcController g = new Gradebook_GradeRecalcController();
				g.recalcGrades();
			}
		test.stopTest();
	}
}