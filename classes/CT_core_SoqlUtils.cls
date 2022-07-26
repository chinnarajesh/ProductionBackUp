global class CT_core_SoqlUtils {
	public static final String ENROLLMENTTRACKINGREFERENCE = 'MM/dd/yyyy\'T\'HH:mm:ss';
	public static Account dummyAccount;
	public static Id staticSetupId;
	public static string plValueType;
	public static Map <String, Picklist_Value__c> plValueMap;
	public static Map<String, Map<String, Id>> rtMap ;
	public static Map <Id, Time_Element__c> timeElementMap ; 
	public static Map <Id, Setup__c> schoolActiveSetupMap;
	public static User loggedInUser;
	public static Map <Id, Map <String, List <Picklist_Value__c>>> masterPlValueMap;
	public static Map <String, StaticResource> csvStaticResourceMap;
	public static Set<String> sectionIds;
	
	public static void processStaticResourceMap(){
		csvStaticResourceMap = new Map <String, StaticResource>();
		for (StaticResource sr: [Select s.Name, s.Id, s.Body From StaticResource s ]){
			csvStaticResourceMap.put(sr.name, sr);
		}
	}

	public static String[] processCSVFile(String fileName){
		// if (csvStaticResourceMap==null) core_soqlUtils.processStaticResourceMap();
	StaticResource sr = [Select s.Name, s.Id, s.Body From StaticResource s where name =:fileName];
	blob tempBlob = sr.Body;
	String tempString = tempBlob.toString();
	tempString = tempSTring.replace('"', '');
	String[] stringArray = tempString.split('\n');
	return stringArray;
	} 
	
	public static User getLoggedInUser(){
		if (loggedInUser==null){
			loggedInUser = [select Id, firstname, lastname, email, Extension, Title, ManagerId, Phone, Street
								,City, State, PostalCode, Country, Department, school__c
							from User 
							where id=:UserInfo.getUserId()];
		}
		return loggedInUser;
	}
	
	public static List<Time_Element__c> getTeList(){
		List<Time_Element__c> teList = new List<Time_Element__c>();
		try{
			teList = [SELECT Reporting_Period_Value__r.name, Reporting_Period_Value__c
							,Name__c , Days_of_Week__c , StartTime__c , EndTime__c
							,Reporting_Period__c, Allow_Periods__c, t.Picklist_Value__r.Name
							,t.Picklist_Value__r.Level__c, t.Type__c, t.SystemModstamp
							,t.Start_Time__c, t.School__c, t.Reference_Id__c
							,t.Parent_Time_Element__c, t.OwnerId, t.Number__c, t.Name
							,t.LastModifiedDate, t.LastModifiedById, t.IsDeleted, t.Id
							,t.End_Time__c, t.End_Date__c ,t.Date_Start_Date__c
							,t.Name_On_Report_Card__c 
					FROM Time_Element__c t
					WHERE picklist_value__r.RecordType.Name = 'Time'];
		} catch (Exception e){
		}
		return teList;
	}
	
	public static Map<Id, Time_Element__c> getTeMap (){
		timeElementMap = new Map <Id, Time_Element__c>();
		for (Time_Element__c te: CT_Core_SoqlUtils.getTeList()){
			timeElementMap.put(te.id, te);
		}
		return timeElementMap;
	}
		
	public static Map<Id, Time_Element__c> getTeMap (String sType){
		timeElementMap = new Map <Id, Time_Element__c>();
		for (Time_Element__c te: CT_Core_SoqlUtils.getTeList()){ 
			if (sType==te.picklist_value__r.name){
				timeElementMap.put(te.id, te);
			}
		}
		return timeElementMap;
	}
	
	public static List <Time_Element__c> getTimeElementsByTerm(Id TermId, boolean bReportingPeriod){
		List<Time_Element__c> termList = getTimeElementsByTerms(new List<Id>{TermId}, bReportingPeriod);
		return termList;
	}

	public static List <Time_Element__c> getTimeElementsByTerms(List<Id> termIds, boolean bReportingPeriod){
		List<Time_Element__c> teList = [SELECT t.Days_of_Week__c , t.Reporting_Period_Value__r.name,t.Parent_Time_Element__r.Name__c
				,t.Reporting_Period_Value__c, t.Name__c, t.StartTime__c, t.EndTime__c,t.CreatedById
				,t.Reporting_Period__c, t.Allow_Periods__c, t.Picklist_Value__r.Name
				,t.Picklist_Value__r.Level__c, t.Type__c, t.SystemModstamp
				,t.Start_Time__c, t.School__c, t.Reference_Id__c
				,t.Parent_Time_Element__c, t.OwnerId, t.Number__c, t.Name
				,t.LastModifiedDate, t.LastModifiedById, t.IsDeleted, t.Id
				,t.End_Time__c, t.End_Date__c, t.Date_Start_Date__c
				,Name_On_Report_Card__c,
				(SELECT Id, Setup__c, Setup__r.School__r.Site__c
				FROM Terms__r)
		FROM Time_Element__c t
		WHERE parent_time_element__c IN : termIds
		ORDER BY date_start_date__c asc];
		List <Time_Element__c> termList = new List <Time_Element__c>();

		for(Time_Element__c t: teList){
			if (bReportingPeriod == null){
				termList.add(t);
			} else if (bReportingPeriod == t.Reporting_Period__c){
				termList.add(t);
			}
		}
		return termList;
	}
	
	//need date specification for report card
	public static List <Time_Element__c> getTimeElementsByTerm (Id TermId, boolean bReportingPeriod, Date startDate){
		List<Time_Element__c> teList = [Select Days_of_Week__c, Reporting_Period_Value__r.name
												,Reporting_Period_Value__c, Name__c, StartTime__c, EndTime__c
												,Reporting_Period__c, Allow_Periods__c, t.Picklist_Value__r.Name
												,t.Picklist_Value__r.Level__c, t.Type__c, t.SystemModstamp
												,t.Start_Time__c, t.School__c, t.Reference_Id__c
												,t.Parent_Time_Element__c, t.OwnerId, t.Number__c, t.Name
												,t.LastModifiedDate, t.LastModifiedById, t.IsDeleted, t.Id
												,t.End_Time__c, t.End_Date__c, t.Date_Start_Date__c, t.CreatedDate
												,Name_On_Report_Card__c 
											From Time_Element__c t
											where parent_time_element__c =:TermId
											and Date_Start_Date__c <= :startDate
											order by date_start_date__c asc];
		List <Time_Element__c> termList = new List <Time_Element__c>();
		
		for(Time_Element__c t:teList){
			if (bReportingPeriod ==null){
				termList.add(t);
			} else if (bReportingPeriod==t.Reporting_Period__c){
				termList.add(t);
			}
		}
		return termList;
	}
	
	public static List <Time_Element__c> getTimeElementsByTermGB (Id TermId){
		List <Time_Element__c> teList = new List <Time_Element__c>();
		Set<ID> parentIDSet = new Set<ID>();
		for(Time_Element__c t:[ Select Id, Name__c, Reporting_Period__c, Date_Start_Date__c, End_Date__c, type__c
								From Time_Element__c t
								where parent_time_element__c =:TermId
								AND Reporting_Period__c = true
								order by date_start_date__c asc]){
			
			teList.add(t);
			parentIDSet.add(t.Id);
		} 
		for(Time_Element__c t:[select Id, Name__c, Reporting_Period__c, Date_Start_Date__c, End_Date__c, type__c
							From Time_Element__c t 
							where parent_time_element__c IN :parentIDSet
							order by date_start_date__c asc]){ 
			teList.add(t); 
		} 
		
		return teList; 
	}
	
	public static Time_Element__c getTimeElementById (Id teId){
		Time_Element__c te = [Select Days_of_Week__c, Reporting_Period_Value__r.name, Reporting_Period_Value__c
									,Name__c, StartTime__c, EndTime__c, Reporting_Period__c, Allow_Periods__c
									,t.Picklist_Value__r.Name, t.Picklist_Value__r.Level__c, t.Type__c
									,t.SystemModstamp, t.Start_Time__c, t.School__c, t.Reference_Id__c
									,t.Parent_Time_Element__c, t.OwnerId, t.Number__c, t.Name, t.LastModifiedDate
									,t.LastModifiedById, t.IsDeleted, t.Id, t.End_Time__c, t.End_Date__c
									,t.Date_Start_Date__c, t.CreatedDate, t.CreatedById, Name_On_Report_Card__c
							From Time_Element__c t
							where id = :teId ];
		return te;
	}
	
	public static List<String> getRecentThreeYears(){
		List<String> te = new List<String>();
		
		for(Time_Element__c t: [SELECT Id From Time_Element__c t where t.New_School_Year__c = false AND t.Parent_Time_Element__c = null 
						AND t.Picklist_Value__r.Name ='Year'
						order by t.Date_Start_Date__c desc LIMIT 3]){ 	
			te.add(t.id);
							
		}
		return te;
	}
	
	public static Map<String,Map<String,Setup__c>> getRecentSchoolSetups(List<String> years, Set<Id> schools){
		Map<String,Map<String,Setup__c>> schoolSetupsByYearMap = new Map<String,Map<String,Setup__c>>();
		for(String school: schools){
			schoolSetupsByYearMap.put(school, new Map<String,Setup__c>());
		}
		//NYC DE1839/US1989 Do Not Show in Portal: added teh School_Using_PGV__c field to the query
		for(Setup__c s: [SELECT Active__c ,room_dependent__c, Configure_Course_Catalog__c, configure_grade_scale_catalog__c, year_start__c, year_end__c, year__r.name, Standards_Based_Grading__c, term__c, term__r.Name, term__r.Name__c, Show_Attendance_Sections_in_Gradebook__c, Published__c, Grade_scale_Catalog__c, Course_Catalog__c, On_Track_Threshold__c, Passing_Grade_Threshold__c, Behavior_Referal_Details__c, Standards_ONLY_Gradebook__c, Group_Based__c, New_School_Year__c, Students_Created_From_Previous_Year__c, Use_Sectional_Attendance__c, Grade_Span__c, Data_Activated__c, Id ,School__c,Year__c,Year__r.Name__c,School__r.Name, School_Using_PGV__c FROM Setup__c WHERE Year__c in: years AND School__c in: schools AND New_School_Year__c = false]){
				schoolSetupsByYearMap.get(s.School__c).put(s.Year__c,s);
		}
		
		return schoolSetupsByYearMap;
	}
	
	public static Schedule_Template__c getTemplateById(Id tempId){
		Schedule_Template__c st = [select reporting_period__c, Start_Time__c, end_Time__c, start_time_text__c, id
										,is_master__c, setup__c, name, color__c, has_class__c, End_Time_Text__c 
								from Schedule_Template__c 
								where id=:tempId];
		return st;
	}
	
	public static Map <Id, Setup__c> getActiveSetups(Set<Id> SchoolId){
		if(schoolActiveSetupMap == null || !schoolActiveSetupMap.keySet().containsAll(schoolId)){
			schoolActiveSetupMap = new Map<Id, Setup__c>();

			String query = 
				'select room_dependent__c, Configure_Course_Catalog__c , configure_grade_scale_catalog__c, id,year_start__c, year_end__c,'+
					'School__c,year__c, year__r.name,year__r.name__c,year__r.Date_Start_Date__c,year__r.End_Date__c,Standards_Based_Grading__c,'+
					'term__c, term__r.Name,Show_Attendance_Sections_in_Gradebook__c, Term__r.Name__c, Published__c ,Grade_scale_Catalog__c,'+
					'Course_Catalog__c,On_Track_Threshold__c, Passing_Grade_Threshold__c, Behavior_Referal_Details__c, Standards_ONLY_Gradebook__c,'+
					'Group_Based__c,New_School_Year__c,Year__r.Previous_Year__c,Students_Created_From_Previous_Year__c,'+
					'Use_Sectional_Attendance__c,Grade_Span__c,Data_Activated__c , School__r.Name, School_Using_PGV__c, School__r.Reference_ID__c'+
				' from Setup__c'+
				' where Active__c= true';

			if(schoolID != null && !schoolId.isEmpty()){
				query += ' and School__c=:schoolId';
			}
			for (Setup__c s: Database.query(query)){
				schoolActiveSetupMap.put(s.School__c, s);
			}
		}
		return schoolActiveSetupMap;
	}
	
	public static Setup__c getSetupBySchoolYear(Id SchoolId,Id Year){
		
	List<Setup__c> setups = [select room_dependent__c, Configure_Course_Catalog__c , configure_grade_scale_catalog__c, id
								,year_start__c, year_end__c, School__c, year__c, year__r.name,year__r.name__c
								,Standards_Based_Grading__c, term__c, term__r.Name
								,Show_Attendance_Sections_in_Gradebook__c
								,term__r.Name__c, Published__c ,Grade_scale_Catalog__c, Course_Catalog__c
								,Passing_Grade_Threshold__c, Behavior_Referal_Details__c, Standards_ONLY_Gradebook__c
								,Group_Based__c,New_School_Year__c,Year__r.Previous_Year__c,Students_Created_From_Previous_Year__c,
								Use_Sectional_Attendance__c,Grade_Span__c,Data_Activated__c , School__r.Name
						from Setup__c 
						where School__c=:SchoolId
						and Year__c = :Year];
	if(setups != null) 
			return setups[0];
	else
			return null;
	}
	
	public static Map <String,Setup__c> getTermSetupsBySchool(String schoolId){
		Map<String, Setup__c> termSetupMap = new Map<String, Setup__c>();
		for (Setup__c s: [select room_dependent__c, Configure_Course_Catalog__c , configure_grade_scale_catalog__c, id
								,year_start__c, year_end__c, School__c, year__c, year__r.name,year__r.name__c
								,Standards_Based_Grading__c, term__c, term__r.Name
								,Show_Attendance_Sections_in_Gradebook__c
								,term__r.Name__c, Published__c ,Grade_scale_Catalog__c, Course_Catalog__c
								,Passing_Grade_Threshold__c, Behavior_Referal_Details__c, Standards_ONLY_Gradebook__c
								,Group_Based__c,Active__c,Use_Sectional_Attendance__c,Data_Activated__c
						from Setup__c 
						where School__c=:SchoolId
						]){
			termSetupMap.put(s.Term__c, s);
		}
		return termSetupMap;
	}

	//US1238: non-average standard calculation type: added calculation type to query
    public static Setup__c getSetupById(String SetupId) {
        return getSetupByIds(new Set<Id>{SetupId})[0];
    }

    public static List<Setup__c> getSetupByIds(Set<Id> sIds){
        List<Setup__c> setups = [Select Year__c, Year_Start__c, Year_End__c, Year__r.Date_Start_Date__c, Year__r.End_Date__c, Use_Sectional_Attendance__c, Term__c,
								Summarized_Data__c, Students_Created__c, Strand_Grade_Mastery_Percentage__c, Standards_ONLY_Gradebook__c, Term__r.Name__c, 
								Standards_Based_Grading__c, Standard_Grade_Mastery_Threshold__c, Show_Standards_in_Portal__c, Show_Meals_in_Portal__c,
								Show_Gradebook_in_Portal__c, Show_Calendar_in_Portal__c, Show_Behavior_in_Portal__c, Show_Awards_in_Portal__c,
								Show_Attendance_in_Portal__c, Show_Attendance_Sections_In_Gradebook__c, Show_Alerts_in_Portal__c, Section_Wizard__c, 
								School_picture__c, School__c, School_Calendar__c, Room_Dependent__c, RecordTypeId, Purged_Two_Years_Old_Data__c, 
								Purged_EOY_Data__c, Published__c, Processed_Setup_Data__c, Processed_Historical_Data__c, Processed_EOY_Data__c,
								Passing_Grade_Threshold__c, OwnerId, New_School_Year__c, Year__r.Previous_Year__c,Name, 
								Law_of_Decaying_Average_Weight__c, LastModifiedDate, LastModifiedById, IsDeleted, Id, Group_Based__c, Grade_Span__c,
								Grade_Scale_Catalog__c, External_Id__c, Evaluation_Documents__c, CreatedDate, CreatedById, Course_Catalog__c, 
								Configure_School_Term__c, Configure_Grade_Scale_Catalog__c, Configure_Course_Catalog__c, Chronological_Periods__c, 
								Cascade_Daily_Attendance__c, Calculation_Type__c, Show_Class_Rank__c, Behavior_Referal_Details__c, Active__c,
								School__r.Reference_Id__c, Year__r.Name__c, School__r.Name, Display_GPA_on_Report_Cards__c, Display_Weighted_GPA_on_Documents__c, 
								Show_Sectional_Attendance_on_Report_Card__c,Display_Incomplete_Assignments__c,Calculate_Class_Rank__c, 
								Term__r.Reporting_Period_Value__r.Name, Year__r.Name, term__r.Name,School__r.Room_Count__c,School__r.Room_Capacity__c,
								Standard_Legend_Description_1__c,Standard_Legend_Description_2__c,Standard_Legend_Description_3__c,Standard_Legend_Description_4__c,
								Standard_Legend_Description_1_Spanish__c,Standard_Legend_Description_2_Spanish__c, Standard_Legend_Description_3_Spanish__c,
								Standard_Legend_Description_4_Spanish__c,On_Track_Threshold__c,GPA_By_Reporting_Period_Rolling__c, School__r.ParentId,
								CEEB_Code__c,Registrar__c,Registrar_Phone__c,Counselor__c, School__r.RecordType.Name, Display_Cumulative_Weighted_GPA__c,
								Show_Normalizations_on_Report_Cards__c,Display_Legend_on_Report_Cards__c, Show_Section_Comments__c, 
								Show_Semester_Grades_On_Report_Cards__c, Display_Reading_Level_On_Report_Card__c,Show_Homework_Percentage__c,
								Include_Section_Grades__c ,Progress_Report_Standard_Display__c,Report_Card_Standard_Display__c,Term__r.Date_start_date__c,
								Term__r.End_date__c,Data_Activated__c,Points_Frequency__c,Points_Reset_Date__c,Points_Reset_Value__c,Days__c,
								Schedule_Start_Date__c,Schedule_End_Date__c, Standard_Legend_1__c , Standard_Legend_1_Spanish__c, Standard_Legend_2__c, 
								Standard_Legend_2_Spanish__c, Standard_Legend_3__c, Standard_Legend_3_Spanish__c, Standard_Legend_4__c,
								Standard_Legend_4_Spanish__c, Standard_Legend_Text__c, Standard_Legend_Text_Spanish__c, Show_class_Rank_on_Transcripts__c,
								Show_Assessments_on_Transcripts__c,Show_Activities_on_Transcripts__c,Show_Honors_on_Transcripts__c,
								Show_Notes_on_Transcripts__c,Notes_on_Transcripts__c,Show_Signature_on_Transcripts__c, Use_1st_Reporting_Period_Start_Date_RC__c,
								Rolling_Standard_Grade__c, Read_Only_Attendance_Wizard_Records__c, Rejection_Reason__c, SystemModstamp, Verification_Status__c,
								Display_Community_Service_Hours__c, Show_Standard_Grades__c, Show_Standard_Scale_on_Report_Cards__c, ActivateRelated__c
							FROM Setup__c s
						WHERE Id IN :sIds];
		return setups;
	}
	
	public static List<Setup__c> getOrgActiveSetups(){
		List<Setup__c> setups = new List<Setup__c>();
		setups = [Select id, School__c, School__r.Name,Data_Activated__c from Setup__c where Active__c = true and School__c != null order by School__r.Name desc];
		return setups;
	}

	public static String getErrorMessageByName(String sName){ 
		ErrorMessages__c e = ErrorMessages__c.getInstance(sName);
		return e.Message__c;
	}
	
	public static Map<String, Id> getRecordTypesBySobject(String sObjectName){
		if (CT_core_SoqlUtils.rtMap == null ){
			CT_core_SoqlUtils.rtMap = new Map<String, Map<String, Id>>();
		}

		if(!CT_core_SoqlUtils.rtMap.containskey(sObjectName)){
	        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(sObjectName);
    	    if(sObjType == null){ return new Map<String, Id>(); }
        	Map<String,Schema.RecordTypeInfo> recordTypeInfo = sObjType.getDescribe().getRecordTypeInfosByDeveloperName();//getRecordTypeInfosByName();
        	Map<String, Id> mapSObjectRTDevNames = new Map<String, Id>();
        	for(recordTypeInfo rti: recordTypeInfo.values()){
        		if(rti.isActive() && String.isNotBlank(rti.getName())){
        			mapSObjectRTDevNames.put(rti.getDeveloperName(), rti.getRecordTypeId());
        		}
        	}
        	rtMap.put(sObjectName, mapSObjectRTDevNames);
        }
        
		return CT_core_SoqlUtils.rtMap.get(sObjectName);

		//if (CT_core_SoqlUtils.rtMap == null){
		//	CT_core_SoqlUtils.rtMap = new Map<String, Map<String, Id>>();
		//	for (RecordType rt: [SELECT id, Name, DeveloperName , sObjectType
		//						FROM RecordType 
		//						WHERE Name!=null
		//						AND IsActive = true]){
		//	string tempSObjectName = rt.sObjectType;
		//		if (rt.sObjectType.contains('SchoolForce')){
		//			tempSObjectName = rt.sObjectType.replace('SchoolForce__','');
		//		}
		//		if (CT_core_SoqlUtils.rtMap.get(tempSObjectName)==null){
		//			Map <String, Id> initMap =new Map<String, Id>();
		//			initMap.put(rt.DeveloperName, rt.Id);
		//			CT_core_SoqlUtils.rtMap.put(tempSObjectName, initMap);
		//		}
		//		else {
		//			CT_core_SoqlUtils.rtMap.get(tempSObjectName).put(rt.DeveloperName, rt.Id);
		//		} 
		//	}
		//}
		//return CT_core_SoqlUtils.rtMap.get(sObjectName);
	}

	public static Id getRecordTypeIdBySobject(String objectAPIName, String recordTypeName){
        Schema.SObjectType sObjType = Schema.getGlobalDescribe().get(objectAPIName);
        if(sObjType == null){ return null; }
        Schema.DescribeSObjectResult cfrSchema = sObjType.getDescribe();
        Map<String,Schema.RecordTypeInfo> recordTypeInfo = cfrSchema.getRecordTypeInfosByName();
        return recordTypeInfo.containsKey(recordTypeName)? recordTypeInfo.get(recordTypeName).getRecordTypeId(): null;
    }

    public static Map<String, String> getPicklistValues(String objectAPIName, String fieldname){
		Map<String, String> lstPickvals = new Map<String, String>();
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectAPIName);
		if(targetType == null){ return lstPickvals; }
		Schema.DescribeSObjectResult sobject_describe = targetType.getDescribe(); //describe the sobject
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
		List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldname).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
		for(Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
			lstPickvals.put(a.getValue(), a.getLabel());//add the value  to our final list
		}
 		return lstPickvals;
	}
    
    public static List<String> getPicklistValuesBySobject(String objectAPIName, String fieldname){
		return new List<String>(getPicklistValues(objectAPIName, fieldname).keySet());
    }
    
    public static String getPicklistDefaultValue(String objectAPIName, String fieldname){
		String plValue = '';
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectAPIName);
		if(targetType == null){ return plValue; }
		Schema.DescribeSObjectResult sobject_describe = targetType.getDescribe(); //describe the sobject
		Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
		List<Schema.PicklistEntry> pick_list_values = field_map.get(fieldname).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
		for(Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            if( a.isDefaultValue() ){
                plValue = a.getValue();
            }
		}
 		return plValue;
	}    

	public static List<User> getUsersByIds(Set<Id> UserIds){
		List <User> userList = new List <User>();
		for (User u: [SELECT Id, firstname, lastname, email, Extension, Title, ManagerId, Phone, Street, City, State, PostalCode, Country , Department,School__c
					FROM User 
					WHERE Id IN :userIds]){
			userList.add(u);
		}
		return userList;
	}
	
	public static Account getDummyOrganization(){
		Account a = dummyAccount;
		if (a==null){
			for (Account acct: [SELECT id from Account where RecordType.Name ='Individuals']){
				a=acct;
			}
			if (a==null){
				Account acct = new Account(Name='Individuals', RecordTypeId=getRecordTypesBySobject('Account').get('Individuals'));
				try {
					insert acct;
					a=acct;
				}
				catch (exception e){
				}
			}
			dummyAccount=a;
		}
		return a;
	}
	
	public static Contact getLoggedInContact(){
		try {
			Contact contact = [select id, name from Contact where user__c =:userInfo.getUserId() limit 1];
			return contact; 
		} 
		catch (exception e){
			return null;
		}
	}
	public static Map<String, Contact> getContactsByExternalId(String[] ReferenceIds){
		Map <String, Contact> contactMap = new Map<String, Contact>();
		for (Contact c: [select id, reference_Id__c 
						FROM Contact
						WHERE reference_Id__c in :ReferenceIds]){
			contactMap.put(c.reference_Id__c, c); 
		}
		return contactMap;
	}
	
	public static Map<Id, Account> getSchoolMap (Set<Id> schoolIds ){
		Map<Id, Account> schoolStaffMap = new Map<Id, Account>();
		for (Account s: [select id, name, school_full_name__c, reference_Id__c from Account where id in :schoolIds]){
			schoolStaffMap.put(s.id, s);
		}
		return schoolStaffMap;
	}
	
	public static Map <Id, List <Section__c>> getSectionsbyStaffMap(Set <Id> staffIds){
		Map <Id, List <Section__c>> staffSectionMap = new Map <Id, List <Section__c>>();
		sectionIds = new Set<String>();
		
		for(Staff_Section__c ss:
				[select id,Section__r.Staff__c, Section__r.Reference_ID__c, section__r.Active__c, section__r.Homeroom__c, section__r.Advisory__c, 
					Section__r.Course__c, Section__r.Description__c, Section__r.Daily_Attendance__c, Section__r.Course__r.Name, Section__r.Course__r.Type__c, 
					Section__r.Course__r.Grade_Scale__c, Section__r.Of_Students__c , Section__r.Period__c , Section__r.Section__c, Section__r.Has_homework__c,
					Section__r.Section__r.Name, Section__r.Is_Section__c, Section__r.Room__c , Section__r.Name, Section__r.Grade_Level__c, Section__r.All_Grades__c,
					Section__r.Record_Attendance__c, Section__c, Staff__c,Section__r.Course__r.Grade_Scale_Lookup__r.Category__c,
					Section__r.Course__r.Grade_Scale_Lookup__r.Name, Section__r.Course__r.Use_Assignment_Type_Percentages__c 
				from Staff_Section__c ss 
				where Section__r.Is_Section__c = true 
				AND Staff__c in :staffIds
				AND Section__r.RecordType.Name = 'Published'
				order by Section__r.Course__r.Name, Section__r.Name]){
			if(staffSectionMap.get(ss.Staff__c)==null){
				staffSectionMap.put(ss.Staff__c, new List <Section__c>{ss.Section__r});
			} else {
				staffSectionMap.get(ss.Staff__c).add(ss.Section__r);
			} 
			sectionIds.add(ss.Section__c);
		}
		return staffSectionMap;
	}
	
	public static Map<String,Map<String,List<Section__c>>> getSectionsbyYear(Set<Id> schools,List <Id> staffIds,List<String> recentYears){
		Map<String,Map<String,List<Section__c>>> schoolSectionsByYearMap = new Map<String,Map<String,List<Section__c>>>();
		for(String school: schools){
			schoolSectionsByYearMap.put(school, new Map<String,List<Section__c>>());
		}
		for(Setup__c s: [SELECT Active__c ,room_dependent__c, Configure_Course_Catalog__c, configure_grade_scale_catalog__c, 
						year_start__c, year_end__c, year__r.name, Standards_Based_Grading__c, term__c, term__r.Name, 
						term__r.Name__c, Show_Attendance_Sections_in_Gradebook__c, Published__c, Grade_scale_Catalog__c,
						Course_Catalog__c, Passing_Grade_Threshold__c, Behavior_Referal_Details__c, Standards_ONLY_Gradebook__c, 
						Group_Based__c, New_School_Year__c,Year__r.Previous_Year__c,Students_Created_From_Previous_Year__c, Use_Sectional_Attendance__c, 
						Grade_Span__c, Data_Activated__c, Id ,School__c,Year__c,Year__r.Name__c,School__r.Name FROM Setup__c 
						WHERE Year__c in: recentYears AND School__c in: schools AND New_School_Year__c = false ]){  //AND Year__r.Previous_Year__c = false
				schoolSectionsByYearMap.get(s.School__c).put(s.Year__c,new List<Section__c>());
		}
		
		Map <String, List <Section__c>> termSectionMap = new Map <String, List <Section__c>>();
	for(Staff_Section__c ss : [select id,Section__r.Staff__c, Section__r.Reference_ID__c, section__r.active__c, section__r.Homeroom__c, 
								section__r.Advisory__c, Section__r.Course__c, Section__r.Description__c, Section__r.Daily_Attendance__c, 
								Section__r.Course__r.Name, Section__r.Course__r.Type__c, Section__r.Course__r.Grade_Scale__c, Section__r.of_Students__c , Section__r.Period__c , Section__r.Section__c, Section__r.has_homework__c,
								Section__r.Section__r.Name, Section__r.Is_Section__c, Section__r.Room__c , Section__r.Name, section__r.Time__c, Staff__r.Organization__c,
								Section__r.Record_Attendance__c , section__c, Staff__c,Section__r.Reporting_Period__r.Parent_Time_Element__c,Archived__c,Is_Active__c
								from Staff_Section__c ss 
								where (Section__r.Is_Section__c = true 
									AND Staff__c in :staffIds 
									AND Section__r.Time__c in: recentYears
									AND Section__r.RecordType.Name = 'Published'
									AND ((Archived__c = false AND Is_Active__c = true) 
									OR (Archived__c = true AND Is_Active__c = false))) 
								order by Section__r.Reporting_Period__r.Parent_Time_Element__c,Section__r.Name]){
									
					schoolSectionsByYearMap.get(ss.Staff__r.Organization__c).get(ss.Section__r.Time__c).add(ss.Section__r);
				
			}
		return schoolSectionsByYearMap; // return the list of sections for a term
	}
	
	public static List<Schedule_Group__c> getGroupsBySetupId(Id SetupId){
		List<Schedule_Group__c> groupList = 
		[select id, name, Description__c, Grade_Level__c, All_Grades__c from Schedule_Group__c
								where setup__c =:SetupId
								///and school__c=:SchoolId
								];
	return groupList;
	}
	
	public static List<Student__c> getStudentsInGroup(string selectedGroupId){
		List <Student__c> studentList=
		[select id, name, Race__c, IEP__c, ELL__c,Grade__c, Gender__c, Special_Ed__c
																		from Student__c 
																		where schedule_Group__c =:selectedGroupId
																			and Active__c = true];
		
		
		return studentList;
	}
	
	
		public static List<Student__c> getStudentsInGroup(string gradeLevel, Id SchoolId){
			String[] grades = gradeLevel.split(';');
			List <Student__c> studentList=
				[select id, name, Race__c, IEP__c, ELL__c,Grade__c, Gender__c, Special_Ed__c from Student__c 
				where School__c =:SchoolId
				and schedule_Group__c =null
				and Active__c = true
				and grade__c IN :grades];
			return studentList;
	}
	
	public static Schedule_Group__c getGroupById (Id GroupId){
		Schedule_Group__c sect = [select id, Setup__c , name, grade_level__c, all_grades__c, description__c from Schedule_Group__c where id =:GroupId];
		return sect;
	}
	
	public static Section__c getSectionById (Id SectionId){
		Section__c sect = [select id, name,name_spanish__c, grade_level__c, all_grades__c, description__c, school__c, time__c from Section__c where id =:SectionId and RecordType.Name='Schedule Group'];
		return sect;
	}
	
	/* From SchoolForce Utility Class*/
	public static List<Section__c> getSectionListforContact (ID contactId) {
		List<Section__c> sectList = new List<Section__c>();
		Set<ID> SectIDs = new Set<ID>();
		Id staff_ID;
		for (Staff__c ss: [SELECT id, organization__c, Id__c
									FROM Staff__c 
									WHERE individual__c=:contactId limit 1]){
			staff_ID=ss.id; 
		} //PTN placeholder to get the first staff_school record, will build out multi schools later
		for(Staff_Section__c ss : [select id, section__c, Staff__c from Staff_Section__c where Staff__c = :staff_ID]){
			SectIDs.add(ss.section__c);
		}
		for (Section__c sect: [SELECT s.Staff__c, s.Name, s.Id, of_Students__c, Record_Attendance__c 
								FROM Section__c s 
								WHERE s.Id IN :SectIDs ]){
			sectList.add(sect); 
		}
		return sectList; // return the list of sections for the staff member
	}
	
	//Summer 2014 iteration 3 - US3605: added Home_Language to query
	public static List<Student__c> getStudentById(Id stuId) {
		List<Student__c> stuList = new List<Student__c>(); 
		try {
			stuList = [Select Id, Name, Grade__c,Grade_Name__c, School__c , Address__c, City__c, State__c, Zip_Code__c
							,Student_First_Name__c, Student_Last_Name__c, Student_Id__c, Legacy_Id__c
							,Final_GPA_Value__c, Reading_Level_Q1__c, Reading_Level_Q2__c, Reading_Level_Q3__c
							,Reading_Level_Q4__c, Alternate_Language__c, School_Year__r.Name__c, Setup__c, Individual__c
								,Today_s_Points_Balance__c,Student_Picture__c, setup__r.term__c, current_gpa__c, Home_Language__c
						From Student__c 
						where Id = :stuId];
		} catch(Exception ex) {
		}
		return stuList; 
	}
	
	public static List<Student__c> getStudents(Set<String> stuIds) {
		List<Student__c> stuList = new List<Student__c>(); 
		try {
			stuList = [Select Id, Name, Grade__c,Grade_Name__c, School__c , Address__c, City__c, State__c, Zip_Code__c
							,Student_First_Name__c, Student_Last_Name__c, Student_Id__c, Legacy_Id__c
							,Final_GPA_Value__c, Reading_Level_Q1__c, Reading_Level_Q2__c, Reading_Level_Q3__c
							,Reading_Level_Q4__c, Alternate_Language__c, School_Year__r.Name__c, Setup__c, Individual__c
							,Today_s_Points_Balance__c,Student_Picture__c, Setup__r.Points_Reset_Date__c, Setup__r.Points_Reset_Value__c
							,Setup__r.Term__r.Date_Start_Date__c
						From Student__c 
						where Id in :stuIds];
		} catch(Exception ex) {
		}
		return stuList; 
	}
	public static Staff__c getStaffDetails(Id staffRecId) {
		try{
			Staff__c staff = [Select s.Name, s.Id, s.Email__c, s.Staff_Email__c From Staff__c s Where s.Id =: staffRecId];
			return staff;
		} catch(Exception ex) {
			return null;
		}
	}
	
	public static List<Staff__c> getContactStaffList(Id ContactId){
		List<Staff__c> staffList = new List<Staff__c>();
		try{
			staffList = [Select id, Organization__c, Organization__r.Name, Name,
							(Select id, Section__r.Name, Section__c 
							from Staff_Section__r 
							where Section__r.RecordType.DeveloperName='Published')
						From Staff__c
						Where Individual__c=:ContactId];
		} catch (Exception ex){
		}
		return staffList;
	}
	
	public static List<Staff__c> getActiveStaffForContact(Id ContactId){
		List<Staff__c> staffList = new List<Staff__c>();
		try{
			staffList = [Select id, Organization__c, Organization__r.Name
						From Staff__c
						Where Individual__c=:ContactId
						AND Active__c = true];
		} catch (Exception ex){
		}
		return staffList;
	}
	
	public static List<Staff__c> getStaffForContactBySchool(Id contactId,Id schoolId){
		List<Staff__c> staffList = new List<Staff__c>();
		try{
			staffList = [Select id, Organization__c, Organization__r.Name
						From Staff__c
						Where Individual__c=:ContactId
						AND Active__c = true
						AND Organization__c =: schoolId];
		} catch (Exception ex){
		}
	
			return staffList;	
	}
	// return a list of Select Options for sections given a list of sections
	public static List<SelectOption> SectOptionsList(List<Section__c> sList) {
		List<SelectOption> sectList = new List<SelectOption>(); 
		// loop through the sections and add them to the select options list
		for(Section__c s : sList) {
			sectList.add(new SelectOption(s.Id, s.Name));
		}
		//add the "none" value to the SelectOption to force the selection of a section
		sectList.add(new SelectOption('- None -', '- None -'));
		
		return sectList;// return the list of select options
	} 
	
	/* End of from Schoolforce Utility Class */
	
	/*From ELH pvmaptutility.cls */
	public static List <Picklist_Value__c> plValuesList;
	public static Map<Id, Picklist_Value__c> mPvalues;
	public static Map<String, Picklist_Value__c> mStringPvalues;
	public static Picklist_Value__c presentVal;
	
		
	public static Map <Id, Map<String, List <Picklist_Value__c>>> getMasterPlValues(){
			Map <Id, Map<String, List <Picklist_Value__c>>> localMasterPlvMap = new Map <Id, Map<String, List <Picklist_Value__c>>>();
			Map <Id, List <Picklist_Value__c>> nullsetupPlValues = new Map <Id, List <Picklist_Value__c>>();
			if (masterPlValueMap==null){
				for (Picklist_Value__c plv: [SELECT Setup__c, RecordTypeId, RecordType.Name, Corresponding_Value__c, Set_as_default__c, Number__c, Standard_Scale__c, Level__c
									,CreatedBy.FirstName, CreatedBy.LastName, Name, Display_Code__c, Short_Description__c
									,Internal_Code__c, Is_Tardy__c, Is_Early_Departure__c, Is_Suspension__c, Notify_Admin__c, Order__c, Id, Type__c
								FROM Picklist_Value__c]){
				if (localMasterPlvMap.get(plv.setup__c)==null){
					Map <String, List<Picklist_Value__c>> tempTypeMap = new Map <String, List<Picklist_Value__c>>();
					tempTypeMap.put(plv.recordType.name, new List <Picklist_Value__c>{plv});
					localMasterPlvMap.put(plv.setup__c, tempTypeMap);
				}
				else {
					if (localMasterPlvMap.get(plv.setup__c).get(plv.RecordType.Name)==null){
						localMasterPlvMap.get(plv.setup__c).put(plv.RecordType.Name, new List <Picklist_Value__c>{plv});
					}
					else localMasterPlvMap.get(plv.setup__c).get(plv.RecordType.Name).add(plv);
				}
			}
			masterPlValueMap=localMasterPlvMap;
			}
		return masterPlValueMap;
	}
		
	public static Map<Id,Picklist_Value__c> getPlValues(String recordType, String SetupId) {
		mPvalues = new Map<Id, Picklist_Value__c>();
		for(Picklist_Value__c pv: CT_core_SoqlUtils.getPlValuesList(recordType, SetupId)) {
			mPvalues.put(pv.Id,pv);
		}
		return mPvalues; 
	}
		
		/*public Static List<Picklist_Value__c> getPlValuesList(String stype, String SetupId) {
		plValuesList = new List<Picklist_Value__c>();
		try{
			if (masterPlValueMap==null) core_SoqlUtils.getMasterPlValues();
			if(masterPlValueMap.containsKey(null)){
				if(masterPlValueMap.get(null).containsKey(sType)) plValuesList.addAll(masterPlValueMap.get(null).get(sType));
			}
			system.debug(plValuesList);
			if(masterPlValueMap.containsKey(SetupId)){
				if(masterPlValueMap.get(SetupId).containsKey(sType)) plValuesList.addAll(masterPlValueMap.get(SetupId).get(sType));
			}
			system.debug(plValuesList);
		} catch (Exception e){
		}
		return plValuesList;
	}*/
	
	public Static List<Picklist_Value__c> getPlValuesList(String stype, String SetupId) {
		plValuesList = new List<Picklist_Value__c>();
		try{
			plValuesList = [SELECT Corresponding_Value__c, Set_as_default__c, Number__c, Standard_Scale__c, Level__c, Category__c, Setup__c
								,CreatedBy.FirstName, CreatedBy.LastName, Name, Display_Code__c, Short_Description__c, Long_Description__c
								,Internal_Code__c, Is_Unexcused__c, Is_Tardy__c, Is_Early_Departure__c, Is_Suspension__c, Notify_Admin__c, Order__c, Id, Type__c
							FROM Picklist_Value__c
							WHERE RecordType.Name = :stype
							AND (setup__c = :SetupId or setup__c = null)
							order by order__c];
		} catch (Exception e){
		}
		return plValuesList;
	}
		
	public Static List<Picklist_Value__c> getPlValuesListByRecordType(String rtype,String SetupId) {
		plValuesList = new List<Picklist_Value__c>();
		try{
			plValuesList = [SELECT Corresponding_Value__c, Set_as_default__c, Number__c, Level__c, Id, Standard_Scale__c
									,CreatedBy.FirstName, CreatedBy.LastName, Name, Display_Code__c, Short_Description__c
									,Internal_Code__c, Behavior_Category__c, Incident_Involves_Weapon__c, Consequence_Weight__c
									,Behavior_Incident_Level__c, Is_Suspension__c, Notify_Admin__c, Order__c, Setup__c 
							FROM Picklist_Value__c 
							WHERE RecordTypeId = :rtype
							AND (setup__c = :SetupId or setup__c = null)
							order by order__c];
		} catch(Exception e){
		}
		return plValuesList;
	}
		public Static List<Picklist_Value__c> getScalesListByCatalog(String rtype,ID gradeScaleCatalogID) {
		plValuesList = new List<Picklist_Value__c>();
		try{
			
			for(Grade_Scale_Catalog_Scale__c gscs : [SELECT Picklist_Value__c, picklist_value__r.category__c, Picklist_Value__r.ID, Picklist_Value__r.Standard_Scale__c, Picklist_Value__r.Name 
							FROM Grade_Scale_Catalog_Scale__c 
							WHERE Grade_Scale_Catalog__c = : gradeScaleCatalogID]){
								plValuesList.add(gscs.Picklist_Value__r);
							}
		} catch(Exception e){
		}
		return plValuesList;
	}
	public Static List<Picklist_Value__c> getScalesListByCatalog(String rtype,Set<ID> gradeScaleCatalogID) {
		plValuesList = new List<Picklist_Value__c>();
		try{
			
			for(Grade_Scale_Catalog_Scale__c gscs : [SELECT Picklist_Value__c, picklist_value__r.category__c, Picklist_Value__r.ID, Picklist_Value__r.Standard_Scale__c, Picklist_Value__r.Name 
							FROM Grade_Scale_Catalog_Scale__c 
							WHERE Grade_Scale_Catalog__c IN : gradeScaleCatalogID]){
								plValuesList.add(gscs.Picklist_Value__r);
							}
		} catch(Exception e){	
		}
		return plValuesList;
	}
		public Static List<Picklist_Value__c> getPlValuesListID(String stype, ID SetupId) {
		plValuesList = new List<Picklist_Value__c>();
		try{
			plValuesList = [SELECT Setup__c, Corresponding_Value__c , Number__c, Set_as_default__c, Level__c, Id, Standard_Scale__c
									,CreatedBy.FirstName, CreatedBy.LastName, Name, Display_Code__c, Short_Description__c
									,Internal_Code__c, Behavior_Incident_Level__c, Is_Suspension__c, Notify_Admin__c, Order__c, Category__c
							FROM Picklist_Value__c
							WHERE RecordType.DeveloperName = :stype
							AND setup__c = :SetupId
							order by order__c];
		} catch(Exception e){
		}
		return plValuesList;
	}

		
	public static Map<String,Picklist_Value__c> getPlStringValues(String stype, String SetupId) {
		if (stype!=plValueType || setupId !=staticSetupId || plValueMap == null){
			staticSetupId = setupId;
			plValueType = stype;
			plValueMap = new Map<String, Picklist_Value__c>();
			for (Picklist_Value__c pv: CT_core_SoqlUtils.getPlValuesList(stype, setupId)){
				plValueMap.put(pv.Name,pv);
			}
		}
		return plValueMap;
	}
		
	public static Picklist_Value__c getDefaultAttendanceVal(String stype, Id setupId) {
		if (presentVal == null) {
			presentVal = [Select Id, Name 
						From Picklist_Value__c
						where recordType.name = :stype 
						AND Set_as_Default__c = true
						AND setup__c=:setupId
						limit 1];
		}
		return presentVal; 
	} 
	/*End ELH pvmaptutility.cls*/
	
	/*Start ELH SOQL Constant*/
	public static String ParentalNotifyOne; 
	public static String ParentalNotifyTwo; 
	public static String ParentalNotifyAbsentOne;
	
	private static String MainPGQuery = 'Select Student_c__r.FirstName, Student_c__r.LastName, Student_c__c, Student__c, Student__r.School__c, ' + 
			' Student__r.Student_Last_Name__c, ' + 
			' Parent_Guardian_c__r.Preferred_Language__c, Parent_Guardian_c__r.Notify_via_SMS__c, ' + 
			' Parent_Guardian_c__r.Notify_via_Email__c, Parent_Guardian_c__r.Email_to_SMS_Address__c, ' + 
			' Parent_Guardian_c__r.Email, Parent_Guardian_c__c, Id From Student_PG__c';
	
	public static String getMainPGQuery () {
		return MainPGQuery;
	}
	
	public static String getMainAbsentQuery (Date pdate, boolean bUnexcused) {
		MainAbsentQuery += ' AND Session_Date__c = '; 
		MainAbsentQuery += string.valueof(pDate);
		MainAbsentQuery += ' AND Daily__c = true';
		MainAbsentQuery +=' AND Picklist_Value__r.is_Unexcused__c ='+bUnexcused;
		return MainAbsentQuery;
	}
	
	public static String getMainTardyQuery (Date pdate, boolean bUnexcused) {
		MainTardyQuery += ' AND Session_Date__c = '; 
		MainTardyQuery += string.valueof(pDate);
		MainTardyQuery += ' AND Daily__c = true';
		MainTardyQuery +=' AND Picklist_Value__r.is_Unexcused__c ='+bUnexcused;
		return MainTardyQuery;
	}
			
	public static String MainAbsentQuery = 'Select Student__c, Daily__c, Status__c, Session_Date__c, ' + 
	' Instructional_Time_Lost__c From Attendance__c WHERE Picklist_Value__r.Category__c = \'Absent\' ';
 
	public static String MainTardyQuery = 'Select Student__c, Daily__c, Status__c, Session_Date__c, ' + 
	' Instructional_Time_Lost__c From Attendance__c where Picklist_Value__r.Is_Tardy__c = true ';
 
 public static String ParentalNotifyAbsentOne () {
		// look up the ID if we haven't already done it
		if ( ParentalNotifyAbsentOne == null ) {
			ParentalNotifyAbsentOne = MainAbsentQuery;
		if (test.isrunningtest()){
			ParentalNotifyAbsentOne += ' AND Student_c__r.LastName = \'BFCSTUD1\''; }
		}
		return ParentalNotifyAbsentOne;
	}
	
	//This is used by attendance and homework to send notifications
	global static Map<String, Map<String, String>> getnotifymap (String alerttype) {
		Map<String, Map<String, String>> mNotificationText = new Map<String, Map<String, String>> ();
		
		List<Value__c> values = 
			[Select Id, Language__c, Communication_Type__c, Text_Alert__c, Setup__r.School__c
			from Value__c 
			where Communication_Type__c != null 
			AND Type__c = :alerttype 
			order by Language__c, Communication_Type__c ASC];
		
		for (Value__c v: values) {
			Map<String, String> cmap;
			string notifyID = v.Language__c + v.Setup__r.School__c;
			if (mNotificationText.containskey(notifyID)) {
				cmap = mNotificationText.get(notifyID);
			} else {
				cmap = new Map<String, String>();
			}
			cmap.put(v.Communication_Type__c,v.Text_Alert__c);
			mNotificationText.put(notifyID, cmap);
		}
		return mNotificationText;
	}
	
	global static String getSearchName(String sName){
		String tempName = String.isNotBlank(sName)? sName: '';
		tempName = tempName.contains('*')? tempName.replace('*','%'): tempName + '%';
		return String.escapeSingleQuotes(tempName);
	}
}