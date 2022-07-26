public with sharing class AttendanceWizard_v2 {
	//Page Parameters
	public String currentSchool {get; set;}
	public String currentYear {get; set;}
	public String bMode {get; set;}
	public String attendanceDate {get; set;}
	public List<SelectOption> activeSchools {get; set;}

	//Controller states
	public Boolean bInitialized {get; set;}

	//internal 
	public Time_Element__c currentYearRecord {get; set;}
	private User currentUser {get; set;}

	public studentAttendanceSearch stSearch {get; set;}
	public sectionAttendanceSearch snSearch {get; set;}
	private final static Integer listLimit = 999;

	public AttendanceWizard_v2() {
		bInitialized = true;
		try {
			attendanceDate = Date.today().format();

			currentUser = [SELECT ID, School__c FROM User WHERE ID =: UserInfo.getUserID()];
			if(String.isNotEmpty(currentUser.School__c)) {
				currentSchool = currentUser.School__c;
			}

			currentYearRecord = getCurrentYear();
			currentYear = currentYearRecord.ID;

			system.debug('*~*~* currentYearRecord: ' + currentYearRecord);

			activeSchools = loadInitialSchools(currentSchool, currentYearRecord);
		}
		catch(Exception e) {
			//use as a control for render if necessary
			bInitialized = false;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'constructor failed - Exception: ' + e.getMessage()));
		}

		//default mode
		bMode = 'Student';

		try {
			loadInitialSearch();	
		}
		catch(Exception e) {
			bInitialized = false;
		}
	}

	private List<SelectOption> loadInitialSchools(String cSchool, Time_Element__c te) {		
		//can get the initial school from user record
		//else populate alphanumeric order
		List<SelectOption> returnList = new List<SelectOption>();
		Boolean bContainsSchool = false;
		for(Setup__c s : [SELECT ID, Year__c, School__c, School__r.Name FROM Setup__c WHERE Year__c =: te.ID AND active__c = true AND School__c != null ORDER BY School__r.Name]) {
			returnList.add(new SelectOption(s.School__c, s.School__r.Name));
			if(!bContainsSchool && cSchool == (String)s.School__c) {
				bContainsSchool = true;
			}
		}

		return returnList;
	}

	private Time_Element__c getCurrentYear() {
		Time_Element__c returnTE = new Time_Element__c();
	
		try {
			for(Time_Element__c te : [SELECT ID, Name__c FROM Time_Element__c WHERE Current__c = true AND Previous_Year__c = false AND Picklist_Value__r.Name = 'Year' ORDER BY Date_Start_Date__c DESC]) {
				if(returnTE.ID == null) {
					returnTE = te;
				}
				else {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'SchoolForce System has encountered another Time Element record that is a year and is current.  Please notify your System Administrator to correct this.'));
				}
			}
			if(returnTE.ID == null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'SchoolForce System cannot find a Time Element that is a year and is current.  Please notify your System Administrator to correct this.'));
			}
		}
		catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'getCurrentYear failed - Exception: ' + e.getMessage())); 
		}


		return returnTE;
	}

	public void loadInitialSearch() {
		String tMode = apexPages.currentPage().getParameters().remove('bMode');
		if(String.isNotEmpty(tMode)) {
			bMode = tMode;
		}

		system.debug('*~*~* bMode: ' + bMode);

		if(bMode == 'Student') {
			stSearch = new studentAttendanceSearch();
		}
		else if(bMode == 'Section') {
			snSearch = new sectionAttendanceSearch();
		}
		else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Failed to load any tab? bMode: ' + '\'' + bMode + '\''));
		}
		
	}

	public void retrieveResults() {
		try {
			Date tDate = Date.parse(attendanceDate);

			system.debug('*~*~* bMode: ' + bMode);
			if(bMode == 'Student') {
				stSearch.retrieveEnrolledStudents(tDate, currentSchool);
			}
			else if(bMode == 'Section') {
				snSearch.retrieveEnrolledSections(tDate, currentSchool, currentYearRecord);
			}		
		}
		catch(Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'retrieveResults failed - Exception: ' + e.getMessage()));
		}

	}

	private static Map<ID, Picklist_Value__c> getAttendancePicklistValues(ID setupID){
		ID attendanceRTID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Attendance'); 
		return new Map<ID, Picklist_Value__c>([select id, Name, Category__c, Is_Early_Departure__c, Is_Suspension__c, Is_Tardy__c, Is_Unexcused__c, set_as_default__c FROM Picklist_Value__c WHERE (Setup__c =:setupID OR Setup__c= null) AND RecordTypeID =: attendanceRTID]);
	}

	private static List<SelectOption> getAttendanceStatusOptions(List<Picklist_Value__c> plv) {
		List<SelectOption> returnSOList = new List<SelectOption>();
		returnSOList.add(new selectOption('', '--None--'));
		for(Picklist_Value__c pv : plv) {
			returnSOList.add(new SelectOption(pv.ID, pv.Name));
		}
		return returnSOList;
	}

	private static Boolean bEnrolled(Enrollment_Tracking__c et, Date attendanceDate) {
		Boolean bAdd = true;
		if(et.End_Date__c != null) {
			if(attendanceDate <= et.End_Date__c.date() && attendanceDate >= et.Start_Date__c.date()) {
				bAdd = true;
			}
			else {
				bAdd = false;
			}
		}
		else{
			if(et.Start_Date__c.date() <= attendanceDate) {
				bAdd = true;
			}
			else {
				bAdd = false;
			}	
		}	
		return bAdd;		
	}

	public static Boolean validateSubmission(List<attendanceWizardWrapper> swAttendance, Map<ID, Picklist_Value__c> pvMap, Date aDate) {
		Boolean bReturn = true;
		Boolean error1 = false;
		Boolean error2 = false;
		Boolean error3 = false;
		Boolean error4 = false;
		Boolean error5 = false;

		for(attendanceWizardWrapper sw : swAttendance) {
			sw.rowStyle = '';
			sw.statusStyle = '';
			sw.arrivalStyle = '';
			sw.departureStyle = '';
			sw.commentStyle = '';
			if(String.isNotEmpty(sw.at.Comments__c) && sw.at.Picklist_Value__c == null) {
				sw.statusStyle = 'border-style : solid; border-color : red;';
				error1 = true;
				bReturn = false;
			}
			if(pvMap.containsKey(sw.at.Picklist_Value__c)) {
				if(pvMap.get(sw.at.Picklist_Value__c).Is_Tardy__c == true) {
					if(String.isNotBlank(sw.at.Arrival_Time_Text__c)) {
						try {
							DateTime tempArrivalTime = core_TimeUtils.processTimeText(sw.at.Arrival_Time_Text__c);
							sw.at.Arrival_Time__c = DateTime.newInstance(aDate.year(), aDate.month(), aDate.day(),tempArrivalTime.hour(), tempArrivalTime.minute(),0 );
						
							if(sw.at.Arrival_Time__c < sw.at.Session_Start_Time__c || sw.at.Arrival_Time__c > sw.at.Session_End_Time__c) {
								sw.arrivalStyle = 'border-style : solid; border-color : red;';
								error5 = true;
								bReturn = false;
							}
						}
						catch (exception e){
							sw.arrivalStyle = 'border-style : solid; border-color : red;';
							error3 = true;
							bReturn = false;
						}					
					}
					else {
						sw.arrivalStyle = 'border-style : solid; border-color : red;';
						error2 = true;
						bReturn = false;
					}
				}
				else {
					sw.at.Arrival_Time__c = null;
					sw.at.Arrival_Time_Text__c = null;
				}
				if(pvMap.get(sw.at.Picklist_Value__c).Is_Early_Departure__c == true) {
					if(String.isNotBlank(sw.at.Departure_Time_Text__c)) {
						try {
							DateTime tempDepartureTime = core_TimeUtils.processTimeText(sw.at.Departure_Time_Text__c);
							sw.at.Departure_Time__c = DateTime.newInstance(aDate.year(), aDate.month(), aDate.day(),tempDepartureTime.hour(), tempDepartureTime.minute(),0 );
						
							if(sw.at.Departure_Time__c < sw.at.Session_Start_Time__c || sw.at.Departure_Time__c > sw.at.Session_End_Time__c) {
								sw.departureStyle = 'border-style : solid; border-color : red;';
								error5 = true;
								bReturn = false;
							}
						}
						catch (exception e){
							sw.departureStyle = 'border-style : solid; border-color : red;';
							error4 = true;
							bReturn = false;
						}								
					}
					else {
						sw.departureStyle = 'border-style : solid; border-color : red';
						error2 = true;
						bReturn = false;
					}
				}
				else {
					sw.at.Departure_Time__c = null;
					sw.at.Departure_Time_Text__c = null;
				}
			}

		}
		if(error1) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You have entered a comment without selecting an attendance status. You must complete the Status field in order to save this information.'));
		}
		if(error2) {
			ApexPages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR, 'You must complete the highlighted fields in order to save this information.'));
		}
		if(error3) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter a valid time for Arrival Time.'));
		}
		if(error4) {
			ApexPages.addMessage(new Apexpages.Message(apexPages.Severity.ERROR, 'Please enter a valid time for Departure Time.'));
		}
		if(error5) {
			ApexPages.addMessage(new Apexpages.Message(apexpages.Severity.ERROR, 'The Arrival and Departure time must fall within the start and end time of the section that attendance is being recorded for.'));
		}
		return bReturn;
	}

	public class attendanceWizardWrapper implements Comparable{
		public Student__c student {get; set;}
		public String studentID {get; set;}
		public String studentName {get; set;}
		public String studentFirstName {get; set;}
		public String studentLastName {get; set;}
		public Attendance__c at {get; set;}
		public Session__c session {get; set;}
		public String sessionSection{get; set;}
		public String sessionTime {get; set;}
		public DateTime startDate {get; set;}
		public DateTime endDate {get; set;}
		public Boolean bDailyAttendance {get; set;}
		public String rowStyle {get; set;}
		public String statusStyle {get; set;}
		public String arrivalStyle {get; set;}
		public String departureStyle {get; set;}
		public String commentStyle {get; set;}
		public String bMode {get; set;}

		public attendanceWizardWrapper() {}
		public attendanceWizardWrapper(Student__c student, Session__c session, String bMode) {
			this.bMode = bMode;
			this.student = student;
			this.studentName = student.Name;
			this.studentFirstName = student.Student_First_Name__c;
			this.studentLastName = student.Student_Last_Name__c;
			this.session = session;
			this.sessionSection = session.Section__r.Name;
			this.startDate = session.Start_DateTime__c;
			this.endDate = session.End_DateTime__c;
			if(session.Start_DateTime__c != null && session.End_DateTime__c != null) {
				this.sessionTime = session.Start_DateTime__c.format('h:mm a') + ' - ' + session.End_DateTime__c.format('h:mm a');
			}
			at = new Attendance__c(
					Student__c = student.ID,
					Session__c = session.ID,
					External_ID__c = String.valueOf(student.ID) + String.valueOf(session.ID),
					Daily__c = session.Section__r.Daily_Attendance__c
				);
			this.bDailyAttendance = session.Section__r.Daily_Attendance__c;
		}
		public attendanceWizardWrapper(Attendance__c attendance, Student__c student, Session__c session, String bMode) {
			this.bMode = bMode;
			this.student = student;
			this.studentName = student.Name;
			this.studentFirstName = student.Student_First_Name__c;
			this.studentLastName = student.Student_Last_Name__c;
			this.session = session;
			this.sessionSection = session.Section__r.Name;
			this.startDate = session.Start_DateTime__c;
			this.endDate = session.End_DateTime__c;
			if(session.Start_DateTime__c != null && session.End_DateTime__c != null) {
				this.sessionTime = session.Start_DateTime__c.format('h:mm a') + ' - ' + session.End_DateTime__c.format('h:mm a');
			}
			at = attendance;
			at.Daily__c = session.Section__r.Daily_Attendance__c;
			this.bDailyAttendance = session.Section__r.Daily_Attendance__c;
		}

		public attendanceWizardWrapper(Enrollment_Tracking__c et, Session__c session, String bMode) {
			this.bMode = bMode;
			this.studentID = et.Student_Section__r.Student__c;
			this.studentName = et.Student_Section__r.Student__r.Name;
			this.studentFirstName = et.Student_Section__r.Student__r.Student_First_Name__c;
			this.studentLastName = et.Student_Section__r.Student__r.Student_Last_Name__c;
			this.session = session;
			this.sessionSection = session.Section__r.Name;
			this.startDate = session.Start_DateTime__c;
			this.endDate = session.End_DateTime__c;
			at = new Attendance__c(
					Student__c = this.studentID,
					Session__c = session.ID,
					External_ID__c = String.valueOf(this.studentID) + String.valueOf(session.ID),
					Daily__c = session.Section__r.Daily_Attendance__c
				); 
			this.bDailyAttendance = session.Section__r.Daily_Attendance__c;
		}

		public attendanceWizardWrapper(Attendance__c attendance, Session__c session, String bMode) {
			this.bMode = bMode;
			this.studentID = attendance.Student__c;
			this.studentName = attendance.Student__r.Name;
			this.studentFirstName = attendance.Student__r.Student_First_Name__c;
			this.studentLastName = attendance.Student__r.Student_Last_Name__c;
			this.session = session;
			this.sessionSection = session.Section__r.Name;
			this.startDate = session.Start_DateTime__c;
			this.endDate = session.End_DateTime__c;
			at = attendance;
			at.Daily__c = session.Section__r.Daily_Attendance__c;
			this.bDailyAttendance = session.Section__r.Daily_Attendance__c;
		}

		public Integer compareTo(Object compareTo) {
			attendanceWizardWrapper compare = (attendanceWizardWrapper)compareTo;
			
			Integer returnValue = 0;
			if(bMode == 'Section') {
				if(studentLastName >= compare.studentLastName) {
					returnValue = 1;
				}
				else if(studentLastName < compare.studentLastName) {
						returnValue = -1;
				}				
			}
			else if(bMode == 'Student') {
				//sort by daily, then time
				if((bDailyAttendance == true && compare.bDailyAttendance == true) || (bDailyAttendance == false && compare.bDailyAttendance == false)) {
					if(startDate >= compare.startDate) {
						returnValue = 1;  //original 1
					}
					else {
						returnValue = -1;  //original -1
					}					
				}
				else if(bDailyAttendance == true && compare.bDailyAttendance == false){
					returnValue = -1;
				}
				else if(bDailyAttendance == false && compare.bDailyAttendance == true) {
					returnValue = 1;
				}
			}
			return returnValue;
		}		

	}

	public class thousandLimitWrapper  {
		public attendanceWizardWrapper [] aww {get; set;}
		public integer blockNumber  {get; set;}
		public thousandLimitWrapper (attendanceWizardWrapper[]  sl, Integer i) {
			aww = sl;
			blockNumber = i;
		}
	}

	public static thousandLimitWrapper[] getThousandBlocks(List<attendanceWizardWrapper> swa) {
		List<thousandLimitWrapper> thousandBlocks  = new thousandLimitWrapper[] {};
		integer counter = 0;
		integer loopcount = 0;
		attendanceWizardWrapper [] local = new attendanceWizardWrapper[]{};

		for(attendanceWizardWrapper aw : swa) {
			if(counter < listLimit) {
				local.add(aw);
				counter++;
			}
			else {
				loopCount++;
				local.add(aw);
				thousandBlocks.add(new thousandLimitWrapper(local, loopCount));
				local = new attendanceWizardWrapper[] {};
				counter = 0;
			}
		}
		loopCount++;
		thousandBlocks.add(new thousandLimitWrapper(local, loopCount));
		return thousandBlocks;
	}

	public class studentAttendanceSearch {
		public Date aDate {get; set;}
		public Student_SearchStudent sCriteria {get; set;}
		public Student__c selectedStudent {get; set;}
		public List<attendanceWizardWrapper> swAttendance {get; set;}
		public List<SelectOption> attendancePV {get; set;}
		public Map<ID, Picklist_Value__c> pvMap {get; set;}
		public List<Picklist_Value__c> pvList {get; set;}
		public Boolean closeModal {get; set;}
		public Boolean setupLock {get; set;}
		public String statusCopyDown {get; set;}
		public String arrivalCopyDown {get; set;}
		public String departureCopyDown {get; set;}
		public String commentCopyDown {get; set;}
		public String afterSubmissionSuccess {get; set;}
		public String bMode {get; set;}
		public Boolean selectAll {get; set;}

		public List<Attendance__c> insertDailyAttendance {get; set;}
		public List<Attendance__c> updateDailyAttendance {get; set;}
		public Set<ID> sections {get; set;}
		public Set<ID> sessions {get; set;}

		public studentAttendanceSearch() {
			sCriteria = new Student_SearchStudent();
			swAttendance = new List<attendanceWizardWrapper>();
			attendancePV = new List<SelectOption>();
			pvMap = new Map<ID, Picklist_Value__c>();
			pvList = new List<Picklist_Value__c>();
			afterSubmissionSuccess = '';
			insertDailyAttendance = new List<Attendance__c>();
			updateDailyAttendance = new List<Attendance__c>();
		}

		public void retrieveEnrolledStudents(Date attendanceDate, String currentSchool) {
			attendancePV = new List<SelectOption>();
			pvMap = new Map<ID, Picklist_Value__c>();
			pvList = new List<Picklist_Value__c>();
			swAttendance = new List<attendanceWizardWrapper>();

			aDate = attendanceDate;
			sCriteria.school = currentSchool;
			sCriteria.searchStudents();
			List<Student__c> tempStudentResults = new List<Student__c>(sCriteria.studResults);
			List<Student__c> actualStudentResults = new List<Student__c>();
			sCriteria.studResults.clear();
			Map<ID, Set<Enrollment_Tracking__c>> studentToEnrollmentTrackingMap = new Map<ID, Set<Enrollment_Tracking__c>>();
			
			for(Enrollment_Tracking__c et : [SELECT ID, Student_Section__c, Student_Section__r.Student__c, Student_Section__r.Section__c, Start_Date__c, End_Date__c FROM Enrollment_Tracking__c WHERE Student_Section__c != null AND Student_Section__r.Student__c IN: tempStudentResults AND Active__c = true]) {
				try {
					if(aDate >= et.Start_Date__c.date()) {
						if(AttendanceWizard_v2.bEnrolled(et, aDate)) {
							if(!studentToEnrollmentTrackingMap.containsKey(et.Student_Section__r.Student__c)) {
								studentToEnrollmentTrackingMap.put(et.Student_Section__r.Student__c, new Set<Enrollment_Tracking__c>{et});
							}
							else {
								studentToEnrollmentTrackingMap.get(et.Student_Section__r.Student__c).add(et);
							}							
						}
					}
				}
				catch(Exception e) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage()));
				}
			}
			if(studentToEnrollmentTrackingMap.isEmpty()){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There are no students that match the search criteria you entered. '));
				return;
			}
			
			Integer plus1000Count = 0;

			for(Student__c s : tempStudentResults) {
				if(studentToEnrollmentTrackingMap.containsKey(s.ID)) {
					if(actualStudentResults.size() < 1000) {
						actualStudentResults.add(s);
					}	
					plus1000Count++;
				}
			}

			if(plus1000Count > 1000) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There were more than 1,000 students that met your search criteria.  Only 1,000 are displayed.'));
			}	
			sCriteria.studResults = actualStudentResults;
		}

		public void getEnrolledAttendance() {
			statusCopyDown = '';
			arrivalCopyDown = '';
			departureCopyDown = '';
			commentCopyDown = '';	
			selectAll = false;		
			swAttendance = new List<attendanceWizardWrapper>();
			String studentID = apexPages.currentPage().getParameters().remove('studentID');
			selectedStudent = [SELECT ID, Name, Student_First_Name__c, Student_Last_Name__c, Setup__c, Setup__r.Read_Only_Attendance_Wizard_Records__c FROM Student__c WHERE ID =: studentID];
			setupLock = selectedStudent.Setup__r.Read_Only_Attendance_Wizard_Records__c;
			pvMap = AttendanceWizard_v2.getAttendancePicklistValues(selectedStudent.Setup__c);
			pvList = pvMap.Values();
			attendancePV = AttendanceWizard_v2.getAttendanceStatusOptions(pvMap.Values());
			List<ID> tempSections = new List<ID>();
			Map<ID, attendanceWizardWrapper> tempWrapperMap = new Map<ID, attendanceWizardWrapper>();
			Map<ID, Session__c> tempSessionMap = new Map<ID, Session__c>();
			
			for(Enrollment_Tracking__c et : [SELECT ID, Student_Section__c, Student_Section__r.Section__c, Start_Date__c, End_Date__c FROM Enrollment_Tracking__c WHERE Student_Section__r.Student__c =: studentID AND Student_Section__c != null AND Student_Section__r.Section__c != null AND Active__c = true]) {
				if(bEnrolled(et, aDate)) {
					tempSections.add(et.Student_Section__r.Section__c);
				}
			}
			
			for(Session__c s : [SELECT ID, Section__c, Section__r.Name, Section__r.Daily_Attendance__c, Start_DateTime__c, End_DateTime__c, Name FROM Session__c WHERE Session_Date__c =: aDate AND Section__c IN: tempSections ORDER BY Section__r.Daily_Attendance__c ASC, Start_DateTime__c DESC]) {
				tempWrapperMap.put(s.ID, new attendanceWizardWrapper(selectedStudent, s, 'Student'));
				tempSessionMap.put(s.ID, s);
			}
			
			for(Attendance__c at : [SELECT ID, Locked__c, Session__c, Session__r.Section__c, Session_Start_Time__c, Session_End_Time__c, Picklist_Value__c, Arrival_Time__c, Arrival_Time_Text__c, Departure_Time__c, Departure_Time_Text__c, Comments__c FROM Attendance__c WHERE Session__r.Section__c IN: tempSections AND Student__c =: studentID AND Session_Date__c =: aDate]) {
				if(tempWrapperMap.containsKey(at.Session__c) && tempSessionMap.containsKey(at.Session__c)) {
					tempWrapperMap.put(at.Session__c, new attendanceWizardWrapper(at, selectedStudent, tempSessionMap.get(at.Session__c), 'Student'));
				}
			}
			swAttendance = new List<attendanceWizardWrapper>(tempWrapperMap.Values());
			swAttendance.sort();
			if(swAttendance.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'This student does not have any attendance sessions for the date you selected.  Update the search criteria and try again.'));
			}
		}

		public void submitDailyAttendance() {
			try {
				if(insertDailyAttendance.size() > 0) {
					insert insertDailyAttendance;

				}
				else if(updateDailyAttendance.size() > 0) {
					update updateDailyAttendance;
				}
				
				updateSessions(sections, sessions, aDate);
				afterSubmissionSuccess = 'Attendance records submitted for ' + selectedStudent.Name;	

				insertDailyAttendance = new List<Attendance__c>();
				updateDailyAttendance = new List<Attendance__c>();
				sections = new Set<ID>();
				sessions = new Set<ID>();
			}
			catch(Exception e) {
				closeModal = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));				
			}
		}

		public void submitAttendance() {
			closeModal = AttendanceWizard_v2.validateSubmission(swAttendance, pvMap, aDate);
			if(closeModal) {
				List<Attendance__c> insertList = new List<Attendance__c>();
				List<Attendance__c> updateList = new List<Attendance__c>();	
				insertDailyAttendance = new List<Attendance__c>();
				updateDailyAttendance = new List<Attendance__c>();
				sections = new Set<ID>();
				sessions = new Set<ID>();

				for(attendanceWizardWrapper sw : swAttendance) {
					sw.at.Locked__c = setupLock;  
					if(sw.at.ID  != null) {
						if(sw.at.Daily__c) {
							updateDailyAttendance.add(sw.at);
						}
						else {
							updateList.add(sw.at);
						}
					}
					else if(sw.at.Picklist_Value__c != null && sw.at.ID == null) {
						if(sw.at.Daily__c) {
							insertDailyAttendance.add(sw.at);
						}
						else {
							insertList.add(sw.at);
						}
					}
					//sections.add(sw.at.Session__r.Section__c);
					sections.add(sw.session.Section__c);
					//sessions.add(sw.at.Session__c);
					sessions.add(sw.session.ID);
				}


				try {
					if(insertList.size() > 0 || updateList.size() > 0 || insertDailyAttendance.size() > 0 || updateDailyAttendance.size() > 0) {
						if(insertList.size() > 0) {
							insert insertList;
						}
						if(updateList.size() > 0) {
							update updateList;
						}										
					}
					else {
						closeModal = false;
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Attendance to submit.'));
					}
				}
				catch(Exception e) {
					closeModal = false;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
				}
			}
		}

		public void updateSessions(Set<ID> sections, Set<ID> sessions, Date aDate) {
			Map<ID, List<Student__c>> sectionToStudents = new Map<ID, List<Student__c>>();
			Map<String, Map<ID, Attendance__c>> sectionToAttendances = new Map<String, Map<ID, Attendance__c>>();
			Map<ID, String> sectionNames  = new Map<ID, String>();
			Map<String, Session__c> sessionRecords = new Map<String, Session__c>();
			Set<ID> tStudents = new Set<ID>();

			try {
				for(Enrollment_Tracking__c et : [SELECT ID, Student_Section__r.Student__c, Student_Section__r.Section__c, Student_Section__r.Section__r.Name, Start_Date__c, End_Date__c FROM Enrollment_Tracking__c WHERE Student_Section__r.Section__c IN: sections AND Student_Section__c != null AND Active__c = true]) {
					sectionNames.put(et.Student_Section__r.Section__c, et.Student_Section__r.Section__r.Name);
					if(bEnrolled(et, aDate)) {
						if(!sectionToStudents.containsKey(et.Student_Section__r.Section__c)) {
							sectionToStudents.put(et.Student_Section__r.Section__c, new List<Student__c>{new Student__c(ID = et.Student_Section__r.Student__c)});
						}
						else {
							sectionToStudents.get(et.Student_Section__r.Section__c).add(new Student__c(ID = et.Student_Section__r.Student__c));
						}
						tStudents.add(et.Student_Section__r.Student__c);
					}
				}

				for(Attendance__c a : [SELECT ID, Student__c, Session__r.Section__c, Session__r.Reference_ID__c FROM Attendance__c WHERE Session__c IN: sessions AND Student__c IN: tStudents]) {
					if(!sectionToAttendances.containsKey(a.Session__r.Reference_ID__c)) {
						Map<ID, Attendance__c> tMap = new Map<ID, Attendance__c>();
						tMap.put(a.Student__c, a);
						sectionToAttendances.put(a.Session__r.Reference_ID__c, tMap);
					}
					else {
						sectionToAttendances.get(a.Session__r.Reference_ID__c).put(a.Student__c, a);
					}
				}

				for(Session__c s : [SELECT ID, Section__c, Attendance_Submitted__c, LastModified__c, Reference_ID__c FROM Session__c WHERE ID IN: sessions]) {
					sessionRecords.put(s.Reference_Id__c, s);
				}

				for(ID s : sections) {
					if(sectionToStudents.containsKey(s)) {
						system.debug('*~*~* sectionToStudents.size: ' + sectionToStudents.get(s).size());
						for(String ss : sessionRecords.KeySet()) {
							if(sessionRecords.get(ss).Section__c == s) {
								if(sectionToAttendances.containsKey(ss)) {
									system.debug('*~*~* sectionToAttendance.size: ' + sectionToAttendances.get(ss).size());						
									if(Attendance_Utils.isAttendanceTaken(sectionToStudents.get(s), sectionToAttendances.get(ss))) {
										//sessionRecords.get(ss).Attendance_Submitted__c = true;
									}
									else {
										//sessionRecords.get(ss).Attendance_Submitted__c = false;
									}
									sessionRecords.get(ss).LastModified__c = Attendance_Utils.setLastModified(sectionNames.get(s));
								}								
							}	
						}
					}
				}
				List<Session__c> tSessions = new List<Session__c>(sessionRecords.Values());
				//update sessionRecords.Values();
				update tSessions;
			}
			catch(Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to update session records.'));
			}
		}
	}

	public class sectionAttendanceSearch {
		//search criteria fields
		public String baseQuery {get; set;}
		public String sectionName {get; set;}
		public String sessionTime {get; set;}
		public String staffMembers {get; set;}

		public Date aDate {get; set;}
		public Session__c selectedSession {get; set;}
		public String selectedSessionTime {get; set;}

		//Modal Drill down results
		public List<SelectOption> attendancePV {get; set;}
		public Map<ID, Picklist_Value__c> pvMap {get; set;}
		public List<Picklist_Value__c> pvList {get; set;}
		public List<attendanceWizardWrapper> swAttendance {get; set;}

		//Result display... could put in another wrapper class, but is it worth?
		public List<ID> sessionResults {get; set;}  //KEY
		public Map<ID, String> sessionSectionNames {get; set;}
		public Map<ID, String> sessionTimes {get; set;}
		public Map<ID, String> sessionStaffMembers {get; set;}
		public Map<ID, Boolean> sessionAttendanceSubmitted {get; set;}

		public Boolean closeModal {get; set;}
		public Boolean setupLock {get; set;}
		public Setup__c setup {get; set;}

		public String afterSubmissionSuccess {get; set;}
		public List<Student__c> totalEnrolledStudents {get; set;}

		public String statusCopyDown {get; set;}
		public String arrivalCopyDown {get; set;}
		public String departureCopyDown {get; set;}
		public String commentCopyDown {get; set;}
		public Boolean selectAll {get; set;}

		public List<thousandLimitWrapper> thousandBlocks {get; set;}

		public sectionAttendanceSearch() {
			attendancePV = new List<SelectOption>();
			pvMap = new Map<ID, Picklist_Value__c>();
			pvList = new List<Picklist_Value__c>();
			swAttendance = new List<attendanceWizardWrapper>();

			sessionResults = new List<ID>();
			sessionSectionNames = new Map<ID, String>();
			sessionTimes = new Map<ID, String>();
			sessionStaffMembers  = new Map<ID, String>();
			sessionAttendanceSubmitted = new Map<ID, Boolean>();
			afterSubmissionSuccess = '';
		}

		public void retrieveEnrolledSections(Date attendanceDate, String currentSchool, Time_Element__c currentYear) {
			attendancePV = new List<SelectOption>();
			pvMap = new Map<ID, Picklist_Value__c>();
			pvList = new List<Picklist_Value__c>();
			swAttendance = new List<attendanceWizardWrapper>();

			sessionResults = new List<ID>();
			sessionSectionNames = new Map<ID, String>();
			sessionTimes = new Map<ID, String>();
			sessionStaffMembers = new Map<ID, String>();
			sessionAttendanceSubmitted = new Map<ID, Boolean>();
			baseQuery = 'SELECT ID, Section__c, Section__r.Name, Start_DateTime__c, End_DateTime__c, Attendance_Submitted__c, LastModified__c, Session_Date__c, Name FROM Session__c WHERE Section__r.Active__c = true ';

			try {
				setup = [SELECT ID, Read_Only_Attendance_Wizard_Records__c FROM Setup__c WHERE School__c =: currentSchool AND Year__c =: currentYear.ID];
				setupLock = setup.Read_Only_Attendance_Wizard_Records__c;
			}
			catch(Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot find a setup to determine the lock status for attendance.'));
			}
			
			try {
				aDate = attendanceDate;
				if(String.isNotEmpty(currentSchool)) {
					baseQuery += 'AND Section__r.School__c = ' + '\'' + currentSchool + '\' ';
				}
				if(String.isNotEmpty(sectionName)) {
					baseQuery += 'AND Section__r.Name LIKE ' + '\'%' + core_SoqlUtils.getSearchName(sectionName) + '\' ';
				}
				if(String.isNotEmpty(sessionTime)) {
					DateTime dTime = core_TimeUtils.processTimeText(sessionTime);
					DateTime cTime = DateTime.newInstance(aDate.year(), aDate.month(), aDate.day(),dTime.hour(), dTime.minute(), 0);
					String formatTime = cTime.format('YYYY-MM-dd') + 'T' + cTime.format('hh:mm:ssZ');
					baseQuery += 'AND Start_DateTime__c <= ' + formatTime + ' AND End_DateTime__c >= ' + formatTime + ' ';
				}			
				if(aDate != null) {
					DateTime tDate = DateTime.newInstance(aDate, System.now().time());
					baseQuery += 'AND Session_Date__c = ' + tDate.format('yyyy-MM-dd') + ' ';
				}
				if(String.isNotEmpty(staffMembers)) {
					Set<ID> ssSections = new Set<ID>();
					String tName = '%' + core_SoqlUtils.getSearchName(staffMembers);
					for(Staff_Section__c ss : [SELECT ID, Staff__c, Staff__r.Name, Section__c FROM Staff_Section__c WHERE Staff__r.Name LIKE: tName ORDER BY Staff__r.Name ASC]) {
						ssSections.add(ss.Section__c);
					}
					if(ssSections.size() > 0) {
						baseQuery += 'AND Section__c IN: ssSections ';
					}
				}
				baseQuery += ' ORDER BY Start_DateTime__c ASC LIMIT 1001';

				Map<ID, String> tStaffMembers = new Map<Id, String>();
				Set<ID> sections = new Set<ID>();		
				List<Session__c> processed = Database.query(baseQuery);

				if(processed.size() == 0) {
					String warningString = 'There are no sessions that match the search criteria you entered. ';
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, warningString));
					return;
				}
				else {
					Integer plus1000 = 0;
					for(Session__c session : processed) {
						if(plus1000 < 1000) {
							sessionResults.add(session.ID);
							sessionSectionNames.put(session.ID, session.Section__r.Name);
							if(session.Start_DateTime__c != null && session.End_DateTime__c != null) {
								sessionTimes.put(session.ID, session.Start_DateTime__c.format('h:mm a') + ' - ' + session.End_DateTime__c.format('h:mm a'));
							}
							sessionStaffMembers.put(session.ID, '');
							sessionAttendanceSubmitted.put(session.ID, session.Attendance_Submitted__c);
							sections.add(session.Section__c);
							plus1000++;
						}
					}
					if(processed.size() > 1000) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There were more than 1,000 sessions that met your search criteria.  Only 1,000 are displayed.'));
					}

					for(Staff_Section__c ss : [SELECT ID, Staff__c, Staff__r.Name, Section__c FROM Staff_Section__c WHERE Section__c IN: sections AND Staff__c != null ORDER BY Staff__r.Name ASC]) {
						if(!tStaffMembers.containsKey(ss.Section__c)) {
							tStaffMembers.put(ss.Section__c, ss.Staff__r.Name);
						}
						else {
							String s = tStaffMembers.get(ss.Section__c) + ', ' + ss.Staff__r.Name;
							tStaffMembers.put(ss.Section__c, s);
						}
					}

					for(Session__c session : processed) {
						if(tStaffMembers.containsKey(session.Section__c)) {
							sessionStaffMembers.put(session.ID, tStaffMembers.get(session.Section__c));
						}
					}
				}
			}
			catch(Exception e) {
				ApexPages.addMessage(new Apexpages.Message(apexpages.Severity.ERROR, e.getMessage()));
			}
		}

		public void getEnrolledAttendance() {
			statusCopyDown = '';
			arrivalCopyDown = '';
			departureCopyDown = '';
			commentCopyDown = '';
			selectAll = false;
			swAttendance = new List<attendanceWizardWrapper>();
			String sessionID = apexPages.currentPage().getParameters().remove('sessionID');
			pvMap = AttendanceWizard_v2.getAttendancePicklistValues(setup.ID);
			pvList = pvMap.Values();
			attendancePV = AttendanceWizard_v2.getAttendanceStatusOptions(pvMap.Values());

			Set<ID> studentIDs = new Set<ID>();

			Map<ID, attendanceWizardWrapper> tempWrapperMap = new Map<ID, attendanceWizardWrapper>();
			system.debug('*~*~* sessionID: ' + sessionID);
			selectedSession = [SELECT ID, Section__c, Section__r.Name, Section__r.Daily_Attendance__c, Start_DateTime__c, End_DateTime__c, Attendance_Submitted__c, LastModified__c, Name FROM Session__c WHERE ID =: sessionID];
			selectedSessionTime = selectedSession.Start_DateTime__c.format('h:mm a') + ' - ' + selectedSession.End_DateTime__c.format('h:mm a');

			for(Enrollment_Tracking__c et : [SELECT ID, Student_Section__c, Student_Section__r.Student__c, Student_Section__r.Student__r.Name, Student_Section__r.Student__r.Student_First_Name__c, Student_Section__r.Student__r.Student_Last_Name__c, Student_Section__r.Section__c, Start_Date__c, End_Date__c FROM Enrollment_Tracking__c WHERE Student_Section__c != null AND Student_Section__r.Section__c =: selectedSession.Section__c AND Active__c = true]) {
				if(AttendanceWizard_v2.bEnrolled(et, aDate)) {
					tempWrapperMap.put(et.Student_Section__r.Student__c, new attendanceWizardWrapper(et, selectedSession, 'Section'));
					studentIDs.add(et.Student_Section__r.Student__c);
				}
			}

			totalEnrolledStudents = [SELECT ID FROM Student__c WHERE ID IN: studentIDs];
			for(Attendance__c at : [SELECT ID, Student__c, Student__r.Name, Student__r.Student_First_Name__c, Student__r.Student_Last_Name__c, Session__c, Session__r.Section__c, Session_Start_Time__c, Session_End_Time__c, Picklist_Value__c, Arrival_Time__c, Arrival_Time_Text__c, Departure_Time__c, Departure_Time_Text__c, Comments__c FROM Attendance__c WHERE Session__c =: selectedSession.ID]) {
				if(tempWrapperMap.containsKey(at.Student__c)) {
					tempWrapperMap.put(at.Student__c, new attendanceWizardWrapper(at, selectedSession, 'Section'));
				}
			}


			swAttendance = new List<attendanceWizardWrapper>(tempWrapperMap.Values());
			swAttendance.sort();
			thousandBlocks = AttendanceWizard_v2.getThousandBlocks(swAttendance);

			if(swAttendance.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'This session does not have students enrolled for the date you selected.  Update the search criteria and try again.'));
			}
		}

		public void submitAttendance() {
			closeModal = AttendanceWizard_v2.validateSubmission(swAttendance, pvMap, aDate);
			if(closeModal) {
				List<Attendance__c> insertList = new List<Attendance__c>();
				List<Attendance__c> updateList = new List<Attendance__c>();	

				Map<ID, Attendance__c> isAttendanceTakenMap = new Map<ID, Attendance__c>();
					
				for(thousandLimitWrapper tlw : thousandBlocks) {
					for(attendanceWizardWrapper sw : tlw.aww) {
						sw.at.Locked__c = setupLock;  
						if(sw.at.ID  != null) {
							updateList.add(sw.at);
							isAttendanceTakenMap.put(sw.at.Student__c, sw.at);
						}
						else if(sw.at.Picklist_Value__c != null && sw.at.ID == null) {
							insertList.add(sw.at);
							isAttendanceTakenMap.put(sw.at.Student__c, sw.at);
						}
					}					
				}	

				try {
					if(insertList.size() > 0 || updateList.size() > 0) {
						if(insertList.size() > 0) {
							insert insertList;
						}
						if(updateList.size() > 0) {
							update updateList;
						}
						/*
						if(Attendance_Utils.isAttendanceTaken(totalEnrolledStudents, isAttendanceTakenMap)) {
							selectedSession.Attendance_Submitted__c = true;
						}
						else {
							selectedSession.Attendance_Submitted__c = false;
						}
						*/
						selectedSession.LastModified__c = Attendance_Utils.setLastModified(selectedSession.Section__r.Name);
						update selectedSession;
						afterSubmissionSuccess = 'Attendance records submitted for ' + selectedSession.Section__r.Name;												
					}
					else {
						closeModal = false;
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Attendance to submit.'));
					}
				}
				catch(Exception e) {
					closeModal = false;
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
				}
			}
		}				
	}

	public void getAfterSubmissionSuccess() {
		if(bMode == 'Student') {
			if(String.isNotEmpty(stSearch.afterSubmissionSuccess)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, stSearch.afterSubmissionSuccess));
				stSearch.afterSubmissionSuccess = '';
			}
			
		}
		else {
			if(String.isNotEmpty(snSearch.afterSubmissionSuccess)) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, snSearch.afterSubmissionSuccess));
				snSearch.afterSubmissionSuccess = '';
			}
		}
	}
}