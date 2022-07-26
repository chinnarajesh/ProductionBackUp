global class sched_AttendanceThresholdAlerts implements Schedulable{
  global void execute(SchedulableContext sc) {
    Attendance_ManageStudentAttendance.processnotifications(system.today(), false);
  }
}