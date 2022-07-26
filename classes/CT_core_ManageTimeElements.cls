public with sharing class CT_core_ManageTimeElements {
	public static Map<String, Picklist_Value__c> plStringValueMap;

	public static void time_Validation(List <Time_Element__c> teList, boolean isInsert){
		Set<ID> parentIds = new Set<ID>();
		for(Time_Element__c te: teList) parentIds.add(te.Parent_Time_Element__c);
			Set<ID> parentTEs = new Set<ID>();
			for(Time_Element__c te: teList){
				if(te.Parent_Time_Element__c != null){
					parentTEs.add(te.Parent_Time_Element__c);
				}
			}

			if(!parentTEs.isEmpty()){
				Map<ID,Time_Element__c> parentMap = new Map<ID,Time_Element__c>(
					[SELECT id, Name__c, Date_Start_Date__c, Start_Time__c, End_Date__c, End_Time__c, Reporting_Period__c, (SELECT id FROM Time__r) 
					FROM Time_Element__c 
					WHERE id IN :parentTEs]
				);

				loadTimePicklistValues();
				for (Time_Element__c te: teList){
					if(te.Date_Start_Date__c > te.End_Date__c){
						te.Date_Start_Date__c.addError('Start date cannot be later than end date.');
					}

					if (te.Parent_Time_Element__c!=null){
						Time_Element__c parent = parentMap.get(te.Parent_Time_Element__c);
						System.debug('\n\n parent.Id => ' + parent.Id + '\n');
						System.debug('\n\n te.Date_Start_Date__c => ' + te.Date_Start_Date__c + '\n');
						if (parent.Date_Start_Date__c > te.Date_Start_Date__c){
							 te.Date_Start_Date__c.addError('Child Time Element cannot have a start date earlier than parent: '+parent.Date_Start_Date__c.format());
						}
						if (parent.End_Date__c < te.End_Date__c){
							 te.End_Date__c.addError('Child Time Element cannot have an end date later than parent: '+parent.End_Date__c.format());
						}
						if (parent.Start_Time__c > te.Start_Time__c){
							 te.End_Time__c.addError('Child Time Element cannot have a start time earlier than parent: '+parent.End_Time__c);
						}
						if (parent.End_Time__c < te.End_Time__c){
							 te.Start_Time__c.addError('Child Time Element cannot have a end time later than parent:'+parent.Start_Time__c);
						}
						//DE3422
						if (parent.Time__r.size()>0 && parent.Reporting_Period__c && isInsert){
							te.Parent_Time_Element__c.addError('This reporting period already has a final time element.	Reporting periods may not have more than 1 child time element.');
						}
					}

					if (te.Parent_Time_Element__c==null){
						Map <Id, Picklist_Value__c> plMap = CT_core_SoqlUtils.getPlValues('Time',null);
						if (plMap.get(te.Picklist_Value__c)!=null){
							if (plMap.get(te.Picklist_Value__c).Name=='Year'){
								Boolean bMatch = false;
								for (Time_Element__c newTe:	[SELECT id , Date_Start_Date__c, end_date__c
															FROM Time_Element__c
															WHERE picklist_Value__c =: plStringValueMap.get('Year').id AND Id <> :te.Id]){
							if (newTe.Date_Start_Date__c <= te.End_Date__c && te.End_Date__c <= newTe.End_Date__c ){
								bMatch=true;
								break;
							}
							else if (newTe.Date_Start_Date__c <= te.Date_Start_Date__c && te.Date_Start_Date__c <= newTe.End_Date__c ){
								bMatch=true;
							break;
							}
						}
						if (bMatch){
							te.addError('School Year time element objects may not overlap, please leverage the existing year or modify the start and end date');
						}
					}
					else {
						te.addError('This time element type requires a parent time element');
					}
				}
			}
		}
	}
}

public static void checkChildDates(List<Time_Element__c> teList){
	Set<ID> parentIDs = new Set<ID>();
	for(Time_Element__c te: teList) parentIDs.add(te.id);
	List<Time_Element__c> children = [SELECT id, Parent_Time_Element__c, Date_Start_Date__c, End_Date__c FROM Time_Element__c WHERE Parent_Time_Element__c IN :parentIDs];
	if(children.size() > 0){
		Map<ID,List<Time_Element__c>> childToParent = new Map<ID,List<Time_Element__c>>();
		for(Time_Element__c te: children){
			if(childToParent.containsKey(te.Parent_Time_Element__c))
				childToParent.get(te.Parent_Time_Element__c).add(te);
			else
				childToParent.put(te.Parent_Time_Element__c,new List<Time_Element__c>{te});
		}
		//time element's start and end dates cannot be edited to exclude its children
		for(Time_Element__c te: teList){
			List<Time_Element__c> child = childToParent.get(te.id);
			if(child.size() > 0){
				Date startDate;
				Date endDate;
				for(Time_Element__c childTe: child){
					if(childTe.Date_Start_Date__c < startDate || startDate==null) startDate = childTe.Date_Start_Date__c;
					if(childTe.End_Date__c > endDate || endDate==null) endDate = childTe.End_Date__c;
				}
//				if(te.Date_Start_Date__c > startDate)
//					te.Date_Start_Date__c.addError('Parent cannot have a start date after the earliest child start date: '+startDate.format()+'.	Please update the start date of the child time elements if you would like to update the start date to '+te.Date_Start_Date__c.format()+'.');
//				if(te.End_Date__c < endDate)
//					te.End_Date__c.addError('Parent cannot have an end date before the latest child end date: '+endDate.format()+'.	Please update the end date of the child time elements if you would like to update the end date to '+te.End_Date__c.format()+'.');
			}
		}
	}
}

public static void checkReportingPeriodOverlap(List <Time_Element__c> teList){
	Map <Id, List <Time_Element__c>> rpMap = new Map <Id, List <Time_Element__c>>();//Map to store parent -> rp relationship & data
	for (Time_Element__c te: teList){
		if (te.Parent_Time_Element__c!=null && te.reporting_period__c){
				rpMap.put(te.parent_time_element__c, new List <Time_Element__c>());
		}
	}
	if (!rpMap.keySet().isEmpty()){
		for (Time_Element__c te: [select Parent_Time_Element__c, id, date_start_date__c, end_date__c from Time_Element__c where parent_Time_Element__c in :rpMap.keySet() ORDER by Date_Start_Date__c ASC]){
			rpMap.get(te.parent_time_element__c).add(te);
		}
		for (Time_Element__c te: teList){
			if (te.Parent_Time_Element__c!=null && te.reporting_period__c){
				for (Time_Element__c rpTe: rpMap.get(te.parent_time_element__c) ){
					if (rpTe.id != te.id){
						if(te.date_start_date__c < rpTe.date_start_date__c){
							if(te.end_date__c >= rpTe.date_start_date__c) {
//								te.End_Date__c.addError('Reporting period end date cannot be later than next reporting period start date: '+rpTe.Date_Start_Date__c.format());
								CT_SetupWizard_Utils.addMessage(apexpages.severity.fatal, 'Reporting period end date cannot be later than next reporting period start date: '+rpTe.Date_Start_Date__c.format());
								break;
							}
						}
						if(te.end_date__c > rpTe.end_date__c){
							if(te.date_start_date__c <= rpTe.end_date__c) {
//								te.Date_Start_Date__c.addError('Reporting period start date cannot be earlier than prior reporting period end date: '+rpTe.End_Date__c.format());
								CT_SetupWizard_Utils.addMessage(apexpages.severity.fatal, 'Reporting period start date cannot be earlier than prior reporting period end date: '+rpTe.Date_Start_Date__c.format());
								break;
							} 
						}
					}
				}
			}
		}
	}
}

public static void checkReportingPeriodDelete(Map<Id, Time_Element__c> oldTeMap){
	Set <Id> rpIds			= new Set <Id>();
	Set <Id> hasSectionSet = new Set <Id>();
	for(Time_Element__c oldTe: oldTeMap.values()){
		if (oldTe.Reporting_Period__c){ //If time element is a reporting period
			rpIds.add(oldTe.id);
		}
	}
	if (!rpids.isEmpty()){
		for (Section_ReportingPeriod__c srp: [select id, time__c from Section_ReportingPeriod__c where time__c in:rpIds]){
			hasSectionSet.add(srp.time__c);
		}
	}
	if (!hasSectionSet.isEmpty()){
		for(Time_Element__c oldTe: oldTeMap.values()){
			if (hasSectionSet.contains(oldTe.id)){
				oldTe.addError('Please delete all sections related to this reporting period before deleting it.');
			}
		}
	}
}

public static void checkReportingPeriodUpdates(Map<Id, Time_Element__c> newTeMap, Map<Id, Time_Element__c> oldTeMap){
	Set <Id> smallerRangeIdSet = new Set <Id>();
	Set <Id> largerRangeIdSet = new Set <Id>();
	Set <Id> termIds			= new Set <Id>();
	Set <Id> schoolIds			= new Set <Id>();
	Set <Date> allChangedDateSet = new Set <Date>();
	Map <Id, Boolean> bValidTimeChangeMap = new Map <Id, Boolean>();
	for(Time_Element__c newTe: newTeMap.values()){
		if (newTe.Reporting_Period__c){ //If time element is a reporting period
			Time_Element__c oldTe = oldTeMap.get(newTe.id);
			if ((oldTe.Date_Start_Date__c!=newTe.Date_Start_Date__c)||(oldTe.End_Date__c!=newTe.End_Date__c)){ //and any of the start/end dates differ
				if ((oldTe.Date_Start_Date__c<newTe.Date_Start_Date__c)||( oldTe.End_Date__c>newTe.End_Date__c)){ //Smaller ranges
					smallerRangeIdSet.add(newTe.id);
					bValidTimeChangeMap.put(newTe.id, true);
				}
				if((oldTe.Date_Start_Date__c>newTe.Date_Start_Date__c)||(oldTe.End_Date__c<newTe.End_Date__c)) {	//Larger time ranges
					largerRangeIdSet.add(newTe.id);
				}
				termIds.add(newTe.parent_time_element__c);
			}
		}
	}
	system.debug('smallerRangeIdSet~~~'+smallerRangeIdSet);
	system.debug('largerRangeIdSet~~~'+largerRangeIdSet);
	if (!smallerRangeIdSet.isEmpty()||!largerRangeIdSet.isEmpty()){
		Map <Id, Set <Id>> activeTermToSchoolMap = new Map<Id, Set <Id>>(); //gives the mapping for the term to schools using that term
		for (Setup__c setup: [select id, school__c, Term__c from Setup__c
									where active__c = true
									and 	term__c in:termIds]){
			schoolIds.add(setup.school__c);//add the school to the set of unique schoolIds
			if(activeTermToSchoolMap.get(setup.term__c)==null){
				activeTermToSchoolMap.put(setup.term__c, new Set <Id>{setup.school__c});
			}
			else activeTermToSchoolMap.get(setup.term__c).add(setup.school__c);
		}

		if (!smallerRangeIdSet.isEmpty()){ //If there are now time elements with smaller ranges
			Map <Id,Set <Date>> removedDayMap = new Map <Id,Set <Date>>();

			for (Id teId: smallerRangeIdSet){
				removedDayMap.put(teId, new Set <Date>());
				Time_Element__c newTe = newTeMap.get(teId);
				Time_Element__c	oldTe =	oldTeMap.get(teId);
				if (oldTe.Date_Start_Date__c<newTe.Date_Start_Date__c){
					Date d=oldTe.Date_Start_Date__c;
					while (d< newTe.Date_Start_Date__c){
						removedDayMap.get(teId).add(d);//Add the removed day to the map
						d=d.addDays(1);
					}
				}
				if ( oldTe.End_Date__c>newTe.End_Date__c) {
					Date d=oldTe.End_Date__c;
					while (d> newTe.End_Date__c){
						removedDayMap.get(teId).add(d);//Add the removed day to the map
						d=d.addDays(-1);
					}
				}
				allChangedDateSet.addAll(removedDayMap.get(teId));
			}

			Map <Id, List <Session__c>> sessionsToDeleteMap = new Map<Id, List <Session__c>>();
			if (!removedDayMap.isEmpty()){
				for (Session__c sess: [select id, time__c, record_attendance__c, attendance_submitted__c from Session__c
										where time__c in:smallerRangeIdSet
										and	session_date__c in: allChangedDateSet
										order BY Time__c]){
											system.debug(sess);
					if (bValidTimeChangeMap.get(sess.time__c)){ //only if the time element is still valid to 'update'
						if (sess.record_attendance__c&&sess.attendance_submitted__c){	//Check whether this session has attendance records
								system.debug(sess);
							bValidTimeChangeMap.put(sess.time__c,false)	; //Session cannot be deleted so simply mark the time element that cannot be updated
						}
						else {
							if (sessionsToDeleteMap.get(sess.time__c)==null) sessionsToDeleteMap.put(sess.time__c, new List <Session__c>{sess}); //initialize the list for the map if its null
							else sessionsToDeleteMap.get(sess.time__c).add(sess);
						}
					}
				}
			}
			List <Session__c> sessionsToDeleteList = new List <Session__c>();
			try {
				for(Time_Element__c newTe: newTeMap.values()){
					if (!bValidTimeChangeMap.get(newTe.id)) newTe.addError('Please first delete any submitted attendance/session records for the days being removed. ');
					else {
						if (sessionsToDeleteMap.get(newTe.id) != null) {
							sessionsToDeleteList.addAll(sessionsToDeleteMap.get(newTe.id));//Valid time element so delete any sessions
						}
					}
				}

				if (!sessionsToDeleteList.isEmpty()){
					delete sessionsToDeleteList;
				}

			} catch(Exception e) {
				System.debug(e.getMessage());
			}
		}

		if (!largerRangeIdSet.isEmpty()){ //If there are now time elements with larger ranges
			Set <Id> rpsWithSessions = new Set <Id>();
			Map <Id, Set <Id>> rpTomasterScheduleTemplateMap = new Map<Id, Set<Id>>();
			for (Session__c sess: [select id, time__c from Session__c where Time__c in:largerRangeIdSet]){
				rpsWithSessions.add(sess.time__c);
			}
			for (Schedule_Template__c st: [select id, reporting_period__c from Schedule_Template__c where is_master__c=true and reporting_period__c in:largerRangeIdSet]){
				if (rpTomasterScheduleTemplateMap.get(st.reporting_period__c)==null){
					rpTomasterScheduleTemplateMap.put(st.reporting_period__c, new Set<Id>{st.id});
				}
				else rpTomasterScheduleTemplateMap.get(st.reporting_period__c).add(st.id);
			}

			List <Schedule_Day__c> scheduleDayList = new List <Schedule_Day__c>();
			Map <Id,Set <Date>> addedDayMap = new Map <Id,Set <Date>>();
			for (Id teId: rpsWithSessions){
				addedDayMap.put(teId, new Set <Date>());
				Time_Element__c newTe = newTeMap.get(teId);
				Time_Element__c	oldTe =	oldTeMap.get(teId);
				if (oldTe.Date_Start_Date__c>newTe.Date_Start_Date__c){
					Date d=oldTe.Date_Start_Date__c.addDays(-1);
					while (d>= newTe.Date_Start_Date__c){
						if (!rpTomasterScheduleTemplateMap.isEmpty()){
							for (Id stId: rpTomasterScheduleTemplateMap.get(teId)){
								scheduleDayList.add(new Schedule_Day__c(Schedule_Template__c=stId, Day__c=d, ReferenceId__c=stId+String.valueOf(d), Reporting_Period__c=teId));
							}
						}
						d=d.addDays(-1);
					}
				}
				if ( oldTe.End_Date__c<=newTe.End_Date__c) {
					Date d=oldTe.End_Date__c.adddays(1);
					while (d< newTe.End_Date__c){
						for (Id stId: rpTomasterScheduleTemplateMap.get(teId)){
							scheduleDayList.add(new Schedule_Day__c(Schedule_Template__c=stId, Day__c=d, ReferenceId__c=stId+String.valueOf(d), Reporting_Period__c=teId));
						}
						system.debug('d~~~'+d);
						system.debug('newTe.End_Date__c~~~'+newTe.End_Date__c);
						d=d.addDays(1);
					}
				}
			}

			if (!scheduleDayList.isEmpty()){
				upsert scheduleDayList ReferenceId__c;
				Set <Id> scheduleDayIds = new Set <Id>();
				for (Schedule_Day__c sd: scheduleDayList){
					scheduleDayIds.add(sd.id);
				}
				CT_BatchInsertSessions b = new CT_BatchInsertSessions(scheduleDayIds);
				Id batchId = Database.executeBatch(b,1);
			}
		}
	}
}

	public static void isInsert(Map<Id, Time_Element__c> newTeMap){
		List <Setup__c> setupList = new List<Setup__c>();
		Set <Id> schoolIds = new Set <Id>();
		loadTimePicklistValues();
		Map <Id, Picklist_Value__c> plValueMap = new Map<ID, Picklist_Value__c>(plStringValueMap.values());
		Map <Id, Setup__c> currentSchoolSetupMap = new Map <Id, Setup__c>();
		Map <Id, Id> oldNewSetupMap = new Map <Id,Id>();

		//So we really only process time elements with the idea that there should only be trigger sizes of 1.
		//Generally this means we do not support dataloader for the loading of time elements.
		Time_Element__c firstIncommingElement = newTeMap.values()[0];
		if(firstIncommingElement.Picklist_Value__c == null || plValueMap.get(firstIncommingElement.Picklist_Value__c) == null || plValueMap.get(firstIncommingElement.Picklist_Value__c).Name != 'Year'){
			return;
		} else {
			//load account data we need
			//doing this query just for the account id set is really inefficent, we probably should just write a query for all active setups
			for (Account a: [select id from Account
							where RecordType.Name='School' OR RecordType.Name='Summer School']){
				schoolIds.add(a.id);
			}
			for (Setup__c s: CT_core_SoqlUtils.getActiveSetups(schoolIds).values()){
				currentSchoolSetupMap.put(s.school__c, s);
			}

			for(ID schoolID: schoolIds){
				if(currentSchoolSetupMap.containsKey(schoolID)){
					setupList.add(cloneSetup(currentSchoolSetupMap.get(schoolID),firstIncommingElement));
				} else {
					setupList.add(new Setup__c(Year__c = firstIncommingElement.id, School__c = schoolId, Active__c=true));
				}
			}

			upsert setupList;
		}
	}

	public static Setup__c cloneSetup(Setup__c currentSetup, Time_Element__c newYear){
		system.debug(currentSetup);
		Setup__c s = currentSetup.clone(false);
		s.OwnerID = UserInfo.getUserId();
		s.Term__c = null;
		s.Year__c = newYear.id;
		s.Published__c=false;
		s.Active__c=false;
		s.New_School_Year__c = newYear.New_School_Year__c;

		s.Processed_EOY_Data__c = false;
		s.Purged_EOY_Data__c = false;
		s.Processed_Historical_Data__c = false;
		s.Data_Activated__c = false;
		s.Schedule_End_Date__c = null;
		s.Schedule_Start_Date__c = null;
		s.Purged_Two_Years_Old_Data__c = false;

		s.RecordTypeId = CT_core_SoqlUtils.getRecordTypesBySobject('Setup__c').get('Unpublished');
		return s;
	}

	public static void manage_FinalTimeElements(Map<Id, Time_Element__c> newTeMap){
		List <Time_Element__c> finalTeList = new List <Time_Element__c>();
		Set <Id>					teIds		= new Set<Id>();
		loadTimePicklistValues();
			for(Time_Element__c te:newTeMap.values()){
				if (te.Reporting_Period__c){
					Time_element__c newTe = te.clone(false);
					newTe.Name__c = te.Name__c+'-Final';
					newTe.Picklist_Value__c = plStringValueMap.get('Final').id;
					newTe.Reporting_Period__c=false;
					newTe.Reference_Id__c = te.id+'-F';
					newTe.Parent_Time_Element__c = te.id;
					finalTeList.add(newTe);
				}
			}
			if (!finalTeList.isEmpty()){
				upsert finalTeList	Reference_Id__c;
			}
	}

	public static void manage_DeleteChildTimeElements(Map<Id, Time_Element__c> oldTeMap){
		List <Time_Element__c> finalTeList = new List <Time_Element__c>();
		Set <Id> teIds = new Set<Id>();
		for(Time_Element__c te:oldTeMap.values()){
			teIds.add(te.id);
		}
		if (!teIds.isEmpty()){
			for (Time_Element__c te: [select id from Time_Element__c where parent_time_element__c in :teIds]){
				finalTeList.add(te);
			}
		}
		if (!finalTeList.isEmpty()){
			delete finalTeList;
		}
	}

	public static void loadTimePicklistValues(){
		if(plStringValueMap == null){
			plStringValueMap = CT_core_SoqlUtils.getPlStringValues('Time', null);
		}
	}

	public static testMethod void test_coreManageTimeElements(){
		test.startTest();
			testDataSetupUtil_v2.setUPCoreData(5);
			testDataSetupUtil_v2.setUpStaffData(5);

			List<Time_Element__c> teList = new List<Time_Element__c>();
			Time_Element__c te = testDataSetupUtil_v2.masterYear;
			te.clone(false);
			te.date_start_date__c = te.date_start_date__c.addDays(1);
			te.end_date__c = te.date_start_date__c.addDays(10);
			te.Reporting_Period__c = true;
			teList.add(te);
			Time_Element__c te2 = testDataSetupUtil_v2.masterYear;
			te2.clone(false);
			te2.date_start_date__c = te.date_start_date__c.addDays(11);
			te2.end_date__c = te.date_start_date__c.addDays(120);
			te2.Reporting_Period__c = true;
			teList.add(te2);
			try {
				upsert teList;
			} catch (exception e){}

			testDataSetupUtil_v2.createSessions(5,te,TestDataSetupUtil_v2.sectionsList[1].Id);

			//overlapping years
			te.date_start_date__c = te.date_start_date__c.addDays(-100);
			try {
				update te;
			} catch (exception e){}

			testDataSetupUtil_v2.createSessions(5,te2,TestDataSetupUtil_v2.sectionsList[1].Id);

			//overlapping years
			te2.Date_Start_Date__c = te2.date_start_date__c.addDays(100);
			try {
				update te2;
			} catch (exception e){}

			try {
				delete te;
			} catch (exception e){}
		test.stoptest();
	}
}