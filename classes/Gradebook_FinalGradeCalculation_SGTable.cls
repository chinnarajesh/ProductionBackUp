global  class Gradebook_FinalGradeCalculation_SGTable implements Database.Batchable<sObject>,Database.Stateful {



global Map<Id, Course__c> mCourse;
global Map<String, Grade_Normalization__c> gtransform;
public String query;
public String email;

global Gradebook_FinalGradeCalculation_SGTable () {

}


global database.querylocator start(Database.BatchableContext BC){
return Database.getQueryLocator(query);
}

global void execute(Database.BatchableContext BC, List<sObject> scope){
//Assumes one student per execution
for(sObject s : scope) {
}
        
}// end execute   

global void finish(Database.BatchableContext BC){
} // end finish

}