public class CT_SetupWizard_Utils {
	public static final ID SW_RECORD_TYPE = CT_core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('Setup_Wizard');
	public static final String NO_SETUP_MESSAGE = 'There is no setup information. Please return to the School Setup homepage to continue the setup process.';
	public static final String NO_FORWARD_MESSAGE = 'Not enough setup steps have been completed to use the previous/next buttons.  Please use the sidebar on the left to choose a setup step to complete.';
	public static final integer TERMS = 1;
	public static final integer SELECTIONS = 2;
	public static final integer TEMPLATES = 3;
	public static final integer CALENDAR = 4;
	public static final integer COURSE_CATALOG = 5;
	public static final integer ROOMS = 6;
	public static final integer STAFF = 7;
	public static final integer GROUP_CONFIG = 10;
	public static final integer SCHEDULE = 11;
	public static final integer STUDENT_SECTIONS = 13;
	public static final integer PUBLISH = 14;
	public static final integer ACTIVATION = 16;
	public static final integer FINISH = 17;

	/*
		Retrieves all schools that are currently in the org (record type = School).
		
		@return the list of schools
	*/
	public static List<Account> querySchools(){
		return [select name, billingState, billingCity, billingPostalCode, BillingCountry , billingStreet, phone, fax, Site__c from Account where recordType.name = 'School' order by Name];
	}
	
	/*
		Retrieves all year records that are currently in the org (picklist value = Year).
		
		@return the list of years
	*/
	public static List<Time_Element__c> queryYears(){
		return [SELECT Name__c, Picklist_Value__r.Name, Type__c, Id, End_Date__c, Date_Start_Date__c, Name_On_Report_Card__c 
			FROM Time_Element__c WHERE picklist_value__r.Name = 'Year' ORDER BY Date_Start_Date__c DESC];
	}
	
	/*
		Given an id, return the setup record with the Setup Wizard specific fields needed.
		
		@param setupId the id of the setup to retrieve
		@return the setup record with Setup Wizard specific fields
	*/
	public static Setup__c getSetupById(Id setupId){
		return [SELECT id, School__c, Using_Summer_School__c, Using_Gradebook__c, Using_Attendance__c, Using_Behavior__c, Using_Portal__c, Using_Points__c, Using_Student_Documents__c,
				Using_Meals__c, Using_Homework__c, Using_Assessments__c, School__r.Name, School__r.Reference_Id__c, Year__c, Year__r.Name__c, Term__c, Term__r.Name__c, Active__c,Verification_Status__c,
				Course_Catalog__c, Group_Based__c, Room_Dependent__c, Chronological_Periods__c, Data_Activated__c, Year__r.Date_Start_Date__c, School__r.ParentID, School__r.SDS_School__c
				FROM Setup__c WHERE id=:setupId];
	}
	
	/*
		Gets the setup wizard version of the EOY progress record (record type=Setup Wizard) for the given setup.
		If the EOY progress record hasn't been created, returns a new EOY progress for the setup.
		
		@param setup the setup to retrieve the EOY progress for
		@return the setup wizard EOY progress record
	*/
	public static EOY_Progress__c getEOYProgressRecord(Setup__c setup){
		try{
			return [SELECT School_Selections_Completed__c, Year__c, Gradebook_Type_Finalized__c,
				Gradebook_Wizard_Started__c, Gradebook_Wizard_Completed__c, Attendance_Wizard_Started__c, Attendance_Wizard_Completed__c,
				Behavior_Wizard_Started__c, Behavior_Wizard_Completed__c, Documents_Wizard_Started__c, Documents_Wizard_Completed__c
				FROM EOY_Progress__c WHERE Setup__c=:setup.id AND School__c=:setup.School__c AND Year__c=:setup.Year__c AND RecordTypeId=:SW_RECORD_TYPE];
		}
		catch(Exception e){
			EOY_Progress__c progress = new EOY_Progress__c(Setup__c=setup.id,School__c=setup.School__c,Year__c=setup.Year__c,RecordTypeId=SW_RECORD_TYPE);
			//insert progress; //throws dml error when used in constructors.
			return progress;
		}
	}
	
	/*
		Given a list of time elements, create a list of select options to represent them.
		
		@param reportingPeriods the list of time elements
		@return the time elements represented as select options for picklists
	*/
	public static List<SelectOption> getReportingPeriodOptions(List<Time_Element__c> reportingPeriods){
		List<SelectOption> reportingPeriodOptionList = new List<SelectOption>();
		if(reportingPeriods == null){
			return reportingPeriodOptionList;
		}
		for (Time_Element__c rp: reportingPeriods){
			reportingPeriodOptionList.add(new SelectOption(rp.id, rp.Name__c)); //Populates list of possible reporting periods
		}
		return reportingPeriodOptionList;
	}
	
