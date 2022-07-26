public with sharing class AttendanceDateWizardController {
	public Boolean			searchedDaily			{get;set;} //whether the attendance records have been searched
	public Alert__c			searchDate				{get;set;} //where the search date parameter is stored
	public Alert__c			startDate				{get;set;} //beginning of the date range
	public Alert__c			endDate					{get;set;} //end of the date range
	public String			selectedSection1		{get;set;} //section selected for range attendance
	public String			selectedSection2		{get;set;} //section selected for date attendance
	public String			sFirstName				{get;set;} //first name to search students for
	public String			sLastName				{get;set;} //last name to search students for
	public String			selectedFunction		{get;set;} //whether to record daily or a range of attendance
	public ID				setStatus				{get;set;} //status to be set for given range
	public String			setComments				{get;set;} //comments for the given range
	public boolean			studentExists			{get;set;} //whether the student search returned records
	public List<Student__c>	studentSearchresults	{get;set;} //query list for found students
	public Attendance__c	attendanceResult		{get;set;} //where the single attendance object from the query is stored
	public ID				selectedStudentID		{get;set;} //student selected on the page
	public Student__c		selectedStudent			{get;set;} //student record
	public boolean			searched				{get;set;} //boolean for rendering
	public List<selectOption>	selectSection		{get;set;} //picklist for sections
	public Map<ID, String>		sectionMap			{get;set;} //for de-duping
	public List<SelectOption>	statuslist1			{get;set;} //store Status Picklist from Picklist Values
	public List<SelectOption> 	statusList2			{get;set;} //store Status Picklist from Picklist Values

	public Session__c					asession; //stores session variables
	private Map<Id,Picklist_Value__c>	pavalues; //stores map of Status values to internal codes

	public core_BaseInfo_v2.cSchool_BaseInfo	baseObj	{get;set;} //base info
	public Student_SearchStudent	searchStudent		{get;set;} //Student Search Container

	public attendanceDateWizardController(){ //initialize variables
		searchDate				= new Alert__c();
		startDate				= new Alert__c();
		endDate					= new Alert__c();
		setComments				= '';
		studentSearchresults	= new List<Student__c>();
		attendanceResult		= new Attendance__c();
		selectSection			= new List<selectOption>();
		sectionMap				= new Map<ID, String>();
		selectedFunction		='Date';
		statusList1 			= new List<SelectOption>();
		statusList2 			= new List<SelectOption>();
		searchStudent			= new Student_SearchStudent();
		resetSearch();
	}

	public void resetSearch(){
		searchStudent		= new Student_SearchStudent();
		selectedStudent		= new Student__c();
		searched			= false;
		searchedDaily		= false;
		studentExists		= false;
	}

	public void Go(){ //when the 'search' button is pressed, fires for both date & student search
		try{
			searchStudent.searchStudents();
			studentSearchresults = searchStudent.studResults;

			if(studentSearchResults.isEmpty()){ //if there is no student, throw error
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('ATT-001')));
			} else{
				studentExists=true;
			}
		}
		catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('', 'Attendance', 'Unexpected exception in attendance wizard search', e);
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,'An unexpected error has occurred. Please try again or contact your system administrator'));
			insert ge;
		}
	}

	/*
		Save the changes into attendance records for the student
	*/
	public pageReference save(){
		//for range of dates
		ApexPages.getMessages().clear();
		try{
			if (selectedFunction=='Range'){
				//don't allow end dates to be before start dates
				if(endDate.Expiration_Date__c<startDate.Expiration_Date__c){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('ATT-002')));
					return null;
				}
				if(startDate.Expiration_Date__c==null || endDate.Expiration_Date__c==null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Please enter a value for both start and end date.'));
					return null;
				}
				List<Session__c> sessionResults		= Attendance_SoqlUtils.getSessionBySection(selectedSection1, startDate.Expiration_Date__c, endDate.Expiration_Date__c);
				Map<ID, Attendance__c> attendanceMap = new Map<ID, Attendance__c>();
				List<Attendance__c> attendanceUpdate = new List<Attendance__c>();
				List<Attendance__c> attendanceResults 	= Attendance_SoqlUtils.getAttendanceFromDates(selectedSection1, startDate, endDate, selectedStudentID);
				//go through the attendance records and set them
				for(Attendance__c a : attendanceResults){
					attendanceMap.put(a.Session__c, a);
					a.Picklist_Value__c		= setStatus;
					a.comments__c	= setComments;
					attendanceUpdate.add(a);
				}
				for(Session__c s : sessionResults){
					//for non-existing attendance records for a given session set the appropriate fields
					if(!attendanceMap.keyset().contains(s.id)){
						Attendance__c newAttendance = new Attendance__c();
						newAttendance.Picklist_Value__c	= setStatus;
						newAttendance.Student__c	= selectedStudentID;
						newAttendance.Session__c	= s.id;
						newAttendance.Comments__c	= setComments;
						newAttendance.Daily__c		= s.Section__r.Daily_Attendance__c;
						newAttendance.External_Id__c = ''+selectedStudentID + s.id;
						attendanceUpdate.add(newAttendance);
					}
				}
				if (!attendanceUpdate.isEmpty()){
					try{
						upsert attendanceUpdate External_Id__c;
						//pageReference p = new pageReference('/apex/AttendanceDateWizard');
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Attendance records for' + ' ' + selectedStudent.Student_First_Name__c + ' ' + selectedStudent.Student_Last_Name__c + ' ' + 'updated successfully!'));
						resetSearch();
						return null;
					}
					catch(Exception e) {
						string links = '';
						Global_Error__c ge = Error_Handling.handleError(links, 'Attendance', 'Attendance wizard - Unexpected error when saving selected function = ' + selectedFunction, e);
						insert ge;
						searched = true;//keeps the necessary panel
						StudentExists=true; //keeps the student result panel
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('ATT-003')));
						return null;
					}
				}
				//throw error if there are no attendance records to process
				else {

					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('ATT-011')));
					throw new Error_Handling.schoolForceException('attendanceUpdate is empty');
					return null;
				}
			} //end range attendance
			//begin daily attendance
			else {
				if (attendanceresult.Arrival_Time_Text__c!=null&&attendanceresult.Arrival_Time_Text__c!=''){
					try {
						DateTime tempArrivalTime = core_TimeUtils.processTimeText(attendanceresult.Arrival_Time_Text__c);
						attendanceresult.Arrival_Time__c = DateTime.newInstance(SearchDate.Expiration_Date__c.year(), SearchDate.Expiration_Date__c.month(), SearchDate.Expiration_Date__c.day(),tempArrivalTime.hour(), tempArrivalTime.minute(),0 );
					}
					catch (exception e){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Please enter a valid time for Arrival Time'));
					}
				}
				if (attendanceresult.Departure_Time_Text__c!=null&&attendanceresult.Departure_Time_Text__c!=''){
					try{
						DateTime tempDepartureTime = core_TimeUtils.processTimeText(attendanceresult.Departure_Time_Text__c);
						attendanceresult.Departure_Time__c = DateTime.newInstance(SearchDate.Expiration_Date__c.year(), SearchDate.Expiration_Date__c.month(), SearchDate.Expiration_Date__c.day(),tempDepartureTime.hour(), tempDepartureTime.minute(),0 );
					}
					catch (exception e){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Please enter a valid time for Departure Time'));
					}
				}
				//if being saved as tardy
				if(pavalues.get(attendanceresult.Picklist_Value__c).Is_Tardy__c ){
					//if no arrival time for tardy, throw error
					if (attendanceResult.Arrival_Time__c == null){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,core_SoqlUtils.getErrorMessageByName('ATT-006')));
						return null;
					}
					//if the dates are wrong, throw error
					if (attendanceResult.Arrival_Time__c.date() != asession.Session_Date__c) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,core_SoqlUtils.getErrorMessageByName('ATT-003')));
						return null;
					}
					//if arrival time does not fall in the limits of the session, throw error
					if (attendanceResult.Arrival_Time__c < asession.Start_DateTime__c || attendanceResult.Arrival_Time__c > asession.End_DateTime__c){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, core_SoqlUtils.getErrorMessageByName('ATT-008')));
						return null;
					}
				}
				//if being saved as early departure
				else if( pavalues.get(attendanceresult.Picklist_Value__c).Is_Early_Departure__c ){
					//if no departure time for early departure, throw error
					if (attendanceResult.Departure_Time__c == null){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,core_SoqlUtils.getErrorMessageByName('ATT-009')));
						return null;
					}
					//should be no arrival time with early departure
					if (attendanceResult.Arrival_Time__c != null){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,core_SoqlUtils.getErrorMessageByName('ATT-010')));
						return null;
					}
					//if the dates are wrong, throw error
					if (attendanceResult.Departure_Time__c.date() != asession.Session_Date__c) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,core_SoqlUtils.getErrorMessageByName('ATT-003')));
						return null;
					}
					//if departure time does not fall in the limits of the session, throw error
					if (attendanceResult.Departure_Time__c < asession.Start_DateTime__c || attendanceResult.Departure_Time__c > asession.End_DateTime__c){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,core_SoqlUtils.getErrorMessageByName('ATT-008')));
						return null;
					}


				}
				//else some kind of absence and does not need arrival/departure time
				else {
					attendanceResult.Arrival_Time__c	= null;
					attendanceResult.Departure_Time__c	= null;
				}
				if (!ApexPages.hasMessages()){

					if(selectedFunction == 'Date'){
						try{
							attendanceResult.External_Id__c = ''+attendanceResult.Student__c + attendanceResult.Session__c;
							upsert attendanceResult External_Id__c; //update/insert attendance record
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, 'Attendance records for' + ' ' + selectedStudent.Student_First_Name__c + ' ' + selectedStudent.Student_Last_Name__c + ' ' + 'updated successfully!'));
							//pageReference p = new pageReference('/apex/AttendanceDateWizard');
							//p.setRedirect(true);
							resetSearch();
							return null;
						}
						catch(Exception e) {
							string links = '';
							searched=true;
							Global_Error__c ge = Error_Handling.handleError(links, 'Attendance', 'Attendance wizard - Unexpected error when saving selected function = ' + selectedFunction, e);
							insert ge;
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('COR-001')));
							return null;
						}
					}
				}
			}
		}
		catch(Exception e){
			string links = '';
			Global_Error__c ge = Error_Handling.handleError(links, 'Attendance', 'Attendance wizard - Unexpected error when saving selected function = ' + selectedFunction, e);
			insert ge;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('COR-001')));
			return null;
		}
		return null;
	}

	//cancel returns to the home page
	public pageReference cancel(){
		pageReference p = new pageReference('/apex/AttendanceDateWizard'); //cancel simply takes the user back to the home page
		p.setRedirect(true);
		return p;
	}

	/*
		Display the sections available to the selected student
	*/
	public void displaySections(){
		try{


			selectedFunction = 'Date';
			selectedStudentID = ApexPages.currentPage().getParameters().get('studID');
			//clear the lists so stacking does not occur
			selectSection.clear();
			sectionMap.clear();

			for (Student__c s : studentSearchResults){
				if(s.ID == selectedStudentID){
					selectedStudent.Student_First_Name__c = s.Student_First_Name__c;
					selectedStudent.Student_Last_Name__c = s.Student_Last_Name__c;
					selectedStudent.Name = selectedStudent.Student_First_Name__c+ ' '+selectedStudent.Student_Last_Name__c;
					loadAttendancePicklistValues(s.Setup__c);
				}
			}

			if(studentExists){
				List<Student_Section__c> sectionResults	= Attendance_SoqlUtils.getStudentSectionListByStudent(selectedStudentID, true);
				if(sectionResults.isEmpty()){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('ATT-004')));
					return;
				}
				//set up junction object map
				for(Student_Section__c ss : sectionResults){
					sectionMap.put(ss.Section__c, ss.Section__r.Name);
				}
				for(ID i : sectionMap.keyset()){ //build picklist
					selectSection.add(new selectOption(i, sectionMap.get(i)));
				}
				searched = true;
			}
		}
		catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('', 'Attendance', 'Unexpected error displaying sections', e);
			insert ge;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('COR-001')));	}
	}

	/*
		Loads the correct picklist values for the selected student
	*/
	private void loadAttendancePicklistValues(ID setupID){
		ID attendanceRTID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Attendance');
		statusList1 = new List<selectOption>();
		statuslist2 = new List<selectOption>();
		List<Picklist_Value__c> holder =
		[select id, Name, Category__c, Is_Early_Departure__c, Is_Suspension__c, Is_Tardy__c, Is_Unexcused__c
		from Picklist_Value__c
		where (Setup__c =:setupID OR Setup__c= null)
		AND RecordTypeID =: attendanceRTID];

		pavalues = new Map<ID, Picklist_Value__c>(holder);

		for(Picklist_Value__c pv:holder){
			if(!pv.Is_Tardy__c && !pv.Is_Early_Departure__c){
				StatusList1.add(new SelectOption(pv.Id, pv.Name));
			}
			StatusList2.add(new SelectOption(pv.Id, pv.Name));
		}
	}

	/*
		Find if the student already has attendance records for the given section and date
		If not, create a new attendance record
	*/
	public void displayAttendance(){
		attendanceResult = new Attendance__c();
		try{
			List<Student_Section__c> tempSection = [Select ID, Section__c from Student_Section__c where Student__c = : selectedStudentID and Section__c=:selectedSection2];
			Set <ID> ssIds = new Set <Id>();
			for (Student_Section__c ss: tempSection){
				ssIds.add(ss.id);
			}
			/*US1243 */
			Map <ID, List <Enrollment_Tracking__c>> etMap = Attendance_SoqlUtils.getEnrollmentTrackingMap(ssIds); //Get enrollment tracking map for the student section ids
			if(tempSection.size()>0){
				//check to make sure the student belongs to a session associated with the date entered on the page
				List<Session__c> tempSession = [Select ID, Start_DateTime__c, End_DateTime__c, Section__r.Daily_Attendance__c, Session_Date__c
				from Session__c where Section__c =: selectedSection2
				AND Session_Date__c =: searchDate.Expiration_Date__c
				AND Record_Attendance__c = true];
				if(tempSession.size()>0){
					asession = tempSession[0];
					List<Attendance__c> tempAtt = [Select Student__r.Name, Status__c, internal_code__c, Picklist_Value__c, Picklist_Value__r.Name, Session__c, Comments__c, Student__c, Departure_Time__c, Arrival_Time__c , Arrival_Time_Text__c, Departure_Time_Text__c
					From Attendance__c
					where Session__c = :tempSession[0].id
					AND Student__c = :	selectedStudentID];

					if(tempAtt.size()>0){
						attendanceResult=tempAtt[0];
					}
					else {
						//Check to see if student was actually in class during this day
						/*START US1243 Logic */
						boolean validDate = true;
						if (etMap.get(tempSection[0].Id)!=null){
							system.debug(etMap.get(tempSection[0].Id));
							validDate=checkEnrollmentTracking(etMap.get(tempSection[0].Id), aSession);
						}
						if (validDate){
							attendanceResult.Session__c = tempSession[0].id;
							attendanceResult.Daily__c	= Boolean.valueOf(tempSession[0].Section__r.Daily_Attendance__c);
							attendanceResult.Student__c =	selectedStudentID;//set up the appropriate links/relationships between records
						}
						else {
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,selectedStudent.name+' was inactive for the selected section and date.	If attendance needs to be submitted, contact your adminstrator.'));
							return;
						}
						/*END US1243 Logic */
					}

				}
				else{
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('ATT-005')));
					return;
				}
			}
			else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('ATT-004')));
				return;
			}
			searchedDaily = true;
		}
		catch(Exception e){
			string links = '';
			Global_Error__c ge = Error_Handling.handleError(links, 'Attendance', 'Unexpected error displaying sections', e);
			insert ge;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL,core_SoqlUtils.getErrorMessageByName('COR-001')));
		}
	}

	public	boolean checkEnrollmentTracking( List <Enrollment_Tracking__c> etList, Session__c selectedSession){
		boolean bValid = false;
		for (Enrollment_Tracking__c et: etList){
			if (et.start_date__c.date() <= selectedSession.Session_Date__c&&et.end_date__c==null&&et.active__c){
				system.debug('the master active record');
				bValid=true;
				break;
			}
			else if (et.start_date__c.date() <= selectedSession.Session_Date__c && et.end_date__c !=null && et.active__c){
				if (selectedSession.Session_date__c <et.end_date__c.date() ){
					system.debug('the secondary active record');
					bValid=true;
					break;
				}
			}
		}
		return bValid;
	}

}