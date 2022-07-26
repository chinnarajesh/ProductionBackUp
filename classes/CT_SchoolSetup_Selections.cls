public class CT_SchoolSetup_Selections {
	public Setup__c schoolSetup		{get;set;}
	public boolean settingsSaved	{get;set;}
	
	public CT_SchoolSetup_Selections(){
		if(ApexPages.currentPage().getParameters().containsKey('setupId')){
			Id setupId = ApexPages.currentPage().getParameters().get('setupId');
			if(setupId!=null){
				schoolSetup = CT_SetupWizard_Utils.getSetupById(setupId);
				if(CT_SetupWizard_Utils.checkSelections(schoolSetup)){
					CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'School preferences must be saved before moving on to the next step.');
					settingsSaved = false;
				}
				else{
					CT_SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'School selections have been saved.  No action required.');
					settingsSaved = true;
				}
			}
			else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
		else CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_SETUP_MESSAGE);
	}
	
	/*
		Saves the selections that the user has made for Group/Period based and Room Dependence.
		Also saves the progress record indicating that these selections have been completed (School_Selections_Completed__c).
		If there is an error, a Global Error will be created and an error message thrown to the user 
		('There was an error while saving your selections.  Please have your system administrator verify any global errors.').
	*/
	public void saveSetup(){
		try{
			EOY_Progress__c progress = CT_SetupWizard_Utils.getEOYProgressRecord(schoolSetup);
			update schoolSetup;
			progress.School_Selections_Completed__c=true;
			settingsSaved = true;
			upsert progress;
			CT_SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Selections saved successfully!');
		}
		catch(Exception e){
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There was an error while saving your selections.  Please have your system administrator verify any global errors.');
			String links='';
			if(schoolSetup!=null){
				EOY_Progress__c progress = CT_SetupWizard_Utils.getEOYProgressRecord(schoolSetup);
				links = 'Setup,'+schoolSetup.id+';Progress Record,'+progress.id;
			}
			Global_Error__c ge = CT_Error_Handling.handleError(links,'Setup Wizard','Error saving school selections', e);
			insert ge;
		}
	}
	
	/*
		Redirects the user to the previous step of the setup process, terms and reporting periods.
		
		@return the PageReference for the core_TermSetup_v2 page
	*/
	public PageReference prev(){
		return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.TERMS,false,schoolSetup);
	}
	
	/*
		Redirects the user to the next step of the setup process, schedule template configuration.
		
		@return the PageReference for the core_ScheduleTemplate page
	*/
	public PageReference next(){
		if(!CT_SetupWizard_Utils.checkSelections(schoolSetup)) return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.TEMPLATES,true,schoolSetup);
		else{
			CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'School preferences must be saved before moving on to the next step.');
			return null;
		}
	}
}