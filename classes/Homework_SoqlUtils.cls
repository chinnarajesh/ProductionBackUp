global class Homework_SoqlUtils {
	public static String HWAlertQuery1 = 'Select Student__c, Student__r.Student_Last_Name__c'+
										' From HW_Tracker__c'+ 
										' WHERE Received_First_Alert__c = FALSE'+
										' AND Notification_Required__c = \'Yes\''+
										' AND Student__c != null';	  
	
	public static String HWAlertQuery2 = 'Select Student__c, Student__r.Student_Last_Name__c'+
										' From HW_Tracker__c'+ 
										' WHERE Received_First_Alert__c = FALSE'+
										' AND Second_Notification_Required__c = \'Yes\''+
										' AND Student__c != null';	  
	
    
			
	public static List<Student_PG__c> getParentalInfo(id studentId){
		List<Student_PG__c> pgList = new List<Student_PG__c>();
		try{
			pgList = [select Student_c__r.FirstName, Student_c__r.LastName, Student_c__c, Student__c
							,Student__r.School__c, Student__r.Student_Last_Name__c
							,Parent_Guardian_c__r.Preferred_Language__c, Parent_Guardian_c__r.Notify_via_SMS__c
							,Parent_Guardian_c__r.Notify_via_Email__c, Parent_Guardian_c__r.Email_to_SMS_Address__c
							,Parent_Guardian_c__r.Email, Parent_Guardian_c__c, Id
						from Student_PG__c
						where Student__c = :studentID];
		} catch (Exception e) {
		}
		return pgList;
	}
	
	public static List<AggregateResult> getHWStatInfo(Set<Id> studentIds){
		List<AggregateResult> groupedResults = new List<AggregateResult>();
		try{
			groupedResults = [Select Student__c s, Picklist_Value__r.Category__c pv, count(Id) scount 
							  From HW_Tracker__c
							  WHERE Student__c IN :studentIds
							  GROUP BY Student__c, Picklist_Value__r.Category__c];
		}catch (Exception e){
		}
		return groupedResults;
	}
	
	public static List<Time_Element__c> getDueReportingPeriod(date dueDate){
		List<Time_Element__c> reportingPeriods = new List<Time_Element__c>();
		try{
			reportingPeriods = [Select Id 
								from Time_Element__c 
								WHERE Date_Start_Date__c <= :dueDate 
								AND End_Date__c >= :dueDate
								AND Reporting_Period__c = true];
		} catch (Exception e){
		}
		return reportingPeriods;
	}
	
	public static List<Student__c> getStudentList(boolean isHomeroom, String section){
		List<Student__c> students = new List<Student__c>();
		try{
			string query = 'Select of_Missing_Homework__c, of_Late_Homework__c, Name, Id'+
						   ',Student__c.Student_Last_Name__c,Student_First_Name__c'+
								',(Select Id, Section__c, section__r.Has_Homework__c, section__r.name'+
										  ',Section__r.Active__c, Section__r.Course__r.Name, Section__r.Course__c'+ 
								' From Student_Section__r'+
								' WHERE section__r.Has_Homework__c = true'+ 
 								' AND section__r.Active__c = true'+
								' AND Active__c = true' +
								' AND Section__r.RecordType.DeveloperName = \'Published\'';
			if(!isHomeroom){
				query +=		' AND Section__c = :section';
			}
			query +=			' Order By Section__r.Course__r.Name ASC)'+
							' From Student__c '+ 
							' WHERE Id IN (Select Student__c'+
											' from Student_Section__c'+
											' WHERE Section__c = :section'+
											' AND Active__c = true)'+
							' AND Active__c = true' + 
							' Order BY Student_Last_Name__c ASC, Student_First_Name__c ASC';
			students = database.query(query);
		} catch (Exception e) {
		}
		return students;
	}
	
	public static List<HW_Tracker__c> getHomework(Date dueDate, id section){
		List<HW_Tracker__c> hw = new List<HW_Tracker__c>();
		try{
			hw = [Select Student__c, Student_Section__c, Student_Section__r.Section__c, Extension_Date__c, Due_Date__c
						 ,Responsibility_Center__c, Id, HW_Status__c, Comments__c, Picklist_Value__c, Student_Section__r.Section__r.Course__c
				  From HW_Tracker__c 
				  WHERE due_date__c = :dueDate
				  AND Student__c IN (Select Student__c 
											from Student_Section__c 
											where Section__c = :section)];
		} catch (Exception e) {
		}
		return hw;
	}
}