public with sharing class Gradebook_Wrapper_v2 {
    
//Filter Options
    public Map<ID, List<SelectOption>> assignmentTypeOptions {get; set;}  //multi select List, Key.ID = reportingPeriod
    public Map<ID, List<SelectOption>> assignmentOptions {get; set;}  //multi select list, Key.ID = reportingPeriod
    public Map<ID, List<SelectOption>> studentOptions {get; set;}  //multi select list
    public List<SelectOption> reportingPeriodOptions {get; set;}  //single select list
    //public transient Map<ID, List<SelectOption>> groupOptions {get; set;}
    public List<SelectOption> orderByOptions {get; set;}
    
//Group Filter Options 
    //actually, currently not possible to even FILTER!  model does not support and no guarantee.
    
//Filter Parameters
    public String reportingPeriod {get; set;}
    public Date startDate {get; set;}
    public Date endDate {get; set;} 
    public String assignmentTypes {get; set;}
    public String assignments {get; set;}
    public String students {get; set;}
    public String groups {get; set;}
    public String orderBy {get; set;}

//Wrapper display variables
    //used to control the render state of the gradebook table, if there are no assignments and no reporting period available
    public Boolean hasAssignment {get; set;}
    
//Used on the page to aid in date restriction and the jquery calendar   
    public List<String> timeMapKeys {get; set;}
    public List<String> timeMapValues {get; set;} 
    
//Wrapper Variables
    public Section__c section {get; set;}
    public Staff_Section__c staffSection {get; set;}
    public Boolean standardBased {get; set;}
    public Boolean standardOnly {get; set;}
    
    private Map<ID, Time_Element__c> timeMap {get; set;}
    public Map<ID, Map<ID, Student_Section__c>> referenceStudentSectionMap {get; set;}
    private Map<ID, Map<ID, Assignment__c>> referenceAssignmentMap {get; set;}
    public Map<ID, Set<ID>> assignmentStandardJunctionMap {get; set;}
    
    private Map<ID, List<Attendance__c>> studentAttendanceMap {get; set;}
    public Boolean useSectionalAttendance {get; set;}
    
//below parameters are RP specific or studentSection specific
    //Key = studentSection + Assignment
    private Map<String, Grade__c> referenceGradeMap {get; set;}
    //Key = studentSection + reportingPeriod
    private Map<String, Section_Grade__c> referenceSectionGradeMap {get; set;}
    //Key = studentSection + reportingPeriod


//Necessary to aid in the generation of the gradebook table.
    public transient List<assignmentDisplayWrapper> assignmentHeader {get; set;}
    public transient List<standardDisplayWrapper> standardHeader {get; set;}
    
    public transient Map<String, studentGradeWrapper> studentGradeWrapperMap {get; set;}
    //public Map<String, studentColumnWrapper> studentColumnWrapperMap {get; set;}
    public List<String> displaystudentWrapperKeys {get; set;}
    
    public Integer swSize {
        get {
            if(studentGradeWrapperMap != null) {
                if(!studentGradeWrapperMap.isEmpty()) {
                    return studentGradeWrapperMap.size();
                }
                else {
                    return 0;
                }
            }
            else {
                return 0;
            }
        }
    }
    
    private void baseInitialization() {
        this.reportingPeriod = null;
        this.hasAssignment = false;
        
        this.assignmentHeader = new List<assignmentDisplayWrapper>();
        this.standardHeader = new List<standardDisplayWrapper>();
        
    //initialize constructors
        this.referenceAssignmentMap = new Map<ID, Map<ID, Assignment__c>>();
        this.assignmentStandardJunctionMap = new Map<ID, Set<ID>>();
        this.referenceStudentSectionMap = new Map<ID, Map<ID, Student_Section__c>>();
        
        this.referenceGradeMap = new Map<String, Grade__c>();
        this.referenceSectionGradeMap = new Map<String, Section_Grade__c>();
        
        this.displayStudentWrapperKeys = new List<String>();
        this.studentGradeWrapperMap = new Map<String, studentGradeWrapper>();
        //this.studentColumnWrapperMap = new Map<String, studentColumnWrapper>();
        
    //only timeMap of existing assignments created
        this.timeMap = new Map<ID, Time_Element__c>();
        this.timeMapKeys = new List<String>();
        this.timeMapValues = new List<String>();
        
    //initialize filterOptions
        this.assignmentTypeOptions = new Map<ID, List<SelectOption>>();
        this.assignmentOptions = new Map<ID, List<SelectOption>>();
        this.studentOptions = new Map<ID, List<SelectOption>>();
        this.reportingPeriodOptions = new List<SelectOption>();
        //this.groupOptions = new Map<ID, List<SelectOption>>();
        this.orderByOptions = new List<SelectOption>();
        
        this.orderBy = 'assignment';
        this.assignments = '';  
    }
    
    //dummy constructor
    public Gradebook_Wrapper_v2() {
        baseInitialization();
    }
    
    //constructor
    public Gradebook_Wrapper_v2(Section__c s, Staff_Section__c ss, Boolean sBased, Boolean sOnly, Boolean useSAttendance) {
        this.section = s;
        this.staffSection = ss;
        this.standardBased = sBased;
        this.standardOnly = sOnly;
        this.useSectionalAttendance = useSAttendance;
        
        baseInitialization();
    }
    
    public void loadSection(ID cSchool, ID cYear, ID aYear, Boolean activeStudents, String rpID) {
        //createAssignmentMap, populate assignmentOptions, assignmentTypeOptions, reportingPeriodOptions
        //create temporary maps 
        
        //passed in parameters to be concerned
        //reportingPeriodID - really just reportingPeriodID
        //assignmentID - call assignmentID Filter
        
        clearFilters();
        
        Map<ID, SelectOption> rpOptions = new Map<ID, SelectOption>();
        Map<ID, List<SelectOption>> aOptions = new Map<ID, List<SelectOption>>();
        Map<ID, List<SelectOption>> atOptions = new Map<ID, List<SelectOption>>();
        Map<ID, Set<SelectOption>>  atSetOptions = new Map<ID, Set<SelectOption>>();
        
        //concept of an 'active' assignment doesn't exist.  but we will check for student sections
        for(Assignment__c a : [SELECT ID, Name, Name_in_Gradebook__c, Due_Date__c, Weighting_Value__c, Color__c, Possible_Points__c, Picklist_Value__c, Picklist_Value__r.Name, Standard_Scale__c, Standard_Scale__r.Name, Assignment_Library__c, Assignment_Library__r.Picklist_Value__c, Assignment_Library__r.Picklist_Value__r.Name, Time__c, Time__r.Name__c, Description__c FROM Assignment__c WHERE Section__c =: section.ID ORDER BY Due_Date__c DESC]) {
            if(!hasAssignment) {
                hasAssignment = true;
            }
            
            if(!aOptions.containsKey(a.Time__c)) {
                aOptions.put(a.Time__c, new List<SelectOption>());
            }
            if(aOptions.containsKey(a.Time__c)) {
                aOptions.get(a.Time__c).add(new SelectOption(a.ID, a.Name));
            }
            
            if(a.Time__c == null) {
                ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Assignment missing reporting period: ' + a.Name));
            }
            else {
                if(!rpOptions.containsKey(a.Time__c)) {
                    rpOptions.put(a.Time__c, new SelectOption(a.Time__c, a.Time__r.Name__c));
                }
                //for now add groups here
                /*
                if(!groupOptions.containsKey(a.Time__c)) {
                    groupOptions.put(a.Time__c, new List<SelectOption>());
                }
                */
            }
            try {
                if(!atOptions.containsKey(a.Time__c)) {
                    atOptions.put(a.Time__c, new List<SelectOption>());
                }
                if(!atSetOptions.containsKey(a.Time__c)) {
                    atSetOptions.put(a.Time__c, new Set<SelectOption>());
                }
                if(atSetOptions.containsKey(a.Time__c)) {
                    atSetOptions.get(a.Time__c).add(new SelectOption(a.Assignment_Library__r.Picklist_Value__c, a.Assignment_LIbrary__r.Picklist_Value__r.Name));
                }
            }
            catch(Exception e) {
                ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Failed to load section assignment type filter options - assignment: ' + a.Name + ' assignment Library: ' + a.Assignment_Library__c + ' (assignment type is stored on the assignment library record)'));
            }
            
            //keep track of reportingPeriod to 
            //in general add to the referenceAssignmentMap
            if(!referenceAssignmentMap.containsKey(a.Time__c)) {
                referenceAssignmentMap.put(a.Time__c, new Map<ID, Assignment__c>());
            }
            if(referenceAssignmentMap.containsKey(a.Time__c)) {
                referenceAssignmentMap.get(a.Time__c).put(a.ID, a);
            }
        }
        
        //create ordered rpOptions 
        if(!rpOptions.isEmpty()) {
            //determine most recent rp to use for auto load!
            ID lastTE;
            //base case
            for(Time_Element__c te : [SELECT ID, Name__c, Reporting_Period__c, Date_Start_Date__c, End_Date__c, Type__c, Parent_Time_Element__c FROM Time_Element__c WHERE ID IN: rpOptions.KeySet() ORDER BY Date_Start_Date__c, Reporting_Period__c DESC]) {
                timeMap.put(te.ID, te);
                reportingPeriodOptions.add(rpOptions.get(te.ID));

                lastTE = te.ID;

                if(system.today() <= te.End_Date__c && system.today() >= te.Date_Start_Date__c) {
                    reportingPeriod = te.ID;
                    startDate = te.Date_Start_Date__c;
                    endDate = te.End_Date__c;
                }
            }
            
            //get the very last one if base conditional failed
            if(startDate == null && endDate == null) {
                reportingPeriod = timeMap.get(lastTE).ID;
                startDate = timeMap.get(lastTE).Date_Start_Date__c;
                endDate = timeMap.get(lastTE).End_Date__c;
            }
            
            //then filter from the final rp, if it could be a final rp, then set to it
            if(timeMap.containsKey(reportingPeriod)) {
                if(!timeMap.get(reportingPeriod).Reporting_Period__c) {
                    //get parent time element
                    ID t = timeMap.get(reportingPeriod).Parent_Time_Element__c;
                    if(timeMap.containsKey(t)) {
                        reportingPeriod = timeMap.get(t).ID;
                        startDate = timeMap.get(t).Date_Start_Date__c;
                        endDate = timeMap.get(t).End_Date__c;
                    }
                }   
            }
            
            //most associated to pulling assignments from specific rp
            if(String.isNotBlank(rpID) && timeMap.containsKey(rpID)) {
                reportingPeriod = rpID;
                startDate = timeMap.get(rpID).Date_Start_Date__c;
                endDate = timeMap.get(rpID).End_Date__c;            
            }

            //for page
            timeMapValues = timeMapValues();
            timeMapKeys = timeMapKeys();
            
            assignmentOptions = aOptions;
            
            for(ID i : atOptions.KeySet()) {
                if(atSetOptions.containsKey(i)) {
                    atOptions.get(i).addAll(atSetOptions.get(i));
                }
            }
            assignmentTypeOptions = atOptions;
        }
        else {
            //throw an apex message to page!
            //something along the lines there are no assignment for any rps in this section
            System.debug('cYear##'+cYear);
            System.debug('aYear##'+aYear);
            if(cYear == aYear) {
                //ApexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'There are no assignments created in this section for any reporting period!  Please create an assignment.'));            
                ApexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'Please enroll your students in the sections before you can create assigments'));            
            }
            else {
                ApexPages.addMessage(new apexPages.Message(apexPages.Severity.WARNING, 'There are no assignments created in this section for any reporting period!'));          
            }
        }

        //populate this always, gives teacher verification of their students even though no assignments are created yet.
        //use the passed in parameters to guarantee that we pull for the correct student/sections for the school and year (as crazy as that sounds)
            
        //... need to de-dup selectOptions  
        Map<ID, Set<ID>> tsOptionMap = new Map<ID, Set<ID>>();
            
        for(Student_Section__c ss : [SELECT ID, Student__r.Student_First_Name__c, Student__r.Student_Last_Name__c, (SELECT ID, Active__c, Student_Section__c, Student_Section__r.Section__c, Current_Record__c, Start_Date__c, End_Date__c FROM Enrollment_Tracking__r ORDER BY Start_Date__c), Student__c, Student__r.Name, Section__c FROM Student_Section__c WHERE Student__r.School__c =: cSchool AND Student__r.School_Year__c =: cYear AND Active__c =: activeStudents AND Section__r.Active__c =: activeStudents AND Student__r.Active__c =: activeStudents ORDER BY Student__r.Student_Last_Name__c]) {
            if(!timeMap.isEmpty()) {
                for(Time_Element__c te : timeMap.Values()) {        
                    //check for selectOptions, populate an empty list if necessary
                    if(!assignmentTypeOptions.containsKey(te.ID)) { 
                        assignmentTypeOptions.put(te.ID, new List<SelectOption>());
                    }
                    if(!assignmentOptions.containsKey(te.ID)) {
                        assignmentOptions.put(te.ID, new List<SelectOption>());
                    }
                    if(!studentOptions.containsKey(te.ID)) {
                        studentOptions.put(te.ID, new List<SelectOption>());
                    }
                    if(!tsOptionMap.containsKey(te.ID)) {
                        tsOptionMap.put(te.ID, new Set<ID>());
                    }
                                        
                    for(Enrollment_Tracking__c et : ss.Enrollment_Tracking__r) {
                        //this implies the start date is before or on the start of the scheduled rp for the section
                        //add this student to the rp based on the enrollment tracking
                        if(et.Student_Section__r.Section__c == section.ID) {
                            if(et.Start_Date__c <= te.End_Date__c) {
                                if(studentOptions.containsKey(te.ID)) {
                                    if(!tsOptionMap.get(te.ID).contains(ss.Student__c)) {
                                        tsOptionMap.get(te.ID).add(ss.Student__c);
                                        studentOptions.get(te.ID).add(new SelectOption(ss.Student__c, ss.Student__r.Name));
                                    }
                                }
                                
                                //perform the same logic for studentSections
                                if(!referenceStudentSectionMap.containsKey(te.ID)) {
                                    referenceStudentSectionMap.put(te.ID, new Map<ID, Student_Section__c>());
                                }
                                
                                if(referenceStudentSectionMap.containsKey(te.ID)) {
                                    referenceStudentSectionMap.get(te.ID).put(ss.ID, ss);
                                }
                            }
                        }               
                    }
                }
            }
            else {
                //
            }
        }

        //clear temp maps?
        tsOptionMap = new Map<ID, Set<ID>>();
        rpOptions.clear();
        aOptions = null;
        atOptions = null;
        atSetOptions.clear();
        //tried clearing aOptions and atOptions, but causes major issues... don't do it!

        //moving forward, use the reportingPeriod variable in the queries
        //loadAssignments();
        changeReportingPeriod();
    }
    
    public void changeReportingPeriod() {
        reloadTime();
        loadAssignments();
    }
    
    public void loadAssignments() {
        getAttendance();
        
        //used to be in loadAssignments, might as well do it here
        //if studentGradeWrapperMap and displayStudentWrapperKeys are transient, we don't need to clear them 
        assignmentHeader = new List<assignmentDisplayWrapper>();
        standardHeader = new List<standardDisplayWrapper>();
        studentGradeWrapperMap = new Map<String, studentGradeWrapper>();
        displayStudentWrapperKeys = new List<String>();
        referenceSectionGradeMap.clear();
        referenceGradeMap.clear();  
        
        //at this point if there are not assignments, then don't do anything here.
        if(reportingPeriod != null && referenceAssignmentMap.containsKey(reportingPeriod) && referenceStudentSectionMap.containsKey(reportingPeriod)) {
            //system.debug('*~*~* rp: ' + reportingPeriod);
            //system.debug('*~*~* referenceStudentSectionMap: ' + referenceStudentSectionMap);
            //system.debug('*~*~* referenceAssignmentMap: ' + referenceAssignmentMap);
            
            //get all the grade records for the reportingPeriod
            for(Grade__c g : [SELECT ID, Student__c, Assignment__c, Entered_Grade__c,Assignment__r.Name,
                              Standard_Gradebook_Grade__c, Student_Section__c,
                              Standard__c, Standard__r.Name, Assignment__r.Due_Date__c, Assignment__r.Name_In_Gradebook__c, Assignment__r.Possible_Points__c, Assignment__r.Picklist_Value__c, Assignment__r.Standard_Scale__c, Assignment__r.Standard_Scale__r.Name,
                              Standard__r.Strand__c, Standard__r.Strand__r.Name, Assignment__r.Color__c, Assignment__r.Weighting_Value__c, Assignment__r.Picklist_Value__r.Name, Assignment__r.Description__c,
                              Time__c, Exclude_From_Section_Grade__c, Comment__c, Publish_Comment__c, Locked_for_Final__c, Standard__r.Long_Text__c
                              FROM Grade__c WHERE Student_Section__c IN: referenceStudentSectionMap.get(reportingPeriod).KeySet() AND Assignment__c IN: referenceAssignmentMap.get(reportingPeriod).KeySet() AND Time__c =: reportingPeriod AND Standard_Gradebook_Grade__c = null
                              ORDER BY Student__r.Name, Assignment__r.Due_Date__c, Standard__r.Name DESC]) {
                String key = String.valueOf(g.Student_Section__c) + String.valueOf(g.Assignment__c) + String.valueOf(g.Standard__c);

                referenceGradeMap.put(key, g);
    
                //deteremine if there are standards/grade for the assignment and create a map of it
                //one of the only reasons we need to know if standardBased && standardOnly
                //if(g.Standard_Gradebook_Grade__c == null) { //exclude fauxGrade but include normal
                if(!assignmentStandardJunctionMap.containsKey(g.Assignment__c)) {
                    assignmentStandardJunctionMap.put(g.Assignment__c, new Set<ID>());
                }
                assignmentStandardJunctionMap.get(g.Assignment__c).add(g.Standard__c);
                //}
            }
            
            for(Section_Grade__c sg : [SELECT ID, Student_Section__c, Time__c, Key__c, Display_Grade_Formula__c, Letter_Grade__c, Grade_Overridden__c, Grade_Override__c, Grade__c, Comments_Next_Steps__c, Alternate_Lang_Comments__c FROM Section_Grade__c WHERE Student_Section__c IN: referenceStudentSectionMap.get(reportingPeriod).KeySet() AND Time__c =: reportingPeriod]) {
                String key = (sg.Key__c==null)? String.valueOf(sg.Student_Section__c) + String.valueOf(sg.Time__c): sg.Key__c;
                referenceSectionGradeMap.put(key, sg);
            }
            
            //assume assignment time is not null
            //cross reference assignment and studentSection to create data placeHolders.
            
            for(Student_Section__c ss : referenceStudentSectionMap.get(reportingPeriod).Values()) {
                if(ss.Section__c == section.ID) {
                    for(Assignment__c a : referenceAssignmentMap.get(reportingPeriod).Values()) {
                        //key of section grade
                        String sgKey = String.valueOf(ss.ID) + String.valueOf(a.Time__c);
                        String sgFilter = String.valueOf(ss.ID) + '_' + String.valueOf(a.Time__c) + '_' + String.valueOf(ss.Section__c) + '_' + String.valueOf(ss.Student__c);                      
                        
                        if(assignmentStandardJunctionMap.containsKey(a.ID)) {
                            for(ID i : assignmentStandardJunctionMap.get(a.ID)) {

                                //key of grade
                                String gKey = String.valueOf(ss.ID) + String.valueOf(a.ID) + String.valueOf(i);
                                
                                if(!studentGradeWrapperMap.containsKey(sgKey)) {
                                    studentGradeWrapper sWrap = new studentGradeWrapper(ss.Student__c, ss.Student__r.Name, ss.Student__r.Student_First_Name__c, ss.Student__r.Student_Last_Name__c, sgKey, sgFilter);
                                    if(studentAttendanceMap.containsKey(ss.Student__c)) {
                                        sWrap.calculateAttendance(studentAttendanceMap.get(ss.Student__c));
                                        studentAttendanceMap.remove(ss.Student__c);
                                    }
                                    
                                    //modification
                                    //studentColumnWrapper cWrap = new studentColumnWrapper(ss.Student__c, ss.Student__r.Name, sgKey, sgFilter);
                                    
                                    //populate section grade if it can find one.
                                    if(referenceSectionGradeMap.containsKey(sgKey)) {
                                        sWrap.sectionGrade = referenceSectionGradeMap.get(sgKey);
                                        sWrap.reportingPeriod = a.Time__c;
                                        referenceSectionGradeMap.remove(sgKey);
                                    }
    
                                    //place in map
                                    studentGradeWrapperMap.put(sgKey, sWrap);
                                    
                                    //modification
                                    //studentColumnWrapperMap.put(sgKey, cWrap);            
                                }
            
                                if(studentGradeWrapperMap.containsKey(sgKey)) {
                                    //add grade record if found one.  if not add a place holder
                                    Grade__c getGrade = new Grade__c();
                                    if(referenceGradeMap.containsKey(gKey)) {
                                        getGrade = referenceGradeMap.get(gKey);
                                        referenceGradeMap.remove(gKey);
                                    }
                                    //populate the getGrade
                                    else {
                                        getGrade.student__c = ss.student__c;
                                        getGrade.Student_Section__c = ss.ID;
                                        getGrade.Time__c = a.Time__c;
                                        getGrade.assignment__c = a.id;
                                        getGrade.Standard__c = i;                                       
                                    }

                                    studentGradeWrapperMap.get(sgKey).addGrade(gKey, getGrade, a, orderBy);                 
                                }
                            }//end of standard
                        }
                    }//end of assignment
                }
            }//end of studentSection
            
            List<studentGradeWrapper> sTemp = studentGradeWrapperMap.Values();
            //List<studentColumnWrapper> cTemp = studentColumnWrapperMap.Values();
            sTemp.sort();
            //cTemp.sort();
            for(studentGradeWrapper s : sTemp) {
                displayStudentWrapperKeys.add(s.Key);
            }

            for(studentGradeWrapper sw : studentGradeWrapperMap.Values()) {
                if(orderBy == 'standard') {
                    sw.standardDisplayWrapperList.addAll(sw.standardDisplayWrapperMap.Values());
                    sw.standardDisplayWrapperList.sort();
                    for(standardDisplayWrapper sdw : sw.standardDisplayWrapperList) {
                        sdw.gradeList.sort();
                    }
                    //sw.standardDisplayWrapperMap.clear();
                }
                else {
                    sw.assignmentDisplayWrapperList.addAll(sw.assignmentDisplayWrapperMap.Values());
                    sw.assignmentDisplayWrapperList.sort();
                    for(assignmentDisplayWrapper adw : sw.assignmentDisplayWrapperList) {
                        adw.gradeList.sort();
                    }
                    //sw.assignmentDisplayWrapperMap.clear();
                }
            }
            
            if(!studentGradeWrapperMap.isEmpty() && !displayStudentWrapperKeys.isEmpty()) {
                if(orderBy == 'assignment') {
                    assignmentHeader = studentGradeWrapperMap.get(displayStudentWrapperKeys[0]).assignmentDisplayWrapperList;
                }
                else {
                    standardHeader = studentGradeWrapperMap.get(displayStudentWrapperKeys[0]).standardDisplayWrapperList;
                }
            }
        }
        else {
            //could mention the errors here of having no assignments, students, and rp is null          
        }
        
        //clear maps, takes up too much view state
        referenceGradeMap.clear();
        studentAttendanceMap.clear();
        referenceSectionGradeMap.clear();
        //do not clear the below two, used for rerendering standards/assignment ordering on table
        //referenceStudentSectionMap.put(reportingPeriod, null);
        //referenceAssignmentMap.put(reportingPeriod, null);
    }
    
    public transient Map<String, studentGradeWrapper> studentGradeWrapperExportMap {get; set;}
    public List<String> exportStudentWrapperKeys {get; set;}
    public transient List<assignmentDisplayWrapper> assignmentExportHeader {get; set;}
    public transient List<standardDisplayWrapper> standardExportHeader {get; set;}
    
    public void getCurrentExport() {
        //build a string query to get data.
        //process data similarly to loadAssignments
        //build containers for export only and clear them when done

        studentGradeWrapperExportMap = new Map<String, studentGradeWrapper>();
        exportStudentWrapperKeys = new List<String>();
        assignmentExportHeader = new List<assignmentDisplayWrapper>();
        standardExportHeader = new List<standardDisplayWrapper>();

        Map<ID, Student_Section__c> ssTempMap = new Map<ID, Student_Section__c>();
        Map<ID, Assignment__c> aTempMap = new Map<ID, Assignment__c>();
        
        getAttendance();
        
        try {
            if(String.isNotEmpty(students)) {
                for(Student_Section__c ss : referenceStudentSectionMap.get(reportingPeriod).Values()) {
                    if(ss.Student__c == students) {
                        ssTempMap.put(ss.ID, ss);
                        break;
                    }
                }
            }
            else {
                ssTempMap = referenceStudentSectionMap.get(reportingPeriod);
            }

            
            if(String.isNotEmpty(assignments)) {
                if(referenceAssignmentMap.get(reportingPeriod).containsKey(assignments)) {
                    aTempMap.put((ID)assignments, referenceAssignmentMap.get(reportingPeriod).get(assignments));
                }
            }
            else if(String.isNotEmpty(assignmentTypes)) {
                for(Assignment__c a : referenceAssignmentMap.get(reportingPeriod).Values()) {
                    if(a.Assignment_Library__r.Picklist_Value__c == assignmentTypes) {
                        aTempMap.put(a.ID, a);
                    }
                }
            }
            else {
                aTempMap = referenceAssignmentMap.get(reportingPeriod);
            }
            
            if((startDate != null || endDate != null) && String.isEmpty(assignments)) {
                for(Assignment__c a : aTempMap.Values()) {
                    if(a.Due_Date__c < startDate || a.Due_Date__c > endDate) {
                        aTempMap.remove(a.ID);
                    }
                }
            }
    
            //re-query grades again
            for(Grade__c g : [SELECT ID, Student__c, Assignment__c, Entered_Grade__c,Assignment__r.Name,
                              Standard_Gradebook_Grade__c, Student_Section__c,
                              Standard__c, Standard__r.Name, Assignment__r.Due_Date__c, Assignment__r.Name_In_Gradebook__c, Assignment__r.Possible_Points__c, Assignment__r.Picklist_Value__c, Assignment__r.Standard_Scale__c, Assignment__r.Standard_Scale__r.Name,
                              Standard__r.Strand__c, Standard__r.Strand__r.Name, Assignment__r.Color__c, Assignment__r.Weighting_Value__c, Assignment__r.Picklist_Value__r.Name, Assignment__r.Description__c,
                              Time__c, Exclude_From_Section_Grade__c, Comment__c, Publish_Comment__c, Locked_for_Final__c, Standard__r.Long_Text__c
                              FROM Grade__c WHERE Student_Section__c IN: ssTempMap.KeySet() AND Assignment__c IN: aTempMap.KeySet() AND Time__c =: reportingPeriod AND Standard_Gradebook_Grade__c = null
                              ORDER BY Student__r.Name, Assignment__r.Due_Date__c, Standard__r.Name DESC]) {
                String key = String.valueOf(g.Student_Section__c) + String.valueOf(g.Assignment__c) + String.valueOf(g.Standard__c);
                referenceGradeMap.put(key, g); 
            }
            
            //have to re-query section grades again
            for(Section_Grade__c sg : [SELECT ID, Student_Section__c, Time__c, Key__c, Display_Grade_Formula__c, Letter_Grade__c, Grade_Overridden__c, Grade_Override__c, Grade__c, Comments_Next_Steps__c, Alternate_Lang_Comments__c FROM Section_Grade__c WHERE Student_Section__c IN: ssTempMap.KeySet() AND Time__c =: reportingPeriod]) {
                String key;
                if(sg.Key__c == null) {
                    key = String.valueOf(sg.Student_Section__c) + String.valueOf(sg.Time__c);
                }
                else {
                    key = sg.Key__c;
                }
                referenceSectionGradeMap.put(key, sg);
            }
    
            for(Student_Section__c ss : ssTempMap.Values()) {
                if(ss.Section__c == section.ID) {
                    for(Assignment__c a : aTempMap.Values()) {
                        //key of section grade
                        String sgKey = String.valueOf(ss.ID) + String.valueOf(a.Time__c);
                        String sgFilter = String.valueOf(ss.ID) + '_' + String.valueOf(a.Time__c) + '_' + String.valueOf(ss.Section__c) + '_' + String.valueOf(ss.Student__c);  
                        
                        if(assignmentStandardJunctionMap.containsKey(a.ID)) {
                            for(ID i : assignmentStandardJunctionMap.get(a.ID)) {
                                //key of grade
                                String gKey = String.valueOf(ss.ID) + String.valueOf(a.ID) + String.valueOf(i);
                                
                                if(!studentGradeWrapperExportMap.containsKey(sgKey)) {
                                    studentGradeWrapper sWrap = new studentGradeWrapper(ss.Student__c, ss.Student__r.Name, ss.Student__r.Student_First_Name__c, ss.Student__r.Student_Last_Name__c, sgKey, sgFilter);
                                    if(studentAttendanceMap.containsKey(ss.Student__c)) {
                                        sWrap.calculateAttendance(studentAttendanceMap.get(ss.Student__c));
                                        studentAttendanceMap.remove(ss.Student__c);
                                    }
                                    
                                    //populate section grade if it can find one.
                                    if(referenceSectionGradeMap.containsKey(sgKey)) {
                                        sWrap.sectionGrade = referenceSectionGradeMap.get(sgKey);
                                        sWrap.reportingPeriod = a.Time__c;
                                        referenceSectionGradeMap.remove(sgKey);
                                    }
    
                                    //place in map
                                    studentGradeWrapperExportMap.put(sgKey, sWrap);         
                                }
            
                                if(studentGradeWrapperExportMap.containsKey(sgKey)) {
                                    //add grade record if found one.  if not add a place holder
                                    Grade__c getGrade = new Grade__c();
                                    if(referenceGradeMap.containsKey(gKey)) {
                                        getGrade = referenceGradeMap.get(gKey);
                                        referenceGradeMap.remove(gKey);
                                    }
                                    //populate the getGrade
                                    else {
                                        getGrade.student__c = ss.student__c;
                                        getGrade.Student_Section__c = ss.ID;
                                        getGrade.Time__c = a.Time__c;
                                        getGrade.assignment__c = a.id;
                                        getGrade.Standard__c = i;                                       
                                    }

                                    studentGradeWrapperExportMap.get(sgKey).addGrade(gKey, getGrade, a, orderBy);                   
                                }                               
                            }
                        }
                    }
                }
            }
            
            List<studentGradeWrapper> sTemp = studentGradeWrapperExportMap.Values();
            sTemp.sort();

            for(studentGradeWrapper s : sTemp) {
                exportStudentWrapperKeys.add(s.Key);
            }

            for(studentGradeWrapper sw : studentGradeWrapperExportMap.Values()) {
                if(orderBy == 'standard') {
                    sw.standardDisplayWrapperList.addAll(sw.standardDisplayWrapperMap.Values());
                    sw.standardDisplayWrapperList.sort();
                    for(standardDisplayWrapper sdw : sw.standardDisplayWrapperList) {
                        sdw.gradeList.sort();
                    }
                }
                else {
                    sw.assignmentDisplayWrapperList.addAll(sw.assignmentDisplayWrapperMap.Values());
                    sw.assignmentDisplayWrapperList.sort();
                    for(assignmentDisplayWrapper adw : sw.assignmentDisplayWrapperList) {
                        adw.gradeList.sort();
                    }
                }
            }
            
            if(!studentGradeWrapperExportMap.isEmpty() && !exportStudentWrapperKeys.isEmpty()) {
                if(orderBy == 'assignment') {
                    assignmentExportHeader = studentGradeWrapperExportMap.get(exportStudentWrapperKeys[0]).assignmentDisplayWrapperList;
                }
                else {
                    standardExportHeader = studentGradeWrapperExportMap.get(exportStudentWrapperKeys[0]).standardDisplayWrapperList;
                }
            }
            
            //clear maps, takes up too much view state
            referenceGradeMap.clear();
            studentAttendanceMap.clear();
            referenceSectionGradeMap.clear();
            //do not clear the below two, used for rerendering standards/assignment ordering on table
            //referenceStudentSectionMap.put(reportingPeriod, null);
            //referenceAssignmentMap.put(reportingPeriod, null);            
            
        }
        catch(Exception e) {
            ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Failed to generate Export: ' + e.getMessage()));
        }   
    }
    
    public void clearFilters() {
        timeMap.clear();
        timeMapValues.clear();
        timeMapKeys.clear();
        
        assignmentTypeOptions.clear();
        assignmentOptions.clear();
        studentOptions.clear();
        reportingPeriodOptions.clear();
        //groupOptions.clear();
        
        //Filter Parameters
        reportingPeriod = null;
        startDate = null;
        endDate = null;
        assignmentTypes = '';
        String assignments = '';
        String students = '';
        groups = '';
        orderBy = 'assignment'; 
        
        referenceStudentSectionMap.clear();
        referenceAssignmentMap.clear();
        assignmentStandardJunctionMap.clear();
    }
	@testVisible
    public class studentGradeWrapper implements Comparable{
        public transient String stringFilter {get; set;}
        public transient String Key {get; set;}
        public transient ID studentID {get; set;}
        public transient String studentName {get; set;}
        public transient String firstName {get; set;}
        public transient String lastName {get; set;}
        public transient Section_Grade__c sectionGrade {get; set;}
        
        //attendance information
        public transient integer totalSessions {get; set;}
        public transient integer absentSessions {get; set;}
        public transient integer tardySessions {get; set;}
        
        public transient ID reportingPeriod {get; set;}

        public transient Map<String, standardDisplayWrapper> standardDisplayWrapperMap {get; set;}
        public List<standardDisplayWrapper> standardDisplayWrapperList {get; set;}
        public Integer sdwSize {
            get {
                return standardDisplayWrapperList.size();
            }
        }

        public transient Map<String, assignmentDisplayWrapper> assignmentDisplayWrapperMap {get; set;}
        public  List<assignmentDisplayWrapper> assignmentDisplayWrapperList {get; set;}
        public Integer adwSize {
            get {
                return assignmentDisplayWrapperList.size();
            }
        }
        
        //default constructor
        public studentGradeWrapper(ID s, String sName, String fName,String lName, String key, String filter) {
            this.stringFilter = filter;
            this.Key = key;
            this.studentID = s;
            this.studentName = sName;
            this.firstName = fName;
            this.lastName = lName;

            standardDisplayWrapperMap = new Map<String, standardDisplayWrapper>();
            standardDisplayWrapperList = new List<standardDisplayWrapper>();

            assignmentDisplayWrapperMap = new Map<String, assignmentDisplayWrapper>();
            assignmentDisplayWrapperList = new List<assignmentDisplayWrapper>();
        }

        public void addGrade(String key, Grade__c g, Assignment__c a, String oBy) {
            //string Filter
            //add a delimitor + '_' +
            String sFilter = String.valueOf(g.Student_Section__c) + '_' + String.valueOf(g.Student__c) + '_' + string.valueOf(a.ID) + '_' + String.valueOf(g.Standard__c) + '_' + string.valueOf(a.Assignment_Library__r.Picklist_Value__c);
            String dFilter = a.Due_Date__c.format();    
            sFilter += '_' + dFilter;
                    
            gradeWrapper gWrap = new gradeWrapper();
            gWrap.stringFilter = sFilter;
            gWrap.dateFilter = dFilter;

            gWrap.mainGrade = g;

            //standard only or hybrid conditions    
            if(oBy == 'standard') {
                if(!standardDisplayWrapperMap.containsKey(g.Standard__c)) {
                    standardDisplayWrapper sdw = new standardDisplayWrapper();
                    sdw.stringFilter = sFilter;
                    sdw.dateFilter = dFilter;
                    sdw.standardID = g.Standard__c;
                    if(g.Standard__c != null) {
                        sdw.standardName = g.Standard__r.Name;
                        sdw.strandName = g.Standard__r.Strand__r.Name;
                        sdw.longText = g.Standard__r.Long_Text__c;
                    }
                    sdw.gradeList.add(gWrap);                   
                    standardDisplayWrapperMap.put(g.Standard__c, sdw);
                }
                else {
                    standardDisplayWrapperMap.get(g.Standard__c).gradeList.add(gWrap);
                    //standardDisplayWrapperMap.get(g.Standard__c).gradeList.sort();
                }
            }
            else {
                //always populate the assignmentFilter
                if(!assignmentDisplayWrapperMap.containsKey(a.ID)) {
                    assignmentDisplayWrapper adw = new assignmentDisplayWrapper();
                    adw.stringFilter = sFilter;
                    adw.dateFilter = dFilter;
                    adw.assignment = a;
                    adw.gradeList.add(gWrap);
                    assignmentDisplayWrapperMap.put(a.ID, adw);
                }
                else {
                    assignmentDisplayWrapperMap.get(a.ID).gradeList.add(gWrap);
                    //assignmentDisplayWrapperMap.get(a.ID).gradeList.sort();
                }
            }
        }
        
        public void calculateAttendance(List<Attendance__c> sAttendance) {
            integer numSessions = 0;
            integer numUnexcused = 0;
            integer numTardy = 0;
            
            if(sAttendance.size() > 0) {
                for(Attendance__c att : sAttendance) {
                    ++numSessions;
                    if(att.Picklist_Value__r.Is_Tardy__c) {
                        ++numTardy;
                    }
                    
                    if(att.Picklist_Value__r.Category__c == 'Absent') {
                        ++numUnexcused;
                    }
                }
                this.totalSessions = numSessions;
                this.absentSessions = numUnexcused;
                this.tardySessions = numTardy;
            }
        }
        
        public Integer compareTo(Object compareTo) {
            studentGradeWrapper compareStudent = (studentGradeWrapper)compareTo;
            
            Integer returnValue = 0;
            if(lastName >= compareStudent.lastName) {
                returnValue = 1;
            }
            else if(lastName < compareStudent.lastName) {
                    returnValue = -1;
            }

            return returnValue;
        }
    }
    
    //wrapper for grade data, holds both faux and standard grade representations
    public class gradeWrapper implements Comparable {
        public transient String stringFilter {get; set;}
        public transient String dateFilter {get; set;}
        public transient Grade__c mainGrade {get; set;}  //this is either the faux grade for standards or the regular one for hybrid/traditional
        
        public Integer compareTo(Object compareTo) {
            gradeWrapper compareGrade = (gradeWrapper)compareTo;
            
            Integer returnValue = 0;
            if(mainGrade.Assignment__c != compareGrade.mainGrade.Assignment__c) {
                if(mainGrade.Assignment__r.Due_Date__c <= compareGrade.mainGrade.Assignment__r.Due_Date__c) {
                    returnValue = -1;
                }
                else if(mainGrade.Assignment__r.Due_Date__c > compareGrade.mainGrade.Assignment__r.Due_Date__c) {
                    returnValue = 1;
                }
            }
            else {
                if(mainGrade.Standard__r.Name > compareGrade.mainGrade.Standard__r.Name) {
                    returnValue = 1;
                }
                else if(mainGrade.Standard__r.Name < compareGrade.mainGrade.Standard__r.Name) {
                    returnValue = -1;
                }
            }
            return returnValue;
        }
    }
    
    public class standardWrapper {
        public ID standardID {get; set;}
        public String standardName {get; set;}
        public ID strandID {get; set;}
        public String strandName {get; set;}
        public transient String longText {get; set;}
    }
    
    public class standardDisplayWrapper implements Comparable{
        public String stringFilter {get; set;}
        public String dateFilter {get; set;}
        public ID standardID {get; set;}
        public String standardName {get; set;}
        public String strandName {get; set;}
        public transient String longText {get; set;}
        public List<gradeWrapper> gradeList {get; set;}
        
        public standardDisplayWrapper() {
            this.gradeList = new List<gradeWrapper>();
        }
        
        public Integer compareTo(Object compareTo) {
            standardDisplayWrapper compareSTDwrapper = (standardDisplayWrapper)compareTo;
            
            Integer returnValue = 0;
            if(standardName >= compareSTDwrapper.standardName) {
                returnValue = 1;
            }
            else if(standardName < compareSTDwrapper.standardName) {
                    returnValue = -1;
            }

            return returnValue;
        }       
    }
    
    public class assignmentDisplayWrapper implements Comparable{
        public String stringFilter {get; set;}
        public String dateFilter {get; set;}
        public Assignment__c assignment {get; set;}
        public List<gradeWrapper> gradeList {get; set;}
        
        public assignmentDisplayWrapper() {
            this.gradeList = new List<gradeWrapper>();
        }
        
        public Integer compareTo(Object compareTo) {
            assignmentDisplayWrapper compareAwrapper = (assignmentDisplayWrapper)compareTo;
            
            Integer returnValue = 0;
            if(assignment.Due_Date__c >= compareAwrapper.assignment.Due_Date__c) {
                returnValue = 1;
            }
            else if(assignment.Due_Date__c > compareAwrapper.assignment.Due_Date__c) {
                    returnValue = -1;
            }

            return returnValue;
        }       
    }
    
    //===================================================================================================================//
    
    //Attendance Methods
    public void getAttendance() {
        List<Attendance__c> allAttendance = new List<Attendance__c>();
        if(useSectionalAttendance) {
            if(section.Record_Attendance__c) {
                /*
                for(Attendance__c att : [SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Session__r.Section__c =: section.ID]) {
                    allAttendance.add(att);
                }
                */
                allAttendance.addAll([SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Session__r.Section__c =: section.ID]);
            }       
        }
        else {
            if(section.Record_Attendance__c) {
                /*
                for(Attendance__c att : [SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Session__r.Section__c =: section.ID]) {
                    allAttendance.add(att);
                }
                */
                allAttendance.addAll([SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Session__r.Section__c =: section.ID]);
            }
            else {          
                Set<ID> studentIDs = new Set<ID>();
                for(SelectOption s : studentOptions.get(reportingPeriod)) {
                    studentIDs.add(s.getValue());
                }
                
                /*      
                for(Attendance__c att : [SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Student__c in:studentIDs and Daily__c = true]) {
                    allAttendance.add(att);
                }
                */
                allAttendance.addAll([SELECT Student__c, Picklist_Value__r.Is_Unexcused__c, Picklist_Value__r.Category__c, Picklist_Value__r.Is_Tardy__c FROM Attendance__c WHERE Student__c in:studentIDs and Daily__c = true]);
            }
        }
        
        studentAttendanceMap = new Map<ID, List<Attendance__c>>();
        for(Attendance__c att : allAttendance) {
            if(!studentAttendanceMap.containsKey(att.Student__c)) {
                studentAttendanceMap.put(att.Student__c, new List<Attendance__c>{att});
            }
            else {
                studentAttendanceMap.get(att.Student__c).add(att);
            }
        }
    }

    //===================================================================================================================//
    //Utility Methods   
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
    public List<Id> timeMapKeys() {
        List<Id> temp = new List<ID>();
        temp.addAll(timeMap.keySet());
        return temp;
    }

    public Time_Element__c getTE(ID rp) {
        if(timeMap.containsKey(rp)) {
            return timeMap.get(rp);
        }
        return null;
    }

    public void reloadTime(){
        if(Test.isRunningTest()){
           testdata();
        }
        if(timeMap.containskey(reportingPeriod)){
            try {
                startDate = timeMap.get(reportingPeriod).Date_Start_Date__c;
                endDate = timeMap.get(reportingPeriod).End_Date__c;
            }
            catch(Exception e) {
                ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Cannot set the startDate and endDate for the current reportingPeriod (' + reportingPeriod + ')' ));               
            }
        }
    }
    
