global with sharing class Student_Section_Utils {
/* **************   Start of Method Directly Called from Student Trigger ****************/
	
	public static void processBeforeInsert(List <Student_Section__c> newStudents){
		if(CT_core_triggerUtils.studSectionTrigger){
			studentSection_BeforeInsert(newStudents);
		}
	}
	public static void processAfterInsert(Map <Id, Student_Section__c> newMap){
		if(!CT_core_triggerUtils.b || CT_core_triggerUtils.studSectionTrigger){
			
			//Summer 2014: need to verify this
			CT_Gradebook_ManageGradeBook.createSectionGradesForStudents(newMap);
			
			if(CT_core_triggerUtils.studentTrigger){
				studentSection_AfterInsert(newMap.values());
				CT_Gradebook_ManageGradeBook.isafterinsert_onss(NewMap, null);  
			}
			Map <Id, Section__c> sectionMap = new Map<Id, Section__c>();
			for (Student_Section__c ss: newMap.values()) sectionMap.put(ss.section__c, null);
			sectionMap = new Map<Id,Section__c>([select id, name, reporting_period__r.date_start_date__c from Section__c
												where id in:sectionMap.keySet()
												and (RecordType.DeveloperName='Published' or RecordType.DeveloperName='Intervention_Section')]);
			manageActivationProcess(newMap, null, true, sectionMap);
		}
	}
	public static void processBeforeUpdate(Map <Id, Student_Section__c> newMap, Map<Id, Student_Section__c> oldMap){
		if(CT_core_triggerUtils.studSectionTrigger){
			Map <Id, Section__c> sectionMap = new Map<Id, Section__c>();
			for (Student_Section__c ss: newMap.values()) sectionMap.put(ss.section__c, null);
			sectionMap = new Map<Id,Section__c>([select id, name, reporting_period__r.date_start_date__c from Section__c
												where id in:sectionMap.keySet()
												and (RecordType.DeveloperName='Published' or RecordType.DeveloperName='Intervention_Section')]);
			manageActivationProcess(newMap, oldMap, false, sectionMap);
		}
	}
	public static void processAfterUpdate(Map <Id, Student_Section__c> newMap, Map<Id, Student_Section__c> oldMap){
		if(!CT_core_triggerUtils.b || CT_core_triggerUtils.studSectionTrigger){
			if(CT_core_triggerUtils.studentTrigger){
				Map<ID, Student_Section__c> tempNewMap = new Map<ID, Student_Section__c>();
				Map<ID, Student_Section__c> tempOldMap = new Map<ID, Student_Section__c>();
				List<Student_Section__c> deactivatedStudentSections = new List<Student_Section__c>();
				for(Student_Section__c ss: newMap.values()){
					//DE3881 This condition does not make sense.  We should only care if a student/section is going inactive -> active
					//and not vice versa.  adding the AND condition that the newMap.value also has to be TRUE
					if(oldMap.get(ss.id).Active__c != newMap.get(ss.id).Active__c && newMap.get(ss.ID).Active__c == true){
						tempNewMap.put(ss.ID, newMap.get(ss.id));
						tempOldMap.put(ss.ID, oldMap.get(ss.id));
					}

					if(!ss.Active__c && oldMap.get(ss.ID).Active__c){
						deactivatedStudentSections.add(ss);
					}
				}
				CT_Gradebook_ManageGradeBook.isafterinsert_onss(tempNewMap, tempOldMap);  
				studentSection_AfterInsert(newMap.values());

				if(!deactivatedStudentSections.isEmpty()){
					checkSectionsToInactivate(deactivatedStudentSections);
				}
			}
		}
	}
	public static void processBeforeDelete(Map <Id, Student_Section__c> oldMap){
		Set <Id> ssIdSet = new Set <Id>();
		Set <Id> sectIds = new Set <Id>();
		Set <Id> childSectIds = new Set <Id>();
		Set <Id> studentIdSet = new Set <Id>();
		Set <String> studentGroupKeySet = new Set <String>();
		List <Student_Section__c> inactiveSsList = new List <Student_Section__c>();
			for(Student_Section__c ss: oldMap.values()){
			   studentGroupKeySet.add(ss.student__c+'-'+ss.section__c);
			   ssIdSet.add(ss.id);
			   sectIds.add(ss.section__c);
			   studentIdSet.add(ss.student__c);
			}  
			for (Section__c sect: [select id from Section__c where Schedule_Group__c in:sectIds]){
				childSectIds.add(sect.id);
			}
			if (!childSectIds.isEmpty()){
				for (Student_Section__c ss: [select id, student__c,  active__c, section__r.Schedule_Group__c 
																	from Student_Section__c 
																	where section__c in:childSectIds
																	and		student__c in :studentIdSet and ID NOT IN: oldMap.keySet()]){
					string sgKey = ss.student__c+'-'+ss.section__r.Schedule_Group__c;
					if (studentGroupKeySet.contains(sgKey)){
						ss.active__c=false;
						inactiveSsList.add(ss);
					}
				}
			}
			if (!inactiveSsList.isEmpty()){
				update inactiveSsList;
			}
			
			List<Grade__c> gradesToDel = [select id FROM Grade__c WHERE  Student_Section__c IN :ssIdSet];
		  	
			if(!gradesToDel.isEmpty())
			CT_core_triggerUtils.gradeDeleteTriggerUpdate(true);
				delete gradesToDel;
			CT_core_triggerUtils.gradeDeleteTriggerUpdate(false);
	}
	
	public static void processAfterDelete(Map<ID,Student_Section__c> oldMap){
		checkSectionsToInactivate(oldMap.values());
	}
	
	public static List <Student_Section__c> studentSectionList;
	
	public static void studentSection_AfterInsert(List <Student_Section__c> ssList){
		Map <Id, Section__c> sectionMap = new Map <Id, Section__c>();
		Set <Id> schedGroupSsIds = new Set <Id>();
		for (Student_Section__c ss: ssList){
			sectionMap.put(ss.section__c, new Section__c());
		}
		if (!sectionMap.isEmpty()){
			sectionMap = new Map<Id, Section__c>( [select id, name, Time__c from Section__c  where id in:sectionMap.keySet() AND RecordType.DeveloperName='Schedule_Group']);
		}
		for (Student_Section__c ss: ssList){
			if(sectionMap.containsKey(ss.Section__c)){
				schedGroupSsIds.add(ss.id);
			}
		}		
		if (!schedGroupSsIds.isEmpty()){
			cascadeScheduleGroupEnrollment(schedGroupSsIds);
		}
	}
	
	public static void studentSection_BeforeInsert(List <Student_Section__c> ssList){
		Map <Id, Section__c>			sectionMap = new Map <Id, Section__c>();
		Map <Id, Student__c>			studentMap = new Map <Id, Student__c>();
		for (Student_Section__c ss: ssList){
			if (ss.student__c !=null){
				sectionMap.put(ss.section__c, new Section__c());
				studentMap.put(ss.Student__c, new Student__c());
			}
			else {
				ss.student__c.addError('Student field must be populated');
			}
		}
		if (!sectionMap.isEmpty()){
			sectionMap = new Map<Id, Section__c>( [select id, name, Time__c, RecordType.DeveloperName from Section__c  where id in:sectionMap.keySet()]);
			studentMap =new Map<Id, Student__c>( [select id, School__r.Reference_id__c, student_id__c, school_year__c, school_year__r.name__c from Student__c where id in:studentMap.keySet()]);
		}
		for (Student_Section__c ss: ssList){
			if (studentMap.get(ss.student__c).school_year__c!=sectionMap.get(ss.section__c).time__c){
				ss.addError('Student Year must be the same as the related Section Year; please verify you are adding the correct active student record.');
			}
			if (ss.student__c !=null){
				ss.reference_id__c = generateStudentSectionReference(studentMap.get(ss.student__c), sectionMap.get(ss.section__c));
			}
		}	
		studentSectionList = ssList;
	}

	@future
	public static void cascadeScheduleGroupEnrollment(Set<Id> schedGroupSsIds){
		Map <Id, Student_Section__c> IdToScheduleGroupMap = new Map <Id, Student_Section__c>();
		Map <Id, List<Section__c>> schedGroupToSectionsMap = new Map <Id, List<Section__c>>();
		List <Student_Section__c> 	 ssList = new List <Student_Section__c>();
		Set <Id> schedGroupIds = new Set <Id>();
		for (Student_Section__c ss: [select id, Active__c, student__r.student_id__c, student__r.school__r.name, student__r.setup__r.year__r.name__c, section__c, section__r.name, section__r.active__c, Enrollment_Start_Date__c, Enrollment_End_Date__c from Student_Section__c where id in:schedGroupSsIds]){
			IdToScheduleGroupMap.put(ss.id, ss);
			schedGroupIds.add(ss.section__c);
		}
		for (Section__c sect: [select id, active__c, Name, Schedule_Group__c from Section__c where Schedule_Group__c in:schedGroupIds]){
			if (schedGroupToSectionsMap.get(sect.Schedule_Group__c)==null){
				schedGroupToSectionsMap.put(sect.Schedule_Group__c, new List <Section__c>{sect});
			}
			else {
				schedGroupToSectionsMap.get(sect.Schedule_Group__c).add(sect);
			}
		}
		for (Id ssId: schedGroupSsIds){
			Student_Section__c masterSs=IdToScheduleGroupMap.get(ssId);
			system.debug('masterSs~~~~~'+masterSs);
			if (schedGroupToSectionsMap.get(masterSs.section__c)!=null){
				for (Section__c sect: schedGroupToSectionsMap.get(masterSs.section__c)){
					system.debug('sect~~~'+sect);
					Student_Section__c newSs= masterSs.clone(false);
					newSs.Section__c = sect.id;
					newSs.Active__c = masterSs.Active__c;
					newss.Reference_ID__c = masterSs.student__r.student_id__c+'_'+sect.Name+'_'+masterSs.student__r.School__r.Name+'_'+masterSs.student__r.setup__r.year__r.name__c;
					system.debug('newSs~~~~'+newSs);
					ssList.add(newss);
				}
			}
		}
		if (!ssList.isEmpty()){
			try {
				upsert ssList reference_id__c;
			}
			catch (exception e){}
		}
	}


	
	public static  Enrollment_Tracking__c processEnrollmentRecords_StudentSection(Student_Section__c ss, Date sectionStartDate){
		Boolean bLogTrackingRecord =true;
		Enrollment_Tracking__c et = new Enrollment_Tracking__c(Student_Section__c=ss.id, Current_Record__c = true);
		
		if (ss.active__c){
			et.active__c=true;
			if (ss.Enrollment_Start_Date__c!=null){
				et.start_date__c = ss.Enrollment_Start_Date__c;
			} else if(ss.student__r.Entry_Date__c!=null ){
				if (ss.student__r.Entry_Date__c > sectionStartDate)
					et.start_date__c =ss.student__r.Entry_Date__c;
				else
					et.start_date__c =sectionStartDate;
			} else {
				et.start_date__c =sectionStartDate;
			}
		} else {
			et.active__c=false;
			et.Exit_Reason__c = ss.Section_Exit_Reason__c;
			if (ss.Enrollment_End_Date__c!=null){
				et.start_date__c = ss.Enrollment_End_Date__c;
			} else {
				et.start_date__c =sectionStartDate;
			}
		}
		system.debug(et);
		et.reference_id__c = ss.id+'-'+et.start_date__c.format();
	
		return et;
	}

	public static string generateStudentSectionReference(Student__c stud, Section__c sect){
		system.debug(stud);
		system.debug(sect);
		return stud.student_id__c +'_'+ sect.name +'_'+ stud.school__r.reference_id__c +'_'+ stud.School_Year__r.name__c;
	}
	
	global static void manageActivationProcess(Map <Id, Student_Section__c> newMap, Map <Id, Student_Section__c> oldMap, boolean isNew){
	}
	
	global static void manageActivationProcess(Map <Id, Student_Section__c> newMap, Map <Id, Student_Section__c> oldMap, boolean isNew, Map<ID,Section__c> sectionMap){
		List <Enrollment_Tracking__c> enrollmentTrackingList = new List <Enrollment_Tracking__c>();
		for(Student_Section__c s: newMap.values()){
			if (isNew){
				if (s.active__c&&sectionMap.keySet().contains(s.section__c)){
					if (sectionMap.get(s.section__c)!=null){
						enrollmentTrackingList.add(processEnrollmentRecords_StudentSection(s, sectionMap.get(s.section__c).reporting_period__r.date_start_date__c));
					}
				}
			} else {
				if (s.active__c&&!oldMap.get(s.id).active__c&&sectionMap.keySet().contains(s.section__c)){
					if (s.enrollment_start_date__c ==null){
						s.enrollment_start_date__c = sectionMap.get(s.section__c).reporting_period__r.date_start_date__c;
					} else {
						enrollmentTrackingList.add(processEnrollmentRecords_StudentSection(s, null));
						s.enrollment_end_date__c = null;
					}
				} else if (!s.active__c && oldMap.get(s.id).active__c){
					if (s.enrollment_end_date__c ==null){
						s.Enrollment_End_Date__c=s.Enrollment_Start_Date__c;
					} else {
						Enrollment_Tracking__c et = processEnrollmentRecords_StudentSection(s, null);
						et.Exit_Reason__c = s.Section_Exit_Reason__c;
						enrollmentTrackingList.add(et);
						s.enrollment_start_date__c = null;
					}
				}	
			}
		}
		if (!enrollmentTrackingList.isEmpty()){
			upsert enrollmentTrackingList reference_Id__c;
		}
	}

	public static void checkSectionsToInactivate(List<Student_Section__c> studentSections){
		Set<ID> sectionIds = new Set<ID>();
		for(Student_Section__c ss: studentSections) sectionIds.add(ss.Section__c);
		
		List<Section__c> toDeactivate = new List<Section__c>();
		for(Section__c sec: [SELECT id, Active__c, (SELECT id, Active__c FROM Student_Section__r) FROM Section__c WHERE id IN :sectionIds]){
			boolean deactivate = true;
			if(sec.Student_Section__r.size()>0){
				for(Student_Section__c ss: sec.Student_Section__r){
					if(ss.Active__c) deactivate = false;
				}
			}
			if(deactivate){
				sec.Active__c = false;
				toDeactivate.add(sec);
			}
		}
		
		if(toDeactivate.size() > 0) update toDeactivate;
	}
}