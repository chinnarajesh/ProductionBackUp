public class scheduler_SoqlUtils {
	public static List <Schedule_Template__c> retreiveScheduleTemplates(Setup__c s, Set<Id> ReportingPeriodSet){
 	List<Schedule_Template__c > schedTemplateList = new List <Schedule_Template__c>();
 	for (Schedule_Template__c pt: [Select s.start_time_Text__c,s.end_time_text__c, s.start_time__c, end_time__c, s.Setup__c, s.Reporting_Period__c, s.Reference_Id__c, s.Name, s.Is_Master__c, color__c, has_class__c, number_of_periods__c
 										From Schedule_Template__c s
 										where s.setup__c=:s.id
 										and 	s.reporting_period__c in :ReportingPeriodSet]){
 		if (pt.Start_Time__c!=null) pt.Start_Time_Text__c = pt.Start_Time__c.format('h:mm a');
 		if (pt.End_Time__c!=null) pt.End_Time_Text__c = pt.End_Time__c.format('h:mm a');
 		schedTemplateList.add(pt);
 	}
 	return schedTemplateList;
 }

	public static Map<ID,List<Scheduled_Section__c>> getScheduledSectionsForPublish(ID schoolId){
		Map<ID, List<Scheduled_Section__c>> rpIdToSchedSecs = new Map<ID, List<Scheduled_Section__c>>();
		for(Scheduled_Section__c ss: [SELECT id, Reporting_Period__c FROM Scheduled_Section__c WHERE Needs_Publish__c = true AND Account__c = :schoolId]){
			if(!rpIdToSchedSecs.containsKey(ss.Reporting_Period__c))
				rpIdToSchedSecs.put(ss.Reporting_Period__c, new List<Scheduled_Section__c>());
			rpIdToSchedSecs.get(ss.Reporting_Period__c).add(ss);
		}
		return rpIdToSchedSecs;
	}

	public static Map<ID,List<HoldingObj__c>> getHoldingObjsForPublish(String schoolRef, String yearName){
		Map<ID, List<HoldingObj__c>> holdingObjsByReportingPeriod = new Map<ID, List<HoldingObj__c>>();
		for(HoldingObj__c ho: [SELECT ID, Type__c, Error_Message__c, Propagated__c, Reporting_Period_Id__c
					FROM HoldingObj__c WHERE School_DBN__c = :schoolRef AND School_Year__c = :yearName]){
			if(!holdingObjsByReportingPeriod.containsKey(ho.Reporting_Period_Id__c))
				holdingObjsByReportingPeriod.put(ho.Reporting_Period_Id__c, new List<HoldingObj__c>());
			holdingObjsByReportingPeriod.get(ho.Reporting_Period_Id__c).add(ho);
		}
		return holdingObjsByReportingPeriod;
	}

	public static List <Scheduled_Section__c> getScheduledSectionsForPublish(Setup__c setup, Id reportingPeriodId, boolean bGroupBased){
		List <Scheduled_Section__c> ssList = new List <Scheduled_Section__c>();
		for (Scheduled_Section__c ss:
				[Select account__r.reference_Id__c, staff__r.reference_Id__c, Type__c,grade_level__c, grade_levels__c,
					schedule_group_name__c, Staff__c, Section__c, Schedule_Template__c, Schedule_Group_Section__c,
					Room__c, Reporting_Period__c, Reference_Id__c, Period_Key__c, Course__c, Course_name__c, Account__c,
 				Reporting_period__r.parent_time_element__r.parent_time_element__r.Name__c,
 				staff__r.First_Name_Staff__c, staff__r.Staff_Last_Name__c, staff__r.Individual__r.Staff_Code__c,
					staff__r.Individual__r.User_Name__c,staff__r.Individual__r.Email, staff__r.Individual__r.Phone,
 					staff__r.Individual__r.MailingStreet, staff__r.Individual__r.MailingCity,
 					staff__r.Individual__r.MailingState, staff__r.Individual__r.MailingPostalCode,
 					staff__r.Individual__r.Gender__c, Section__r.Section_Number__c, section__r.Name,
					section__r.Grade_Level__c, section__r.All_Grades__c, section__r.Period__c,
					section__r.Record_Attendance__c, section__r.Daily_attendance__c, section__r.Reporting_period__c,
					section__r.time__r.Name__c, room__r.Name
 			From Scheduled_Section__c s
 			where s.Reporting_Period__c =:reportingPeriodId
 			and account__c =:setup.School__c]){
 		if ((bGroupBased&& ss.Schedule_Group_Section__c!=null)||(!bGroupBased&& ss.Schedule_Group_Section__c==null))
 			ssList.add(ss);
 	}
		return ssList;
	}

	/*
		Returns a Map of sectionId and its related GroupId
	*/
	public static Map<ID, Id> getGroupsBySections(Set<ID> sectionIds){
		//scheduled section relates groups to sections
		Map<String, Id> refKeyToSection = new Map<String,Id>();
		Map<Id, Id> sectionToGroupId;
		for(Section__c sec :
				[SELECT id, Scheduler_Reference_Id__c
				FROM Section__c
				WHERE Id in : sectionIds
				AND Scheduler_Reference_Id__c <> null]){
			refKeyToSection.put(sec.Scheduler_Reference_Id__c,sec.Id);
		}
		if(refKeyToSection.keyset().size() > 0){
			sectionToGroupId = new Map<Id,Id>();
			for(Scheduled_Section__c ssec :[SELECT id, Schedule_Group_Section__c, Section_Reference_Id__c FROM Scheduled_Section__c
				WHERE Section_Reference_Id__c IN :refKeyToSection.keyset() ]){
				sectionToGroupId.put(refKeyToSection.get(ssec.Section_Reference_Id__c),ssec.Schedule_Group_Section__c);
			}
		}
		return sectionToGroupId;
	}

	/*
		Returns all Schedule Groups for the setup record
	*/
	public static List<Section__c> getGroupsBySetupId(Id setup){
		Map <String, List <Section__c>> sectionMapByGrade = new Map <String, List<Section__c>>();
		Setup__c s= core_SoqlUtils.getSetupById(setup);
		List <Section__c> sectionList = new List <Section__c>();
		for (Section__c sect:
				[SELECT ID, all_grades__c ,NAME
				FROM Section__c
				WHERE RecordType.DeveloperName='Schedule_Group'
				AND	School__c=:s.school__c
				AND	Time__c=:s.year__c
				order by name]){
			string firstGl;
			if (sect.all_grades__c!=null){
				firstGl = (sect.all_grades__c.contains(';'))?sect.all_grades__c.split(';')[0]:sect.all_grades__c;

				if (sectionMapByGrade.get(firstGl)==null){
					sectionMapByGrade.put(firstGl, new List <Section__c>{sect});
				} else {
					sectionMapByGrade.get(firstGl).add(sect);
				}
			}
		}
		for (Schema.PicklistEntry pl :Section__c.grade_level__c.getDescribe().getPicklistValues()){
			if (sectionMapByGrade.get(pl.getValue())!=null){
				sectionList.addAll(sectionMapByGrade.get(pl.getValue()));
			}
		}
		return sectionList;
	}

	/*			Get ScheduleTemplate by Id*/
	public static List<Schedule_Template__c> getScheduleTemplateById(Id tempId){
		return [SELECT ID,Name,End_Time_Text__c,Start_Time_Text__c,Start_Time__c,End_Time__c
				FROM Schedule_Template__c
				WHERE Id = : tempId];
	}


	/*			Get ScheduleTemplate by RP*/
	public static List<Schedule_Template__c> getScheduleTemplateBySetup(Id setupId){
		return [SELECT Id,Name,Setup__c,Start_Time__c,End_Time__c,is_Master__c
					,Reporting_Period__c,Reporting_Period__r.Name,Reporting_Period__r.Name__c
					,Color__c,Has_Class__c
				FROM Schedule_Template__c
				WHERE Setup__c=:setupId];
	}

	// Retrieve regular scheduled sections by Template Id
	public static List<Scheduled_Section__c> getScheduledSectionsByTempId(Id schedTempId){
		return [SELECT Type__c,Start_Time__c,Start_Time_Text__c,Rounded_Start_Time__c,Rounded_End_Time__c
					,Staff__c,Staff__r.Name,Staff__r.Staff_Last_Name__c,Staff__r.First_Name_Staff__c
					,Section__c,Schedule_Template__c,Schedule_Group_Section__c
					,Room__c,Room__r.Number__c,Room_Key__c,Reporting_Period__r.Name,Reporting_Period__c
					,Reference_Id__c,Period_Key__c,Name,Id,End_Time__c,End_Time_Text__c
					,Course__c,Course__r.Name,Account__c,Daily_Attendance__c,Record_Attendance__c
					,No_Meeting__c,Color__c,schedule_template__r.Start_time_text__c
					,schedule_template__r.End_time_text__c, Room__r.Name
				FROM Scheduled_Section__c
				WHERE Schedule_Template__c = : schedTempId
				order by schedule_group_Section__c, Start_Time__c];
 }

	public static List<Scheduled_Section__c> getClonedScheduledSections(Id oldSchedTempId,Id newSchedTempId,Id rpId){
		List<Scheduled_Section__c> clonedSSecList = new List<Scheduled_Section__c>();
		Set <String> referenceIdSetCheck = new Set <String> ();
				for(Scheduled_Section__c ss : [SELECT Type__c,Start_Time__c,Start_Time_Text__c
													,Rounded_Start_Time__c,Rounded_End_Time__c
													,Staff__c,Staff__r.Name,Staff__r.Staff_Last_Name__c
													,Staff__r.First_Name_Staff__c,Section__c
													,Schedule_Template__c,Schedule_Group_Section__c
													,Schedule_Group__r.Name,Room__c,Room__r.Number__c
													,Room_Key__c,Reporting_Period__r.Name
													,Reporting_Period__c,Reference_Id__c,color__c
													,Period_Key__c,Name,Id,End_Time__c
													,End_Time_Text__c	,Course__c,Course__r.Name
													,Account__c,Record_Attendance__c,Daily_Attendance__c
													,No_Meeting__c
												FROM Scheduled_Section__c
												WHERE Schedule_Template__c = : oldSchedTempId
												order by schedule_group_Section__c, Start_Time__c]){
					Scheduled_Section__c 	clonedSS = ss.clone(false);
					clonedSs.Schedule_Template__c = newSchedTempId;
					clonedSs.Reference_Id__c = ImportUtils.createScheduledSectionKey(ss.Account__c,ss.Schedule_Group_Section__c,ss.Course__c,rpId,newSchedTempId);
					clonedSs.Section_Reference_Id__c = ImportUtils.createSectionReferenceKey(ss.Account__c,ss.schedule_group__c,ss.course__c,rpId);
					clonedSs.Reporting_Period__c = rpId;
					clonedSs.Needs_Publish__c = true;
					if (!referenceIdSetCheck.contains(clonedSs.Reference_Id__c)){
						clonedSSecList.add(clonedSs);
						referenceIdSetCheck.add(clonedSs.Reference_Id__c);
					}
			}

 		return clonedSSecList;
 	}
 	
	// Retrieve regular scheduled sections by Template Id
	public static List<Scheduled_Section__c> getScheduledSectionById(Id ssId){
		return [SELECT Type__c,Start_Time__c,Start_Time_Text__c,Rounded_Start_Time__c
					,Rounded_End_Time__c,Staff__c,Staff__r.Name,Staff__r.Staff_Last_Name__c
					,Staff__r.First_Name_Staff__c,Section__c,Schedule_Template__c
					,Schedule_Group_Section__c,Room__c,Room__r.Number__c
					,Room_Key__c,Reporting_Period__r.Name,Reporting_Period__c,Reference_Id__c
					,Period_Key__c,Name,Id,End_Time__c,End_Time_Text__c,Course__c
					,Course__r.Name,Account__c,Daily_Attendance__c,Record_Attendance__c,No_Meeting__c,Room__r.Name
				FROM Scheduled_Section__c
				WHERE Id = : ssId];
 	}

	// Retrieve regular scheduled sections by Template Id
	public static List<Scheduled_Section__c> getAllDayScheduledSectionsByTempId(Id schedTempId){
		return [SELECT Type__c,Start_Time__c,Start_Time_Text__c,Rounded_Start_Time__c,Rounded_End_Time__c
					,Staff__c,Staff__r.Name,Staff__r.Staff_Last_Name__c,Staff__r.First_Name_Staff__c
					,Section__c,Schedule_Template__c,Schedule_Group_Section__c,Id
					,Room__c,Room__r.Number__c,Room_Key__c,Reporting_Period__r.Name
					,Reporting_Period__c,Reference_Id__c,Period_Key__c,Name
					,End_Time__c,End_Time_Text__c,Course__c,Course__r.Name,Account__c
					,Daily_Attendance__c,Record_Attendance__c,No_Meeting__c, Room__r.Name
				FROM Scheduled_Section__c
				WHERE Schedule_Template__c = : schedTempId
				AND (Daily_Attendance__c = true OR No_Meeting__c = true)
				order by id];
	}

	// return a list of Select Options for a given list of Schedulable rooms
	public static List<SelectOption> getRoomOptionsBySchool(Id schoolId) {
		List<SelectOption> roomOptionList = new List<SelectOption>();
		for(Room__c r : [SELECT id, name, number__c from Room__c
						WHERE school__c = : schoolId
						AND Schedulable__c = true
						AND number__c !=null
						order by number__c asc]){
			roomOptionList.add(new SelectOption(r.Id,String.valueOf(r.Name)));
		}
		return roomOptionList;
 	}

	// return a list of Select Options for a given list of Courses
	public static List<SelectOption> getCourseOptionsByCCatId(Id ccatId) {
		List<SelectOption> courseOptionList = new List<SelectOption>();
		for(Course_Course_Catalog__c c:
				[SELECT id, course__r.name, course__c
				FROM Course_Course_Catalog__c
				WHERE course_catalog__c =:ccatId
				AND course__c <> null
				order by Course__r.Name asc]){
			courseOptionList.add(new SelectOption(c.Course__c,c.Course__r.Name));
		}
		return courseOptionList;
 	}

	// return a list of Select Options for a given list of Courses
	public static List<SelectOption> getStaffOptionsBySchool(Id schoolId) {
		List<SelectOption> staffOptionList = new List<SelectOption>();
		for(Staff__c s: [SELECT id, Name
						FROM Staff__c
						WHERE organization__c =:schoolId
						AND Active__c=true
						order by name asc]){
			staffOptionList.add(new SelectOption(s.Id,String.valueOf(s.Name)));
		}
		return staffOptionList;
	}

	//test getScheduledSectionsForPublish method
	static testMethod void testGetScheduledSectionsForPublish(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		TestDataSetupUtil_v2.setUpStaffData(5);
		TestDataSetupUtil_v2.setUpStudentData(5);

		List<Section__c> groups = TestDataSetupUtil_v2.getScheduleGroups_Section();
		List<Scheduled_Section__c> schSects = TestDataSetupUtil_v2.createScheduledSections(groups);
		Time_Element__c rp = new Time_Element__c(Name__c = 'Test-RP');
		insert rp;
		for(Scheduled_Section__c ss: schSects) ss.Reporting_Period__c = rp.id;
		update schSects;

		Test.startTest();

		List<Scheduled_Section__c> publishSS = getScheduledSectionsForPublish(TestDataSetupUtil_v2.activeSetup, rp.id, true);
		System.assertEquals(publishSS.size(), schSects.size());

		Test.stopTest();
	}
}