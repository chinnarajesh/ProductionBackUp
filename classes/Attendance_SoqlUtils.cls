global class Attendance_SoqlUtils {
		public static List <Student__c> getStudentByName (String sFirstName, String sLastName){
			String tempFirst = core_SoqlUtils.getSearchName(sFirstName);
			String tempLast = core_SoqlUtils.getSearchName(sLastName);
			List <Student__c> studentList = new List <Student__c>();
			String queryString = 'SELECT ID, Student_First_Name__c, Student_Last_Name__c, Grade__c, Individual__r.MailingStreet FROM Student__c';
			if(sFirstName!=null||sLastName!=null){
				queryString +=' Where active__c = true ';
			}
			if(sFirstName!=null){
				queryString += 'AND Student_First_Name__c LIKE '+'\''+tempFirst+'\'';
			}
			if(sLastName!=null){
				queryString += 'AND Student_Last_Name__c LIKE '+'\''+tempLast+'\'';
			}
			studentList = database.query(queryString);
			return studentList;
		}

	public static List <Session__c> getSessionBySection(String selectedSection, Date startDate, Date endDate){
		List <Session__c> sessionList = new List <Session__c>();
		for (Session__c s: [SELECT s.ID, s.Name, s.Session_Date__c, s.Section__r.Daily_Attendance__c
							FROM Session__c s
							WHERE Record_Attendance__c = true
							AND Section__c = :selectedSection ]){
			if (startDate!=null && endDate !=null){
				if (s.Session_Date__c >= startDate && s.Session_Date__c <= endDate){
					sessionList.add(s);
				}
			}
			else sessionList.add(s);
		}
		return sessionList;
	}

	public static List<Student_Section__c> getStudentSectionListByStudent (String selectedStudentID, boolean bAttendance){
		List <Student_Section__c> studSectionList = new List <Student_Section__c>();
		for (Student_Section__c ss: [SELECT ID, Name, Section__r.Name, Section__c, Section__r.Record_Attendance__c
									  FROM Student_Section__c
									  WHERE Student__c = :selectedStudentID
									  AND active__c=true
									  and Section__r.RecordType.DeveloperName = 'Published']){
			if (bAttendance){
				if (ss.Section__r.Record_Attendance__c){
					studSectionList.add(ss);
				}
			}
			else studSectionList.add(ss);
		}
		return studSectionList;
	}

	public static Map<ID,Integer> getTardyMap(Set<ID> studIDSet, ID sectionId){
		Map<ID, Integer> tempMap = new Map<ID, Integer>();
		for(AggregateResult ag : [SELECT Student__c s, count(Name) cnt
									FROM Attendance__c
									WHERE Student__c IN :studIDSet
									AND Picklist_Value__r.Is_Tardy__c = true
									AND Session__r.Section__c =: sectionID
									GROUP BY Student__c]){
			tempMap.put((ID)ag.get('s'),(Integer)ag.get('cnt'));
		}
		return tempMap;
	}

	public static Map<ID,Integer> getAbsentMap(Set<ID> studIDSet, ID sectionId){
		Map<ID, Integer> tempMap = new Map<ID, Integer>();
		for(AggregateResult ag : [SELECT Student__c s, count(Name) cnt
									FROM Attendance__c
									WHERE Student__c IN :studIDSet
									AND Picklist_Value__r.Category__c = 'Absent'
									AND Session__r.Section__c =: sectionId
									GROUP BY Student__c]){
			tempMap.put((ID)ag.get('s'),(Integer)ag.get('cnt'));
		}
		return tempMap;
	}

	public static List<Attendance__c> getAttendanceFromDates(String section, Alert__c startDate, Alert__c endDate, ID student){
		List<Attendance__c> att = [Select   ID, Comments__c, Student__c, Picklist_Value__c, Session__c, Daily__c , external_id__c
										From Attendance__c where Student__c =:student
										AND (Session_Date__c >= :startDate.Expiration_Date__c AND Session_Date__c <= :endDate.Expiration_Date__c)
										AND Session__r.Section__c = :section];
		return att;
	}

	public static Map <ID, List <Enrollment_Tracking__c>> getEnrollmentTrackingMap(Set <Id> studSecIdSet){
		Map <ID, List <Enrollment_Tracking__c>> etMap = new Map <ID, List <Enrollment_Tracking__c>>();
		for (Enrollment_Tracking__c et: [select Active__c, student_section__c, id, start_date__c, end_date__c from Enrollment_Tracking__c where Student_Section__c in: studSecIdSet]){
			if (etMap.get(et.student_section__c)==null){
				etMap.put(et.student_section__c, new List <Enrollment_Tracking__c>{et});
			}
			else etMap.get(et.student_section__c).add(et);
		}
		return etMap;
	}
}