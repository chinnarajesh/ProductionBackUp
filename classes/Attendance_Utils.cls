public with sharing class Attendance_Utils {
	//attendances key -> value is: studentID -> Attendance
	public static Boolean isAttendanceTaken(List<Student__c> students, Map<ID, Attendance__c> attendances) {
		Boolean b = true;
		try {
			if(students.size() != attendances.size() ) {
				b = false;
			}	
		}
		catch(Exception e) {
			throw(e);
		}
		return b;
	}

	public static String setLastModified(String sectionName) {
		Datetime dt = System.now();
		String s = UserInfo.getName() + ' took attendance for ' + sectionName + ' on ' + dt.format('MM/dd/yyyy h:mm a');
		return s;
	}
}