public with sharing class  CT_core_CourseCatalogController {
	
	public ApexPages.StandardController controller {get;set;}
	public boolean isManaged						{get;set;}
	
	/* DATA STORAGE FOR CATALOGS*/ 
	public CT_core_SetupWrapper			cSetup					{get;set;} //contains info for the current setup
	public List <Course_Catalog__c>		availableCatalogs		{get;set;} //a list of the avaiable course catalogs
	public Map <Id, Course_Catalog__c>	courseCatalogsMap		{get;set;} //a map of avaiable course catalogs
	public cCatalogWrapper				selectedCatalogWrapper	{get;set;} //contains info on the selected catalog
	public Course_Catalog__c			selectedCatalogElement	{get;set;} //the currently selected catalog
	
	/* DATA STORAGE FOR COURSES */
	public Course_Course_Catalog__c		selectedCourseCourseCat	{get;set;} //the link object between course and catalog
	public courseWrapper				selectedCourse			{get;set;} //contains information on the selected course
	public List<courseWrapper>			wrappedCourses			{get;set;} //a list of all the courses on the catalog
	public Map <Id, Course__c>			courseMap				{get;set;} //a map of all the courses on the catalog
   // public List<Course_Weightings__c>	courseWeightingsList	{get;set;} //a list of all course weightings avaiable
	
	/* PAGE PARAMS */
	public string setupId					{get;set;} //setup which is being edited
	public string selectedCatalogId			{get;set;} //course catalog that is being edited
	public string selectedCatForSetupId		{get;set;} //the catalog currently used by the setup
	public string selectedCourseId			{get;set;} //the course being edited
	public string selectedCourseCourseCatId	{get;set;} //the linking object between catalog and course
	public string courseSectionString		{get;set;} //the section that currently uses the selected course
	public string selectedTerm;						   //the term selected
	
	/* PAGE CONTROL */
	public boolean	bShowCatalogDetails		{get;set;} //show the edit page for a catalog (object edit, not course edit)
	public boolean	bConfigureCatalog		{get;set;} //show the course edit page for a catalog
	public boolean	bConfigureCatalogDates	{get;set;} //show the running dates for a course catalog
	public boolean	bShowCourseDetails		{get;set;} //show the details of a course
	public boolean	bConfigureCourse		{get;set;} //show the edit page for a course
	public boolean	bAddNewCourse			{get;set;} //show the add course page
   	public boolean	bEditCourse				{get;set;} //show the edit course page
   	public boolean	bConfigureWeightings	{get;set;} //show the weighting panel on the course edit page
   	public boolean	bAssWeightings	{get;set;} //show the assignment weighting panel on the course edit page
   	public boolean  bPercentWeightings	{get;set;}
   	public boolean	bAddCourse				{get;set;} //show the available courses modal
	public Map<Id,assignmentWeightWrapper> 		plMap		{get;set;}  //a map of assignment weights for courses
	public Map<ID,Default_Assignment_Weighting__c>	dawMap		{get;set;}  //a map of default assignement weights
	public List<assignmentWeightWrapper> 			plList		{get;set;} 	//a list of assingment weights linked to the setup
	public static  List <Picklist_Value__c> rpPlvList {get;set;}
	public Map <String, Id> courseRecordTypeMap;

	public List<SelectOption> gradeScaleOptionList	{get;set;}
	private Set<ID> pointsGradeScales;
	public Boolean bPointBasedCourse				{get;set;}
	  
	// Initialize the page variables
	public CT_core_CourseCatalogController(ApexPages.StandardController controller){
		try{
			isManaged = Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__');
			selectedCourseId = '';	
			bShowCatalogDetails=false;

			gradeScaleOptionList = new List <SelectOption>();
			pointsGradeScales = new Set<ID>();
			for (Picklist_Value__c plv: CT_core_GradeScaleCatalogController.getAvailableGrade_Scales()){
				gradeScaleOptionList.add(new SelectOption(plv.id, plv.name));
				if(plv.Category__c == 'Points')
					pointsGradeScales.add(plv.id);
			}
			plMap = new Map<Id, assignmentWeightWrapper>();
			plList = new List<assignmentWeightWrapper>();
			dawMap = new Map<ID,Default_Assignment_Weighting__c>();
			courseRecordTypeMap = CT_core_SoqlUtils.getRecordTypesBysObject('Course__c');
			if (System.currentPageReference().getParameters().containsKey('setupid')!=null) setupId = System.currentPageReference().getParameters().get('setupid');
			if (setupId!=null){
				cSetup= new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'course');
				selectedTerm = cSetup.setup.term__r.Reporting_Period_Value__r.Name;
				courseCatalogsMap = new Map<Id, Course_Catalog__c>();	
				returnAvailableCatalogs();
				if (cSetup.setup.Course_Catalog__c!=null){
					selectedCatalogId = cSetup.setup.Course_Catalog__c;
					returnCatalogDetails();
					bShowCatalogDetails=true;
				}
				else if (System.currentPageReference().getParameters().containsKey('ccid')) {
					selectedCatalogId = System.currentPageReference().getParameters().get('ccid');
					returnCatalogDetails();
					bShowCatalogDetails=true;
				}
				verifyCatalog();
			}
			bConfigureCourse= false;
			bAddCourse = false;
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was a problem initailizing the page.'));
		}
	}
	//Initialize the page variables
	 

	//Gets all available catalogs in the system
	public void goBack(){
		bShowCatalogDetails=false;
		bConfigureCatalog = false;
		returnAvailableCatalogs();
	}

	//save the course catalog to the setup record
	public void saveSetup(){
	 	try{System.debug('----$$selectedCatalogId$$$$'+selectedCatalogId);
			if (selectedCatalogId!=null){
		 		cSetup.setup.Course_Catalog__c=selectedCatalogId;
		 		System.debug('---- cSetup.setup$$$'+ cSetup.setup);
		 		update  cSetup.setup;
		 		cSetup= new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setupId),'course');
			}
	 	}
	 	catch(Exception e){
	 		ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error updating the course catalog on the setup record.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Course Catalog, '+selectedCatalogId, 'Course Catalog', 'error updating course catalog on setup', e);
			insert ge;
		}
	}

	//gather available course catalogs
	public void returnAvailableCatalogs(){
		availableCatalogs = new List <Course_Catalog__c>();
		for (Course_Catalog__c cat:  [ SELECT c.Name, c.Course_Catalog_Description__c, c.LastModifiedDate, c.CreatedDate, c.Course_Catalog_Status__c, c.id
									   FROM Course_Catalog__c c
									   WHERE c.Course_Catalog_Status__c = true
									   ]){
												
			courseCatalogsMap.put(cat.id, cat);
			availableCatalogs.add(cat);
		}
	}
	
	
	public static  List <Course_Course_Catalog__c> returnCourseCourseCatalogs(string catalogId){
		List <Course_Course_Catalog__c> ccList = new List <Course_Course_Catalog__c>();
		for (Course_Course_Catalog__c ccCat: [Select c.Course__r.Id, c.Course__r.Name, c.Course__r.Course_Notes__c
													,c.Course__r.Course_Number__c, c.Course__r.Department__c, course__r.description__c
													,c.Course__r.Credit_Hours__c ,  c.course__r.Grade_Scale_Lookup__c, c.course__r.Grade_Scale__c 
												From Course_Course_Catalog__c c
												where c.Course_Catalog__c =:catalogId]){
			ccList.add(ccCat);
		}
		return ccList;
	}
	
	public static List <Course__c> getAvailableCourses(){
		List <Course__c> courseList = [Select c.SystemModstamp, c.Subject_Area_Lookup__c, c.Reference_Id__c, c.OwnerId
											,c.Name, c.Legacy_ID__c, c.Id,  c.Multiply_GPA_Added_Value_Points__c, c.GPA_Added_Value_Points__c
											,c.Exclude_on_RC_Transcripts__c, c.Exclude_from_Honor_Roll__c, c.Exclude_from_GPA__c
											,c.Exclude_from_Class_Rank__c, c.Description__c, c.Department__c
											,c.Default_Maximum_Enrollment__c, c.Credit_Hours__c, c.CreatedDate, c.CreatedById
											,c.Course_Number__c, c.Course_Notes__c, c.Account__c, c.Type__c
											,c.Required_for_graduation__c, c.Min_of_enrollment__c, c.Max_of_enrollment__c
											,c.Has_a_lab__c, c.Grading_reporting_period_length__c, c.Meets_every_day__c
											,c.Display_Numerical_Values_On_Report_Card__c
											,c.Pre_requisites__c, c.Room_Type__c 
											,c.Use_Assignment_Type_Percentages__c 
											,c.Name_Spanish__c //US1309
											,c.Grade_Scale_Lookup__c
											,c.Grade_Scale__c 
											,c.Include_In_Section_Snapshot__c
										From Course__c c
										where Reference_Id__c !=null];
		return courseList; 
	}
	
	
	public static Course__c getCourseDetails(Id courseId){
		Course__c course= [Select c.Type__c,  c.Required_for_graduation__c, c.Pre_requisites__c
								,c.Name, c.Min_of_enrollment__c, c.Meets_every_day__c, c.Max_of_enrollment__c
								,c.Has_a_lab__c, c.Grading_reporting_period_length__c, c.Description__c
								,c.Department__c, c.Credit_Hours__c, c.Course_Number__c, c.Course_Notes__c
								,c.Room_Type__c, c.Has_Final_Grade__c, c.Number_of_Reporting_Periods__c
								,c.Weightings__c,c.Special_Subject__c,c.Homework_based__c 
								,c.Display_Numerical_Values_On_Report_Card__c,c.Multiply_GPA_Added_Value_Points__c
								,c.GPA_Added_Value_Points__c,c.Use_Assignment_Type_Percentages__c 
								,c.Name_Spanish__c,Exclude_on_RC_Transcripts__c,Subject_Area_Lookup__c
								,c.Grade_Scale_Lookup__c,Grade_Scale__c,c.Include_In_Section_Snapshot__c
								,c.Display_on_Student_Staff_Schedule__c
							From Course__c c 
							where c.id =: courseId];
		 return course;
	}

	public Integer getNumberOfSections(String courseId){
		Integer sectionsCount= [Select Count()
										From Section__c
										where Course__c = :courseId
										AND is_Section__c = true
										AND Active__c = true];
		return sectionsCount; 
	}
	
	public List<SelectOption> getSubjectAreas(){
		List<SelectOption> options = new List<SelectOption>();
		for (Course__c subject: [SELECT Name FROM Course__c WHERE RecordTypeId = :courseRecordTypeMap.get('Subject_Area')]){
			options.add(new SelectOption(subject.id, subject.Name));
		}
		return options;
	}
	//Gets all available catalogs in the system
	
	//Configure new catalog
	public void configureNewCatalog(){
		try{
			bConfigureCatalog = true;
			bShowCatalogDetails = false;
			bShowCourseDetails = false;
			selectedCatalogWrapper = new cCatalogWrapper(new Course_Catalog__c(course_catalog_status__c = true)); 
		} 
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was a problem configuring the new course catalog.'));
			Global_Error__c ge = CT_Error_Handling.handleError('', 'Course Catalog', 'problem configuring new catalog', e);
			insert ge;
		}
	}
	//Configure new catalog
	
	//Edit catalog
	public void editCatalogDetails(){
		try{
			bShowCatalogDetails = false;
			bConfigureCatalog = true;
			bShowCourseDetails = false;
			
			if (System.currentPageReference().getParameters().get('selectedCatalogId')!=null){
				selectedCatalogId = System.currentPageReference().getParameters().get('selectedCatalogId');
				selectedCatalogElement = courseCatalogsMap.get(selectedCatalogId);
				selectedCatalogWrapper = new cCatalogWrapper(selectedCatalogElement);
			}
		} catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was a problem initializing the edit page.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Course Catalog, '+selectedCatalogId, 'Course Catalog', 'error changing to edit page', e);
			insert ge;
		} 
	}
	//Edit catalog   

	// Remove catalog
	public void removeCatalogDetails(){
		try{
			bShowCatalogDetails =false;
			bConfigureCatalog = false;
			bShowCourseDetails = false;
			
			if (System.currentPageReference().getParameters().get('selectedCatalogId')!=null){
				selectedCatalogId = System.currentPageReference().getParameters().get('selectedCatalogId');
				List<Setup__c> setups = [SELECT id FROM Setup__c WHERE Course_Catalog__c=:selectedCatalogId];
				if(setups.size()==0){
					selectedCatalogElement = courseCatalogsMap.get(selectedCatalogId);
					delete selectedCatalogElement;
				}
				else{
					CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'This course catalog is currently in use by other setups and cannot be removed.');
				}
			}
	
			returnAvailableCatalogs(); //requery the database to setup the map for all
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error deleting the course catalog.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Course Catalog, '+selectedCatalogId, 'Course Catalog', 'error deleting course catalog', e);
			insert ge;
		}
	}
	//Remove catalog 
	
	// Return catalog
	 public void setCatalog(){
	 	try{
			if (System.currentPageReference().getParameters().get('selectedCatalogId')!=null||selectedCatalogId!=null){
				if (selectedCatalogId==null||selectedCatalogId=='') selectedCatalogId = System.currentPageReference().getParameters().get('selectedCatalogId');
				selectedCatalogElement = courseCatalogsMap.get(selectedCatalogId);
				selectedCatalogWrapper = new cCatalogWrapper(selectedCatalogElement);
			}
	 	}
	 	catch(Exception e){
	 		ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'The selected course catalog is not available.'));
	 		Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Course Catalog, '+selectedCatalogId, 'Course Catalog', 'problem setting course catalog', e);
	 		System.debug('Global Error: ' + ge);
			insert ge;
	 	}
	 }
	 
	public void returnCatalogDetails(){
		try{
			bConfigureCatalog = false;
			bShowCatalogDetails = true;
			
			setCatalog();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Catalog details were not retrieved successfully.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+setupId+'; Course Catalog, '+selectedCatalogId, 'Course Catalog', 'error retrieving catalog details', e);
			insert ge;
		}
	} 
	 
	// Edit course	 
	public void editCourseDetails(){
		try{
			bShowCatalogDetails = false;
			bConfigureCatalog = false;
			bShowCourseDetails = true;
			bAddNewCourse = false;
			bConfigureCourse= true;
			bEditCourse = true;
			courseSectionString = 'Edit Course';
			
			selectedCourseId = ApexPages.currentPage().getParameters().get('selectedCourseId');
			Integer numberOfSect = getNumberOfSections(selectedCourseId);
			System.debug('$$$courseSectionsMap$$$'+numberOfSect);
		 	selectedCourse = new CourseWrapper(getCourseDetails(selectedCourseId), true);

			 if(numberOfSect > 0){
				selectedCourse.isDisabled = true;
				System.debug('$$$selectedCoursep$$$'+selectedCourse);
			}
			else{
				selectedCourse.isDisabled = false;
				System.debug('$$$%%%%selectedCoursep$$$'+selectedCourse);	
			}
			if (selectedCourse.course.number_of_reporting_periods__c ==null ) selectedCourse.course.number_of_reporting_periods__c=1;
			selectedCourse.selectedRpNum = string.valueOf(selectedCourse.course.number_of_reporting_periods__c);
			initAssignmentWeightings();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error retrieving the selected course.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Course, '+selectedCourseId, 'Course Catalog', 'error setting course', e);
			insert ge;
		}
	}//Edit course


	//Saves information entered for the Term Config
	public void saveCatalogConfig(){
		try{
			upsert selectedCatalogWrapper.catalog;		
			returnAvailableCatalogs(); //requery the database to setup the map for all
			bConfigureCatalog = false;
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Could not save the course catalog.'));
			Global_Error__c ge; 
			if(selectedCatalogWrapper==null) ge = CT_Error_Handling.handleError('', 'Course Catalog', 'could not save catalog', e);
			else ge=CT_Error_Handling.handleError('Course Catalog, '+selectedCatalogWrapper.catalog.id, 'Course Catalog', 'could not save catalog', e);
			insert ge;
		}
	}
	
	public void addCourse(){
		try{
			//bConfigureCourse=true;
			bAddCourse = true;
			wrappedCourses = new List <courseWrapper>();
			for (Course__c c: CT_core_CourseCatalogController.getAvailableCourses()){
				if (!selectedCatalogWrapper.configuredCourseIds.contains(c.id)){
					wrappedCourses.add(new courseWrapper(c, false));
				}
		   	}
		}
		catch(Exception e){
			Global_Error__c ge = CT_Error_Handling.handleError('Course Catalog, '+selectedCatalogWrapper.catalog.id, 'Course Catalog', 'error setting course', e);
			insert ge;
		}
	}
	
	public void cancelAddCourses(){
		bAddCourse=false;
	}
	
	public void cancelCourse(){
		plMap.clear();
		plList.clear();
		bAddNewCourse=false;
		bEditCourse=false;
		bShowCatalogDetails = true;
		bConfigureWeightings = false;
		bConfigureCourse= false;
	}
	
	//Add New Course
	public void addNewCourse(){
		bAddNewCourse=true;
		bEditCourse = false;
		bConfigureCourse= true;
		bConfigureCatalog = false;
		bShowCatalogDetails=false;
		courseSectionString = 'Create New Course';
		selectedCourse = new courseWrapper( new Course__c(), true);
		selectedCourse.course.Include_In_Section_Snapshot__c = true;
		selectedCourse.course.Display_on_Student_Staff_Schedule__c = true;
		selectedCourseId = null;
		initAssignmentWeightings();
	}//Add New Course
	
	//Save New Course	
	public void saveNewCourse(){
		boolean bError = false;
		try{
		 	selectedCourse.course.grade_scale_Lookup__c = selectedCourse.selectedGradeScale;
		 	selectedCourse.course.number_of_Reporting_periods__c = integer.valueOf(selectedCourse.selectedRpNum);
		 	selectedCourse.course.Reference_Id__c = selectedCourse.course.Course_Number__c;

		 	if(selectedCourse.course.GPA_Added_Value_Points__c==null){
		 		selectedCourse.course.GPA_Added_Value_Points__c=0;
		 	}
			try {
				upsert selectedCourse.course;	
			}catch (exception e){
				bConfigureCourse=true;
				bError=true;
			}

			if(!bError){
				List<Course_Course_Catalog__c> cccs = [SELECT Course__c FROM Course_Course_Catalog__c WHERE Course_Catalog__c=:selectedCatalogId];
				Set<ID> courses = new Set<ID>();
				for(Course_Course_Catalog__c c: cccs) courses.add(c.Course__c);
				if(!courses.contains(selectedCourse.course.id)){
					Course_Course_Catalog__c ccc = new Course_Course_Catalog__c(course_catalog__c = selectedCatalogId, course__c = selectedCourse.course.id);
					try{
						insert ccc;
					} catch(exception e) {
						bError = true;
						bConfigureCourse=true;
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Database error: unable to save course/course catalog relationship.'));
						throw e;
					}
				}
			}
		}
		catch(Exception e){
			Global_Error__c ge;
			bError = true;
			if(selectedCourse!=null)ge = CT_Error_Handling.handleError('Course, '+selectedCourse.course.id+'; Course Catalog, '+selectedCatalogId, 'Course Catalog', 'unable to save course/course catalog relationship', e);
			else ge = CT_Error_Handling.handleError('Course Catalog, '+selectedCatalogId, 'Course Catalog', 'unable to save course/course catalog relationship', e);
			insert ge;
		}

		if (!bError){
			selectedCourseId = selectedCourse.course.id;
			system.debug('~~~~~ selectedCourse.course: '+selectedCourse.course);
			saveWeightings();
			saveDefaultAssignmentWeightings();
			if(selectedCourse.course.Use_Assignment_Type_Percentages__c){
				boolean percentageError = true;//if there are any assignment weightings with a percentage entered, this will go true and no error will occur
				for(Default_Assignment_Weighting__c daw : [select Id, Name, Course__c, Course__r.Use_Assignment_Type_Percentages__c, Picklist_Value__r.Name, Default_Weighting__c,Percent_Of_Section_Grade__c 
														 from Default_Assignment_Weighting__c 
														 where Course__c = :selectedCourseId AND Percent_Of_Section_Grade__c!= null]){
					percentageError=false;					 	
				}
				if(percentageError){
					CT_SetupWizard_Utils.addMessage(ApexPages.Severity.ERROR, 'You have selected to use assignment type percentages. Please make sure that values are entered in the Percentage of Section Grade field in the Edit Assignment Weightings window.');
					bError = true;
				}
			}
			if(!ApexPages.hasMessages()){
				bConfigureCourse=false;
				bAddNewCourse = false;
				bEditCourse = false;
				returnCatalogDetails();
			}
		}
	}//Save New Course

	//Add Course Weightings
	public void initAssignmentWeightings(){
		try{
			plMap.clear();
			plList.clear();
			for(PickList_Value__c pv:CT_core_SoqlUtils.getPlStringValues('Assignment Type', cSetup.setup.id).values()){
				plMap.put(pv.Id, new assignmentWeightWrapper(pv.Name,pv.Id));
			}

			if(selectedCourseId!=null){
				List<Default_Assignment_Weighting__c> weightingsToProcess = new List<Default_Assignment_Weighting__c>();
				Boolean inGlobalMode = true;
				for(Default_Assignment_Weighting__c daw:[select Id, Name, Course__c, Course__r.Use_Assignment_Type_Percentages__c, Picklist_Value__r.Name, Default_Weighting__c,Percent_Of_Section_Grade__c, Picklist_Value__r.Setup__c
														 from Default_Assignment_Weighting__c 
														 where Course__c = :selectedCourseId
														 and (Picklist_Value__r.Setup__c =: cSetup.setup.ID OR Picklist_Value__r.Setup__c = null)
														 and PickList_Value__c IN: plMap.keySet()
														 order by Picklist_Value__r.Name]){
					if(daw.Picklist_Value__r.Setup__c == null && inGlobalMode){
						weightingsToProcess.add(daw);
					} else if(daw.Picklist_Value__r.Setup__c != null){
						if(inGlobalMode){
							weightingsToProcess.clear();
						}
						inGlobalMode = false;
						weightingsToProcess.add(daw);
					}
				}

				for(Default_Assignment_Weighting__c daw:weightingsToProcess){
					if (plMap.containsKey(daw.Picklist_Value__c)){
						plMap.get(daw.Picklist_Value__c).useRecord = true;
			 			plMap.get(daw.Picklist_Value__c).weight = daw.Default_Weighting__c.format();
						plMap.get(daw.Picklist_Value__c).dawID = daw.Id;
						plMap.get(daw.Picklist_Value__c).percentWeight = daw.Percent_Of_Section_Grade__c;//JW assignment types with percentage weightings
						dawMap.put(daw.Id, daw);
					}
				}
			}
			plList = plMap.values();
		}
		catch(Exception e){
			String links = 'Course Catalog, '+selectedCatalogWrapper.catalog.id;
			if(selectedCourseId!=null) links += ';Course,'+selectedCourseId;
			Global_Error__c ge = CT_Error_Handling.handleError(links, 'Course Catalog', 'error initializing default assignment weightings', e);
			insert ge;
		}
	}
	
	
	public void addAssWeightings(){
		try{
			bAssWeightings = true;
			bPercentWeightings = selectedCourse.course.Use_Assignment_Type_Percentages__c;
			bPointBasedCourse = pointsGradeScales.contains(selectedCourse.selectedGradeScale);
		} catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There was an error loading the weightings panel.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Course, '+selectedCourseId, 'Course Catalog', 'error loading course weightings', e);
			insert ge;
		}
	}
	
	public void addWeightings(){
		bConfigureWeightings = true;
	}//Add Course Weightings
	
	//Save Course Weightings
	public void saveWeightings(){
		List <Course_Weightings__c> courseWeightingsList = new List <Course_Weightings__c>();
		List <Course_Weightings__c> deleteCourseWeightingsList = new List <Course_Weightings__c>();
		//EE 4/7 make sure that there are appropriate weightings for existing sections
		List<Section__c> sectionsForCourse=
			[SELECT id, Number_of_Reporting_Periods__c 
			FROM Section__c 
			WHERE Course__c=:selectedCourse.course.id
			AND (RecordType.Name = 'Published' or RecordType.Name='Unpublished')
			AND Course__c!=null AND Active__c=true];
		Set<String> rpInUse = new Set<String>();
		if(!sectionsForCourse.isEmpty()){
			for(Section__c sec: sectionsForCourse) rpInUse.add(sec.Number_of_Reporting_Periods__c);
		}
		//EE 4/8 course weightings are created when courses are inserted.  This can happen on creation of a new course.
		//To make sure duplicate weightings are not created, update base weightings here.
		List<Course_Weightings__c> weightings = [SELECT id, Key__c, Reporting_Period_Type__c FROM Course_Weightings__c WHERE Course__c=:selectedCourse.course.id];
		Map<ID,Map<String,Course_Weightings__c>> plToWeightings = new Map<ID,Map<String,Course_Weightings__c>>();
		for(Course_Weightings__c cw: weightings){
			if(plToWeightings.containsKey(cw.Reporting_Period_Type__c))
				plToWeightings.get(cw.Reporting_Period_Type__c).put(cw.Key__c,cw);
			else
				plToWeightings.put(cw.Reporting_Period_Type__c, new Map<String,Course_Weightings__c>{cw.Key__c=>cw});
		}
		//END VALIDATION
		for (courseWeightingConfigWrapper cwcw : selectedCourse.cwWrapper){
			//update base weightings
			if(plToWeightings.containsKey(cwcw.rpPlValue.id)){
				Map<String,Course_Weightings__c> existingWeightings = plToWeightings.get(cwcw.rpPlValue.id);
				for(courseWeightingWrapper cww: cwcw.weightingsList){
					if(existingWeightings.containsKey(string.valueOf(cww.iNum))) cww.baseWeighting = existingWeightings.get(string.valueOf(cww.iNum));
					if(existingWeightings.containsKey(cww.iNum+'-Final')) cww.finalWeighting = existingWeightings.get(cww.iNum+'-Final');
				}
			}
			if (cwcw.bInUse){
				decimal sumW = 0.00;
				for (courseWeightingWrapper weightWrap: cwcw.weightingsList ){
					if (weightWrap.baseWeighting==null || weightWrap.baseWeighting.id==null){
						if (weightWrap.iNum==null) weightWrap.iNum=0;
						weightWrap.baseWeighting=new Course_Weightings__c( Reporting_Period_Type__c=cwcw.rpPlValue.id, Course__c=selectedCourse.course.id, Weighting__c=weightWrap.iWeighting, Key__c=string.valueOf(weightWrap.iNum));
					}
					else {
						weightWrap.baseWeighting.Weighting__c=weightWrap.iWeighting;
					}
					courseWeightingsList.add(weightWrap.baseWeighting);	 
					system.debug('courseWeightingsList'+courseWeightingsList);
					sumW+=weightWrap.iWeighting;
					if (weightWrap.bHasFinal){
						if (weightWrap.finalWeighting==null || weightWrap.finalWeighting.id==null){
							weightWrap.finalWeighting=new Course_Weightings__c( Reporting_Period_Type__c=cwcw.rpPlValue.id,  Course__c=selectedCourse.course.id, Weighting__c=weightWrap.iFinalWeighting, Key__c=string.valueOf(weightWrap.iNum)+'-Final');
						}
						else {
							weightWrap.finalWeighting.Weighting__c=weightWrap.iFinalWeighting;
						}
						courseWeightingsList.add(weightWrap.finalWeighting);	 
						system.debug('courseWeightingsList'+courseWeightingsList);
						sumW+=weightWrap.iFinalWeighting;
					}
					else {
						system.debug('deleteWeighting~~~'+weightWrap.finalWeighting);
						if (weightWrap.finalWeighting!=null) deleteCourseWeightingsList.add(weightWrap.finalWeighting);
					}
				}
				if (sumW!=100){
					CT_SetupWizard_Utils.addMessage(ApexPages.Severity.ERROR, 'Weightings not saved: sum of weightings should be equal to 100 for each combination.  Please update weightings for '+cwcw.rpPlValue.Corresponding_Value__c+' reporting periods.');
				}
			}
			else {
				if(rpInUse.contains(String.valueOf(cwcw.rpPlValue.Corresponding_Value__c))){
					CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'There are active sections for this course using '+cwcw.rpPlValue.Corresponding_Value__c+' reporting periods.  Course weightings must be set up for this combination.  Please update weightings.');
				} else if(Integer.valueOf(selectedCourse.selectedRpNum) == cwcw.rpPlValue.Corresponding_Value__c){
					if(bEditCourse) CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The default number of reporting periods for a course must have weightings configured. There are no weightings configured for '+cwcw.rpPlValue.Corresponding_Value__c+' reporting period(s).  Course weightings must be set up for this combination. Please update weightings.');
					else continue;
				}
				else{
					for (courseWeightingWrapper weightWrap: cwcw.weightingsList ){
						if (weightWrap.baseWeighting!=null && weightWrap.baseWeighting.id!=null) deleteCourseWeightingsList.add(weightWrap.baseWeighting);
						if (weightWrap.finalWeighting!=null && weightWrap.finalWeighting.id!=null) deleteCourseWeightingsList.add(weightWrap.finalWeighting);
					}
				}
			}
		}
		if(ApexPages.hasMessages()){
			bConfigureWeightings= true;
			return;
		}
		else if(selectedCourse.course.id!=null){
			if(!courseWeightingsList.isEmpty()) upsert courseWeightingsList;
			if(!deleteCourseWeightingsList.isEmpty()) delete deleteCourseWeightingsList;
			selectedCourse = new CourseWrapper(getCourseDetails(selectedCourseId), true);
		}
		bConfigureWeightings = false;
	}//Save Course Weightings

	//Cancel Course Weightings
	public void cancelWeightings(){
		bConfigureWeightings = false;
		bAssWeightings = false;
	}//Cancel Course Weightings
	 
	public void addExistingCourses(){
		try{
			List <Course_Course_Catalog__c> ccCatListToUpsert = new List <Course_Course_Catalog__c>();
			for (courseWrapper cw : wrappedCourses ){
				if (cw.useRecord){
					Course_Course_Catalog__c ccc = new Course_Course_Catalog__c(course_catalog__c =selectedCatalogId,course__c=cw.course.id);
					ccCatListToUpsert.add(ccc);
				}
			}
			upsert ccCatListToUpsert;
			returnCatalogDetails();
			bAddCourse = false;
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Courses could not be added to the selected catalog.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Course Catalog, '+selectedCatalogId, 'Course Catalog', 'error creating Course_Course_Catalog__c objects', e);
			insert ge;
		}
	}	   
	public void removeCourses(){
		try{
			List <Course_Course_Catalog__c> ccCatListToDelete = new List <Course_Course_Catalog__c>();
			for (courseWrapper cw : selectedCatalogWrapper.catalogElementList ){
				if (cw.useRecord){
					ccCatListToDelete.add(cw.ccCat);
				}
			}
			delete ccCatListToDelete;
			returnCatalogDetails();
		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Could not delete the courses from the course catalog.'));
			Global_Error__c ge = CT_Error_Handling.handleError('Course Catalog, '+selectedCatalogWrapper.catalog.id, 'Course Catalog', 'error deleting Course_Course_Catalog__c objects', e);
			insert ge;
		}
	}
	//End Save Term Config
	public void saveDefaultAssignmentWeightings(){
		try{
			List<Default_Assignment_Weighting__c> dawUpsertList = new List<Default_Assignment_Weighting__c>();
			List<Default_Assignment_Weighting__c> dawDeleteList = new List<Default_Assignment_Weighting__c>();
			//EE 4/19 need to validate weightings add up to 100%
			if(selectedCourse.course.Use_Assignment_Type_Percentages__c){
				decimal sum = 0;
				for(assignmentWeightWrapper aww: plList){
					if(aww.useRecord) sum+=aww.percentWeight;
				}
				if(sum!=100){
					CT_SetupWizard_Utils.addMessage(apexpages.severity.ERROR,'The assignment weighting percentages must add up to 100%.  The current sum is '+sum+'%.  Please revise weightings.');
					return;
				}
			}
			//EE 4/1 US2917 need to be able to add weightings to a new course before saving course
			if(selectedCourse.course.id==null){
				bAssWeightings=false;
				return;
			}
			for(assignmentWeightWrapper aww: plList){
				if(aww.useRecord){
					if(aww.dawID==null){
						dawUpsertList.add(new Default_Assignment_Weighting__c(Course__c=selectedCourseId, Picklist_Value__c=aww.plID, Default_Weighting__c=double.valueof(aww.weight), Percent_Of_Section_Grade__c = aww.percentWeight));
						
					}
					else{
						dawUpsertList.add(new Default_Assignment_Weighting__c(ID=aww.dawID, Course__c=selectedCourseId, Picklist_Value__c=aww.plID, Default_Weighting__c=double.valueof(aww.weight), Percent_Of_Section_Grade__c = aww.percentWeight));
	
					}
				}
				else{
					if(aww.dawID!=null){
						dawDeleteList.add(new Default_Assignment_Weighting__c(ID=aww.dawID));
					}
				}
			}
			if(dawUpsertList.size()>0){
				upsert dawUpsertList;
			}
			if(dawDeleteList.size()>0){
				delete dawDeleteList;
			}
			bAssWeightings = false;

		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Could not update the default assignment weightings for the selected course'));
			Global_Error__c ge = CT_Error_Handling.handleError('Course, '+selectedCourseId, 'Course Catalog', 'could not save default assignment weightings', e);
			insert ge;
		}
	}
	//End wrapper class construction and instantiation
		
		
		public static void updateCourseWeightings_Chicago(){
			Map <Id, Course__c> courseMap =new Map <Id, Course__c>();
			for (Course__c c: [select id, number_of_reporting_periods__c from Course__c]) courseMap.put(c.id, c);
			Map <Decimal, Picklist_Value__c> rpPlValueMap = new Map<Decimal, Picklist_Value__c>();
			for (Picklist_Value__c plv: CT_core_soqlUtils.getPlValuesList('Time', null)){
					if (plv.Category__c == 'Reporting Period'&&plv.corresponding_value__c!=null){
						rpPlValueMap.put(plv.corresponding_value__c, plv);
					}
			}
			List <Course_Weightings__c> cwList = new List <Course_Weightings__c>();
			for (Course_Weightings__c  cw :[select Id, Name, Key__c, Weighting__c, Course__c 
											 from Course_Weightings__c ]){
				Course__c course = courseMap.get(cw.course__c);
				cw.Reporting_Period_Type__c = 	rpPlValueMap.get(course.number_of_reporting_periods__c).id; 			
				cwList.add(cw);
			}
			if (!cwList.isEmpty()){
				update cwList;
			}
		}
		
		public static void updateGradeScale_Hawaii(){
			Map <String, Id> plvMap = new Map <String, ID>();
			List <Picklist_Value__c> gsList = new List <Picklist_Value__c>();
			List <Course__c> courseList = new List <Course__c>();
			List <Grade_Normalization__c> gnlist = new List <Grade_Normalization__c>();
			for (Picklist_Value__c plv: [select id, name, category__c, type__c from Picklist_Value__c where RecordType.DeveloperName = 'Grade_Scale']){
				plv.type__c = 'Grade Scale';
				if (plv.Category__c==null){
					if (plv.name.contains('Standard')) plv.category__c = 'Standards';
					if (plv.name =='Points') plv.category__c = 'Points';
					if (plv.name =='Credit/No Credit') plv.category__c = 'Credit/No Credit';	
					if (plv.name =='0-100')			plv.category__c = '0-100';
					if (plv.name.contains('Letter'))			plv.category__c = 'Default';
					system.debug(plv.name);
				}
				gsList.add(plv);
				plvMap.put(plv.name, plv.id);
			}
			
			Map <Decimal, Grade_Normalization__c> gnMap = CT_Gradebook_SoqlUtils.getNormalizationMap(null);
			
			for (Grade_Normalization__c gn: [select name, transformed_grade__c,grade_value__c, picklist_value__c,picklist_value__r.name, id from Grade_Normalization__c where isFinal__c=false]){
				if (gn.Transformed_Grade__c==null && gn.name.length() < 10) gn.Transformed_Grade__c = gn.name;
				if (gn.Grade_Value__c!=null){
					Grade_Normalization__c matchingGn= gnMap.get(gn.grade_value__c);
					if (matchingGn !=null) gn.GP_Value__c = matchingGn.gp_value__c;
				}
				
				gnList.add(gn);
			}
			if (!gsList.isEmpty())			update gsList;
			if (!gnList.isEmpty())		update gnList;
		/*
			for (Course__c c: [select id, grade_scale__c, grade_scale_lookup__c from Course__c where (RecordType.DeveloperName= 'Course' or RecordTypeId = null) and subject_area_lookup__c!=null]){
				system.debug(c.grade_Scale__c);
				if (plvMap.get(c.grade_Scale__c)!=null){
					c.grade_scale_lookup__c = plvMap.get(c.grade_scale__c);	
					courseList.add(c);
				}
				else {
					c.grade_scale_lookup__c = plvMap.get('Default');	
					courseList.add(c);
				}
			}
			if (!courseList.isEmpty()){
				update courseList;
			}
			if (!gsList.isEmpty()){
				update gsList;
			}
			*/
		}
	
	public PageReference next(){
		if(verifyCatalog()) return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.ROOMS,true,cSetup.setup);
		else return null;
	}
	
	public PageReference prev(){
		return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.CALENDAR,false,cSetup.setup);
	}
	
	public boolean verifyCatalog(){
		if(CT_SetupWizard_Utils.checkCourseCatalog(cSetup.setup)){
			if(cSetup.setup.Course_Catalog__c==null){
				CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'A course catalog must be selected and contain at least one course before moving on to the next step.');
				return false;
			}
			else if(selectedCatalogWrapper.catalogElementList.size()==0){
				CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'The course catalog must contain at least one course before moving on to the next step.');
				return false;
			}
			else{
				List<String> courseNames = new List<String>();
				for(courseWrapper cw: selectedCatalogWrapper.catalogElementList){
					if(cw.course.Grade_Scale_Lookup__c==null) courseNames.add(cw.course.Name);
				}
				if(courseNames.size()>0){
					courseNames.sort();
					CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'The Grade Scale field is required for all courses.  Review the value and click Save.  Please update this field on the following course(s): '+String.join(courseNames,', '));
					return false;
				}
			}
		}
		return true;
	}
	   
	
	//Start wrapper class construction and instantiation
	public class cCatalogWrapper {
		public Course_Catalog__c		catalog {get;set;}
		public List<courseWrapper>	  catalogElementList {get;set;}
		public List <Course_Catalog__c> editCatalogs {get;set;}
		public Set <Id>				 configuredCourseIds {get;set;}
		public string				   selectedCatalogId {get;set;}	  

		public cCatalogWrapper (Course_Catalog__c parentCatalog ){
			catalogElementList = new List <courseWrapper> ();
			configuredCourseIds = new Set <Id>();
			if(parentCatalog != null){
				this.catalog = parentCatalog;	   
				for (Course_Course_Catalog__c ccc: CT_core_CourseCatalogController.returnCourseCourseCatalogs(parentCatalog.id) )   {
						configuredCourseIds.add(ccc.course__c);
						system.debug('course~~~~~'+ccc.course__r);
						courseWrapper cw = new courseWrapper(ccc.course__r, false);
					   cw.ccCat = ccc;
						catalogElementList.add(cw);
				}
			}
		}
	}
	
	public class courseWrapper{
		public Course__c course												{get;set;}
		public string selectedRpNum											{get;set;}
		public List <SelectOption> rpNumOptions								{get;set;}
		public boolean useRecord											{get;set;}
		public Course_Course_Catalog__c ccCat								{get;set;}
		public boolean isDisabled											{get;set;}
		public List <courseWeightingConfigWrapper>  cwWrapper				{get;set;}
	  	public List <Course_Weightings__c>   cwList							{get;set;}
	  	public Map <Id, Map <String, Course_Weightings__c>> plvChildCwMap	{get;set;}
	  	public string selectedGradeScale									{get;set;}
		
		public courseWrapper(Course__c course, boolean bEdit){
			this.course = course;
			this.selectedGradeScale = course.grade_Scale_lookup__c;
			useRecord = false;
			if (bEdit){
				configureWeightings();
			}
		}
		
		public void configureWeightings(){
			rpNumOptions = new List <SelectOption>();
			plvChildCwMap = new Map <Id, Map <String, Course_Weightings__c>>();
			CT_core_CourseCatalogController.rpPlvList = new List <Picklist_Value__c>();			
	 		for (Picklist_Value__c plv: CT_core_soqlUtils.getPlValuesList('Time', null)){
				if (plv.Category__c == 'Reporting Period'&&plv.corresponding_value__c!=null){
					rpPlvList.add(plv);
				}
			}
			for (Picklist_Value__c plv: CT_core_CourseCatalogController.rpPlvList){
				rpNumOptions.add(new SelectOption(String.valueOf(plv.corresponding_value__c), string.valueOf(plv.corresponding_value__c)));
				plvChildCwMap.put(plv.id, new Map <String, Course_Weightings__c>{});
			}
			for (Course_Weightings__c cw : [select id, key__c,  Reporting_Period_Type__c, Weighting__c, course__c
																FROM Course_Weightings__c
																WHERE course__c =:course.id]){
				if (cw.reporting_period_Type__c!=null){
					if(plvChildCwMap.containsKey(cw.Reporting_Period_Type__c))
						plvChildCwMap.get(cw.reporting_period_type__c).put(cw.key__c, cw);
					else
						CT_SetupWizard_Utils.addMessage(apexpages.severity.WARNING,'There was an error loading one or more course weightings. Please check your course weightings are configured as expected.');
				}
			}
			isDisabled = false;
			cwWrapper = new List <courseWeightingConfigWrapper>();
			
			for (Picklist_Value__c plv: rpPlvList){
				courseWeightingConfigWrapper cwcw = new courseWeightingConfigWrapper(plv, plvChildCwMap.get(plv.id) );
				cwWrapper.add(cwcw);
			}
		}
	}
		
	public class assignmentWeightWrapper{
				public Boolean useRecord			{get;set;}
				public String typeName				{get;set;}
				public String weight				{get;set;}
				public List<SelectOption> weightList {get;set;}
				public ID dawID						{get;set;}
				public Decimal percentWeight		{get;set;}
				public ID plID						{get;set;}
				
				public assignmentWeightWrapper(String typeName, ID picklistvalID){
					this.typeName = typeName;
					this.plID = picklistvalID;
					useRecord = false;
					weight = '1';
					dawID = null;
					weightList = new List<SelectOption>();
					for(Integer i=1; i<=10; i++){
						String s = i.format();
						weightList.add(new SelectOption(s,s));
					}
				}
	}
	
	public class courseWeightingConfigWrapper{
		public Picklist_Value__c 			rpPlValue {get;set;}
		public boolean 							bInUse		{get;set;}
		public List <courseWeightingWrapper> weightingsList {get;set;}
		
		public courseWeightingConfigWrapper(Picklist_Value__c plV, Map <String, Course_Weightings__c> childWeightMap ){
			system.debug('chidWeightMap~~~~'+childWeightMap);
			this.rpPlValue = plV;
			this.weightingsList = new List <courseWeightingWrapper>();
			if (!childWeightMap.isEmpty()){
				bInUse = true;
				for (Integer i=1; i<=plV.corresponding_value__c; i++){
					courseWeightingWrapper cww=new courseWeightingWrapper(i);
					if (childWeightMap.get(string.valueOf(i))!=null){
						cww.bInUse = true;
						cww.iWeighting = childWeightMap.get(string.valueOf(i)).weighting__c;
						cww.baseWeighting = childWeightMap.get(string.valueOf(i));
					}
					else {
						cww.bInUse = false;
						cww.iWeighting = 0;
					//	cww.baseWeighting = new Course_Weightings__c (Reporting_Period_Type__c=plv.id, key=string.valueOf(i));
					}
					if (childWeightMap.get(string.valueOf(i+'-Final'))!=null){
						cww.bHasFinal = true;
						cww.finalWeighting = childWeightMap.get(string.valueOf(i+'-Final'));
						cww.iFinalWeighting = childWeightMap.get(string.valueOf(i+'-Final')).weighting__c;		 			
					}
					else {
						cww.bHasFinal = false;
						//	cww.finalWeighting = new Course_Weightings__c (Reporting_Period_Type__c=plv.id, key=string.valueOf(i+));
					}
					this.weightingsList.add(cww);
				}
			}
			else {
				bInUse=false;
				for (Integer i=1; i<=plV.corresponding_value__c; i++){
					this.weightingsList.add(new courseWeightingWrapper(i));
				}
			}
		}
	}
	
	public class courseWeightingWrapper {
		public integer iNum {get;set;}
		public boolean bInUse {get;set;}
		public decimal iWeighting {get;set;}
		public boolean bHasFinal {get;set;}
		public decimal iFinalWeighting {get;set;}
		public Course_Weightings__c baseWeighting {get;set;}
		public Course_Weightings__c finalWeighting {get;set;}
		
		public courseWeightingWrapper(integer k){
			this.iNum = k;
		}
	}
}