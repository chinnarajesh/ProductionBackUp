public with sharing class Section_Utils {
/* **************   Start of Method Directly Called from Section Trigger ****************/
	public static Map <Id, List <Time_Element__c>>   termRpMap;
	public static Map <Id, Id> parentTeMap;
	public static Set <Id>		reportingPeriodIds;
	public static Map <Id, Id> finalRpMap;
	public static Map <Id, Time_Element__c> teMap;
	public static Map <Id, String> sectRtMap;
	public static Set <String> nonSectionRtSet = new Set <String>{'Schedule_Group', 'Gradebook_Group', 'Intervention_Section'};
	
	public static void getTeConfig(){
		if (termRpMap==null){
			Set <Id> termIds = new Set <Id>();
			finalRpMap = new Map <Id, Id>();
			parentTeMap = new Map <Id, Id>();
			termRpMap = new Map <Id, List <Time_Element__c>>();
			teMap = new Map <Id, Time_Element__c>();
			for (Time_Element__c te: [select id, name__c, parent_time_element__c from Time_Element__c where id in:reportingPeriodIds]){
				termRpMap.put(te.parent_time_element__c, new List <Time_Element__c>());
				termIds.add(te.parent_time_element__c);
			}
			for (Time_Element__c te: [select name__c, id, date_start_date__c, parent_time_element__c , (select id from time__r)
															from Time_Element__c 
															where parent_time_element__c in:termIds
															order by parent_time_element__c, date_start_date__c]){
				parentTeMap.put(te.id, te.parent_time_element__c);
				termRpMap.get(te.parent_time_element__c).add(te);
				teMap.put(te.id, te);
				for (Time_Element__c finalTe: te.time__r){
					finalRpMap.put(te.id, finalTe.id);
				}
			}
		}
	}
	
	public static Map <Id, String> getSectionRtMap(){
		if (sectRtMap ==null){
			sectRtMap = new Map <Id, String>();
			Map <String, Id> rtNameMap = core_SoqlUtils.getRecordTypesBySobject('Section__c');
			for (string rtName:  rtNameMap.keySet()){
				sectRtMap.put(rtNameMap.get(rtName), rtName);
			}
		}
		return sectRtMap;
	}
	
	
	public static void processBeforeInsert(List <Section__c> newList){
		translateSectionName(newList);
		mapTimeConfig(newList);
		verifyTimeConfig(newList, null, null);
		verifyWeightingConfig(newList, null, null);
	}
	public static void processAfterInsert(Map <Id, Section__c> newMap){
		cascadeSectionTimeChanges(newMap, null);
		cascadeNumberOfPeriodsUpdate(newMap, null);
	}
	public static void processBeforeUpdate(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
		updReferenceId(newMap, oldMap);
		verifyTimeConfig(null, newMap, oldMap);
		verifyWeightingConfig(null, newMap, oldMap);
	}
	public static void processAfterUpdate(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
		cascadeSectionTimeChanges(newMap, oldMap);
		cascadeNumberOfPeriodsUpdate(newMap, oldMap);
		cascadeStaffSectionRefIdUpdate(newMap, oldMap);
		checkDeactivation(newMap, oldMap);
	}
	public static void processBeforeDelete(List<Section__c> old){
		try{
				core_TriggerUtils.cascadeDeletefromSections(old);  //Delete related objects that are not in masater-detail relationships
				Set<Id> sectionIds = new Set<Id>();
				for(Section__c s: old){
					sectionIds.add(s.id);
				}
				delete [select id from Section_Standard__c where Section__c IN: sectionIds];
			} catch(Exception e) {
				string links = '';
				for(Section__c s: old){
					if(s.id != null){
						if(links==''){
							links = s.name + ',' + s.id;
						}else{
							links = links + ';' + s.name + ',' + s.id;
						}
					}
				}
				Global_Error__c ge = Error_Handling.handleError(links, 'Scheduler', 'updateSectionRefIds failed', e);
				insert ge;
			}
	}
	
		/* **************   End of Method Directly Called from Section Trigger ****************/


	/****************** Start of Utility Methods ************************************/
	public static void updReferenceId (Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
		Set <Id> updSectionIDs = new Set <Id>();
		SchoolForce_Settings__c settings = SchoolForce_Settings__c.getOrgDefaults();
		//Set<ID> orgIDs = new Set<ID>{'00Dc00000001OMs','00DL00000009w6e','00DE0000000YCnU','00Dc00000001qrT','00Dc000000020td'};
		for (Section__c sect: newMap.values()){
			if (core_TriggerUtils.scheduler){			
				if (oldMap.get(sect.id).Reporting_Period__c!=null){
					Id oldRpId = oldMap.get(sect.id).Reporting_Period__c;	// obtain the "original" reporting period ID value
					if (sect.Reporting_Period__c!=oldRpId){	// trigger records don't contain the "original" reporting period ID value
						sect.Reporting_Period__c=oldRpId;		// reset the reporting period ID to the "original" ID value
					}
				}
				if (sect.Name!=oldMap.get(sect.id).name){	// trigger records name is not the same as the original or the one the auto generated name was changed to
					sect.Name=oldMap.get(sect.id).name;		// reset the name to the original
				}
				//DE3193 scheduler should not update number of reporting periods on sections
				if (sect.Number_of_Reporting_Periods__c!=oldMap.get(sect.id).Number_of_Reporting_Periods__c){
					sect.Number_of_Reporting_Periods__c = oldMap.get(sect.id).Number_of_Reporting_Periods__c;
				}
			}
			if (oldMap.get(sect.id).Time__c!=sect.time__c){
				sect.addError('Not allowed to update the year for Section record, please create new section');
			}
			if (oldMap.get(sect.id).School__c!=sect.School__c){
				sect.addError('Not allowed to update the school for Section record, please create new section');
			}
			if (sect.Name!=oldMap.get(sect.id).name && !settings.Static_Reference_IDs__c){
			//if (sect.Name!=oldMap.get(sect.id).name && !orgIDs.contains(UserInfo.getOrganizationId())){
				//add check to make sure the section Ref Id actually contains the sec name.
				if(!sect.Reference_Id__c.contains(sect.Name)){
					sect.Reference_Id__c=sect.Reference_Id__c.replace(oldMap.get(sect.id).Name, sect.Name);
				}
				
			}
		}
	}
	
	public static void cascadeCompletedFlagFromSectionReportingPeriod(Map <Id, Section_ReportingPeriod__c> newMap, Map <Id, Section_ReportingPeriod__c> oldMap){
		List <Section__c> sectionList = new List <Section__c>();
		Set <Id> incompletedSectionsSet = new Set <Id>();
		Set <Id> checkCompletedSectionsSect = new Set <Id>();
		for (Section_ReportingPeriod__c srp: newMap.values()){
			if (srp.completed__c != oldMap.get(srp.id).completed__c){
				if (!srp.completed__c){
					incompletedSectionsSet.add(srp.section__c);
				}
				else {
					checkCompletedSectionsSect.add(srp.section__c);
				}
			}
		}
		if (!incompletedSectionsSet.isEmpty()){
			for (Id sectionId: incompletedSectionsSet){
				sectionList.add(new Section__c(Id=sectionId, Completed__c = false));
			}
		}
		if (!checkCompletedSectionsSect.isEmpty()){ 
			for (Section__c sect: [select id, (select id, completed__c from Section_ReportingPeriod__r where time__r.parent_Time_element__r.picklist_value__r.name='Term') from Section__c where id in:checkCompletedSectionsSect]){
				boolean bCompleted =true;
				for (Section_ReportingPeriod__c srp: sect.Section_ReportingPeriod__r){
					system.debug('srp~~~'+srp);
					if (!srp.completed__c) {
						bCompleted = false;
						break;
					}
				}
				if (bCompleted){
					sectionList.add(new Section__c(Id=sect.id, Completed__c = true));
				}
			}
		}
		if (!sectionList.isEmpty()){
			update sectionList;
		}
	}
	
	public static void mapTimeConfig (List <Section__c> sectList){
		Map <String, Time_Element__c> yearTeMap = new Map <String, Time_Element__c>();
		Map <String, Time_Element__c> rpTeMap = new Map <String, Time_Element__c>();
		Set <String> rpNameSet = new Set <String>();
		Map <Id, String> rtMap = getSectionRtMap();
		for (Section__c sect: sectList){
			if (!nonSectionRtSet.contains(rtMap.get(sect.recordTypeId))){
				if (sect.year_name__c==null&&sect.time__c==null){
					sect.addError('Year Name or Time must be entered');
				}	
				else {
					if (sect.time__c==null){
						yearTeMap.put(sect.year_name__c, null);	
					}
				}
				if (sect.reporting_period_Name__c==null&&sect.reporting_period__c==null){
					sect.addError('Reporting Period Name or Reporting Period must be entered');
				}	
				else {
					if (sect.reporting_period__c==null){
						rpNameSet.add(sect.reporting_period_name__c);
					}
				}
			}
		}
		
		if (!yearTeMap.keySet().isEmpty() || !rpNameSet.isEmpty()){
			for (Time_Element__c te: [Select id, name__c, parent_time_element__r.parent_time_element__c from Time_Element__c where (Name__c in :yearTeMap.keySet() and Picklist_Value__r.Name='Year') OR Name__c in :rpNameSet]){
				yearTeMap.put(te.name__c, te);
				if(te.Parent_time_element__r.Parent_time_element__c != null){
					rpTeMap.put(te.name__c+'-'+te.parent_time_element__r.parent_time_element__c, te);
				}
			}
		}
		
		for (Section__c sect: sectList){
			if (sect.year_name__c!=null){
				if (yearTeMap.keySet().contains(sect.year_name__c)){
					sect.time__c = yearTeMap.get(sect.year_name__c).id;
				}
			}
			if (sect.reporting_period_name__c!=null){
				if (rpTeMap.keySet().contains(sect.reporting_period_name__c+'-'+sect.time__c)){
					sect.reporting_period__c = rpTeMap.get(sect.reporting_period_name__c+'-'+sect.time__c).id;
				}
			}
		}
	}
	
	public static void verifyTimeConfig (List <Section__c> sectList, Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
		//Check that the time element & rp 
		reportingPeriodIds = new Set <Id>();
		Map <Id, String> rtMap = getSectionRtMap();
		if (sectList!=null){
			for (Section__c sect: sectList){
				if (!nonSectionRtSet.contains(rtMap.get(sect.recordTypeId))){
					if (sect.Reporting_Period__c==null) sect.addError('Reporting Period must be populated');
					else {
						system.debug('rpId~~~'+sect.reporting_period__c);
						reportingPeriodIds.add(sect.reporting_period__c);
					}
				}
			}
		}
		else {
			for (Section__c sect: newMap.values()){
				if (!nonSectionRtSet.contains(rtMap.get(sect.recordTypeId))){
					if (sect.number_of_Reporting_periods__c!=oldMap.get(sect.id).number_of_reporting_periods__c||sect.reporting_period__c!=oldMap.get(sect.id).reporting_period__c){
						if (sect.Reporting_Period__c==null) sect.addError('Reporting Period must be populated');
						else {
						system.debug('rpId~~~'+sect.reporting_period__c);
						reportingPeriodIds.add(sect.reporting_period__c);
						}
					}
				}
			}
		}
		if (!reportingPeriodIds.isEmpty()){
			if (termRpMap==null){
				getTeConfig();
			}
			List <Section__c> checkSectionList;
			if (sectList!=null){
				checkSectionList=sectList;
			}
			else checkSectionList = newMap.values();
			for (Section__c sec: checkSectionList){
				if (oldMap!=null){
					if (sec.reporting_period__c!=oldMap.get(sec.id).reporting_period__c){
						if (!teMap.keySet().contains(sec.reporting_period__c)){
							sec.reporting_period__c.addError('Only time elements that are base reporting periods are allowed');
						}
						else {
							if(sec.name.contains(teMap.get(oldMap.get(sec.id).reporting_period__c).name__c)){
								sec.name=sec.name.replace(teMap.get(oldMap.get(sec.id).reporting_period__c).name__c, teMap.get(sec.reporting_period__c).name__c);//Replace the time element portion of the name to match the new reporting period
							}
						}
					}
				}
				Integer i=0;
				system.debug('termRpMap~~'+termRpMap);
				system.debug('parentTeMap~~'+parentTeMap);
				for (Time_Element__c te: termRpMap.get(parentTeMap.get(sec.reporting_period__c))){
					  if (te.id == sec.Reporting_Period__c&&i==0||i!=0){
						i++;
					}
				}
				if (i < integer.valueOf(sec.number_of_reporting_periods__c)){
					sec.Number_of_Reporting_Periods__c.addError('Invalid starting reporting period & number of reporting periods combination');
				}
			}
		}
	}
	
	public static void verifyWeightingConfig (List <Section__c> sectList, Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
		Map <Id, String> rtMap = getSectionRtMap();
		Set <Id>		courseIds  = new Set <Id>();
		Map <Id, Set <String>> courseWeightingConfigMap = new Map <Id, Set <String>>();
		if (sectList!=null){
			for (Section__c sect: sectList){
				if (!nonSectionRtSet.contains(rtMap.get(sect.recordTypeId))){
					courseIds.add(sect.course__c);
					courseWeightingConfigMap.put(sect.course__c, new Set<String>{});
				}
			}
		}
		else {
			for (Section__c sect: newMap.values()){
				if (!nonSectionRtSet.contains(rtMap.get(sect.recordTypeId))){
					if (sect.number_of_Reporting_periods__c!=oldMap.get(sect.id).number_of_reporting_periods__c){
						courseIds.add(sect.course__c);
						courseWeightingConfigMap.put(sect.course__c, new Set<String>{});
					}
				}
			}
		}
		if (!courseIds.isEmpty()){
			for (Course_Weightings__c cw: [select id, key__c, course__c, reporting_period_type__r.corresponding_value__c from Course_Weightings__c where course__c in :courseIds]){
				String weightingConfigKey = cw.course__c+'-'+cw.reporting_period_type__r.corresponding_value__c;
				if (!courseWeightingConfigMap.get(cw.course__c).contains(weightingConfigKey)){
					courseWeightingConfigMap.get(cw.course__c).add(weightingConfigKey);
				}
			}
			List <Section__c> checkSectionList;
			if (sectList!=null){
				checkSectionList=sectList;
			}
			else checkSectionList = newMap.values();
			for (Section__c sect: checkSectionList){
				if (sect.course__c!=null){
					if (courseWeightingConfigMap.get(sect.course__c)!=null){
						String weightingConfigKey = sect.course__c+'-'+sect.number_of_reporting_periods__c;
						Set <String> validConfigComboSet = courseWeightingConfigMap.get(sect.course__c);					
						if(!validConfigComboSet.contains(weightingConfigKey)){
							sect.addError('No course weightings for selected course & number of reporting periods combination; please create course weightings.');	
						}
					}
				}
			}
		}
	}
	
	public static void checkDeactivation(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
		Set<ID> deactivatedIDs = new Set<ID>();
		for(Section__c sec: newMap.values()){
			//if section was deactivated
			if(oldMap.get(sec.id).Active__c && !sec.Active__c) deactivatedIDs.add(sec.id);
		}
		if(!deactivatedIDs.isEmpty()){
			core_triggerUtils.deactivateStaffSections(deactivatedIDs,false);
			core_triggerUtils.deactivateStudentSections(deactivatedIDs,false);
		}
	}
	
	public static void cascadeSectionTimeChanges(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
		List <Section__c> sectionList = new List <Section__c>();
		Set <Id> ssIds = new Set <Id>();
		Map <Id, String> rtMap = getSectionRtMap();
		for (Section__c sect: newMap.values()){
			if (oldMap==null){
				if (!nonSectionRtSet.contains(rtMap.get(sect.recordTypeId))){
					sectionList.add(sect);
				}
			}
			else {
				if (!nonSectionRtSet.contains(rtMap.get(sect.recordTypeId))){
					if (sect.number_of_Reporting_periods__c!=oldMap.get(sect.id).number_of_reporting_periods__c){
						sectionList.add(sect);
					}
					else if (sect.reporting_period__c!=oldMap.get(sect.id).reporting_period__c){
						sectionList.add(sect);
					}
				}
			}
		}
		if (!sectionList.isEmpty()){
			if (termRpMap==null){
				getTeConfig();
			}
			Scheduler_TriggerUtils.createSectionRPs(sectionList);
		}
	}
	
	public static void cascadeStaffSectionRefIdUpdate(Map <Id, Section__c> newMap, Map<Id, Section__c> oldMap){
		Map <Id, Section__c> changeRpSectionMap = new Map <Id, Section__c>();
		Set <Id> updSectionIDs = new Set <Id>();
		for (Section__c sect: newMap.values()){
			if (sect.Name!=oldMap.get(sect.id).name){
				updSectionIDs.add(sect.id);
			}
		}
		if(!updSectionIDs.isEmpty()){
			core_triggerUtils.updateStaffSectionRefIdsFromSection(updSectionIDs);
		}
	}
	
	public static void cascadeNumberOfPeriodsUpdate(Map<ID, Section__c> newMap, Map<ID, Section__c> oldMap){
		Set<ID> sectionIDs = new Set<ID>();
		for(Section__c section: newMap.values()){
			if(oldMap==null) sectionIDs.add(section.id);
			else if(newMap.get(section.id).Number_of_Periods__c!=oldMap.get(section.id).Number_of_Periods__c) sectionIDs.add(section.id);
		}
		if(sectionIDs.size()>0){
			List<Section_ReportingPeriod__c> srps = [SELECT id, Section__c FROM Section_ReportingPeriod__c WHERE Section__c IN :sectionIDs];
			for(Section_ReportingPeriod__c srp: srps){
				srp.Number_of_Periods__c = newMap.get(srp.Section__c).Number_of_Periods__c;
			}
			update srps;
		}
	}
	
	public static void translateSectionName(List <Section__c> newList){
		Set <Id> courseIds = new Set <Id>();
		Set <Id> groupIds = new Set <Id>();
		Map <Id, Course__c> courseMap = new Map <Id, Course__c>();
		Map <Id, Section__c> groupMap = new Map <Id, Section__c>();
		for (Section__c sect: newList){
			system.debug(sect);
			/*Autopop Section Name in Spanish - US1310*/
			if (sect.Schedule_Group__c!=null) groupIds.add(sect.Schedule_Group__c);
			if (sect.Course__c!=null) courseIds.add(sect.Course__c);
		}
		if (!courseIds.isEmpty()){
			for (Course__c c: [select id, name, name_spanish__c from Course__c where id in :courseIds]){
				courseMap.put(c.id, c);
			}
		}
		if (!groupIds.isEmpty()){
			for (Section__c s: [select id, name, name_spanish__c from Section__c where id in :groupIds AND RecordType.DeveloperName='Schedule_Group']){
				groupMap.put(s.id, s);
			}
		}
		for (Section__c sect: newList){
			if (sect.Schedule_Group__c!=null && sect.Course__c !=null){
				String spanishCourseName = courseMap.get(sect.course__c).name_spanish__c !=null ? courseMap.get(sect.course__c).name_spanish__c : null;
				String  spanishGroupName = groupMap.get(sect.Schedule_Group__c).name_spanish__c !=null? groupMap.get(sect.Schedule_Group__c).name_spanish__c  : groupMap.get(sect.Schedule_Group__c).name;
				if (spanishCourseName!=null) sect.Name_Spanish__c = spanishGroupName + ' - ' + spanishCourseName;
				system.debug(sect);
			}
		}
	}
	
	public static void checkSectionReportingPeriodDeletion(Map <Id, Section_ReportingPeriod__c> oldMap){
		Map <String, Boolean> srpValidationMap = new Map <String, Boolean>();
		Set <Id> sectionIds = new Set <Id>();
		Set <Id> timeIds = new Set <Id>();
		Set <String> schedulerRefIds = new Set <String>();
		//DE2987 changing Map<ID,String> to Map<String,String> since scheduler reference id will be string, NOT id
		Map <String, String> schedulerRefIdToSrpMap  = new Map <String, String>();
		Map <String, List <Scheduled_Section__c>> srpKeySsDelMap= new Map <String, List <Scheduled_Section__c>>();
		List <Scheduled_Section__c> ssDelList = new List <Scheduled_Section__c>();
		for (Section_ReportingPeriod__c srp:oldMap.values()){
			sectionIds.add(srp.section__c);
			timeIds.add(srp.time__c);
			srpValidationMap.put(srp.section__c+'-'+srp.time__c, false);
			if (srp.Scheduler_ReferenceId__c!=null){
				schedulerRefIdToSrpMap.put(srp.Scheduler_ReferenceId__c, srp.section__c+'-'+srp.time__c);
			}
		}
		List <AggregateResult> aggrs =[SELECT  section__c sect, time__c rp, COUNT(id) total
														FROM Assignment__c
														where section__c in :sectionIds
														and time__c in :timeIds
														GROUP BY section__c, time__c];
		for (AggregateResult ja : aggrs){
			if ((Decimal)ja.get('total')>0){
				String srpKey = (String)ja.get('sect')+'-'+(String)ja.get('rp');
				if (srpValidationMap.keySet().contains(srpKey)){
					srpValidationMap.put(srpKey, true);
				}
			}
		}
		
		for (Scheduled_Section__c ss: [select id, section_reference_id__c, reporting_period__c, section__c from Scheduled_Section__c 
														where (section_reference_id__c in :schedulerRefIds 
														or section__c in:sectionIds)]){
			String srpKey;
			if (ss.section_reference_id__c!=null){
				srpKey= schedulerRefIdToSrpMap.get(ss.section_reference_id__c);
			}
			else srpKey = ss.section__c+'-'+ss.reporting_period__c;
			if (srpValidationMap.containsKey(srpKey)){
				if (srpKeySsDelMap.get(srpKey)!=null){
					srpKeySsDelMap.get(srpKey).add(ss);
				}
				else {
					srpKeySsDelMap.put(srpKey, new List <Scheduled_Section__c>{ss});	
				}
			}
		}
		//Delete Sessions; will prevent if has attendance
		List <Session__c> sessionList = new List <Session__c>();
		Set <Id> sessIdSet = new Set <Id>();
	
		for (Session__c sess : [select id, section__c, time__c, (select id from Attendance__r limit 1)  from Session__c 
																where section__c in :sectionIds
																and time__c in :timeIds]){
			String srpKey = sess.section__c+'-'+sess.time__c;
			if (srpValidationMap.keySet().contains(srpKey)){
				if (!srpValidationMap.get(srpKey)){
					if (sess.attendance__r.size()>0){
						srpValidationMap.put(srpKey, true);
					}
					else {
						sessionList.add(sess);
						if (srpKeySsDelMap.get(srpKey)!=null){
							ssDelList.addAll(srpKeySsDelMap.get(srpKey));
						}
					}
				}
			}
		}
		//PTN - need a way to restore any sessions that shouldnt be deleted.  
		for (Section_ReportingPeriod__c srp:oldMap.values()){
			String srpKey = srp.section__c+'-'+srp.time__c;
			if (srpValidationMap.get(srpKey)){
				srp.addError('Deletion of Section Reporting Period not allowed. Please delete all assignments & attendance related to the reporting period and section being purged');
			}
		}
		if (!sessionList.isEmpty()){
			delete sessionList;
		}
		if (!ssDelList.isEmpty()){
			delete ssDelList;
		}
	}
	
	/****************** End of Utility Methods ************************************/
}