/*
	@author Elizabeth Ellis <eellis@acumensolutions.com>
	@since	2013-04-10
*/
public class BatchWrapper {
	public ID batchId				{get;set;}
	public ID rpId					{get;set;}
	public ID setupId				{get;set;}
	public boolean needsStudents	{get;set;}
	public String status			{get;set;}
	public integer processed		{get;set;}
	public integer totalItems		{get;set;}
	
	public BatchWrapper(ID batchId, ID setupId){
		this.batchId = batchId;
		this.setupId = setupId;
	}
	
	/*
		Continue processing an already running batch
	*/
	public boolean continueBatch(){
		system.debug('~~~~~ batchId '+batchId);
		AsyncApexJob batch = [SELECT ID, ApexClassId, Status, TotalJobItems, JobItemsProcessed, CompletedDate FROM AsyncApexJob WHERE id=:batchId];
		status = batch.Status;
		processed = batch.JobItemsProcessed;
		totalItems = batch.TotalJobItems;
		if(status=='Completed'){
			String className = [SELECT Name FROM ApexClass WHERE id=:batch.ApexClassId].Name;
			List<Data_Load_Log__c> dll = [SELECT id, Batch_ID__c, Start_Time__c FROM Data_Load_Log__c WHERE Batch_ID__c=:batch.Id];
			if(className=='Scheduler_HoldingProcessor'){
				checkForLogs('Scheduler_HoldingProcessor',true,dll[0].Start_Time__c);
			}
			else if(className=='Batch_ProcessEOYData'){
				if(needsStudents){
					checkForLogs('Batch_ProcessEOYData',false,dll[0].Start_Time__c);
				}
				else{
					return false;
				}
			}		
			else{
				return false;
			}	
		}
		else if(status=='Failed'){
			return true;
		}
		return null;
	}
	
	/*
		Check for the logs for subsequent batch runs if the completed batch is part of a synchronous batch process.
		These include publishing batches, data activation batches, and some EOY batches.
		
		@param className the name of the next apex class that is supposed to run
		@param useRPs determines whether the logs should be filtered on reporting period
		@param prevBatchEndTime the time when the last batch finished running.  The start time on the next batch should be later than this.
	*/
	public void checkForLogs(String className,boolean useRPs,DateTime prevBatchStartTime){
		List<Data_Load_Log__c> dll;
		if(useRPs)
			dll = [SELECT id, Batch_ID__c FROM Data_Load_Log__c WHERE Setup__c=:setupId AND Reporting_Period__c=:rpId AND Class_Name__c=:className AND Start_Time__c >= :prevBatchStartTime AND Batch_ID__c!=:batchId ORDER BY CreatedDate DESC];
		else
			dll = [SELECT id, Batch_ID__c FROM Data_Load_Log__c WHERE Setup__c=:setupId AND Class_Name__c=:className AND Start_Time__c >= :prevBatchStartTime AND Batch_ID__c!=:batchId ORDER BY CreatedDate DESC];
		system.debug('~~~~~ dll: '+dll);
		if(dll.size()==0){
			setupWaitingMessage();
		}
		else if(dll[0].Batch_ID__c!=null){
			batchId = dll[0].Batch_ID__c;
			needsStudents = false;
			continueBatch();
		}
	}
	
	/*
		Set up the user message if the next batch isn't found.
	*/
	public void setupWaitingMessage(){
		status = 'Waiting for next batch';
		processed = 0;
		totalItems = 0;
	}
}