	/*
		Returns a page reference of the current page.  This is used to refresh the setup wizard pages dynamically.
		
		@param setupId the id of the setup that is currently being set up
		@param failed indicates whether the action that was completed was a failure.  If true, adds a page parameter to 
						the refresh of failure => true.  In most cases, this should be false.
		@return the current page's refreshed page reference 
	*/
	public static PageReference refreshPage(Id setupId,boolean failed){
		String refreshURL = ApexPages.currentPage().getUrl();
		if(refreshURL.contains('?')) refreshURL = refreshURL.split('\\?')[0];
		PageReference p = new PageReference(refreshURL);
		p.getParameters().put('setupId',setupId);
		if(failed) p.getParameters().put('failed','true');
		p.setRedirect(true);
		return p;
	}
	
	/*
		Returns a page reference for the setup wizard home page.
		
		@return the homepage page reference
	*/
	public static PageReference goToSetupWizardHome(){
		PageReference pr = Page.CT_SetupWizard_Home;
		pr.setRedirect(true);
		return pr;
	}

	/*
		Returns a page reference for teh school setup wizard homepage for a given school and year.

		@param selectedSchool the id of the school
		@param selectedYear the id of the year
		@return the homepage page reference, or null if an error
	*/
	public static PageReference getSchoolSetup(ID selectedSchool, ID selectedYear){
		if(selectedSchool == null ){
			system.debug('no school selected');
			return null;
		}
		if(selectedYear == null){
			system.debug('no year selected');
			return null;
		}
		List<Setup__c> setupList = [SELECT id FROM Setup__c WHERE School__c=:selectedSchool AND Year__c=:selectedYear];
		Setup__c schoolSetup;
		if(setupList.size()==0){
			schoolSetup = new Setup__c(School__c=selectedSchool, Year__c=selectedYear);
			insert schoolSetup;
		} else if(setupList.size()==1){
			schoolSetup = setupList[0];
		} else{
			//DE3540
			//more than 1 setup, throw error
			String schoolName=[SELECT id, Name FROM Account WHERE id=:selectedSchool].Name;
			String yearName=[SELECT id, Name__c FROM Time_Element__c WHERE id=:selectedYear].Name__c;
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There are multiple setup objects for '+schoolName+' for the year '+yearName+'.  You may only have 1 setup record.  Please go to the Setup Object and delete any unwanted setups and try again.');
			return null;
		}
		return CT_SetupWizard_Utils.goToSchoolHome(schoolSetup.id);
	}
	/*
		Returns a page reference for publish page for a given school and year.

		@param selectedSchool the id of the school
		@param selectedYear the id of the year
		@return the homepage page reference, or null if an error
	*/
	public static PageReference getPublishSetup(ID selectedSchool, ID selectedYear){
		List<Setup__c> setupList = [SELECT id FROM Setup__c WHERE School__c=:selectedSchool AND Year__c=:selectedYear];
		Setup__c schoolSetup;
		if(setupList.size()==0){
			schoolSetup = new Setup__c(School__c=selectedSchool, Year__c=selectedYear);
			insert schoolSetup;
		} else if(setupList.size()==1){
			schoolSetup = setupList[0];
		} else{
			//DE3540
			//more than 1 setup, throw error
			String schoolName=[SELECT id, Name FROM Account WHERE id=:selectedSchool].Name;
			String yearName=[SELECT id, Name__c FROM Time_Element__c WHERE id=:selectedYear].Name__c;
			CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There are multiple setup objects for '+schoolName+' for the year '+yearName+'.  You may only have 1 setup record.  Please go to the Setup Object and delete any unwanted setups and try again.');
			return null;
		}
		return CT_SetupWizard_Utils.goToPublishSetup(schoolSetup.id);
	}

	public static PageReference goToPublishSetup(Id setupId){
		PageReference pr = Page.CT_core_PublishSetup;
		pr.getParameters().put('setupId',setupId);
		pr.setRedirect(true);
		return pr;
	}
	/*
		Returns a page reference for the school setup wizard home page for the given setup.
		
		@param setupId the id of the setup to return homepage
		@return the homepage page reference
	*/
	public static PageReference goToSchoolHome(Id setupId){
		PageReference pr = Page.CT_core_TermSetup_v2;
		pr.getParameters().put('setupId',setupId);
		pr.setRedirect(true);
		return pr;
	}

