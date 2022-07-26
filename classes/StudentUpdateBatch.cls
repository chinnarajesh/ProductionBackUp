public class StudentUpdateBatch implements Database.Batchable<sObject>{
    public final String Query;

    public StudentUpdateBatch(){
        Query = 'SELECT Id FROM Student__c WHERE External_Evaluation_ID__c = \'\'';
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        update scope;
    }

    public void finish(Database.BatchableContext BC){

    }

}