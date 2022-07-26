global class  CT_core_triggerUtils {
	public static final String SECTIONEXITREASONBYTRIGGER = 'Deactivated by trigger.';	
	public static boolean bProcessAttendance = true;
	public static boolean b=false;
	public static boolean deactivate=false;
	public static boolean gradeDeletionAllowed = false;
	//assignment deleting vs. assignment editing
	public static boolean gradeStandardTrigger = false;
	public static boolean setupDataCloningEnabled = true;
	
	public static boolean scheduler=false;
	public static boolean calculateGrades = false;
	public static boolean gradeTrigger=false;
	public static boolean studentTrigger = true;
	public static boolean studSectionTrigger = true;
	public static boolean contactTrigger = true;
	public static boolean mealsTrigger = false;
	public static boolean sectionWizard = false;
	public static boolean bGroupAgenda =false;
	public static CT_core_BaseInfo_v2.cSchool_BaseInfo baseObj;
	public static List <Student_Section__c> studentSectionList;
    public static Boolean disabledProceedSS = false;	
	
	public static boolean bTriggersDisabled(){
			SchoolForce_Settings__c sfs = SchoolForce_Settings__c.getOrgDefaults();
			if (sfs.id==null) return false;
			else {
				return sfs.Triggers_Disabled__c;
			}
	}
	//A boolean that is set and then checked at the beginning of update triggers to be sure they only execute once
	public static  void  recursiveHelper (Boolean tempBool){
		b=tempBool;
	}
	
	public static  void  processAttendance (Boolean tempBool){
		bProcessAttendance=tempBool;
	}
	public static CT_core_BaseInfo_v2.cSchool_BaseInfo setupBaseInfo(){
		if (baseObj==null){
			CT_core_BaseInfo_v2.initBaseInfo();
			baseObj= CT_core_BaseInfo_v2.baseInfoObj;
		}
		return baseObj;
	}
	
	public static void studentTriggerUpdate (Boolean tempBool){
		studentTrigger = tempBool;
	}
	
	public static void studentSectionTriggerUpdate (Boolean tempBool){
		studSectionTrigger = tempBool;
	}
	
	public static void calculationTriggerUpdate (Boolean tempBool){
		calculateGrades = tempBool;
	}
	
	public static void schedulerTriggerUpdate (Boolean tempBool){
		scheduler = tempBool;
	}
	public static void gradeTriggerUpdate (Boolean tempBool){
		gradeTrigger = tempBool;
	}
	public static void gradeDeleteTriggerUpdate (Boolean tempBool){
		gradeDeletionAllowed = tempBool;
	}
	public static  void  mealsTriggerUpdate (Boolean tempBool){
		mealsTrigger=tempBool;
	}
	public static void cascadeDeletefromSections(List <Section__c> oldSections){
		List<Id> secList = new List<ID>();
		for(Section__c s: oldSections){
			secList.add(s.id);
		}
		
		List<Scheduled_Section__c> schedSecList = [SELECT id FROM Scheduled_Section__c WHERE Section__c IN :secList OR Schedule_Group_Section__c IN :secList];
		if(schedSecList.size() > 0) delete schedSecList;
		
		List<Assignment__c> assignmentList = [SELECT id FROM Assignment__c WHERE Section__c IN :secList];
		//PU:09/23/1 - Adding null check
		if(assignmentList.size() > 0){
			List<Id> assignmentIds = new List<Id>();
			for(Assignment__c a: assignmentList){
				assignmentIds.add(a.id);
			}
					
			List<Grade__c> grades = [SELECT id, Assignment__r.Section__c FROM Grade__c where Assignment__c IN :assignmentIds];
			if((grades!=null)&&(grades.size()>0))
				Trigger.oldMap.get(grades[0].Assignment__r.Section__c).addError('Unable to delete: There are still grades attached to this Section.');
			else
				delete assignmentList;
		}
		
		List<Session__c> sessionsTodelete = [SELECT Id FROM Session__c WHERE Section__c in : secList];
		System.debug('----------sessionsTodelete--------------'+sessionsTodelete);
		if(sessionsTodelete.size() > 0){
			try{
				System.debug('----------sessionsTodelete--------------'+sessionsTodelete.size());
				delete sessionsTodelete;
				
			}
			catch(Exception ex){
				System.debug(ex);
			}
		}
	}
	public static void updateSectionRefIds(List<Section__c> sectionList){
		List <Section__c> 	sectNameUpdList = new List <Section__c>();
		Set <Id>			schoolIds 	= new Set <Id>();
		Set <Id>			timeIds		= new Set <Id>();
		Map<Id, Time_Element__c>	timeMap = new Map <Id, Time_Element__c>();
		Map<Id, Account>	schoolMap = new Map <Id, Account>();
		//Id sectionGroupId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Schedule_Group');
		for (integer i=0; sectionList.size()>i; i++){
			if (sectionList[i].Time__c!=null&&sectionList[i].School__c!=null){
				timeIds.add(sectionList[i].Time__c);
				schoolIds.add(sectionList[i].School__c);
			}
		}
		if (!timeIds.isEmpty()){
			timeMap = CT_core_SoqlUtils.getTeMap();
		}
		if (!schoolIds.isEmpty()){
			schoolMap = CT_core_SoqlUtils.getSchoolMap(schoolIds);
		}
		if (!timeMap.isEmpty()&&!schoolMap.isEmpty()){
			for (integer i=0; sectionList.size()>i; i++){
				if (schoolMap.get( sectionList[i].school__c)!=null&&timeMap.get( sectionList[i].time__c)!=null){
					//sectionList[i].reference_Id__c = sectionList[i].Name+schoolMap.get(sectionList[i].school__c).reference_id__c+timeMap.get(sectionList[i].time__c).name__c;
					sectionList[i].Reference_Id__c = CT_Section_Utils.generateSectionReference(sectionList[i].Name, schoolMap.get(sectionList[i].school__c).reference_id__c, timeMap.get(sectionList[i].time__c).name__c);
				}
			}
		}	
	}

	public static void updateStaffSectionRefIdsFromSection(Set <Id> sectionIds){
		List <Staff_Section__c> sslist = new List <Staff_Section__c>();
		List<Student_Section__c> studslist = new List<Student_Section__c>();
	
		//JW updates student sections to correct ids
		for(Section__c s: [SELECT Id, (SELECT Id, staff__r.individual__r.reference_id__c, reference_id__c, section__r.name FROM Staff_Section__r),
									(SELECT Id, Section__r.Name, Reference_ID__c, Student__r.Student_Id__c, Student__r.School_Year__r.Name__c, Section__r.School__r.Name FROM Student_Section__r)
								FROM Section__c WHERE Id IN :sectionIds]){
			for(Student_Section__c ss: s.Student_Section__r){
				if(ss.Reference_ID__c != ss.Student__r.Student_ID__c + '_' + ss.Section__r.Name + '_' + ss.Section__r.School__r.Name+ '_' + ss.Student__r.School_Year__r.Name__c){
					ss.Reference_ID__c = ss.Student__r.Student_ID__c + '_' + ss.Section__r.Name + '_' + ss.Section__r.School__r.Name+ '_' + ss.Student__r.School_Year__r.Name__c;
					studslist.add(ss);
				}
			}
			for (Staff_Section__c ss: s.Staff_Section__r){
				if (ss.reference_id__c !=ss.staff__r.individual__r.reference_id__c+'_'+ss.section__r.name) {
					ss.reference_id__c = ss.staff__r.individual__r.reference_id__c+'_'+ss.section__r.name;
					sslist.add(ss);
				}
			}			
		}		
		//for(Student_Section__c ss: [Select ID, Section__r.Name, Reference_ID__c, Student__r.Student_Id__c, Student__r.School_Year__r.Name__c, Section__r.School__r.Name from Student_Section__c where Section__c IN : sectionIds]){
		//	if(ss.Reference_ID__c != ss.Student__r.Student_ID__c + '_' + ss.Section__r.Name + '_' + ss.Section__r.School__r.Name+ '_' + ss.Student__r.School_Year__r.Name__c){
		//		ss.Reference_ID__c = ss.Student__r.Student_ID__c + '_' + ss.Section__r.Name + '_' + ss.Section__r.School__r.Name+ '_' + ss.Student__r.School_Year__r.Name__c;
		//		studslist.add(ss);
		//	}
		//}
		//for (Staff_Section__c ss: [select id, staff__r.individual__r.reference_id__c, reference_id__c, section__r.name from Staff_Section__c where section__c in :sectionIds]){
		//	if (ss.reference_id__c !=ss.staff__r.individual__r.reference_id__c+'_'+ss.section__r.name) {
		//		ss.reference_id__c = ss.staff__r.individual__r.reference_id__c+'_'+ss.section__r.name;
		//		sslist.add(ss);
		//	}
		//}
		if(!studslist.isEmpty()){
			update studslist;
		}
		if (!sslist.isEmpty()){
			update sslist;
		}
	}

	public static void deactivateSchoolSetups(Set<ID> schoolIds){
		if (!schoolIds.isEmpty()){
			List<Setup__c> deactivateSetupList = new List<Setup__c>();
			for (Setup__c s: CT_core_SoqlUtils.getActiveSetups(schoolIds).values()){
				s.active__c = false;//Deactivate the old setup since the new one will be active
				deactivateSetupList.add(s);
			}
			try {
				update deactivateSetupList;
			}
			catch(Exception e){
				string linkString = '';
				for(Setup__c s: deactivateSetupList){
					linkString = s.id;
				}
				Global_Error__c ge = CT_Error_Handling.handleError(linkString, 'Setup', 'Setup before update trigger failure', e);
				insert ge;
			}
		}
	}

	public enum SOBJTYPE {STUDENT, SECTION}
	public enum FIELDNAME {EXITREASON, EXITDATE}
	public enum SOBJMODE {StudenSection, StaffSection, All}
	public static final String FLDACTIVE = 'Active__c';
	public static Map<SOBJTYPE, String> mapTYPE2SOBJ = new Map<SOBJTYPE, String>{
		SOBJTYPE.STUDENT => 'Student__c',
		SOBJTYPE.SECTION => 'Section__c'
	};
	public static Map<SOBJTYPE, Map<FIELDNAME, String>> mapTYPE2FIELDS = new Map<SOBJTYPE, Map<FIELDNAME, String>>{
		SOBJTYPE.STUDENT => new Map<FIELDNAME, String>{
									FIELDNAME.EXITREASON => 'Student_Exit_Reason__c',
									FIELDNAME.EXITDATE => 'Exit_Date__c'
								},
		SOBJTYPE.SECTION => new Map<FIELDNAME, String>{
									FIELDNAME.EXITREASON => 'Section_Exit_Reason__c', 
									FIELDNAME.EXITDATE => 'Section_Exit_Date__c'
								}
	};

	public static void populateDeactivateActivateSS(Map<Id, sObject> mapsObjects, Map<Id, sObject> oldMap, SOBJTYPE otype, SOBJMODE mode){
		if(CT_core_triggerUtils.disabledProceedSS){ return; }
		CT_core_triggerUtils.disabledProceedSS = true;
		Set<Id> sObjIds = mapsObjects.keySet();
		List<Staff_Section__c> staffSections = new List<Staff_Section__c>();
		List<Student_Section__c> studentSections = new List<Student_Section__c>();
		String fldExitReason = mapTYPE2FIELDS.get(otype).get(FIELDNAME.EXITREASON);
		String fldExitDate = mapTYPE2FIELDS.get(otype).get(FIELDNAME.EXITDATE);
		String query = 'SELECT Id, Active__c, '+fldExitReason+', '+fldExitDate;
		if(otype==SOBJTYPE.SECTION && mode!=SOBJMODE.StudenSection){
			query += ', (SELECT id, Is_Active__c, Deactivated__c FROM Staff_Section__r)';
		}
		if(mode!=SOBJMODE.StaffSection){
			query += ', (SELECT id, Active__c, Enrollment_End_Date__c, Deactivated__c, Section__c FROM Student_Section__r)';
		}
		query += ' FROM '+mapTYPE2SOBJ.get(otype)+' WHERE Id IN :sObjIds';
		List<sObject> sobjects = Database.query(query);

		for(sObject s: sobjects){
			Boolean  sActive = (Boolean)mapsObjects.get(s.Id).get(FLDACTIVE);
			Datetime sExitDate = (DateTime)mapsObjects.get(s.Id).get(fldExitDate);
			Datetime sExitDateOld = (DateTime)oldMap.get(s.Id).get(fldExitDate);
			if(sActive == false && otype==SOBJTYPE.SECTION && mode!=SOBJMODE.StudenSection && null != s.getSObjects('Staff_Section__r')){
				for(Staff_Section__c ss: (List<Staff_Section__c>)s.getSObjects('Staff_Section__r')){
					ss.Is_Active__c = false;
					ss.Deactivated__c = true;
					staffSections.add(ss);
				}
			}

			if(mode!=SOBJMODE.StaffSection){
				List<Student_Section__c> lstSS = s.getSObjects('Student_Section__r')!=null? (List<Student_Section__c>)s.getSObjects('Student_Section__r'): new List<Student_Section__c>();
				for(Student_Section__c ss: lstSS){
					if(sActive!=ss.Active__c && (sActive==false || (sActive==true && sExitDateOld==ss.Enrollment_End_Date__c && otype==SOBJTYPE.SECTION))){
						ss.Active__c = sActive;//s.Active__c;
						ss.Deactivated__c = !sActive;//!s.Active__c;
						ss.Section_Exit_Reason__c = sActive==false? (String)mapsObjects.get(s.Id).get(fldExitReason): '';
						ss.Enrollment_End_Date__c = (sActive==false && sExitDate!=null)? sExitDate: ss.Enrollment_End_Date__c;
						studentSections.add(ss);
					}
				}
			}
		}

		if(!staffSections.isEmpty()){
			update staffSections;
		}
		if(!studentSections.isEmpty()){
			update studentSections;
		}
	}

	//public static void deactivateStaffSections(Set<ID> deactivatedIDs, boolean isStaff){
	//	List<Staff_Section__c> staffSections;
	//	if(isStaff)
	//		staffSections = [SELECT id, Is_Active__c, Deactivated__c FROM Staff_Section__c WHERE Staff__c IN :deactivatedIDs];
	//	else
	//		staffSections = [SELECT id, Is_Active__c, Deactivated__c FROM Staff_Section__c WHERE Section__c IN :deactivatedIDs];
	//	if(staffSections.size() > 0){
	//		for(Staff_Section__c ss: staffSections){
	//			ss.Is_Active__c = false;
	//			ss.Deactivated__c = true;
	//		}
	//		update staffSections;
	//	}
	//}
	
	//public static void deactivateStudentSections(Set<ID> deactivatedIDs, boolean isStudent){
	//	List<Student_Section__c> studentSections;
	//	if(isStudent)
	//		studentSections = [SELECT id, Active__c FROM Student_Section__c WHERE Student__c IN :deactivatedIDs];
	//	else
	//		studentSections = [SELECT id, Active__c FROM Student_Section__c WHERE Section__c IN :deactivatedIDs];
	//	if(!studentSections.isEmpty()){
	//		for(Student_Section__c ss: studentSections){
	//			ss.Active__c = false;
	//			ss.Section_Exit_Reason__c = SECTIONEXITREASONBYTRIGGER;
	//		}
	//		update studentSections;
	//	}
	//}
	
	global static void createSetupRecords(List<Account> newSchools){
		ID yearID;
		try{
			Time_Element__c te = [SELECT id FROM Time_Element__c WHERE Picklist_Value__r.Name='Year' AND Current__c=true];
			yearID = te.id;
		} catch (Exception e){
			Global_Error__c ge = CT_Error_Handling.handleError('', 'Account trigger', 'No current year record located, or more than one located', e);
			insert ge;
		}
		
		List <Setup__c> setupList = new List <Setup__c>();
		if (yearID!=null){
			//check and see if a setup already exists
			List<Setup__c> currentSetups = [SELECT id, School__c FROM Setup__c WHERE School__c IN :newSchools AND Year__c=:yearID];
			Set<ID> schoolsWithSetup = new Set<ID>();
			if(!currentSetups.isEmpty()){
				for(Setup__c setup: currentSetups) schoolsWithSetup.add(setup.School__c);
			}
				
			for (Account school: newSchools){
				//if the setup already exists, don't create another one
				if(!schoolsWithSetup.contains(school.id))
					setupList.add(new Setup__c(Active__c=true, Year__c=yearID, School__c=school.id));
			}
		}
		if (!setupList.isEmpty()){
			insert setupList;
		}
	}
}