	public static PageReference goToSchoolHomeModified(Id setupId) {
		PageReference pr = Page.CT_setupwizard_home;
		pr.getParameters().put('setupId',setupId);
		pr.setRedirect(true);
		return pr;
	}
	
	/*
		Checks to see if the module setups for the given setup are complete.
		
		@param setupId the id of the setup to check completion
		@return true if module setups are complete, false otherwise
	*/
	public static boolean checkModuleSetupComplete(Id setupId){
		Setup__c setup = getSetupById(setupId);
		EOY_Progress__c progress = getEOYProgressRecord(setup);
		boolean complete = true;
		if(setup.Using_Attendance__c && !progress.Attendance_Wizard_Completed__c) complete = false;
		if(setup.Using_Behavior__c && !progress.Behavior_Wizard_Completed__c) complete = false;
		if(setup.Using_Gradebook__c && !progress.Gradebook_Wizard_Completed__c) complete = false;
		if(setup.Using_Student_Documents__c && !progress.Documents_Wizard_Completed__c) complete = false;
		//if(setup.Using_Assessments__c)
		//if(setup.Using_Homework__c)
		//if(setup.Using_Meals__c)
		//if(setup.Using_Points__c)
		//if(setup.Using_Portal__c)
		return complete;
	}
	
	public static PageReference goToSchoolStep(integer stepNo, boolean goForward, Setup__c setup){
		PageReference pr;
		if(stepNo==TERMS) pr = Page.CT_core_TermSetup_v2;
		else if(stepNo==SELECTIONS) pr = Page.CT_SchoolSetup_Selections;
		else if(stepNo==TEMPLATES) pr = Page.CT_core_ScheduleTemplate;
		else if(stepNo==CALENDAR) pr = Page.CT_ReportingPeriodCalendarView;
		else if(stepNo==COURSE_CATALOG) pr = Page.CT_core_CourseCatalogSetup;
		else if(stepNo==ROOMS){
			if(setup.Room_Dependent__c)
				pr = Page.CT_core_RoomCreate;
			else{
				if(goForward)
					return goToSchoolStep(STAFF,goForward,setup);
				else
					return goToSchoolStep(COURSE_CATALOG,goForward,setup);
			}
		}
		else if(stepNo==STAFF) pr = Page.CT_SchoolSetup_Staff;
		else if(stepNo==GROUP_CONFIG){
			if(setup.Group_Based__c)
				pr = Page.CT_core_GroupConfiguration;
			else{
				if(goForward)
					return goToSchoolStep(SCHEDULE,goForward,setup);
				else
					return goToSchoolStep(STAFF,goForward,setup);
			}
		}
		else if(stepNo==SCHEDULE){
			if(setup.Group_Based__c){
				pr = Page.CT_GroupAgendaView;
			}
			else{
				pr = Page.CT_scheduler_Grid;
			}
		}
		else if(stepNo==STUDENT_SECTIONS) {
			pr = Page.CT_SchoolSetup_StudentSections;
			pr.getParameters().put('type', 'Student Section');
		}
		else if(stepNo==PUBLISH) pr = Page.CT_core_PublishSetup;
		else if(stepNo==ACTIVATION) pr = Page.CT_SchoolSetup_ActivateData;
		else if(stepNo==FINISH) pr = Page.CT_SchoolSetup_Finish;

		if(pr!=null){
			pr.getParameters().put('setupId',setup.Id);
			pr.setRedirect(true);
		}
		return pr;
	}
	
	public static integer calculateStepLocation(Id setupId){
		Setup__c setup = getSetupById(setupId);
		if(checkTerm(setup)) return TERMS;
		else if(checkSelections(setup)) return SELECTIONS;
		else if(checkTemplates(setup)) return TEMPLATES;
		else if(checkCalendar(setup)) return CALENDAR;
		else if(checkCourseCatalog(setup)) return COURSE_CATALOG;
		else if(checkRooms(setup)) return ROOMS;
		else if(checkGroups(setup)) return GROUP_CONFIG;
		else if(checkSchedule(setup)) return SCHEDULE;
		else if(checkPublish(setup)) return PUBLISH;
		else if(checkActivation(setup)) return ACTIVATION;
		return 0;
	}
	
	public static boolean checkTerm(Setup__c setup){
		if(setup.Term__c==null) return true;
		else{
			List<Time_Element__c> reportingPeriods = CT_core_SoqlUtils.getTimeElementsByTerm(setup.Term__c,true);
			if(reportingPeriods.size()==0) return true;
		}
		return false;
	}
	
	public static boolean checkSelections(Setup__c setup){
		EOY_Progress__c progress=getEOYProgressRecord(setup);
		if(!progress.School_Selections_Completed__c) return true;
		return false;
	}
	
