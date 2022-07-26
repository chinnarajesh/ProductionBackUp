public with sharing class Gradebook_Quick_Create_Assignment {
	//US3131
	public Gradebook_AssignmentWrapper_v2 assignmentWrapper {get; set;}
	public searchStandards searchFeature {get; set;}
	Map<String, String> standardScaleMap {get; set;}
	Set<ID> pointsGradeScaleID {get; set;}
	public String dueDate {get; set;} //within the reporting period they are currently on
	//pull the RP ID from the filter

	public String courseCategory {get; set;}

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
	
	//Need passed parameters
	//current Setup__c from core_baseInfo_v2.cSchool_BaseInfo activeSetup
	private Setup__c currentSetup {get; set;}
	public Section__c currentSection {get; set;}
	public Time_Element__c currentTimeElement {get; set;}
	//current section and course
	
	public Gradebook_Quick_Create_Assignment(Setup__c cSetup, Section__c cSection, Time_Element__c cTimeElement) {
		this.currentSetup = cSetup;
		this.currentSection = cSection;
		this.currentTimeElement = cTimeElement;
		
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
		}
		catch(Exception e) {
			Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'There was a problem initializing Quick Create Assignment Feature. Please contact your administrator.'));
		}		
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
		for(Default_Assignment_Weighting__c daw : [SELECT ID, Picklist_Value__c, Picklist_Value__r.Name, Default_Weighting__c, Course__c, Section__c FROM Default_Assignment_Weighting__c WHERE Course__c =: assignmentWrapper.assignmentCourse AND (Picklist_Value__r.Setup__c =: currentSetup.ID OR Picklist_Value__r.Setup__c = null) ORDER BY Course__r.Name, Picklist_Value__r.Name ASC]) {
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
		from Grade_Scale_Catalog_Scale__c where Grade_Scale_Catalog__c = :currentSetup.Grade_Scale_Catalog__c order by picklist_value__r.name];
		for(Grade_Scale_Catalog_Scale__c pv: gscs){
			if(pv.Picklist_Value__r.Name == 'Points'||pv.picklist_value__r.category__c=='Points'){
				pointsGradeScaleID.add(pv.Picklist_Value__c);
			}
			if(pv.Picklist_Value__r.Category__c=='Standards'||pv.Picklist_Value__r.Standard_Scale__c){
				standardScaleOptions.add(new SelectOption(pv.Picklist_Value__c, pv.Picklist_Value__r.Name));
				standardScaleMap.put(pv.Picklist_Value__r.Name, pv.Picklist_Value__c);
			}
			if (pv.Picklist_Value__c!=null) {
				gradeScaleOptions.add(new SelectOption(pv.Picklist_Value__c, pv.Picklist_Value__r.Name));
			}
		}
	}

	public void renderPointsField() {
		if(pointsGradeScaleID.contains(assignmentWrapper.gradeScale)) {
			rPoints = true;
			assignmentWrapper.assignmentWeighting = 1;
		}
		else {
			rPoints = false;
			assignmentWrapper.assignmentPossiblePoints = null;
			setDefaultAssignmentWeighting();
		}
	}

	public void initializeQuickCreateAssignment() { //call this on section selection and openModal?
		rIntegers = true;
		rPoints = false;
		rGradeScale = true;
		try {
			assignmentWrapper = new Gradebook_AssignmentWrapper_v2(currentSetup.Standards_Based_Grading__c, currentSetup.Standards_ONLY_Gradebook__c);
			searchFeature = new searchStandards();
			assignmentWrapper.assignmentCourse = currentSection.Course__c;
			Course__c queriedCourse = [SELECT ID, Name, Grade_Scale_Lookup__r.Category__c, Grade_Scale_Lookup__c, Grade_Scale_Lookup__r.Name, Grade_Scale__c, Use_Assignment_Type_Percentages__c FROM Course__c WHERE ID =: assignmentWrapper.assignmentCourse];
			assignmentWrapper.courseName = queriedCourse.Name;

			dueDate = ''; //reminder within range of the RP
			advanceAssignmentOptions = false;
			closeQuickCreate = false;
			quickCreateNew = false;
			try {
				currentReportingPeriodName = currentTimeElement.Name__c;
			}
			catch(Exception e) {
				ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'currentTimeELement is null'));
			}
			
			/*
			if(assignmentWrapper.standardBased) {
				rStandardScale = true;
			}
			else {
				rStandardScale = false;
			}
			*/

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
				rPoints = true;
				assignmentWrapper.assignmentWeighting = 1;
			}
			else {
				rPoints = false;
			}
			courseCategory = queriedCourse.Grade_Scale_Lookup__r.Category__c;
			assignmentWrapper.gradeScale = queriedCourse.Grade_Scale_Lookup__c;
			//rIntegers = !queriedCourse.Use_Assignment_Type_Percentages__c;
			usePercentage = !rIntegers;
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

	//DE3505
	public void setDefaultAssignmentWeighting() {
		//DE3505 set the integer assignment weighting based on the DAW
		if(assignmentWrapper.assignmentCourse != null && assignmentWrapper.assignmentType != null && !rPoints) {
			String Key = String.valueOf(assignmentWrapper.assignmentCourse) + String.valueOf(assignmentWrapper.assignmentType);
			if(defaultAssignmentWeighting.containsKey(Key)) {
				assignmentWrapper.assignmentWeighting = defaultAssignmentWeighting.get(Key);
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
				if(tempDate < currentTimeElement.Date_Start_Date__c || tempDate > currentTimeElement.End_Date__c) {
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
			assignmentWrapper.sectionToDueDate.put(currentSection.ID, tempDate);
		}
		catch(Exception e) {
			system.debug('*~*~* Error in sectionDueDates! dueDate is: ' + dueDate);
			return false;
		}

		//create the sectionToReportingPeriod
		if(currentTimeElement != null) {
			assignmentWrapper.sectionToReportingPeriods.put(currentSection.ID, currentTimeElement.ID);
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

	public ID submit() {
		ID returnAssignmentID;
		if(validateSubmit()) {
			assignmentWrapper.createAssignmentLibrary();
			assignmentWrapper.createAssignments();

			//setting the parameters to refresh to that selected assignment
			returnAssignmentID = assignmentWrapper.assignmentID;
			//singleassignment.add(new SelectOption(assignmentWrapper.assignmentID, assignmentWrapper.assignmentName));
			closeQuickCreate = true;

			if(assignmentWrapper.attachAssignment) {
				domain = ApexPages.currentPage().getHeaders().get('Host');
				fromGradeBook = ApexPages.currentPage().getParameters().get('fromGradeBook');
			}
		}
		else {
			system.debug('*~*~* Quick Assignment Creation failed; assignmentWrapper: ' + assignmentWrapper);
		}
		return returnAssignmentID;
	}

	public void submitAndNew() {
		if(submit() != null) {
			quickCreateNew = true;
		}
	}	
}