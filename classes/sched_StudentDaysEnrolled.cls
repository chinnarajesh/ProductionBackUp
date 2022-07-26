global class sched_StudentDaysEnrolled implements Schedulable{
	global void execute(SchedulableContext sc){
		BatchStudentDaysEnrolled bsde = new BatchStudentDaysEnrolled();
		ID batchprocessid = Database.executeBatch(bsde,1);
	}
}