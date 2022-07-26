global  class Gradebook_CurrentCourseGradeCalculation implements Database.Batchable<sObject>,Database.Stateful {

global Map<String, Grade_Normalization__c> gtransform;
public String query;
public String email;

global Gradebook_CurrentCourseGradeCalculation () {
gtransform = new Map<String, Grade_Normalization__c> ();
for (Grade_Normalization__c gn: [Select Name, GP_Value__c, Transformed_Grade__c from Grade_Normalization__c where GP_Value__c != NULL]) {
gtransform.put(gn.Name, gn);
}

}


global database.querylocator start(Database.BatchableContext BC){
return Database.getQueryLocator(query);
}

global void execute(Database.BatchableContext BC, List<sObject> scope){
//Assumes one student per execution
for(sObject s : scope) {
    Student__c std = (Student__c ) s;
    List<Final_Grade__c> finalgrades = new List<Final_Grade__c> () ;

//Final Grade selects all grades for the student and groups by course and time
  
AggregateResult[] groupedResults = 
                [
                SELECT Course__c c,
                sum(Assignment_Weighting__c) aw, sum(Weighted_Grade_Value__c) wgv
                FROM Grade__c 
                WHERE Student__c = :std.Id
                AND Standard__c = null
                AND Entered_Grade__c != null AND Entered_Grade__c != 'N/A' AND Entered_Grade__c != 'N' AND Entered_Grade__c != 'I'
                GROUP BY Course__c];
for (AggregateResult ar : groupedResults)  {
/*Each record returned is a unique comination of grade per course for year to date per student
to course weights, and then add that number to course/final grade total
*/
        Double sgrade = (Decimal)ar.get('wgv') / (Decimal)ar.get('aw');
        
                    //Transform final grade to letter and GPA Value
                    Long roundedgrade = sgrade.round();
                    if (roundedgrade>100) {roundedgrade = 100;} //Grade cannot be more than 100 for transform purposes; extra credit or mistake entries when points possible was used was likely the cause of this
                    
                    String lettergrade =  gtransform.get(string.valueof(roundedgrade)).Transformed_Grade__c;
                    
                    
           //write to final grade table                  
                    finalgrades.add (new Final_Grade__c (
                            Student__c = std.Id, 
                            Course__c = (String)ar.get('c'), 
                            key__c = string.valueof(std.Id) + (String)ar.get('c'), 
                            Current_Grade_Letter_v2__c = lettergrade,
                            Current_Grade_Value__c = sgrade ) );
        }
      //upsert based on key field ( Student + Course ) 
        upsert finalgrades key__c;
}

}// end execute   

global void finish(Database.BatchableContext BC){
} // end finish

}