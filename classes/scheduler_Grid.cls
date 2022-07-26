global with sharing  class scheduler_Grid {
	public Set <String> periodSet  {get;set;}
	public List <String> tempperiodList  {get;set;}
	public List <Period__c> periodList  {get;set;}
	public List <String> periodStringList  {get;set;}
	public List <String> courseList {get;set;}
	public List <Room__c> roomList {get;set;} 
	public List <Staff__c> staffList {get;set;}
	public List <SelectOption> roomOptionList {get;set;}
	public List <SelectOption> courseOptionList {get;set;}
	public Map <Id, Course__c> courseMap {get;set;}
	//DE2995 course to a list of possible # of reporting periods based on course weightings
	public Map <ID,Map<String,List<Course_Weightings__c>>> courseToCombinations {get;set;}
	public List<SelectOption> numReportingPeriodOptions {get;set;}
	public List <SelectOption> staffOptionList {get;set;}
	public String selectedRoom {get;set;}
	public String selectedCourse {get;set;}
	public String selectedStaff {get;set;}
	public String setupId {get;set;}
	public core_SetupWrapper cSetup {get;set;}
	public boolean bRoomView	{get;set;}
	public boolean dnmView	{get;set;}
	public boolean bScheduleGrid {get;set;}
	public List <cRowWrapper> rowList {get;set;}
	public string rpId  {get;set;}
	public List <Time_Element__c> reportingPeriodList {get;set;}
	public Map <Id, Time_Element__c> rpMap {get;set;}
	public Map <String, List <Scheduled_Section__c>> scheduleStaffMap {get;set;}
	public Map <String, List <Scheduled_Section__c>> scheduleDNMStaffMap {get;set;}
	public Map <String, List <Scheduled_Section__c>>scheduleRoomMap {get;set;}
	public Map <String, List <Scheduled_Section__c>> scheduleDNMRoomMap {get;set;}
	public Time_Element__c rPeriod {get;set;}
	public List <Section_ReportingPeriod__c> unpublishedSectionList {get;set;}
	public Section__c section {get;set;}
	public Section_ReportingPeriod__c sectionRp									 {get;set;}
	public string	   sectionId   {get;set;}
	public Map <Id, Integer> configuredSectionMap; //Added for DE209 need to keep track of how many have been added to grid
	public String[]	 sErrorMessages;
	public boolean bErrors {get;set;}
	public boolean  bEditSectionConfig {get;set;}
	
	public Map <Integer, Set <Id>> c {get;set;}
	public Map <Integer, cTabWrapper>  periodFocusMap {get;set;}
	public Map <Integer, cTabWrapper> staffFocusMap {get;set;}
	public Map <Integer, cTabWrapper> roomFocusMap {get;set;}
	public List <cTabWrapper> periodTabWrapperList {get;set;}
	public List <cTabWrapper> staffTabWrapperList {get;set;}
	public List <cTabWrapper> roomTabWrapperList {get;set;}
	
	/* US - 702 Limit Staff in Grid*/ 
	public List <SelectOption> filterStaffOptionList {get;set;}
	public List <SelectOption> mainFilterOptionList {get;set;}
	public Id[]				   selectedStaffFilter {get;set;}
	public String[]				selectedPeriodFilter {get;set;}
	public List <String> allDayList  {get;set;}
	public string							 sSelectedPeriod {get;set;}
	public string							 sSelectedStaff {get;set;}
	public string							 sSelectedRoom {get;set;}
	public string							 sLastColor							   {get;set;} //US944 - Variable to remember last color 
	
	public List <SelectOption> filterPeriodOptionList {get;set;}
	
	/* US 1046 - Copy from Another Reporting Period*/
	public string																			 selectedCopyRp {get;set;}
	public string																			 selectedMainFilterOption {get;set;}
	public List <SelectOption>	   reportingPeriodCopyOptions {get;set;}
	public List<SelectOption> reportingPeriodOptions {get;set;}
	
	public Boolean isManaged {get; set;}

	public scheduler_Grid (){
		isManaged = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
		initPage();
		/*Getting the parameters from the URL*/
		if (System.currentPageReference().getParameters().containsKey('setupid')!=null){
			setupId = System.currentPageReference().getParameters().get('setupid');  //Invoked upon 'New' from Setup
			cSetup=new core_SetupWrapper(core_SoqlUtils.getSetupById(setupId),'grid');
			reportingPeriodList = cSetup.reportingPeriodList;
			for (Time_Element__c te: reportingPeriodList){
				reportingPeriodOptions.add(new SelectOption(te.id, te.Name__c));
			}
			if(SetupWizard_Utils.checkSchedule(cSetup.setup)){
				SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'At least one section must be scheduled for '+cSetup.reportingPeriodList[0].Name__c+' before moving on to the next step.');
			}
		}
	}
	
	public void initPage(){
		sSelectedPeriod = '0';
		sSelectedStaff = '0';
		serrorMessages  = new String[]{};
		courseMap = new Map <Id, Course__c>();
		unpublishedSectionList = new List <Section_ReportingPeriod__c>();
		configuredSectionMap = new Map <Id, Integer>(); //DE209
		scheduleRoomMap = new Map <String, List <Scheduled_Section__c>>();
		scheduleDNMRoomMap = new Map <String, List <Scheduled_Section__c>>();
		scheduleStaffMap = new Map <String, List <Scheduled_Section__c>>();
		scheduleDNMStaffMap = new Map <String, List <Scheduled_Section__c>>();
		roomOptionList = new List <SelectOption>();
		staffOptionList = new List <SelectOption>();
		filterStaffOptionList = new List <SelectOption>();
		filterPeriodOptionList = new List <SelectOption>();
		mainFilterOptionList = new List <SelectOption>();
		courseOptionList = new List <SelectOption>();
		numReportingPeriodOptions = new List<SelectOption>();
		reportingPeriodOptions = new List<SelectOption>();
		reportingPeriodList = new List <Time_Element__c>();
		staffList = new List <Staff__c>();
		periodStringList = new List <String>();
		courseList = new List<String> {};
		roomList = new List <Room__c>();
		bScheduleGrid = false;
		bRoomView = false;
		dnmView = false;
		bEditSectionConfig=false;
		bErrors = false;
		allDayList = new List<String>{'1*','2*','3*','4*','5*','6*'};
		sLastColor = '#CFEEF8';//US 488
		periodFocusMap = new Map <Integer,cTabWrapper>();
		staffFocusMap = new Map <Integer,cTabWrapper>();
		roomFocusMap = new Map <Integer, cTabWrapper>();
		periodTabWrapperList = new List <cTabWrapper>();
		staffTabWrapperList = new List <cTabWrapper>();
		roomTabWrapperList = new List <cTabWrapper>();
		reportingPeriodCopyOptions = new List <SelectOption>(); //US1046
	} 

	/*Utility Methods for Scheduler Grid*/
	public void resetErrorVars(){
		bErrors = false;
		sErrorMessages.clear();
	}

	public void processErrorMessages(){
		for (String s: sErrorMessages){
			Apexpages.addMessage(new apexpages.message(apexpages.severity.fatal, s));
			if (!bErrors) bErrors = true;
		}
	}
	
	/*End Utility Methods*/
	
	public void initScheduleGrid(){
		if (rpId!=null){
			reportingPeriodCopyOptions.clear();
			for (Time_Element__c te: reportingPeriodList){
				if (te.id == rpid) {
					rPeriod = te;
					cSetup.selectedTab = rPeriod.name__c+'grid';
				}
				else reportingPeriodCopyOptions.add(new SelectOption(te.id, te.Name__c));
			}
			cSetup=new core_SetupWrapper(cSetup.setup,rPeriod.name__c+'grid');
			queryScheduledSections();
			queryPeriods();
			runStaffQuery(false);
			mainFilterOptionList.clear();
			queryStaff();
			if(cSetup.setup.room_dependent__c) queryRooms();
			for(Course_Course_Catalog__c c: [select id, course__r.number_of_reporting_periods__c, course__r.name, course__c , course__r.course_number__c
													from Course_Course_Catalog__c 
													where course_catalog__c =:cSetup.setup.course_catalog__c
													order by course__r.name asc]){
				courseList.add(c.course__r.name);
				courseMap.put(c.course__c, c.course__r);
				if (c.course__r.name!=null) courseOptionList.add(new SelectOption(c.course__c, c.course__r.name+' - '+c.course__r.course_number__c));
			} 
			//DE2995 need what number of reporting period combinations are allowed for each course
			//when course is selected on section modal, only selectable number of reporting periods should be combinations that include course weightings
			courseToCombinations = new Map<ID,Map<String,List<Course_Weightings__c>>>();
			if(courseMap.size() > 0){
				createCourseCombinationMap(courseMap.keySet());
			}
			if (cSetup.setup.Room_Dependent__c){
				if (roomList.isEmpty()){ 
					sErrorMessages.add('No Rooms Created, please create rooms and then retry. ');
				}
			}
			if (staffList.isEmpty()){
				sErrorMessages.add('No Staff Created, please create staff and then retry. ');
			}
			if (courseList.isEmpty()){
				sErrorMessages.add('No Courses Enabled, please associate a course catalog and then retry. ');
			}
			if (!sErrorMessages.isEmpty()){
				processErrorMessages();
			}
			else {
				bScheduleGrid = true;
				processView();
				/*Need to get the unpublished sections to allow admins to assign to individual cells*/
				reQuerySections();
			}
		}
	}
	
	/*Section Edit/Create Logic*/
	public void newSection(){
		bEditSectionConfig=true;
		section = new Section__c(RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Unpublished'), 
										School__c = cSetup.school.id, 
										Reporting_Period__c= rpId,
										is_section__c = true,
										Number_of_Reporting_Periods__c='1',
										Number_of_Staff__c='1',
										Time__c = cSetup.setup.Year__c,
										color__c = sLastColor, //US 488
										Record_Attendance__c=true);   
	} 
 
	public void editSection(){
		sectionRp = new Section_ReportingPeriod__c();
		section = new Section__c();
		if(sectionId!=null){
			sectionRp = [SELECT id, Number_of_Periods__c ,ReferenceId__c, RecordType.Name, 
								Section__r.RecordType.Name, Section__r.Description__c ,
								Section__r.Number_of_Reporting_Periods__c ,Section__r.name,
								Section__r.color__c, Section__r.section_number__c, 
								Section__r.grade_level__c, Section__r.all_grades__c, Section__r.course__c, 
								Section__r.advisory__c, Section__r.daily_attendance__c, Section__r.has_homework__c,
								Section__r.record_Attendance__c,Section__r.Number_of_Periods__c,
								Section__r.Course__r.Name,
								 Section__r.Course__r.Course_Number__c,
								section__r.number_of_staff__c,
								section__r.Room__c,
								section__r.No_Meeting__c,
								section__r.Name_Spanish__c //US1310
								FROM Section_Reportingperiod__c
								WHERE section__c =:sectionId
								AND time__c =:rpId];
			//DE2495
			if(sectionRp.RecordType.Name=='Unpublished'){
				if(sectionRp.Section__r.RecordType.Name=='Unpublished'){
					section = sectionRp.Section__r;
					selectedCourse = section.Course__c;
					bEditSectionConfig = true;
				}
				else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This section has already been published and cannot be edited.'); 
			}
			else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This section has already been published for '+rPeriod.Name__c+' and cannot be edited.');
		}
		else SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This section is not available to be edited.');
	}
	
	public void cancelSection(){
		bEditSectionConfig=false;
		reQuerySections();
	}

	public void saveSection(){
		List<Section_ReportingPeriod__c> secRepPeriodList = new List<Section_ReportingPeriod__c>();
		resetErrorVars(); 
		section.course__c = selectedCourse;
		sLastColor =  section.color__c;
		//DE2995 number of reporting periods now selectable
		//if (section.id ==null){
			//if (tempCourse.Number_of_Reporting_Periods__c==null) section.Number_of_Reporting_Periods__c='1';
			//else section.Number_of_Reporting_Periods__c = string.valueOf(tempCourse.Number_of_Reporting_Periods__c);
		//}
		List <Time_Element__c> teList = core_SoqlUtils.getTimeElementsByTerm(cSetup.setup.term__c, true);		   
		try {
			Course__c tempCourse = courseMap.get(selectedCourse);
			if(!courseToCombinations.containsKey(section.Course__c) || !courseToCombinations.get(section.Course__c).containsKey(section.Number_of_Reporting_Periods__c)){
				sErrorMessages.add(tempCourse.Name+' does not have weightings for '+section.Number_of_Reporting_Periods__c+' reporting periods.  Please check the course weightings if you would like to create the section for '+section.Number_of_Reporting_Periods__c+' reporting periods.');
			} else if(courseToCombinations.get(section.Course__c).get(section.Number_of_Reporting_Periods__c).size()!=integer.valueOf(section.Number_of_Reporting_Periods__c)){
				sErrorMessages.add(tempCourse.Name+' has malformed weightings for '+section.Number_of_Reporting_Periods__c+' reporting periods.  Please check the course weightings and verify that there are no duplicate weightings.');
			}
			//DE2495
			if(section.Id!=null){
				Section__c oldSection = [SELECT id, No_Meeting__c, Record_Attendance__c, Daily_Attendance__c FROM Section__c WHERE id=:section.Id];
				if(section.No_Meeting__c!=oldSection.No_Meeting__c ||
					section.Record_Attendance__c!=oldSection.Record_Attendance__c ||
					section.Daily_Attendance__c!=oldSection.Daily_Attendance__c){
					//one of the attendance values changed--delete scheduled sections & section/reporting period period__c
					List<Section_ReportingPeriod__c> sectionRPs = new List<Section_ReportingPeriod__c>();
					for(Section_ReportingPeriod__c srp: [SELECT id, Period__c, RecordType.Name, Time__r.Name__c FROM Section_ReportingPeriod__c WHERE Section__c=:section.Id]){
						if(srp.RecordType.Name=='Unpublished'){
							srp.Period__c = '';
							sectionRPs.add(srp);
						}
						else sErrorMessages.add('This section has already been published for '+srp.Time__r.Name__c+' and cannot update the Sectional Attendance, Daily Attendance, or No Meeting fields.');
					}
					if(sErrorMessages.isEmpty()){
						if(!sectionRPs.isEmpty()) update sectionRPs;
						List<Scheduled_Section__c> ss = [SELECT id, Section_ReportingPeriod__c FROM Scheduled_Section__c WHERE Section__c=:section.Id];
						if(!ss.isEmpty()) delete ss;
					}
				}
			}
			if(sErrorMessages.isEmpty()) upsert section;
		}
		catch (exception e){
			if (e.getMessage().contains('DUPLICATE_VALUE')){
				sErrorMessages.add('Section Name with name '+section.name+' has already been created, please use a different name');
			}
			else {
				string link = 'Selected Setup , ' + cSetup.setup.id + 'Selected Rp:  '+ rpId;
				Global_Error__c ge = Error_Handling.handleError(link, 'Scheduler', 'Scheduler Grid: Section details: ' + section, e);
				insert ge;
				sErrorMessages.add('An error occurred, please contact your administrator');
			}
		}
		if (sErrorMessages.isEmpty()){
			if(sectionRp != null){
				sectionRp.Number_of_periods__c = section.Number_of_Periods__c;
				upsert sectionRp ReferenceId__c;
			} 
			bEditSectionConfig=false;
			refreshSections();
		}
		else processErrorMessages();
	}
	/*End of Section Create/Edit Methods*/

	/*Start Grid Methods*/
	public void refreshGrid(){
		String selectedType = Apexpages.currentPage().getParameters().get('selectedType');
		if (selectedType == 'p'){
			sSelectedPeriod = Apexpages.currentPage().getParameters().get('selectedTab');
			dnmView = periodFocusMap.get(Integer.valueOf(sSelectedPeriod)).bAllDay; //Check the all day boolean from the retrieved tabWrapper
		
		}
		else if (selectedType =='s'){
			sSelectedStaff = Apexpages.currentPage().getParameters().get('selectedTab');
			bRoomView = false;
		}
		else{
			sSelectedRoom = Apexpages.currentPage().getParameters().get('selectedTab');
			bRoomView = true;
		}
		refreshSections();
	}

	public void processView(){
		rowList = new List <cRowWrapper>();
		if(bRoomView){
			roomList = roomFocusMap.get(Integer.valueOf(sSelectedRoom)).roomList; //If Room Tab is selected; then set the Room List to the list available through the FocusMap
			if (!dnmView) processCellData (roomList, scheduleRoomMap);
			else processCellData (roomList, scheduleDNMRoomMap);
		}
		else {
			if (sSelectedStaff!=null){
				if (staffFocusMap.get(Integer.valueOf(sSelectedStaff))!=null){
					staffList = staffFocusMap.get(Integer.valueOf(sSelectedStaff)).staffList;
					if (!dnmView) processCellData (staffList,  scheduleStaffMap);
					else processCellData (staffList,  scheduleDNMStaffMap);
				}
			}
		}
	}


	public void refreshSections(){
		queryScheduledSections();
		processView();
		reQuerySections();
	}

	public void reQuerySections(){
		unpublishedSectionList.clear();
		for (Section_ReportingPeriod__c s: [select Section__c,Section__r.Text_Color__c,Section__r.Number_of_Reporting_Periods__c ,	  
								Section__r.course__c, Section__r.course__r.name,Section__r.name,Section__r.course__r.course_number__c,
								Section__r.color__c , Number_of_Periods__c,
								Section__r.Description__c ,
								Section__r.section_number__c,
								Section__r.grade_level__c, Section__r.all_grades__c,
								Section__r.advisory__c,
								Section__r.daily_attendance__c, Section__r.has_homework__c,
								Section__r.record_Attendance__c,
								section__r.number_of_staff__c,
								section__r.No_Meeting__c
						from Section_ReportingPeriod__c
						WHERE recordType.name = 'Unpublished'
						and Time__c =:rpId
						and Section__r.school__c =:cSetup.school.id
						order by section__r.course__r.name]){
			if ((!dnmView&&!s.Section__r.No_Meeting__c&&!s.Section__r.Daily_Attendance__c)||(dnmView&&(s.Section__r.No_Meeting__c||s.Section__r.Daily_Attendance__c))){ // Needed to filter the unscheduled section list
				/*DE209 Changes*/
				Integer tempNumPeriods;
				Integer numConfigured;
				Boolean bAdd = true;
				if (configuredSectionMap.get(s.section__c)!=null){
					numConfigured=configuredSectionMap.get(s.section__c);
				}
				else {
					numConfigured=0;
				}
				if ((s.number_of_periods__c==null || s.number_of_periods__c=='') || (s.section__r.number_of_staff__c ==null||s.section__r.number_of_staff__c =='')){
					tempNumPeriods=1;
				}
				else {
					if (!bRoomView) tempNumPeriods=Integer.valueOf(s.number_of_periods__c)*Integer.valueOf(s.section__r.number_of_staff__c);
					else tempNumPeriods=Integer.valueOf(s.number_of_periods__c); //# should only be # of Periods for Room View
				}
				if (tempNumPeriods > numConfigured){ //Compare # of Sections they are allowed to drag vs ones that have already been configured
					s.number_of_periods__c = string.valueOf(tempNumPeriods-numConfigured);//TA467 US592
				}
				else bAdd=false; //All are configured; do not add to the list, move to the next Section
				if (s.Section__r.color__c==null) s.Section__r.Color__c='#CFEEF8';
				else {
					if (!s.section__r.color__c.contains('#')) s.Section__r.Text_Color__c ='#000000';
					else s.Section__r.Text_Color__c =core_ColoringUtils.getTextColor(s.Section__r.color__c);
				}
				if (bAdd) unpublishedSectionList.add(s);
			}
		}
	}
	
	

