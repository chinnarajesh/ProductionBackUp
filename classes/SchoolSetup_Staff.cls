public with sharing class SchoolSetup_Staff {
	public Id setupId					{get;set;}
	public String schoolName			{get;set;}
	public Setup__c setup				{get;set;}
	public boolean bProcessing			{get;set;}
	public boolean isManaged			{get;set;}
	public BatchWrapper batch			{get;set;}
	public List<Data_Load_Log__c> logs	{get;set;}
	
	public SchoolSetup_Staff(){
		bProcessing = true;
		isManaged = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
		if(System.currentPageReference().getParameters().containsKey('setupid')){
			setupId = System.currentPageReference().getParameters().get('setupid');
			if(setupId!=null){
				if(System.currentPageReference().getParameters().get('failed') != null){
					Error_Handling.errorMessage('One or more records has failed to publish. Review the holding object for the errors. See SchoolForce Help for information about troubleshooting failures.');
				}
				setup = SetupWizard_Utils.getSetupById(setupId);
				schoolName = setup.School__r.Name;
				loadLogs();
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_SETUP_MESSAGE);
	}

	public void loadLogs(){
		logs = [SELECT id, OwnerId, LastModifiedDate, End_Time_Text__c, Type__c, Status__c, Failed_Records__c, Messages__c, Total_Records__c, Reporting_Period__c 
				FROM Data_Load_Log__c
				WHERE Setup__c = :setupId
				AND Class_Name__c ='CT_Scheduler_HoldingProcessor'
				and Type__c != 'Session'
				ORDER BY End_Time__c DESC];
	}

	public void publishData(){
		try{
			bProcessing = true;
			CT_Scheduler_HoldingProcessor shp = new CT_Scheduler_HoldingProcessor();
			shp.continueBatch = true;
			shp.cSetup = core_SoqlUtils.getSetupById(setupId);//new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'publish');
			shp.mode = 'Staff';
			Id batchId = database.executeBatch(shp);
			batch = new BatchWrapper(batchId,setupId);
			continueBatch();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId, 'Core (Publish)', 'error during staff propagation', e);
			insert ge;
		}	 	
	}
	
	public PageReference continueBatch(){
		try{
			boolean failed = batch.continueBatch();
			loadLogs();
			if(failed!=null){
				//bit of hard coding, but it overcomes the publisher not correctly reporting it's failure state.
				if(logs.size()>=2){
					if((logs[0].Failed_Records__c != null && logs[0].Failed_Records__c >0) ||
						(logs[1].Failed_Records__c != null && logs[1].Failed_Records__c >0)){
						failed = true;
					}
				}
				
				return SetupWizard_Utils.refreshPage(setupId,failed);
			}
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while checking the status of the batch.'));
			Global_Error__c ge = Error_Handling.handleError('Setup, '+setupId+'; Batch, '+batch.batchId, 'Core (Publish)', 'batch check failed', e);
			insert ge;
		}
		return null;
	}

	public PageReference prev(){
		Integer location = SetupWizard_Utils.calculateStepLocation(setupId);
		if(location >= SetupWizard_Utils.STAFF)
			return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.ROOMS,false,SetupWizard_Utils.getSetupById(setupId));
		else {
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_FORWARD_MESSAGE);
			return null;
		}
	}
	
	public PageReference next(){
		Integer location = SetupWizard_Utils.calculateStepLocation(setupId);
		if(location >= SetupWizard_Utils.STAFF)
			return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.GROUP_CONFIG,true,SetupWizard_Utils.getSetupById(setupId));
		else {
			SetupWizard_Utils.addMessage(apexpages.severity.ERROR,SetupWizard_Utils.NO_FORWARD_MESSAGE);
			return null;
		}
	}
}