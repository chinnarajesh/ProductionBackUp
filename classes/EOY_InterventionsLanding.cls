public with sharing class EOY_InterventionsLanding {
	public Time_Element__c currentYear {get;set;}
	public List<Data_Load_Log__c> logs {get;set;}
	public Boolean deactivationAvailable			{get;set;}
	public boolean batchRunning						{get;set;}

	public EOY_InterventionsLanding(){
		currentYear = CYUtil.getCurrentYear();
		logs = new List<Data_Load_Log__c>();

		if(currentYear == null){
			CYUtil.errorMessage('Unable to locate the current year record. Please check your setup.');
			deactivationAvailable = false;
		} else {
			checkStatus();
		}
	}

	public void startDeactivation(){
		Data_Load_Log__c log = new Data_Load_Log__c(
			Type__c = 'Interventions Data Deactivation',
			Status__c = 'Pending',
			Failed_Records__c = 0,
			Total_Records__c = 0,
			Processed_Records__c = 0,
			Reporting_Period__c = currentYear.id
		);

		try{
			batchRunning = true;
			checkStatus();
			delete logs;
			insert log;

			checkStatus();
			batchRunning = true;
			deactivationAvailable = false;
		} catch(System.DMLException e){
			CYUtil.errorMessage('An unexpected error occured when trying to create a log for the deactivation process.');
			return;
		}

		Batch_DeactivateData batch = new Batch_DeactivateData(log.id);
		Database.executeBatch(batch);
		ApexPages.getMessages().clear();
		CYUtil.infoMessage('The batch has been started.');
	}

	public void checkStatus(){
		logs = [select id, Status__c, Start_Time__c, End_Time__c, Processed_Record_Type__c,
				Total_Records__c, Processed_Records__c, Failed_Records__c, Batch_ID__c
			from Data_Load_Log__c 
			where Type__c = 'Interventions Data Deactivation' 
			and Reporting_Period__c =: currentYear.id
			order by CreatedDate desc];

		if(logs.isEmpty()){
			deactivationAvailable = true;
			return;
		}

		boolean isComplete = true;
		boolean hasHadErrorMessage = false;
		for(Data_Load_Log__c log:logs){
			if(!log.Status__c.contains('Completed')){
				if(log.Status__c.contains('Failed') && !hasHadErrorMessage){
					hasHadErrorMessage = true;
					CYUtil.errorMessage('One or more of the batches below have failed. Please review the messages in the table below for assistance in resolving the failure.');
				}
				if(!log.Status__c.contains('Failed')){
					isComplete = false;
					batchRunning = true;
					CYUtil.infoMessage('The batch is still running.');
				}
			}
		}

		if(batchRunning == null || isComplete){
			batchRunning = false;
		}

		if(isComplete && !hasHadErrorMessage){
			deactivationAvailable = false;
			finalizeBatch();
		} else if(isComplete && hasHadErrorMessage) {
			deactivationAvailable = true;
		}
	}

	public void finalizeBatch(){
		List<EOY_Progress__c> eoyProgress = [select id, Is_Complete__c from EOY_Progress__c where Module_Name__c='Interventions' and Year__c =:currentYear.id limit 1];
		deactivationAvailable = !eoyProgress[0].Is_Complete__c;
		if(eoyProgress[0].Is_Complete__c){
			CYUtil.successMessage('The EOY process for Interventions has been completed for this year.');
		}
	}

	public void checkForEOYProgress(){
		List<EOY_Progress__c> eoyProgress = [select id, Is_Complete__c from EOY_Progress__c where Module_Name__c='Interventions' and Year__c =:currentYear.id limit 1];

		if(eoyProgress.isEmpty()){
			makeNewEOYProgress();
		}
	}

	private void makeNewEOYProgress(){
		List<EOY_Progress__c> sfEOYProgress = 
				[select id from EOY_Progress__c 
				where School__c = null 
				and Year__c =: currentYear.id 
				and (Module_Name__c = 'Schoolforce' OR Module_Name__c = null)];

		EOY_Progress__c progress = new EOY_Progress__c(
			Module_Name__c = 'Interventions',
			Year__c = currentYear.id,
			Parent_Progress__c = (sfEOYProgress.isEmpty())?null:sfEOYProgress[0].id,
			RecordTypeID = CYUtil.getRecordTypeID('EOY')
		);

		try{
			DMLManager.insertAsUser(new EOY_Progress__c[]{progress});
			deactivationAvailable = true;
		} catch(DMLManager.CRUDException e){
			CYUtil.errorMessage('User lacks permission to create new EOY Progress records.');
		} catch(DMLManager.FLSException e){
			CYUtil.errorMessage('User lacks permission to edit required fields on EOY Progress records');
		} catch(System.DMLException e){
			CYUtil.errorMessage('Unable to create EOY tracking records. Please resolve this issue before continuing.');
			deactivationAvailable = false;
		}
	}
}