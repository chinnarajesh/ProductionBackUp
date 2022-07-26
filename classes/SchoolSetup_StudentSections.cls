public with sharing class SchoolSetup_StudentSections {
	public Id setupId		{get;set;}
	public core_LoadCsvData csvLoader	{get;set;}
	
	public SchoolSetup_StudentSections(){
		if(System.currentPageReference().getParameters().containsKey('setupid')){
			setupId = System.currentPageReference().getParameters().get('setupid');
			if(setupId!=null){
				csvLoader = new core_LoadCsvData();
				csvLoader.selectedLoadType = 'Student/Section';
				csvLoader.changeLink();
				csvLoader.bNeedsType=false;
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
	}
	
	public PageReference prev(){
		return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.SCHEDULE,false,SetupWizard_Utils.getSetupById(setupId));
	}
	
	public PageReference next(){
		return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.PUBLISH,true,SetupWizard_Utils.getSetupById(setupId));
	}

}