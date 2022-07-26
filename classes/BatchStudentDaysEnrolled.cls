global class BatchStudentDaysEnrolled implements Database.Batchable<sObject> {
	private final  Map <Id, List <Schedule_Day__c>> scheduleDayMap {get;set;}
	private final 	Map <Id, Date> scheduleStartMap {get;set;}
	public  Set <Id> setupIds {get;set;}

	global BatchStudentDaysEnrolled(){
		scheduleDayMap = new Map <Id, List<Schedule_Day__c>>();
		scheduleStartMap = new Map <Id, Date>();
		for (Schedule_Day__c sd:
				[SELECT s.schedule_template__r.reporting_period__c, s.schedule_template__r.setup__c, s.Day__c
				FROM Schedule_Day__c s 
				WHERE s.Schedule_Template__r.Setup__r.Active__c = true 
				AND s.Schedule_Template__r.Has_Class__c = true 
				ORDER BY s.Day__c]){
			if (scheduleDayMap.get(sd.schedule_template__r.setup__c)==null){
				scheduleDayMap.put(sd.schedule_template__r.setup__c, new List <Schedule_Day__c>{sd});
				scheduleStartMap.put(sd.schedule_template__r.setup__c, sd.day__c);
			} else {
				scheduleDayMap.get(sd.schedule_template__r.setup__c).add(sd);
			}
		}
	}


	global Database.QueryLocator start(Database.BatchableContext BC) {
		for (Id setupId: scheduleDayMap.keySet()){
			populateDaysElapsed(scheduleDayMap.get(setupId));
		}
		setupIds = scheduleDayMap.keySet();
		String query = 'SELECT entry_date__c, exit_date__c, exit_reason__c, active__c, Setup__c from Student__c where setup__c in :setupIds';

		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Student__c> studentList){
		List <Enrollment_Tracking__c> etList = new List <Enrollment_Tracking__c>();
		Set <Id> studentIds								= new Set <Id>();
		List <Student_Section__c>			ssList = new List <Student_Section__c>();
		Map <Id, List <Enrollment_Tracking__c>> etMap;
		for (Student__c student : studentList) {
			etList.add(CT_Student_Utils.processEnrollmentRecords(student, scheduleStartMap.get(student.setup__c)));
			studentIds.add(student.id);
		}

		for (Student_Section__c ss:
				[SELECT id, Student_Section__c.Student__r.entry_date__c, section__r.reporting_period__r.date_start_date__c, 
					enrollment_start_date__c, enrollment_end_date__c, active__c, Section_Exit_Reason__c, Student_Entry_Date__c
				FROM Student_Section__c
				WHERE student__c in :studentIds
				AND 	Section__r.Active__c=true
				AND	Section__r.RecordType.Name = 'Published'])	{
			etList.add(Student_Section_Utils.processEnrollmentRecords_StudentSection(ss, ss.section__r.reporting_period__r.date_start_date__c));
		}

		upsert etList reference_id__c;

		etMap = CT_Student_Utils.getStudentEnrollmentMap(studentIds); //Gets the Enrollment Tracking Data for Students

		for (Student__c student: studentList){
			populateDaysEnrolled(scheduleDayMap.get(student.setup__c), student, System.today(), etMap.get(student.id));
		}

		update studentList;
	}

	global void populateDaysEnrolled(List<Schedule_Day__c> scheduleDayList, Student__c student, Date someDate, List <Enrollment_Tracking__c> etList) {
		Integer counter = 0;
		if (student.entry_date__c==null) student.entry_date__c = scheduleStartMap.get(student.setup__c);
		for (Schedule_Day__c scheduleDay : scheduleDayList) {
			if (scheduleDay.Day__c >= student.Entry_Date__c && scheduleDay.Day__c <= someDate) {
				if (etList==null)	counter++;
				else if (CT_Student_Utils.checkEnrollmentTracking(etList, scheduleDay.Day__c)) counter++;
			}
		}

		student.Days_Enrolled__c = counter;
	}

	global void populateDaysElapsed(List<Schedule_Day__c> scheduleDayList){
		for (Integer i = 0; i < scheduleDayList.size(); i++) {
			scheduleDayList[i].Days_Elapsed__c = (i + 1);
		}
		upsert scheduleDayList;
	}

	global void finish(Database.BatchableContext BC){}
}