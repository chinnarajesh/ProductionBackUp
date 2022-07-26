global with sharing class CT_Student_Section_Utils {
/* **************   Start of Method Directly Called from Student Trigger ****************/
	
	public static void processBeforeInsert(List <Student_Section__c> newStudents){
		if(core_triggerUtils.studSectionTrigger){
			studentSection_BeforeInsert(newStudents);
			populateBaseFilds(newStudents, null);
		}
	}

	public static void processAfterInsert(Map <Id, Student_Section__c> newMap){
		if(!core_triggerUtils.b || core_triggerUtils.studSectionTrigger){
			
			//Summer 2014: need to verify this
			CT_Gradebook_ManageGradeBook.createSectionGradesForStudents(newMap);
			
			if(core_triggerUtils.studentTrigger){
				studentSection_AfterInsert(newMap.values());
				CT_Gradebook_ManageGradeBook.isafterinsert_onss(NewMap, null);  
			}
			manageActivationProcess(newMap, null, true);
		}
	}

	public static void processBeforeUpdate(Map <Id, Student_Section__c> newMap, Map<Id, Student_Section__c> oldMap){
		if(core_triggerUtils.studSectionTrigger){
			manageActivationProcess(newMap, oldMap, false);
			populateBaseFilds(newMap.values(), oldMap);
		}
	}

	public static void processAfterUpdate(Map <Id, Student_Section__c> newMap, Map<Id, Student_Section__c> oldMap){
		if(!core_triggerUtils.b || core_triggerUtils.studSectionTrigger){
			if(core_triggerUtils.studentTrigger){
				Map<ID, Student_Section__c> tempNewMap = new Map<ID, Student_Section__c>();
				Map<ID, Student_Section__c> tempOldMap = new Map<ID, Student_Section__c>();
				for(Student_Section__c ss: newMap.values()){
					//DE3881 This condition does not make sense.  We should only care if a student/section is going inactive -> active
					//and not vice versa.  adding the AND condition that the newMap.value also has to be TRUE
					if(oldMap.get(ss.id).Active__c != newMap.get(ss.id).Active__c && newMap.get(ss.ID).Active__c == true){
						tempNewMap.put(ss.ID, newMap.get(ss.id));
						tempOldMap.put(ss.ID, oldMap.get(ss.id));
					}
				}
				CT_Gradebook_ManageGradeBook.isafterinsert_onss(tempNewMap, tempOldMap);  
				studentSection_AfterInsert(newMap.values());
			}
		}
	}

	public static void processBeforeDelete(Map <Id, Student_Section__c> oldMap){
		Set <Id> ssIdSet = new Set <Id>();
		Set <Id> sectIds = new Set <Id>();
		Set <Id> studentIdSet = new Set <Id>();
		Set <String> studentGroupKeySet = new Set <String>();
		List <Student_Section__c> inactiveSsList = new List <Student_Section__c>();
		
		CT_core_triggerUtils.disabledProceedSS = true;
		for(Student_Section__c ss: oldMap.values()){
		   studentGroupKeySet.add(ss.student__c+'-'+ss.section__c);
		   ssIdSet.add(ss.id);
		   sectIds.add(ss.section__c);
		   studentIdSet.add(ss.student__c);
		}  

		for (Student_Section__c ss: [SELECT Id, Student__c, Active__c, Section__r.Schedule_Group__c 
					FROM Student_Section__c 
					WHERE Section__c IN (SELECT Id FROM Section__c WHERE Schedule_Group__c IN :sectIds)
					AND	Student__c IN :studentIdSet AND Id NOT IN :oldMap.keySet()]){
			string sgKey = ss.student__c+'-'+ss.section__r.Schedule_Group__c;
			if (studentGroupKeySet.contains(sgKey)){
				ss.active__c=false;
				ss.Section_Exit_Reason__c = CT_core_triggerUtils.SECTIONEXITREASONBYTRIGGER;
				inactiveSsList.add(ss);
			}
		}

		if (!inactiveSsList.isEmpty()){
			update inactiveSsList;
		}
		
		List<Grade__c> gradesToDel = [select id FROM Grade__c WHERE  Student_Section__c IN :ssIdSet];
	  	
		if(!gradesToDel.isEmpty())
		core_triggerUtils.gradeDeleteTriggerUpdate(true);
			delete gradesToDel;
		core_triggerUtils.gradeDeleteTriggerUpdate(false);
	}
	
	public static void processAfterDelete(Map<ID,Student_Section__c> oldMap){

	}

	public static void populateBaseFilds(List<Student_Section__c> ssList, Map<Id, Student_Section__c> oldMap){
		for(Student_Section__c ss: ssList){
			//should run after manageActivationProcess
			if(ss.Intervention_Enrollment_Start_Date__c==null && ss.Enrollment_Start_Date__c!=null ){
				ss.Intervention_Enrollment_Start_Date__c = ss.Enrollment_Start_Date__c;
			}
			if(oldMap!=null && !ss.Active__c && oldMap.get(ss.Id).Active__c){
				CT_core_triggerUtils.disabledProceedSS = true;
			}	
		}
	}
	
	public static void studentSection_AfterInsert(List <Student_Section__c> ssList){
		cascadeScheduleGroupEnrollment(ssList);
	}
	
	public static void studentSection_BeforeInsert(List <Student_Section__c> ssList){
		for (Student_Section__c ss: ssList){
			if (ss.student__c == null){
				ss.student__c.addError('Student field must be populated');
			}			
			if(ss.Student_school_year__c != ss.Section_time__c){				
				ss.addError('Student Year must be the same as the related Section Year; please verify you are adding the correct active student record.');
			}
			ss.reference_id__c = generateStudentSectionReference(ss);
		}	
	}

	public static string generateStudentSectionReference(Student_Section__c ss){
		return ss.Student_Id__c +'_'+ ss.Section_Name__c +'_'+ ss.School_Reference_Id__c +'_'+ ss.School_Year_Name__c;
	}

	public static string generateStudentSectionReference(Student__c stud){
		return stud.Student_id__c +'_'+ stud.Primary_Schedule_Group_Name__c +'_'+ stud.School_Reference_Id__c +'_'+ stud.School_Year_Name__c;
	}

	public static string generateStudentSectionReference(Student__c stud, Section__c sect){
		return stud.student_id__c +'_'+ sect.name +'_'+ stud.school__r.reference_id__c +'_'+ stud.School_Year__r.name__c;
	}

	public static void cascadeScheduleGroupEnrollment(List<Student_Section__c> ssAllList){
		Map<Id, List<Student_Section__c>>	schedGroupToStudentSectionMap = new Map<Id, List<Student_Section__c>>();
		List<Student_Section__c>			ssList = new List<Student_Section__c>();
		for (Student_Section__c ss: ssAllList){
			if(ss.Section_RT__c == 'Schedule_Group'){
				if(!schedGroupToStudentSectionMap.containsKey(ss.Section__c)){
					schedGroupToStudentSectionMap.put(ss.Section__c, new List<Student_Section__c>());
				}
				schedGroupToStudentSectionMap.get(ss.Section__c).add(ss);
			}
		}
		if(schedGroupToStudentSectionMap.isEmpty()) {
			return;
		}

		for (Section__c sect: [SELECT Id, Active__c, Name, Schedule_Group__c 
				FROM Section__c WHERE Schedule_Group__c in :schedGroupToStudentSectionMap.keySet()]){
			System.debug('sect~~~'+sect);			
			for(Student_Section__c masterSs: schedGroupToStudentSectionMap.get(sect.Schedule_Group__c)){
				System.debug('masterSs~~~~~'+masterSs);
				Student_Section__c newSs= masterSs.clone(false);
				newSs.Section__c = sect.id;
				newSs.Active__c = masterSs.Active__c;
				newSS.Section_Exit_Reason__c = masterSs.Section_Exit_Reason__c;
				newss.Reference_ID__c = masterSs.Student_Id__c+'_'+sect.Name+'_'+masterSs.School__c+'_'+masterSs.Setup_Year_Name__c;
				System.debug('newSs~~~~'+newSs);
				ssList.add(newss);
			}
		}

		if (!ssList.isEmpty()){
			List<String> ssJsons = new List<String>();
			for(Student_Section__c ss: ssList){
				ssJsons.add(JSON.serialize(ss));
			}
			String ssListJSON = '[{ss}]'.replace('{ss}', String.join(ssJsons, ','));
			createCascadeScheduleGroupEnrollment(ssListJSON);
		}
	}

	@future//this possible a forever loop
	public static void createCascadeScheduleGroupEnrollment(String schedGroupSsJSON){
		System.debug('@@@ schedGroupSsJSON: '+schedGroupSsJSON);
		List<Student_Section__c> listSchedGroupSs = 
			(List<Student_Section__c>)JSON.deserialize(schedGroupSsJSON, List<Student_Section__c>.class);
		try {
			upsert listSchedGroupSs reference_id__c;
		}
		catch (exception e){
			System.debug('createCascadeScheduleGroupEnrollment error: '+ e.getMessage());
		}		
	}
	
	public static  Enrollment_Tracking__c processEnrollmentRecords_StudentSection(Student_Section__c ss, DateTime sectionStartDate){
		Boolean bLogTrackingRecord =true;
		Enrollment_Tracking__c et = new Enrollment_Tracking__c(Student_Section__c=ss.id, Current_Record__c = true);
		
		if (ss.active__c){
			et.active__c=true;
			if(ss.Enrollment_Start_Date__c!=null){
				et.start_date__c = ss.Enrollment_Start_Date__c;
			}else{
				et.start_date__c = (ss.Student_Entry_Date__c!=null && ss.Student_Entry_Date__c > sectionStartDate)? ss.Student_Entry_Date__c: sectionStartDate;
			}
		} else {
			et.active__c=false;
			et.Exit_Reason__c = ss.Section_Exit_Reason__c;
			et.start_date__c = (ss.Enrollment_End_Date__c!=null)? ss.Enrollment_End_Date__c: sectionStartDate;
		}
		System.debug(et);
		et.reference_id__c = ss.id+'-'+et.start_date__c.format(CT_core_SoqlUtils.ENROLLMENTTRACKINGREFERENCE);
	
		return et;
	}
	
	global static void manageActivationProcess(Map<Id, Student_Section__c> newMap, Map<Id, Student_Section__c> oldMap, boolean isNew){
		Set<String> allowedRT = new Set<String>{'Published', 'Intervention_Section', 'Curriculum'};

		List<Enrollment_Tracking__c> enrollmentTrackingList = new List <Enrollment_Tracking__c>();
		for(Student_Section__c s: newMap.values()){
			if (isNew){
				if (s.active__c && allowedRT.contains(s.Section_RT__c) ){
					enrollmentTrackingList.add(processEnrollmentRecords_StudentSection(s, s.Section_ReportingPeriod_StartDate__c));
				}
			} else {
				if (allowedRT.contains(s.Section_RT__c) && (s.active__c && !oldMap.get(s.id).active__c) ||
						(!s.Active__c && s.Enrollment_End_Date__c==null && oldMap.get(s.id).Enrollment_End_Date__c!=null)){
					if(s.Enrollment_start_date__c <= s.Enrollment_End_Date__c){
						s.Enrollment_start_date__c.addError(System.Label.Intervention_validation);
					}
					s.Active__c = true;
					s.Enrollment_start_date__c = s.Enrollment_start_date__c==null? Datetime.now(): s.Enrollment_start_date__c;
					enrollmentTrackingList.add(processEnrollmentRecords_StudentSection(s, null));
					s.Section_Exit_Reason__c = null;
					s.Enrollment_End_Date__c = null;
				} else if (!s.active__c && oldMap.get(s.id).active__c){
					if(s.Enrollment_start_date__c > s.Enrollment_End_Date__c){
						s.Enrollment_start_date__c.addError(System.Label.Intervention_validation);
					}					
					if(String.isBlank(s.Section_Exit_Reason__c)){
						s.Section_Exit_Reason__c.addError('Please choose Exit Reason');
					}
					s.Enrollment_End_Date__c = s.Enrollment_End_Date__c==null? Datetime.now(): s.Enrollment_End_Date__c;
					Enrollment_Tracking__c et = processEnrollmentRecords_StudentSection(s, null);
					et.Exit_Reason__c = s.Section_Exit_Reason__c;
					enrollmentTrackingList.add(et);
					s.enrollment_start_date__c = null;
				}	
			}
			System.debug('@@@ s: '+s);
		}
		
		if (!enrollmentTrackingList.isEmpty()){
			upsert enrollmentTrackingList Reference_Id__c;
		}	
	}

}