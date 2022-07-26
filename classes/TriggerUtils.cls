public with sharing class TriggerUtils {
	public static final String MATH = 'Math';
	public static final String BEH = 'Behavior';
	public static final String ATT = 'Attendance';
	public static final String ELA = 'ELA/Literacy';

	public static void createAccountPrograms(List<Account> schools, List<Program__c> programs){
		List<Account_Program__c> connections = new List<Account_Program__c>();
	
		for (Program__c program : programs){
			if(program.Required_Program__c){
				for(Account acc : schools){
					Account_Program__c AP = new Account_Program__c();
					AP.Active__c = false;
					AP.School__c = acc.id;
					AP.Program__c = program.id;
					AP.name = program.name;
					connections.add(AP);
				}
			}
		}
		
		if(!connections.isEmpty()) insert connections;
	}
	
	public static void deactivateAccountPrograms(Set<ID> programs){
		List<Account_Program__c> connections = [SELECT id FROM Account_Program__c WHERE Program__c IN :programs];
		if(!connections.isEmpty()){
			for(Account_Program__c ap: connections){
				ap.Active__c = false;
			}
			update connections;
		}
	}
	
	public static void assignSchoolYear(List<Account_Program__c> newList){
		Set<ID> schoolIDs = new Set<ID>();
		for(Account_Program__c ap: newList) schoolIDs.add(ap.School__c);
		List<Setup__c> setups = [SELECT id, School__c, School__r.Name, Year__c FROM Setup__c
			WHERE School__c IN :schoolIDs AND Active__c=true];
			
		Map<ID,Setup__c> schoolToActiveSetup = new Map<ID,Setup__c>();
		for(Setup__c setup: setups) schoolToActiveSetup.put(setup.School__c,setup);
		
		for(Account_Program__c ap: newList){
			if(schoolToActiveSetup.containsKey(ap.School__c)){
				ap.Current_Year_ID__c = schoolToActiveSetup.get(ap.School__c).Year__c;
				if(ap.Current_Year_ID__c==null)
					ap.addError('There is no current school year for this school.  Please check that the active setup for '+schoolToActiveSetup.get(ap.School__c).School__r.Name+' has an associated year record.');
			}
			else
				ap.addError('There is no active setup for school with id: '+ap.School__c+'.  Please activate a setup for this school.');
		}
	}
	
	public static void AUSectionStaffSectionCreate(List<Section__c> triggerNew, Map<Id, Section__c> triggerMapOld) {
		List<Staff_Section__c> staffList = new List<Staff_Section__c>();
		List<Id> sectionIds = new List<Id>(); 
		for(Section__c sec :triggerNew){
			if(sec.Intervention_Primary_Staff__c != triggerMapOld.get(sec.Id).Intervention_Primary_Staff__c && sec.Intervention_Primary_Staff__c != null){
				sectionIds.add(sec.Id);
			}
		}

		if(!sectionIds.isEmpty()){
			
			List<Section__c> sections = [Select Id, Name, Intervention_Primary_Staff__c, (Select Id, Staff__c, Section__c, Intervention_Primary_Staff__c FROM Staff_Section__r) FROM Section__c WHERE Id IN :triggerNew];
		
			for(Section__c sec :sections) {
				Boolean isNoActiveSS = true;
				if(sec.Staff_Section__r!=null && !sec.Staff_Section__r.isEmpty()){
					for(Staff_Section__c ss :sec.Staff_Section__r) {
						if(ss.Staff__c == sec.Intervention_Primary_Staff__c) {
							if(ss.Intervention_Primary_Staff__c != true) {
								ss.Intervention_Primary_Staff__c = true;
								staffList.add(ss);
							}
							isNoActiveSS = false;
						}
					}
				}
				if(isNoActiveSS){
					Staff_Section__c staffSec = new Staff_Section__c();
					staffSec.Intervention_Primary_Staff__c = true;
					staffSec.Staff__c = sec.Intervention_Primary_Staff__c;
					staffSec.Section__c = sec.id;
					staffList.add(staffSec);
				}
			}
			
			try {
				if(!staffList.isEmpty()) upsert staffList;
			} catch( Dmlexception e) {
				String linkString='';
				for(Section__c sec: sections){
					if(linkString!='') linkString+=';';
					linkString+=sec.Name+','+sec.id;
				}
				Global_Error__c ge = Error_Handling.handleError(linkString,'Section Trigger','Update primary corps member staff sections failure',e);
			}
		}
	}
	public static void AISectionStaffSectionCreate(List<Section__c> triggerNew) {
		List<Staff_Section__c> staffList = new List<Staff_Section__c>();
		for(Section__c sec :triggerNew) {
			if(sec.Intervention_Primary_Staff__c!=null){
				Staff_Section__c staffSec = new Staff_Section__c();
				staffSec.Intervention_Primary_Staff__c = true;
				staffSec.Staff__c = sec.Intervention_Primary_Staff__c;
				staffSec.Section__c = sec.Id;
				staffList.add(staffSec);
			}
		}
		try {
			if(!staffList.isEmpty()) insert staffList;
		} catch( Dmlexception e) {
			String linkString='';
			for(Section__c sec: triggerNew){
				if(linkString!='') linkString+=';';
				linkString+=sec.Name+','+sec.id;
			}
			Global_Error__c ge = Error_Handling.handleError(linkString,'Section Trigger','Insert primary corps member staff sections failure',e);
		}
	}
	
	public static void AIAUStaffSection(List<Staff_Section__c> triggerNew) {
		List<Id> sectionIds = new List<Id>();
		for(Staff_Section__c ss :triggerNew) {
			if(ss.Intervention_Primary_Staff__c == true) sectionIds.add(ss.Section__c);
		}
		
		List<Staff_Section__c> PCMList = new List<Staff_Section__c>();
		Map <Id, Section__c> SecMap = new Map<Id, Section__c>([SELECT Id, Intervention_Primary_Staff__c,(SELECT Id, Intervention_Primary_Staff__c FROM Staff_Section__r WHERE Intervention_Primary_Staff__c = true AND Id NOT IN :triggerNew) FROM Section__c WHERE Id IN :sectionIds]);
		List <Section__c> sectionsToUpdate = new List<Section__c>();		
		if(!sectionIds.isEmpty()){
			for(Staff_Section__c ss :triggerNew) {
				if(SecMap.containsKey(ss.Section__c) && ss.Intervention_Primary_Staff__c) {
					Section__c sec = SecMap.get(ss.Section__c);
					sec.Intervention_Primary_Staff__c = ss.Staff__c;
					if(sec.Staff_Section__r!=null && !sec.Staff_Section__r.isEmpty()){
						for(Staff_Section__c pm :sec.Staff_Section__r) {
							pm.Intervention_Primary_Staff__c = false;
							PCMList.add(pm);
						}
					}
					SecMap.put(sec.id,sec);
				}
			}
		}
		
		try {
			if(!PCMList.isEmpty()) update PCMList;
			if(!SecMap.isEmpty()) update SecMap.values();
			
		} catch( Dmlexception e) {
			String linkString='';
			for(Staff_Section__c sec: triggerNew){
				if(linkString!='') linkString+=';';
				linkString+=sec.Staff__r.Name+'-'+sec.Section__r.Name+','+sec.id;
			}
			Global_Error__c ge = Error_Handling.handleError(linkString,'Staff/Section Trigger','DML Failure',e);
		}
	}

	public static void checkReferenceId(List<Indicator_Area_Student__c> newList){
		for(Indicator_Area_Student__c ias : newList){
			String key = ias.Student__c+'_'+ias.Indicator_Area__c;
			if(ias.Reference_ID__c!=key) ias.Reference_ID__c = key;
		}
	}
	
	public static void checkReferenceId(List<Account_Program__c> newList){
		for(Account_Program__c ap : newList){
			String key = ap.School__c+'_'+ap.Program__c+'_'+ap.Current_Year_ID__c;
			if(ap.Reference_ID__c != key) ap.Reference_ID__c = key;
		}
	}
	
	public static Contact createContact(Student__c student, Account school){
		Contact newContact = new Contact();
		if(Student.Student_Last_Name__c != null){
			newContact.LastName = Student.Student_Last_Name__c;
		}
		if(Student.Student_First_Name__c != null){
			newContact.FirstName = Student.Student_First_Name__c;
		}
		if(Student.Date_of_Birth__c!= null){
			newContact.Date_of_Birth__c = Student.Date_of_Birth__c;
		}
		if(Student.Gender__c != null){
			newContact.Gender__c = Student.Gender__c;
		}
		if(Student.Ethnicity__c != null){
			newContact.Ethnicity__c = Student.Ethnicity__c;
		}
		if(Student.Active__c != null){
			newContact.Active__c = Student.Active__c;
		}
		if(school != null){
			newContact.AccountId = school.id;
		}
		return newContact;
	}
}