	public static boolean checkTemplates(Setup__c setup){
		List<Time_Element__c> reportingPeriods = CT_core_SoqlUtils.getTimeElementsByTerm(setup.Term__c,true);
		System.debug('@@@ reportingPeriods: '+reportingPeriods);
		if(reportingPeriods.isEmpty()) return true;
		Time_Element__c firstRP = reportingPeriods[0];
		System.debug('@@@ firstRP: '+firstRP);
		List<Schedule_Template__c> st = [SELECT id FROM Schedule_Template__c WHERE Is_Master__c=true AND Has_Class__c=true AND Setup__c=:setup.id AND Reporting_Period__c=:firstRP.id limit 1];
		System.debug('@@@ st: '+st);
		if(st.size()==0) return true;
		return false;
	}
	
	public static boolean checkCalendar(Setup__c setup){
		List<Time_Element__c> reportingPeriods = CT_core_SoqlUtils.getTimeElementsByTerm(setup.Term__c,true);
		if(reportingPeriods.isEmpty()) return true;
		Time_Element__c firstRP = reportingPeriods[0];
		List<Schedule_Day__c> sd = [SELECT id FROM Schedule_Day__c WHERE Schedule_Template__r.Setup__c=:setup.id AND Reporting_Period__c=:firstRP.id limit 1];
		if(sd.size()==0) return true;
		return false;
	}
	
	public static boolean checkCourseCatalog(Setup__c setup){
		if(setup.Course_Catalog__c==null) return true;
		List<Course_Course_Catalog__c> ccc = [SELECT id, Course__r.Grade_Scale_Lookup__c FROM Course_Course_Catalog__c WHERE Course_Catalog__c=:setup.Course_Catalog__c];
		if(ccc.size()==0) return true;
		else{
			for(Course_Course_Catalog__c c: ccc){
				if(c.Course__r.Grade_Scale_Lookup__c==null) return true;
			}
		}
		return false;
	}
	
	public static boolean checkRooms(Setup__c setup){
		if(setup.Room_Dependent__c){
			List<Room__c> room = [SELECT id FROM Room__c WHERE School__c=:setup.School__c limit 1];
			if(room.size()==0) return true;
			return false;
		}
		return false;
	}
	
	public static boolean checkGroups(Setup__c setup){
		if(setup.Group_Based__c){
			List<Section__c> groups = [SELECT id FROM Section__c WHERE School__c=:setup.School__c AND Time__c=:setup.Year__c AND RecordTypeId=:CT_core_SoqlUtils.getRecordTypesBySObject('Section__c').get('Schedule_Group') limit 1];
			if(groups.size()==0){
				//addMessage(apexpages.severity.WARNING,'At least one schedule group must be created before moving on in the setup process.');
				return true;
			}
			return false;
		}
		return false;
	}
	
	public static boolean checkSchedule(Setup__c setup){
		List<Time_Element__c> reportingPeriods = CT_core_SoqlUtils.getTimeElementsByTerm(setup.Term__c,true);
		Time_Element__c firstRP = reportingPeriods[0];
		List<Scheduled_Section__c> ss = [SELECT id FROM Scheduled_Section__c WHERE Account__c=:setup.School__c AND Reporting_Period__c=:firstRP.id limit 1];
		if(ss.size()==0) return true;
		return false;
	}
	
	public static boolean checkPublish(Setup__c setup){
		List<Scheduled_Section__c> ss = [SELECT id FROM Scheduled_Section__c WHERE Account__c=:setup.School__c AND Reporting_Period__r.Parent_Time_Element__c=:setup.Term__c AND Needs_Publish__c=true limit 1];
		List<HoldingObj__c> ho = [SELECT id FROM HoldingObj__c WHERE School_DBN__c=:setup.School__r.Reference_Id__c AND School_Year__c=:setup.Year__r.Name__c AND Propagated__c=false limit 1];
		System.debug('\n\n ss => ' + ss+ '\n');
		System.debug('\n\n ss.size() => ' + ss.size() + '\n');
		System.debug('\n\n ho => ' + ho + '\n');
		System.debug('\n\n ho.size() => ' + ho.size() + '\n');
		if(ss.size()>0 || ho.size()>0) return true;
		return false;
	}
	
	public static boolean checkActivation(Setup__c setup){
		if(!setup.Data_Activated__c) return true;
		return false;
	}
	
	public static void addMessage(ApexPages.Severity severity, String msg){
		ApexPages.addMessage(new ApexPages.Message(severity, msg));
	}
	
}