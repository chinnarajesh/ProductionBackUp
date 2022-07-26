public with sharing class Homework_HomeworkController {

	/* PAGE CONTROLS */
	public boolean bFatalError	{get;set;} //Setup error. Hides all but error
	public boolean bDataError	{get;set;} //User data error. Hides data section
	

	/* PAGE VARIABLES */
	public List<SelectOption>	sectList	{get;set;} //List of Sections available to Teacher
	public List<SelectOption>	statusList	{get;set;} //List of HW Status values - based on Picklist Value Object
	public List<studentwrap>	swrap		{get;set;} //List of students for display
	public List<coursewrap>		cwrap		{get;set;} //List of courses for display
	public HW_Tracker__c		dueDate		{get;set;} //used as a due date holder

	/* PRIVATE STOREAGE VARIABLES */
	private core_BaseInfo_v2.cSchool_BaseInfo baseObj; //core school info object
	private Id SchoolId; //current school id NEEDED?
	private Id ReportingPeriodId; //current reporting period
	private Map<Id, Section__c>  allSections; //map of all sections for user
	private Set<Id> noRespCenter = new Set<Id> (); //picklist values that don't require resp center
	private boolean checksectype = false;
	private Set <Id> sectionIDs = new Set <Id>();
	private Map<String, Student__c> studentmap;
	private Map<Id, List<HW_Tracker__c>> StudentHWMap;
	private Map<Id, Map<String, Student_Section__c> > StudentCourseMap; //For each Student Id - Map of Course and Section for that Course
	public Map<String, Map<Id, String> > CourseSectionMap {get;set;}
	private Map<Id, List<HW_Tracker__c>> SectionHWList;
	private Map<Id, Section__c> sectiondisplaymap {get;set;}

	/* SORTING HELPERS */
	private Set<Id> CoursestoSort;
	private List<String> sortCourses; //used to sort variables


	//Default HW Status - e.g. Complete
	Public ID defaultStatusId {get;set;} 
	//Absent Value - we store here to we can set when absent cb is set
	Public ID absentStatusId {get;set;} 

	//Page Param Variables
	public Id newsectionId {get; set;}
	public Id pagerefstudentId {get; set;}
	public Boolean bAbsentStatus {get;set;}
	public String section {get;set;}

	/* CONSTRUCTOR */
	public Homework_HomeworkController() {
		statusList = new List<SelectOption>();
		allSections = new Map<Id, Section__c>();
		dueDate = new HW_Tracker__c(Due_Date__c = system.today());
		sectList = new List<SelectOption>();
		bFatalError = false;

		//get information on current user and school
		try {
			core_BaseInfo_v2.initBaseInfo();
			baseObj=core_BaseInfo_v2.baseInfoObj;
			SchoolId = baseObj.activeSetup.School__c;
		} catch(Exception e) {
			bFatalError = true;
			errorMessage('User: '+userInfo.getFirstName()+' '+userInfo.getLastName()+' is not associated with a staff record. Therefore there are no available sections.');
		}

		//Set up Picklist Values
		List< Picklist_Value__c> plValues = core_SoqlUtils.getPlValuesList('Homework', baseObj.activeSetup.Id);
		if(plValues.isEmpty()){
			errorMessage('Error: There are no options for homework status.');
			bFatalError = true;
		} else {
			for (Picklist_Value__c pv: plValues){
				if (pv.Category__c == 'Absent'){
					NoRespCenter.add(pv.Id);
					absentStatusId = pv.Id;
				}
				if(pv.Set_as_Default__c){
					defaultStatusId = pv.Id;
					NoRespCenter.add(pv.Id);
				}
				statusList.add(new SelectOption(pv.Id, pv.Name));
			}
		}

		//load section lists for user
		if(baseObj.sectionList.isEmpty()) {
			sectList.add(new SelectOption('-None-', 'No sections found.'));
		} else {
			sectList = new List<SelectOption>();
			for (Section__c sect:  baseObj.sectionList){
				if (sect.Active__c && (sect.has_homework__c || (sect.Homeroom__c || sect.Advisory__c))) {
					allSections.put(sect.Id, sect);
					sectionIds.add(sect.id);
					sectList.add(new SelectOption(sect.Id, sect.Name));
				}
			}
			if (sectList.size() > 0 ){
				sortList(sectList);
				sectList.add(0, new SelectOption('-None-', '- None -'));
			} else {
				sectList.add(new SelectOption('-None-', 'No sections found.'));
			}
		}
	} //end constructor

	//Load all data (tied to go button on page)
	public pagereference gethwdata(){
		bDataError = false;
		try {
			CoursestoSort = new Set<Id>();
			SectionHWList = new Map<Id, List<HW_Tracker__c>>();
			StudentHWMap = new Map<Id, List<HW_Tracker__c>>();
			sectiondisplaymap = new Map<Id, Section__c>();
			studentmap = new Map<String, Student__c>();
			swrap = new List<studentwrap>();
			cwrap = new List<coursewrap>();
			CourseSectionMap  = new Map<String, Map<Id, String>>();
			StudentCourseMap = new Map<Id, Map<String, Student_Section__c>>();

			Map<String,HW_Tracker__c> existinghwtrecords = new Map <String, HW_Tracker__c> ();

			//user needs to pick a section
			if (section != null && section == '-None-'){
				errorMessage('Please select a section.');
				bDataError = true;
				return null;
			}
			
			List<Time_Element__c> teList = Homework_SoqlUtils.getDueReportingPeriod(dueDate.Due_Date__c);
			if(!teList.isEmpty()){
				ReportingPeriodId = teList[0].id;
			} else {
				errorMessage('The date you selected is not part of any reporting period. Please check the date and try again.');
				bDataError = true;
				return null;
			}
			boolean isHomeroom = false;
			if (allSections.get(section).Homeroom__c && allSections.get(section).Advisory__c){
				isHomeroom = true;
			}

			for (Student__c s: Homework_SoqlUtils.getStudentList(isHomeroom, section)){
				//create empty map in case a student in Homeroom has no sections with Homework
				Map <String, Student_Section__c> scoursemap = new Map <String, Student_Section__c>();
				StudentCourseMap.put(s.Id, scoursemap);

				//put student record in Student Map
				studentmap.put(s.Student_Last_Name__c + s.Student_First_Name__c + s.Id, s);

				//For each section the current student is on, add them to the Student - HW Map
				for (Student_Section__c ssc : s.Student_Section__r) {
					//We'll requery for courses at the end to sort correctly...just build unique list for now
					CoursestoSort.add(ssc.Section__r.Course__c);
					//We'll use existing fields on section to control logic on page - has hw to assign new HW, is active to lock when already assigned
					//Sectiondisplaymap lists all sections for each course, so one course can display multiple sections in a single column
					sectiondisplaymap.put(ssc.Section__c,new Section__c(Name = ssc.section__r.name,Has_Homework__c= false, Active__c = false));

					//Is student in map already? If so, get list, otherwise, create new list
					if (!StudentCourseMap.containskey(s.Id) ) {
						scoursemap = new Map <String, Student_Section__c>();
					} else {
						scoursemap = StudentCourseMap.get(s.id);
					}

					scoursemap.put(ssc.Section__r.Course__r.Name, ssc);
					StudentCourseMap.put(s.Id, scoursemap);

					//Now also Build Unique Course to Section[ ] Map
					Map<Id, String> cmap;
					if (CourseSectionMap.containskey(ssc.Section__r.Course__r.Name) ) {
						cmap = CourseSectionMap.get(ssc.Section__r.Course__r.Name);
					} else {
						cmap = new Map<Id, String> ();
					}
					cmap.put(ssc.section__c, ssc.section__r.name);
					CourseSectionMap.put(ssc.Section__r.Course__r.Name, cmap);
				}
			} //end Student__c iteration


			//sort CourseDisplayMap - uses value on Course
			sortCourses = new List<String> ();
			Map<String, String> courseIdMap = new Map<String, String>();
			for (Course__c c: [Select Id, Name from Course__c WHERE Id IN :CoursestoSort order by Display_Order__c ASC, Name ASC] ) {
				sortCourses.add(c.Name);
				courseIdMap.put(c.Name, c.ID);
			}

			Set<Id> sectionswithhw = new Set<Id> ();
			List<HW_Tracker__c> hwList = Homework_SoqlUtils.getHomework(dueDate.Due_Date__c, section);

			//Select all existing HW tracking records for selected date and students
			for (HW_Tracker__c h: hwList) {
				existinghwtrecords.put(String.valueof(h.Student__c) + String.valueof(h.Student_Section__c), h);
				//Also, lock any sections that have HW from available list to select
				sectionswithhw.add(h.Student_Section__r.Section__c);
			}

			//Build Course - Section Display Map
			for (String s : sortCourses) {
				List<Section__c> csections = new List<Section__c> ();

				for (Id cs: CourseSectionMap.get(s).keyset() ) {
					Section__c ns = new Section__c(Id = cs, Name = CourseSectionMap.get(s).get(cs), has_homework__c = FALSE, Active__c = FALSE);
					if (sectionswithhw.contains(ns.Id)) {
						ns.has_homework__c = true;
						ns.Active__c = true;
					}
					csections.add(ns);
					sectiondisplaymap.put(ns.Id,ns);
				}

				cwrap.add(new coursewrap(s,  csections, courseIDMap.get(s)));
			}

			//Loop through each student and find if they have a section for this each course on the page
			for (Id sid: StudentCourseMap.keyset() ) {
				Map<String, Student_Section__c> thisstudentscoursemap = StudentCourseMap.get(sid);
				List<HW_Tracker__c> shwt = new List<HW_Tracker__c> ();
				//for each student, we check to see if they should have HW created for that course
				for (String s: sortCourses) {
					if(thisstudentscoursemap.containskey(s)){
						String skey = String.valueof(sid) + String.valueof(thisstudentscoursemap.get(s).Id);
						HW_Tracker__c newhw;
						if (existinghwtrecords.containskey(skey)) {
							newhw = existinghwtrecords.get(skey);
							shwt.add(newhw);
						} else {
							//if not, but they are on section with HW, create a record we can then update
							newhw = new HW_Tracker__c(Student_Section__c = thisstudentscoursemap.get(s).Id
														,Student_Section__r = thisstudentscoursemap.get(s)
													  ,Student__c = sid, Picklist_Value__c = null
													  ,Due_Date__c = dueDate.Due_Date__c
													  ,Time__c = ReportingPeriodId
													  ,Responsibility_Center__c = system.today());

							shwt.add(newhw);
						}

						List<HW_Tracker__c> sectionhw;
						if (SectionHWList.containskey(thisstudentscoursemap.get(s).section__c)) {
							sectionhw = SectionHWList.get(thisstudentscoursemap.get(s).section__c);
						} else {
							sectionhw = new List<HW_Tracker__c> ();
						}
						sectionhw.add(newhw);
						SectionHWList.put(thisstudentscoursemap.get(s).section__c, sectionhw);
					} else {
						//Otherwise, just add blank placeholder to ensure page renders with correct data columns
							shwt.add(new HW_Tracker__c(Picklist_Value__c = null));
					}
				}//end iteration over courses

					//Add to final map of Students with related KW Tracking records (should be one HW record per Course Column)
					StudentHWMap.put(sid, shwt);
			} //end iteration over student/Course map

			//Sort Students A-Z
			List<String> namesort = new List<String> ();
			namesort.addall(studentmap.keyset());
			namesort.sort();
			for (String s: namesort) {
				swrap.add(new studentwrap(studentmap.get(s), StudentHWMap.get(studentmap.get(s).Id), absentStatusId  ) );
			}
		} catch (Exception e){
			globalErrorMessage(null, 'Unexpected error during data retrival.', e, true);
			bDataError = true;
		}
		return null;
	} //end load data

	public pagereference abshomework () {
	List<HW_Tracker__c> newhws = StudentHWMap.get(pagerefstudentId);
		for (HW_Tracker__c hw: newhws) {
			if (hw.Picklist_Value__c != null){
				if (bAbsentStatus == false) {
					hw.Picklist_Value__c = absentStatusId;
				} else {
					hw.Picklist_Value__c = defaultStatusId;
				}
			}
		}
		return null;
	}

	//set all HW for a section has having HW when checked
	public void newhomework () {
		try {
			List<HW_Tracker__c> newhws = SectionHWList.get(newsectionid);

			Section__c secnewhw = sectiondisplaymap.get(newsectionid);
			if (secnewhw.has_homework__c){
				for (HW_Tracker__c hw: newhws) {
					hw.Picklist_Value__c = defaultStatusId;
				}
			} else {
				system.debug('Turning off homework.');
				//set all HW for a section has not having HW when un-checked
				for (HW_Tracker__c hw: newhws) {
					hw.Picklist_Value__c = null;
				}
			}
		} catch (Exception e) {
			globalErrorMessage(null, 'Unexpected error during homework creation', e, true);
		}
	}

	//execute save function
	public pagereference saverecords() {
		executesave();
		PageReference pref = Page.Homework;
		pref.setredirect(true);
		return pref;
	}

	//to save the comment, touch the controller, but that's all the more we need to do.
	public pagereference commentSave() {
		return null;
	}

	public void executesave() {
		try {
			List <HW_Tracker__c> recordstosubmit = new List<HW_Tracker__c> ();

			for (studentwrap sw: swrap) {
				for (HW_Tracker__c hw: sw.shw) {
					if (hw.Picklist_Value__c != null){
						//For Page Rendering Efficieny, we preset the RC value - blank it out now if we don't need it
						if (NoRespCenter.contains(hw.Picklist_Value__c)) {
							hw.Responsibility_Center__c = null;
						}
						recordstosubmit.add(hw);
					}
				}
			}
			upsert recordstosubmit;
		} catch (Exception e) {
			globalErrorMessage(null, 'Unexpected error during save', e, true);
		}
	}

	//Uses merge sort to sort a list of select options
	private List<SelectOption> sortList(List<SelectOption> orig){
		if(orig.size() <= 1){
		return orig;
		}
		List<SelectOption> left = new List<SelectOption>();
		List<SelectOption> right = new List<SelectOption>();
		List<SelectOption> result = new List<SelectOption>();
		integer mid = orig.size()/2;

		for(integer i=0;i<mid;i++) {
			left.add(orig[i]);
		}
		for(integer i=mid;i<orig.size();i++) {
			right.add(orig[i]);
		}

		left = sortList(left);
		right = sortList(right);
		result = mergeSort(left, right);
		return result;
	}
	/*
		Helper method for above sortList
		Merges the two lists together
	*/
	private List<SelectOption> mergeSort(List<SelectOption> left, List<SelectOption> right){
		List<SelectOption> result = new List<SelectOption>();
		while(left.size() > 0 || right.size() > 0){
			if(left.size() > 0 && right.size() > 0){
				if(left[0].getLabel() < right[0].getLabel()){
					result.add(left.remove(0));
				} else {
					result.add(right.remove(0));
				}
			} else if(left.size() > 0) {
				result.add(left.remove(0));
			} else if(right.size() > 0) {
				result.add(right.remove(0));
			}
		}
		return result;
	}

	private PageReference errorMessage(string message){
		ApexPages.getMessages().clear();
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,message));
		return null;
	}

	private void globalErrorMessage(string links, string info, Exception e, boolean pageError){
		Global_Error__c ge = Error_Handling.handleError('Section,' + section + ';' + links, 'Homework', info, e);
		insert ge;

		if(pageError){
			errorMessage(info);
		}
	}

	//to display students as required, we use a simple wrapper
	public class studentwrap {
		public Student__c			stud		{get;set;}
		public Integer				mcount		{get;set;} //number of late missing assignments
		public HW_Tracker__c		respcenter	{get;set;}
		public List<HW_Tracker__c>	shw			{get;set;}
		public Boolean				bAbsent		{get;set;}

		public studentwrap(Student__c s,  List<HW_Tracker__c> hw, Id absentStatusId) {
			
			mcount = 0;
			bAbsent = false;
			stud = s;
			if (s.of_Late_Homework__c == null) {
				s.of_Late_Homework__c = 0;
			}
			if (s.of_Missing_Homework__c == null) {
				s.of_Missing_Homework__c = 0;
			}
			mcount = Integer.ValueOf(s.of_Late_Homework__c) + Integer.ValueOf(s.of_Missing_Homework__c);
			for (HW_Tracker__c h: hw) {
				//if a current record has absent status, mark student as absent
				if ((h.Picklist_Value__c == absentStatusId) && (absentStatusId!=null)) {
					bAbsent = true;
					break;
				}
			}
			shw = hw;
		} //end constructor
	} //end wrapper

	//to display course/sections as required, we use a simple wrapper
	public class coursewrap{
		public String			scourse		{get;set;}
		public String			courseID	{get;set;}
		public List<Section__c>	sections	{get;set;}

		public coursewrap(String sc, List<Section__c> s, String cID){
			scourse = sc;
			sections = s;
			courseID = cID;
		} //end constructor
	} //end wrapper
} //end class