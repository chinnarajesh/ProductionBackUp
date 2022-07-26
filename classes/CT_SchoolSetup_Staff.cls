public with sharing class CT_SchoolSetup_Staff {
	public static final Integer MAXLOGS = 7;
	public Id setupId					{get;set;}
	public String schoolName			{get;set;}
	public Setup__c setup				{get;set;}
	public boolean bProcessing			{get;set;}
	public boolean isManaged			{get;set;}
	public CT_BatchWrapper batch		{get;set;}
	public List<Data_Load_Log__c> logs	{get;set;}
	public DateTime startBatchDate		{get;set;}

	public CT_SchoolSetup_Staff(){
		bProcessing = true;
		startBatchDate = Datetime.now();
		isManaged = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
		setupId = System.currentPageReference().getParameters().get('setupid');
		if(setupId==null){
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_SETUP_MESSAGE); return;	
		}
		if(System.currentPageReference().getParameters().get('failed') != null){
			CT_Error_Handling.errorMessage('One or more records has failed to publish. Review the holding object for the errors. See SchoolForce Help for information about troubleshooting failures.');
		}
		setup = CT_SetupWizard_Utils.getSetupById(setupId);
		schoolName = setup.School__r.Name;
		loadLogs(true);
	}

	public void loadLogs(Boolean AllLogs){
		String query = 'SELECT Id, OwnerId, LastModifiedDate, End_Time_Text__c, Type__c, Status__c, Failed_Records__c, Messages__c, Total_Records__c, Reporting_Period__c ';
		query += ' FROM Data_Load_Log__c';
		query += ' WHERE Setup__c = :setupId';
		query += ' AND Class_Name__c =\'CT_Scheduler_HoldingProcessor\'';
		query += ' AND Type__c != \'Session\'';
		query += AllLogs==true? '': ' AND Start_Time__c > :startBatchDate';
		query += ' ORDER BY End_Time__c DESC';
		query += AllLogs==true? '': ' LIMIT :MAXLOGS';
		logs = (List<Data_Load_Log__c>)Database.query(query);
	}

	public void publishData(){
		if(String.isBlank(setupId)){return;}
		try{
			startBatchDate = Datetime.now();
			bProcessing = true;
			CT_Scheduler_HoldingProcessor shp = new CT_Scheduler_HoldingProcessor();
			System.debug('Running holding processor');
			shp.continueBatch = true;
			shp.cSetup = CT_core_SoqlUtils.getSetupById(setupId);//new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'publish');
			shp.mode = 'Staff';
			Id batchId = database.executeBatch(shp);
			batch = new CT_BatchWrapper(batchId,setupId);
			continueBatch();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'A processing error has occurred.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId, 'Core (Publish)', 'error during staff propagation', e);
			insert ge;
		}	 	
	}
	
	public PageReference continueBatch(){
		if(String.isBlank(setupId)){return CT_SetupWizard_Utils.refreshPage(setupId,true);}
		List<String> lstMsgs = new List<String>();
		Boolean failed = false;		
		try{
			Boolean failedBatch = batch.continueBatch();
			loadLogs(false);
			if(logs!=null){
				for(Data_Load_Log__c log: logs){
					lstMsgs.addAll(String.isNotBlank(log.Messages__c)? log.Messages__c.split(';'): new List<String>());
					failed = failedBatch==true || log.Failed_Records__c>0;
				}
				if(failed==true || !lstMsgs.isEmpty()){
					CT_Error_Handling.errorMessage('One or more records has failed to publish. Review the holding object for the errors. See SchoolForce Help for information about troubleshooting failures.');
					for(String msg: lstMsgs){
						ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, msg));
					}
				}
				if(failedBatch!=null){//stop display info about the running batch
					bProcessing = false;
				}
			}
			//	return CT_SetupWizard_Utils.refreshPage(setupId,failed);
		}
		catch(Exception e){
			bProcessing = false;
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error while checking the status of the batch.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Batch, '+batch.batchId, 'Core (Publish)', 'batch check failed', e);
			insert ge;
		}
		return null;
	}

	public PageReference prev(){
//		Integer location = CT_SetupWizard_Utils.calculateStepLocation(setupId);
//		if(location >= CT_SetupWizard_Utils.STAFF)
			return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.TEMPLATES,false,CT_SetupWizard_Utils.getSetupById(setupId));
//		else {
//			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_FORWARD_MESSAGE);
//			return null;
//		}
	}
	
	public PageReference next(){
//		Integer location = CT_SetupWizard_Utils.calculateStepLocation(setupId);
//		if(location >= CT_SetupWizard_Utils.STAFF)
			return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.SCHEDULE,true,CT_SetupWizard_Utils.getSetupById(setupId));
//		else {
//			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,CT_SetupWizard_Utils.NO_FORWARD_MESSAGE);
//			return null;
//		}
	}
}