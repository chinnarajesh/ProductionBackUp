public with sharing class CT_SetupWizard_Home {
	public boolean orgWideComplete	{get;set;}
	public boolean needSchools		{get;set;}
	public boolean needYears		{get;set;}
	
	public List<SelectOption> schools	{get;set;}
	public String selectedSchool		{get;set;}
	
	public List<SelectOption> years		{get;set;}
	public String selectedYear			{get;set;}
	
	public CT_SetupWizard_Home(){
		init();
	}
	
	public void init(){
		needSchools = false;
		needYears = false;
		orgWideComplete = false;
		schools = new List<SelectOption>();
		years = new List<SelectOption>();
		
		List<Account> schoolList = CT_SetupWizard_Utils.querySchools();
		List<Time_Element__c> yearsList = CT_SetupWizard_Utils.queryYears();
		if(schoolList.size()==0){
			//need to do schools for org-wide
			needSchools = true;
		}
		else if(yearsList.size()==0){
			//need to do years for org-wide
			needYears = true;
		}
		else{
			//org-wide is complete
			orgWideComplete = true;
		}
		
		if(orgWideComplete){
			//org-wide is done and time to do school setups
			for(Account a: schoolList){
				schools.add(new SelectOption(a.id,a.Name));
			}
			for(Time_Element__c te: yearsList){
				years.add(new SelectOption(te.id,te.Name__c));
			}
		}
	}
	
	public PageReference goToSchoolSetup(){
		boolean bError = false;
		if(selectedSchool==null || selectedSchool==''){
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Please select a school to set up.');
			bError = true;
		}
		if(selectedYear==null || selectedYear==''){
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'Please select a year for which the setup will be valid.');
			bError = true;
		}
		if(!bError){
			return CT_SetupWizard_Utils.getSchoolSetup(selectedSchool, selectedYear);
		}
		else{
			return null;
		}
	}
}