/*
	Given a set of course ids, populate the courseToCombination map using the course weightings.
	When a course is selected for a section, the options given for number of reporting periods will populate using this map.
	@param courseIds the set of possible courses
*/
public void createCourseCombinationMap(Set<ID> courseIds){
	List<Course_Weightings__c> courseWeightings = [SELECT id, Course__c, Reporting_Period_Type__c, Reporting_Period_Type__r.Corresponding_Value__c FROM Course_Weightings__c WHERE Course__c IN :courseIds AND (NOT Key__c like '%Final')];
	//validation map is to check for each course(ID), check that the weightings are correctly set up
	//ex: if reporting period type is for 2 reporting periods, make sure 2 weightings are set up for that type
	Map<ID,Map<Integer,List<Course_Weightings__c>>> validationMap = new Map<ID,Map<Integer,List<Course_Weightings__c>>>();
	for(Course_Weightings__c cw: courseWeightings){
		ID course = cw.Course__c;
		Integer numRp = Integer.valueOf(cw.Reporting_Period_Type__r.Corresponding_Value__c);
		if(validationMap.containsKey(course)){
			Map<Integer,List<Course_Weightings__c>> temp = validationMap.get(course);
			if(temp.containsKey(numRp)){
				temp.get(numRp).add(cw);
			}
			else{
				temp.put(numRp,new List<Course_Weightings__c>{cw});
			}
			validationMap.put(course,temp);
		}
		else{
			validationMap.put(course,new Map<Integer,List<Course_Weightings__c>>{numRp=>new List<Course_Weightings__c>{cw}});
		}
	}
	
	if(validationMap.size()>0){
		for(ID course: validationMap.keySet()){
			Map<Integer,List<Course_Weightings__c>> numRpToWeightings = validationMap.get(course);
			if(numRpToWeightings.size()>0){
				for(Integer numRp: numRpToWeightings.keySet()){
					//if the number of reporting periods expected matches the number of course weightings,
					//weightings are set up correctly and combination is valid
					String value = String.valueOf(numRp);
					if(courseToCombinations.containsKey(course)) courseToCombinations.get(course).put(value,numRpToWeightings.get(numRp));
					else courseToCombinations.put(course,new Map<String,List<Course_Weightings__c>>{value=>numRpToWeightings.get(numRp)});
				}
			}
		}
	}
}
	
	public void queryScheduledSections(){
		scheduleRoomMap.clear();
		scheduleStaffMap.clear();
		scheduleDNMRoomMap.clear();
		scheduleDNMStaffMap.clear();
		configuredSectionMap.clear();
		for (Scheduled_Section__c ss: [Select  Section__r.Description__c,
						Section__r.section_number__c,
						Section__r.grade_level__c, Section__r.all_grades__c, 
						Section__r.advisory__c,
						section__r.Room__c, section__r.No_Meeting__c ,
						Section__r.daily_attendance__c, Section__r.has_homework__c,  section__r.text_color__c,
						Section__r.record_Attendance__c, Section_ReportingPeriod__c , section__r.name, section__r.color__c, course__r.name, Staff__r.id, Staff__r.name, Room__r.id, Room__r.name, Room__r.number__c, s.Room_Key__c, s.Type__c, s.SystemModstamp, s.Start_Time__c, s.Start_Time_Text__c, s.Staff__c, s.Section__c, s.Schedule_Template__c, s.Room__c, s.Reporting_Period__c, s.staff_key__c, s.Period_Key__c, s.OwnerId, s.Name, s.LastModifiedDate, s.LastModifiedById, s.IsDeleted, s.Id, s.End_Time__c, s.End_Time_Text__c, s.CreatedDate, s.CreatedById, s.Course__c, s.Account__c
							From Scheduled_Section__c s
							Where reporting_Period__c =:rPeriod.id
							And account__c =:cSetup.school.id 
							And section__c !=null]){
			system.debug('~~~~~ ss '+ss);
			processConfiguredSectionDetails(ss.section__c);
			if (ss.Section__r.color__c==null) ss.Section__r.Color__c='#CFEEF8';
			else {
				if (!ss.section__r.color__c.contains('#'))  ss.Section__r.Text_Color__c ='#000000';
				else ss.Section__r.Text_Color__c =core_ColoringUtils.getTextColor(ss.Section__r.color__c);
			}
			if (ss.Section__r.Daily_Attendance__c||ss.Section__r.No_Meeting__c){
				processSsMap(ss,scheduleDNMStaffMap, false);
				processSsMap(ss,scheduleDNMRoomMap, true);
			}
			else {
				processSsMap(ss,scheduleStaffMap, false);
				processSsMap(ss,scheduleRoomMap, true);
			}
		}
	}
	
	public static void processSsMap(Scheduled_Section__c ss, Map <String, List <Scheduled_Section__c>> ssListMap, boolean bRoom){
		if (bRoom){
			if (ssListMap.get(ss.room_key__c)==null){
				ssListMap.put(ss.room_key__c, new List <Scheduled_Section__c> {ss});
			}
			else ssListMap.get(ss.room_key__c).add(ss);
		}
		else {
			if (ssListMap.get(ss.staff_key__c)==null){
				ssListMap.put(ss.staff_key__c, new List <Scheduled_Section__c> {ss});
			}
			else ssListMap.get(ss.staff_key__c).add(ss);
		}
	}


	public void runStaffQuery(boolean bFiltered){
		staffList.clear();
		system.debug('selectedStaffFilter~~~~'+selectedStaffFilter);
		if (selectedStaffFilter ==null) bFiltered=false;
		else if (selectedStaffFilter.isEmpty()) bFiltered=false;
		if (!bFiltered){
				filterStaffOptionList.clear();
				for (Staff__c s: [select id, name , Staff_Last_Name__c 
													from Staff__c 
													where organization__c =:cSetup.setup.school__c
													and Active__c=true
													and instructional_staff__c = true
													order by staff_last_name__c, name asc]){
				staffOptionList.add(new SelectOption (s.id+'|'+s.name, s.name));
				filterStaffOptionList.add(new SelectOption(s.id, s.name));
				staffList.add(s); 
			}
		}
		else {
			for (Staff__c s: [select id, name , Staff_Last_Name__c 
													from Staff__c 
													where organization__c =:cSetup.setup.school__c
													and Active__c=true
													and instructional_staff__c = true
													and id in :selectedStaffFilter
													order by staff_last_name__c, name asc]){
				staffList.add(s);
			}
		}
	}
	
	public void queryRooms(){
		for (Room__c r: [select id, name, number__c from Room__c
												where school__c=:cSetup.setup.school__c
												and Schedulable__c = true
												order by NAME asc]){
			roomOptionList.add(new SelectOption(r.id+'|'+String.valueOf(r.Name), String.valueOf(r.Name)));
			roomList.add(r);	
		}
		Integer k = 0;
		Room__c lastRoom;
		for (Room__c room: roomList){
			lastRoom = room;
			if (roomFocusMap.get(k)==null){
				roomFocusMap.put(k, new cTabWrapper (k, new List <Room__c>{room}, 'Room', false));
			}
			else {
				roomFocusMap.get(k).roomList.add(room);
			}
			if (roomFocusMap.get(k).roomList.size()==8){
				roomFocusMap.get(k).sLabel +=' - ' + room.Name;
				k++;
			}
		}
		if (roomFocusMap.get(k)!=null) roomFocusMap.get(k).sLabel +=' - ' +lastRoom.Name;
		roomTabWrapperList = roomFocusMap.values();
		for (cTabWrapper tw: roomTabWrapperList){
			mainFilterOptionList.add(new SelectOption (string.valueOf(tw.iId)+'|'+tw.sType, 'ROOM(S): '+ tw.sLabel));
		}
	}
	
	public void queryStaff(){
				staffFocusMap.clear();
				Integer k = 0;
				Integer z = 0;
				Staff__c lastStaff;
				system.debug('staffList~~~'+staffList);
				for (Staff__c s: staffList){
		lastStaff = s;
				if (staffFocusMap.get(k)==null){
								staffFocusMap.put(k, new cTabWrapper (k, new List <Staff__c>{s}, 'Staff', false));
				}
				else {
								 staffFocusMap.get(k).staffList.add(s);
				}
				
				z++;
				if (staffFocusMap.get(k).staffList.size()==8){
								staffFocusMap.get(k).sLabel +=' - ' + s.Staff_Last_Name__c;
								 k++;
				} 
				}
				if (staffFocusMap.get(k)!=null) staffFocusMap.get(k).sLabel +=' - ' + lastStaff.Staff_Last_Name__c;
				staffTabWrapperList = staffFocusMap.values();
				for (cTabWrapper tw: staffTabWrapperList){
					mainFilterOptionList.add(new SelectOption (string.valueOf(tw.iId)+'|'+tw.sType, 'STAFF: '+tw.sLabel));
				}
			   if (!mainFilterOptionList.isEmpty()){
			   	 selectedMainFilterOption = mainFilterOptionList[0].getValue();
			   }
}

	public void queryPeriods(){
		periodSet = new Set<String>();
		Map <String, Period__c>		 periodMap = new Map<String, Period__c>();
		Map <String, Period__c>		 periodSortMap = new Map<String, Period__c>();
		Map <Integer, List <String>> orderPeriodMap = new Map <Integer, List <String>>();
		
		List <String> temporderList = new List <String>{};//List of periods
		Set <Integer>  orderCheckSet = new Set <Integer>{};
		for (Period__c p: [select id,Name , key__c, Order__c from Period__c
															 where schedule_template__r.setup__c =:setupId
															 and schedule_template__r.reporting_period__c =:rpId
															 order by Order__c]){
			if (!periodSet.contains(p.key__c)){
				periodSet.add(p.key__c);
				temporderList.add(p.key__c);
			}
			periodSet.addAll(allDayList);//Add in all day keys to Period Set DE1157
			periodMap.put(p.key__c, p);
		}
		temporderList.sort();
		
		Set <String> selectedPeriodFilterSet = new Set <String>();
		if (selectedPeriodFilter!=null){
			for (String p:selectedPeriodFilter ){
				selectedPeriodFilterSet.add(p);
			}
		}
		
		periodStringList.clear();
		for (String k: tempOrderList){
			filterPeriodOptionList.add(new SelectOption(k,k));
			if (selectedPeriodFilterSet.contains(k)||selectedPeriodFilter==null){
				periodStringList.add(k);
			}
		}
		Integer k = 0;
 		Integer z = 0;
 		periodFocusMap.clear();
  		for (String s: periodStringList){
			if (periodFocusMap.get(k)==null){
				periodFocusMap.put(k, new cTabWrapper (k, new List <Period__c>{periodMap.get(s)}, 'Period', false));
			}
			else periodFocusMap.get(k).periodList.add(periodMap.get(s));
			
			z++;
		
			if (periodFocusMap.get(k).periodList.size()==8){
				periodFocusMap.get(k).sLabel +=' - ' + s;
				k++;
			}
			else if (periodMap.keySet().size()==z)  periodFocusMap.get(k).sLabel +=' - ' + s;
		}
		Integer x = periodFocusMap.size();
		Integer y = 0;
		for (String s: allDayList){
			if (y==0){
				cTabWrapper tabWrap = new cTabWrapper (periodFocusMap.size(), new List <Period__c>{new Period__c(Key__c=s)}, 'Period', true);
				tabWrap.sLabel = 'All Day';
				periodFocusMap.put(x, tabWrap);
			}
			else periodFocusMap.get(x).periodList.add(new Period__c(Key__c=s));
			y++;
		}
		periodTabWrapperList = periodFocusMap.values(); //Set the complete period tablist based on the values
	}

