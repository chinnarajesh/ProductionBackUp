global class Behavior_SoqlUtils {
	private static string studentSearchQuery = 'SELECT id, Name, Student_First_Name__c, Student_Last_Name__c,'+
												' Grade__c, Active__c, Date_of_Birth__c, Individual__c,' + 
												' Student_Id__c, School__c, Reference_ID__c, Setup__c' +
												' FROM Student__c' + 
												' WHERE Active__c = true';
	
	public static Behavior_Incident__c getBehaviorIncident(Id incidentId) {
		Behavior_Incident__c behaviorIncident = new Behavior_Incident__c(); 
		try {
			behaviorIncident = [Select Id ,Name, Incident_Title__c, Incident_Date__c, Incident_Status__c
										,Additional_Comments__c, Incident_Description__c, Student_Witness__c
										,Adult_on_Duty__c, Request_Info_AoD__c, Request_Info_Adult1__c
										,Request_Info_Adult2__c, Addl_Educational_Time_Lost__c, Context_Time__c
										,Context_Location__c, Weapon_Type__c, Other_Adult_Involved_1__c
										,Other_Adult_Involved_2__c, Other_Adult_Involved_1_Email__c, Other_Adult_Involved_2_Email__c
										,Incident_Identifier__c, Other_Notes__c, Incident_Time__c, Adult_On_Duty_Email__c
										,Notify_Incident_Owner__c, Student_Involved_Full_Name__c, Verbal_Redirection__c
										,Take_A_Break__c, Buddy_Classroom__c, Alternative_Seating__c, Time_Out__c
										,Practice_desired_behavior__c, Verbal_or_written_apology__c, Loss_Of_Privilege__c
										,Restitution_Community_Service__c, Behavior_Contract__c, Other__c, Incident_Type__c
										,Selected_Behavior_Category__c, Selected_Behavior_Incident_Type__c
										,Incident_Points__c, Adult_On_Duty__r.Individual__r.User__r.Id
										,Other_Adult_Involved_1__r.Individual__r.User__r.Id, Other_Adult_Involved_2__r.Individual__r.User__r.Id
										,Show_In_Portal__c, Selected_Behavior_Incident_Type__r.Name, Preserve__c
								From Behavior_Incident__c 
								where Id = :incidentId]; 
		} catch (Exception ex) {
		}
		return behaviorIncident;		  
	}
	
	public static List<Student_Behavior__c> getStudentsInvolved(Id incidentId) {
		List<Student_Behavior__c> studentsInvolved = new List<Student_Behavior__c>();		
		try {
			studentsInvolved = [Select Id, Name, Student__c, Behavior_Incident__c, Student__r.Name, Student__r.Archived__c
										,Student__r.Student_First_Name__c, Student__r.Student_Last_Name__c, Student__r.Grade__c
										,Incident_Role__c, Total_Time_Lost__c, Type_Of_Contact__c, Family_Contacted__c
										,Consequence_Time_Lost__c, Final_Consequence_Weighting__c			  
								From Student_Behavior__c 
								where Behavior_Incident__c = :incidentId];
		} catch(Exception ex) {
		}
		return studentsInvolved; 
	}
	
	public static  List<Consequence__c> getAllConsequences(Set<Id> studentInvolvedIds) {
		List<Consequence__c> consequences = new List<Consequence__c>();
		try{
			consequences = [Select Id, Name, Student__c, Consequence__c, Consequence_Weighting__c, Time_Lost__c 
									,Consequence_Category__c, Final_Consequence__c, Days_Suspended__c, Is_Suspended__c 
									,Date_of_Re_entry__c, Re_entry_Notes__c, Re_entry_Mtg_Time__c, Re_entry_Mtg_Date__c
									,Picklist_Value__r.Name, Picklist_Value__r.Notify_Admin__c, Picklist_Value__r.Category__c, Student_Consequence__c
									,Show_Suspension_In_Attendance__c, Suspension_End_Date__c, Suspension_Start_Date__c
							From Consequence__c 
							where Student__c in :studentInvolvedIds];
		} catch(Exception e){
		}
		return consequences;								
	}  
	
	public static List <Behavior_Incident__c> getBehIncById (Set <Id> BehIds){
		List <Behavior_Incident__c> behList = new List<Behavior_Incident__c>();
		try{
			behList = [select Id, Name, Incident_Weighting__c, Student_Involved_Full_Name__c 
					   from Behavior_Incident__c 
					   where ID IN :BehIds];
		} catch (Exception e){
		}
		return behList;
	}
	
	public static List <Student_Behavior__c> getStudentBehaviorListByIncident(Set <Id> biSet){
		List <Student_Behavior__c> studBehList = new List<Student_Behavior__c>();
		try{
			 studBehList =  [select Id 
							 from Student_Behavior__c 
							 where Behavior_Incident__c IN :biSet];
		} catch (Exception e){
		}
		return studBehList;
	}
	
	public static List <Student_Behavior__c> getStudentBehaviorToWeight(Set <Id> studBehIds){
		List <Student_Behavior__c> studBehList = new List<Student_Behavior__c>();
		try{
			studBehList = [SELECT Id, Total_Time_Lost__c, Final_Consequence_Weighting__c 
						   FROM Student_Behavior__c 
						   WHERE Id in :studBehIds];
		} catch (Exception e){
		}
		return studBehList;
	}
	
	public static List<Student__c> searchStudents(Student__c searchInfo, String schoolId){
		String firstName = '', lastName = '';
		//modified version from AttendanceDateWizardController
		//wildcard stuff - we've trained EL Haynes to use a * in their searches for wildcard...needed to hardcode that here
		if(searchInfo.Student_First_Name__c!=null){
			firstName = core_SoqlUtils.getSearchName(searchInfo.Student_First_Name__c);
		}
    	if(searchInfo.Student_Last_Name__c!=null){
    		lastName = core_SoqlUtils.getSearchName(searchInfo.Student_Last_Name__c);
    	}
    	//end code borrowed from AttendanceDateWizardController
    	
    	String query = Behavior_SoqlUtils.studentSearchQuery;
    	
    	query += (firstName == '') ? '':' AND Student_First_Name__c LIKE \''+firstName+'\'';
    	query += (lastName == '') ? '': ' AND Student_Last_Name__c LIKE \''+lastName+'\'';
    	query += (searchInfo.Date_of_Birth__c == null) ? '':' AND Date_of_Birth__c=' + String.valueOf(searchInfo.Date_of_Birth__c);
    	query += (searchInfo.Gender__c == null) ? '':' AND Gender__c=\''+searchInfo.Gender__c+'\'';
    	query += (searchInfo.Student_Id__c == null) ? '':' AND Student_Id__c=\'' + String.escapeSingleQuotes(searchInfo.Student_Id__c) + '\'';
		query += (searchInfo.Grade__c == null) ? '':' AND Grade__c=\''+searchInfo.Grade__c+'\'';
		query += (searchInfo.School__c == null)?'':' AND School__c=\''+searchInfo.School__c+'\'';
		
		query += ' ORDER BY Student_Last_Name__c ASC';
		List<Student__c> results = new List<Student__c>((List<Student__c>)Database.query(query));
		return results;
	}
	
	public static Map<Id, Student__c> getStudentsById(Set<Id> ids){
		Map<Id, Student__c> students = new Map<Id, Student__c>([select id, Name, Setup__c from Student__c where id IN: ids]);
		return students;
	}
	
	public Static List<Picklist_Value__c> getPlValuesListByRecordType(String rtype,String SetupId) {
		List<Picklist_Value__c> plValuesList = new List<Picklist_Value__c>();
		plValuesList = [SELECT Corresponding_Value__c, Set_as_default__c, Name, Behavior_Category__c
							,Incident_Involves_Weapon__c, Consequence_Weight__c, RecordTypeId, Setup__c, Type__c
							,Behavior_Incident_Level__c, Is_Suspension__c, Notify_Admin__c, Order__c, Category__c
						FROM Picklist_Value__c 
						WHERE RecordTypeId = :rtype
						AND (setup__c = :SetupId or setup__c = null)
						order by Set_As_Default__c DESC, order__c ASC];
		return plValuesList;
	}
	
	public static List<Student_Behavior__c> getStudentBehaviorListByContact(Id contactId){
		List<Student_Behavior__c> studentsInvolved = new List<Student_Behavior__c>();		
		try {
			studentsInvolved = [Select Id, Name, Student__c, Behavior_Incident__c, Behavior_Incident__r.Incident_Title__c
										,Behavior_Incident__r.Incident_Date__c, Final_Consequence_Weighting__c
										,Incident_Role__c, Total_Time_Lost__c, Consequence_Time_Lost__c
										,Behavior_Incident__r.Selected_Behavior_Category__c, Behavior_Incident__r.Selected_Behavior_Incident_Type_Formula__c
								From Student_Behavior__c 
								where Contact__c =: contactId
								order by Behavior_Incident__r.Incident_Date__c];
		} catch(Exception ex) {
		}
		return studentsInvolved;
	}
}