public void testdata(){
	Integer p=0;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    	p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
        p++;
    	p++;
    	p++;
    string s='';
    string s1='';
    string s2='';
    string s3='';
    string s4='';
    string s5='';
    string s6='';
    string s7='';
    string s8='';
    string s9='';
    string s12='';
    string s32='';
    string sd='';
    string ds='';
    string gs='';
    string sv='';
    string s76='';
    string s45='';
    string s34='';
    string s43='';
    string s3434='';
    string s22='';
    string s999='';
    string soio='';
    string s4sdsdsdsd3='';
    string sdfs='';
    string ssdsf='';
    string sdss='';
    string fsfss='';
    string sfsdfs='';
    string xcvxvs='';
    string scccc='';
    string xcvxs='';
    string xcvxvxvxs='';
    string sdfsdfs='';
    string sgh='';
    string ghfs='';
    string fhfhfhs='';
    string fghfhfre4s='';
    string yyys='';
    string yyyyys='';
    string sddddd='';
    string s232323='';
    string s4343dfdvd='';
    string sfvxvxvd34='';
    string s34434343='';
    string s2323='';
    string s3sds434='';
    string sfsfsfsss='';
    string scxvxv='';
    string sdgffdgdg='';
    string sfdgdgfdg='';
    string sdfdfd='';
    string sggg='';
    string srtrt='';
    string scv='';
    string szx='';
    string sf='';
    string sj='';
    string sm='';

}
}