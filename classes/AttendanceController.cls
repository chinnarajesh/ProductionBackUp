public class AttendanceController {
	/* Global variables */
	public Setup__c		 					setup			{get;set;}	//active setup
	public string								sTheme			{get;set;}	//Placeholder to toggle themes
	public List <Section__c> 					sectionList		{get;set;}	//list of sections for the given staff member
	public Session__c							selectedSession	{get;set;}	//selected session taking attendance for
	public string								localStartTime	{get;set;} 	//Use this date time since visualforce doesn't allow you to properly display local times on page
	public string								localEndTime	{get;set;}	//same as above
	public Date 								atndate			{get;set;}  // attendance date
	public String 								section			{get;set;}  // section
	public String 								session			{get;set;}  // session
	public List<String> 						errorMsgs		{get;set;}  // set containing error messags for display
	public Boolean 								errorMsgsRend	{get;set;}  // render value for the error messages panel
	public Time_Element__c 						timeEl			{get;set;}  // record used to borrow the date field so that it formats on the VF page
	public List <AttendanceWrapper> 			atnWrapList		{get;set;}  // list of attendance wrappers to display on the page and capture updates
	public List<Student__c> 					studList		{get;set;}  // list of students
	public Map<ID, Attendance__c> 				studAttenMap	{get;set;}  // map of student ID's and their corresponding Attendance record for that day
	public String 								sectionName		{get;set;}  // name of the section attendance is being taken for
	public Boolean 								pullStudents	{get;set;}  // boolean that displays students based on whether a session is present for that day
	public Boolean 								sectDaily		{get;set;} 	// whether this section takes daily attendance
	public Boolean 								GoClicked		{get;set;}  // whether or not the go button has been clicked
	public List<SelectOption> 					StatusList      {get;set;}	    // list of possible attendance options to list for each student
	public core_BaseInfo_v2.cSchool_BaseInfo	baseObj 		{get;set;}	// base info--setup, school, etc.
	public AttendanceWrapper 					attendanceObj	{get;set;}	// used for sortDisplayData method
	public List <AttendanceWrapper> 			tempWrapList	{get;set;}	// stores attendance data while it is being updated
	public Id 									UserId			{get;set;}	// id of the logged in user
	public Map<ID,Integer> 						dailyTardyMap	{get;set;}	// map of student ID to number of tardies
	public Map<ID,Integer> 						dailyAbsentMap	{get;set;}	// map of student ID to number of absences
	public List<Picklist_Value__c>				pvs				{get;set;}	// list of picklist values to populate js array
	public List<SelectOption> yearOptions           		{get;set;}
    public List<SelectOption> schoolOptions           		{get;set;}
        public String yearId									{get;set;}
        public String schoolId									{get;set;}
    public  Map<String,Map<String,Setup__c>> 		 schoolSetupsByYearMap;
	public  Map<String,Map<String,List<Section__c>>> yearSectionsMap;
	public  Map <Id, Account>            schoolMap;
	public  Map <Id, Id>                 staffSchoolMap;    
	public  Picklist_Value__c defaultAttendanceValue;

	public Boolean attendanceTaken {get; set;}

	// No Argument Constructor
	public AttendanceController() {
		init();
	} // end no argument constructor 
	
	public void init(){
		goclicked = false;
		sectionList = new List<Section__c>();
		staffSchoolMap = new Map<Id,Id>();
        schoolMap = new Map<Id,Account>();
        yearSectionsMap = new Map<String,Map<String,List<Section__c>>>();

		//Create Status List based on Picklist Values object

		StatusList = new List<SelectOption>();

		try {
			if (UserId == null){
				UserId = UserInfo.getUserId();
			}
			
            core_BaseInfo_v2.initBaseInfo(true);
            system.debug(core_BaseInfo_v2.baseInfoObj.sectionList);
            system.debug(core_BaseInfo_v2.schoolSetupsByYearMap);
            system.debug(core_BaseInfo_v2.yearSectionsMap);
            system.debug(core_BaseInfo_v2.staffSchoolMap);
            system.debug(core_BaseInfo_v2.schoolMap);
            
            schoolSetupsByYearMap = core_BaseInfo_v2.schoolSetupsByYearMap;
            yearSectionsMap = core_BaseInfo_v2.yearSectionsMap;
            staffSchoolMap = core_BaseInfo_v2.staffSchoolMap;
            schoolMap = core_BaseInfo_v2.schoolMap;
			reloadYear();
        	yearOptions = getSchoolYears();    
        	schoolOptions = getSchools();
			
			

		} catch(Exception e) {
			Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'User: ' + userInfo.getFirstName() + ' ' + userInfo.getLastName() + ' is not associated with a staff record.  Therefore there are no sections available for selection.'));
		}

		this.atndate		= Date.today();
		this.errorMsgs		= new List<String>();
		this.errorMsgsRend	= false;
		this.timeEl			= new Time_Element__c();
		this.atnWrapList	= new List<AttendanceWrapper>();
		this.studList		= new List<Student__c>();
		this.studAttenMap	= new Map<ID, Attendance__c>();
		this.sectDaily		= false;
		this.attendanceObj	= new AttendanceWrapper();
		this.tempWrapList	= new List<AttendanceWrapper>();
		this.dailyTardyMap	= new Map<ID, Integer>();
		this.dailyAbsentMap	= new Map<ID, Integer>();
		
		
	}
	
	public  void getDefaultAttendanceValue(){
		if (defaultAttendanceValue ==null){
					  try{
						  defaultAttendanceValue = core_SoqlUtils.getDefaultAttendanceVal('Attendance', baseObj.activeSetup.id);
					  } catch (exception e){
						  try{
							  defaultAttendanceValue = core_SoqlUtils.getPlValuesList('Attendance', baseObj.activeSetup.id)[0];
						  } catch (exception e2){
							  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to find existing Attendance select values. Please check setup and try again.'));
						  }
					  }
		}
	}

	public List<SelectOption> getSectList() {
		List<SelectOption> sectList = new List<SelectOption>();
		
		if(sectionList==null||sectionList.isEmpty()) {
			sectList.add(new SelectOption('None.', 'No sections found.'));
		}
		else {
			for(Section__c s: sectionList){
				if(s.Record_Attendance__c || s.Daily_Attendance__c){
					sectList.add(new SelectOption(s.id, s.Name));
				}
			}
			if(sectList.size()==0){
				sectList.add(new SelectOption('None.', 'No sections found.'));
			}
		}
		return sectList;
	}

	public void retrieveStudents(){
		try{
			//refresh data
		 	Apexpages.getMessages().clear();
			atnWrapList.clear();
			studAttenMap.clear();
			tempWrapList.clear();
			dailyTardyMap.clear();
			dailyAbsentMap.clear();
			pullStudents = true;
			try{
				//grab the session from selected section and date
				Session__c tempsession = [select Section__r.name, Time__r.StartTime__c, Time__r.EndTime__c, Session_Date__c , Start_DateTime__c ,End_DateTime__c ,s.Id, s.Section__r.Daily_Attendance__c, Time__c, LastModified__c from Session__c s where s.Section__c = :section and s.Session_Date__c = :timeEl.Date_Start_Date__c and s.Record_Attendance__c = true  limit 1];
				timeEl = core_SoqlUtils.getTimeElementById(tempSession.time__c);
				selectedSession = tempsession;
				localStartTime = selectedSession.Start_DateTime__c.format('h:mm a');
				localEndTime = selectedSession.End_DateTime__c.format('h:mm a');
				session = tempsession.Id;
				sectDaily = tempsession.Section__r.Daily_Attendance__c;
				Section__c tempsect = [select Id, Name from Section__c where Id = :section limit 1];
				sectionName = tempsect.Name;
				if(!baseObj.activeSetup.Active__c){
            		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'The students listed below reflect this section\'s roster at the end of the selected year. Students who transferred out of this section prior to the end of the year will not be displayed.'));
            	}
			}
			catch(exception e){
				//if something failed, don't continue and alert the user that no sessions were available for attendance
				pullStudents = false;
				Apexpages.addMessage(new apexpages.message(apexpages.severity.fatal, 'The section you have chosen does not have any sessions where attendance is being taken on the date you chose.  Please choose a different section or date.'));
			}
			if(pullStudents){
				//grab the students enrolled in the section
				List <Student_Section__c> sstempList = [select Id, Student__c, Section__c from Student_Section__c where Section__c =:section AND ((Archived__c = false AND Active__c = true) OR (Archived__c = true AND Active__c = false))];
				Set <ID> studIDSet = new Set<ID>();
				Set <ID> sectIDSet = new Set<ID>();
				Set <ID> studSecIdSet = new Set <ID>();
				goClicked = true;
				for(Student_Section__c ss : sstempList){
					sectIDSet.add(ss.Section__c);
					studSecIdSet.add(ss.id);
				}
				
				/* START US1243 Updating past Attendance*/
				Map <ID, List <Enrollment_Tracking__c>> etMap = new Map <ID, List <Enrollment_Tracking__c>>();
				for (Enrollment_Tracking__c et: [select Active__c, student_section__c, id, start_date__c, end_date__c from Enrollment_Tracking__c where Student_Section__c in: studSecIdSet]){
					if (etMap.get(et.student_section__c)==null){
						etMap.put(et.student_section__c, new List <Enrollment_Tracking__c>{et});
					}
					else etMap.get(et.student_section__c).add(et);
				}
				system.debug(etMap.values());
				
				for(Student_Section__c ss : sstempList){
					if (etMap.get(ss.id)!=null){
						for (Enrollment_Tracking__c et: etMap.get(ss.id)){
							if (et.start_date__c.date() <= selectedSession.Session_Date__c&&et.end_date__c==null&&et.active__c){
								system.debug(ss);
								studIDSet.add(ss.Student__c); 
								break;
							}
							else if (et.start_date__c.date() <= selectedSession.Session_Date__c && et.end_date__c !=null && et.active__c){
								if (selectedSession.Session_date__c <et.end_date__c.date() ){
									system.debug(ss);
									studIDSet.add(ss.Student__c); 
									break;
								}
							}
						}
					}
					else{
						system.debug(ss);
						 studIDSet.add(ss.Student__c); 
					}
				}
				/* END US1243 Updating past Attendance Logic*/
				//get the student objects that the student sections reference
				studList = [select s.Student_Last_Name__c, s.Student_First_Name__c, s.Id, s.Name From Student__c s where s.Id IN :studIDSet order by Name, Student_First_Name__c ];
	
				//find if the students already have attendance records for this session
				for(Attendance__c a : [Select a.Status__c,  a.Departure_Time_Text__c, a.Arrival_Time_Text__c, a.Student__c, a.Picklist_Value__r.Name, a.Picklist_Value__c , a.Session__r.Start_DateTime__c, a.Session__r.End_DateTime__c, a.Session__c, a.Instructional_Time_Lost__c, a.Departure_Time__c, a.Daily__c, a.Comments__c, a.Arrival_Time__c, Locked__c From Attendance__c a where Student__c IN :studIDSet AND a.Session__c = :selectedSession.id ]){
					studAttenMap.put(a.Student__c, a);
				}
	
				attendanceTaken = Attendance_Utils.isAttendanceTaken(studList, studAttenMap);
				if(attendanceTaken) {
					If(String.isNotEmpty(selectedSession.LastModified__c)) {
						Apexpages.addMessage(new apexpages.message(apexpages.severity.info, selectedSession.LastModified__c));
					}
					else {
						Apexpages.addMessage(new apexpages.message(apexpages.severity.info, 'Attendance has been taken for this section because daily attendance has been recorded for the students in this section'));
					}
				}

				//get the number of tardies/absences the students currently have
				dailyTardyMap = Attendance_SoqlUtils.getTardyMap(studIDSet, section);
				dailyAbsentMap = Attendance_SoqlUtils.getAbsentMap(studIDSet, section);
				getDefaultAttendanceValue();
				for(Student__c s: studList){
					//if the student has a previous attendance record, update it
					if(studAttenMap.keyset().contains(s.Id)){
						AttendanceWrapper aw = new AttendanceWrapper(s.Id, s.Student_First_Name__c, s.Student_Last_Name__c,  studAttenMap.get(s.Id), timeEl);
						aw.statusVal = aw.atn.Picklist_Value__r.Name;
						if(dailyTardyMap.keyset().contains(s.Id))aw.tardyCnt = dailyTardyMap.get(s.Id);
						if(dailyAbsentMap.keyset().contains(s.Id))aw.absentCnt = dailyAbsentMap.get(s.Id);
						if (aw.atn.Arrival_Time__c!=null){
							aw.te.StartTime__c = aw.atn.Arrival_Time__c.format('hh:mm a');
							aw.te.Start_Time__c = aw.atn.Arrival_Time__c;
						}
						if (aw.atn.Departure_Time__c!=null){
							aw.te.EndTime__c = aw.atn.Departure_Time__c.format('hh:mm a');
							aw.te.End_Time__c = aw.atn.Departure_Time__c;
						}
						tempWrapList.add(aw);
					}
					//else make a new attendance record
					else{
					  AttendanceWrapper aw = new AttendanceWrapper(s.Id, s.Student_First_Name__c, s.Student_Last_Name__c, timeEl);
	
					  aw.atn.Picklist_Value__c = defaultAttendanceValue.id;
	
					  if(dailyTardyMap.keyset().contains(s.Id))aw.tardyCnt = dailyTardyMap.get(s.Id);
					  if(dailyAbsentMap.keyset().contains(s.Id))aw.absentCnt = dailyAbsentMap.get(s.Id);
					  aw.statusVal = defaultAttendanceValue.name;
					  tempWrapList.add(aw);
					}
				}
	
				//sort the attendance records by student last name
				atnWrapList=attendanceObj.sortDisplayData(tempWrapList);
				Integer i=1;
	
				for(AttendanceWrapper aw: atnWrapList){
					if (math.mod(i,2)==1) aw.rowStyle='odd';
						else aw.rowStyle='even';
					i++;
				}
	
	
			}
		} catch (Exception e){
			globalErrorMessage(null, 'Unexpected error while retrieving data.', e, true);
		}
	}

	/*
		Provide validation for times: arrival time != null for tardy, tardy time must be later than start time, early departure must be
		earlier than end time, etc.
		Save all changes to the attendance records
	*/
	public void save(){
		try {
			boolean bErrors = false;
			//Create the Picklist Values map for attendance
			Map<Id,Picklist_Value__c> pavalues = core_SoqlUtils.getPlValues('Attendance', baseObj.activeSetup.id);
	
			List<Attendance__c> upsAttenList = new List<Attendance__c>();
			for(AttendanceWrapper aw : atnWrapList){
				if(aw.atn.Session__c==null){
					aw.atn.Session__c = selectedSession.id;
				}
				if(aw.atn.Student__c==null){
					aw.atn.Student__c = aw.studID;
				}
				aw.atn.Daily__c = sectDaily;
	
				if (aw.te.StartTime__c!=null||aw.te.EndTime__c!=null){
					aw.te.Parent_Time_Element__c = timeEl.id;
					aw.te=core_TimeUtils.mapPeriodTime(aw.te);
					if (aw.te.Start_Time__c!=null) aw.atn.Arrival_Time__c = dateTime.newInstance(selectedSession.session_Date__c.year(),	selectedSession.session_Date__c.month(),	selectedSession.session_Date__c.day(),		aw.te.Start_Time__c.hour(),  aw.te.Start_Time__c.minute(),0);
					if (aw.te.End_Time__c!=null) aw.atn.Departure_Time__c=dateTime.newInstance(selectedSession.session_Date__c.year(),	selectedSession.session_Date__c.month(),	selectedSession.session_Date__c.day(),		aw.te.End_Time__c.hour(),  aw.te.End_Time__c.minute(),0);
				}
				map <String, Picklist_value__c> temp=core_SoqlUtils.getPlStringValues('Attendance', baseObj.activeSetup.id);
				aw.atn.Picklist_Value__c=temp.get(aw.statusVal).id;
				
				if((aw.atn.Arrival_Time__c!= null || aw.atn.Departure_Time__c != null) && !(pavalues.get(aw.atn.Picklist_Value__c).is_tardy__c
						|| pavalues.get(aw.atn.Picklist_Value__c).is_early_departure__c)){
					aw.atn.Arrival_Time__c = null;
					aw.atn.Arrival_Time_Text__c = '';
					aw.atn.Departure_Time__c = null;
					aw.atn.Departure_Time_Text__c = '';
				}
				if (aw.atn.Arrival_Time__c!=null)
					aw.atn.Arrival_Time_Text__c = aw.atn.Arrival_Time__c.format('hh:mm a');
				if (aw.atn.Departure_Time__c!=null)
					aw.atn.Departure_Time_Text__c = aw.atn.Departure_Time__c.format('hh:mm a');
	
				//begin error checking
				if(pavalues.get(aw.atn.Picklist_Value__c).is_tardy__c){
					 if(aw.atn.Arrival_Time__c == null){
						Apexpages.addMessage(new apexpages.message(apexpages.severity.fatal, 'There must be an "Arrival Time" associated with a ' + pavalues.get(aw.atn.Picklist_Value__c).name + ' status.'));
						bErrors=true;
					}
				}
	
				if(pavalues.get(aw.atn.Picklist_Value__c).is_early_departure__c){
					if(aw.atn.Departure_Time__c == null){
						Apexpages.addMessage(new apexpages.message(apexpages.severity.fatal, 'There must be a "Departure Time" associated with a ' + pavalues.get(aw.atn.Picklist_Value__c).name  + ' status.'));
						bErrors =true;
					}
				}
	
				if((aw.atn.Arrival_Time__c!=null&&(aw.atn.Arrival_Time__c<selectedSession.Start_DateTime__c||aw.atn.Arrival_Time__c>selectedSession.End_DateTime__c))||(aw.atn.Departure_Time__c!=null&&(aw.atn.Departure_Time__c<selectedSession.Start_DateTime__c||aw.atn.Departure_Time__c>selectedSession.End_DateTime__c))){
					Apexpages.addMessage(new apexpages.message(apexpages.severity.fatal, 'The Arrival and Departure time must fall within the start and end time of the section that attendance is being recorded for.'));
					bErrors = true;
				}
				aw.atn.External_Id__c = ''+aw.atn.Student__c + aw.atn.Session__c;
				upsAttenList.add(aw.atn);
			}
	
			if (!bErrors){
				try {
					upsert upsAttenList; //External_Id__c;
					//Note: this is fine because it submits all attendance as taken.

					selectedSession.Attendance_Submitted__c = true;
					Datetime dt = System.now();
					selectedSession.LastModified__c = Attendance_Utils.setLastModified(selectedSession.Section__r.Name);
					
					update selectedSession;
				} catch(exception e){
					Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'There was an error while saving the attendance records.  Please contact your system administrator.'));
					Apexpages.addMessage(new apexpages.message(apexpages.severity.error, e.getMessage()));
				}
				if (!apexPages.hasMessages()){
					Apexpages.addMessage(new apexpages.message(apexpages.severity.CONFIRM, upsAttenList.size()+' attendance records submitted for '+selectedSession.Section__r.name+' on '+selectedSession.Session_Date__c.format()));
					init();
				}
			}
		} catch (Exception e) {
			globalErrorMessage(null, 'Unexpected error while saving data.', e, true);
		}
	}
	
	public void reloadSchool(){
    	Integer i = 0;
    	for(String y: schoolSetupsByYearMap.get(schoolId).keyset()){
    		if(i == 0){
    			yearId = y;
    			break;
    		}
    		i++;	
    	}
    	reloadYear();	
    }
    
    public void reloadYear(){
    	    
    	    if(yearId == '' || yearId == null){
    	    	baseObj = core_BaseInfo_v2.baseInfoObj;
    	    	schoolId  = baseObj.school.Id;
    	    	yearId = baseObj.activeSetup.Year__c;
    	    }

    	    	refreshYear(schoolId, yearId);

    	    sectionList = baseObj.sectionlist;
			pvs = new List<Picklist_Value__c>();
			for (Picklist_Value__c pv:  core_SoqlUtils.getPlValuesList('Attendance', baseObj.activeSetup.id)){
				 StatusList.add(new SelectOption(pv.Name, pv.Name));
				 pvs.add(pv);
			}
    	    
    }
    
    public void refreshYear(String schoolId,String yearId){
    	
            baseObj.sectionMap = new Map <Id, Section__c>();
            baseObj.sectionList = new List<Section__c>();
            baseObj.reportingPeriodOptions = new List <SelectOption>();
            baseObj.sectionOptions = new List <SelectOption>();
            System.debug('$$$$$schoolId$$$$$$'+schoolId);
           	
           	baseObj.activeSetup = schoolSetupsByYearMap.get(schoolId).get(yearId);
           	baseObj.school =      schoolMap.get(SchoolId);
            baseObj.staff       = core_SoqlUtils.getStaffDetails(staffSchoolMap.get(schoolId));
            
            System.debug('$$$$$schoolId$$$$$$'+schoolId);
            
            System.debug('$$$$$schoolSetupsByYearMapp$$$$$$'+schoolSetupsByYearMap);
            System.debug('$$$$$termSetupMap$$$$$$'+schoolMap);
            System.debug('$$$$$schoolId$$$$$$'+schoolId);
            System.debug('$$$$$staffSchoolMap.get(schoolId)$$$$$$'+ staffSchoolMap.get(schoolId));
            if(!baseObj.activeSetup.Active__c){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Students who were active at the End of Previous year will be displayed.'));
            }
            if (baseObj.activeSetup!=null){
                baseObj.bStandardsBased = baseObj.activeSetup.Standards_Based_Grading__c;
                baseObj.dPassingGrade  = baseObj.activeSetup.Passing_Grade_Threshold__c;
                
                       
                    for (Time_Element__c t: core_SoqlUtils.getTimeElementsByTermGB(baseObj.activeSetup.term__c)){
                        baseObj.reportingPeriodOptions.add(new SelectOption(t.Id, t.Name__c)); 
                    }
                
                
                
                    if (yearSectionsMap.get(baseObj.activeSetup.School__c).get(baseObj.activeSetup.Year__c)!=null){ 
                        for (Section__c s: yearSectionsMap.get(baseObj.activeSetup.School__c).get(baseObj.activeSetup.Year__c)){
                            baseObj.sectionMap.put(s.id, s);
                            baseObj.sectionList.add(s);
                            baseObj.sectionOptions.add(new SelectOption(s.id, s.name));
                        }
                    }
                    else{
                    	Apexpages.addMessage(new apexpages.message(apexpages.severity.error,'No sections for school year: '+baseObj.activeSetup.Year__r.Name__c));
                    }
                
            } else {
                core_BaseInfo_v2.errorMessages.add('No active setup for your School. Please contact your administrator.');
            }
    }
    public List<SelectOption> getSchoolYears(){
    	List<SelectOption> schoolyears = new List<SelectOption>();
    	for(String yr: core_SoqlUtils.getRecentThreeYears()){
    		if(schoolSetupsByYearMap.get(schoolId).containsKey(yr)){
				schoolyears.add(new SelectOption(yr,schoolSetupsByYearMap.get(schoolId).get(yr).Year__r.Name__c));
    		}
    	} 
    	
    	   
    	return schoolyears;
    }
    
     public List<SelectOption> getSchools(){
    	List<SelectOption> schools = new List<SelectOption>();
    	for(Account acc: core_BaseInfo_v2.schoolMap.values()){
    		schools.add(new SelectOption(acc.Id,acc.Name));
    	}  
    	return schools;
    }
	private PageReference errorMessage(string message){
		ApexPages.getMessages().clear();
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,message));
		return null;
	}
	
	private void globalErrorMessage(string links, string info, Exception e, boolean pageError){
		Global_Error__c ge = Error_Handling.handleError('Section,' + section + ';' + 'Session,'+ session + ';' + links, 'Attendance', info, e);
		insert ge;
		
		if(pageError){
			errorMessage(info);
		}
	}
}