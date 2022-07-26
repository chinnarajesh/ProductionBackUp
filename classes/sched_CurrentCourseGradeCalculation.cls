global class sched_CurrentCourseGradeCalculation implements Schedulable{
	global void execute(SchedulableContext sc) {
		Gradebook_Final_GPA_Batch fg = new Gradebook_Final_GPA_Batch();
		fg.query = 'Select Id, Setup__r.Term__c, Setup__c from Student__c where Active__c =true';
		ID batchprocessid = Database.executeBatch(fg,1);
	}
}