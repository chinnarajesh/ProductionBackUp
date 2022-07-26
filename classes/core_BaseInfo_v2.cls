public with sharing class core_BaseInfo_v2{ 
	public static Contact con {get;set;} //Logged in contact
	public static User cUser {get;set;} 
	public static List <Staff__c> staffList {get;set;} //List of staff records for logged in Contact (no need to link back to contact record since there will only ever be 1)
	public static Map <Id, Id> staffSchoolMap {get;set;} //Needed to get the staff record related to the school since its 1:1 
	public static Map <Id, Account> schoolMap {get;set;} //If toggling between schools this helps retreive that info
	public static Map <Id, List <Section__c>> staffSectionListMap {get;set;} //List of sections related to a single school/ needed if toggling
	public static Map <Id, Setup__c> activeSetupsBySchoolMap {get;set;}
	public static Map<String, Id> picklistValueRecordTypeMap {get;set;} //LIst of recordTypes for Picklist Value obj
	public static String[] errorMessages {get;set;}
	public static core_BaseInfo_v2.cSchool_BaseInfo baseInfoObj {get;set;}
	public static Map<String,Map<String,List<Section__c>>> yearSectionsMap;
	public static List<String> recentSchoolYears;
	public static Map<String,Map<String,Setup__c>> schoolSetupsByYearMap;
	public static Id UserId; 

	public core_BaseInfo_v2(){
	}

	public static void showErrorMessages(){
		if (!errorMessages.isEmpty()){
			for (String s: errorMessages){
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,s));
			}
		}
	}

	public static void initBaseInfo(){
		loadBaseInfo(null, true, true, true,false,null);
	}
	
	public static void initBaseInfo(Boolean isYOY){
		loadBaseInfo(null, true, true, true,true,null);
	}

	public static void initBaseInfo(Boolean isYOY, String yearID){
		loadBaseInfo(null, true, true, true, true, yearID);
	}
	
	public static void initBaseInfo(String schoolId){
		loadBaseInfo(schoolId, true, true, true,false,null);
	}
	
	public static void initBaseInfo(boolean reporting, boolean section, boolean picklist){
		loadBaseInfo(null, reporting, section, picklist,false,null);
	}
	
	public static void initBaseInfo(String schoolId, boolean reporting, boolean section, boolean picklist){
		loadBaseInfo(schoolId, reporting, section, picklist,false,null);
	}
	
	private static void loadBaseInfo(string schoolId, boolean reporting, boolean section, boolean picklist,boolean prevYear, String yearID) {
		staffSchoolMap = new Map <Id, Id>();
		staffList = new List <Staff__c>();
		schoolMap = new Map <Id, Account>();
		staffSectionListMap = new Map<Id, List <Section__c>>();
		activeSetupsBySchoolMap = new Map <Id, Setup__c>();
		Set <Id> staffIds = new Set <Id>();
		Set <Id> schoolIds = new Set <Id>();
		errorMessages = new String[]{};
		picklistValueRecordTypeMap = new Map<String, Id>();
		
		//get logged in user id
		if (core_Baseinfo_v2.UserId==null){
			UserId = UserInfo.getUserId();
		}
		
		con = core_SoqlUtils.getLoggedInContact(); //Always first step, get logged in contact
		if (con == null){
			errorMessages.add('The system was unable to locate a contact record for your user. Please contact your administrator.');
			return;
		}
		cUser = core_SoqlUtils.getLoggedInUser();
		
		try{
			staffList = [select id, Organization__c from staff__c where Individual__c=:con.id];
		} catch (Exception e){
			errorMessages.add('The system was unable to locate staff records for your contact. Please contact your administrator.');
			return;
		}
		
		//make a map of schools avaiable for the logged in user
		for (Staff__c s: staffList){
			staffIds.add(s.id);
			if (s.Organization__c!=null) {
				schoolIds.add(s.organization__c);
				staffSchoolMap.put(s.organization__c, s.id);
			}
		}
		
		if(schoolIds.isEmpty()){
			errorMessages.add('The system was unable to locate schools linked to your staff record(s). Please contact your administrator.');
			return;
		}
		
		schoolMap= core_SoqlUtils.getSchoolMap(schoolIds);
		activeSetupsBySchoolMap = core_SoqlUtils.getActiveSetups(schoolMap.keySet());//TBD add error handling if there is not an active setup for a certain school
		
		if(section){
			staffSectionListMap= core_SoqlUtils.getSectionsbyStaffMap(staffIds); //TBD needs to be a single school
		}
		
		recentSchoolYears = core_SoqlUtils.getRecentThreeYears(); 
		schoolSetupsByYearMap = core_SoqlUtils.getRecentSchoolSetups(recentSchoolYears, staffSchoolMap.keyset());

		if(prevYear){
			if(section) 
			yearSectionsMap = core_SoqlUtils.getSectionsByYear(staffSchoolMap.keyset(),staffSchoolMap.values(),recentSchoolYears);
			System.debug('$$$staffSchoolMap.keyset()$$$$'+staffSchoolMap.keyset());
			System.debug('$$$recentSchoolYears$$$$$'+recentSchoolYears);	
			System.debug('$$$yearSectionsMap$$$$$'+yearSectionsMap);	
		}

		//Set the current school to the users last used school, or the first of the avaiable schools.
		if(schoolId != null){
			if(prevYear){
				baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(schoolId, reporting, section,activeSetupsBySchoolMap.get(schoolId).Year__c);
			}
			else 
			baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(schoolId, reporting, section);
		} else if(cUser.School__c == null || cUser.School__c == ''){
			if(prevYear){
				if(String.isBlank(yearID)){
					baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(schoolMap.values()[0].id, reporting, section,activeSetupsBySchoolMap.get(schoolMap.values()[0].id).Year__c);
				} else {
					baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(schoolMap.values()[0].id, reporting, section,yearID);
				}
			} else{
				baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(schoolMap.values()[0].id, reporting, section); 
			} 
			cUser.School__c = String.valueOf(baseInfoObj.school.Id);
		} else {
			if(prevYear){
				if(String.isBlank(yearID)){
					baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(cUser.School__c, reporting, section,activeSetupsBySchoolMap.get(cUser.School__c).Year__c);
				} else {
					baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(cUser.School__c, reporting, section,yearID);
				}
			} else{
				baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(cUser.School__c, reporting, section);
			}
		}
		
		if(picklist){ 
			picklistValueRecordTypeMap = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c');
		}
	}
	
	//Nested class
	public class cSchool_BaseInfo{
		public Staff__c staff {get;set;}
		public boolean bStandardsBased {get;set;}
		public Decimal dPassingGrade {get;set;}
		//NYC functionality commented out, 8/20/2012 uncommented dFailingGrade
		public Decimal dFailingGrade {get;set;}
		public Setup__c activeSetup {get;set;}
		public Account school {get;set;}
		public List <Section__c> sectionList {get;set;}
		public List <SelectOption> reportingPeriodOptions {get;set;}
		public List <SelectOption> sectionOptions {get;set;}
		public List <SelectOption> assignmentTypeOptions {get;set;}
		public Id selectedTimeId {get;set;}
		public Map <Id, Section__c> sectionMap {get;set;}
		
		public cSchool_BaseInfo(Id SchoolId){
			this(SchoolId, true, true);
		}
		
		public cSchool_BaseInfo(Id SchoolId, boolean reporting, boolean section){
			sectionMap = new Map <Id, Section__c>();
			sectionList = new List<Section__c>();
			reportingPeriodOptions = new List <SelectOption>();
			sectionOptions = new List <SelectOption>();
			
			activeSetup = core_BaseInfo_v2.activeSetupsBySchoolMap.get(SchoolId);
			school = core_BaseInfo_v2.schoolMap.get(SchoolId);
			staff = core_SoqlUtils.getStaffDetails(core_BaseInfo_v2.staffSchoolMap.get(schoolId));

			if (activeSetup!=null){
				bStandardsBased = activeSetup.Standards_Based_Grading__c;
				//NYC functonality commented out, 8/20/2012 uncommented dPassingGrade, dFailingGrade
				//dPassingGrade = activeSetup.Passing_Grade_Threshold__c;
				dPassingGrade = activeSetup.On_Track_Threshold__c;
				dFailingGrade = activeSetup.Passing_Grade_Threshold__c;
				
				if(reporting){ 
					for (Time_Element__c t: core_SoqlUtils.getTimeElementsByTermGB(activeSetup.term__c)){
						reportingPeriodOptions.add(new SelectOption(t.Id, t.Name__c)); 
					}
				}
				
				if(section){
					if (core_BaseInfo_v2.staffSectionListMap.get(staffSchoolMap.get(SchoolId))!=null){
						for (Section__c s: core_BaseInfo_v2.staffSectionListMap.get(staffSchoolMap.get(SchoolId))){
							sectionMap.put(s.id, s);
							sectionList.add(s);
							sectionOptions.add(new SelectOption(s.id, s.name));
						}
					}
					else{
						core_BaseInfo_v2.errorMessages.add('No sections for school year: '+activeSetup.Year__r.Name__c);
					}
				}
			} else {
				core_BaseInfo_v2.errorMessages.add('No active setup for your School. Please contact your administrator.');
			}
			
		}
		
		public cSchool_BaseInfo(Id SchoolId, boolean reporting, boolean section,String yearId){
			sectionMap = new Map <Id, Section__c>();
			sectionList = new List<Section__c>();
			reportingPeriodOptions = new List <SelectOption>();
			sectionOptions = new List <SelectOption>();
			
			
			activeSetup = core_BaseInfo_v2.schoolSetupsByYearMap.get(SchoolId).get(yearId);
			school = core_BaseInfo_v2.schoolMap.get(SchoolId);
			staff = core_SoqlUtils.getStaffDetails(core_BaseInfo_v2.staffSchoolMap.get(schoolId));
			if (activeSetup!=null){
				bStandardsBased = activeSetup.Standards_Based_Grading__c;
				//NYC functionality commented out, 8/20/2012 uncommented dPassingGrade, dFailingGrade
				//dPassingGrade = activeSetup.Passing_Grade_Threshold__c;
				dPassingGrade = activeSetup.On_Track_Threshold__c;
				dFailingGrade = activeSetup.Passing_Grade_Threshold__c;
				
				if(reporting){ 
					for (Time_Element__c t: core_SoqlUtils.getTimeElementsByTermGB(activeSetup.term__c)){
						reportingPeriodOptions.add(new SelectOption(t.Id, t.Name__c)); 
					}
				}
				
				if(section){
					if (core_BaseInfo_v2.yearSectionsMap.get(schoolId).get(activeSetup.Year__c)!=null){
						for (Section__c s: core_BaseInfo_v2.yearSectionsMap.get(schoolId).get(activeSetup.Year__c)){
							sectionMap.put(s.id, s);
							sectionList.add(s);
							sectionOptions.add(new SelectOption(s.id, s.name));
						}
					}
					else{
						core_BaseInfo_v2.errorMessages.add('No sections for school year: '+activeSetup.Year__r.Name__c);
					}
				}
			} else {
				core_BaseInfo_v2.errorMessages.add('No active setup for your School. Please contact your administrator.');
			}
			
		}
	}
}