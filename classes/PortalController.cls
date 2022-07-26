public class PortalController {
	public Id uId						{get;set;}
	public PortalWrapper port			{get;set;}
	public Boolean isManagedPackage		{get;set;}
	public Boolean displayHome			{get;set;}
	public Boolean displayMyAssignments	{get;set;}
	public Boolean displayMyProgress	{get;set;}
	public Boolean displayMyCalendar	{get;set;}
	public Boolean displayMyPortfolio	{get;set;}
	public Boolean displayMyStrands		{get;set;}
	public Boolean displayMytonomy		{get;set;}
	public Boolean showMytonomyTab		{get;set;}
	public String progressCourseName	{get;set;}
	public String mediaSourceLink		{get;set;}
	public String mediaSourceName		{get;set;}
	public Decimal behaviorGoal			{get;set;}
	public Decimal behaviorProgress		{get;set;}
	public Decimal attendanceGoal		{get;set;}
	public Decimal attendanceProgress	{get;set;}
	public String portalPage			{get;set;}
	public String mediasource			{get;set;}

	public PortalController(){
		isManagedPackage = Schema.SObjectType.Assesment__c.getName().replace('__c', '').contains('__');
		portalPage = ApexPages.currentPage().getUrl();
		this.uId = UserInfo.getUserId();
		port = new PortalWrapper(uId);
		progressCourseName ='All';

		//Check to see if a tab is requested
		if(ApexPages.currentPage().getParameters().containsKey('tab')){
			string tabName = ApexPages.currentPage().getParameters().get('tab');

			displayHome = (tabName == 'Home') ? true:false;
			displayMyAssignments = (tabName == 'Assignments') ? true:false;
			displayMyProgress = (tabName == 'Progress') ? true:false;
			displayMyCalendar = (tabName == 'Calendar') ? true:false;
			displayMyPortfolio = (tabName == 'Portfolio') ? true:false;
			displayMyStrands	= (tabName == 'Strands') ? true:false;
			displayMytonomy = (tabName == 'Mytonomy') ? true:false;
		} else {
			displayHome = true;
		}
		
		SchoolForce_Settings__c settings = SchoolForce_Settings__c.getOrgDefaults();
		showMytonomyTab = (settings != null)?settings.Mytonomy__c:false;

		if(port.mediaList!= null && !port.mediaList.isEmpty()){
			mediaSourceLink = port.mediaList[0].Resource__c;
			mediaSourceName = port.mediaList[0].Name;
		}

		if(port.acc.acc.Behavior_Goal__c != null)
			behaviorGoal = 100 - port.acc.acc.Behavior_Goal__c;
		else
			behaviorGoal = 0;

		if(port.currstudent.Student_Behavior_Score__c != null)
			behaviorProgress = 100 - port.currstudent.Student_Behavior_Score__c;
		else
			behaviorProgress = 0;

		if(port.acc.acc.Attendance_Goal__c != null)
			attendanceGoal = port.acc.acc.Attendance_Goal__c;
		else
			attendanceGoal = 0;

		if(port.currstudent.Attendance_Percentage__c != null)
			attendanceProgress = port.currstudent.Attendance_Percentage__c;
		else
			attendanceProgress = 0;
	}

	public Pagereference refreshMyAssignmentCourses(){
		port.courses = new List<PortalWrapper.CourseWrapper>();
		String courseName;
		port.currAssignsPerSection = new List<PortalWrapper.AssignmentWrapper>();
		port.pastAssignsPerSectionList = new List<PortalWrapper.AssignmentWrapper>();
		port.mediaList = new List<External_Resources__c>();
		
		if(ApexPages.currentPage().getParameters().get('tabName') != null)
			courseName = ApexPages.currentPage().getParameters().get('tabName');
		else
			courseName = 'All';
		try{
			for(integer i = 0; i<(port.courseNames).size(); i++){
				if(port.courseNames[i].Name == courseName)
					port.courses.add(new PortalWrapper.CourseWrapper(port.courseNames[i].Name, port.courseNames[i].Description, true));
				else
					port.courses.add(new PortalWrapper.CourseWrapper(port.courseNames[i].Name, port.courseNames[i].Description, false));
			}

			if(courseName == 'All'){
				port.pastAssignsPerSectionList = port.sectionIdToListOfPastAssignmentsMap.get('All');
				port.currAssignsPerSection = port.sectionIdToListOfCurrAssignmentsMap.get('All');
			}else{
				port.pastAssignsPerSectionList = port.sectionIdToListOfPastAssignmentsMap.get(port.courseToSectionsMap.get(courseName));
				port.currAssignsPerSection = port.sectionIdToListOfCurrAssignmentsMap.get(port.courseToSectionsMap.get(courseName));
			}
			
			if(port.sectionToMediaMap.containsKey(port.courseToSectionsMap.get(courseName))){
				for(external_Resources__c m : port.sectionToMediaMap.get(port.courseToSectionsMap.get(courseName))){
					port.mediaList.add(m);
				}
			}
			
			if(ApexPages.currentPage().getParameters().get('mname') != null && ApexPages.currentPage().getParameters().get('mlink') != null){
				mediaSourceName = ApexPages.currentPage().getParameters().get('mname');
				mediaSourceLink = ApexPages.currentPage().getParameters().get('mlink');
			}else{
				if(port.mediaList.size() > 0){
					mediaSourceLink = port.mediaList[0].Resource__c;
					mediaSourceName = port.mediaList[0].Name;
				}else{
					mediaSourceLink = '';
					mediaSourceName = '';
				}
			}
		}catch(Exception e) {
			System.debug(e.getMessage());
		}
		return null;
	}

	public Pagereference refreshMyProgressCourses(){
		port.courses = new List<PortalWrapper.CourseWrapper>();
		port.progressGradeList = new List<PortalWrapper.GradeWrapper>();
		port.selectedSectionGrade = '';
		try{
			if(ApexPages.currentPage().getParameters().get('progressCourseName') != null)
				progressCourseName = ApexPages.currentPage().getParameters().get('progressCourseName');
			else
				progressCourseName = 'All';

			for(integer i = 0; i<(port.courseNames).size(); i++){
				if(port.courseNames[i].Name == progressCourseName)
					port.courses.add(new PortalWrapper.CourseWrapper(port.courseNames[i].Name, port.courseNames[i].Description, true));
				else
					port.courses.add(new PortalWrapper.CourseWrapper(port.courseNames[i].Name, port.courseNames[i].Description, false));
			}

			if(progressCourseName == 'All'){
				for(List<Grade__c> grd :port.sectionToListOfGrades.values()){
					for(Grade__c g:grd){
						port.progressGradeList.add(new PortalWrapper.GradeWrapper(g));
					}
				}
					
				}
			else{
				if(port.sectionToListOfGrades.containskey(port.courseToSectionsMap.get(progressCourseName))){
					for(Grade__c g:port.sectionToListOfGrades.get(port.courseToSectionsMap.get(progressCourseName)))
						port.progressGradeList.add(new PortalWrapper.GradeWrapper(g));
					if(port.progressGradeList != null  && port.progressGradeList.size() > 0)
					port.selectedSectionGrade = port.sectionGradeMap.get(port.progressGradeList[0].grade.student_section__c);
				}
			}
		} catch(Exception e) {
			System.debug(e.getMessage());
		}
		return null;
	}

	public Pagereference refreshMyStandards(){
		port.strandsByCourseList = new List<PortalWrapper.StrandWrapper>();
		port.standsbulletinList = new List<External_Resources__c>();
		port.standsResList = new List<External_Resources__c>();
		String strandCourseName;

		try{
			if(ApexPages.currentPage().getParameters().get('strandCourseName') != null)
				strandCourseName = ApexPages.currentPage().getParameters().get('strandCourseName');
			else
				strandCourseName = port.myStandardCourses[0].courseName;

			port.myStandardCourses = new List<PortalWrapper.CourseWrapper>();

			for(integer i = 0; i<(port.courseNames).size(); i++){
				if(port.courseNames[i].Name != 'All'){
					if(port.courseNames[i].Name == strandCourseName)
						port.myStandardCourses.add(new PortalWrapper.CourseWrapper(port.courseNames[i].Name, port.courseNames[i].Description, true));
					else
						port.myStandardCourses.add(new PortalWrapper.CourseWrapper(port.courseNames[i].Name, port.courseNames[i].Description, false));
				}
			}
			if(port.sectionToStrandWrapper.containskey(strandCourseName)){
				port.strandsByCourseList = port.sectionToStrandWrapper.get(strandCourseName);
			}

			port.standsResList = port.courseToStandVideosMap.get(strandCourseName);
			port.standsbulletinList = port.courseToStandUrlsMap.get(strandCourseName);
		} catch(Exception e) {
			System.debug(e.getMessage());
		}
		return null;
	}

	public void dummyRefresh(){
	}
	
	public pageReference updateLanguage(){
		boolean loaded = false;
		for(StaticResource sr:[select Name,Description, Body from StaticResource where Description=:port.selectedLanguage and Name LIKE '%Portal%']){
			if(!loaded || !sr.Name.contains('SchoolForce__')){
				port.loadTranslation(sr);
			}
		}
		return null;
	}
}