public void filterStaff(){ 
	runStaffQuery(true);
	queryStaff();
	processView();
}

	public void filterPeriods(){ 
		queryPeriods();
		processView();
	}
	
	public void processConfiguredSectionDetails (Id sectionId){
		if (sectionId!=null) {
			/*Changed logic for DE209*/
			if (configuredSectionMap.get(sectionId)!=null){
				Integer configCount = configuredSectionMap.get(sectionId)+1;//Add one to keep track of how many have  been added
				configuredSectionMap.put(sectionId,configCount);
			}
			else configuredSectionMap.put(sectionId, 1);//Initialize with 1
		}
	}
	
	public  void copyScheduledSectionsForNewRp(){
		Id FromTimeId =selectedCopyRp;
		Id ToTimeId			= rPeriod.id;
		Map <String, Id> sectRpMap = new Map <String, Id>();
		for (Section_ReportingPeriod__c srp: [Select s.Time__c, s.SystemModstamp, s.Section__c, s.Scheduler_ReferenceId__c, s.ReferenceId__c, 
											s.RecordTypeId, s.Period__c, s.Number_of_periods__c, s.Name, s.LastModifiedDate, s.LastModifiedById, 
											s.LastActivityDate, s.IsDeleted, s.Id, s.CreatedDate, s.CreatedById 
											From Section_ReportingPeriod__c s
											where time__c = :ToTimeId]){
			sectRpMap.put(srp.section__c, srp.id);
		}
		List <Scheduled_Section__c> newSSList = new List <Scheduled_Section__c>();
		for (Scheduled_Section__c ss: [Select s.section__r.Name, s.Type__c, s.SystemModstamp, s.Start_Time__c, s.Start_Time_Text__c, s.Staff__c, 
											s.Section__c, s.Section_ReportingPeriod__c, s.Section_Reference_Id__c, s.Schedule_Template__c, s.Schedule_Group__c, 
											s.Schedule_Group_Name__c, s.Rounded_Start_Time__c, s.Rounded_End_Time__c, s.Room__c, s.Room_Key__c, 
											s.Reporting_Period__c, s.staff_key__c, s.Record_Attendance__c, s.Period_Key__c, s.OwnerId, s.No_Meeting__c, 
											s.Name, s.LastModifiedDate, s.LastModifiedById, s.IsDeleted, s.Id, s.Grade_Level__c, s.End_Time__c, 
											s.End_Time_Text__c, s.Daily_Attendance__c, s.CreatedDate, s.CreatedById, s.Course__c, s.Course_Name__c, s.Account__c 
											From Scheduled_Section__c s
											where Reporting_Period__c =:FromTimeId
											and Account__c =:cSetup.setup.school__c]){
			if (sectRpMap.get(ss.section__c)!=null&&periodSet.contains(ss.period_key__c)){
				Scheduled_Section__c clonedSs = ss.clone(false);
				clonedSs.OwnerID = UserInfo.getUserID();
				clonedSs.Reporting_Period__c = rPeriod.id;
				clonedSs.staff_key__c = clonedSs.staff_key__c.replace(FromTimeId,ToTimeId);
				clonedSs.needs_publish__c = true;
				if (clonedSs.room_key__c!=null) clonedSs.room_key__c = clonedSs.room_key__c.replace(FromTimeId,ToTimeId);
				clonedSs.Section_ReportingPeriod__c = sectRpMap.get(clonedSs.section__c);
				clonedSs.reference_id__c = clonedSs.Section_ReportingPeriod__c+'-'+clonedSs.period_key__c+clonedSs.Staff__c;
				newSSList.add(clonedSs);
			}
		}
		system.debug(newSSList);
		try {
			upsert  newSSList reference_id__c;
		}
		catch (exception e){
						string link = 'Selected Setup , ' + cSetup.setup.id + 'Selected Rp:  '+ rpId;
						Global_Error__c ge = Error_Handling.handleError(link, 'Scheduler', 'Scheduler Grid: Copying from Period '+FromTimeId+' to '+ToTimeId, e);
						insert ge;
						sErrorMessages.add('An error occurred, please contact your administrator');
		}
		refreshSections();
}



	public void processCellData (List <sObject> masterRowList,  Map <String, List <Scheduled_Section__c>> scheduledSectionMap){
		rowList.clear();
		for (sObject r: masterRowList){
			cRowWrapper rowWrap = new cRowWrapper(r,bRoomView);
			periodList = periodFocusMap.get(integer.valueOf(sSelectedPeriod)).periodList;
			for (Period__c p: periodList) {
				String key = rPeriod.id+'-'+p.key__c+'-'+r.id;
				SchedulerGrid_SectionWrapper sectionWrap;
				if (scheduledSectionMap.get(key)!=null){
					sectionWrap = new SchedulerGrid_SectionWrapper(scheduledSectionMap.get(key),p);
					//processConfiguredSectionDetails(sectionWrap.sectId);
				} 
				else sectionWrap = new SchedulerGrid_SectionWrapper(r, p, rPeriod, bRoomView);
				rowWrap.scheduledSections.add(sectionWrap);
			}
			if (math.mod(rowList.size(),15)==0) rowWrap.bHeader = true;
			rowList.add(rowWrap);
		} 
	}
	
	public class cRowWrapper{
		public Staff__c staff {get;set;}
		public Room__c room {get;set;}
		public List <SchedulerGrid_SectionWrapper> scheduledSections {get;set;}
		public boolean	 bHeader {get;set;} //Use variable to determine whether the headers should repeat 
		public cRowWrapper (sObject s, boolean bRoomView){
			if(bRoomView) this.room = (Room__c)s;
			else this.staff = (Staff__c)s;
			scheduledSections = new List<SchedulerGrid_SectionWrapper>();
		}
		public cRowWrapper(Staff__c s){
			this.staff = s;
			this.bHeader = false;
			scheduledSections = new List<SchedulerGrid_SectionWrapper>();
		}
		public cRowWrapper(Room__c r){
			this.room = r;
			this.bHeader = false;
			scheduledSections = new List<SchedulerGrid_SectionWrapper>();
		}
	}
	
	public class cTabWrapper{
		public List <Period__c> periodList	{get;set;}
		public List <Staff__c> staffList	{get;set;}
		public List <Room__c> roomList		{get;set;}
		public String sLabel				{get;set;}
		public Integer iId					{get;set;}
		public boolean bSelected			{get;set;}
		public boolean bAllDay				{get;set;}
		public string sType					{get;set;}
		public cTabWrapper(Integer j, List <sObject> filteredList, string sType, boolean allDay){
			this.bAllDay = allDay;
			this.bSelected = false;
			this.iId = j;
			
			if (sType =='Room'){
				Room__c r = (Room__c)filteredList[0];
				sLabel = r.Name;
				roomList = filteredList;
				this.sType='r';
			}
			else if (sType =='Period') {
				Period__c p = (Period__c)filteredList[0];
				sLabel = p.key__c;
				periodList = filteredList;
				this.sType ='p';
			}
			else {		
				staffList = filteredList;
				Staff__c s = (Staff__c)staffList[0];
				sLabel = s.staff_last_name__c;
				this.sType ='s';
			}
		}
	}

	public void saveSections() {
		String cmc = ApexPages.currentPage().getParameters().get('cmc');
		String deleteList = ApexPages.currentPage().getParameters().get('deleteList');
		system.debug('~~~~~ cmc '+cmc);
		system.debug('~~~~~ deleteList '+deleteList);
		List <Scheduled_Section__c> tempUpsertSsList = new List <Scheduled_Section__c>();
		List <Scheduled_Section__c> deleteSsList = new List <Scheduled_Section__c>();
		if (cmc!=null&cmc!=''){
			for(String s:cmc.split(',')){
				list <String> splitList = s.split(';');
				Scheduled_Section__c tempScheduledSection;
				if (splitList[0]!=null&&splitList[0]!='') tempScheduledSection = new Scheduled_Section__c(Id = splitList[0]);
				else tempScheduledSection = new Scheduled_Section__c();
				if (splitList[1]!=null&&splitList[1]!='') tempScheduledSection.Section_ReportingPeriod__c = splitList[1];
				if (splitList[2]!=null&&splitList[2]!='') tempScheduledSection.Period_Key__c = splitList[2];
				if (splitList[3]!=null&&splitList[3]!='') tempScheduledSection.Staff__c = splitList[3];
				if (splitList[4]!=null&&splitList[4]!='') tempScheduledSection.Daily_Attendance__c = boolean.valueOf(splitList[4]);
				if (splitList[5]!=null&&splitList[5]!='') tempScheduledSection.Record_Attendance__c = boolean.valueOf(splitList[5]);
				if (splitList.size()>6) {
					if (splitList[6]!=null&&splitList[6]!='') tempScheduledSection.Room__c = splitList[6];
				}
				tempUpsertSsList.add(tempScheduledSection);
			}
			if(!tempUpsertSsList.isEmpty()){
				upsert tempUpsertSsList;
				SetupWizard_Utils.addMessage(apexpages.severity.CONFIRM,tempUpsertSsList.size()+' record(s) updated!');
			}
		}
		if(deleteList!=null && deleteList!=''){
			List<String> splitList = deleteList.split(',');
			for (String s: splitList){
				deleteSsList.add(new Scheduled_Section__c(Id=s));
			}
			if (!deleteSsList.isEmpty()){
				delete deleteSsList;
				Apexpages.addMessage(new apexpages.message(apexpages.severity.confirm, deleteSsList.size()+' record(s) deleted!'));
			}
		}
	}
	
	@RemoteAction
	global static List<String> saveSections_Remote(String cmc, String [] deleteList) {
			List<String> retList = new List<String>();
		try{
			List <Scheduled_Section__c> tempUpsertSsList = new List <Scheduled_Section__c>();
			List <Scheduled_Section__c> deleteSsList = new List <Scheduled_Section__c>();
			system.debug(cmc);
			if (cmc!=null&cmc!=''){
				for(String s:cmc.split(',')){
					list <String> splitList = s.split(';');				
					//			sectionArrayList.push(ssId+";"+sectionRpId+";"+staffId+";"+periodKey+";"+StaffId+";"+RoomId);
					Scheduled_Section__c tempScheduledSection;
					if (splitList[0]!=null&&splitList[0]!='')		tempScheduledSection		 		 	 = new Scheduled_Section__c(Id = splitList[0]);
					else 	 tempScheduledSection		 		 	 = new Scheduled_Section__c();
					if (splitList[1]!=null&&splitList[1]!='')					tempScheduledSection.Section_ReportingPeriod__c = splitList[1];
					if (splitList[2]!=null&&splitList[2]!='')					tempScheduledSection.Period_Key__c = splitList[2];
					if (splitList[3]!=null&&splitList[3]!='')					tempScheduledSection.Staff__c = splitList[3];
					if (splitList.size()>4)
						{
							 if (splitList[4]!=null&&splitList[4]!='')					tempScheduledSection.Room__c = splitList[4];
						}
					tempUpsertSsList.add(tempScheduledSection);
				}
				upsert tempUpsertSsList;
			}
			for (String s: deleteList){
				deleteSsList.add(new Scheduled_Section__c(Id=s));
			}
			if (!deleteSsList.isEmpty()){
				delete deleteSsList;
				Apexpages.addMessage(new apexpages.message(apexpages.severity.confirm, deleteSsList.size()+' record(s) deleted!'));
			}
		}
		Catch (Exception e) {
			if(e.getTypeName() == 'System.DmlException'){
				for (Integer i = 0; i < e.getNumDml(); i++) {
					if(e.getDmlMessage(i).length()>18){//In case error is not bad entered grade
						throw e;
					}
					retList.add(e.getDmlMessage(i));
				}
			
		
			return retList;
			}
			else{
				throw e;
			}
		}
		return retList;
	}

	public void deleteSessions(Set<Id> ssList){
		Integer attRecsCnt = 0;
		Set<Id> sectionRpIds = new Set<Id>();
		Set<Id> sessionssectionIds = new Set<Id>();
		Set<Id> sessionIds;
		List<Section__c> SectionIdsToUpdate = new List<Section__c>();
		Set<Date> scheduleDaysSet;
		Set<Id> schedTempSet;
		Set<String> keySet = new Set<String>();
		List<Session__c> sessionsToDelete = new List<Session__c>();
		List<Section_ReportingPeriod__c> updateSectRps = new List<Section_ReportingPeriod__c>();
							   
		sErrorMessages.clear();
							   
		for(Scheduled_Section__c ss : [SELECT Period_Key__c,Section_ReportingPeriod__c,Section__c FROM Scheduled_Section__c WHERE Id in:ssList]){
			keySet.add(ss.Period_Key__c);
			sectionRpIds.add(ss.Section_ReportingPeriod__c);
			sessionssectionIds.add(ss.Section__c);
		}
		if(keySet.size() > 0){
			schedTempSet = new Set<Id>();
			for(Period__c p : [SELECT Schedule_Template__c FROM Period__c WHERE Key__c in : keySet 
								AND Schedule_Template__r.Setup__c = : setupId 
								AND Schedule_Template__r.Reporting_Period__c = : rpId
								order by Order__c]){
				schedTempSet.add(p.Schedule_Template__c);
			}
								
			if(schedTempSet !=null && schedTempSet.size() > 0){		  
				scheduleDaysSet = new Set<Date>();
				for(Schedule_Day__c sd :[SELECT Id,day__c FROM Schedule_Day__c 
											WHERE Schedule_Template__c in : schedTempSet 
											AND Reporting_Period__c = :rpId]){	
					scheduleDaysSet.add(sd.Day__c);
				}
				sessionIds = new Set<Id>();
				for(Session__c sess : [SELECT Id FROM Session__c WHERE Section__c in: sessionssectionIds AND Session_Date__c in : scheduleDaysSet]){
					sessionsToDelete.add(sess);
					sessionIds.add(sess.Id);
				}
																
				if(sessionIds.size() > 0){
					attRecsCnt = [SELECT COUNT() FROM Attendance__c WHERE Session__c in : sessionIds];
					if(attRecsCnt == 0){
						delete sessionsToDelete; 
																								
						for(Section_ReportingPeriod__c srp : [SELECT Id, RecordTypeId FROM Section_ReportingPeriod__c WHERE Section__c in: sessionssectionIds AND Time__c = : rpId]){
							srp.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section_ReportingPeriod__c').get('UnPublished');
							updateSectRps.add(srp);
						}
						System.debug('-------updateSectRps--------------------'+updateSectRps);
						if(updateSectRps.size() > 0){
										update updateSectRps;
						}
						System.debug('------After Update -updateSectRps--------------------'+updateSectRps);
						for(Section__c sec : [SELECT Id,RecordTypeId FROM Section__c
												WHERE Id in:sessionssectionIds 
												AND Reporting_Period__c =: rpId]){
							sec.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Unpublished');
							SectionIdsToUpdate.add(sec);
						}
						System.debug('-------SectionIdsToUpdate--------------------'+SectionIdsToUpdate);
						if(SectionIdsToUpdate.size() > 0){
							update SectionIdsToUpdate; 
						}
						System.debug('------After -SectionIdsToUpdate--------------------'+SectionIdsToUpdate);																		
					}else{
						sErrorMessages.add('You cannot delete Sections associated to attendance records.');
						if (!sErrorMessages.isEmpty()){
							processErrorMessages();
						}
					}
				}
			}
		}
	}
	
	public void updateSecRepPeriods(Set<Id> secIds){
		Map<Id,List<String>> secRpToSchedSecPeriod = new Map<Id,List<String>>();
		List<Section_ReportingPeriod__c> updateSecRpList = new List<Section_ReportingPeriod__c>();
		updateSecRpList = [SELECT Id,Section__c
						   FROM Section_ReportingPeriod__c 
						   WHERE Section__c in: secIds
						   AND Time__c =: rpId];
		for(Scheduled_Section__c ss : [SELECT Section__c, Period_Key__c FROM  Scheduled_Section__c WHERE Section__c in: secIds AND Reporting_Period__c =: rpId]){
			if(secRpToSchedSecPeriod.get(ss.Section__c)!=null)
				secRpToSchedSecPeriod.get(ss.Section__c).add(ss.Period_Key__c);
			else {
				List<String> newPeriodList = new List<String>();
				newPeriodList.add(ss.Period_Key__c);
				secRpToSchedSecPeriod.put(ss.Section__c,newPeriodList);
			}
		}
		for(Section_ReportingPeriod__c sp :updateSecRpList){
			String periodStr = '';
			if(secRpToSchedSecPeriod.get(sp.Section__c) != null){
				for(String s : secRpToSchedSecPeriod.get(sp.Section__c)){
					if (periodStr == '')
						periodStr = s;
					else if(!periodStr.contains(s))
						periodStr += ','+s;
				}
				sp.Period__c = periodStr; 
			}
			system.debug('sp~~~~'+sp);
		}
		update updateSecRpList;
	}

	public PageReference prev(){
		return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.STAFF,false,cSetup.setup);
	}
	
	public PageReference next(){
		if(!SetupWizard_Utils.checkSchedule(cSetup.setup)) return SetupWizard_Utils.goToSchoolStep(SetupWizard_Utils.STUDENT_SECTIONS,true,cSetup.setup);
		else{
			SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'At least one section must be scheduled for '+cSetup.reportingPeriodList[0].Name__c+' before moving on to the next step.');
			return null;
		}
	}
	
	global static void update_Ohio(){
		List <Scheduled_Section__c> ssList = new List <Scheduled_Section__c>();
		for (Scheduled_Section__c ss: [select id, reference_id__c, staff_key__c from Scheduled_Section__c where section_reportingPeriod__c !=null] ){
			ss.staff_key__c = ss.reference_id__c;
			ss.reference_id__c = null;
			ssList.add(ss);
		}
		if (!ssList.isEmpty()){
			update ssList;
		} 
	}
	
}