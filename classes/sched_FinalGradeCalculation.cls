global class sched_FinalGradeCalculation implements Schedulable{
		global void execute(SchedulableContext sc) {
			Gradebook_FinalGradeCalculation_SGTable	  fg = new Gradebook_FinalGradeCalculation_SGTable();
			fg.query = 'Select Id from Student__c';
			ID batchprocessid = Database.executeBatch(fg,1);
		}
}