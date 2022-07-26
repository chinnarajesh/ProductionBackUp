global class Gradebook_Semester_Midterm_Batch implements Database.Batchable<SObject> {
	public String query;
	global Database.queryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}
	
	
	global void execute(Database.BatchableContext BC, List<SObject> scope) {
		for(sObject s : scope) {
			Student__c student = (Student__c)s;
			Gradebook_Semester_Midterm_Controller calculate = new Gradebook_Semester_Midterm_Controller();
			//Summer 2014 iteration 2: new parameter, requires list of students
			calculate.calcSemesterMidtermGrades(new List<Student__c> {student});
		}
	}
	
	global void finish(Database.BatchableContext BC) {
		//do nothing
	}

}