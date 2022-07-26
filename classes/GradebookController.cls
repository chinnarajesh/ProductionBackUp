global class GradebookController{
	public String section								{get;set;}
	public String commentId								{get;set;}
	public String tempSection							{get;set;}
	public String errorMsg								{get;set;}
	public List<SelectOption> periodList				{get;set;}
	public List<SelectOption> displayToggle				{get;set;}
	public List<SelectOption> singleAssignment			{get;set;}
	public List<SelectOption> singleStandard			{get;set;}
	public List<SelectOption> singleStudentSelect		{get;set;}
	public GradebookWrapper gradebookObj				{get;set;}
	public ID timeId									{get;set;}
	public String standardDisplayString					{get;set;}
	public String selectedAssignmentID					{get;set;}
	public String selectedstandardID					{get;set;}
	public String studentFilterID						{get;set;}
	public Boolean standardDisplay						{get;set;}
	public boolean viewReadOnly{get;set;}
	public Boolean addWizardDisplay						{get;set;}
	public integer iMainTableWidth						{get;set;}
	public integer iRightLeft							{get;set;}
	public List<SelectOption> atypeList					{get;set;}
	public String aType									{get;set;}
	public integer iGradeColWidth;
	public integer iMaxGradeTabWidth;
	public core_BaseInfo_v2.cSchool_BaseInfo	baseObj	{get;set;}
	public string string2								{get;set;}
	public ID selectedStudentID							{get;set;}
	public Boolean firstQuery							{get;set;}
	public Boolean bGlobalStandardsBased				{get;set;}
	public Boolean bStandardsONLYGB						{get;set;}
	public Time_Element__c timeFilter					{get;set;}
	public List<SelectOption> yearOptions				{get;set;}
	public List<SelectOption> schoolOptions				{get;set;}
	public String yearId								{get;set;}
	public String schoolId								{get;set;}
	public String selectedCourseGradeScale				{get;set;}
	public boolean showCurrentViewOnly					{get;set;}
	public boolean isCurrentYear						{get;set;}
	public ID activeYearID {get; set;}

	public Staff__c staff								{get;set;}
	public boolean bStandardsBased						{get;set;}
	public Decimal dPassingGrade						{get;set;}
	public Setup__c activeSetup							{get;set;}
	public Account school								{get;set;}
	public List <Section__c> sectionList				{get;set;}
	public List <SelectOption> reportingPeriodOptions	{get;set;}
	public List <SelectOption> sectionOptions			{get;set;}
	public Id selectedTimeId							{get;set;}
	public Map <Id, Section__c> sectionMap				{get;set;}

	public Map<String,Map<String,Setup__c>>			schoolSetupsByYearMap;
	public Map<String,Map<String,List<Section__c>>> yearSectionsMap;
	public Map <Id, Account>			schoolMap;
	public Map <Id, Id>				staffSchoolMap;

	public Map <Id, List<SelectOption>> assignmentMap;
	public Map <Id, List<SelectOption>> studentSelectMap;

	//US2346
	public Map <Id, Time_Element__c> timeMap	{get; set;}
	public List<String> timeMapValues			{get; set;}
	public List<ID> timeMapKeySet				{get; set;}
	public Set<ID> availableRPs					{get; set;}

	transient ID headerstudentId;
	transient List<Grade__c> headerGradeList;
	transient public List <Grade__c> gradeList;
	public	List<Attendance__c> totalAttendance;
	public 	Map<Id, List<Attendance__c>> studentAttendanceMap ;

	public Boolean urlBlock	{get; set;}

	//US3131
	public Gradebook_AssignmentWrapper_v2 assignmentWrapper {get; set;}
	public searchStandards searchFeature {get; set;}
	Map<String, String> standardScaleMap {get; set;}
	Set<ID> pointsGradeScaleID {get; set;}
	public String dueDate {get; set;} //within the reporting period they are currently on
	//pull the RP ID from the filter

	//similar selectOptions from assignmentController_v2
	public List<SelectOption> assignmentTypeOptions {get; set;} //can only be populated once we know what the course is
	public List<SelectOption> gradeScaleOptions {get; set;} //can only be populated once we know what the course is
	public List<SelectOption> standardScaleOptions	{get; set;} //same as gradeScale
	public List<SelectOption> integerAssignmentWeightingOptions {get; set;} //can populate in constructor

	//DE3505
	//Key = courseID + DAW -> Integer weighting
	public Map<String, Integer> defaultAssignmentWeighting {get; set;}
	public List<SelectOption> colorOptions {get; set;} //can be populated in constructor

	//render Parameters, I believe should be controlled on the page, and not in the wrapper
	public Boolean rGradeScale {get; set;}
	public Boolean rStandardScale {get; set;}
	public Boolean rPoints {get; set;}
	public Boolean rIntegers {get; set;}
	public Boolean rStandards {get; set;}
	public Boolean advanceAssignmentOptions {get; set;}
	public Boolean closeQuickCreate {get; set;}
	public Boolean quickCreateNew {get; set;}
	//for redirecting
	public String domain {get; set;}
	public String fromGradeBook {get; set;}
	public Boolean usePercentage {get; set;}
	
	//Reporting Period display
	public String currentReportingPeriodName {get; set;}

	public GradebookController(){
		viewReadOnly = false;
		addWizardDisplay = true;
		this.firstQuery = true;
		this.timeFilter = new Time_Element__c();
		this.assignmentMap = new Map<Id,List<SelectOption>>();
		this.studentSelectMap = new Map<Id,List<SelectOption>>();

		//US2346
		this.timeMapValues = new List<String>();
		this.timeMapKeySet = new List<ID>();
		this.timeMap = new Map<Id, Time_Element__c>();
		this.availableRPs = new Set<ID>();

		this.headerGradeList = new List<Grade__c>();
		this.singleAssignment = new List<SelectOption>();
		this.singleStandard = new List<SelectOption>();
		this.singleStudentSelect = new List<SelectOption>();
		this.selectedAssignmentID='All';
		this.selectedStandardID='All';
		this.studentFilterID = 'All';
		this.iGradeColWidth = 75;
		this.iMaxGradeTabWidth = 12;
		this.gradebookObj = new GradebookWrapper();
		this.standardDisplay = true;
		this.aType='All';
		this.isCurrentYear = true;
		this.standardDisplayString = 'true';
		this.gradeList = new List<Grade__c>();

		this.string2 = '';

		this.displayToggle = new List<SelectOption>{new SelectOption('false','By Assignment'),new SelectOption('true','By Standard')};
		this.atypeList = new List<SelectOption>();

		atypeList.add(new SelectOption('All','All'));

		//US2346
		urlBlock = false;

		try{
			//DE3496 round 2
			try {
				staffSchoolMap = new Map<Id,Id>();
				schoolMap = new Map<Id,Account>();
				yearSectionsMap = new Map<String,Map<String,List<Section__c>>>();

				core_BaseInfo_v2.initBaseInfo(true);
				schoolSetupsByYearMap = core_BaseInfo_v2.schoolSetupsByYearMap;
				yearSectionsMap = core_BaseInfo_v2.yearSectionsMap;
				staffSchoolMap = core_BaseInfo_v2.staffSchoolMap;
				schoolMap = core_BaseInfo_v2.schoolMap;
				System.debug('$$$$$staffSchoolMap$$$$$'+staffSchoolMap);
				reloadYear();
				yearOptions = getSchoolYears();
				schoolOptions = getSchools();
			}
			catch(Exception e) {
				addWizardDisplay = false;
				//huh, this function doesn't work? Need to investigate why.
				//core_BaseInfo_v2.showErrorMessages();
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'You are not associated to any sections for the current year. Please contact your administrator.'));
			}

			//DE3496 verifying staff
			try {
				if(ApexPages.currentPage().getParameters().get('fromAssignment')=='1'){
					//US2346
					urlBlock = true;
					baseObj.selectedTimeId = ApexPages.currentPage().getParameters().get('timeid');

					//US2346
					reloadTime();
					timeMapValues = timeMapValues();
					timeMapKeySet = timeMapKeySet();

					section = ApexPages.currentPage().getParameters().get('section');
					selectedAssignmentID = ApexPages.currentPage().getParameters().get('assignmentID');
					standardDisplayString = 'false';

					//US 1334: adding new parameters to pre-filter students list
					if(ApexPages.currentPage().getParameters().get('studentID')!=null)
					{
						studentFilterID = ApexPages.currentPage().getParameters().get('studentID');
					}
					//DE1235
					//DE1725 - need to test this more to make sure de1235 is resolved
					retrieveStudentGrades();
				}
			}
			catch(Exception e) {
				addWizardDisplay = false;
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'You are not scheduled to teach any sections for this year. Please contact your administrator.'));
			}

			addWizardDisplay = true;

			//US3131
			try {
				pointsGradeScaleID = new Set<ID>();
				standardScaleMap = new Map<String, String>();
				//part of the advanced options
				assignmentTypeOptions = new List<SelectOption>();
				gradeScaleOptions = new List<SelectOption>();
				standardScaleOptions = new List<SelectOption>();
				integerAssignmentWeightingOptions = getIntegerAssignmentWeightingOptions();
				//DE3505
				defaultAssignmentWeighting = new Map<String, Integer>();
				colorOptions = getColorOptions();
				getScaleOptions();
				reloadTime();
				system.debug('~~~~~ selectedTimeId: '+baseObj.selectedTimeId);
			}
			catch(Exception e) {
				addWizardDisplay = false;
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'There was a problem initializing Quick Create Assignment Feature. Please contact your administrator.'));
			}
		}
		catch(Exception e) {
			addWizardDisplay = false;
			Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'There was a problem initializing the Gradebook. Please contact your administrator.'));
		}
	}

	public pagereference xls(){
		retrieveStudentGrades();
		return Page.Gradebook_Export;
	}


	public pagereference newAssignmentPage(){
		//pagereference p = Page.Gradebook_AddAssignments;
		pageReference p = Page.Gradebook_AddAssignments_v2;
		p.getParameters().put('fromGradebook','true');
		return p;
	}

	public void reloadAssignments(){
		if(assignmentMap.containskey(section)){
			singleAssignment = assignmentMap.get(section);
		}
		else{
			singleassignment = new List<SelectOption>{new SelectOption('All','All')};
		}



		if(studentSelectMap.containskey(section)){
			singleStudentSelect = studentSelectMap.get(section);
		}
		else{
			singleStudentSelect = new List<SelectOption>{new SelectOption('All','All')};
		}
		//US2347
		changeRPOptions();
	}



	public void reloadTime(){
		if(timeMap.containskey(baseObj.selectedTimeId)){
			timeFilter.Date_Start_Date__c = timeMap.get(baseObj.selectedTimeId).Date_Start_Date__c;
			timeFilter.End_Date__c = timeMap.get(baseObj.selectedTimeId).End_Date__c;
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
			schoolId = baseObj.school.Id;
			yearId = baseObj.activeSetup.Year__c;
			activeYearID = baseObj.activeSetup.Year__c;
		}
		else {
			system.debug('*~*~* yearID: ' + yearID);
			system.debug('*~*~* baseObj.activeSetup.Year__c: ' + baseObj.activeSetup.Year__c);
			system.debug('*~*~* activeYearID: ' + activeYearID);
			//DE3480
			//isCurrentYear = (yearID == baseObj.activeSetup.Year__c);
			isCurrentYear = (yearID == activeYearID);
		}

		refreshYear(schoolId, yearId);
		bGlobalStandardsBased = baseObj.bStandardsBased;
		bStandardsONLYGB = baseObj.activeSetup.Standards_ONLY_Gradebook__c;
		standardDisplayString = 'false';
		Set<Id> sectIDSet = new Set<ID>();
		integer x = 0;
		for(Section__c s:baseObj.sectionList){
			sectIDset.add(s.Id);
			if(x==0){
				section = s.Id;
			}
			x++;
		}
		for(Assignment__c a:[select Id, Name, Section__c from Assignment__c where Section__c IN :sectIDSet order by Name asc]){
			if(assignmentMap.containskey(a.Section__c)){
				assignmentMap.get(a.Section__c).add(new SelectOption(a.Id, a.Name));
			}
			else{
				assignmentMap.put(a.Section__c,new List<SelectOption>{new SelectOption('All','All'), new SelectOption(a.Id, a.Name)});
			}
		}


		for(Student_Section__c ss:[select Id, Name, Student__r.Name, Student__c, Section__c from Student_Section__c where (Section__c IN :sectIDSet AND ((Archived__c = false AND Active__c = true AND Student__r.Active__c = true) OR (Archived__c = true AND Active__c = false))) order by Student__r.Name asc]){
			if(studentSelectMap.containskey(ss.Section__c)){
				studentSelectMap.get(ss.Section__c).add(new SelectOption(ss.Student__c, ss.Student__r.Name));
			}
			else{
				studentSelectMap.put(ss.Section__c,new List<SelectOption>{new SelectOption('All','All'), new SelectOption(ss.Student__c, ss.Student__r.Name)});
			}
		}


		reloadAssignments();

		Boolean rpSet = false;
		ID tempTimeID;
		integer y=0;
		for(Time_Element__c te:core_SoqlUtils.getTimeElementsByTermGB(baseObj.activeSetup.term__c)){
			if(y==0){
				tempTimeID = te.Id;
			}
			//US2347
			//set it to default the last, because the next if statement will set it appropriately to the
			//current reporting period if it is in one, else the rp is over and initialize with the last one
			//this does not effect the on section select, that uses the reloadAssignment
			if(te.Id == baseObj.reportingPeriodOptions[baseObj.reportingPeriodOptions.size() - 1].getValue()) {
				tempTimeID = te.Id;
			}

			timeMap.put(te.Id, te);

			if(te.Reporting_Period__c&&system.today()>=te.Date_Start_Date__c&&system.today()<=te.End_Date__c&&availableRPs.contains(te.id)){
				baseObj.selectedTimeId = te.Id;
				rpSet = true;
			}
			y++;
		}
		if(!rpSet){
			baseObj.selectedTimeId = tempTimeID;
		}

		//US2346
		reloadTime();
		timeMapValues = timeMapValues();
		timeMapKeySet = timeMapKeySet();

		for (Picklist_Value__c pl: core_SoqlUtils.getPlStringValues('Assignment Type', baseObj.activeSetup.id).values()){
			this.atypeList.add(new SelectOption(pl.id, pl.Name));
		}


	}

	public void refreshYear(String schoolId,String yearId){

		baseObj.sectionMap = new Map <Id, Section__c>();
		baseObj.sectionList = new List<Section__c>();
		baseObj.reportingPeriodOptions = new List <SelectOption>();
		baseObj.sectionOptions = new List <SelectOption>();
		System.debug('$$$$$schoolId$$$$$$'+schoolId);

		baseObj.activeSetup = schoolSetupsByYearMap.get(schoolId).get(yearId);
		baseObj.school =	schoolMap.get(SchoolId);
		baseObj.staff	= core_SoqlUtils.getStaffDetails(staffSchoolMap.get(schoolId));

		System.debug('$$$$$schoolId$$$$$$'+schoolId);

		System.debug('$$$$$schoolSetupsByYearMap$$$$$$'+schoolSetupsByYearMap);
		System.debug('$$$$$termSetupMap$$$$$$'+schoolMap);
		System.debug('$$$$$schoolId$$$$$$'+schoolId);
		System.debug('$$$$$staffSchoolMap.get(schoolId)$$$$$$'+ staffSchoolMap.get(schoolId));
		if (baseObj.activeSetup!=null){
			baseObj.bStandardsBased = baseObj.activeSetup.Standards_Based_Grading__c;
			//defect 2020
			baseObj.dPassingGrade = baseObj.activeSetup.On_Track_Threshold__c;
			baseObj.dFailingGrade = baseObj.activeSetup.Passing_Grade_Threshold__c;


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

	public pagereference redirectInitialPage(){
		pagereference p;
		/*
		try{
			if(!bStandardsONLYGB){
				p = Page.Gradebook;
			}
			else{
				p = Page.Gradebook_SO;
			}
			if(ApexPages.currentPage().getParameters().get('fromAssignment')=='1'){
				p.getParameters().put('fromAssignment','1');
				p.getParameters().put('timeid',ApexPages.currentPage().getParameters().get('timeid'));
				p.getParameters().put('section',ApexPages.currentPage().getParameters().get('section'));
				p.getParameters().put('assignmentID',ApexPages.currentPage().getParameters().get('assignmentID'));
			}
			p.setRedirect(true);
			return p;
		}
		catch(Exception e){
			return Page.Gradebook;
		}
		*/
		
		p = Page.Gradebook_v2;
		if(ApexPages.currentPage().getParameters().get('fromAssignment')=='1'){
			p.getParameters().put('fromAssignment','1');
			p.getParameters().put('tID',ApexPages.currentPage().getParameters().get('tID'));
			p.getParameters().put('sID',ApexPages.currentPage().getParameters().get('sID'));
			p.getParameters().put('aID',ApexPages.currentPage().getParameters().get('aID'));
		}		
		p.setRedirect(true);
		return p;
	}


	@RemoteAction
	global static List<String> updategradelist2(String cmc) {
		List<String> retList = new List<String>();
		try{
			Map<ID,Grade__c> gMap = new Map<ID, Grade__c>();
			for(String s:cmc.split(',')){
				list <String> splitList = s.split(';');
				String tempGrade;
				if(splitList.size()==1){
					tempGrade = null;
				}
				else{
					tempGrade = splitlist[1];
				}
				gMap.put(splitlist[0], new Grade__c (Id = splitlist[0], Entered_grade__c = tempGrade));
			}
			system.debug('#### gMap.values = '+gMap.values());
			update gMap.values();

		}
		Catch (Exception e) {
			system.debug('#### error in manageGB = '+e);
			if(e.getTypeName() == 'System.DmlException'){
				for (Integer i = 0; i < e.getNumDml(); i++) {
					if(e.getDmlMessage(i).length()>18){//In case error is not bad entered grade
						throw e;
					}
					retList.add(e.getDmlMessage(i));
				}

				system.debug('#### retlistA = '+retList);
				return retList;
			}
			else{
				throw e;
			}
		}
		system.debug('#### retlistB = '+retList);
		return retList;
	}

	@RemoteAction
	global static List<String> updategradelistcheck(String cmc) {
		Set<String> skipValues= new Set<String>();

		//start out at the User level, then work down to profile and then org defaults,
		//technically we do not care about the id, as long as allowable_grades__c is populated
		OverrideSettings__c os = OverrideSettings__c.getInstance(UserInfo.getUserID());
		if(os.Allowable_Grades__c != null && os.Allowable_Grades__c != '') {
			for(String s: os.Allowable_Grades__c.split(',')){
				skipValues.add(s.trim());
			}
		}
		else {
			os = OverrideSettings__c.getInstance(UserInfo.getProfileID());
			if(os.Allowable_Grades__c != null && os.Allowable_Grades__c != '') {
				for(String s: os.Allowable_Grades__c.split(',')){
					skipValues.add(s.trim());
				}
			}
			else {
				os = OverrideSettings__c.getOrgDefaults();
				if(os.Allowable_Grades__c != null && os.Allowable_Grades__c != '') {
					for(String s: os.Allowable_Grades__c.split(',')){
						skipValues.add(s.trim());
					}
				}
			}
		}
		
		skipValues.add('');
		skipValues.add(null);
		Map<String, String> assignMap = new Map<String,String>();
		List<String> List0100 = new List<String>();
		List<String> borderList = new List<String>();
		try{

			Map<ID,Grade__c> gMap = new Map<ID, Grade__c>();
			for(String s:cmc.split(',')){
				list <String> splitList = s.split(';');
				String tempGrade;
				if(splitList.size()==1){//
					tempGrade = null;
				}
				else{
					tempGrade = splitlist[1];
				}
				if(splitlist.size()==3){
					gMap.put(splitlist[0], new Grade__c (Id = splitlist[0], Entered_grade__c = tempGrade, exclude_From_Section_Grade__c = boolean.valueOf(splitlist[2])));
				}
				else{
					gMap.put(splitlist[0], new Grade__c (Id = splitlist[0], Entered_grade__c = tempGrade));
				}
			}
			for(Grade__c g:[select id, exclude_From_Section_Grade__c, Possible_Points__c, Entered_Grade__c, Assignment__r.Picklist_Value__r.Name, Assignment__r.Name, Assignment__r.Picklist_Value__r.Category__c, Assignment__c from Grade__c where Id IN :gMap.keyset()]){

				if(!(skipValues.contains(gMap.get(g.id).Entered_grade__c))){
					if(g.Assignment__r.Picklist_Value__r.Category__c == 'Points' || g.Assignment__r.Picklist_Value__r.Name == 'Standard' || g.Assignment__r.Picklist_Value__r.Category__c == '0-100'){
						if(isdecimal(gMap.get(g.Id).Entered_grade__c)){
							if(g.Possible_Points__c >0 && gMap.get(g.id).Entered_grade__c!=null && decimal.valueOf(gMap.get(g.id).Entered_grade__c)>g.Possible_Points__c){
								assignMap.put(g.Assignment__c, g.Assignment__r.Name);
							}
							if(g.Assignment__r.Picklist_Value__r.Category__c == '0-100' && gMap.get(g.id).Entered_grade__c != null && decimal.valueOf(gMap.get(g.ID).Entered_Grade__c) > 100.00) {
								borderList.add(g.ID);
							}
						}
						else{
							borderList.add(g.id);
						}
					}
				}
			}
		}
		Catch (Exception e) {
			Global_Error__c ge = Error_Handling.handleError('', 'GradebookController', 'Remote Method updategradelist', e);
			insert ge;
			throw e;
		}
	
		if(borderList.size()>0||assignMap.size()>0){
			borderList.add('::');
			borderList.addAll(assignMap.values());
		}
		//return assignMap.values();
		return borderList;
	}



	@RemoteAction
	//US2681: updated to account for 'Include_In_Standard_Grade__c'
	global static Grade__c fetchcomment(String gid) {
		Grade__c g = new Grade__c();
		try{
			g = [select Id, Comment__c, Entered_Grade__c, exclude_From_Section_Grade__c, Publish_Comment__c, Include_In_Standard_Grade__c, Grade_With_Standard__c from Grade__c where Id = :gid];
			system.debug('Fetched comment: ' + g);
		}
		Catch (Exception e) {
			Global_Error__c ge = Error_Handling.handleError('', 'GradebookController', 'Remote Method fetchcomment', e);
			insert ge;
			throw e;
		}
		return g;
	}

	@RemoteAction
	//part of US2681: cannot simply modify global functions.
	//have to create new ones
	global static Grade__c updatecomment_v2(String gid, String ctext, String cpub, String eg, boolean exclude) {
		return new Grade__c();
	}

	@RemoteAction
	//US2681: updated to account for 'Include_In_Standard_Grade__c'
	global static Grade__c updatecomment_v3(String gid, String ctext, String cpub, String eg, boolean exclude, boolean include) {
		Grade__c cmupdate;
		try{
			Boolean checked = cpub == 'true' ? true : false;
			cmupdate = new Grade__c (Id = gid, Entered_Grade__c = eg, Exclude_From_Section_Grade__c = exclude, Comment__c = ctext, Publish_Comment__c = checked, Include_In_Standard_Grade__c = include);
			system.debug('Grade update: ' + cmupdate);

			//DE1647: did not modify the faux grade, which effects the Section Grade
			//note for hybrid gradebook, I'm pretty sure hybrid does not have the faux grades
			//but doesn't hurt to check
			List<Grade__c> fauxGrade = new List<Grade__c>();
			fauxGrade = [SELECT ID, Exclude_From_Section_Grade__c FROM Grade__c WHERE Standard_Gradebook_Grade__c =: gid LIMIT 1];
			if(fauxGrade.size() > 0) {
				fauxGrade[0].exclude_From_Section_Grade__c = exclude;
				update fauxGrade;
			}

			update cmupdate;
		}
		Catch (Exception e) {
			Global_Error__c ge = Error_Handling.handleError('', 'GradebookController', 'Remote Method updatecomment', e);
			insert ge;
			throw e;
		}
		return cmupdate;
	}

	@RemoteAction
	global static Grade__c updatecomment(String gid, String ctext, String cpub) {
		//original function
		return null;
	}

	@RemoteAction
	global static String lockgrades(String cmc) {
		try{
			List<Grade__c> gList = new List<Grade__c>();
			for(String s:cmc.split(',')){
				gList.add(new Grade__c (Id = s, Locked_for_Final__c = true));
			}
			update gList;
		}
		Catch (Exception e) {
			Global_Error__c ge = Error_Handling.handleError('', 'GradebookController', 'Remote Method lockgrades', e);
			insert ge;
			throw e;
		}
		return cmc;
	}

	@RemoteAction
	global static String highlighterrors(String errorMsg){
		String msg = errorMsg;
		integer parser = msg.indexOf(';');
		if(parser>0){
			msg		= msg.substring(parser-18,parser);
		}
		return msg;
	}


	public PageReference retrieveStudentGrades(){

		try{
			Section__c sect = [select Course__r.Grade_Scale__c from Section__c where Id = :section];
			viewReadOnly = [SELECT View_Gradebook_as_Read_Only__c FROM Staff_Section__c WHERE Section__c = :section AND Staff__c = :baseObj.staff.Id].View_Gradebook_As_Read_Only__c;
			selectedCourseGradeScale = sect.Course__r.Grade_Scale__c;
			if(section!=tempSection){
				firstQuery = true;
				singleStandard.clear();

			}
			if(standardDisplayString=='true'){
				standardDisplay = true;
			}
			else{
				standardDisplay = false;
			}

			if(studentFilterID=='All'){
				try{
					headerstudentId = [select Student__c from Student_Section__c where (Section__c = :section AND ((Archived__c = false AND Active__c = true) OR (Archived__c = true AND Active__c = false))) limit 1].Student__c;

				}
				catch(exception e){
					Apexpages.addMessage(new apexpages.message(apexpages.severity.error,'There are no students in this section.'));
					return null;
				}
			}
			else{
				headerstudentId = studentFilterID;
			}

			reloadAssignments();
			gradebookObj.swMap.clear();
			gradebookObj.singleAssignmentMap.clear();
			gradebookObj.singleStandardMap.clear();

			//DE1336
			if(selectedStandardID == null) {
				//for some reason it's in Gradebook_SO and not here: resetSearch()
				//same functionality though
				selectedstandardID = 'All';
			}

			//US2346
			if(ApexPages.currentPage().getParameters().get('fromAssignment')=='1' && urlBlock == true) {
				urlBlock = false;
				baseObj.selectedTimeId = ApexPages.currentPage().getParameters().get('timeid');
			}

			headerGradeList = Gradebook_SoqlUtils.getGradeListSoql(section, baseObj.selectedTimeId, aType, selectedAssignmentID, selectedStandardID, headerstudentId, timeFilter.End_Date__c, timeFilter.Date_Start_Date__c);

			gradeList	= Gradebook_SoqlUtils.getGradeListSoql(section, baseObj.selectedTimeId, aType, selectedAssignmentID, selectedStandardID, studentFilterID, timeFilter.End_Date__c, timeFilter.Date_Start_Date__c);

			gradebookObj.sectionName = baseObj.sectionMap.get(section).name;
			pullGrades(section, baseObj.selectedTimeId);


			for(Grade__c g:headerGradeList){
				gradebookObj.singleStandardMap.put(g.Standard__c, g.Standard__r.Name);
			}


			if(standardDisplay){

				Set<ID> standardSet = new Set<ID>();

				for(Grade__c g:headerGradeList){
					standardSet.add(g.Standard__c);
				}

				gradebookObj.standardMap = Gradebook_SoqlUtils.getStandardMap(standardSet);

				for(Grade__c g:gradeList){

					GradebookWrapper.cStudentWrapper w;
					if(!gradebookObj.swMap.keyset().contains(g.Student_Section__r.Student__c)){
						if(g.Standard__c==null){									//If there is no standard on a grade then the value of null is passed to the wrapper map

							w = new GradebookWrapper.cStudentWrapper(g, null, gradebookObj.sectGradeMap.get(g.Student_Section__r.Student__c));
						}
						else{
							w = new GradebookWrapper.cStudentWrapper(g, gradebookObj.standardMap.get(g.Standard__c), gradebookObj.sectGradeMap.get(g.Student_Section__r.Student__c));
						}

						gradebookObj.swMap.put(g.Student_Section__r.Student__c, w);
					}
					else{
						w = gradebookObj.swMap.get(g.Student_Section__r.Student__c);

						if(!w.standardMap.keyset().contains(g.Standard__c)){
							w.standardMap.put(g.Standard__c, new GradebookWrapper.cStandardWrapper(g, gradebookObj.standardMap.get(g.Standard__c)));
						}
						else{
							w.standardMap.get(g.Standard__c).gradelist.add(g);
						}
						gradebookObj.swMap.put(g.Student_Section__r.Student__c, w);
					}
					w.standardMap.get(g.Standard__c).gradeListSize+=1;
				}
				gradebookObj.studentWrapperList = gradebookObj.sortDisplayData(gradebookObj.swMap.values(), standardDisplay);
				getStudentAttendanceInfo();
				integer k=0;


				for(GradebookWrapper.cStudentWrapper sw:gradebookObj.studentWrapperList){

					Id stud = sw.student.id;



					gradebookObj.swMap.get(stud).standardWrapperList.addall(gradebookObj.swMap.get(stud).standardMap.values());

					for (GradebookWrapper.cStandardWrapper ca:gradebookObj.swMap.get(stud).standardMap.values()){
						gradebookObj.swMap.get(stud).gradeListSize+=ca.gradeListSize;
					}

					processStudentAttendanceInfo(sw);

					processGbStyles(gradebookObj, stud, k);
					k++;
				}


			}


			else{
				Set<ID> assignSet = new Set<ID>();

				for(Grade__c g:headerGradeList){
					assignSet.add(g.Assignment__c);
				}

				gradebookObj.assignmentMap = gradebook_SoqlUtils.getAssignmentMap(assignSet);

				for(Grade__c g: gradeList){


					GradebookWrapper.cStudentWrapper w;
					if(!gradebookObj.swMap.keyset().contains(g.Student_Section__r.Student__c)){

						w = new GradebookWrapper.cStudentWrapper(g, gradebookObj.assignmentMap.get(g.Assignment__c), null, gradebookObj.sectGradeMap.get(g.Student_Section__r.Student__c));


						gradebookObj.swMap.put(g.Student_Section__r.Student__c, w);
					}
					else{
						w = gradebookObj.swMap.get(g.Student_Section__r.Student__c);

						if(!w.assignmentMap.keyset().contains(g.Assignment__c)){
							checkStandards(g);
							w.assignmentMap.put(g.Assignment__c, new GradebookWrapper.cAssignmentWrapper(g, gradebookObj.assignmentMap.get(g.Assignment__c)));
						}
						else{
							checkStandards(g);
							w.assignmentMap.get(g.Assignment__c).gradelist.add(g);
						}
						gradebookObj.swMap.put(g.Student_Section__r.Student__c, w);
					}
					w.assignmentMap.get(g.Assignment__c).gradeListSize+=1;
				}
				gradebookObj.studentWrapperList = gradebookObj.sortDisplayData(gradebookObj.swMap.values(), standardDisplay);
				getStudentAttendanceInfo();
				integer k=0;

				for(GradebookWrapper.cStudentWrapper sw:gradebookObj.studentWrapperList){
					Id stud =			sw.student.id;
					for (GradebookWrapper.cAssignmentWrapper ca:gradebookObj.swMap.get(stud).assignmentMap.values() ){
						gradebookObj.swMap.get(stud).gradeListSize+=ca.gradeListSize;
					}

					processStudentAttendanceInfo(sw);

					processGbStyles(gradebookObj, stud, k);
					k++;
				}

			}

			removeBadStudents();

			gradebookObj.studentWrapperlist = sortWrapperList(gradebookObj.studentWrapperlist);

			if (!gradebookObj.studentWrapperList.isEmpty()) gradebookObj.header = gradebookObj.studentWrapperlist[0];

			if(firstQuery){
				singleStandard.add(new SelectOption('All', 'All'));
				for(ID si:gradebookObj.singleStandardMap.keyset()){
					if(si!=null){
						singleStandard.add(new SelectOption(si, gradebookObj.singleStandardMap.get(si)));
					}
				}
				if(ApexPages.currentPage().getParameters().get('fromAssignment')=='1'){
					firstQuery = true;
				}
				else{
					firstQuery = false;
				}
			}
			tempSection=section;
		}
		catch(exception e){
			Global_Error__c ge = Error_Handling.handleError('', 'GradebookController', 'retrieveStudentGrades', e);
			insert ge;
			Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'There was an error returning the grades. Please contact your administrator.'));
			return null;
		}

		//final sort - JW
		list<string> headerOrder = new List<String>(); //set up a key that will order the grades

		if(standardDisplayString == 'true'){
			for(GradebookWrapper.cStandardWrapper g: gradebookObj.header.standardWrapperList){
				for(Grade__c g1: g.gradeList){
					headerOrder.add(string.valueOf(g1.Assignment__c) + string.valueOf(g1.Standard__c) + string.valueOf(g1.Assignment__r.Due_Date__c));
				}
			}
			for(GradebookWrapper.cStudentWrapper g: GradebookObj.studentWrapperList){
				for(GradebookWrapper.cStandardWrapper aw: g.standardWrapperList){
					map<String, Grade__c> orderMap = new Map<String, Grade__c>();
					List<Grade__c> orderedGradeList = new List<Grade__c>();
					for(Grade__c gr : aw.gradeList){
						orderMap.put(string.valueOf(gr.Assignment__c) + string.valueOf(gr.Standard__c) + string.valueOf(gr.Assignment__r.Due_Date__c),gr);
					}
					for(String o : headerOrder){
						if(orderMap.containsKey(o)){
							orderedGradeList.add(orderMap.get(o));
						}
					}
					aw.gradeList.clear();
					aw.gradeList.addAll(orderedGradeList);
				}

			}
		}
		//DE754
		if(GradebookObj.studentWrapperList.size() == 0) {
			Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'No assignments to display.'));
		}

		return null;
	}

	public void removeBadStudents(){
		Integer i = 0;
		Map<Integer, Integer> sizeMap = new Map<Integer, Integer>();
		String warning = 'The following Students have an incorrect number of grade records: ';
		Set<ID> removeSet = new Set<ID>();
		for(GradebookWrapper.cStudentWrapper sw:gradebookObj.studentWrapperList){
			if(i==0){
				sizeMap.put(sw.gradeListSize,1);
			}
			else{
				if(sizeMap.containskey(sw.gradeListSize)){
					sizeMap.put(sw.gradeListSize,sizeMap.get(sw.gradeListSize)+1);
				}
				else{
					sizeMap.put(sw.gradeListSize,1);
				}
			}
			i++;
		}
		if(sizeMap.size()>1){
			Integer max = 0;
			Integer key = 0;
			for(Integer t:sizeMap.keyset()){
				if(sizeMap.get(t)>max){
					max = sizeMap.get(t);
					key = t;
				}
			}
			sizeMap.remove(key);
			Integer x = 0;
			for(GradebookWrapper.cStudentWrapper sw:gradebookObj.studentWrapperList){
				if(sizeMap.containskey(sw.gradeListSize)){
					if(x==0){
						warning+=sw.student.Name;
					}
					else{
						warning+=', '+sw.student.Name;
					}

					gradebookObj.swMap.remove(sw.student.Id);
					x++;
				}
			}
			if(x>0){
				warning += '. Please contact your system administrator for further instruction.';
				gradebookObj.studentWrapperList = gradebookObj.swMap.values();
				Apexpages.addMessage(new apexpages.message(apexpages.severity.warning, warning));
			}
		}
	}

	public void checkStandards(Grade__c g){
		if (!gradeBookObj.bHasStandards && g.Standard__c!=null){
			gradeBookObj.bHasStandards = true;
		}

	}

	public void processGbStyles(GradebookWrapper gbOb,id StudentId, integer y){
		if (y==0){
			if (gbOb.swMap.get(StudentId).gradeListSize < 12) iMainTableWidth = gbOb.swMap.get(StudentId).gradeListSize*iGradeColWidth;
			else iMainTableWidth=iGradeColWidth*iMaxGradeTabWidth;
			iRightLeft = 160+iMainTableWidth;
		}
		if (math.mod(y,2)==0) gbOb.swMap.get(StudentId).rowStyle='odd';
		else gbOb.swMap.get(StudentId).rowStyle='even';

		//commenting out NYC funcitonality

		if(gbOb.swMap.get(StudentId).sectionGrade.Grade__c>=baseObj.dPassingGrade) gbOb.swMap.get(StudentId).sectGradeStyle='ontrack';
		else if(gbOb.swMap.get(StudentId).sectionGrade.Grade__c<baseObj.dPassingGrade && gbOb.swMap.get(StudentId).sectionGrade.Grade__c>=baseObj.dFailingGrade) gbOb.swMap.get(StudentId).sectGradeStyle='passing';
		else gbOb.swMap.get(StudentId).sectGradeStyle='failing';

		//8/20/2012, commented out, uncommenting above
		/*
			if(gbOb.swMap.get(StudentId).sectionGrade.Grade__c>=baseObj.dPassingGrade) gbOb.swMap.get(StudentId).sectGradeStyle='passing';
			else gbOb.swMap.get(StudentId).sectGradeStyle='failing';
			*/
	}


	public void errorProcess(){
		String msg = errorMsg;
		integer parser = msg.indexOf(',');
		if(parser>0){
			msg		= msg.substring(parser+1);
		}
		integer parser2 = msg.indexOf(':');
		if(parser2>0){
			msg		= 'ERROR: ' + msg.substring(0, parser2);
		}
		Apexpages.addMessage(new apexpages.message(apexpages.severity.error, msg));
	}

	public void pullGrades(Id section, Id timeperiod){
		//US 1334: added Student's primary language field and Comments & alt. comments fields in the query
		//US1284 quarters
		//NYC DE1839/US1989 Do Not Show in Portal: added the new field to query: Do_Not_Show_in_PGV__c
		for(Section_Grade__c sg : [select s.ID, s.Standard_Section_Grade_v2__c, s.Credit_No_Credit_Section_Grade__c, s.Name, s.Time__c, s.Student_Section__r.Student__c, s.Grade_Overridden__c, s.Student_Section__c, s.Student_Section__r.Section__c, s.Grade__c, s.Letter_Grade__c, s.Student_Section__r.Student__r.Home_Language__c, s.Alternate_Lang_Comments__c, s.Comments_Next_Steps__c, Do_Not_Show_in_PGV__c, Display_Grade_Formula__c From Section_Grade__c s
		where (s.Student_Section__r.Section__c = :section AND s.Time__c = :timeperiod AND ((s.Student_Section__r.Archived__c = false AND s.Student_Section__r.Active__c = true) OR (s.Student_Section__r.Archived__c = true AND s.Student_Section__r.Active__c = false)) AND (RecordTypeID = null OR RecordType.Name = 'Quarter'))]){
			Decimal sectiongrade = sg.Grade__c;
			//DE2323
			if(sectiongrade != null) {
				sectiongrade = sectiongrade.Divide(100,4)*100;
			}
			gradebookObj.sectGradeMap.put(sg.Student_Section__r.Student__c, sg);
		}
	}

	public void getStudentAttendanceInfo(){
		Section__c thisSection = [select record_Attendance__c, daily_attendance__c from Section__c where id=:section];
		totalAttendance = new List <Attendance__c>();
		if (baseObj.activeSetup.Use_Sectional_Attendance__c)
		{
			system.debug('yes to use sectional');
			if (thisSection.record_Attendance__c){
				for (Attendance__c att: [SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Session__r.Section__c = :section ]){
					totalAttendance.add(att);
				}
			}
		}
		else
		{
			if (thisSection.record_Attendance__c){
				for (Attendance__c att: [SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Session__r.Section__c = :section ]){
					totalAttendance.add(att);
				}
			}
			else {
				setupDailyAttendance();
			}
		}
		studentAttendanceMap = new Map<Id, List<Attendance__c>>();
		for (Attendance__c curr: totalAttendance)
		{
			List<Attendance__c> studAttend = studentAttendanceMap.get(curr.Student__c);
			if (studAttend == null)
			{
				studAttend = new List<Attendance__c>();
				studentAttendanceMap.put(curr.Student__c, studAttend);
			}
			studAttend.add(curr);
		}

	}

	public void setupDailyAttendance(){
		Set <Id> studIds = new Set <Id>();
		for (GradebookWrapper.cStudentWrapper stud: GradebookObj.studentWrapperList ){
			studIds.add(stud.student.id);
		}
		for (Attendance__c att:[SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Student__c in:studIds and Daily__c =true]){
			totalAttendance.add(att);
		}
	}

	public void processStudentAttendanceInfo(GradebookWrapper.cStudentWrapper sw){
		integer numSessions = 0;
		integer numUnexcused = 0;
		integer numTardy = 0;
		List<Attendance__c> studAttendance = studentAttendanceMap.get(sw.student.id);
		if (studAttendance != null)
		{
			for (Attendance__c att: studAttendance)
			{
				++numSessions;
				if (att.Picklist_Value__r.Is_Tardy__c)
				++numTardy;

				if (att.Picklist_Value__r.Category__c == 'Absent')
				++numUnexcused;
			}
			sw.totalSessions = numSessions;
			sw.absentSessions = numUnexcused;
			sw.tardySessions = numTardy;
		}
	}



	public List<GradebookWrapper.cStudentWrapper> sortWrapperList(List<GradebookWrapper.cStudentWrapper> pList){
		// utility lists
		List<String> names				= new List<String>();			// list of student names
		List<GradebookWrapper.cStudentWrapper> retList = new List<GradebookWrapper.cStudentWrapper>(); // sorted list ready to be returned
		Map <String, GradebookWrapper.cStudentWrapper> studentWrapperMap = new Map<String, GradebookWrapper.cStudentWrapper>();


		// obtain the student's name
		for(GradebookWrapper.cStudentWrapper h : pList){
			string key = h.student.student_last_name__c+h.student.student_first_Name__c+h.student.id;
			names.add(key);		// add the student's name to the list for sorting purposes
			studentWrapperMap.put(key, h);
		}

		names.sort();	// sort the list of names

		// prepare the output data list to match the order of sorted name list
		for(String s : names) {
			retList.add(studentWrapperMap.get(s));
		}

		return retList;
	}

	global static Boolean isdecimal(String str){
		try{
			decimal temp = decimal.valueof(str);
			system.assertequals(temp/1, temp,'Invalid decimal');
		}
		catch(exception e){
			if(e.getmessage().contains('Invalid decimal')){
				return false;
			}
		}
		return true;
	}

	global static string updategradelist(String cmc){
		return null;
	}

	//US2346
	public List<String> timeMapValues() {
		List<String> temp = new List<String>();
		for(ID i : timeMap.keySet()) {
			//reformat the string
			String s1 = String.valueOf(timeMap.get(i).Date_Start_Date__c);
			List<String> s1split = s1.split('-');
			if(s1split[1].startsWith('0')) {
				s1split[1] = s1split[1].substring(1, s1split[1].length());
			}
			if(s1split[2].startsWith('0')) {
				s1split[2] = s1split[2].substring(1, s1split[2].length());
			}

			s1 = s1split[1] + '/' + s1split[2] + '/' + s1split[0];
			String s2 = String.valueOf(timeMap.get(i).End_Date__c);
			List<String> s2split = s2.split('-');
			if(s2split[1].startsWith('0')) {
				s2split[1] = s2split[1].substring(1, s2split[1].length());
			}
			if(s2split[2].startsWith('0')) {
				s2split[2] = s2split[2].substring(1, s2split[2].length());
			}
			s2 = s2split[1] + '/' + s2split[2] + '/' + s2split[0];
			temp.add(s1);
			temp.add(s2);
		}
		return temp;
	}

	//US2346
	public List<Id> timeMapKeySet() {
		List<Id> temp = new List<ID>();
		temp.addAll(timeMap.keySet());
		return temp;
	}

	//US2347
	public void changeRPOptions() {
		//clear the reportingperiod options and rebuild it
		baseObj.reportingPeriodOptions.clear();
		availableRPs.clear();

		for(Section_ReportingPeriod__c srp : [SELECT ID, Time__c, Time__r.Name__c, Time__r.Date_Start_Date__c, Time__r.End_Date__c FROM Section_ReportingPeriod__c WHERE Section__c =: section ORDER BY time__r.Name__c]) {
			baseObj.reportingPeriodOptions.add(new SelectOption(srp.Time__c, srp.Time__r.Name__c));
			availableRPs.add(srp.Time__c);
		}
	}

	//DE2148
	@RemoteAction
	//US2681: updated to account for 'Include_In_Standard_Grade__c'
	public static excludeErrorPassing excludeErrorMethod(String gid, String pA, String pB, String pC, String pD, String pE) {

		Grade__c getStudent = [SELECT ID, Student_Section__r.Student__c, Student_Section__c, Time__c, Entered_Grade__c FROM Grade__c WHERE ID =: gid];
		List<Grade__c> excludedGrades = [SELECT ID, Exclude_From_Section_Grade__c, Entered_Grade__c FROM Grade__c WHERE Student_Section__c =: getStudent.Student_Section__c AND Time__c =: getStudent.Time__c AND Faux_Grade__c = false];

		system.debug('excludedGrades.size: ' + excludedGrades);
		Integer excluded = 0;
		Integer total = 0;
		for(Grade__c g : excludedGrades) {
			if(g.Exclude_From_Section_Grade__c && g.Entered_Grade__c != null && g.Entered_Grade__c != '') {
				excluded++;
			}
			if(g.Entered_Grade__c != null && g.Entered_Grade__c != '') {
				total++;
			}
		}
		excludeErrorPassing obj = new excludeErrorPassing();
		obj.eeA = pA;
		obj.eeB = pB;
		obj.eeC = pC;
		obj.eeD = pD;
		obj.eeE = pE;
		if(excluded == total - 1 && pD == 'true') {

			obj.ee0 = 'true';
			return obj;
		}
		obj.ee0 = 'false';
		return obj;
	}

	//US2681: updated to account for 'Include_In_Standard_Grade__c'
	public class excludeErrorPassing
	{
		String eeA;
		String eeB;
		String eeC;
		String eeD;
		String eeE;
		String ee0;
	}

	//US3131
	//getter and setter functions
	private List<SelectOption> getIntegerAssignmentWeightingOptions() { //stolen from Gradebook_AssignmentController_v2
		List<SelectOption> returnList = new List<SelectOption>();
		for(Integer i = 1; i <= 10; i++) {
			returnList.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
		}
		return returnList;
	}

	private List<SelectOption> getColorOptions() { //stolen from Gradebook_AssignmentController_v2
		List<SelectOption> returnList = new List<SelectOption>();

		Schema.sObjectType assignment = Assignment__c.getSObjectType();
		Schema.DescribeSObjectResult assignmentDescribe = assignment.getDescribe();
		map<String, Schema.SObjectField> fieldMap = assignmentDescribe.fields.getMap();
		List<Schema.PicklistEntry> colors = fieldMap.get('Color__c').getDescribe().getPickListValues();

		//default value
		returnList.add(new SelectOption('', '--None--'));
		for(Schema.PicklistEntry color : colors) {
			returnList.add(new SelectOption(color.getValue(), color.getLabel()));
		}

		return returnList;
	}

	public List<SelectOption> getAssignmentTypeOptions(ID course) {
		List<SelectOption> returnList = new List<SelectOption>();
		Set<SelectOption> cleanupSet = new Set<SelectOption>();

		//generate the assignmentTypeOptions
		for(Default_Assignment_Weighting__c daw : [SELECT ID, Picklist_Value__c, Picklist_Value__r.Name, Default_Weighting__c, Course__c, Section__c FROM Default_Assignment_Weighting__c WHERE Course__c =: assignmentWrapper.assignmentCourse AND (Picklist_Value__r.Setup__c =: baseObj.activeSetup.ID OR Picklist_Value__r.Setup__c = null) ORDER BY Course__c, Picklist_Value__r.Name ASC]) {
			cleanupSet.add(new SelectOption(daw.Picklist_Value__c, daw.Picklist_Value__r.Name));

			//DE3505
			//populate the defaultAssignmentWeighting
			//generate key = courseID + DAW
			String Key = String.valueOf(daw.Course__c) + String.valueOf(daw.Picklist_Value__c);
			if(!defaultAssignmentWeighting.containsKey(key)) {
				defaultAssignmentWeighting.put(key, (Integer)daw.Default_Weighting__c);
			}
		}
		returnList.addAll(cleanupSet);
		return returnList;
	}

	public void getScaleOptions() {
		List<Grade_Scale_Catalog_Scale__c> gscs = [Select ID,
		Picklist_Value__c,
		Picklist_Value__r.Set_as_default__c,
		Picklist_Value__r.Number__c,
		Picklist_Value__r.Level__c,
		Picklist_Value__r.Id,
		Picklist_Value__r.Category__c,
		Picklist_Value__r.Standard_Scale__c,
		Name,
		Picklist_Value__r.Name
		from Grade_Scale_Catalog_Scale__c where Grade_Scale_Catalog__c = :baseObj.activeSetup.Grade_Scale_Catalog__c order by picklist_value__r.name];
		for(Grade_Scale_Catalog_Scale__c pv: gscs){
			if(pv.Picklist_Value__r.Name == 'Points'||pv.picklist_value__r.category__c=='Points'){
				pointsGradeScaleID.add(pv.Picklist_Value__c);
			}

			if(pv.Picklist_Value__r.Category__c=='Standards'||pv.Picklist_Value__r.Standard_Scale__c){
				standardScaleOptions.add(new SelectOption(pv.Picklist_Value__c, pv.Picklist_Value__r.Name));
				standardScaleMap.put(pv.Picklist_Value__r.Name, pv.Picklist_Value__c);
			}
			else{
				if (pv.Picklist_Value__c!=null) {
					gradeScaleOptions.add(new SelectOption(pv.Picklist_Value__c, pv.Picklist_Value__r.Name));
				}
			}
		}
	}

	public void renderPointsField() {
		if(pointsGradeScaleID.contains(assignmentWrapper.gradeScale)) {
			rPoints = true;
			//DE3684: removed rInteger selection from the assignment grade scale level
			//rIntegers = false;
		}
		else {
			rPoints = false;
			//DE3684
			//rIntegers = usePercentage;
			assignmentWrapper.assignmentPossiblePoints = null;
		}
	}

	public void initializeQuickCreateAssignment() { //call this on section selection and openModal?
		//US3131
		try {
			assignmentWrapper = new Gradebook_AssignmentWrapper_v2(baseObj.activeSetup.Standards_Based_Grading__c, baseObj.activeSetup.Standards_ONLY_Gradebook__c);
			searchFeature = new searchStandards();
			system.debug('*~*~* baseObj.sectionMap.get(section): ' + baseObj.sectionMap.get(section));
			assignmentWrapper.assignmentCourse = baseObj.sectionMap.get(section).Course__c;
			Course__c queriedCourse = [SELECT ID, Grade_Scale_Lookup__r.Category__c, Grade_Scale_Lookup__r.Name, Grade_Scale_Lookup__c, Grade_Scale__c, Use_Assignment_Type_Percentages__c FROM Course__c WHERE ID =: assignmentWrapper.assignmentCourse];
			assignmentWrapper.courseName = baseObj.sectionMap.get(section).Course__r.Name;

			dueDate = ''; //reminder within range of the RP
			advanceAssignmentOptions = false;
			closeQuickCreate = false;
			quickCreateNew = false;
			currentReportingPeriodName = timeMap.get(baseObj.selectedTimeID).Name__c;

			//render logic
			if(!assignmentWrapper.standardOnly) {
				rGradeScale = true;
			}
			else {
				rGradeScale = false;
			}

			if(assignmentWrapper.standardBased && !assignmentWrapper.standardOnly) {
				rStandardScale = true; //write a method to set to false if No Standards are selected in hybrid state
			}
			else {
				rStandardScale = false; //else for traditional or for standardOnly, set based on Course or is null
			}

			if(assignmentWrapper.standardBased) {
				rStandards = true;
			}
			else {
				rStandards = false;
			}

			//this depends on the grade scale, will change on modal call
			assignmentTypeOptions = getAssignmentTypeOptions(assignmentWrapper.assignmentCourse);

			//DE3505
			//set the default based on the daw and change it all the time
			assignmentWrapper.assignmentWeighting = 1;

			if(assignmentTypeOptions.size() > 0) {
				String Key = String.ValueOf(assignmentWrapper.assignmentCourse) + String.valueOf(assignmentTypeOptions[0].getValue());
				if(defaultAssignmentWeighting.containsKey(Key)) {
					assignmentWrapper.assignmentWeighting = defaultAssignmentWeighting.get(Key);
				}
			}

			//set the gradeScale if standardOnly
			if(assignmentWrapper.standardBased && assignmentWrapper.standardOnly) {
				try {
					assignmentWrapper.gradeScale = standardScaleMap.get(queriedCourse.Grade_Scale_Lookup__r.Name);
					assignmentWrapper.standardGradeScale = standardScaleMap.get(queriedCourse.Grade_Scale_Lookup__r.Name);
					system.debug('*~*~* gradeScale: ' + assignmentWrapper.gradeScale);
					system.debug('*~*~* standardGradeScale: ' + assignmentWrapper.standardGradeScale);
				}
				catch(Exception e) { //legacy scale looking for assignment with Standards
					if(standardScaleMap.containsKey(queriedCourse.Grade_Scale_Lookup__r.Category__c)) {
						assignmentWrapper.gradeScale = standardScaleMap.get(queriedCourse.Grade_Scale_Lookup__r.Category__c);
						assignmentWrapper.standardGradeScale = standardScaleMap.get(queriedCourse.Grade_Scale_Lookup__r.Category__c);
						system.debug('*~*~* exception -> gradeScale: ' + assignmentWrapper.gradeScale);
						system.debug('*~*~* exception -> standardGradeScale: ' + assignmentWrapper.standardGradeScale);
					}
				} finally {
					if(assignmentWrapper.gradescale == null || assignmentWrapper.standardGradeScale == null){
						ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'The grade scale listed on this course is not of a standard type, or the grade scale is not a part of your grade scale catalog. Please have your administrator check your setup before continuing.'));
					}
				}
			} else if(queriedCourse.Grade_Scale_Lookup__c != null){
				assignmentWrapper.gradeScale = queriedCourse.Grade_Scale_Lookup__c;
				if(assignmentWrapper.standardBased && standardScaleMap.containsKey(queriedCourse.Grade_Scale_Lookup__r.Name)){
					assignmentWrapper.standardGradeScale = standardScaleMap.get(queriedCourse.Grade_Scale_Lookup__r.Name);
				}
			}
			//DE3684
			if(queriedCourse.Grade_Scale_Lookup__r.Category__c == 'Points') {
				rIntegers = false;
			}
			else {
				rIntegers = true;
			}
			//rIntegers = !queriedCourse.Use_Assignment_Type_Percentages__c;
			usePercentage = rIntegers;			
			renderPointsField();

		}
		catch(Exception e) {
			system.debug('*~*~* Failed initializing assignmentWrapper: ' + e.getMessage());
		}
	}

	public void populateGradebookName() {
		//provide gradebookName
		if(String.isEmpty(assignmentWrapper.gradebookName) && String.isNotEmpty(assignmentWrapper.assignmentName)) {
			if(assignmentWrapper.assignmentName.length() > 5) {
				assignmentWrapper.gradebookName = assignmentWrapper.assignmentName.substring(0,5);
			}
			else {
				assignmentWrapper.gradebookName = assignmentWrapper.assignmentName;
			}
		}
	}

	public Boolean validateSubmit() {
		if(String.isEmpty(assignmentWrapper.assignmentName)) {
			ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'There is no name for this assignment!'));
			return false;
		}
		//place validation on grade scales

		//vadiate entered date, and then place it in the assignmentWrapper
		try {
			Date tempDate;
			try {
				tempDate = Date.Parse(dueDate);

				//validate time frame
				if(tempDate < timeMap.get(baseObj.selectedTimeID).Date_Start_Date__c || tempDate > timeMap.get(baseObj.selectedTimeID).End_Date__c) {
					ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'The Due Date is not in range of the reporting period!'));
					return false;
				}
			}
			catch(Exception e) {
				if(String.isEmpty(dueDate)) {
					ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'A Due Date is blank!'));
				}
				else {
					ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'The Due Date: ' + dueDate + ' is malformed!'));
				}
				return false;
			}
			assignmentWrapper.sectionToDueDate.put((ID)section, tempDate);
		}
		catch(Exception e) {
			system.debug('*~*~* Error in sectionDueDates! dueDate is: ' + dueDate);
			return false;
		}

		//create the sectionToReportingPeriod
		if(baseObj.selectedTimeId != null) {
			assignmentWrapper.sectionToReportingPeriods.put((ID)section, baseObj.selectedTimeID);
		}
		else {
			return false;
		}

		//pull the standards
		assignmentWrapper.assignmentStandards = searchFeature.getSOSLSelectedStandards();
		assignmentWrapper.standardToUse = searchFeature.getSOSLStandardToInclude();

		if(assignmentWrapper.standardBased && assignmentWrapper.standardOnly) {
			if(assignmentWrapper.assignmentStandards.size() == 0) {
				ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'An SO school must have standards selected!'));
				return false;
			}
			if(assignmentWrapper.gradeScale == null || assignmentWrapper.standardGradeScale == null){
				ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'There is no grade scale selected for your assignment. The grade scale for this course has not been configured correctly. Please notify your system administrator.'));
				return false;
			}
		}
		else {
			//additional validation on gradeScale
			if(assignmentWrapper.gradeScale == null) {
				ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'An Assignment must have a grade scale!'));
				return false;
			}

			if(assignmentWrapper.standardGradeScale == null && assignmentWrapper.assignmentStandards.size() > 0) {
				ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'If standards are selected then a standard grade scale must be selected!'));
				return false;
			}
			
			if(rPoints) {
				if(String.isEmpty(assignmentWrapper.assignmentPossiblePoints)) {
					ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Please enter a valid point value!'));
					return false;
				}
				else {
					try {
						if(Integer.valueOf(assignmentWrapper.assignmentPossiblePoints) <= 0){
							ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Please enter a point value greater than 0!'));
							return false;
						}
					}
					catch(Exception e) {
						ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Please provide an integer value!'));
						return false;
					}
				}
			}
		}

		//general error
		if(String.isEmpty(assignmentWrapper.gradebookName)) {
			ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Please enter a gradebook Name between 0 and 5 characters!'));
			return false;
		}
		else if(assignmentWrapper.gradebookName.length() > 5) {
			ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'The gradebook Name is too long! Please shorten the gradebook Name.'));
			return false;
		}

		return true;
	}

	public void setDefaultAssignmentWeighting() {
		//DE3505 set the integer assignment weighting based on the DAW
		if(assignmentWrapper.assignmentCourse != null && assignmentWrapper.assignmentType != null) {
			String Key = String.valueOf(assignmentWrapper.assignmentCourse) + String.valueOf(assignmentWrapper.assignmentType);
			if(defaultAssignmentWeighting.containsKey(Key)) {
				assignmentWrapper.assignmentWeighting = defaultAssignmentWeighting.get(Key);
			}
		}
	}

	public void submit() {
		if(validateSubmit()) {
			assignmentWrapper.createAssignmentLibrary();
			assignmentWrapper.createAssignments();

			//setting the parameters to refresh to that selected assignment
			selectedAssignmentID = assignmentWrapper.assignmentID;
			singleassignment.add(new SelectOption(assignmentWrapper.assignmentID, assignmentWrapper.assignmentName));
			closeQuickCreate = true;

			if(assignmentWrapper.attachAssignment) {
				domain = ApexPages.currentPage().getHeaders().get('Host');
				fromGradeBook = ApexPages.currentPage().getParameters().get('fromGradeBook');
			}
		}
		else {
			system.debug('*~*~* Quick Assignment Creation failed; assignmentWrapper: ' + assignmentWrapper);
		}
	}

	public void submitAndNew() {
		submit();
		quickCreateNew = true;
	}
}