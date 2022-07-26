global class CYSectionSharingBatch implements Database.Batchable<SObject> {
	global Iterable<sObject> start(Database.BatchableContext bc)  {
		return Database.query('');
	}
	
	global void execute(Database.BatchableContext bc, List<sObject> batch){
	}
	
	global void finish(Database.BatchableContext bc){
	}
}