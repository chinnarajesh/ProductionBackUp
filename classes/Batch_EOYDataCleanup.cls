global with sharing class Batch_EOYDataCleanup implements Database.Batchable<SObject>, Database.Stateful{
	public Integer mode {get; set;}
	
	public Batch_EOYDataCleanup() {
		mode = 0;
	}
	
	public Batch_EOYDataCleanup(Integer m) {
		mode = m;
	}
	
	global Database.QueryLocator start(Database.BatchableContext ctx){
		try{
			String query = setQuery();
			return Database.getQueryLocator(query);
		} catch(Exception e){
			insert Error_Handling.handleError('','Batch_EOYDataCleanup','Failure starting batch for mode '+mode,e);
		}
		return Database.getQueryLocator('');
	}
	
	global void execute(Database.BatchableContext ctx, List<SObject> scope){
		List<Database.deleteResult> results = database.delete(scope,false);
	}
	
	global void finish(Database.BatchableContext ctx) {
		mode++;
		if(getObjectString(mode) != null){
			try{
				Batch_EOYDataCleanup newBatch = new Batch_EOYDataCleanup(mode);
				Database.executeBatch(newBatch);
			} catch(Exception e){
				insert Error_Handling.handleError('','Batch_EOYDataCleanup','Failure initalizing batch for mode '+mode,e);
			}
		}
	}
	
	private String setQuery() {
		String returnQuery = 'SELECT ID FROM ' + String.escapeSingleQuotes(getObjectString(mode));
		if(mode == 1) { //Data_Load_Log__c
			returnQuery += ' WHERE Class_Name__c = \'Batch_SchoolProcessData\' OR';
			returnQuery += ' Class_Name__c = \'Batch_SchoolPurgeEOYData\' OR';
			returnQuery += ' Class_Name__c = \'Batch_SchoolPurgeHistoricalData\' OR';
			returnQuery += ' Class_Name__c = \'Batch_SchoolSnapshotAttendanceCalc\' OR';
			returnQuery += ' Class_Name__c = \'BatchSnapshot\' OR';
			returnQuery += ' Class_Name__c = \'Batch_CohortSnapshot\' OR';
			returnQuery += ' Class_Name__c = \'Batch_CreateStudents\' ';
		}
		return returnQuery;
	}

	private String getObjectString(Integer i) {
		if(i == 0) return 'Global_Error__c';
		else if(i == 1) return 'Data_Load_Log__c';
		else if(i == 2) return 'HoldingObj__c';
		else if(i == 3) return 'Document_Log__c';
		else {
			return null;
		}
	}
}