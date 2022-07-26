public with sharing class SchoolSetup_Documents {
	public core_SetupWrapper cSetup	{get;set;}
	public EOY_Progress__c progress	{get;set;}
	private ID setupID;

	public SchoolSetup_Documents() {
		setupID = ApexPages.currentPage().getParameters().get('setupId');
		if(setupID != null){
			cSetup = new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),null);
			progress = SetupWizard_Utils.getEOYProgressRecord(cSetup.setup);
		}
	}

	/*
		Saves the assoicated setup. 
	*/
	public void save(){
		try{
			update cSetup.setup;
			progress.Documents_Wizard_Started__c = true;
			upsert progress; //upsert incase this is the first module they visit.
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Changes saved successfully.');
		} catch(System.DMLException e){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'An error occured while trying to save your changes.');
		}
	}

	/*
		Save the assoicated setup and finalizes the module.
	*/
	public void finalize(){
		if(cSetup.setup.Evaluation_Documents__c == null || cSetup.setup.Evaluation_Documents__c == ''){
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'You must select at least one evaluation document before finalizing this module.');
			return;
		}
		progress.Documents_Wizard_Completed__c = true;
		save();
		if(ApexPages.hasMessages(ApexPages.severity.ERROR)){
			progress.Documents_Wizard_Completed__c = false;
		} else {
			SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,'Your changes have been finalized. You may return here to update settings as needed.');
		}
	}

	/*
		Moves the user to the previous module page
	*/
	public PageReference prev(){
		PageReference p = Page.SchoolSetup_Home;
		p.getParameters().put('setupId',setupID);
		return p;
	}

	@isTest static void test(){
		TestDataSetupUtil_v2.setupCoreData(5);

		PageReference p = Page.SchoolSetup_Documents;
		p.getParameters().put('setupId', TestDataSetupUtil_v2.activeSetup.id);
		Test.setCurrentPage(p);

		Test.startTest();
			SchoolSetup_Documents controller = new SchoolSetup_Documents();
			controller.cSetup.setup.Standard_Legend_4_Spanish__c = 'Something unique';
			controller.save();
			System.assertEquals('Something unique', [select Standard_Legend_4_Spanish__c from Setup__c where ID=:TestDataSetupUtil_v2.activeSetup.id].Standard_Legend_4_Spanish__c);
			controller.finalize();
			controller.prev();
	}
}