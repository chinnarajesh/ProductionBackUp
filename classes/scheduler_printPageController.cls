global with sharing class scheduler_printPageController {
	/* PAGE CONTROLS*/
	public boolean bPreSelect			{get;set;} //was a student/staff selected before load?
	public String scheduleType			{get;set;} //either 'staff' OR 'student'
	public String dateType				{get;set;} //either 'All'. '1 week', '2 weeks'
	public boolean bTimeFiltersDisplay	{get;set;}
	public boolean bpdf					{get;set;}
	public String maxWidth				{get;set;}
	public boolean bAutoGenerate		{get;set;}

	/* PAGE DATA */
	public List<SelectOption> rpList	{get;set;}
	public Time_Element__c dateHolder	{get;set;}
	public String selectedID			{get;set;}
	public String searchFirstName		{get;set;}
	public String searchLastName		{get;set;}
	public String selectedRP			{get;set;}
	public Student__c selectedStudent	{get;set;}
	public Staff__c selectedStaff		{get;set;}
	public String scheduleEmail			{get;set;}
	public String scheduleCCEmail		{get;set;}
	public Setup__c staffSetup			{get;set;}

	/*Search Data*/
	public List<Student__c> studentSearchResults	{get;set;}
	public List<Staff__c> staffSearchResults		{get;set;}

	/* INTERNAL DATA */
	private Map<ID, Time_Element__c> rpMap;
	private Set<String> daysSet;
	private Date firstStart;
	private Date lastEnd;
	private Map<ID,ID> courseToSectionMap;
	private ID lastLoadedSchool;
	private Boolean groupBased;

	/* Scheduler Generation */
	public List<String> daysOfWeek				{get;set;}
	public List<weekWrapper> scheduleWrapper	{get;set;}
	public String displayName					{get;set;} //name of student/staff generated for
	
	public scheduler_printPageController(){
		Map<String, String> params = ApexPages.currentPage().getParameters();
		bAutoGenerate = params.get('bAutoGenerate')!=null;
		bPreSelect = params.get('bPreSelect')!=null;
		rpMap = new Map<ID,Time_Element__c>();
		bPdf = params.get('pdf')==null;
		selectedStaff = new Staff__c();
		selectedStudent = new Student__c();
		dateType = 'all';
		scheduleType = 'student';
		DateHolder = new Time_Element__c();
		groupBased = false;
		
		if(bPreSelect){
			selectedID = params.get('selectedID');
			scheduleType = params.get('scheduleType');

			if(scheduleType == 'staff'){
				getStaff();
			} else if(scheduleType == 'student'){
				getStudents();
			} else {
				//this shouldn't ever happen.
				Error_Handling.errorMessage('The system was unable to load properly. Please check your settings and try again.');
				return;
			}
			//this is an optimization, if they preload, they only have one choice to load, so just preload the RP data for that person.
			loadForGeneation();

			if(bAutoGenerate){
				dateType = params.get('dateType');
				dateHolder.Date_Start_Date__c = (params.get('startDate')!=null)?Date.valueOf(params.get('startDate')):null;
				if(dateType == 'all'){
					dateHolder.End_Date__c = (params.get('endDate')!=null)?Date.valueOf(params.get('endDate')):null;
				} else {
					//For the week based, the date ranges are inclusive on both ends, so 1/1/13 + 7 days =  1/8/13, but we really only want 7 days inclusive, so add 6 days
					dateHolder.End_Date__c = (dateType == 'oneweek')?dateHolder.Date_Start_Date__c.addDays(6):dateHolder.Date_Start_Date__c.addDays(13);
				}
				generate();
			}
		}
	}

	public void updateFilters(){
		if(selectedRP != 'all' && rpMap.containsKey(selectedRP)){
			dateHolder.Date_Start_Date__c = rpMap.get(selectedRP).Date_Start_Date__c;
			refreshDateType();
		} else {
			dateHolder.Date_Start_Date__c = firstStart;
			dateHolder.End_Date__c = lastEnd;
		}
	}

	public void refreshDateType(){
		//For the week based, the date ranges are inclusive on both ends, so 1/1/13 + 7 days =  1/8/13, but we really only want 7 days inclusive, so add 6 days
		if(dateType == 'oneweek'){
			dateHolder.End_Date__c = DateHolder.Date_Start_Date__c.addDays(6);
		} else if(dateType == 'twoweeks') {
			dateHolder.End_Date__c = DateHolder.Date_Start_Date__c.addDays(13);
		} else if(dateType == 'all'){
			if(selectedRP != 'all' && rpMap.containsKey(selectedRP))
				DateHolder.End_Date__c = rpMap.get(selectedRP).End_Date__c;
			else
				DateHolder.End_Date__c = lastEnd;
		}
	}

	public void loadForGeneation(){
		if(scheduleType == 'student'){
			if(selectedStudent.id != selectedID){
				selectedStudent = (Student__c)getSelectedRecord();
				loadReportingPeriods(selectedStudent.School__c);
			}
		} else if(scheduleType == 'staff'){
			if(selectedStaff.Reference_ID__c != selectedID){
				selectedStaff = (Staff__c)getSelectedRecord();
				loadReportingPeriods(selectedStaff.Organization__c);
			}
		}
		dateType = 'all';
	}
	
	public void getStudents(){
		if(!bPreSelect &&(searchFirstName == null || searchFirstName == '')){
			Error_Handling.errorMessage('First name is required.');
			return;
		}
		studentSearchResults = new List<Student__c>();

		string query='select id, Name, Student_First_Name__c, Student_Last_Name__c, School__r.Name, Grade__c, Student_Id__c, School_Year__r.Name__c from Student__c where ';
		if(bPreSelect){
			query += 'ID =\''+selectedID+'\'';
		} else {
			if(searchFirstName != null && searchFirstName != ''){
				query+= 'Student_First_Name__c LIKE \''+ core_SoqlUtils.getSearchName(searchFirstName) + '\' AND ';
			}
			if(searchLastName != null && searchLastName != ''){
				query+= 'Student_Last_Name__c LIKE \'' + core_SoqlUtils.getSearchName(searchLastName) + '\' AND ';
			}	
			query+= 'Active__c = true';
		}
		
		studentSearchResults = Database.query(query);

		if(studentSearchResults.size()>0){
			bTimeFiltersDisplay = true;
		} else {
			Error_Handling.infoMessage('Your search returned zero results.');
		}
	}

	public void getStaff(){
		if(!bPreSelect &&(searchFirstName == null || searchFirstName == '')){
			Error_Handling.errorMessage('First name is required.');
			return;
		}
		staffSearchResults = new List<Staff__c>();
		String query = 'Select ID, Name, First_Name_Staff__c, Staff_Last_Name__c, Organization__r.Name, Grade__c, ID__c, Reference_Id__c from Staff__c where ';
		if(bPreSelect){
			//use the reference ID because salesforce formula buttons cannot tell between Staff__c.ID and Staff__c.ID__c
			system.debug(selectedID);
			query += 'Reference_Id__c=\''+selectedID+'\'';
		} else {
			if(searchFirstName != null && searchFirstName != ''){
				query+= 'First_Name_Staff__c LIKE \''+ core_SoqlUtils.getSearchName(searchFirstName) + '\' AND ';
			}
			if(searchLastName != null && searchLastName != ''){
				query+= 'Staff_Last_Name__c LIKE \'' + core_SoqlUtils.getSearchName(searchLastName) + '\' AND ';
			}	
			query+= 'Active__c = true';
		}
		system.debug(query);
		staffSearchResults = Database.query(query);
		system.debug(staffSearchResults.size());

		if(staffSearchResults.size()>0){
			bTimeFiltersDisplay = true;
		} else {
			Error_Handling.infoMessage('Your search returned zero results.');
		}
	}

	private void loadReportingPeriods(ID schoolID){
		if(schoolId != lastLoadedSchool){
			staffSetup = core_SoqlUtils.getActiveSetups(new Set<ID>{schoolID}).get(schoolID);
			ID termID = staffSetup.Term__c;
			rpList = new List<SelectOption>{new SelectOption('All','All')};
			rpMap = new Map<ID, Time_Element__c>();
			boolean isFirst = true;
			for(Time_Element__c te : [Select ID, Days_of_Week__c, End_Date__c, Date_Start_Date__c, Name__c 
										FROM Time_Element__c 
										WHERE Parent_Time_Element__c =: termID
										AND Reporting_Period__c = true
										order by Date_Start_Date__c]){
				if(isFirst){
					//because rps get their days from the term, we can just use the first one.
					buildWeekHeaders(te.Days_of_Week__c);
					firstStart = te.Date_Start_Date__c;
					//10 inch page, 1 pt is 1/72 of an inch, so 720/number of columns gives you the max size for each column
					maxWidth = String.ValueOf(Math.round(720/daysSet.size()))+'pt';
					isFirst = false;
				}
				lastEnd = te.End_Date__c;
				rpList.add(new SelectOption(te.id, te.Name__c));
				rpMap.put(te.id, te);
				
			}
			dateHolder = new Time_Element__c(End_Date__c=lastEnd, Date_Start_Date__c=firstStart);
		}
	}

	/* Single Generation */
	public PageReference generateAndPrint(){
		Attachment schedule = new Attachment(
			parentId = (scheduleType == 'staff')?selectedStaff.Id:selectedStudent.Id,
			Name=buildAttachmentName()
		);

		schedule.body = generatePDF();
		ID attachmentID = upsertSchedule(schedule);
		PageReference attachmentLocation = new PageReference('/servlet/servlet.FileDownload');
		attachmentLocation.getParameters().put('file',attachmentID);
		return attachmentLocation;
	}

	public void generateAndEmail(){
		system.debug(scheduleEmail);
		if(scheduleEmail == ''||scheduleEmail ==null){
			Error_Handling.errorMessage('You must enter an email.');
			return;
		}

		Attachment schedule = new Attachment(
			parentId = (scheduleType == 'staff')?selectedStaff.Id:selectedStudent.Id,
			Name=buildAttachmentName()
		);
		schedule.body = generatePDF();
		ID attachmentID = upsertSchedule(schedule);

		List<String> emails = StringUtils.splitandTrim(scheduleEmail,',');
		Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
		if(scheduleCCEmail != null && scheduleCCEmail != ''){
			message.setCcAddresses(StringUtils.splitandTrim(scheduleCCEmail,','));
		}
		message.setToAddresses(emails);
		message.setSubject('SchoolForce - Schedule For '+((scheduleType == 'staff')?selectedStaff.Name:selectedStudent.Name));
		message.setPlainTextBody('Please see the schedule attached below.');
		message.setUseSignature(false);
		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		//create and link attachment
		attachment.setBody(schedule.body);
		attachment.setContentType('application/pdf');
		attachment.setFileName(schedule.Name);
		attachment.setInline(false);
		message.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
		schedule = null;

		try{
			Messaging.sendEmail(new Messaging.Email[]{message}, true);
			Error_Handling.successMessage('The schedule was emailed successfuly.');
		} catch(Exception e){
			Error_Handling.errorMessage('Unable to send the email. Please check the email addresses entered');
		}
	}

	private String buildAttachmentName(){
		String attachmentName = ((selectedRP == 'all')?'All':rpMap.get(selectedRP).Name__c);
		if(scheduleType == 'student'){
			Student__c s = (Student__c) getSelectedRecord();
			attachmentName += '.'+s.School__r.Name+'.'+s.Grade__c+'.'+s.Student_Last_Name__c+'.'+s.Student_Id__c+'.Schedule.pdf';
		} else if(scheduleType == 'staff'){
			Staff__c s = (Staff__c) getSelectedRecord();
			attachmentName += '.'+s.Organization__c+'.'+s.Staff_Last_Name__c+'.'+s.Id__c+'.Schedule.pdf';
		}
		return attachmentName;
	}

	private Blob generatePDF(){
		PageReference pdfPage = buildReference();
		system.debug(pdfPage);
		if(!Test.isRunningTest())
			return pdfPage.getContentAsPDF();
		return Blob.valueOf('This is a test.');
	}

	private pageReference buildReference(){
		PageReference pdfPage = new PageReference('/apex/pdfSchedule');
		pdfPage.getParameters().put('bPreSelect','true');
		pdfPage.getParameters().put('bAutoGenerate','true');
		pdfPage.getParameters().put('selectedID',selectedID);
		pdfPage.getParameters().put('scheduleType',scheduleType);
		pdfPage.getParameters().put('dateType', dateType);
		pdfPage.getParameters().put('startDate',StringUtils.getQueryDate(DateHolder.Date_Start_Date__c.format()));
		pdfPage.getParameters().put('endDate',StringUtils.getQueryDate(DateHolder.End_Date__c.format()));
		pdfPage.setRedirect(false);
		system.debug(pdfPage.getURL());
		return pdfPage;
	}

	private ID upsertSchedule(Attachment a){
		List<Attachment> existing = [select id from Attachment where parentId=:a.ParentID and Name=:a.Name order by CreatedDate limit 1];
		if(existing.size()>0){
			a.id = existing[0].id;
		}
		upsert a;
		return a.id;
	}

	/* Bulk Generation */
	private void generate(){
		if(dateHolder.Date_Start_Date__c == null && dateType != 'all'){
			Error_Handling.errorMessage('You must enter a start date.');
			return;
		}
		getDisplayName();

		Set<ID> sections = getTargetSections();
		List<Session__c> sessions = loadSessionData(sections);

		Map<ID, String> staffMap = new Map<ID,String>();
		if(scheduleType == 'student')
			staffMap = buildStaffMap(sections);
		/*
			Map is Section ID to Reporting Period ID to period (string) to room name. Sorry is has to be that way, but the session room depends on all of those
		*/
		Map<ID,Map<Id,Map<String,String>>> sectionRoomMap = buildRoomMap(sections);
		buildSchedule(sessions, staffMap, sectionRoomMap);
	}

	/* Generation Methods */
	private void buildWeekHeaders(String days){
		daysSet = new Set<String>();
		daysOfWeek = new List<String>();
		if(days.contains('U')){
			daysOfWeek.add('Sunday');
		}
		if(days.contains('M')){
			daysOfWeek.add('Monday');
		}
		if(days.contains('T')){
			daysOfWeek.add('Tuesday');
		}
		if(days.contains('W')){
			daysOfWeek.add('Wednesday');
		}
		if(days.contains('H')){
			daysOfWeek.add('Thursday');
		}
		if(days.contains('F')){
			daysOfWeek.add('Friday');
		}
		if(days.contains('S')){
			daysOfWeek.add('Saturday');
		}
		daysSet.addAll(daysOfWeek);
	}

	private Date toFirstSchoolDay(Date d){
		Datetime dt = DateTime.newInstance(d.toStartOfWeek(),Time.newInstance(0,0,0,0)); //this might break if we ever start giving this out to EU schools.
		system.debug('Aborting at: '+DateTime.newInstance(d.addDays(7),Time.newInstance(0,0,0,0)));
		while(dt < DateTime.newInstance(d.addDays(7),Time.newInstance(0,0,0,0))){
			system.debug('Checking for '+dt.format('EEEE'));
			if(daysSet.contains(dt.format('EEEE'))){
				return Date.newInstance(dt.year(), dt.month(), dt.day());
			} else {
				dt = dt.addDays(1);
			}
		}
		return null;
	}

	private void getDisplayName(){
		displayName = '';
		sObject record = getSelectedRecord();
		if(record!=null){
			displayName = (String) record.get('Name');
		}
	}

	private sObject getSelectedRecord(){
		if(scheduleType== 'student'){
			for(Student__c s:studentSearchResults){
				if(s.id == selectedID){
					return s;
				}
			}
		} else if(scheduleType =='staff') {
			for(Staff__c s:staffSearchResults){
				if(s.Reference_Id__c == selectedID){
					return s;
				}
			}
		}
		return null;
	}

	private List<Session__c> loadSessionData(Set<ID> sections){
		string query = 'select Start_DateTime__c, Session_Date__c, End_DateTime__c, Section__c, Section__r.Course__r.Name,Time__c, Reference_Id__c from Session__c'+
						+' where Section__c IN: sections';
		if(dateHolder.Date_Start_Date__c != null){
			query += ' and Session_Date__c >= '+ StringUtils.getQueryDate(DateHolder.Date_Start_Date__c.format());
		}
		if(dateHolder.End_Date__c != null){
			query += ' and Session_Date__c <= '+ StringUtils.getQueryDate(DateHolder.End_Date__c.format());
		}
		query += ' order by Session_Date__c, Start_DateTime__c, Section__r.Course__r.Name';
		return Database.query(query);
	}

	private Set<ID> getTargetSections(){
		Set<ID> sections = new Set<ID>();
		courseToSectionMap = new Map<ID,ID>();

		if(scheduleType=='staff'){
			for(Staff_Section__c ss:
					[select Section__c, Section__r.Schedule_Group__c, Section__r.Course__c
					from Staff_Section__c 
					where Staff__r.Reference_Id__c =: selectedID 
					and Is_Active__c = true 
					and Archived__c = false
					and Section__r.Course__r.Display_on_Student_Staff_Schedule__c = true
					AND Section__r.RecordType.DeveloperName='Published']){
				sections.add(ss.Section__c);
				courseToSectionMap.put(ss.Section__r.Course__c,ss.Section__c);
				if(ss.Section__r.Schedule_Group__c!=null){
					sections.add(ss.Section__r.Schedule_Group__c);
				}
			}
		} else if(scheduleType=='student'){
			for(Student_Section__c ss:
					[select Section__c, Section__r.Schedule_Group__c, Section__r.Course__c
					from Student_Section__c
					where Student__c =: selectedID
					and Active__c = true
					and Archived__c = false
					and Section__r.Course__r.Display_on_Student_Staff_Schedule__c = true
					and Section__r.RecordType.DeveloperName = 'Published']){
				sections.add(ss.Section__c);
				courseToSectionMap.put(ss.Section__r.Course__c,ss.Section__c);
				if(ss.Section__r.Schedule_Group__c!=null){
					sections.add(ss.Section__r.Schedule_Group__c);
				}
			}
		}

		return sections;
	}

	private Map<ID, String> buildStaffMap(Set<ID> sections){
		Map<ID, String> staffMap = new Map<ID, String>();
		for(Staff_Section__c ss:[select Section__c,Staff__r.Name from Staff_Section__c where Section__c IN: sections AND Display_Teacher_On_RC_PR__c=true]){
			if(!staffMap.containsKey(ss.Section__c)){
				staffMap.put(ss.Section__c, ss.Staff__r.Name);
			}
		}
		return staffMap;
	}

	private Map<ID,Map<Id,Map<String,String>>> buildRoomMap(Set<ID> sections){
		Map<ID,Map<Id,Map<String,String>>> roomMap = new Map<ID,Map<Id,Map<String,String>>>();

		//we need the scheduled sections to build the map, but that's it
		for(Scheduled_Section__c ss:[select id, Room__r.Name, Reporting_Period__c, Course__c, Section__c, Schedule_Group_Section__c, Period_Key__c
				from Scheduled_Section__c
				//period based has sections
				where (Section__c IN: sections)
				//group based requires the schedule group and course (unique combo per group)
				OR (Schedule_Group_Section__c IN: sections AND Course__c IN: courseToSectionMap.keySet())]){
			ID sectionId;
			if(ss.Section__c == null && ss.Schedule_Group_Section__c!= null){
				sectionID = courseToSectionMap.get(ss.Course__c);
				groupBased = true;
			}else if(ss.Section__c != null){
				sectionID = ss.Section__c;
			}

			if(roomMap.containsKey(sectionID)){
				if(roomMap.get(sectionID).containsKey(ss.Reporting_Period__c)){
					roomMap.get(sectionID).get(ss.Reporting_Period__c).put(ss.Period_Key__c,ss.Room__r.Name);
				} else {
					roomMap.get(sectionID).put(ss.Reporting_Period__c,new Map<String, String>{ss.Period_Key__c => ss.Room__r.Name});
				}
			} else{
				roomMap.put(sectionID, new Map<ID, Map<String,String>>{ss.Reporting_Period__c => new Map<String, String>{ss.Period_Key__c => ss.Room__r.Name}});
			}
		}

		return roomMap;
	}

	private void buildSchedule(List<Session__c> sessions, Map<ID,String> staffMap, Map<ID,Map<Id,Map<String,String>>> roomMap){
		scheduleWrapper = new List<weekWrapper>();
		
		if(DateHolder.Date_Start_Date__c == null){
			DateHolder.Date_Start_Date__c = firstStart;
		}
		if(DateHolder.End_Date__c == null){
			DateHolder.End_Date__c = lastEnd;
		}

		Date processingDate = toFirstSchoolDay(DateHolder.Date_Start_Date__c);
		system.debug(processingDate.format());
		while(sessions.size()>0 && processingDate <= DateHolder.End_Date__c){
			weekWrapper week = new weekWrapper();
			for(String dow:daysOfWeek){
				system.debug('Processing day '+processingDate.format()+' is inside the range:'+(processingDate >= DateHolder.Date_Start_Date__c && processingDate <= DateHolder.End_Date__c));
				dayWrapper day = new dayWrapper(dow, processingDate.format(), (processingDate >= DateHolder.Date_Start_Date__c && processingDate <= DateHolder.End_Date__c));
				while(sessions.size()>0 && sessions[0].Session_Date__c == processingDate){
					Session__c session = sessions.remove(0);
					String staffName = (staffMap.containsKey(session.Section__c))?staffMap.get(session.Section__c):'';
					String period = (session.Reference_Id__c!=null && session.Reference_Id__c.split('-').size()>1)?session.Reference_Id__c.split('-')[1]:null;
					String roomName = '';
					//null check everything, just in case
					if(roomMap.containsKey(session.Section__c) 
							&& roomMap.get(session.Section__c).containsKey(session.Time__c)){
						if(!groupBased && roomMap.get(session.Section__c).get(session.Time__c).containsKey(period)){
							roomName = roomMap.get(session.Section__c).get(session.Time__c).get(period);
						} else if(roomMap.get(session.Section__c).get(session.Time__c).containsKey(null)){
							roomName = roomMap.get(session.Section__c).get(session.Time__c).get(null);
						}
					}
					day.sections.add(new sectionWrapper(session.Start_DateTime__c.format('h:mm a'),session.End_DateTime__c.format('h:mm a'),session.Section__r.Course__r.Name,staffName,roomName));
					day.dayName = dow;
				}
				week.days.add(day);
				processingDate = getNextSchoolDay(processingDate);
			}
			scheduleWrapper.add(week);
		}
	}

	private Date getNextSchoolDay(Date d){
		while(d<=DateHolder.End_Date__c.addDays(7)){
			if(daysSet.contains(DateTime.newInstance(d.addDays(1), Time.newInstance(0,0,0,0)).format('EEEE'))){
				return d.addDays(1);
			} else {
				d = d.addDays(1);
			}
		}
		return DateHolder.End_Date__c.addDays(1);
	}
	
	
	
	/* WRAPPERS */
	public class weekWrapper{
		public List<dayWrapper> days	{get;set;}

		public weekWrapper(){
			days = new List<dayWrapper>();
		}
	}

	public class dayWrapper{
		public List<sectionWrapper> sections	{get;set;}
		public String dayName					{get;set;}
		public String dateString				{get;set;}
		public boolean isInside					{get;set;} //is this day inside the requested range

		public dayWrapper(String dayName, String dateString, boolean isInside){
			sections = new List<sectionWrapper>();
			this.dayName = dayName;
			this.dateString = dateString;
			this.isInside = isInside;
		}
	}

	public class sectionWrapper{
		public String startTime		{get;set;}
		public String endTime		{get;set;}
		public String courseName	{get;set;}
		public String staffNames	{get;set;}
		public String room			{get;set;}

		public sectionWrapper(String startTime, String endTime, String courseName, String staffNames, String room){
			this.startTime  = startTime;
			this.endTime	= endTime;
			this.courseName	= courseName;
			this.staffNames	= staffNames;
			this.room		= room;
		}
	}

	//Depricated - cannot remove from package
	@RemoteAction
	global static String emailSched(String HTML, String toEmail){return null;} 
}