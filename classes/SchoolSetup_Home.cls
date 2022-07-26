public class SchoolSetup_Home {
	public Setup__c schoolSetup		{get;set;}
	public EOY_Progress__c progress	{get;set;}
	public Account childAccount		{get;set;}
	public boolean hasSummerSchool	{get;set;}
	public static string GRADEBOOK	{get{return 'gradebook';} set;}
	public static string ATTENDANCE	{get{return 'attendance';} set;}
	public static string BEHAVIOR	{get{return 'behavior';} set;}
	public static string DOCUMENTS	{get{return 'documents';} set;}
	public static final string NO_SETUP_MSG = 'There is no setup selected for this load.  Please return to the SchoolForce Setup Wizard homepage to select a school and year to set up.';
	
	public SchoolSetup_Home(){
		if(ApexPages.currentPage().getParameters().containsKey('setupId')){
			Id setupId = ApexPages.currentPage().getParameters().get('setupId');
			if(setupId!=null){
				schoolSetup = SetupWizard_Utils.getSetupById(setupId);
				progress = SetupWizard_Utils.getEOYProgressRecord(schoolSetup);
				//EE 12/19 adding summer school US3514
				try{
					childAccount = [SELECT id FROM Account WHERE RecordType.Name='Summer School' AND ParentId=:schoolSetup.School__c];
					hasSummerSchool = true;
				} catch (QueryException qe){
					hasSummerSchool = false;
				}

				if(!schoolSetup.Active__c){
					checkForCloningBatch();
				}
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,NO_SETUP_MSG);
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,NO_SETUP_MSG);
	}
	
	public void saveModules(){
		if(!schoolSetup.Using_Gradebook__c) schoolSetup.Using_Student_Documents__c = false;
		update schoolSetup;
	}

	private void checkForCloningBatch(){
		ID cloneClassID = [select id from ApexClass where Name LIKE '%Batch_CloneSetupData' limit 1].ID; //do a like here because it works in both packaged and unpackaged

		List<AsyncApexJob> jobs = [select id from AsyncApexJob where ApexClassID =: cloneClassID and Status != 'Completed' and Status != 'Aborted' and Status != 'Failed'];
		if(!jobs.isEmpty()){
			Error_Handling.infoMessage('There are one or more processes running to copy the data related to a setup for a newly created year. Not all of your records for the new year may be visible at this time.');
		}
	}
	
	public PageReference redirectToWizard(){
		String wizard = ApexPages.currentPage().getParameters().get('wizardName');
		PageReference pr;
		if(wizard==GRADEBOOK) pr = Page.SchoolSetup_Gradebook;
		else if(wizard==ATTENDANCE) pr = Page.SchoolSetup_Attendance;
		else if(wizard==BEHAVIOR) pr = Page.SchoolSetup_Behavior;
		else if(wizard==DOCUMENTS) pr = Page.SchoolSetup_Documents;
		
		if(pr!=null){
			pr.getParameters().put('setupId',schoolSetup.Id);
			pr.setRedirect(true);
		}
		return pr;
	}

	public PageReference redirectToSummerSchool(){
		update schoolSetup;
		return SetupWizard_Utils.getSchoolSetup(childAccount.id, schoolSetup.Year__c);
	}
}