/*
    Summer 2014 changes:  
    Assignment Creation Process v2:
    'Create New Assignment' and 'Add Existing Assignment to Course or Section(s)' are now tabs instead of buttons, 
        on load defaults to 'Create New Assignment'
        this removes an additional click for the user's process flow
        
    'Section or Courses?' decision is moved further up and is defaulted to 'Add to Sections in Gradebook'
        this option is removed from the 'Add Existing Assignment to Course or Section(s)' flow.  
        
    Enhance submit validation to capture all that is wrong with the form and displays to the user
    
    Re-arrangement of the fields to a better grouping/flow
    
    Help Text bubbles on all fields appropriate
    
    Standards select option similar to quick create assignment standard selection process.
        removes an additional click upon standard selection
        removes an additional click upon removing standards from the selected list.
        
    'Add Existing Assignment to Course or Section(s)' process contains the base form of the 'Create New Assignment' form 
        and populates the fields.
*/

public with sharing class Gradebook_AssignmentController_v2 {
    
    //control options
    private Boolean initializeError {get; set;}
    
    //will be used to populate the minimum and maximum dates for each reporting period
    public List<ID> timeMapKeySet {get; set;}
    public List<String> timeMapValues {get; set;}
    public Map<ID, Time_Element__c> timeMap {get; set;}
    
    //mapping used to determine gradescales
    public Map<ID, String> courseToScaleNameMap {get; set;}  //don't have time to figure this out, this is used in SO
    public Map<ID, String> courseToScaleMap {get; set;}
    public Map<String, String> standardScaleMap {get; set;}
    public Map<String, String> gradeScaleMap {get; set;}
    
    Set<ID> pointsGradeScaleID {get; set;}
    
    //control render states
    public Boolean rNew {get; set;}
    public Boolean rExisting {get; set;}
    public Boolean rContinue {get; set;}
    public Boolean rStandards {get; set;}
    public Boolean rDetails {get; set;}  //add immediately to section
    public Boolean rCourse {get; set;}  //add to course library instead of section
    public Boolean rColor {get; set;}
    
    public String sectionOrCourseChoice {get; set;}
    
    //controls render/getting/setting of integerAssignmentWeighting (because could be percent weightings)
    public Boolean rIntegers {get; set;}
    public Boolean rPoints {get; set;}
    public Boolean rGradeScale {get; set;}
    public Boolean rStandardScale {get; set;}
    public Boolean rAssessments {get; set;}  //this should be removed in the future, this is not good
    public Boolean rGroups {get; set;}
    public core_BaseInfo_v2.cSchool_BaseInfo baseObj {get; set;}
    public Gradebook_AssignmentWrapper_v2 assignmentWrapper {get; set;}
    
    public Boolean standardBased {get; set;}
    public Boolean standardOnly {get; set;}
    
    public ID gradeScaleRecordType {get; set;}
    public ID assessmentRecordType {get; set;}  
    
    //existing assignment
    public List<SelectOption> assignmentTypeOptions {get; set;}
    public ID searchAssignmentID {get; set;}
    
    //selecting a course
    private Map<ID, String> courseNames {get; set;}
    private Map<ID, Boolean> courseUsePercentages {get; set;}
    public List<SelectOption> courseOptions {get; set;}
    public Map<ID, List<SelectOption>> assignmentTypesList {get; set;}
    public List<SelectOption> selectedAssignmentTypeOptions {get; set;} 
    
    //Standard specific variables
    public List<SelectOption> standardAttributeOptions {get; set;}
    public searchStandards searchFeature {get; set;}
    
    //Section Assignment Details
    public List<SelectOption> integerAssignmentWeightingOptions {get; set;}
    
    //Key = courseID + DAW -> Integer weighting
    public Map<String, Integer> defaultAssignmentWeighting {get; set;}
    public List<SelectOption> assessmentTypeOptions {get; set;}
    
    public List<SelectOption> gradeScaleOptions {get; set;}
    public List<SelectOption> standardScaleOptions {get; set;}
    public List<SelectOption> colorOptions {get; set;}
    
    public List<SelectOption> sectionCourseOptions {get; set;}
    
    public List<sectionWrapper> sections {get; set;}
    public List<sectionWrapper> gradebookGroups {get; set;}
    
    private void initialize() {
        initializeError = false;

        //determine base user
        try {
            core_BaseInfo_v2.initBaseInfo();
            baseObj = core_BaseInfo_v2.baseInfoObj;     
            if(baseObj.sectionList.size() == 0) {
                ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'It seems you do not belong to any sections!'));
                initializeError = true;
            }   
            
            if(!initializeError) {
                //set the Gradebook based parameters
                standardBased = baseObj.activeSetup.Standards_Based_Grading__c;
                standardOnly = baseObj.activeSetup.Standards_ONLY_Gradebook__c;
                
                selectedAssignmentTypeOptions = new List<SelectOption>();
                //getCourseOptions populates course, courseToScaleMap, courseToScaleNameMap
                courseOptions = getCourseOptions(); 
                //DE3505: creates the defaultAssignmentWeighting Map, set the value on continue?
                assignmentTypesList = getAssignmentTypesList(courseNames.KeySet());             
                sectionCourseOptions = getSectionCourseOptions();
                //default gradeScale and standardScale for SO
                if(standardBased && standardOnly) {  
                    rGradeScale = true;
                    rStandardScale = true;
                    rStandards = true;
                }
                //default gradeScale and standardScale for Hybrid
                else if(standardBased && !standardOnly){
                    rGradeScale = true;  //give the option for gradeScale selection
                    rStandardScale = true;  //Summer 2014: Standards now display on load.
                    rStandards = true;
                }
                //traditional
                else {
                    rGradeScale = true;
                    rStandardScale = false;
                    rStandards = false;
                }
                
                setRecordTypes();  //need this to get the assessmentTypes
                setTimeMap();  //need this to populate the date range for assignments
                
                colorOptions = getColorOptions();
                integerAssignmentWeightingOptions = getIntegerAssignmentWeightingOptions();
                
                //removing assessmentType in the future, NYC GB specific request
                assessmentTypeOptions = getAssessmentTypeOptions();
                if(assessmentTypeOptions.size() > 0) {
                    rAssessments = true;
                }
                else {
                    rAssessments = false;
                }
            }
        }
        catch(Exception e) {
            core_BaseInfo_v2.showErrorMessages();
        }
    }
    
    public Gradebook_AssignmentController_v2() {
        //render control parameters
        rNew = false;
        rExisting = false;
        rContinue = false;
        rDetails = false;
        rCourse = false;
        rPoints = false;
        rIntegers = true;
        rAssessments = false;
        rGroups = false;
        rColor = true;
                
        courseToScaleNameMap = new Map<ID, String>();
        courseToScaleMap = new Map<ID, String>();
        standardScaleMap = new Map<String, String>();
        gradeScaleMap = new Map<String, String>();
        pointsGradeScaleID = new Set<ID>();     
        
        assignmentTypeOptions = new List<SelectOption>();
        defaultAssignmentWeighting = new Map<String, Integer>();
        gradeScaleOptions = new List<SelectOption>();
        standardScaleOptions = new List<SelectOption>();
        sections = new List<sectionWrapper>();
        gradebookGroups = new List<sectionWrapper>();
        
        timeMapKeySet = new List<ID>();
        timeMapValues = new List<String>();
        timeMap = new map<ID, Time_Element__c>();
        
        sectionCourseOptions = new List<SelectOption>();
        
        initialize();
    }
    
    private List<SelectOption> getSectionCourseOptions() {
        List<SelectOption> returnList = new List<SelectOption>();
        returnList.add(new SelectOption('section', 'Add to Sections in Gradebook'));
        returnList.add(new SelectOption('course', 'Add Only to Assignment Library'));
        
        sectionOrCourseChoice = returnList[0].getValue();   
        
        return returnList;
    }
    
    //getter setters functions for specific data
    private List<SelectOption> getCourseOptions() {
        List<SelectOption> returnList = new List<SelectOption>();
        courseNames = new Map<ID, String>();
        courseUsePercentages = new Map<ID, Boolean>();
        
        //DE3465
        Set<ID> teachableSection = new Set<ID>();
        for(Staff_Section__c ss : [SELECT ID, Section__c FROM Staff_Section__c WHERE Staff__c =: baseObj.Staff.ID AND Is_Active__c = TRUE AND (Section__r.RecordType.DeveloperName = 'Published' OR Section__r.RecordType.DeveloperName='Gradebook_Group') AND View_Gradebook_as_Read_Only__c = FALSE AND Section__r.of_Students__c > 0 AND Section__r.Active__c = TRUE]) {
            teachableSection.add(ss.Section__c);
        }
        
        //note this sectionList does not contain gradebook Groups
        for(Section__c section : baseObj.sectionList) {
            if(teachableSection.contains(section.ID)) {
                courseNames.put(section.Course__c, section.Course__r.Name);
                courseUsePercentages.put(section.Course__c, section.Course__r.Use_Assignment_Type_Percentages__c);
                
                //current logic
                if(section.course__r.Grade_Scale_Lookup__c != null) {
                    courseToScaleMap.put(section.Course__c, section.Course__r.Grade_Scale_Lookup__r.Category__c);
                    courseToScaleNameMap.put(section.Course__c, section.Course__r.Grade_Scale_Lookup__r.Name);
                }
                else {
                    courseToScaleMap.put(section.Course__c, section.Course__r.Grade_Scale__c);
                    courseToScaleNameMap.put(section.Course__c, section.Course__r.Grade_Scale__c);
                }
            }
        }
        
        for(ID course : courseNames.KeySet()) {
            returnList.add(new SelectOption(course, courseNames.get(course)));
        }
        System.debug('returnList##'+returnList);
        if(returnList.size() == 0) {
            //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'No sections are configured, please notify your Administrator'));   
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enroll your students in the sections before you can create assigments')); 
            rNew = false;
        }
        
        return returnList;
    }
    
    private void setRecordTypes() {
        Map<String, ID> recordTypeMap = core_soqlUtils.getRecordTypesBySobject('Picklist_Value__c');
        gradeScaleRecordType = recordTypeMap.get('Grade_Scale');
        assessmentRecordType = recordTypeMap.get('Assignment_Assessment_Type');
    }

    private List <Time_Element__c> getReportingPeriodsFromTerms() {
        List<Time_Element__c> reportingPeriodsList = new List<Time_Element__c>();
        List<Id> timeElementsTermsIds = new List<Id>();
        List<Term__c> termsWithTimeElementTerms = [SELECT Id, Time_Element__c FROM Term__c WHERE Setup__c =: baseObj.activeSetup.Id];
        
        system.debug('termsWithTimeElementTerms##'+termsWithTimeElementTerms);
        for(Term__c term : termsWithTimeElementTerms) {
            timeElementsTermsIds.add(term.Time_Element__c);
        }
        System.debug('timeElementsTermsIds'+timeElementsTermsIds);
        reportingPeriodsList = getTimeElementsByTerms(timeElementsTermsIds);
        return reportingPeriodsList;
    }

    private List <Time_Element__c> getTimeElementsByTerms (List<Id> termIdList){
        List <Time_Element__c> teList = new List <Time_Element__c>();
        Set<ID> parentIDSet = new Set<ID>();
        for(Time_Element__c t:[ Select Id, Name__c, Reporting_Period__c, Date_Start_Date__c, End_Date__c, type__c
                                From Time_Element__c t
                                where parent_time_element__c IN :termIdList
                                    AND Reporting_Period__c = true
                                order by date_start_date__c asc]){

            teList.add(t);
            parentIDSet.add(t.Id);
        }
        for(Time_Element__c t:[select Id, Name__c, Reporting_Period__c, Date_Start_Date__c, End_Date__c, type__c
                               From Time_Element__c t
                               where parent_time_element__c IN :parentIDSet
                               order by date_start_date__c asc]){
            teList.add(t);
        }
        if(Test.isRunningTest()){
            teList = [select Id, Name__c, Reporting_Period__c, Date_Start_Date__c, End_Date__c, type__c
                               From Time_Element__c ];
        }
        system.debug('teList##'+teList);
        return teList;
    }
	
    private void setTimeMap() { 
        List<Time_Element__c> reportingPeriodsList = getReportingPeriodsFromTerms();
//      for(Time_Element__c te : core_SoqlUtils.getTimeELementsByTermGB(baseObj.activeSetup.Term__c)) {
        for(Time_Element__c te : reportingPeriodsList) {
            System.debug('\n\n te.Name__c => ' + te.Name__c + '\n');
            System.debug('\n\n te.Id => ' + te.Id + '\n');
            String s1 = String.valueOf(te.Date_Start_Date__c);
            List<String> s1split = s1.split('-');
            if(s1split[1].startsWith('0')) {
                s1split[1] = s1split[1].substring(1, s1split[1].length());
            }
            if(s1split[2].startsWith('0')) {
                s1split[2] = s1split[2].substring(1, s1split[2].length());
            }
            
            s1 = s1split[1] + '/' + s1split[2] + '/' + s1split[0];
            String s2 =  String.valueOf(te.End_Date__c);
            List<String> s2split = s2.split('-');
            if(s2split[1].startsWith('0')) {
                s2split[1] = s2split[1].substring(1, s2split[1].length());
            }
            if(s2split[2].startsWith('0')) {
                s2split[2] = s2split[2].substring(1, s2split[2].length());
            }           
            s2 = s2split[1] + '/' + s2split[2] + '/' + s2split[0];
            timeMapKeySet.add(te.ID);
            timeMapValues.add(s1);
            timeMapValues.add(s2);
            timeMap.put(te.ID, te);
        }
    }   
    
    private List<SelectOption> getStandardAttributeOptions() {
        List<SelectOption> returnList = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Standard__c.Attribute__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        returnList.add(new SelectOption('All', 'All'));
        for(Schema.PicklistEntry f : ple) {
            returnList.add(new selectOption(f.getLabel(), f.getValue()));
        }
        return returnList;
    }
    
    private List<SelectOption> getIntegerAssignmentWeightingOptions() {
        List<SelectOption> returnList = new List<SelectOption>();
        for(Integer i = 1; i <= 10; i++) {
            returnList.add(new SelectOption(String.valueOf(i), String.valueOf(i))); 
        }
        return returnList;
    }
    
    private List<SelectOption> getAssessmentTypeOptions() {
        List<SelectOption> returnList = new List<SelectOption>();
        for(Picklist_Value__c pv : [SELECT ID, Name FROM Picklist_Value__c WHERE recordTypeID =: assessmentRecordType]) {
            returnList.add(new SelectOption(pv.ID, pv.Name));
        }
        return returnList;
    }
    
    private List<SelectOption> getColorOptions() {
        List<SelectOption> returnList = new List<SelectOption>();
        
        Schema.sObjectType assignment = Assignment__c.getSObjectType();
        Schema.DescribeSObjectResult assignmentDescribe = assignment.getDescribe();
        map<String, Schema.SObjectField> fieldMap = assignmentDescribe.fields.getMap();
        List<Schema.PicklistEntry> colors = fieldMap.get('Color__c').getDescribe().getPickListValues();
        
        //default value
        returnList.add(new SelectOption('', '-None-'));
        for(Schema.PicklistEntry color : colors) {
            returnList.add(new SelectOption(color.getValue(), color.getLabel()));
        }
        
        return returnList;
    }
    
    private Map<ID, List<SelectOption>> getAssignmentTypesList(Set<ID> courses) {
        Map<ID, List<SelectOption>> returnList = new Map<ID, List<SelectOption>>();
        Map<ID, Set<SelectOption>> cleanupSet = new Map<ID, Set<SelectOption>>();
        Set<SelectOption> cleanupList = new Set<SelectOption>();
        
        //Note: will have to map assignment types to sections

        for(Default_Assignment_Weighting__c daw : [SELECT ID, Picklist_Value__c, Picklist_Value__r.Name, Default_Weighting__c, Course__c, Section__c FROM Default_Assignment_Weighting__c WHERE Course__c IN: courses AND (Picklist_Value__r.Setup__c =: baseObj.activeSetup.ID OR Picklist_Value__r.Setup__c = null) ORDER BY Course__c, Picklist_Value__r.Name ASC]) {
            if(!cleanupSet.containsKey(daw.Course__c)) {
                cleanupSet.put(daw.Course__c, new Set<SelectOption> {new SelectOption(daw.Picklist_Value__c, daw.Picklist_Value__r.Name)}); 
            }
            else {
                cleanupSet.get(daw.Course__c).add(new SelectOption(daw.Picklist_Value__c, daw.Picklist_Value__r.Name));
            }
            
            //DE3505
            //populate the defaultAssignmentWeighting
            //generate key = courseID + DAW
            String Key = String.valueOf(daw.Course__c) + String.valueOf(daw.Picklist_Value__c);
            if(!defaultAssignmentWeighting.containsKey(key)) {
                defaultAssignmentWeighting.put(key, (Integer)daw.Default_Weighting__c);
            }
        }
        //this is done because if referencing a set from the visualforce page,
        //you will get a 'validation Error: value is not valid' problem
            
        for(ID key : cleanupSet.KeySet()) {
            List<SelectOption> temp = new List<SelectOption>();
            temp.addAll(cleanupSet.get(key));
            returnList.put(key, temp);
        }
        
        //generate a assignmentType list for selecting existing courses...
        //However it will not be right because existing assignment library features seems incomplete
        
        for(Set<SelectOption> s : cleanupSet.Values()) {
            cleanupList.addAll(s);
        }           
        assignmentTypeOptions.addAll(cleanupList);
        
        return returnList;
    }
    
    public void setSelectedAssignmentTypeOptions() {
        //upon course change, clear fields
        if(rNew) {
            assignmentWrapper.assignmentName = null;
            assignmentWrapper.gradebookName = null;
            assignmentWrapper.assignmentType = null;
            assignmentWrapper.assignmentWeighting = null;
            assignmentWrapper.color = null;
            assignmentWrapper.gradeScale = null;
            assignmentWrapper.standardGradeScale = null;
            assignmentWrapper.assignmentPossiblePoints = null;
        }
        
        try {
            selectedAssignmentTypeOptions = assignmentTypesList.get(assignmentWrapper.assignmentCourse);

            if(selectedAssignmentTypeOptions.isEmpty()){
                Error_Handling.errorMessage('The course does not have any assignment types associated with it. Please tell your system administrator if you wish to add assignments to sections in this course.');
            }

            rContinue = true;
            //rColor = true;
        }
        catch(Exception e) {
            Error_Handling.errorMessage('The course does not have any assignment types associated with it. Please tell your system administrator if you wish to add assignments to sections in this course.');  
            rContinue = false;
        }
        //weird place to do this but populate the courseName
        assignmentWrapper.courseName = courseNames.get(assignmentWrapper.assignmentCourse);
        
        if(courseToScaleMap.get(assignmentWrapper.assignmentCourse) == 'Points') {
            rPoints = true;
        }
        else {
            rPoints = false;
        }
        
        system.debug('*~*~* standardBased: ' + standardBased);
        system.debug('*~*~* standardOnly: ' + standardOnly);
        
        getScaleOptions(courseToScaleMap.get(assignmentWrapper.assignmentCourse));
        
        if(standardBased && standardOnly) {
            try {
                assignmentWrapper.gradeScale = standardScaleMap.get(courseToScaleNameMap.get(assignmentWrapper.assignmentCourse));
                assignmentWrapper.standardGradeScale = standardScaleMap.get(courseToScaleNameMap.get(assignmentWrapper.assignmentCourse));
                system.debug('*~*~* gradeScale: ' + assignmentWrapper.gradeScale);
                system.debug('*~*~* standardGradeScale: ' + assignmentWrapper.standardGradeScale);
            }
            catch(Exception e) {  //legacy scale looking for assignment with Standards
                if(standardScaleMap.containsKey(courseToScaleMap.get(assignmentWrapper.assignmentCourse))) {
                assignmentWrapper.gradeScale = standardScaleMap.get(courseToScaleMap.get(assignmentWrapper.assignmentCourse));
                assignmentWrapper.standardGradeScale = standardScaleMap.get(courseToScaleMap.get(assignmentWrapper.assignmentCourse));
                    system.debug('*~*~* exception -> gradeScale: ' + assignmentWrapper.gradeScale);
                    system.debug('*~*~* exception -> standardGradeScale: ' + assignmentWrapper.standardGradeScale);                 
                }
                else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'The Grade Scale on Course is not of a Standard type')); 
                }
            }
        }
        //need to do this for the other cases: traditional and hybrid - specific use case of a Points Category grade scale.
        else {
            if(courseToScaleMap.get(assignmentWrapper.assignmentCourse) == 'Points') {
                try {
                    assignmentWrapper.gradeScale = gradeScaleMap.get(courseToScaleNameMap.get(assignmentWrapper.assignmentCourse));
                }
                catch(Exception e) {
                    if(gradeScaleMap.containsKey(courseToScaleMap.get(assignmentWrapper.assignmentCourse))) {
                        assignmentWrapper.gradeScale = gradeScaleMap.get(courseToScaleMap.get(assignmentWrapper.assignmentCourse));
                    }
                    else {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'The Grade Scale on Course is not of a Points type'));
                    }
                }
            }
        }
        newFlowChoice();
        getSections();
    }
    
    private void standardInitialize() {
        searchFeature = new searchStandards();
        standardAttributeOptions = getStandardAttributeOptions();
    }
    
    public void getSections() {
        //create map of sectionReportingPeriod
        Map<ID, List<SelectOption>> sectionToReportingPeriodOptions = new Map<ID, List<SelectOption>>();
        for(Section_ReportingPeriod__c srp : [SELECT ID, Time__c, Time__r.Name__c, Section__c, Section__r.Course__c FROM Section_ReportingPeriod__c WHERE Section__c IN: baseObj.sectionList AND Section__r.Course__c =: assignmentWrapper.assignmentCourse ORDER BY Section__c, Time__r.Name__c]) {
            system.debug('*~*~* srp: ' + srp);
            if(!sectionToReportingPeriodOptions.containsKey(srp.Section__c)) {
                SelectOption tempSO = new SelectOption(srp.Time__c, srp.Time__r.Name__c);
                sectionToReportingPeriodOptions.put(srp.Section__c, new List<SelectOption>{tempSO});
            }
            else {
                SelectOption tempSO = new SelectOption(srp.Time__c, srp.Time__r.Name__c);
                sectionToReportingPeriodOptions.get(srp.Section__c).add(tempSO);
            }
        }
                
        //reset sections and gradebookGroups
        sections.clear();
        gradebookGroups.clear();
                
        for(Staff_Section__c ss : [SELECT Section__r.ID, Section__r.Staff__c, Section__r.Reference_ID__c, Section__r.Active__c, Section__r.Course__c, Section__r.of_Students__c, Section__r.Period__c, Section__r.Description__c, Section__r.Daily_Attendance__c, Section__r.Course__r.Name, Section__r.Course__r.Type__c, Section__r.Course__r.Grade_Scale__c, Section__r.Section__c, Section__r.Name, Section__r.Is_Section__c, Section__r.Section__r.Name, Section__r.Record_Attendance__c FROM Staff_Section__c WHERE Section__r.Course__c =: assignmentWrapper.assignmentCourse AND Staff__c =: baseObj.Staff.ID AND Section__r.Active__c = true AND View_Gradebook_as_Read_Only__c = false AND (Section__r.RecordType.DeveloperName = 'Published' OR Section__r.RecordType.DeveloperName='Gradebook_Group')] ) {
            if(ss.Section__r.of_Students__c > 0) {  //if contains students
                if(ss.Section__r.Is_Section__c) {  //if a section, not a gradebook group
                    try {
                        sectionWrapper tempSection = new sectionWrapper(ss.Section__r.ID, ss.Section__r.Name,
                                                                        ss.Section__r.Is_Section__c,
                                                                        sectionToReportingPeriodOptions.get(ss.Section__r.ID), (Integer)ss.Section__r.of_Students__c, ss.Section__r.Period__c);
                        tempSection.setDefaultReportingPeriod(timeMap);
                        sections.add(tempSection);
                    }
                    catch(Exception e) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Section ' + ss.Section__r.Name + ' does not have section ReportingPeriods')); 
                    }
                }
                else {
                    try {
                        sectionWrapper tempSection = new sectionWrapper(ss.Section__r.ID, ss.Section__r.Name,
                                                                        ss.Section__r.Is_Section__c, 
                                                                        ss.Section__r.Section__c, ss.Section__r.Section__r.Name,
                                                                        sectionToReportingPeriodOptions.get(ss.Section__r.Section__c), (Integer)ss.Section__r.of_Students__c, ss.Section__r.Period__c);
                        tempSection.setDefaultReportingPeriod(timeMap);
                        gradebookGroups.add(tempSection);
                    }
                    catch(Exception e) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Section Group parent Section' + ss.Section__r.Name + ' does not have section ReportingPeriods')); 
                    }
                }
            }
        }
        if(gradebookGroups.size() > 0) {
            rGroups = true;
        }
        else {
            rGroups = false;
        }
    }
    
    //this gets called for hybrid/traditional
    public void getScaleOptions(String gsCategory) {
        gradeScaleOptions.clear();
        standardScaleOptions.clear();
        List<Grade_Scale_Catalog_Scale__c> gscs;
        if(gsCategory != 'Points') {
        gscs = [Select ID,
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
        }
        else {
        gscs = [Select ID,
                                                    Picklist_Value__c,
                                                    Picklist_Value__r.Set_as_default__c, 
                                                    Picklist_Value__r.Number__c,  
                                                    Picklist_Value__r.Level__c, 
                                                    Picklist_Value__r.Id, 
                                                    Picklist_Value__r.Category__c, 
                                                    Picklist_Value__r.Standard_Scale__c, 
                                                    Name,
                                                    Picklist_Value__r.Name 
                                                    from Grade_Scale_Catalog_Scale__c where Grade_Scale_Catalog__c = :baseObj.activeSetup.Grade_Scale_Catalog__c AND (Picklist_Value__r.Category__c = 'Points' OR Picklist_Value__r.Category__c = 'Standards') order by picklist_value__r.name];
                    
        }
        for(Grade_Scale_Catalog_Scale__c pv: gscs){ 
            if(pv.Picklist_Value__r.Name == 'Points'||pv.picklist_value__r.category__c=='Points'){
                pointsGradeScaleID.add(pv.Picklist_Value__c);
            }
            
            if(pv.Picklist_Value__r.Category__c=='Standards'||pv.Picklist_Value__r.Standard_Scale__c){
                standardScaleOptions.add(new SelectOption(pv.Picklist_Value__c, pv.Picklist_Value__r.Name));
                standardScaleMap.put(pv.Picklist_Value__r.Name, pv.Picklist_Value__c);
            }

            //Make sure that all grade scales go here (yes, even standards)
            if (pv.Picklist_Value__c!=null) {
                gradeScaleOptions.add(new SelectOption(pv.Picklist_Value__c, pv.Picklist_Value__r.Name));
                gradeScaleMap.put(pv.Picklist_Value__r.Name, pv.Picklist_Value__c);
            }

        }       
    }
    
    //flow functions
    public void newAssignmentFlow() {
        initializeRenderState();
        rNew = true;
        rExisting = false;
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
    
    //deprecated
    public void addStandards() {
        if(standardBased && !standardOnly) {
            rStandardScale = true;
        }
        searchFeature.addMethod();
    }
    
    //deprecated
    public void removeStandards() {
        searchFeature.removeMethod();
        if(!searchFeature.showStandards) {
            rStandardScale = false;
            assignmentWrapper.standardGradeScale = null;
        }
    }
    
    //deprecated
    public void doNotAddStandards() {
        //hybrid state: the render state will control if this is displayed or not
        searchFeature.removeStandards();
        if(assignmentWrapper.assignmentStandards.size() > 0) {
            assignmentWrapper.assignmentStandards.clear();
        }
        rStandardScale = false;
        assignmentWrapper.standardGradeScale = null;
    }
    
    //Optional Details
    public void newFlowChoice() {
        if(sectionOrCourseChoice == 'section') {
            rDetails = true;
            rCourse = false;
        }
        else if(sectionOrCourseChoice == 'course') {
            rCourse = true;
            rDetails = false;
        }       
    }
    
    public void setGradebookName() {
        //provide gradebookName shorthand
        if(String.isEmpty(assignmentWrapper.gradebookName) && String.isNotEmpty(assignmentWrapper.assignmentName)) {
            if(assignmentWrapper.assignmentName.length() > 5) {
                assignmentWrapper.gradebookName = assignmentWrapper.assignmentName.substring(0,5);
            }
            else {
                assignmentWrapper.gradebookName = assignmentWrapper.assignmentName;
            }
        }
    }
    
    public void renderPointsField() {
        if(pointsGradeScaleID.contains(assignmentWrapper.gradeScale)) {
            rPoints = true;
            //DE3684 remove Integer controlling from the assignment grade scale level
            //rIntegers = false;
        }
        else {
            rPoints = false;
            //DE3684 remove Integer controlling from the assignment grade scale level
            //rIntegers = !courseUsePercentages.get(assignmentWrapper.assignmentCourse);
            assignmentWrapper.assignmentPossiblePoints = null;
        }
    }   
    
    public void existingAssignmentFlow() {
        initializeRenderState();
        rNew = false;
        rExisting = true;
        selectedAssignmentTypeOptions = new List<SelectOption>();
    }
    
    public void selectAssignment() {
        searchAssignmentID = ApexPages.currentPage().getParameters().get('assignmentLibraryID');
        assignmentWrapper.selectAssignmentMethod(searchAssignmentID);
        searchFeature.searchStandardResults.clear();
        if(assignmentWrapper.assignmentStandards.size() > 0) {
            searchFeature.addStandards(assignmentWrapper.assignmentStandards);
        
            //removed for Summer 2014
            //DE3588
            //rStandardScale = true;
        }
        
        //set other control parameters
        if(standardBased) {
            rStandards = true;
            if(!standardOnly) {
                
            }
            else {
                //DE3532
                //set the grade scale from the assignment library
                if(standardBased && standardOnly) {
                    try {
                        assignmentWrapper.gradeScale = standardScaleMap.get(courseToScaleNameMap.get(assignmentWrapper.assignmentCourse));
                        assignmentWrapper.standardGradeScale = standardScaleMap.get(courseToScaleNameMap.get(assignmentWrapper.assignmentCourse));
                        system.debug('*~*~* gradeScale: ' + assignmentWrapper.gradeScale);
                        system.debug('*~*~* standardGradeScale: ' + assignmentWrapper.standardGradeScale);
                    }
                    catch(Exception e) {  //legacy scale looking for assignment with Standards
                        if(standardScaleMap.containsKey(courseToScaleMap.get(assignmentWrapper.assignmentCourse))) {
                        assignmentWrapper.gradeScale = standardScaleMap.get(courseToScaleMap.get(assignmentWrapper.assignmentCourse));
                        assignmentWrapper.standardGradeScale = standardScaleMap.get(courseToScaleMap.get(assignmentWrapper.assignmentCourse));
                            system.debug('*~*~* exception -> gradeScale: ' + assignmentWrapper.gradeScale);
                            system.debug('*~*~* exception -> standardGradeScale: ' + assignmentWrapper.standardGradeScale);                 
                        }
                        else {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'The Grade Scale on Course is not of a Standard type')); 
                        }
                    }
                }   
            }
        }
        setSelectedAssignmentTypeOptions();
        setGradebookName();
        setDefaultAssignmentWeighting();
    }
    
    public void searchAssignmentMethod() {
        searchFeature.searchStandardResults.clear();
        assignmentWrapper.searchMethod();
    }
    
    public pageReference submit() {
        //populate the reportingPeriodMap and the dueDateMap in assignmentWrapper
        if(validateSubmit(sectionOrCourseChoice)) {
            if(rNew && !rExisting) {
                if(sectionOrCourseChoice == 'section') {
                    //need to create assignment library
                    assignmentWrapper.createAssignmentLibrary();
                    assignmentWrapper.createAssignments();
                }
                else if(sectionOrCourseChoice == 'course') {
                    assignmentWrapper.createAssignmentLibrary();    
                }
            }
            else if(rExisting && !rNew) {
                if(sectionOrCourseChoice == 'section') {
                    //use existing library
                    assignmentWrapper.createAssignments();
                }
                else if(sectionOrCourseChoice == 'course') {
                    //creat new library from existing
                    assignmentWrapper.createNewLibraryFromExisting();
                }
            }
            else {
                //what did we do?!?!?!
                system.debug('*~*~* failed after validateSubmit');
            }
            
            //only if successful can we do this
            pageReference p;
            if(assignmentWrapper.attachAssignment) {
                String temp1 = 'false';
                String temp2 = ApexPages.currentPage().getParameters().get('fromGradeBook');
                p = new pageReference('/apex/Gradebook_AttachAssignment' + '?id='+assignmentWrapper.assignmentLibrary.ID +'&aName='+assignmentWrapper.assignmentName +'&createNew='+temp1 +'&fromGradeBook='+temp2);
                p.setRedirect(true);
                return p;
            }
            else {
                /*
                if(standardBased && standardOnly) {

                    p = new pageReference('/apex/gradebook_so');
                    for(sectionWrapper s : sections) {
                        if(s.selected) {
                            p = new pageReference('/apex/gradebook_so?fromAssignment=1&section=' + s.sectionID + '&assignmentID=' + assignmentWrapper.sectionToAssignmentIDs.get(s.sectionID) +'&timeid=' + assignmentWrapper.sectionToReportingPeriods.get(s.sectionID));
                            break;
                        }
                    }

                    for(sectionWrapper g : gradebookGroups) {
                        if(g.selected) {
                            p = new pageReference('/apex/gradebook_so?fromAssignment=1&section=' + assignmentWrapper.groupToParentSection.get(g.sectionID) + '&assignmentID=' + assignmentWrapper.sectionToAssignmentIDs.get(g.sectionID) +'&timeid=' + assignmentWrapper.sectionToReportingPeriods.get(g.sectionID));
                            break;
                        }
                    }
                }
                else {
                    p = new pageReference('/apex/gradebook');
                    for(sectionWrapper s : sections) {
                        if(s.selected) {
                            p = new pageReference('/apex/gradebook?fromAssignment=1&section=' + s.sectionID + '&assignmentID=' + assignmentWrapper.sectionToAssignmentIDs.get(s.sectionID) +'&timeid=' + assignmentWrapper.sectionToReportingPeriods.get(s.sectionID));
                            break;
                        }
                    }
                    
                    for(sectionWrapper g : gradebookGroups) {
                        if(g.selected) {
                            p = new pageReference('/apex/gradebook?fromAssignment=1&section=' + assignmentWrapper.groupToParentSection.get(g.sectionID) + '&assignmentID=' + assignmentWrapper.sectionToAssignmentIDs.get(g.sectionID) +'&timeid=' + assignmentWrapper.sectionToReportingPeriods.get(g.sectionID));
                            break;
                        }
                    }
                }
                */
                
                p = new pageReference('/apex/Gradebook_v2');
                
                for(sectionWrapper s : sections) {
                    if(s.selected) {
                        p = new pageReference('/apex/Gradebook_v2?fromAssignment=1&sID=' + s.sectionID + '&aID=' + assignmentWrapper.sectionToAssignmentIDs.get(s.sectionID) +'&tID=' + assignmentWrapper.sectionToReportingPeriods.get(s.sectionID));
                    }
                }
                
                for(sectionWrapper g : gradebookGroups) {
                    if(g.selected) {
                        p = new pageReference('/apex/Gradebook_v2?fromAssignment=1&sID=' + assignmentWrapper.groupToParentSection.get(g.sectionID) + '&aID=' + assignmentWrapper.sectionToAssignmentIDs.get(g.sectionID) +'&tID=' + assignmentWrapper.sectionToReportingPeriods.get(g.sectionID));
                        break;
                    }
                }               
                
                p.setRedirect(true);
                return p;
            }           
            
        }
        else {
            system.debug('*~*~* validateSubmit failed');
        }
        return null;
    }
    
    public pageReference submitAndNew() {
        if(validateSubmit(sectionOrCourseChoice)) {
            if(rNew && !rExisting) {
                if(sectionOrCourseChoice == 'section') {
                    //need to create assignment library
                    assignmentWrapper.createAssignmentLibrary();
                    assignmentWrapper.createAssignments();
                }
                else if(sectionOrCourseChoice == 'course') {
                    assignmentWrapper.createAssignmentLibrary();    
                }
            }
            else if(rExisting && !rNew) {
                if(sectionOrCourseChoice == 'section') {
                    //use existing library
                    assignmentWrapper.createAssignments();
                }
                else if(sectionOrCourseChoice == 'course') {
                    //creat new library from existing
                    assignmentWrapper.createNewLibraryFromExisting();
                }
            }
            else {
                //what did we do?!?!?!
                system.debug('*~*~* failed after validateSubmit');
            }
            
            //only if successful can we do this
            pageReference p;
            if(assignmentWrapper.attachAssignment) {
                String temp1 = 'false';
                String temp2 = ApexPages.currentPage().getParameters().get('fromGradeBook');
                p = new pageReference('/apex/Gradebook_AttachAssignment' + '?id='+assignmentWrapper.assignmentLibrary.ID +'&aName='+assignmentWrapper.assignmentName +'&createNew='+temp1 +'&fromGradeBook='+temp2);
                p.setRedirect(true);
                return p;
            }
            else {          
                p = new pageReference('/apex/Gradebook_AddAssignments_v2?fromGradebook=true');
                p.setRedirect(true);
                return p;
            }       
        }
        else {
            system.debug('*~*~* validateSubmit failed');
        }
        return null;            
    }
    
    private void initializeRenderState() {
        sections = new List<Gradebook_AssignmentController_v2.sectionWrapper>();
        gradebookGroups = new List<Gradebook_AssignmentController_v2.sectionWrapper>();
        selectedAssignmentTypeOptions = new List<SelectOption>();
        gradeScaleOptions = new List<SelectOption>();
        standardScaleOptions = new List<SelectOption>();
        assignmentWrapper = new Gradebook_AssignmentWrapper_v2(standardBased, standardOnly);
        standardInitialize();
        if(rNew) {
            sectionOrCourseChoice = 'section';
            rContinue = false;
        }
        rDetails = true;
        rCourse = false;
        rPoints = false;
        //rIntegers = true;
        rGroups = false;
        //rColor = true;
        
        try {
            searchFeature.showStandards = true;
        }
        catch(Exception e) {
            //allow passing
        }           
    }
    
    public Boolean validateSubmit(String sectionCourse) {
        //Summer 2014 Enhancement: tell the user all that is wrong with the form! (Modern Design Techniques)
        
        //innocent until proven guilty!
        Boolean bValue = true;
        List<sectionWrapper> selectedSections = new List<sectionWrapper>();
        
        //add this message
        if(assignmentWrapper.assignmentCourse == null) {
            ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Select Course: Please select the course for which you want to create the assignment.'));
            bValue = false;
        }
        
        if(String.isEmpty(assignmentWrapper.assignmentName)) {
            ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Assignment Name: Please enter the name of the assignment.'));
            bValue = false;
        }
        
        if(sectionCourse == 'section') {
            if(String.isEmpty(assignmentWrapper.gradebookName)) { 
                ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Name in Gradebook: Please enter the name you want to display for the assignment in the gradebook.'));
                bValue = false;
            }
            else if(assignmentWrapper.gradebookName.length() > 5) {
                ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Name in Gradebook: Please shorten the gradebook name to 5 characters or less.'));
                bValue = false;
            }
        }
        
        if(String.isEmpty(assignmentWrapper.assignmentType)) {
            ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Assignment Type: Please select an assignment type.'));
            bValue = false;
        }
        
        if(assignmentWrapper.assignmentWeighting == null && rIntegers && sectionCourse == 'section') {
            ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Weighting Value: Please enter a weighting value for the assignment.'));
            bValue = false;
        }
        
        if(assignmentWrapper.gradeScale == null && rGradeScale && sectionCourse == 'section') {
            ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Grading Scale: Please select the grading scale you want the assignment to use.'));
            bValue = false;
        }
        
        if(rPoints && sectionCourse == 'section') {
            if(String.isEmpty(assignmentWrapper.assignmentPossiblePoints)) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'Possible Points: You selected a points grading scale. Please enter the possible points for the assignment.'));
                bValue = false;
            }
            else {
                try {
                    if(Integer.valueOf(assignmentWrapper.assignmentPossiblePoints) <= 0) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'Possible Points: must be greater than 0.'));
                        bValue = false;
                    }
                }
                catch(Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'Possible Points: must be an integer.'));
                    bValue = false;
                }
            }
        }
        
        //for section/course option
        if(standardBased) {
            //populate stanards on assignment
            assignmentWrapper.assignmentStandards = searchFeature.getSelectedStandards();   
            assignmentWrapper.standardToUse = searchFeature.getStandardToInclude();     
            
            //SO
            if(standardOnly) {
                if(assignmentWrapper.assignmentStandards.size() == 0) {
                    ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Standards: Please select the standard(s) you want to associate to this assignment.'));
                    bValue = false;
                }
            }
            //hybrid
            else {
                //no special rule
            }
        }

        if(standardBased) {
            if(standardOnly) {
                //only use case was captured above
            }
            else {          
                if(assignmentWrapper.standardGradeScale == null && assignmentWrapper.assignmentStandards.size() > 0 && sectionOrCourseChoice == 'section') {
                    ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Standards Grading Scale: You added standards to this assignment. Please select a standards grading scale.'));
                    bValue = false;
                }   
            }
        }
            
        if(sectionOrCourseChoice == 'section') {    
            Map<ID, ID> returnGroupToParentSection = new Map<ID, ID>();
            //general validation: includes section selection, due dates, and section reporting periods selected
                
            for(sectionWrapper sWrapper : sections) {
                if(sWrapper.selected) {
                    selectedSections.add(sWrapper);
                }
            }
            
            for(sectionWrapper sWrapper : gradebookGroups) {
                if(sWrapper.selected) {
                    selectedSections.add(sWrapper);
                    returnGroupToParentSection.put(sWrapper.sectionID, sWrapper.parentSectionID);
                }
            }
                
            //modify for adding only to library...
            if(selectedSections.size() == 0 && assignmentWrapper.assignmentCourse != null) {
                ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Select Sections: Please select the section(s) to which you want to add the assignment.'));
                bValue = false;
            }
    
            //check for dueDate error
            Map<ID, Date> returnSectionDueDates = new Map<ID, Date>();
            Map<ID, ID> returnSectionReportingPeriods = new Map<ID, ID>();          
                
            for(sectionWrapper s : selectedSections) {
                if(!returnSectionReportingPeriods.containsKey(s.sectionID)) {
                    if(s.reportingPeriod != null) {
                        returnSectionReportingPeriods.put(s.sectionID, s.reportingPeriod);
                    }
                    else {
                        system.debug('*~*~* Error in sectionReportingPeriod! reportingPeriod is null: ' + s);
                        //this one should be impossible unless the data is that bad...
                        ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Reporting Period: Please select a reporting Period for ' + s.sectionName));
                        bValue = false;
                    }
                }
                    
                if(!returnSectionDueDates.containsKey(s.sectionID)) {
                    if(s.dueDate != null) {
                        try {
                            Date tempDate = Date.Parse(s.dueDate);
                            system.debug('*~*~* tempDate: ' + tempDate);
                            
                            //validate time frame
                            if(tempDate < timeMap.get(returnSectionReportingPeriods.get(s.sectionID)).Date_Start_Date__c || tempDate > timeMap.get(returnSectionReportingPeriods.get(s.sectionID)).End_Date__c) {
                                ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Due Date: Please enter an assignment due date within the dates of the selected reporting period for ' + s.sectionName + '.'));
                                bValue = false;
                            }                       
                            
                            returnSectionDueDates.put(s.sectionID, tempDate);                       
                        }
                        catch(Exception e) {
                            system.debug('*~*~* Error in sectionDueDate! dueDate is: ' + s);
                            if(String.isEmpty(s.dueDate)) {
                                ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Due Date: Please enter an assignment due date for ' + s.sectionName + '.'));
                            }
                            else {
                                ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Due Date: ' + s.dueDate + ' is malformed for ' + s.sectionName + '.'));
                            }
                            bValue = false;
                        }
                    }
                    else {
                        system.debug('*~*~* Error in sectionDueDate! dueDate is null: ' + s);
                        if(String.isEmpty(s.dueDate)) {
                            ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Due Date: Please enter an assignment due date for ' + s.sectionName + '.'));
                        }   
                        bValue = false;
                    }
                }
                else {
                    //should never get in here!
                    system.debug('*~*~* Error in sectionDueDate! Map already contains sectionID as key: ' + s);
                    ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Due Date: Please provide a due date for ' + s.sectionName));
                    bValue = false;
                }
            }
    
            //if it got through all of that validation, then the dueDates and the reportingPeriods should be good!
            assignmentWrapper.sectionToDueDate = returnSectionDueDates;
            assignmentWrapper.sectionToReportingPeriods = returnSectionReportingPeriods;
            assignmentWrapper.groupToParentSection = returnGroupToParentSection;
        }
            
        return bValue;
    }
    
    public pageReference cancel(){ //cancel returns to the home page and deletes the new assignment library (if it was made)
        /*
        if((ApexPages.currentPage().getParameters().get('fromGradeBook')=='true')){
            pageReference p;
            if(standardOnly) {
                p = new pageReference('/apex/gradeBook_SO');
            }
            else {
                p = new pageReference('/apex/gradeBook');
            }
            p.setRedirect(true);
            return p;
        }
        else {
            pageReference p = new pageReference('/home/home.jsp'); //cancel simply takes the user back to the home page
            p.setRedirect(true);
            return p;
        }
        */
        pageReference p = new pageReference('/apex/Gradebook_v2');
        p.setRedirect(true);
        return p;
    }   
    
    //helper class to display sections the teacher has
    public class sectionWrapper {
        public Boolean selected {get; set;}
        public String dueDate {get; set;}
        public ID sectionID {get; set;}
        public string sectionName {get; set;}
        public ID parentSectionID {get; set;}
        public string parentSectionName {get; set;}
        
        public Boolean mainSection {get; set;}  //Is_Section__c determines if section or group on section
        public Integer numberOfStudents {get; set;}
        public String periods {get; set;}
        public ID reportingPeriod {get; set;}
        public List<SelectOption> reportingPeriodOptions {get; set;}
        
        public sectionWrapper(ID sID, String sName, Boolean g, List<SelectOption> rpOptions, Integer nStudents, String p) {
            selected = false;
            sectionID = sID;
            sectionName = sName;
            mainSection = g;
            reportingPeriodOptions = rpOptions;
            numberOfStudents = nStudents;
            periods = p;
        }
        
        public sectionWrapper(ID sID, String sName, Boolean g, ID gID, String gName, List<SelectOption> rpOptions, Integer nStudents, String p) {
            selected = false;
            sectionID = sID;
            sectionName = sName;
            parentSectionID = gID;
            parentSectionName = gName;
            mainSection = g;
            reportingPeriodOptions = rpOptions;
            numberOfStudents = nStudents;
            periods = p;
        }
        
        public void setDefaultReportingPeriod(Map<ID, Time_Element__c> timeMap) {
            //constructor logic to set the reportingperiod based on todays date and the available time map
            try {
                for(SelectOption so : this.reportingPeriodOptions) {
                    Date sd = timeMap.get(so.getValue()).Date_Start_Date__c;
                    Date ed = timeMap.get(so.getValue()).End_Date__c;
                    
                    if(reportingPeriod == null) {
                        reportingPeriod = so.getValue();
                    }
                    else {
                        if(system.today() >= sd && system.today() <= ed) {
                            if(timeMap.get(so.getValue()).Reporting_Period__c) {
                                reportingPeriod = so.getValue();
                            }
                        }
                    }
                }
                if(system.today() > timeMap.get(reportingPeriodOptions[reportingPeriodOptions.size() - 1].getValue()).End_Date__c) {
                    reportingPeriod = reportingPeriodOptions[reportingPeriodOptions.size() - 1].getValue();
                }
            }
            catch(Exception e) {
                System.debug('\n\n e.getLineNumber() => ' + e.getLineNumber() + '\n');
                System.debug('\n\n e.getMessage() => ' + e.getMessage() + '\n');
                ApexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, 'Failed to set default reporting period!'));
            }           
        }
    }
}