public without sharing class Gradebook_Controller_v2 {
    //Private Variables
    //baseObj is used to set the school information desired.  core_BaseInfo_v2 has a cSchool_BaseInfo object but 
    //it contains the default loaded record.
    public core_BaseInfo_v2.cSchool_BaseInfo currentSchool {get; set;}
    
    //Filter Options
    public List<SelectOption> yearOptions  {get; set;}
    public List<SelectOption> schoolOptions  {get; set;}
    
    //Filter Parameters
    public ID currentYearID  {get; set;}
    public ID currentSchoolID  {get; set;}
    
    //Active State
    public ID activeYearID {get; set;}
    
    //Controller Variables
    public Boolean standardBased {get; set;}
    public Boolean standardOnly {get; set;}
    
    //key = Staff_Section__c -> wrapper; Staff_Section__c will have the order value on it
    public List<Staff_Section__c> orderedSchoolSections {get; set;}
    public Set<Staff_Section__c> currentSchoolSections {get; set;}
    public Gradebook_Wrapper_v2 loadedSchoolSection {get; set;} //currentSchoolSection on display
    
    //save state for returning back to
    public Integer sectionPosition {get; set;}
    public String sectionID {get; set;}
    public String assignmentID {get; set;}
    public String timeID {get; set;}
    public String sID {get; set;}
    
    //single grade comment
    public String commentGradeKey {get; set;}
    public Grade__c commentGrade {get; set;}
    public Grade__c fauxCommentGrade {get; set;}
    
    //single section grade comment
    public String sgCommentGradeKey {get; set;}
    public Section_Grade__c sgCommentGrades {get; set;}
    public transient List<Section_Grade__c> allSGCommentGrades {get; set;}
    
    
    //Quick Create Assignment
    public Gradebook_Quick_Create_Assignment gQCA {get; set;}
    
    public Boolean bSaveOrder {get; set;}
    
    public List<orderWrapper> ssOrder {get; set;}
    
    public Gradebook_Controller_v2() {
        commentGrade = new Grade__c();
        sgCommentGrades = new Section_Grade__c();
        sectionPosition = 0;
        ssOrder = new List<orderWrapper>();
        
        if(initializeController()) {
            try {
                yearOptions = loadYearOptions();
                schoolOptions = loadSchoolOptions();
            }
            catch(Exception e) {
                ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Failed to load Year Options and/or School Options.  Please contact your administrator.'));
            }
        } else {
            system.debug('Init failed');
        }
    }
    
    private Boolean initializeController() {
        Boolean returnB = true;
        //If this fails, we are in serious trouble
        try {
            //this generates map associated to the current user.
            core_BaseInfo_v2.initBaseInfo(true);
        }
        catch(Exception e) {
            core_BaseInfo_v2.showErrorMessages();
            //ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, '\nFailed to initialize your contact information.  Please contact your administrator.'));
            ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, '\nPlease update your school on the home page in the component on the right and click "Change."'));
            returnB = false;
        }
        
        //Normal operations, set important maps and filters as needed.  First school will be the default loaded
        try {
            //load currentSchool
            currentSchool = core_BaseInfo_v2.baseInfoObj;
            standardBased = currentSchool.activeSetup.Standards_Based_Grading__c;
            standardOnly = currentSchool.activeSetup.Standards_ONLY_Gradebook__c;
            currentYearID = currentSchool.activeSetup.Year__c;
            activeYearID = currentSchool.activeSetup.Year__c;
            currentSchoolID = currentSchool.school.ID;
        system.debug('currentSchool'+currentSchool);
            currentSchoolSections = getCurrentSchoolSections(currentSchool);
            system.debug('currentSchoolSections '+currentSchoolSections);
            orderedSchoolSections = getOrderedSchoolSections(currentSchoolSections);
            system.debug('orderedSchoolSections '+orderedSchoolSections );
            currentSchoolSections.clear();
            
            sID = apexPages.currentPage().getParameters().get('sID');
            assignmentID = apexPages.currentPage().getParameters().get('aID');
            timeID = apexPages.currentPage().getParameters().get('tID');            
            
            getSection();
        }
        catch(Exception e) {
            system.debug(e);
            core_BaseInfo_v2.showErrorMessages();
            returnB = false;
        }
        return returnB;
    }
    
    private Set<Staff_Section__c> getCurrentSchoolSections(core_BaseInfo_v2.cSchool_BaseInfo school) {
        Set<Staff_Section__c> returnSet = new Set<Staff_Section__c>();
        
        for(Staff_Section__c ss : [SELECT ID, Order__c, Staff__c, Section__c, Section__r.Course__c, View_Gradebook_as_Read_Only__c, Section__r.Name, Section__r.of_Students__c FROM Staff_Section__c WHERE Staff__c =: school.staff.ID AND Section__c IN: school.SectionList AND Section__r.Is_Section__c = TRUE AND Section__r.RecordType.Name = 'Published' ORDER BY Section__r.Course__r.Name, Section__r.Name]) {
            //returnMap.put(ss, new Gradebook_Wrapper_v2(school.sectionMap.get(ss.Section__c), ss, standardBased, standardOnly, currentSchool.activeSetup.Use_Sectional_Attendance__c));
            returnSet.add(ss);
        }
        
        return returnSet;
    }
    
    public List<Staff_Section__c> getOrderedSchoolSections(Set<Staff_Section__c> staffSections) {
        List<Staff_Section__c> returnList = new List<Staff_Section__c>();
        Map<Decimal, List<Staff_Section__c>> tMap = new Map<Decimal, List<Staff_Section__c>>();
        Set<Staff_Section__c> tSet = new Set<Staff_Section__c>();
        
        for(Staff_Section__c ss : staffSections) {
            if(ss.Order__c != null) {
                if(!tMap.containsKey(ss.Order__c)) {
                    tMap.put(ss.Order__c, new List<Staff_Section__c>{ss});
                }
                else {
                    tMap.get(ss.Order__c).add(ss);
                }
            }
            else {
                tSet.add(ss);
            }
        }
        
        //sort by asc order
        List<Decimal> tList = new List<Decimal>(tMap.KeySet());
        tList.sort();
        for(Decimal i : tList) {
            for(Staff_Section__c ss : tMap.get(i)) {
                returnList.add(ss);
            }
        }

        //sort by asc order
        List<Staff_Section__c> ssList = new List<Staff_Section__c>(tSet);
        ssList.sort();
        for(Staff_Section__c ss : ssList) {
            returnList.add(ss);
        }
        
        return returnList;
    }
    
    //should be one time operation during initialization
    public List<SelectOption> loadSchoolOptions() {
        List<SelectOption> returnOptions = new List<SelectOption>();
        for(Account a : core_BaseInfo_v2.schoolMap.Values()) {
            returnOptions.add(new SelectOption(a.ID, a.Name));
        }
        return returnOptions;
    }
    
    public List<SelectOption> loadYearOptions() {
        List<SelectOption> returnOptions = new List<SelectOption>();
        for(Time_Element__c te : [SELECT ID, Name__c FROM Time_Element__c WHERE ID IN: core_BaseInfo_v2.recentSchoolYears]) {
            returnOptions.add(new SelectOption(te.ID, te.Name__c));
        }
        return returnOptions;
    }
    
    //currentSchoolID and currentYearID is implied from the global variables
    public void getSchoolandYear() {
        try {
            core_BaseInfo_v2.initBaseInfo(true, currentYearID);
            core_BaseInfo_v2.baseInfoObj = new core_BaseInfo_v2.cSchool_BaseInfo(currentSchoolID, true, true, (String)currentYearID);
            currentSchool = core_BaseInfo_v2.baseInfoObj;
            currentYearID = currentSchool.activeSetup.Year__c;
            standardBased = currentSchool.activeSetup.Standards_Based_Grading__c;
            standardOnly = currentSchool.activeSetup.Standards_ONLY_Gradebook__c;
                                    
            currentSchoolSections = getCurrentSchoolSections(currentSchool);
            orderedSchoolSections = getOrderedSchoolSections(currentSchoolSections);
            currentSchoolSections.clear();
            sectionPosition = 0;
            getSection();
        }
        catch(Exception e) {
            core_BaseInfo_v2.showErrorMessages();
            ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, '\nFailed to initialize selected school variables.  Please contact your administrator.'));         
        }
    }
    
    public void getSection() {
        //system.debug('*~*~* core_baseInfo_v2: ' + currentSchool);
        Staff_Section__c ss;
        if(sID != null) {
            sectionID = sID;
            sID = null;
        }
        else {
            sectionID = apexPages.currentPage().getParameters().remove('sectionID');
        }

        system.debug('*~*~* sectionID: ' + sectionID);
        if(String.isNotBlank(sectionID)) {
            for(Integer i = 0; i < orderedSchoolSections.size(); i++) {
                if(sectionID == orderedSchoolSections[i].Section__c) {
                    sectionPosition = i;
                    break;
                }
            }
        }
        else if(!orderedSchoolSections.isEmpty()) {
            sectionPosition = 0;
            sectionID = orderedSchoolSections[0].Section__c;
            ss = orderedSchoolSections[sectionPosition];
        } 
        else {
            loadedSchoolSection = null;
            //Error_Handling.errorMessage('You do not have any staff/sections for the selected year. Please select a different year.');
            Error_Handling.errorMessage('Please enroll students into your Gradebook sections first.');
            return;
        }

        try {
            ss = orderedSchoolSections[sectionPosition];
            //loadedSchoolSection = currentSchoolSections.get(orderedSchoolSections[sectionPosition]);
            loadedSchoolSection = new Gradebook_Wrapper_v2(currentSchool.sectionMap.get(ss.Section__c), ss, standardBased, standardOnly, currentSchool.activeSetup.Use_Sectional_Attendance__c);
            loadedSchoolSection.loadSection(currentSchoolID, currentYearID, activeYearID, currentSchool.activeSetup.Active__c, timeID);
            timeID = null;
            
            if(assignmentID != null) {
                loadedSchoolSection.assignments = assignmentID;
                assignmentID = null;
            }
                    
        }
        catch(Exception e) {
            //ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Error in loading section.'));
        }
    }
    
    public pagereference newAssignmentPage(){
        pageReference p = Page.Gradebook_AddAssignments_v2;
        p.getParameters().put('fromGradebook','true');
        return p;
    }
    
    public void resetSaveOrder() {
        bSaveOrder = false;
    }   
    
    public void saveSectionOrder() {
        bSaveOrder = false;
        Map<ID, String> tempOrder = new Map<ID, String>();
        for(orderWrapper ow : ssOrder) {
            tempOrder.put(ow.staffSection.ID, ow.order);
        }
        
        for(Staff_Section__c ss : orderedSchoolSections) {
            if(tempOrder.containsKey(ss.ID)) {
                if(String.isNotEmpty(tempOrder.get(ss.ID))) {
                    try {
                        ss.Order__c = Decimal.valueOf(tempOrder.get(ss.ID));
                    }
                    catch(Exception e) {
                        ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, 'Invalid integer: ' + tempOrder.get(ss.ID)));
                        return;
                    }
                }
                else {
                    ss.Order__c = null;
                }
            }
        }
        
        try {
            Database.saveResult[] results = Database.update(orderedSchoolSections);
            for(Database.saveResult result : results) {
                if(!result.isSuccess()) {
                    return;
                }
            }
        }
        catch(Exception e) {
            return;
        }
        bSaveOrder = true;
    }

    //===================================================================================================================// 
    
    //should return result of validation for grade entries
    //pass in the mapped grades, does not need to sit in controller, only temporary.
    @RemoteAction 
    public static Map<String, Map<String, String>> validate(Map<String, String> geMap, Boolean standardBased, Boolean standardOnly) {
        
        //returnMap
        //first key == 'error' -> Map<gKey, Boolean>
        //second key == 'submit' -> geMap
        Map<String, Map<String, String>> returnMap = new Map<String, Map<String, String>>();
        
        //assignment based
        Map<ID, Boolean> isPoints = new Map<ID, Boolean>();
        Map<ID, String> assignmentName = new Map<ID, String>();
        Map<ID, Decimal> assignmentPoints = new Map<ID, Decimal>();
        Set<ID> assignments = new Set<ID>();
        
        for(String s : geMap.KeySet()) {
            List<String> tList = s.split('_');
            assignments.add(tList[2]);
        }
        
        //build points Validation
        try {
            for(Assignment__c a : [SELECT ID, Name, Section__r.Course__r.Grade_Scale_Lookup__r.Category__c, Picklist_Value__r.Category__c, Possible_Points__c FROM Assignment__c WHERE ID IN: assignments]) {
                if(a.Section__r.Course__r.Grade_Scale_Lookup__r.Category__c == 'Points' || a.Picklist_Value__r.Category__c == 'Points') {
                    isPoints.put(a.ID, true);
                }
                else {
                    isPoints.put(a.ID, false);
                }
                assignmentName.put(a.ID, a.Name);
                assignmentPoints.put(a.ID, a.Possible_Points__c);
            }
        }
        catch(Exception e) {
            //e.setMessage(e.getMessage() + ' zero e');
            throw e;
        }       
        
        //parse again through the map
        String values = '';
        Map<String, String> errorMap = new Map<String, String>();
        Set<String> nameSet = new Set<String>();
        for(String s : geMap.KeySet()) {
            List<String> tList = s.split('_');
            if(isPoints.containsKey(tList[2])) {
                if(isPoints.get(tList[2])) {
                    try {
                        if(Decimal.valueOf(geMap.get(s)) > assignmentPoints.get(tList[2])) {
                            nameSet.add(assignmentName.get(tList[2]));
                            errorMap.put(s, 'true');
                        }
                    }
                    catch(Exception e) {
                        //let it by pass and catch in trigger
                        //throw e;
                    }
                }
            }
        }
        
        for(String n : nameSet) {
            if(values == '') {
                values += n;
            }
            else {
                values += ', ' + n;
            }           
        }
        
        //parse the geMap should be key -> entered value
        //where key = studentID + assignmentID + standardID(could be null) + assignmentPicklistListValueID aka stringFilter
        //the above is enough information to reference the list of reference to parse through
        
        //need to validate grade entry via controller.  
        //validate what?  old use to validate against string vs decimal
                    
        //alternatively, what we want is to just find the assignment from the key

        
        //this returnMap will be passed to commitDML
        //return returnMap; 
        
        //for now, just return the geMap
        returnMap.put(' ', geMap);
        returnMap.put(values, errorMap);

        //return new Map<String, Map<String, String>>{values => geMap};
        return returnMap;
    }
    
    //keep the geMap in the page until a commitDML is valid
    @RemoteAction 
    public static Map<String, String> commitDML(Map<String, String> validMap, Boolean standardBased, Boolean standardOnly) {
        Boolean success = true;
        Map<String, String> errorHandling = new Map<String, String>();
        system.debug('@@validMap');
        system.debug('validMap'+validMap);
        //used to get the initial grades
        Set<ID> tStudentSections = new Set<ID>();
        Set<ID> tStudents = new Set<ID>();
        Set<ID> tAssignments = new Set<ID>();
        Set<ID> tStandards = new Set<ID>();
    
        //Map of existing Grades
        Map<ID, Assignment__c> getAssignments = new Map<ID, Assignment__c>();
        Map<String, Grade__c> existingGrades = new Map<String, Grade__c>();
        List<Grade__c> upsertGrades = new List<Grade__c>();
        Map<Grade__c, Grade__c> upsertFauxGrades = new Map<Grade__c, Grade__c>();
    
        //use this loop for grade submission.  Pull from the Assignment
        //to generate the grade records as necessary.

        for(String k : validMap.KeySet()) {
            List<String> tList = k.split('_');
            if(tList[3] == 'null') {
                tList[3] = null;
            }
            system.debug('!!tList'+tList.size());
            if(tList.size() == 6) {  //has standard
                system.debug('##newlist');
                tStudentSections.add(tList[0]);
                tStudents.add(tList[1]);
                tAssignments.add(tList[2]);
                tStandards.add(tList[3]);
                system.debug('@@tStandards'+tAssignments);
                system.debug('##tStudents'+tStudents);
            }
            else if(tList.size() == 5) {  //does not
                tStudentSections.add(tList[0]);
                tStudents.add(tList[1]);
                tAssignments.add(tList[2]);
            }
            else {
                //we have a problem
                //system.debug('stringFilter does not contains 3 or 4 IDs!');
                
            }
        }
        //build the assignment map
        getAssignments = new Map<ID, Assignment__c>([Select ID, Section__r.Course__c, Include_In_Final_Grade__c, Time__c, Weighting_Value__c, Description__c, Due_Date__c, Assignment_Library__r.Picklist_Value__c FROM Assignment__c WHERE ID IN: tAssignments]);
        system.debug('getAssignments'+getAssignments);
        //build the existing Grade Map
        for(Grade__c g : [SELECT ID, Student__c, Student_Section__c, Assignment__c, Standard__c, Assignment__r.Assignment_Library__r.Picklist_Value__c, Entered_Grade__c, Assignment__r.Due_Date__c, (SELECT ID, Entered_Grade__c FROM Grades__r) FROM Grade__c WHERE Student__c IN: tStudents AND Assignment__c IN: tAssignments AND Standard_Gradebook_Grade__c = null]) {
            String gKey = String.valueOf(g.Student_Section__c) + '_' + String.valueOf(g.Student__c) + '_' + String.valueOf(g.Assignment__c) + '_' + String.valueOf(g.Standard__c) + '_' + String.valueOf(g.Assignment__r.Assignment_Library__r.Picklist_Value__c) + '_' + g.Assignment__r.Due_Date__c.format();
            //only want to manipulate the grades that we have keys for
            if(validMap.containsKey(gKey)) {
                existingGrades.put(gKey, g);
            }
            system.debug('existingGrades'+existingGrades);
        }
        
        //go through the validMap again, set the Value of the Grade record or create net new grade record
        for(String k : validMap.KeySet()) {
            List<String> tList = k.split('_');
            system.debug('%%tList'+tList);
            if(tList[3] == 'null') {
                tList[3] = null;
            }
            if(existingGrades.containsKey(k)) {
                Grade__c addG = existingGrades.get(k);
                addG.Entered_Grade__c = validMap.get(k);
                upsertGrades.add(addG);
                
                //update faux grade too
                for(Grade__c g : existingGrades.get(k).Grades__r) {
                    g.Entered_Grade__c = validMap.get(k);
                    upsertGrades.add(g);
                }
            }
            //auto correcting gradebook
            else {
                //create net new Grade
                try {
                    Assignment__c localAssignment = getAssignments.get(tList[2]);
                    system.debug('##standardBased'+standardBased);
                    system.debug('@@standardOnly'+standardOnly);
                    if(standardBased && standardOnly) {
                        //standard grade
                        try {
                            Grade__c localGrade = new Grade__c (
                                Entered_Grade__c = validMap.get(k),
                                Student_Section__c = tList[0],
                                Student__c = tList[1],
                                Assignment__c = tList[2],
                                Standard__c = tList[3],
                                Standards_Only_Grading__c = true,
                                Include_In_Standard_Grade__c = true,
                                Course__c = localAssignment.Section__r.Course__c,
                                Exclude_From_Section_Grade__c = !localAssignment.Include_In_Final_Grade__c,
                                Time__c = localAssignment.Time__c,
                                Standard_Times_Assignment__c = localAssignment.Weighting_Value__c,
                                Assignment_Weighting__c = localAssignment.Weighting_Value__c
                                
                            );
                            Grade__c localFauxGrade = new Grade__c (
                                Entered_Grade__c = validMap.get(k),
                                Student_Section__c = tList[0],
                                Student__c = tList[1],
                                Assignment__c = tList[2],
                                Standards_Only_Grading__c = true,
                                Include_In_Standard_Grade__c = false,
                                Course__c = localAssignment.Section__r.Course__c,
                                Exclude_From_Section_Grade__c = !localAssignment.Include_In_Final_Grade__c,
                                Time__c = localAssignment.Time__c,
                                Standard_Times_Assignment__c = localAssignment.Weighting_Value__c,
                                Assignment_Weighting__c = localAssignment.Weighting_Value__c
                                //Standard_Gradebook_Grade__c;
                            );
                            upsertFauxGrades.put(localGrade, localFauxGrade);
                        }
                        catch(Exception e) {
                            throw e;
                        }
                    }
                    else {
                        try {
                            Grade__c localGrade = new Grade__c (
                                Entered_Grade__c = validMap.get(k),
                                Student_Section__c = tList[0],
                                Student__c = tList[1],
                                Assignment__c = tList[2],
                                Standards_Only_Grading__c = true,
                                Course__c = localAssignment.Section__r.Course__c,
                                Exclude_From_Section_Grade__c = !localAssignment.Include_In_Final_Grade__c,
                                Time__c = localAssignment.Time__c,
                                Standard_Times_Assignment__c = localAssignment.Weighting_Value__c,
                                Assignment_Weighting__c = localAssignment.Weighting_Value__c
                                
                            );
                            if(tList.size() == 6) {
                                localGrade.Standard__c = tList[3];
                                localGrade.Include_In_Standard_Grade__c = true;
                            }
                            upsertGrades.add(localGrade);                                               
                        }
                        catch(Exception e) {
                            throw e;
                        }
                    }
                }
                catch(Exception e) {
                    throw e;
                }
            }
        }
        
        if(upsertGrades.size() > 0) {
            try {
                upsert upsertGrades;
            }
            catch(DmlException e) {
                for(Integer i = 0; i < e.getNumDml(); i++) {
                    if(String.isNotEmpty(e.getDMLMessage(i))) {
                        Grade__c g = upsertGrades[e.getDMLIndex(i)];
                        if(getAssignments.containsKey(g.Assignment__c)) {
                            Assignment__c a = getAssignments.get(g.Assignment__c);
                            String gKey = String.valueOf(g.Student_Section__c) + '_' + String.valueOf(g.Student__c) + '_' + String.valueOf(g.Assignment__c) + '_' + String.valueOf(g.Standard__c) + '_' + String.valueOf(a.Assignment_Library__r.Picklist_Value__c) + '_' + a.Due_Date__c.format();
                            errorHandling.put(gKey, e.getDMLMessage(i));
                        }
                    }
                }
                for(Grade__c g : upsertGrades) {    
                    if(getAssignments.containsKey(g.Assignment__c)) {
                        Assignment__c a = getAssignments.get(g.Assignment__c);
                        String gKey = String.valueOf(g.Student_Section__c) + '_' + String.valueOf(g.Student__c) + '_' + String.valueOf(g.Assignment__c) + '_' + String.valueOf(g.Standard__c) + '_' + String.valueOf(a.Assignment_Library__r.Picklist_Value__c) + '_' + a.Due_Date__c.format();
                        if(!errorHandling.containsKey(gKey)) {
                            errorHandling.put(gKey, '');
                        }
                    }
                }
            }
        }
        
        if(upsertFauxGrades.size() > 0) {
            List<Grade__c> tList = new List<Grade__c>(upsertFauxGrades.KeySet());
            try {
                if(tList.size() > 0) {
                    upsert tList;
                }
            }
            catch(DmlException e) {
                errorHandling.put('e0', e.getMessage());
                for(Integer i = 0; i < e.getNumDml(); i++) {
                    if(String.isNotEmpty(e.getDMLMessage(i))) {
                        Grade__c g = tList[e.getDMLIndex(i)];
                        if(getAssignments.containsKey(g.Assignment__c)) {
                            Assignment__c a = getAssignments.get(g.Assignment__c);
                            String gKey = String.valueOf(g.Student_Section__c) + '_' + String.valueOf(g.Student__c) + '_' + String.valueOf(g.Assignment__c) + '_' + String.valueOf(g.Standard__c) + '_' + String.valueOf(a.Assignment_Library__r.Picklist_Value__c) + '_' + a.Due_Date__c.format();
                            errorHandling.put(gKey, e.getDMLMessage(i));
                        }
                    }
                }
                for(Grade__c g : tList) {   
                    if(getAssignments.containsKey(g.Assignment__c)) {
                        Assignment__c a = getAssignments.get(g.Assignment__c);
                        String gKey = String.valueOf(g.Student_Section__c) + '_' + String.valueOf(g.Student__c) + '_' + String.valueOf(g.Assignment__c) + '_' + String.valueOf(g.Standard__c) + '_' + String.valueOf(a.Assignment_Library__r.Picklist_Value__c) + '_' + a.Due_Date__c.format();
                        if(!errorHandling.containsKey(gKey)) {
                            errorHandling.put(gKey, '');
                        }
                    }
                }               
                
            }
            
            try {
                for(Grade__c g : tList) {
                    if(upsertFauxGrades.containsKey(g)) {
                        upsertFauxGrades.get(g).Standard_Gradebook_Grade__c = g.ID;
                    }
                }
                if(upsertFauxGrades.Values().size() > 0) {
                    upsert upsertFauxGrades.Values();           
                }   
            }
            catch(DmlException e) {
                errorHandling.put('e1', e.getMessage());
                for(Integer i = 0; i < e.getNumDml(); i++) {
                    if(String.isNotEmpty(e.getDMLMessage(i))) {
                        Grade__c g = upsertFauxGrades.Values()[e.getDMLIndex(i)];
                        if(getAssignments.containsKey(g.Assignment__c)) {
                            Assignment__c a = getAssignments.get(g.Assignment__c);
                            String gKey = String.valueOf(g.Student_Section__c) + '_' + String.valueOf(g.Student__c) + '_' + String.valueOf(g.Assignment__c) + '_' + String.valueOf(g.Standard__c) + '_' + String.valueOf(a.Assignment_Library__r.Picklist_Value__c) + '_' + a.Due_Date__c.format();
                            errorHandling.put(gKey, e.getDMLMessage(i));
                        }                       
                    }
                }
                for(Grade__c g : upsertFauxGrades.Values()) {   
                    if(getAssignments.containsKey(g.Assignment__c)) {
                        Assignment__c a = getAssignments.get(g.Assignment__c);
                        String gKey = String.valueOf(g.Student_Section__c) + '_' + String.valueOf(g.Student__c) + '_' + String.valueOf(g.Assignment__c) + '_' + String.valueOf(g.Standard__c) + '_' + String.valueOf(a.Assignment_Library__r.Picklist_Value__c) + '_' + a.Due_Date__c.format();
                        if(!errorHandling.containsKey(gKey)) {
                            errorHandling.put(gKey, '');
                        }
                    }
                }               
            }
        }
        
        //clear gradeEntries when done with a successful commit
        if(errorHandling.size() == 0) {
            errorHandling = null;
        }
        return errorHandling;
    }

    public void getGradeComment() {
        commentGrade = null;
        fauxCommentGrade = null;
        commentGradeKey = apexPages.currentPage().getParameters().get('commentGradeKey');
        System.debug('commentGradeKey'+commentGradeKey);
        List<String> tList = commentGradeKey.split('_');
        system.debug('@@tList'+tList);
        if(tList[3] == 'null') {
            tList[3] = null;
        }
        commentGrade = [SELECT ID, Student__c, Student_Section__c, Time__c, Assignment__c, Standard__c, Assignment__r.Assignment_Library__r.Picklist_Value__c, Exclude_From_Section_Grade__c, Include_In_Standard_Grade__c, Comment__c, Publish_Comment__c, (SELECT ID, Entered_Grade__c, Exclude_From_Section_Grade__c FROM Grades__r LIMIT 1) FROM Grade__c WHERE Student__c =: tList[1] AND Assignment__c =: tList[2] AND Standard__c =: tList[3] AND Standard_Gradebook_Grade__c = null LIMIT 1];
        system.debug('##commentGrade'+commentGrade.id);
        if(commentGrade.ID != null) {
            if(commentGrade.Grades__r.size() > 0) {
                fauxCommentGrade = commentGrade.Grades__r[0];
            }
        }
        system.debug('@@commentGrade'+commentGrade.ID);
        system.debug('##tList'+tList[2]);
        if(commentGrade.ID == null) {
            //have to get assignment
            system.debug('$$newcommenrgrade');
            system.debug('##tList'+tList[2]);
            Assignment__c a = [Select ID, Section__r.Course__c, Include_In_Final_Grade__c, Time__c, Weighting_Value__c FROM Assignment__c WHERE ID =: tList[2] LIMIT 1];
            //popluate grade to return for submission
            commentGrade.Student_Section__c = tList[0];
            commentGrade.Student__c = tList[1];
            commentGrade.Assignment__c = tList[2];
            
            if(standardBased && standardOnly) {
                commentGrade.Standard__c = tList[3];
                commentGrade.Standards_Only_Grading__c = true;
                commentGrade.Include_In_Standard_Grade__c = true;
                commentGrade.Course__c = a.Section__r.Course__c;
                commentGrade.Exclude_From_Section_Grade__c = !a.Include_In_Final_Grade__c;
                commentGrade.Time__c = a.Time__c;
                commentGrade.Standard_Times_Assignment__c = a.Weighting_Value__c;
                commentGrade.Assignment_Weighting__c = a.Weighting_Value__c;
                
                Grade__c fauxGrade = new Grade__c (
                    Student_Section__c = tList[0],
                    Student__c = tList[1],
                    Assignment__c = tList[2],
                    Standards_Only_Grading__c = true,
                    Include_In_Standard_Grade__c = false,
                    Course__c = a.Section__r.Course__c,
                    Exclude_From_Section_Grade__c = !a.Include_In_Final_Grade__c,
                    Time__c = a.Time__c,
                    Standard_Times_Assignment__c = a.Weighting_Value__c,
                    Assignment_Weighting__c = a.Weighting_Value__c
                );
                
                fauxCommentGrade = fauxGrade;
            }
            else {
                commentGrade.Standards_Only_Grading__c = true;
                commentGrade.Course__c = a.Section__r.Course__c;
                commentGrade.Exclude_From_Section_Grade__c = !a.Include_In_Final_Grade__c;
                commentGrade.Time__c = a.Time__c;
                commentGrade.Standard_Times_Assignment__c = a.Weighting_Value__c;
                commentGrade.Assignment_Weighting__c = a.Weighting_Value__c;
                
                if(tList.size() == 6) {
                    commentGrade.Standard__c = tList[3];
                    commentGrade.Include_In_Standard_Grade__c = true;
                }
            }
        }
    }
    
    public void submitGradeComment() {
        upsert commentGrade;
        if(fauxCommentGrade != null) {
            fauxCommentGrade.exclude_From_Section_Grade__c = commentGrade.exclude_From_Section_Grade__c;
            fauxCommentGrade.Standard_Gradebook_Grade__c = commentGrade.ID;
            upsert fauxCommentGrade;
        }

        //get section grade and update map
        //String sgKey = String.valueOf(commentGrade.Student_Section__c) + String.valueOf(commentGrade.Time__c);
        //loadedSchoolSection.studentColumnWrapperMap.get(sgKey).sectionGrade = [SELECT ID, Student_Section__c, Time__c, Key__c, Display_Grade_Formula__c, Letter_Grade__c, Grade_Overridden__c, Grade_Override__c FROM Section_Grade__c WHERE Key__c =: sgKey LIMIT 1];
    }
    
    public void getSGComment() {
        sgCommentGrades = new Section_Grade__c();
        sgCommentGradeKey = apexPages.currentPage().getParameters().get('sgCommentGradeKey');
        List<String> tList = sgCommentGradeKey.split('_');
        
        String key = tList[0] + tList[1];
        String rID = tList[0] + '-' + tList[1];
        sgCommentGrades = [SELECT ID, Grade__c, Credit_No_Credit_Section_Grade__c, Standard_Section_Grade_v2__c, Student_Section__r.Section__c, Student_Name_SG__c, Student_Section__r.Student__r.Home_Language__c, Alternate_Lang_Comments__c, Comments_Next_Steps__c, Key__c, Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__r.Category__c FROM Section_Grade__c WHERE (Key__c =: key OR Reference_ID__c =: rID) AND (RecordTypeID = null OR RecordType.Name = 'Quarter') LIMIT 1];
        
        if(sgCommentGrades.id != null) {
            //get srp 
            //generate 
            String srpID = tList[2] + '-' + tList[1];
            Section_ReportingPeriod__c srp = [SELECT ID, Course_Weighting__c FROM Section_ReportingPeriod__c WHERE ReferenceID__c =: srpID];
        }
    }
    
    public void submitSGComment() {
        if(sgCommentGrades.id == null) {
            upsert sgCommentGrades Key__c;
        }
        else {
            update sgCommentGrades;
        }
    }
    
    public void getAllSGComment() {
        allSGCommentGrades = null;
        
        Map<String, Section_Grade__c> tSGMap = new Map<String, Section_Grade__c>();
        List<Section_Grade__c> upsertSG = new List<Section_Grade__c>();
        List<Section_Grade__c> updateSG = new List<Section_Grade__c>();
        //pull all SG comments for current section
        for(Section_Grade__c sg : [SELECT ID, Grade__c, Credit_No_Credit_Section_Grade__c, Standard_Section_Grade_v2__c, Student_Section__r.Section__c, Student_Name_SG__c, Student_Section__r.Student__r.Home_Language__c, Alternate_Lang_Comments__c, Comments_Next_Steps__c, Key__c, Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__r.Category__c FROM Section_Grade__c WHERE Student_Section__r.Section__c =: loadedSchoolSection.section.ID AND Time__c =: loadedSchoolSection.reportingPeriod AND (RecordTypeID = null OR RecordType.Name = 'Quarter') AND Student_Section__c IN: loadedSchoolSection.referenceStudentSectionMap.get(loadedSchoolSection.reportingPeriod).Values()]) {
            if(sg.Key__c == null) {
                sg.Key__c = String.valueOf(sg.Student_Section__c) + loadedSchoolSection.reportingPeriod;
                updateSG.add(sg);
            }
            tSGMap.put(sg.Key__c, sg);
            system.debug('##tSGMap'+tSGMap);
        }
        
        Section_ReportingPeriod__c srp = [SELECT ID, Course_Weighting__c FROM Section_ReportingPeriod__c WHERE Time__c =: loadedSchoolSection.reportingPeriod AND Section__c =: loadedSchoolSection.section.ID LIMIT 1];
        
        //create section grades and commit them.
        for(Student_Section__c ss : loadedSchoolSection.referenceStudentSectionMap.get(loadedSchoolSection.reportingPeriod).Values()) {
            String sgKey = String.valueOf(ss.ID) + loadedSchoolSection.reportingPeriod;
            system.debug('##sgKey'+sgKey);
            if(!tSGMap.containsKey(sgKey)) {
                Section_Grade__c tSG = new Section_Grade__c();
                tSG.Student_Section__c = ss.ID;
                tSG.Time__c = loadedSchoolSection.reportingPeriod;
                tSG.Course_Weighting__c = srp.Course_Weighting__c;
                tSG.Key__c = String.valueOf(ss.ID) + loadedSchoolSection.reportingPeriod;
                tSG.Reference_ID__c = String.valueOf(ss.ID) + '-' + loadedSchoolSection.reportingPeriod;
                upsertSG.add(tSG);
            }
        }
        update updateSG;
        upsert upsertSG Key__c;
        
        allSGCommentGrades = [SELECT ID, Grade__c, Credit_No_Credit_Section_Grade__c, Standard_Section_Grade_v2__c, Student_Section__r.Section__c, Student_Name_SG__c, Student_Section__r.Student__r.Home_Language__c, Alternate_Lang_Comments__c, Comments_Next_Steps__c, Key__c, Student_Section__r.Section__r.Course__r.Grade_Scale_Lookup__r.Category__c FROM Section_Grade__c WHERE Student_Section__r.Section__c =: loadedSchoolSection.section.ID AND Time__c =: loadedSchoolSection.reportingPeriod AND (RecordTypeID = null OR RecordType.Name = 'Quarter') AND Student_Section__c IN: loadedSchoolSection.referenceStudentSectionMap.get(loadedSchoolSection.reportingPeriod).Values() ORDER BY Student_Section__r.Student__r.Student_Last_Name__c];
    }
    
    @RemoteAction 
    public static Map<String, Boolean> submitAllSGComment(Map<ID, String> sgComments, Map<ID, String> sgAltComments) {
        List<Section_Grade__c> upsertSG = new List<Section_Grade__c>();
        Map<String, Boolean> returnMap = new Map<String, Boolean>();
        for(Section_Grade__c sg : [SELECT ID, Alternate_Lang_Comments__c, Comments_Next_Steps__c, Student_Section__r.Section__c, Student_Section__c, Student_Section__r.Student__c, Time__c FROM Section_Grade__c WHERE (ID IN: sgComments.KeySet() OR ID IN: sgAltComments.KeySet()) AND Student_Section__c != null]) {
            if(sgComments.containsKey(sg.ID)) {
                sg.Comments_Next_Steps__c = sgComments.get(sg.ID);
            }
            if(sgAltComments.containsKey(sg.ID)) {
                sg.Alternate_Lang_Comments__c = sgAltComments.get(sg.ID);
            }
            
            String key = String.valueOf(sg.Student_Section__c) + '_' + String.valueOf(sg.Time__c) + '_' + String.valueOf(sg.Student_Section__r.Section__c) + '_' + String.valueOf(sg.Student_Section__r.Student__c);            
            if(String.isNotEmpty(sg.Comments_Next_Steps__c) || String.isNotEmpty(sg.Alternate_Lang_Comments__c)) {
                returnMap.put(key, true);
            }
            else {
                returnMap.put(key, false);
            }
            upsertSG.add(sg);
        }
        
        upsert upsertSG;
        return returnMap;
    }
    
    public pageReference xls() {
        //get data again            
        loadedSchoolSection.loadAssignments();

            system.debug('*~*~* assignments: ' + loadedSchoolSection.assignments);      
            system.debug('*~*~* assignmentTypes: ' + loadedSchoolSection.assignmentTypes);
            system.debug('*~*~* startDate: ' + loadedSchoolSection.startDate);
            system.debug('*~*~* endDate: ' + loadedSchoolSection.endDate);
            system.debug('*~*~* student: ' + loadedSchoolSection.students); 
        
        loadedSchoolSection.getCurrentExport();
        PageReference pr = new PageReference('/apex/Gradebook_Export_v2');
        return pr;
    }
    
    public void openQCA() {
        gQCA = new Gradebook_Quick_Create_Assignment(currentSchool.activeSetup, loadedSchoolSection.section, loadedSchoolSection.getTE(loadedSchoolSection.reportingPeriod));
        gQCA.initializeQuickCreateAssignment();
        timeID = loadedSchoolSection.reportingPeriod;
    }
    
    public void submitAssignment() {
        assignmentID = gQCA.submit();
    }
    
    //===================================================================================================================//
    
    public class orderWrapper {
        public Staff_Section__c staffSection {get; set;}
        public String order {get; set;}
        
        public orderWrapper(Staff_Section__c ss) {
            this.staffSection = ss;
            this.order = String.valueOf(ss.Order__c);
        }
    }
    
    public void buildOrderWrapper() {
        ssOrder = new List<orderWrapper>();
        for(Staff_Section__c ss : orderedSchoolSections) {
            ssOrder.add(new orderWrapper(ss));
        }
    }
    
    //===================================================================================================================//
    //Utility Methods
    public String errorMsg {get; set;}
    
    public void errorProcess(){
        List<String> errorMessages = errorMsg.split('\n');
        for(String message:errorMessages){
            Error_Handling.errorMessage(message);
        }
    }   
}