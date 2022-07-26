global class sched_AttendanceTardyAlert  implements Schedulable{
	global boolean bUnexcused = false;
	global void execute(SchedulableContext sc) {
		Attendance_PGNotification pgn1 = new Attendance_PGNotification  ('Tardy Alerts');
		date d = system.today();
		pgn1.query = core_SoqlUtils.getMainTardyQuery(d, bUnexcused);
		ID batchprocessid = Database.executeBatch(pgn1,1);
	}
}