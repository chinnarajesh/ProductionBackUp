public class PortalWrapper {
	public transient AccountWrapper acc		{get;set;}
	public Setup__c pic						{get;set;}
	public transient ContactWrapper contact	{get;set;}
	public Student__c currstudent			{get;set;}
	public String calandarUrl				{get;set;}
	public transient Id contactId			{get;set;}
	public transient User usr				{get;set;}
	public Boolean showemptyawards			{get;set;}
	public transient Id currentYearId		{get;set;}
	public String selectedSectionGrade		{get;set;}
	public Integer behIncdCountYTD			{get;set;}
	public Integer dailyExcsAbsences		{get;set;}
	public Integer dailyUnExcsAbsences		{get;set;}
	public Integer dailyTardies				{get;set;}
	public Integer dailyDepartures			{get;set;}
	public String schoolWebsite				{get;set;}
	public Double behaviorTimeLost			{get;set;}
	public Double attendanceTimeLost		{get;set;}
	public Double studentPointsBal			{get;set;}
	public Decimal studentCS				{get;set;}
	public String selectedLanguage			{get;set;}
	public Decimal currentGPA				{get;set;}

	public List<Calendars__c> progsList							{get;set;}
	public transient List<Section__c> sectionList				{get;set;}
	public transient List<Student_Section__c> studentSections	{get;set;}
	public List<SectionGradeWrapper> sectionGradeWrapperList	{get;set;}
	public List<Awards__c> awardsList							{get;set;}
	public List<Awards__c> awardsListFull						{get;set;}
	public List<Integer> emptyAwardsList						{get;set;}
	public List<Alert__c> alertsList							{get;set;}
	public List<Alert__c> smallAlertsList						{get;set;}
	public List<String> translationOptions						{get;set;}
	public Map<String, String> translationStrings				{get;set;}

	public List<AssignmentWrapper> currAssignsPerSectionList	{get;set;}
	public List<AssignmentWrapper> currAssignsPerSection		{get;set;}
	public List<AssignmentWrapper> pastAssignsPerSectionList	{get;set;}
	public List<AssignmentWrapper> currentAssignmentList		{get;set;}
	public List<AssignmentWrapper> overdueAssignmentList		{get;set;}
	public List <GradeWrapper> progressGradeList				{get;set;} //Variable for my progress Grades
	public List<StudentPortfolioWrapper> portFolioAssignsList	{get;set;}
	public List<External_Resources__c> mediaList				{get;set;}
	public List<External_Resources__c> standsResList			{get;set;}
	public List<External_Resources__c> standsbulletinList		{get;set;}
	public List<CourseWrapper> courses							{get;set;}
	public List<courseNameWrapper> courseNames					{get;set;}
	public List<ReportCardsWrapper> reportCardsList				{get;set;}
	public List<Student_Behavior__c> latestBehincidents			{get;set;}
	public List<Student_Behavior__c> allBehincidents			{get;set;}
	public List<SectionalAttendanceWrapper> sectionalAtt		{get;set;}
	public transient List<Time_Element__c> currReportingPeriod	{get;set;}
	public List<Time_Element__c> reportingPeriodList			{get;set;}
	public List<StrandWrapper> strandsByCourseList				{get;set;}

	public transient Map<String,String> sectionToStaffStringMap;
	public Map <String, String>	sectionGradeMap;
	public Map<String,String> courseToSectionsMap;
	public Map<String,List<Grade__c>> sectionToListOfGrades;
	public Map<String,List<AssignmentWrapper>> sectionIdToListOfPastAssignmentsMap;
	public Map<String,List<AssignmentWrapper>> sectionIdToListOfCurrAssignmentsMap;
	public transient Map<Id,Attachment> assignmentToAttachmentMap;
	public transient Map<Id,List<Attachment>> gradeToAttachmentsMap;
	public transient Map<Id, StudentPortfolioWrapper> IdToStudentWrapperMap;
	public transient Map<Id,List<String>> sectionToStaffSectionsMap;
	public Map<Id,List<External_Resources__c>> sectionToMediaMap;
	public transient Map<Id,List<External_Resources__c>> standToVideoLinksMap;
	public transient Map<Id,List<External_Resources__c>> standToUrlsMap;
	public transient Map<String,SectionalAttendanceWrapper> sectionNameToAttCount;
	public transient Map<String,Student_Reporting_Period__c> attachmentToStudentRP;
	public transient Map<String, Set<String>> courseToStandMap;
	public Map<String, List<External_Resources__c>> courseToStandVideosMap;
	public Map<String, List<External_Resources__c>> courseToStandUrlsMap;
	public transient Map<String,String>	assignmentToGrademap;
	public List<CourseWrapper> myStandardCourses				{get;set;}
	public Map<String,List<StrandWrapper>> sectionToStrandWrapper;
	public transient Set<Id> standsNotMastered;
	transient List<Grade__c> individualGrades;
	transient List<Grade__c> retrievedGrades;
	public List<HomeworkWrapper> homeworkInfo	{get;set;}

	public PortalWrapper(Id usrId){
		this.usr = [SELECT Name,Id,ContactId
					From User
					WHERE Id = : usrId];

		contactWrapper c = getContact();
		if(c == null){
			return;
		}
		getStudents();
		loadLanguageSettings();
		getAccount();
		getCurrTermReportinPeriods();
		getCurrentRepPeriod();
		getSectionsForStudent();
		getHomework();
		getStaffSections();
		getsectionGrades();
		getAwards();
		getemptyAwardsList();
		getAlerts();
		getCommunityService();
		getAssignments();
		getCourses();
		getMediaLinks();
		getCalandarUrl();
		getStudentScoreCard();
		getStudentBehaviorScore();
		getStudentReportCards();
		getStudentStandardGrades();
		getStandsResourceList();
	}

	public ContactWrapper getContact(){
		Id usId = usr.ContactId;
		if(contact == null){
			Contact c;
			try{
				c = [SELECT Id,Name,Student__c, Account.id FROM Contact WHERE Id = : usId];
			} catch (Exception e){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Your user is not associated with a contact. Please contact your system admin.'));
			}

			if (c!=null)
				contact = new ContactWrapper(c);
		}
		return contact;
	}

	public List<Time_Element__c> getCurrTermReportinPeriods(){
		if(reportingPeriodList == null){
			reportingPeriodList = new List<Time_Element__c>();
			reportingPeriodList = core_SoqlUtils.getTimeElementsByTerm(pic.term__c, true);
		}
		return reportingPeriodList;
	}

	public List<Time_Element__c> getCurrentRepPeriod(){
		Map<Integer,Time_Element__c> timeMap = new Map<Integer,Time_Element__c>();
		Integer i=1;
		if(currReportingPeriod == null){
			currReportingPeriod = new List<Time_Element__c>();
			for(Time_Element__c te: [SELECT Id,Date_Start_Date__c,End_Date__c
									FROM Time_Element__c
									WHERE Reporting_Period__c =: true
									AND Parent_Time_Element__c = : pic.Term__c
									order by Date_Start_Date__c]){
				if(System.Today() >= te.Date_Start_Date__c && System.Today() <= te.End_Date__c){
					currReportingPeriod.add(te);
				}
				timeMap.put(i,te);
				i++;
			}

			if(currReportingPeriod.isEmpty()){
				for(Integer k = 1; k < timeMap.values().size();k++){
					if(System.Today()>timeMap.get(k).End_Date__c && System.Today()< timeMap.get(k+1).Date_Start_Date__c ){
						currReportingPeriod.add(timeMap.get(k));
					}
				}
				if(currReportingPeriod.IsEmpty()){
					currReportingPeriod.add(timeMap.get(timeMap.values().size()));
				}
			}
		}
		return currReportingPeriod;
	}
	
	public void getCommunityService(){
		List<AggregateResult> ar = [select SUM(Service_Hours_Completed__c) hours from Community_Service__c where (Student__c =: currstudent.id or Contact__c =: contact.con.id)];
		if(ar != null && !ar.isEmpty()){
			if(ar[0].get('hours')!= null){
				studentCS = 0 + ((Decimal)ar[0].get('hours')).setScale(2);
			} else {
				studentCS = 0;
			}
		} else {
			studentCS = 0;
		}
	}

	public Map<Id, StudentPortfolioWrapper> getStudents(){
		IdToStudentWrapperMap = new Map<Id, StudentPortfolioWrapper>();
		currstudent = new Student__c();
		for(Student__c stu : [SELECT Id
									,NAME
									,School__c
									,School_Name__c
									,Grade__c
									,Email__c
									,Student_Picture__c
									,RT_Picture__c
									,School__r.Name
									,Current_Meals_Balance__c
									,School_Year__r.Date_Start_Date__c
									,School__r.School_Picture__c
									,Active__c
									,Student_Behavior_Score__c
									,Attendance_Percentage__c
									,Final_GPA_Value__c
									,GPA_To_Date__c
									,Attendance_Time_Lost__c
									,Sum_of_Time_Lost__c
									,Today_s_Points_Balance__c
									,Current_GPA__c
								FROM Student__c
								WHERE Individual__c = : contact.con.Id
								AND School__r.RecordType.Name = 'School']){

			if(stu.Active__c == true){
				currstudent = stu;
				currentGPA = (stu.Current_GPA__c!= null)?stu.Current_GPA__c.setScale(2):0;
				behaviorTimeLost = Math.round((currstudent.Sum_of_Time_Lost__c/60)*Math.POW(10,1))/Math.POW(10,1);
				attendanceTimeLost = Math.round((currstudent.Attendance_Time_Lost__c/60)*Math.POW(10,1))/Math.POW(10,1);
				studentPointsBal = currstudent.Today_s_Points_Balance__c;
			}
			if(stu.School_Year__r.Date_Start_Date__c != null){
				Integer d = stu.School_Year__r.Date_Start_Date__c.year();
				List<AttachmentsWrapper> grades = new List<AttachmentsWrapper>();
				IdToStudentWrapperMap.put(stu.Id, new StudentPortfolioWrapper(d, grades));
			}
		}
		return IdToStudentWrapperMap;
	}
	
	public void loadLanguageSettings(){
		translationOptions = new List<String>();
		boolean loadedEnglish = false;
		for(StaticResource sr: [select Name, Description, Body from StaticResource where Name LIKE 'PortalTranslation_%' order By Description]){
			if(sr.Description != 'English'){
				translationOptions.add(sr.Description);
			} else if((!loadedEnglish || !sr.Name.contains('SchoolForce')) && sr.Name.contains('English')){
				loadTranslation(sr);
				loadedEnglish = true;
			}
		}
		translationOptions.sort();
		translationOptions = new List<String>(new Set<String>(translationOptions));

	}

	public AccountWrapper getAccount(){
		if(acc == null){
			acc = new AccountWrapper([SELECT NAME, id
											,School_Picture__c
											,Attendance_Goal__c
											,Behavior_Goal__c
											,Website
									FROM Account
									WHERE Id = :currstudent.School__c]);
		}
		if(acc.acc.Website != null){
			schoolWebsite = (acc.acc.Website.contains('http://'))?acc.acc.Website:('http://'+acc.acc.Website);
		}
		pic = new Setup__c();
		pic =  [Select School_Logo_for_Portal__c,Year__c,Term__c,Passing_Grade_Threshold__c
						,Show_Attendance_in_Portal__c, Show_Meals_in_Portal__c
						,Show_Gradebook_in_Portal__c,Show_Calendar_in_Portal__c
						,Show_Behavior_in_Portal__c,Show_Awards_in_Portal__c
						,Show_Alerts_in_Portal__c ,Standard_Grade_Mastery_Threshold__c
						,Strand_Grade_Mastery_Percentage__c, Show_Homework_in_Portal__c
						,Show_Standards_in_Portal__c, Show_Points_Balance_in_Portal__c
						,Standards_ONLY_Gradebook__c
						,Standards_Based_Grading__c
						,Show_Community_Service_In_Portal__c
						,Display_GPA_on_Report_Cards__c
				from Setup__c where School__c = : currstudent.School__c AND active__c = true limit 1];
		return acc;
	}


	public List<Section__c> getSectionsForStudent(){
		Decimal totalGoal = 0.0;

		if(sectionList == null){
			sectionList = new List<Section__c>();

			Set<Id> ssecIds = new Set<Id>();
			studentSections = [Select Section__c,Goal__c
								From Student_Section__c
								WHERE Student__c = : currstudent.Id
								AND Active__c=true
								AND Section__r.Show_In_Portal__c = true
								and Section__r.RecordType.DeveloperName = 'Published'];

			for(Student_Section__c ssec : studentSections){
				ssecIds.add(ssec.Section__c);
			}

			for(Section__c sec : [SELECT Name, Id,Course__r.Name,Course__r.Course_Notes__c
									FROM Section__c
									WHERE Id in : ssecIds AND Show_In_Portal__c = true
									AND is_Section__c = true
									AND Active__c = true
									AND RecordType.DeveloperName='Published'
									order by Course__r.Name desc]){
				sectionList.add(sec);
			}
		}
		return sectionList;
	}

	public void getHomework(){
		Set<Id> sectionIds = new Set<Id>();
		homeworkInfo = new List<homeworkWrapper>();
		
		if(!pic.Show_Homework_in_Portal__c)
			return;
		for(Section__c s:sectionList){
			sectionIds.add(s.id);
		}

		Map<ID, Integer> ssLate = new Map<Id, Integer>();
		Map<Id, Integer> ssMissing = new Map<Id, Integer>();
		Map<Id, Integer> ssTotal = new Map<Id, Integer>();
		Map<Id, String> ssCourse = new Map<Id, String>();

		for(HW_Tracker__c h: [select id
									,Student_Section__c
									,Picklist_Value__r.Category__c
									,Student_Section__r.Section__r.Course__r.Name
								from HW_Tracker__c
								where Student_Section__r.Active__c = true
								AND Student_Section__r.Section__r.Active__c = true
								And Student_Section__r.Section__r.Has_Homework__c = true
								AND Student__c =: currstudent.id
								order by Student_Section__r.Section__r.Course__r.Name]){

			if(!ssCourse.containsKey(h.Student_Section__c)){
				ssCourse.put(h.Student_Section__c, h.Student_Section__r.Section__r.Course__r.Name);
			}
			
			if(h.Picklist_Value__r.Category__c == 'Late'){
				if(!ssLate.containsKey(h.Student_Section__c)){
					ssLate.put(h.Student_Section__c, 1);
				} else {
					ssLate.put(h.Student_Section__c, ssLate.get(h.Student_Section__c)+1);
				}
			} else if(h.Picklist_Value__r.Category__c == 'Incomplete'){
				if(!ssMissing.containsKey(h.Student_Section__c)){
					ssMissing.put(h.Student_Section__c, 1);
				} else {
					ssMissing.put(h.Student_Section__c, ssMissing.get(h.Student_Section__c)+1);
				}
			}
			
			if(h.Picklist_Value__r.Category__c != 'Exempt'){
				if(ssTotal.containsKey(h.Student_Section__c)){
					ssTotal.put(h.Student_Section__c, ssTotal.get(h.Student_Section__c)+1);
				} else {
					ssTotal.put(h.Student_Section__c, 1);
				}
			}
		}

		for(Id id: ssCourse.keySet()){
			homeworkInfo.add(new HomeworkWrapper(ssCourse.get(id),ssMissing.get(id),ssLate.get(id),ssTotal.get(id)));
		}
	}

	public List<SectionGradeWrapper> getsectionGrades(){
		sectionGradeWrapperList = new List<SectionGradeWrapper>();
		Map<String, Section_Grade__c> keyToRpSecGradesMap = new Map<String, Section_Grade__c>();
		Set<String> cIds = new  Set<String>();
		List<Course__c> courseList = new List<Course__c>();
		Map<Id, String> courseIdToFinalGradeMap = new Map<Id, String>();
		Map<Id,Section__c> courseIdToSectionMap = new Map<Id,Section__c>();
		List<String> secGradesList;
		String[] allow;
		String currRPGrade = '';
		OverrideSettings__c os = OverrideSettings__c.getInstance(UserInfo.getUserId());
		if(os.Allowable_Grades__c != null)
			allow = os.Allowable_Grades__c.split(',');

		Set<String> allowSet = new Set<String>();
		if(allow != null && allow.size() > 0){
			for(String s: allow){
				allowSet.add(s.trim());
			}
		}

		//build a map of final grades for the student
		for(Final_Grade__c fg :[SELECT  Final_Grade_Value__c, Course__c, Display_Final_Grade_Formula__c,Course__r.Display_Numerical_Values_On_Report_Card__c
								FROM Final_Grade__c
								WHERE Student__c =: currstudent.Id and Final__c = true and Show_In_Portal__c=true]){
			String grade;
			if(fg.Course__r.Display_Numerical_Values_On_Report_Card__c){
				grade = (fg.Final_Grade_Value__c!=null)?String.valueOf(fg.Final_Grade_Value__c.round()):'';
			} else {
				grade = fg.Display_Final_Grade_Formula__c;
			}
			courseIdToFinalGradeMap.put(fg.Course__c,grade);
		}

		sectionGradeMap = new Map<String, String>();
		for(Section_Grade__c sg : [SELECT Id,Grade__c,Letter_Grade__c,Time__r.Name__c,Student_Section__c,Student_Section__r.Section__r.Course__r.Name
										,Student_Section__r.Section__r.Course__c,Student_Section__r.Section__r.Name,Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c
										,Student_Section__r.Section__r.Homework_based__c,Standard_Section_Grade_v2__c,Display_Grade_Formula__c
									FROM Section_Grade__c
									WHERE Student_Section__c in : studentSections
									AND Student_Section__r.Active__c = true
									AND Student_Section__r.Section__r.Active__c = true
									AND Time__r.Date_Start_Date__c <= : currReportingPeriod[0].Date_Start_Date__c
									AND Time__r.Reporting_Period__c = true
									AND Student_Section__r.Section__r.Daily_Attendance__c = false
									AND Student_Section__r.Section__r.Course__r.Exclude_on_RC_Transcripts__c = false
									order by Student_Section__r.Section__r.Course__r.Name desc]){

			keyToRpSecGradesMap.put(sg.Student_Section__r.Section__r.Course__c+'-'+sg.Time__c,sg);
			courseIdToSectionMap.put(sg.Student_Section__r.Section__r.Course__c,sg.Student_Section__r.Section__r);
			if(!cIds.contains(sg.Student_Section__r.Section__r.Course__c)){
				courseList.add(sg.Student_Section__r.Section__r.Course__r);
				cIds.add(sg.Student_Section__r.Section__r.Course__c);
			}
		}

		for(Course__c c: courseList){
			secGradesList = new List<String>();
			for(Time_Element__c te : reportingPeriodList){
				if(keyToRpSecGradesMap.containsKey(c.Id+'-'+te.Id)){
					Section_Grade__c sg = keyToRpSecGradesMap.get(c.Id+'-'+te.Id);
					String grade;
					if(sg.Student_Section__r.Section__r.Course__r.Display_Numerical_Values_On_Report_Card__c){
						grade = (sg.Grade__c!= null)?String.valueOf(sg.Grade__c.round()):'';
					} else {
						grade = sg.Display_Grade_Formula__c;
					}
					secGradesList.add((grade!=null)?grade:'');
					if(te.id == currReportingPeriod[0].id){
						currRPGrade = grade;
					}
				} else {
					secGradesList.add('');
				}
			}
			sectionGradeWrapperList.add(new SectionGradeWrapper(c.Name,secGradesList,courseIdToFinalGradeMap.get(c.Id),currRPGrade));
			currRPGrade = '';
		}
		return sectionGradeWrapperList;
	}

	public void getStaffSections(){
		sectionToStaffSectionsMap = new Map<Id,List<String>>();
		sectionToStaffStringMap = new Map<String,String>();
		List<String> individualStaffSectionsList;
		for(Staff_Section__c ss : [SELECT Id
										,Section__c
										,Staff__r.First_Name_Staff__c
										,Staff__r.Staff_Last_Name__c
									FROM Staff_Section__c
									WHERE Section__c in : sectionList]){

			if(sectionToStaffSectionsMap.containsKey(ss.Section__c)){
				sectionToStaffSectionsMap.get(ss.Section__c).add(ss.Staff__r.First_Name_Staff__c+ ' '+ss.Staff__r.Staff_Last_Name__c);
			}
			else{
				individualStaffSectionsList = new List<String>();
				individualStaffSectionsList.add(ss.Staff__r.First_Name_Staff__c+ ' '+ss.Staff__r.Staff_Last_Name__c);
				sectionToStaffSectionsMap.put(ss.Section__c,individualStaffSectionsList);
			}
		}

		for(Section__c sec : sectionList ){
			String staff = '';
			if(sectionToStaffSectionsMap.containskey(sec.Id) && sectionToStaffSectionsMap.get(sec.Id)!=null){
				for(Integer i = 0; i < sectionToStaffSectionsMap.get(sec.Id).size(); i++ ){
					if(i == 0)
						staff = sectionToStaffSectionsMap.get(sec.Id)[i];
					else
						staff += ', ' + sectionToStaffSectionsMap.get(sec.Id)[i] ;
				}
			}
			sectionToStaffStringMap.put(sec.Id, staff);
		}
	}

	public List<Awards__c> getAwards(){
		if(awardsList == null){
			Integer i = 0;
			awardsList = new List<Awards__c>();
			awardsListFull = new List<Awards__c>();
			for(Awards__c aw : [SELECT Award_File__c
									,Description__c
								FROM Awards__c
								WHERE Student__c = : currstudent.Id
								order by LastmodifiedDate desc]){
				if(i< 5){
					awardsList.add(aw);
					i++;
				}
				awardsListFull.add(aw);
			}
		}
		return awardsList;
	}

	public List<Integer> getemptyAwardsList(){
		if(emptyAwardsList == null){
			emptyAwardsList = new List<Integer>();
		}

		if(awardsList.size()< 5){
			for(Integer i=0;i< (5 - awardsList.size());i++){
				emptyAwardsList.add(i);
			}
			showemptyawards = true;
		}
		return emptyAwardsList;
	}

	public List<Alert__c> getAlerts(){
		if(alertsList == null){
			alertsList = new List<Alert__c>();
			smallAlertsList = new List<Alert__c>();
			for(Alert__c al : [SELECT Message__c
										,Createdby.Name
										,School__r.Name
										,Student__r.Name
										,Section__r.Name
								FROM Alert__c
								WHERE ((School__c = : acc.acc.Id) OR
										(Student__c = : currstudent.Id) OR
										(Section__c in : sectionList)) AND
										(Expiration_Date__c >= Today) order by Createddate desc]){
				alertsList.add(al);
				if(smallAlertsList.size() < 5){
					smallAlertsList.add(al);
				}
			}
		}
		return alertsList;
	}

	public List <Grade__c> getGrades(Set<Id> studIds){
		assignmentToGrademap = new Map<String,String>();
		Map<String,List<String>> assignmentToGradeListmap = new Map<String,List<String>>();
		List<Grade__c> gList = new List<Grade__c>();
		for(Grade__c g:[SELECT Locked_for_Final__c
								,Publish_Comment__c
								,Name
								,Comment__c
								,Entered_Grade__c
								,Exclude_From_Section_Grade__c
								,Assignment__r.Name_in_Gradebook__c
								,Assignment__r.Weighting_Value__c
								,Assignment__r.NAME
								,Assignment__r.Due_Date__c
								,Assignment__r.Due_Date_for_Gradebook__c
								,Assignment__r.Section__r.Staff__r.First_Name_Staff__c
								,Assignment__r.Section__r.Staff__r.Staff_Last_Name__c
								,Assignment__r.Section__r.Course__r.Name
								,Assignment__r.Section__r.Section_Number__c
								,Assignment__r.Description__c
								,Assignment__r.Section__r.Name
								,Assignment__r.Media_Source__c
								,Assignment__r.Media_Name__c
								,Assignment__r.Possible_Points__c
								,Assignment__r.Time__r.Name__c
								,Assignment__r.Time__c
								,Assignment__r.Assignment_Library__r.Picklist_value__r.Name
								,Student_Section__r.Student__c
								,student_section__c
								,Time__r.Parent_Time_Element__r.Parent_Time_Element__c
								,Student_Section__r.Section__c
								,Student_Section__r.Section__r.Active__c
								,Student__r.Email__c
								,Standard__r.Name
							FROM Grade__c
							WHERE Student_Section__r.Student__c in : StudIds
							AND Student_Section__r.Active__c = true
							AND Standard_Gradebook_Grade__c = : null
							AND Assignment__r.Show_in_portal__c = true
							order by Assignment__r.Due_Date__c desc]){

			if(g.Time__c == currReportingPeriod[0].Id){
				if(assignmentToGradeListmap.containskey(g.Assignment__c)){
					assignmentToGradeListmap.get(g.Assignment__c).add(g.Id);
				}else{
					assignmentToGradeListmap.put(g.Assignment__c, new List<string>{g.Id});
				}
			}
			gList.add(g);
		}

		for(String assign : assignmentToGradeListmap.keyset() ){
			String gradeString = '';
			if(assignmentToGradeListmap.containskey(assign) && assignmentToGradeListmap.get(assign)!=null){
				for(Integer i = 0; i < assignmentToGradeListmap.get(assign).size(); i++ ){
					if(i == 0)
						gradeString =  assignmentToGradeListmap.get(assign)[i];
					else
						gradeString += ',' + assignmentToGradeListmap.get(assign)[i] ;
				}
			}
			assignmentToGrademap.put(assign, gradeString);
		}
		return gList;
	}

	public Map<Id,List<Attachment>> getGradesAttachments(){
		Grade__c grade = new Grade__c();
		if(gradeToAttachmentsMap ==  null){
			gradeToAttachmentsMap = new Map<Id,List<Attachment>>();
			for(Attachment att: [SELECT  Id,Name,ParentId
								FROM Attachment
								WHERE ParentId in : retrievedGrades]){
				if(gradeToAttachmentsMap.containskey(att.ParentId))
					gradeToAttachmentsMap.get(att.ParentId).add(att);
				else
					gradeToAttachmentsMap.put(att.ParentId,new List<Attachment>{att});
			}
		}
		return gradeToAttachmentsMap;
	}

	public List<GradeWrapper> getAssignments(){
		currAssignsPerSectionList = new List<AssignmentWrapper>();
		pastAssignsPerSectionList = new List<AssignmentWrapper>();
		currAssignsPerSection	 = new List<AssignmentWrapper>();
		overdueAssignmentList	 = new List<AssignmentWrapper>();
		currentAssignmentList	 = new List<AssignmentWrapper>();
		progressGradeList = new List<GradeWrapper>();
		sectionToListOfGrades = new  Map<String,List<Grade__c>>();
		sectionIdToListOfPastAssignmentsMap = new Map<String,List<AssignmentWrapper>>();
		sectionIdToListOfCurrAssignmentsMap = new Map<String,List<AssignmentWrapper>>();
		assignmentToAttachmentMap = new Map<Id,Attachment>();
		List<AssignmentWrapper> individualAssignments;
		retrievedGrades = new List<Grade__c>();
		Set<String> assignmentIds = new Set<String>();
		Set<Id> StudentIds = IdToStudentWrapperMap.keyset();

		portFolioAssignsList = new List<StudentPortfolioWrapper>();
		retrievedGrades = getGrades(StudentIds);

		getGradesAttachments();
		sectionIdToListOfCurrAssignmentsMap.put('All',new List<AssignmentWrapper>());
		sectionIdToListOfPastAssignmentsMap.put('All',new  List<AssignmentWrapper>());
		Set<Id> assignLibraries = new Set<Id>();
		for(Assignment__c aLib : [SELECT Assignment_Library__c
									FROM Assignment__c
									WHERE Section__c in:sectionList]){
			assignLibraries.add(aLib.Assignment_Library__c);
		}
		List<Attachment> assigList = [SELECT  Id,Name,ParentId
									FROM Attachment
									WHERE ParentId in : assignLibraries];
		if(assigList.size() > 0){
			for(Attachment att : assigList){
				assignmentToAttachmentMap.put(att.ParentId, att);
			}
		}
		for(Grade__c g : retrievedGrades){
			if(g.Time__c == currReportingPeriod[0].Id){
				progressGradeList.add(new GradeWrapper(g));
				if(sectionToListOfGrades.containskey(g.Assignment__r.Section__c)){
					sectionToListOfGrades.get(g.Assignment__r.Section__c).add(g);
				}
				else{
					sectionToListOfGrades.put(g.Assignment__r.Section__c, new List<Grade__c>{g});
				}
			}
			if(!(assignmentIds.contains(g.Assignment__c)) && (g.Time__r.Parent_Time_Element__r.Parent_Time_Element__c == currstudent.School_Year__c) ){
				assignmentIds.add(g.Assignment__c);
				if((g.Entered_Grade__c != null)){
					pastAssignsPerSectionList.add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
					if(sectionIdToListOfPastAssignmentsMap.containskey(g.Assignment__r.Section__c)){
						sectionIdToListOfPastAssignmentsMap.get(g.Assignment__r.Section__c).add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
					}else{
						individualAssignments = new List<AssignmentWrapper>();
						individualAssignments.add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
						sectionIdToListOfPastAssignmentsMap.put(g.Assignment__r.Section__c,individualAssignments);
					}
					sectionIdToListOfPastAssignmentsMap.get('All').add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
				}else{
					currAssignsPerSection.add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
					if(sectionIdToListOfCurrAssignmentsMap.containskey(g.Assignment__r.Section__c)){
						sectionIdToListOfCurrAssignmentsMap.get(g.Assignment__r.Section__c).add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
					}else{
						individualAssignments = new List<AssignmentWrapper>();
						individualAssignments.add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
						sectionIdToListOfCurrAssignmentsMap.put(g.Assignment__r.Section__c,individualAssignments);
					}
					sectionIdToListOfCurrAssignmentsMap.get('All').add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
				}

				if((g.Assignment__r.Due_Date__c >= System.today()) && (g.Assignment__r.Due_Date__c <= System.today()+ 15) && (g.Entered_Grade__c == null) && g.Student_Section__r.Section__r.Active__c)
					currentAssignmentList.add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
				if((g.Assignment__r.Due_Date__c < System.today()) && (g.Entered_Grade__c == null)&&g.Student_Section__r.Section__r.Active__c)
					overdueAssignmentList.add(new AssignmentWrapper(assignmentToGrademap.get(g.Assignment__c),assignmentToAttachmentMap.get(g.Assignment__r.Assignment_Library__c),sectionToStaffStringMap.get(g.Assignment__r.Section__c),g.Assignment__r));
			}
			if(gradeToAttachmentsMap.containskey(g.Id)){
				IdToStudentWrapperMap.get(g.Student_Section__r.Student__c).gradesList.add(new AttachmentsWrapper(g,gradeToAttachmentsMap.get(g.Id),sectionToStaffStringMap.get(g.Assignment__r.Section__c)));
			}
		}
		portFolioAssignsList = IdToStudentWrapperMap.values();
		portFolioAssignsList.sort(); //Commenting out for 5.6.5
		//set ids to allow collapse/expand function in page
		for(integer i=0; i<portFolioAssignsList.size(); i++) portFolioAssignsList[i].id=''+i;
		return null;
	}

	public List<CourseWrapper> getCourses(){
		courses = new List<CourseWrapper>();
		Set<Id> individualSections;
		courseToSectionsMap = new Map<String,String>();
		courseNames = new List<courseNameWrapper>();
		myStandardCourses = new List<CourseWrapper>();
		courseNameWrapper all = new courseNameWrapper();
		courseToStandVideosMap = new Map<String, List<External_Resources__c>>();
		courseToStandUrlsMap = new Map<String, List<External_Resources__c>>();
		Integer i = 0;
		all.Name='All';
		courseNames.add(all);

		for(Section__c sec : sectionList){
			courseNameWrapper temp = new courseNameWrapper();
			temp.Name=sec.Course__r.Name;
			temp.Description = sec.Course__r.Course_Notes__c;
			courseNames.add(temp);
			courseToSectionsMap.put(sec.Course__r.Name,sec.Id);
		}

		for(courseNameWrapper c : courseNames){
			if(c.Name == 'All')
				courses.add(new CourseWrapper(c.Name, c.Description, true));
			else{
				courses.add(new CourseWrapper(c.Name, c.Description, false));
				if(i==0){
					myStandardCourses.add(new CourseWrapper(c.Name, c.Description, true));
				}else{
					myStandardCourses.add(new CourseWrapper(c.Name, c.Description, false));
				}
				courseToStandVideosMap.put(c.name,new List<External_Resources__c>());
				courseToStandUrlsMap.put(c.name,new List<External_Resources__c>());
				i++;
			}
		}
		return courses;
	}

	public List<External_Resources__c> getMediaLinks(){
		List<External_Resources__c> individualMediaList;
		sectionToMediaMap = new Map<Id, List<External_Resources__c>>();
		if(mediaList == null){
			mediaList = new List<External_Resources__c>();
			for(External_Resources__c med:[SELECT Resource__c
													,Name
													,Section__c
											FROM External_Resources__c
											WHERE Section__c in : sectionList
											AND RecordTypeId = : core_SoqlUtils.getRecordTypesBySobject('External_Resources__c').get('Section')
											order by LastModifiedDate desc]){
				mediaList.add(med);
				if(sectionToMediaMap.containsKey(med.Section__c)){
					sectionToMediaMap.get(med.Section__c).add(med);
				}else{
					individualMediaList  = new List<External_Resources__c>();
					individualMediaList.add(med);
					sectionToMediaMap.put(med.Section__c, individualMediaList);
				}
			}
		}
		return mediaList;
	}

	public List<External_Resources__c> getStandsResourceList(){
		standToVideoLinksMap = new Map<Id, List<External_Resources__c>>();
		standToUrlsMap = new Map<Id, List<External_Resources__c>>();
		standsbulletinList = new List<External_Resources__c>();
		standsResList = new List<External_Resources__c>();

		for(External_Resources__c sr : [SELECT Resource__c
												,Name
												,Standard__c
												,Type__c
										FROM External_Resources__c
										WHERE Standard__c in : standsNotMastered
										AND RecordTypeId = : core_SoqlUtils.getRecordTypesBySobject('External_Resources__c').get('Standard')
										order by LastModifiedDate desc]){

			if(sr.Type__c == 'Video'){
				if(standToVideoLinksMap.containsKey(sr.Standard__c)){
					standToVideoLinksMap.get(sr.Standard__c).add(sr);
				}else{
					standToVideoLinksMap.put(sr.Standard__c, new List<External_Resources__c> {sr});
				}
			}else if(sr.Type__c == 'Url'){
				if(standToUrlsMap.containsKey(sr.Standard__c)){
					standToUrlsMap.get(sr.Standard__c).add(sr);
				}else{
					standToUrlsMap.put(sr.Standard__c, new List<External_Resources__c> {sr});
				}
			}
		}

		for(CourseWrapper c : myStandardCourses){
			if(courseToStandMap.containskey(c.courseName) && courseToStandMap.get(c.courseName)!= null){
				for(String standrd : courseToStandMap.get(c.courseName)){
					if(standToVideoLinksMap.containskey(standrd) && standToVideoLinksMap.get(standrd) != null){
						courseToStandVideosMap.get(c.courseName).addAll(standToVideoLinksMap.get(standrd));
					}
					if(standToUrlsMap.containskey(standrd) && standToUrlsMap.get(standrd) != null){
						courseToStandUrlsMap.get(c.courseName).addAll(standToUrlsMap.get(standrd));
					}
				}
			}
		}

		if(myStandardCourses!=null && myStandardCourses.size() > 0){
			if(courseToStandVideosMap.get(myStandardCourses[0].courseName)!=null){
				standsResList = courseToStandVideosMap.get(myStandardCourses[0].courseName);
			}
			if(courseToStandUrlsMap.get(myStandardCourses[0].courseName)!=null){
				standsbulletinList = courseToStandUrlsMap.get(myStandardCourses[0].courseName);
			}
		}
		return standsResList;
	}

	public String getCalandarUrl(){
		String calandarIds = '';
		progsList = new List<Calendars__c>();
		progsList = [SELECT Calendar_Id__c,Color__c, Name
						FROM Calendars__c
						WHERE Organization__c = : acc.acc.Id
						order by Name];
		if(currStudent.Email__c!=null)
			progsList.add(new Calendars__c(Name = currStudent.Name, Calendar_Id__c=currStudent.Email__c));

		for(Integer i = 0; i <progsList.size(); i++  ){
			String colorCode = '';
			if(progsList[i].Color__c == null)
				colorCode = '';
			else
				colorCode = progsList[i].Color__c;

			if(progsList[i].Calendar_Id__c!=null){
				if(i == 0)
					calandarIds = EncodingUtil.urlEncode(progsList[i].Calendar_Id__c,'UTF-8')+'&color='+ EncodingUtil.urlEncode(colorCode,'UTF-8');
				else
					calandarIds = calandarIds + '&src='+ EncodingUtil.urlEncode(progsList[i].Calendar_Id__c,'UTF-8')+'&color='+EncodingUtil.urlEncode(colorCode,'UTF-8');
			}
		}
		calandarUrl = 'https://www.google.com/calendar/embed?src='+calandarIds+'&ctz='+[SELECT TimeZoneSidKey FROM User WHERE Id = : usr.Id].TimeZoneSidKey;
		return calandarUrl;
	}

	public void getStudentScoreCard(){
		sectionalAtt = new List<SectionalAttendanceWrapper>();
		sectionNameToAttCount = new Map<String,SectionalAttendanceWrapper>();
		dailyExcsAbsences = 0;
		dailyUnExcsAbsences = 0;
		dailyTardies = 0;
		dailyDepartures = 0;
		for(Attendance__c att : [SELECT Id,Session__r.Section__r.Name,Session__r.Section__c,Attendance_Status_Read_Only__c,
									Picklist_Value__r.Is_Early_Departure__c,Picklist_Value__r.Is_Tardy__c,Picklist_Value__r.Is_Unexcused__c,
									Picklist_Value__r.Category__c
									From Attendance__c  WHERE Student__c  =:currstudent.Id
									AND daily__c = true AND Picklist_Value__r.Category__c <> 'Present'
									AND Session__r.Time__r.Date_Start_Date__c <=:currReportingPeriod[0].Date_Start_Date__c]){

			if(att.Picklist_Value__r.Category__c == 'Absent' && !att.Picklist_Value__r.Is_Unexcused__c){
				dailyExcsAbsences++;
			}
			if(att.Picklist_Value__r.Category__c == 'Absent' && att.Picklist_Value__r.Is_Unexcused__c){
				dailyUnExcsAbsences++;
			}
			if(att.Picklist_Value__r.Is_Tardy__c){
				dailyTardies++;
			}
			if(att.Picklist_Value__r.Is_Early_Departure__c){
				dailyDepartures++;
			}
		}

		for(Attendance__c att : [SELECT Id,Session__r.Section__r.Name,Session__r.Section__c,Attendance_Status_Read_Only__c
									 From Attendance__c a WHERE a.Student__c  =:currstudent.Id
									 AND daily__c = false AND Attendance_Status_Read_Only__c <> 'Present'
									 AND Session__r.Time__r.Date_Start_Date__c <=:currReportingPeriod[0].Date_Start_Date__c]){

			if(sectionNameToAttCount.containskey(att.Session__r.Section__c)){
				if(att.Attendance_Status_Read_Only__c == 'Unexcused Absence'){
					Integer i = sectionNameToAttCount.get(att.Session__r.Section__c).unexcusedAbsences;
					i++;
					sectionNameToAttCount.put(att.Session__r.Section__c,new SectionalAttendanceWrapper(sectionNameToAttCount.get(att.Session__r.Section__c).sectionName,sectionNameToAttCount.get(att.Session__r.Section__c).excusedAbsences,i,sectionNameToAttCount.get(att.Session__r.Section__c).unexcusedTardys,sectionNameToAttCount.get(att.Session__r.Section__c).tardys));
				}else{
					if(att.Attendance_Status_Read_Only__c == 'Excused Absence'){
						Integer i = sectionNameToAttCount.get(att.Session__r.Section__c).excusedAbsences;
						i++;
						sectionNameToAttCount.put(att.Session__r.Section__c,new SectionalAttendanceWrapper(sectionNameToAttCount.get(att.Session__r.Section__c).sectionName,i,sectionNameToAttCount.get(att.Session__r.Section__c).unexcusedAbsences,sectionNameToAttCount.get(att.Session__r.Section__c).unexcusedTardys,sectionNameToAttCount.get(att.Session__r.Section__c).tardys));
					}else{
						if(att.Attendance_Status_Read_Only__c == 'Unexcused Tardy'){
							Integer i = sectionNameToAttCount.get(att.Session__r.Section__c).unexcusedTardys;
							i++;
							sectionNameToAttCount.put(att.Session__r.Section__c,new SectionalAttendanceWrapper(sectionNameToAttCount.get(att.Session__r.Section__c).sectionName,sectionNameToAttCount.get(att.Session__r.Section__c).excusedAbsences,sectionNameToAttCount.get(att.Session__r.Section__c).unexcusedAbsences,i,sectionNameToAttCount.get(att.Session__r.Section__c).tardys));
						}else{
							if(att.Attendance_Status_Read_Only__c == 'Tardy'){
								Integer i = sectionNameToAttCount.get(att.Session__r.Section__c).tardys;
								i++;
								sectionNameToAttCount.put(att.Session__r.Section__c,new SectionalAttendanceWrapper(sectionNameToAttCount.get(att.Session__r.Section__c).sectionName,sectionNameToAttCount.get(att.Session__r.Section__c).excusedAbsences,sectionNameToAttCount.get(att.Session__r.Section__c).unexcusedAbsences,sectionNameToAttCount.get(att.Session__r.Section__c).unexcusedTardys,i));
							}
						}
					}
				}
			}else{
				if(att.Attendance_Status_Read_Only__c == 'Unexcused Absence'){
					sectionNameToAttCount.put(att.Session__r.Section__c,new SectionalAttendanceWrapper(att.Session__r.Section__r.Name,0,1,0,0));
				}else{
					if(att.Attendance_Status_Read_Only__c == 'Excused Absence'){
						sectionNameToAttCount.put(att.Session__r.Section__c,new SectionalAttendanceWrapper(att.Session__r.Section__r.Name,1,0,0,0));
					}else{
						if(att.Attendance_Status_Read_Only__c == 'Unexcused Tardy'){
							sectionNameToAttCount.put(att.Session__r.Section__c,new SectionalAttendanceWrapper(att.Session__r.Section__r.Name,0,0,1,0));
						}else{
							if(att.Attendance_Status_Read_Only__c == 'Tardy'){
								sectionNameToAttCount.put(att.Session__r.Section__c,new SectionalAttendanceWrapper(att.Session__r.Section__r.Name,0,0,0,1));
							}
						}
					}
				}
			}

			if(sectionNameToAttCount.keyset().size() > 0){
				sectionalAtt = sectionNameToAttCount.values();
			}
		}
	}

	public void getStudentBehaviorScore(){
		Set<Id> behIncdIds = new Set<Id>();
		behIncdCountYTD = [Select COUNT()
							From Student_Behavior__c s
							WHERE s.Student__c  =: currstudent.Id
							AND s.Behavior_Incident__r.Incident_Status__c <> 'Draft'];

		if(allBehincidents == null){
			allBehincidents = new List<Student_Behavior__c>();
			latestBehincidents = new List<Student_Behavior__c>();
			for(Student_Behavior__c sb : [SELECT Behavior_Incident__r.Incident_Title__c
											 	,Behavior_Incident__r.Incident_Points__c
											 	,Behavior_Incident__r.Incident_Date__c
											FROM Student_Behavior__c
											WHERE Student__c =: currstudent.Id
											AND Behavior_Incident__r.Show_In_Portal__c = true
											order by Behavior_Incident__r.Incident_Date__c desc]){
				if(!behIncdIds.contains(sb.Behavior_Incident__c)){
					behIncdIds.add(sb.Behavior_Incident__c);
					allBehincidents.add(sb);
					if(latestBehincidents.size() < 5){
						latestBehincidents.add(sb);
					}
				}
			}
		}
	}

	public List<ReportCardsWrapper> getStudentReportCards(){
		Set<Id> attachments = new Set<Id>();
		reportCardsList = new List<ReportCardsWrapper>();
		if(attachmentToStudentRP == null){
			attachmentToStudentRP = new Map<String,Student_Reporting_Period__c>();
			for(Student_Reporting_Period__c sr : [SELECT Time__c,Show_In_Portal__c,Student__c,Reporting_Period_Name__c
													  	,Student__r.School_Year__r.Date_Start_Date__c
													  	,Attachment_ID__c, Time__r.Name__c
													From Student_Reporting_Period__c
													WHERE Student__c = :currstudent.Id
													AND Show_In_Portal__c = true]){
				attachmentToStudentRP.put(sr.Attachment_ID__c,sr);
				attachments.add(sr.Attachment_ID__c);
			}
		}
		for(Attachment att: [SELECT CreatedDate,Id
							FROM Attachment
							WHERE Id in: attachments]){
			if(attachmentToStudentRP.containskey(att.Id)){
				reportCardsList.add(new ReportCardsWrapper(attachmentToStudentRP.get(att.Id),att.CreatedDate.date(),attachmentToStudentRP.get(att.Id).Student__r.School_Year__r.Date_Start_Date__c.year()));
			}
		}

		return null;
	}

	public void getStudentStandardGrades(){
		//Also why is this called SECTIONToStrandWrapper if it uses Course Names?
		sectionToStrandWrapper = new Map<String,List<StrandWrapper>>();

		//a few other places depend on these being populated here
		standsNotMastered = new Set<Id>();
		courseToStandMap = new Map<String, Set<String>>();

		Map<ID, Set<ID>> courseToStandardMap = new Map<ID, Set<ID>>();
		Map<ID, String> courseIDToNameMap = new Map<ID, String>();
		for(Section_Standard__c ss: [SELECT Section__r.Course__c,Standard__r.Strand__c, Section__r.Course__r.Name
									FROM Section_Standard__c
									WHERE Section__c in: sectionList]){
			if(courseToStandardMap.containsKey(ss.Section__r.Course__c)){
				courseToStandardMap.get(ss.Section__r.Course__c).add(ss.Standard__r.Strand__c);
			} else {
				courseToStandardMap.put(ss.Section__r.Course__c, new Set<ID>{ss.Standard__r.Strand__c});
			}
			if(courseToStandMap.containskey(ss.Section__r.Course__r.Name)){
				courseToStandMap.get(ss.Section__r.Course__r.Name).add(ss.Standard__c);
			}else{
			 	courseToStandMap.put(ss.Section__r.Course__r.Name,new Set<String>{ss.Standard__c});
			}
			courseIDToNameMap.put(ss.Section__r.Course__c, ss.Section__r.Course__r.Name);
		}

		//Map is Strand ID to Standard ID, to RP ID to Standard Grade
		Map<ID, Map<ID, Map<ID, Standard_Grade__c>>> strandToStandardGradeMap = new Map<ID, Map<ID, Map<ID, Standard_Grade__c>>>();
		for(Standard_Grade__c sg:[select Standard__c, Standard__r.Long_Text__c, Standard_Grade__c, Standard__r.Strand__r.Long_Text__c,
									Reporting_Period__c, Standard__r.Strand__c
								from Standard_Grade__c
								where Student__c = : currStudent.ID
								order by Standard__c, Reporting_Period__r.Date_Start_Date__c desc]){
			if(strandToStandardGradeMap.containsKey(sg.Standard__r.Strand__c)){
				if(strandToStandardGradeMap.get(sg.Standard__r.Strand__c).containsKey(sg.Standard__c)){
					strandToStandardGradeMap.get(sg.Standard__r.Strand__c).get(sg.Standard__c).put(sg.Reporting_Period__c, sg);
				} else {
					strandToStandardGradeMap.get(sg.Standard__r.Strand__c).put(sg.Standard__c, new Map<ID, Standard_Grade__c>{sg.Reporting_Period__c => sg});
				}
			} else {
				strandToStandardGradeMap.put(sg.Standard__r.Strand__c, new Map<ID, Map<ID, Standard_Grade__c>>{sg.Standard__c => new Map<ID, Standard_Grade__c>{sg.Reporting_Period__c => sg}});
			}
		}
		for(ID courseID: courseToStandardMap.keyset()){
				List<StrandWrapper> strandWrappers = new List<StrandWrapper>();
			for(ID strandID:courseToStandardMap.get(courseID)){
				List<StandardWrapper> standardWrappers = new List<StandardWrapper>();
				String longText='';
				Integer masteredStandardsCount = 0;
				if(strandToStandardGradeMap.containsKey(strandID)){
					for(ID standardID: strandToStandardGradeMap.get(strandID).keySet()){
						List<Standard_Grade__c> standardGrades = new List<Standard_Grade__c>();
						Boolean masteredLastRP = false;
						for(Time_Element__c te:reportingPeriodList){
							if(strandToStandardGradeMap.get(strandID).get(standardID).containsKey(te.ID)){
								Standard_Grade__c sg = strandToStandardGradeMap.get(strandID).get(standardID).get(te.ID);
								if(longText == ''){
									longText = sg.Standard__r.Strand__r.Long_Text__c;
								}

								if(sg.Standard_Grade__c != null && sg.Standard_Grade__c < pic.Standard_Grade_Mastery_Threshold__c){
									standsNotMastered.add(sg.Standard__c);
									masteredLastRP = false;
								} else {
									masteredLastRP = true;
								}

								standardGrades.add(sg);
							} else {
								standardGrades.add(new Standard_Grade__c());
							}
						}
						if(masteredLastRP)
							masteredStandardsCount++;
						standardWrappers.add(new StandardWrapper(standardGrades));
					}
					strandWrappers.add(new StrandWrapper(longText,standardWrappers,masteredStandardsCount));
				}
			}
			sectionToStrandWrapper.put(courseIDToNameMap.get(courseID), strandWrappers);
		}

		if(myStandardCourses.size()>0)
			strandsByCourseList = sectionToStrandWrapper.get(myStandardCourses[0].courseName);
	}
	
	public void loadTranslation(StaticResource sr){
		selectedLanguage = sr.Description;
		translationStrings = new Map<String, String>();
		String[] fileLines = StringUtils.splitAndTrim(sr.Body.toString(),'\n');
		sr = null;
		for(String s:fileLines){
			if(s.startsWith('//')){
				continue;
			} else if(s.length() == 0){
				continue;
			} else {
				String[] entry = s.split(':',2);
				if(entry.size() != 2){
					continue;
				}
				translationStrings.put(entry[0].trim(),entry[1].trim());
			}
		}
	}

	public class AccountWrapper {
		public Account acc	{get;set;}

		public AccountWrapper(Account a){
			this.acc = a;
		}
	}

	public class ContactWrapper {
		public Contact con	{get; set;}
		

		public ContactWrapper(Contact c){
			this.con = c;
		}
	}

	public class StudentPortfolioWrapper implements Comparable {
		public Integer year							{get;set;}
		public List<AttachmentsWrapper> gradesList	{get;set;}
		public String id							{get;set;}

		public StudentPortfolioWrapper(Integer y, List<AttachmentsWrapper> grades){
			gradesList = new List<AttachmentsWrapper>();
			year = null;
			this.year = y;
			this.gradesList = grades;
		}
		
		//EE 10/11 removed because patches will break--adding in for 6.2
		public integer compareTo(Object o){
			StudentPortfolioWrapper spw = (StudentPortfolioWrapper) o;
			if(year > spw.year || spw.year==null) return -1;
			else if(year < spw.year || year==null) return 1;
			else return 0;
		}
	}

	public class AttachmentsWrapper {
		public Grade__c grade						{get;set;}
		public List<Attachment> uploadedAttachments {get;set;}
		public String staff							{get;set;}

		public AttachmentsWrapper(Grade__c g,List<Attachment> att,String st){
			this.grade = g;
			this.uploadedAttachments = att;
			this.staff = st;
		}
	}

	public class GradeWrapper {
		public Grade__c grade				{get;set;}
		public Attachment atchmnt			{get;set;}
		public List<String> staffNamesList	{get;set;}
		public String dueDate				{get;set;}
		public String sortDueDate			{get;set;}

		public GradeWrapper(Grade__c g, Attachment a,List<String> ss){
			this.grade = new Grade__c();
			this.atchmnt = new Attachment();
			this.staffNamesList = new List<String>();
			this.grade = g;
			this.atchmnt = a;
			this.staffNamesList = ss;
		}
		
		public GradeWrapper(Grade__c g){
			this.grade = g;
			this.dueDate = g.Assignment__r.Due_Date__c.format();
			List<String> longDue = this.dueDate.split('/');
			if(longDue[0].length() == 1)
				longDue[0] = '0'+longDue[0];
			if(longDue[1].length() == 1)
				longDue[1] = '0'+longDue[1];	 
			this.sortDueDate = longDue[2]+longDue[0]+longDue[1];
		}
	}

	public class AssignmentWrapper {
		public String grade				{get;set;}
		public Attachment atchmnt		{get;set;}
		public String staffNames 		{get;set;}
		public Assignment__c assignment	{get;set;}

		public AssignmentWrapper(String g, Attachment a,String ss,Assignment__c assign){
			this.grade = '';
			this.atchmnt = new Attachment();
			this.staffNames = '';
			this.assignment = new Assignment__c();
			this.grade = g;
			this.atchmnt = a;
			this.staffNames = ss;
			this.assignment = assign;
		}
	}

	public class CourseWrapper {
		public String courseName		{get;set;}
		public String courseDescription {get;set;}
		public Boolean selected			{get;set;}

		public CourseWrapper(String c, String D, Boolean val ){
			this.courseName = c;
			this.selected = val;
			this.courseDescription = D;
		}
	}

	public class CourseNameWrapper {
		public String Name			{get; set;}
		public String Description 	{get; set;}

		public CourseNameWrapper(){}
	}

	public class SectionGradeWrapper {
		public String course				{get;set;}
		public List<String> rpGrades		{get;set;}
		public String finalGrade		  	{get;set;}
		public String currentGrade			{get;set;}
		public boolean hasOneSectionGrade	{get;set;}

		public SectionGradeWrapper(String c, List<String> grd,String fg,String currGrade){
			this.course = c;
			this.rpGrades = grd;
			this.finalGrade = fg;
			this.currentGrade = currGrade;
			this.hasOneSectionGrade = (String.join(grd,'') != '');
		}
	}

	public class ReportCardsWrapper {
		public Student_Reporting_Period__c studRP	{get;set;}
		public String issueDate						{get;set;}
		public Integer year							{get;set;}

		public ReportCardsWrapper(Student_Reporting_Period__c srp,Date d, Integer y){
			this.studRP = srp;
			this.issueDate = d.format();
			this.year = y;
		}
	}

	public class SectionalAttendanceWrapper {
		public String sectionName			{get;set;}
		public Integer excusedAbsences		{get;set;}
		public Integer unexcusedAbsences	{get;set;}
		public Integer unexcusedTardys		{get;set;}
		public Integer tardys				{get;set;}

		public SectionalAttendanceWrapper(String name,Integer ea,Integer uae,Integer uet, Integer t){
			this.sectionName = name;
			this.excusedAbsences = ea;
			this.unexcusedAbsences = uae;
			this.unexcusedTardys = uet;
			this.tardys = t;
		}
	}

	public class StrandWrapper{
		public String strandName						{get;set;}
		public List<StandardWrapper> standardsList	{get;set;}
		public Integer masteredStandardsCount			{get;set;}
		public Decimal masteredStrandPerc				{get;set;}

		public StrandWrapper(String strName, List<standardWrapper> standardWrappers,Integer ms){
			this.strandName = strName;
			this.standardsList = standardWrappers;
			this.masteredStandardsCount = 0;
			this.masteredStrandPerc = 0.0;

			if(ms != null)
				this.masteredStandardsCount = ms;
			else
				this.masteredStandardsCount = 0;
			if(standardsList!= null && standardsList.size() > 0)
				this.masteredStrandPerc = (Decimal.valueOf(masteredStandardsCount)/standardsList.size() * 100).divide(1,2);
		}

		public StrandWrapper(){
			standardsList = new List<StandardWrapper>();
		}
	}

	public class StandardWrapper{
		public String longText						{get;set;}
		public List<Standard_Grade__c> standards	{get;set;}
		public Decimal lastGrade					{get;set;}

		public StandardWrapper(List<Standard_Grade__c> grades){
			longText = '';
			if(!grades.isEmpty()){
				for(Standard_Grade__c s:grades){
					if(String.isBlank(longText) && !String.isBlank(s.Standard__r.Long_Text__c)){
						longText = s.Standard__r.Long_Text__c.left(75);
						if(s.Standard__r.Long_Text__c.length() > 75){
							longText+='...';
						}
					}
					if(s.Standard_Grade__c != null){
						lastGrade = s.Standard_Grade__c;
					}
				}
				standards = grades;
			} else {
				//if they don't have a grade but have a standard grade, then override the lastGrade to always show green.
				lastGrade = 100;
			}
		}
	}

	public class homeworkWrapper{
		public String courseName		{get;set;}
		public Double percentMissing	{get;set;}
		public Double percentLate		{get;set;}

		public homeworkWrapper(string cName, Double missing, Double late, Double Total){
			courseName = cName;
			percentMissing = 0;
			percentLate = 0;
			if(total != null && total != 0){
				if(missing != null)
					percentMissing = Math.round((missing/Total)*100*Math.POW(10,1))/Math.POW(10,1);
				if(late != null)
					percentLate = Math.round((late/Total)*100*Math.POW(10,1))/Math.POW(10,1);
			}
		}
	}
}