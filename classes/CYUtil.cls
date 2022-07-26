public with sharing class CYUtil{
	public static String CMPROFILENAME = 'CY CM/Direct Service Provider Profile';
	public static String SCHOOLPROFILENAME = 'CY School Administrator Profile';
	public static String SITEPROFILENAME = 'CY Location/Site Administrator Profile';
	public static String NETWORKPROFILENAME = 'CY Network Admin (HQ) Profile';
	public static String SYSADMINPROFILENAME = 'System Administrator';

	public static Time_Element__c currentYear;

	public static Map<String, ID> recordTypeNameMap;
	public static Map<ID, Profile> profileMap;
	
	public static List<Account> getStaffSchool(){
		List<Account> schools = new List<Account>();
		String userId = Userinfo.getUserId();
		userId = userId.substring(0,15);
		system.debug(userId);
		List<Staff__c> staffRecords = new List<Staff__c>();
		Profile p = [Select Id, Name from Profile WHERE Id =:Userinfo.getProfileId()];
		RecordType rt = [Select ID FROM RecordType WHERE Name = 'School'];
		if(p.Name == SYSADMINPROFILENAME) {
			schools = [Select Id, Name FROM Account WHERE RecordTypeId = :rt.Id ORDER BY Name ASC];
			return schools;
		}
		else {
			staffRecords = [SELECT Id, Name, User_ID__c, Organization__r.Id,Organization__r.Name FROM Staff__c where User_ID__c = :userId AND Active__c = true];
			if(staffRecords.size() >=1){
				for(Staff__c s :staffRecords)
				{
					if(userId.equals(s.User_ID__c) && s.Organization__r!=null)
						schools.add(s.Organization__r);
				}
				return schools;
			}
		}
		return null;
	}
	
	public static List<Account> getAllActiveSchools() {
		ID rtID = getRecordTypeID('School');
		List<Account> schools = new List<Account>();
		for(Setup__c s:
				[select id, School__r.Name, School__c 
				from Setup__c 
				where Active__c = true
				and School__r.RecordTypeId = :rtID
				ORDER BY School__r.Name ASC]){
			schools.add(s.School__r);
		}
		if(schools.size() > 0){
			return schools;
		}
		return null;
		 
	}

	public static Id getSchoolYearID(Id schoolID) {
		List <Setup__c> activeSetup = [SELECT Id, Year__r.Id FROM Setup__c WHERE Active__c = true AND School__c = :schoolID limit 1];
		
		if(activeSetup.Size() > 0)
			return activeSetup[0].Year__r.Id;//r.Id;
		return null;
	}

	public static Id getRecordTypeID(String recordTypeName) {
		if(recordTypeNameMap == null){
			recordTypeNameMap = new Map<String, ID>();

			for (RecordType rt: [SELECT id, Name, DeveloperName , sObjectType
								FROM RecordType 
								WHERE Name!=null
								AND IsActive = true]){
				if(rt.sObjectType == 'Section__c' || rt.sObjectType == 'Contact' 
					|| rt.sObjectType == 'Account' || rt.sObjectType == 'EOY_Progress__c'){
					recordTypeNameMap.put(rt.Name, rt.ID);
				}
			}
		}
		
		return recordTypeNameMap.get(recordTypeName);
	}

	public static String getProfileTypeName(Id ProfileTypeID) {
		if(profileMap == null){
			profileMap = new Map<ID, Profile>([SELECT Id, Name FROM Profile WHERE Id = :ProfileTypeID LIMIT 1]);
		}
		if(profileMap.containsKey(ProfileTypeID)){
			return profileMap.get(ProfileTypeID).Name;
		}
		return null;
	}

	public static List<Intervention_Session__c> getInterventionDataForSection(Id sectionId){
		return [Select Skills_Covered_for_the_Session__c, Id, Date__c, Comments__c
				From Intervention_Session__c WHERE Section__c = :sectionId];
	}
	
	public static list<Intervention_Session__c> getInterventionDataForSection(Id sectionId, Date startDate, Date endDate){
		return [Select Skills_Covered_for_the_Session__c, Id, Date__c, Comments__c,
					(Select Id, Amount_of_Time__c, Student_Section__c, Intervention_Session__r.Skills_Covered_for_the_Session__c,
						Intervention_Session__r.Date__c, Intervention_Session__r.Comments__c , 
						Intervention_Session__c, Student__c, Student_Section__r.Student__c
					FROM Intervention_Session_Results__r )
				From Intervention_Session__c WHERE Section__c = :sectionId AND Date__c >= :startDate AND Date__c <= :endDate
				ORDER BY Date__c ASC];
	}

	public static ID getCurrentYearID(){
		return getCurrentYear().id;
	}

	public static Time_Element__c getCurrentYear(){
		if(currentYear == null){ //why query when you already have it?
			try{
				currentYear=
					[select id, Name__c, Date_Start_Date__c, End_Date__c 
					from Time_Element__c 
					where Current__c = true 
					order by End_Date__c
					limit 1];
			} catch (System.QueryException e){
				return null;
			}
		}
		return currentYear; 
	}

	public static map<ID, list<Indicator_Area_Student__c>> getStudentIndicatorAreaMap(list<Student__c> students) {
		list<Indicator_Area_Student__c> iaList = new list<Indicator_Area_Student__c>([
			SELECT Id, Name, Student__c, Indicator_Area__c
			FROM Indicator_Area_Student__c
			WHERE Student__c IN :students
		]);
		map<ID, list<Indicator_Area_Student__c>> studentIndicatorAreaMap = new map<ID, list<Indicator_Area_Student__c>>();
		for (Indicator_Area_Student__c ia : iaList) {
			if (!studentIndicatorAreaMap.containsKey(ia.Student__c)) {
				studentIndicatorAreaMap.put(ia.Student__c, new list<Indicator_Area_Student__c>());
			}
			studentIndicatorAreaMap.get(ia.Student__c).add(ia);
		}
		return studentIndicatorAreaMap;
	}

	public static void errorMessage(String message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,message));
	}

	public static void infoMessage(String message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,message));
	}

	public static void warningMessage(String message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,message));
	}

	public static void successMessage(String message){
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,message));
	}

	public class InterventionsException extends Exception{
		
	}

	public class InterventionsPermissionsException extends Exception{

	}

	public static ID userStaffsSection(ID sectionID){
		List<Staff_Section__c> userSectionStaff =
			[select id,Staff__c from Staff_Section__c 
			WHERE Section__c =:sectionID
			AND Is_Active__c=true
			AND Staff__r.Individual__r.User__c =: UserInfo.getUserID()];

		if(userSectionStaff.isEmpty()){
			return null;
		} else {
			return userSectionStaff[0].Staff__c;
		}
	}
}