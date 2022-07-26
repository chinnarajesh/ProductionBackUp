public without sharing class AssessmentWizardController {
    /* PAGE CONTROL */
    private Integer recordsCount {get;set;}
    private Integer recordSearchCount {get;set;}
    public boolean mainPage {get;set;}   
    public string callDateError{get;set;}//Added by harsh singh for showing error message if date is null in the template 
    public String slctdStdId{get;set;} //String formatted array which we will receive from VF page. 
    public List<Assesment__c> assessmentsExport{get;set;}
    private Set<Id> theSearchedAssessmentIds { get; set; }
    public Integer exportCount{get;set;}
    // public boolean checkDate=false;//Added by harsh singh to check if there is Date_Administered__c in the CSV file
    /* ASSESSMENT GROUPS */
    public boolean showStudentSearch        {get;set;}
    public boolean showAssessmentPane       {get;set;}
    public boolean showStudentAssessments   {get;set;}
    public boolean pastMode                 {get;set;}
    /* ASSESSMENT IMPORT */
    public boolean showImport   {get;set;}
    public boolean showDataPane {get;set;}
    /* EXISTING EXPORT */
    public boolean showExport   {get;set;}

    /* GENERAL CONTAINERS */
    private boolean isManagedPackage;
    private Map<String, String> assessmentAPIMap;
    private Map<String, String> assessmentLabelMap;
    private Map<String, String> assessmentSystemLabels;
    private Map<String, String> fieldTypeMap;
    private Map<String, Integer> fieldLengthMap;
    private Map<ID, String> studentMap;
    private Id assessmentTypeRTID;
    public string possibleSchools                       {get;set;}

    /* GROUP CONTAINERS */
    private Map<ID, Time_Element__c> years;
    public List<SelectOption> yearOptions               {get;set;}
    public string selectedYear                          {get;set;}
    public studentWrapper studentSearchInfo             {get;set;}
    public sectionWrapper sectionSearchInfo             {get;set;}
    public  List<studentWrapper> studentList             {get;set;}//Addedby Harsh 3 may 2016
    public  List<studentWrapper> studentSearchResults    {get;set;}
    public  List<sectionWrapper> sectionSearchResults    {get;set;}
    public String searchType                            {get;set;}
    public Set<Id> selectedStudents                     {get;set;}
    public String redirectURL                           {get;set;}

    /* EXPORT CONTAINERS */
    public  List<assessmentWrapper> newAssessments      {get;set;}//Addedby Harsh 3 may 2016
    public List<SelectOption> typeOptions               {get;set;}
    private Map<Id, Picklist_Value__c> typeMap;  
    public string selectedType                          {get;set;}
    public Picklist_Value__c selectedPL                 {get;set;}
    public List<SelectOption> typeIAOptions             {get;set;}
    public String typeIASelected                        {get;set;}
    transient public string csvdata                     {get;set;}
    
    /* EXPORT EXISTING CONTAINERS */
    public Section__c gradeHolder   {get;set;}
    public String startDate         {get;set;}
    public string endDate           {get;set;}
    /* IMPORT CONTAINERS */
    public String fileContentType       {get;set;}
    public String fileName              {get;set;}
    public String fileSize              {get;set;}
    public Transient Blob fileBlob                {get;set;}
    public dataWrapper inputWrapper     {get;set;}
    public dataWrapper importwrapper     {get;set;}

    public AssessmentWizardController(){
        mapAssessmentToRemove = new Map<String, Boolean>();
        assessmentAPIMap = new Map<String, String>();
        assessmentLabelMap =  new Map<String, String>();

        try{
            recordsCount=Integer.valueOf(Label.Record_Count);
            recordSearchCount=Integer.valueOf(Label.Record_Count_Search);
            assessmentTypeRTID = CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Assessment_Type');
            isManagedPackage = Schema.SObjectType.Assesment__c.getName().replace('__c', '').contains('__');
            loadIATypes();
            createAssessmentFieldSet();
            mainpage = true;
            createGroup();
            searchType='student';
            showDataPane = false;
            showExport = false;
            pastMode = false;
            if(ApexPages.currentPage().getParameters().get('goodimport') != null){
                infoMessage('The data was imported successfully.');
            }
        } catch (Exception e){
            errorMessage('Error during load. Please contact your system administrator.');
        }
    }

    /* PAGE CONTROL METHODS */
    public PageReference goHome(){
        mainPage = true;
        showImport = false;
        showStudentSearch = false;
        showAssessmentPane = false;
        showDataPane = false;
        showExport = false;
        studentSearchResults.clear();
        sectionSearchResults.clear();

        if(ApexPages.currentPage() != Page.AssessmentWizard){
            pageReference pref = Page.AssessmentWizard;
            pref.getParameters().put('goodimport', 'true');
            return pref;
        } else {
            return null;
        }
    }

    public void goToMain(){
        studentList = new List<studentWrapper>();
        selectedStudents = new Set<Id>();
        goHome();
    }
    
    public PageReference cancelImport(){
        goHome();
        buildSchoolList();
        return Page.AssessmentWizard;
    }

    public void createGroup(){
        yearOptions = new List<SelectOption>();
        studentList = new List<studentWrapper>();
        studentSearchResults = new List<studentWrapper>();
        sectionSearchResults = new List<sectionWrapper>();
        studentSearchInfo = new studentWrapper();
        sectionSearchInfo = new sectionWrapper();
        selectedStudents = new Set<Id>();
        selectedYear = '';
        selectedPL = new Picklist_Value__c();
        Time_Element__c latestYear = new Time_Element__c();

        years = new Map<Id, Time_Element__c>(Assessment_SoqlUtils.getYears());
        for(Time_Element__c t: years.values()){
            yearOptions.add(new SelectOption(t.id, t.Name__c));
            if(t.Date_Start_Date__c < system.today() && t.End_Date__c > system.today()){
                selectedYear = t.id;
            }
            if(latestYear.id == null || latestYear.End_Date__c < t.End_Date__c){
                latestYear = t;
            }
        }
        if(yearOptions.isEmpty()){
            errorMessage('Unable to find a valid year. Please contact your system admin.');
        } else {
            if(selectedYear == ''){
                selectedYear = latestYear.id;
            }
            showStudentSearch = true;
        }
        buildSchoolList();
    }

    public pageReference startImport(){
        inputWrapper = new DataWrapper();//added 5/4/2016 
        importwrapper = new DataWrapper();//added 5/4/2016       
        if(studentList!=null){studentList.clear();  studentList = new List<studentWrapper>();}
        if(newAssessments!=null){
            newAssessments.clear();
            System.debug('AssessmentSize@@@@'+newAssessments);
            newAssessments=new List<assessmentWrapper>();
        }//added 4/19/2016 
        newAssessments=new List<assessmentWrapper>();
        if(inputWrapper!=null){inputWrapper.assessments.clear();}
        if(importwrapper!=null){importwrapper.assessments.clear();}
        if(assessmentsExport!=null){assessmentsExport.clear();assessmentsExport=new List<Assesment__c>();}
        if(studentSearchInfo!=null){studentSearchInfo=new studentWrapper();}
        if(sectionSearchInfo!=null){ sectionSearchInfo = new sectionWrapper();}
        if(studentSearchResults!=null){studentSearchResults.clear();}
        if(sectionSearchResults!=null){sectionSearchResults.clear();}
        
        System.debug('StudentList-->'+studentList.size());
        showDataPane = false;
        csvData='';
        return Page.Assessment_Import;
    }

    public void changeAssessmentType(){
        showStudentAssessments = true;
        selectedPL = typeMap.get(selectedType);
        if(!showExport){
            for(assessmentWrapper a: newAssessments){
                a.assessment.Type__c = selectedPL.id;
                a.assessment.Year_Over_Year__c = selectedPL.Year_Over_Year__c;
                a.assessment.Show_On_Report_Card__c = selectedPL.Show_On_Report_Card__c;
                a.assessment.Show_On_Transcript__c = selectedPL.Show_On_Transcript__c;
            }
        }
    }
    /* END PAGE CONTROL METHODS */

    /* ACTION METHODS */
    public void changeYear(){
        studentList = new List<studentWrapper>();
        studentSearchResults.clear();
        sectionSearchResults.clear();
        studentSearchInfo = new studentWrapper();
        sectionSearchInfo = new sectionWrapper();
        buildSchoolList();
        showStudentSearch = true;
        pastmode = false;
    }

    public void groupSearch(){
        assessmentsExport = new List<Assesment__c>();
        List<sObject> sResults = new List<sObject>();

        if(searchType == 'student' && studentSearchInfo.school!=null && possibleSchools!=null && pastMode!=null){
            studentSearchResults = new List<studentWrapper>();
            String selYear = (!pastMode && (possibleSchools.contains(studentSearchInfo.school) || studentSearchInfo.school != '--None--'))? selectedYear: null;
            sResults = Assessment_SoqlUtils.searchStudents(studentSearchInfo, selYear);

            for(sObject stud: sResults){//Student__c
                studentSearchResults.add(new studentWrapper((Student__c)stud));
            }
        } else if(sectionSearchInfo!=null && searchType=='section') {
            sectionSearchResults = new List<sectionWrapper>();
            sResults = Assessment_SoqlUtils.searchSections(sectionSearchInfo.section,sectionSearchInfo.rcdType ,sectionSearchInfo.course.Name, selectedYear);//Record type for T-493158

            for(sObject sec: sResults){//Section__c
                sectionSearchResults.add(new sectionWrapper((Section__c)sec));
            }
        }

        if(sResults.isEmpty()){
            infoMessage('Search returned 0 results.');
            return;
        } else if(sResults.size()==recordSearchCount){
            infoMessage('Your search terms returned more then '+recordSearchCount+' results. Only the first '+recordSearchCount+' are displayed.');
        }
    }

    public void getstdata(){
        if(inputWrapper!=null){
            inputWrapper.assessments.clear();
        }
        if(importwrapper!=null){
            importwrapper.assessments.clear();
        }
        if(assessmentsExport!=null){
            assessmentsExport.clear();
        }
        System.debug('myString: ' +slctdStdId );
        String str=slctdStdId;
        List<String> listOfId=str.split(',');
        System.debug('List Of String'+listOfId);
        addStudents(new Set<String>(listOfId));
        listOfId.clear();
        slctdStdId='';
    }
    public void addStudents( Set<String> stIds){
        boolean foundStudent = false;
        for(studentWrapper s:studentSearchResults){
          
            if(stIds.contains(s.student.Student_Id__c)){
                if(!selectedStudents.contains(s.student.id)){
                    studentList.add(s);
                    s.selected = true;
                    foundStudent = true;

                    if(selectedStudents.size()<1000)
                        selectedStudents.add(s.student.id);
                    else {
                        errorMessage('You have already selected 1000 students. You cannot select more then 1000 students at a time.');
                        return;
                    }
                } else {
                    infoMessage('Student ' + s.student.Name + ' is already in the group.');
                }
            }
            
            /* if(s.selected){
                if(!selectedStudents.contains(s.student.id)){
                    studentList.add(s);
                    s.selected = false;
                    foundStudent = true;

                    if(selectedStudents.size()<1000)
                        selectedStudents.add(s.student.id);
                    else {
                        errorMessage('You have already selected 1000 students. You cannot select more then 1000 students at a time.');
                        return;
                    }
                } else {
                    infoMessage('Student ' + s.student.Name + ' is already in the group.');
                }
            }*/
        }

        if(!foundStudent){
            errorMessage('Error: Please select a student.');
            return;
        }
        studentSearchResults.clear();
    }

    public void removeStudents(){       
        boolean foundStudent = false;
        List<studentWrapper> tempList = new List<studentWrapper>();
        for(studentWrapper s:studentList){
            if(!s.selected){
                tempList.add(s);
            } else {
                foundStudent = true;
                selectedStudents.remove(s.student.id);
            }
        }
        studentList = tempList;

        if(!foundStudent){
            errorMessage('Error: Please select a student.');
            return;
        }
    }

    public void generateAssessments(){
        newAssessments = new List<assessmentWrapper>();
        studentList = sortStudents(studentList);
        for(studentWrapper s: studentList){
            if(s.selected){
                Assesment__c a = new Assesment__c(Date__c = system.today());
                if(!pastMode && possibleSchools.contains(s.student.School__c)){
                    a.Student__c = s.student.id; 
                    a.Student_Name__c = s.student.Student_First_Name__c+' '+s.student.Student_Last_Name__c;
                }
                newAssessments.add(new assessmentWrapper(a, s.student));
            }
        }
        showAssessmentPane = true;
        mainPage = false;
        studentList.clear();//Added on 3rd May 2016 By Harsh Singh
        studentSearchResults.clear();
        sectionSearchResults.clear();
        selectedType = '';

        typeIASelected = '';
        loadTypes(typeIASelected);
        showStudentAssessments = false;
    }

    public Map<String, Boolean> mapAssessmentToRemove {get;set;}
    public void processInput(){
        mapAssessmentToRemove = new Map<String, Boolean>();
        if(assessmentAPIMap!=null){
             createAssessmentFieldSet();//Added on 9th May
        }
        callDateError='';
        if(importwrapper!=null){
            importwrapper.assessments.clear();
        }
        assessmentsExport = new List<Assesment__c>();
        inputWrapper = new dataWrapper();
      
        studentSearchResults.clear();
        sectionSearchResults.clear();           
        studentList.clear();
        newAssessments = new List<assessmentWrapper>();

        showDataPane = false;
        boolean success = false;
        success = extractData();
        if(!success){
            return;
        }
        inputWrapper.skipColumns = 3;//skip fields Student USID, Student Id, Student Name
        inputWrapper.studentData.headers.remove(0);//remove Student USID
        inputWrapper.studentData.headers.remove(0);//remove Student Id
        inputWrapper.studentData.headers.remove(0);//remove Student Name
        inputWrapper.studentData.headers.remove(inputWrapper.studentData.headers.size()-1);
        success = splitData();
        if(!success){
            return;
        }
        success = parseStudentData();
        showDataPane = success? true: showDataPane;
        for(sObject a: inputWrapper.assessments){
            mapAssessmentToRemove.put(a.Id, false);
        }
       // system.debug(' inputWrapper.studentData'+ inputWrapper.studentData.parsedData.size());
        inputWrapper.studentData=null;//Added on 9th May 2016
        assessmentAPIMap.clear();//Added on 9th May 2016
        assessmentLabelMap.clear();//Added on 9th May 2016
        assessmentSystemLabels.clear();//Added on 9th May 2016
    }
    
    public void saveExisting(){
        saveInput();
        if(callDateError==''){
            mainPage = true;
            showExport = false;
        }else{
            mainPage = false;
            showExport = true;
        }
    }

    public PageReference saveInput(){       
        callDateError='';
        //remove all selected assessments
        Map<Id, sObject> mapAssessment = new Map<Id, sObject>();
        for(sObject a: inputWrapper.assessments){
            mapAssessment.put(a.Id, a);
        }
        for(String idx: mapAssessmentToRemove.keySet()){
            Integer index = mapAssessment.containsKey(idx)? inputWrapper.assessments.indexOf(mapAssessment.get(idx)): -1;
            if(mapAssessmentToRemove.get(idx) == true && index>=0){
                mapAssessmentToRemove.put(idx, false);
                inputWrapper.assessments.remove(index);
            }
        }
        List<String> msgErrors = updateAssessments(inputWrapper);
        boolean goodSave = msgErrors.isEmpty();
        if(goodSave){
            infoMessage('The data was imported successfully.');
            inputWrapper = new dataWrapper();
            studentList = new List<studentWrapper>();
            studentSearchResults = new List<studentWrapper>();
            sectionSearchResults = new List<sectionWrapper>();
            studentSearchInfo = new studentWrapper();
            sectionSearchInfo = new sectionWrapper();
            selectedStudents = new Set<Id>();
            assessmentAPIMap = new Map<String, String>();//Added on 9th May
            assessmentLabelMap =  new Map<String, String>();//Added on 9th May
            createAssessmentFieldSet();//Added on 9th May
            pageReference pref = Page.AssessmentWizard;
            buildSchoolList();
            return pref;
        } else {
            errorMessage('There were errors when saving the data. Please fix the errors and try again.');
            for(String msg: msgErrors){
                errorMessage(msg);
            }
            return null;
        }
    }

    public void searchChange(){
        studentSearchResults.clear();
        sectionSearchResults.clear();
    }

    public void addSections(){
        boolean foundSection = false;
        Set<Id> sectionIds = new Set<Id>();
        for(sectionWrapper s:sectionSearchResults){
            if(s.selected){
                sectionIds.add(s.section.id);
                foundSection = true;
            }
        }

        if(!foundSection){
            errorMessage('Error: Please select a section.');
            return;
        }
        for(Student__c s: Assessment_SoqlUtils.getStudentsInSections(sectionIds)){
            if(!selectedStudents.contains(s.id)){
                studentWrapper sw = new studentWrapper(s);
                sw.selected = true;
                studentList.add(sw);
            } else {
                infoMessage('Student ' + s.Name + ' is already part of the group.');
            }
        }

        sectionSearchResults.clear();
    }
    
    public PageReference exportExisting(){
        newAssessments = new List<assessmentWrapper>();
        
        for(SObject s:inputWrapper.assessments){
            Assesment__c tempAssessment = (Assesment__c)s;
            System.debug('assessment1'+tempAssessment);
            newAssessments.add(new assessmentWrapper(tempAssessment, tempAssessment.Student__r));
        }
        generateCSV(true);newAssessments.clear();//4th May 2016
        return Page.Assessment_Export;
    }

    public PageReference exportExisting2(){
        newAssessments = new List<assessmentWrapper>();
        for(Assesment__c s: Database.query('SELECT Date__c, Student_Name__c, Student__r.Student_First_Name__c, Student__r.Student_Last_Name__c, Student__r.Legacy_Id__c, Student__r.Student_Id__c,' + String.escapeSingleQuotes(typeMap.get(selectedType).fieldSet__c) + ' From Assesment__c where Id IN :theSearchedAssessmentIds')){
            Assesment__c tempAssessment = (Assesment__c)s;
            newAssessments.add(new assessmentWrapper(tempAssessment, tempAssessment.Student__r));
        }
        generateCSV(true);
        newAssessments.clear();//4th May 2016
        return Page.Assessment_Export;
    }
    
    public PageReference saveForExport(){ 
        studentList = new List<studentWrapper>();
        List<String> msgErrors = new List<String>();
        if(selectedType == '' || selectedType == '--None--'){
            errorMessage('Please select an assessment type.');
            return null;
        }
        List<Assesment__c> assessments = new List<Assesment__c>();
        for(assessmentWrapper a: newAssessments){
            a.assessment.Type__c = selectedType;
            a.assessment.Contact__c = (typeMap.get(selectedType).Year_over_year__c || pastMode || a.assessment.Student__c==null)?a.student.Individual__c:null;
            a.assessment.Year_Over_Year__c = pastMode || a.assessment.Student__c==null||a.assessment.Year_Over_Year__c;
            assessments.add(a.assessment);
        }
        if(msgErrors.isEmpty()){
            msgErrors.addAll( saveAssessments((List<Assesment__c>)assessments));
        }
        Boolean success = msgErrors.isEmpty();
        assessments.clear();//Added on 3rd May 2016 by Harsh singh                              
        if(!success){
            errorMessage('Error while saving data. Please try again.');
            for(String msg: msgErrors){
                errorMessage(msg);
            }
            return null;
        }
        generateCSV(false);newAssessments.clear();//4th May 2016
        newAssessments=new List<assessmentWrapper>();                                 
        System.debug('Assessment#####'+newAssessments.size());
                                       //  newAssessments.clear();//Added on 4th May 2016                                         
        return Page.Assessment_Export;
    }
    
    public void startExistingExport(){
        showExport = true;
        mainPage = false;
        typeIASelected = '';
        loadTypes(typeIASelected);
        buildSchoolList();
        typeOptions.remove(0);
        gradeHolder = new Section__c();
    }
    
    public void searchExisting(){
        inputWrapper = new DataWrapper();
        importwrapper = new DataWrapper();
        assessmentsExport = new List<Assesment__c>();
        studentSearchResults = new List<studentWrapper>();
        sectionSearchResults = new List<sectionWrapper>();
        newAssessments = new List<assessmentWrapper>();
        Date sDate = null, eDate = null;

        Boolean checkallDate = (studentSearchInfo.nullDateAdminister!=true && String.isBlank(startDate) && String.isBlank(endDate))? false: true;
        if(checkallDate == true){
            try{
                sDate = String.isNotBlank(startDate)? Date.parse(startDate): null;
                eDate = String.isNotBlank(endDate)? Date.parse(endDate): null;
            }catch (System.TypeException e){
                errorMessage('Please enter a valid date'); return;
            }
        }

        System.debug('##Indicator'+studentSearchInfo.indicatorArea);
        List<Assesment__c> assessments = Assessment_SoqlUtils.getExistingAssessments(typeMap.get(selectedType), studentSearchInfo.student, sDate, eDate, studentSearchInfo.school, gradeHolder.All_Grades__c, studentSearchInfo.indicatorArea,studentSearchInfo.nullDateAdminister);
        if(assessments.isEmpty()){
            infoMessage('Search returned no results.'); return;
        }

        //populate DataList
        List<Assesment__c> firstTwentyAssessments =new List<Assesment__c>();
        Integer size = (assessments.size()<20)? assessments.size(): 19;
        for(integer i=0;i<size;i++){
            firstTwentyAssessments.add(assessments[i]);
        }

        theSearchedAssessmentIds = new Set<Id>();
        for(Assesment__c theRecord : assessments) {
            theSearchedAssessmentIds.add(theRecord.Id);
        }
        assessments.clear();

        // assessmentsExport=assessments;
        // importwrapper=inputWrapper;
        importwrapper.assessments = (List<sObject>) firstTwentyAssessments;
        System.debug('Import size');
        List<String> fieldList = new List<String>();//new List<String>{'Date__c'};
        fieldList.addAll(StringUtils.splitAndTrim(typeMap.get(selectedType).FieldSet__c,','));
        for(String field: fieldList){
            importwrapper.displayLabels.add(new fieldWrapper(assessmentSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
        }
        exportCount=Assessment_SoqlUtils.getExistingAssessmentsCount(typeMap.get(selectedType), studentSearchInfo.student, sDate, eDate, studentSearchInfo.school, gradeHolder.All_Grades__c,studentSearchInfo.indicatorArea,studentSearchInfo.nullDateAdminister);

        sDate=NULL;
        eDate=Null;
        studentSearchInfo.nullDateAdminister=false;

        infoMessage('Your query returned ' + exportCount + ' assessment records. '+
                ((exportCount > 10000)? 'You will be able to export only first 10,000 records. ': '')+
                'Displaying first 20 records.....');
    }
    
    public void dummyRefresh(){
        studentSearchResults.clear();
        sectionSearchResults.clear();
    }
    /* END ACTION METHODS */

    /* HELPER METHODS */
    private static final String PROFILESITEADMIN = 'Site Administrator';
    private static final String PROFILESCHOOLADMIN = 'School Administrator';
    private void buildSchoolList(){
        possibleSchools = '';
        for(Setup__c s:Assessment_SoqlUtils.getSetupsByYear(selectedYear)){
            possibleSchools+=s.School__c;
        }

        studentSearchInfo.schools.clear();
        if(String.isBlank(possibleSchools)){
            pastMode = true;
            searchType = 'student';
            studentSearchInfo.Schools.add(new SelectOption('--None--', '--None--'));
            studentSearchInfo.indicatorAreas.add(new SelectOption('--None--', '--None--'));
            return;
        }

        //Added for T-493156 begin
        Schema.DescribeFieldResult studentStatus = Indicator_Area__c.Indicator_Area_Type__c.getDescribe();
        List<Schema.PicklistEntry> studentStatusValues = studentStatus.getPicklistValues();
        List<String> picval=new List<String>();
        studentSearchInfo.indicatorAreas.clear();
        for(Schema.PicklistEntry  pe : studentStatusValues){
            if(pe.isActive()==true ){
                 studentSearchInfo.indicatorAreas.add(new SelectOption(pe.getValue(),pe.getValue()));
           }
        }//Added for T-493156 end

        Map<String, Profile> mapProfiles = new Map<String, Profile>([SELECT Id, Name FROM Profile WHERE Name IN (:PROFILESITEADMIN, :PROFILESCHOOLADMIN)]);
        Set<ID> schoolIDs = new Set<ID>();        
        String querySetup = 'SELECT Id, School__c, School__r.Name FROM Setup__c WHERE School__r.RecordType.Name = \'School\'';
        Id cProfileId = System.Userinfo.getProfileId();
        //School list for Site Administrator profile
        if(mapProfiles.containsKey(cProfileId) && mapProfiles.get(cProfileId).Name == PROFILESITEADMIN){
            Set<String> cUserLocations = new Set<String>();
            for(UserTerritory2Association ut2a: [SELECT Id, Territory2.Name, Territory2.Territory2Model.Name 
                            FROM UserTerritory2Association 
                            WHERE UserId = :Userinfo.getUserId()]){
                cUserLocations.add(ut2a.Territory2.Name);
            }
            querySetup += ' AND School__r.Is_Active__c = true';
            if(!cUserLocations.isEmpty()){
                querySetup += ' AND School__r.Site__c IN (\'' + String.join(new List<String>(cUserLocations), '\',\'') + '\')';
            }
        }
        //School list for School Administrator profile
        else if(mapProfiles.containsKey(cProfileId) && mapProfiles.get(cProfileId).Name == PROFILESCHOOLADMIN){
            //getting child contact to logged in user
            Set<String> schoolIdSet = new Set<String>();
            for(Staff__c staff :[SELECT Organization__c FROM Staff__c 
                                WHERE Active__c = true AND Individual__c IN 
                                (SELECT Id FROM Contact WHERE User__c = :Userinfo.getUserId() AND Active__c = true)]){
                schoolIdSet.add(staff.Organization__c);
            }
            if(!schoolIdSet.isEmpty()){
                querySetup += ' AND School__c IN (\'' + String.join(new List<String>(schoolIdSet), '\',\'') + '\')';
            }
        }
        querySetup += ' ORDER BY School__r.Name';

        System.debug('@@@ querySetup: '+querySetup);
        for(Setup__c s: Database.query(querySetup)){
            if(!schoolIDs.contains(s.School__c)){
                studentSearchInfo.Schools.add(new SelectOption(s.School__c, s.School__r.Name));
                schoolIds.add(s.School__c);
            }
        }
        studentSearchInfo.Schools.add(0, new SelectOption('--None--', '--None--'));
        studentSearchInfo.indicatorAreas.add(0, new SelectOption('--None--', '--None--'));
        pastMode = false;
    }

    //This could be a lot more memory efficent, if you run into heap size issues, start here.
    //See the fieldWrapper object. Map<API, fieldWrapper> would probably be best. I just don't have to the time.
    private void createAssessmentFieldSet(){
        assessmentSystemLabels = new Map<String, String>();
        fieldTypeMap = new Map<String, String>();
        fieldLengthMap = new Map<String, Integer>();
        Set<String> excludeSet = new Set<String>{'Student__c', 'Student_Id__c', 'Type__c', 'Contact__c'
                                                ,'External_Id__c', 'Time__c', 'Year_Over_Year__c'
                                                ,'Show_On_Report_Card__c', 'Show_On_Transcript__c'};

        Map<String, Schema.SObjectField> describe = Schema.SObjectType.Assesment__c.fields.getMap();

        for(Schema.Sobjectfield s: describe.values()){
            string fieldName = String.valueOf(s);
            fieldName = (isManagedPackage)?fieldName.replace('SchoolForce__', ''):fieldName;

            if(fieldName.contains('__c') && !excludeSet.contains(fieldName)){
                string api = fieldName;
                //we need to make sure the field headers are unique
                string label = s.getDescribe().getLabel();
                string uniquelabel = label+' (' + api + ')';

                assessmentAPIMap.put(api, uniqueLabel);
                assessmentSystemLabels.put(api, label);
                assessmentLabelMap.put(uniqueLabel, api);
                string fieldType = String.valueOf(s.getDescribe().getType());
                fieldTypeMap.put(api, fieldType);
                if(fieldType == 'TEXT' || fieldType == 'TEXTAREA'){
                    fieldLengthMap.put(api, Integer.valueOf(s.getDescribe().getLength()));
                } else if(fieldType == 'DOUBLE' || fieldType == 'PERCENT'){
                    fieldLengthMap.put(api, Integer.valueOf(s.getDescribe().getPrecision()));
                }
            }
        }
    }

    private void errorMessage(string error){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
    }

    private void infoMessage(string message){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
    }

    private List<String> saveAssessments(List<Assesment__c> assessments){
        List<String> msgErrors = new List<String>();
        try{
            insert assessments;
        }catch(DmlException e){
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msgErrors.add('Record Num: '+(e.getDmlIndex(i)+1)+'. Fields: '+String.join(e.getDmlFieldNames(i), ',')+'. '+e.getDmlMessage(i) );
                System.debug(e.getDmlMessage(i));
            }
        }
        return msgErrors;
    }
    
    private List<String> updateAssessments(DataWrapper dw){
        List<Assesment__c> assessments = (List<Assesment__c>)dw.assessments;
        List<String> msgErrors = new List<String>();
        
        Set<String> studentIds = new Set<String>();
        Set<String> typeIds = new Set<String>();
        Set<Date> adminDates = new Set<Date>();
        for(Assesment__c a: assessments){
            studentIds.add(a.Student_Id__c);
            typeIds.add(a.Type__c);
            adminDates.add(a.Date_Administered__c);
        }

        try{
            Integer i=0;
            for (Assesment__c assmnt : assessments){   
                if(String.isBlank(String.valueof(assmnt.Date_Administered__c))){
                    callDateError='<script> dateValError(); </script>';
                    assmnt.Date_Administered__c.addError(Label.MissingDate);
                    msgErrors.add(Label.MissingDate);
                }
                if(assmnt.Date_Administered__c > Date.today()){
                    assmnt.Date_Administered__c.addError('Date administered cannot be in the future.');
                    msgErrors.add('Date administered cannot be in the future.');
                }
                i++;
            }

            if(!msgErrors.isEmpty()){
                return msgErrors;
            }
            try{
                update assessments;
            }catch(DmlException e){
                for (i = 0; i < e.getNumDml(); i++) {
                    msgErrors.add('Record Num: '+(e.getDmlIndex(i)+1)+'. Fields: '+String.join(e.getDmlFieldNames(i), ',')+'. '+e.getDmlMessage(i));
                    System.debug(e.getDmlMessage(i));
                }
            }
            return msgErrors;
        } catch (Exception e) {
            msgErrors.add(e.getMessage());
            return msgErrors;
        }
    }

    private void generateCSV(boolean existing){
        string fieldSet = ((existing)?'Date__c,':'') + typeMap.get(selectedType).fieldSet__c;
        string genDate = system.today().month() + '-' + system.today().day() + '-' + system.today().year();
        fileName = typeMap.get(selectedType).Name.replace(' ', '_') + '_Assessments_' + genDate;

        string fieldString = getBlankFieldString(fieldSet);
        List<String> allRows = new List<String>();
        allRows.add(typeMap.get(selectedType).Name + ' Assessments,Generated ' + genDate);
        allRows.add(getFieldHeaders(fieldSet));
        for(assessmentWrapper a: newAssessments){
            List<String> dataRow = new List<String>();
            sObject sobj = (sObject) a.assessment;
            Map<String, Schema.SobjectField> fmap = sobj.getSObjectType().getDescribe().fields.getMap();
            dataRow.add(a.student.Legacy_Id__c+',');
            dataRow.add(a.student.Student_Id__c+',');
            dataRow.add('"' + a.student.Student_Last_Name__c + ', ' + a.student.Student_First_Name__c + '",');
            if(!showExport){
                dataRow.add(fieldString);
            } else {
                for(String s: StringUtils.splitAndTrim(fieldSet,',')){
                    if(sobj.get(s) != null){
                        //the quotes are an oversimplifcation, assume everything needs them.
                        if(fmap.get(s).getDescribe().getType() == Schema.DisplayType.Date) //s == 'Date__c')
                            dataRow.add('"' + String.valueOf(sobj.get(s)).split(' ')[0] + '",');
                        else
                            dataRow.add('"' + sobj.get(s) + '",');
                        
                    } else {
                        dataRow.add(',');
                    }
                }
            }
            dataRow.add(a.assessment.id);
            allRows.add(String.join(dataRow,''));
        }
        csvData = String.join(allRows,'\n');
        allRows.clear();//Added on 4th May 2016
        newAssessments.clear();//Added on 4th May 2016
    }

    private String getFieldHeaders(string fieldSet){
        string fieldheaders = 'Student USID, Student Id, Student Name';
        for(String s: StringUtils.splitAndTrim(fieldSet, ',')){
            fieldHeaders += ',' + assessmentAPIMap.get(s);
        }
        fieldHeaders += ',ID';
        return fieldHeaders;
    }

    private string getBlankFieldString(string fieldSet){
        string fieldString = '';
        for(String s: StringUtils.splitAndTrim(fieldSet, ',')){
            fieldString += ',';
        }
        return fieldString;
    }

    public void changeAssessmentTypeIA(){
        loadTypes(typeIASelected);
    }

    public void loadIATypes(){
        typeIAOptions = new List<SelectOption>();
        typeIAOptions.add(new SelectOption('', '--None--', true));
        Schema.DescribeFieldResult descIA = Picklist_Value__c.Indicator_Area__c.getDescribe();
        List<Schema.PicklistEntry> lstSchemaIA = descIA.getPicklistValues();
        for(Schema.PicklistEntry  pe : lstSchemaIA){
            if(pe.isActive()==true ){
                typeIAOptions.add(new SelectOption(pe.getValue(),pe.getValue()));
            }
        }
    }

    private void loadTypes(String typeIA){
        typeMap = new Map<Id, Picklist_Value__c>(Assessment_SoqlUtils.getTypes(assessmentTypeRTID, typeIA));
        typeOptions = new List<SelectOption>();
        for(Picklist_Value__c pv: typeMap.values()){
            typeOptions.add(new SelectOption(pv.id, pv.Name));
        }
        typeOptions = sortList(typeOptions);
        if(typeOptions.isEmpty()){
            errorMessage('No assessment types found. Please create an assessment type and try again.');
        } else {
            typeOptions.add(0, new SelectOption('--None--', '--None--', true));
        }
    }

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

    private List<studentWrapper> sortStudents(List<studentWrapper> orig){
        if(orig.size() <= 1){
            return orig;
        }
        List<studentWrapper> left = new List<studentWrapper>();
        List<studentWrapper> right = new List<studentWrapper>();
        List<studentWrapper> result = new List<studentWrapper>();
        integer mid = orig.size()/2;

        for(integer i=0;i<mid;i++) {
            left.add(orig[i]);
        }
        for(integer i=mid;i<orig.size();i++) {
            right.add(orig[i]);
        }

        left = sortStudents(left);
        right = sortStudents(right);
        result = mergeSortStudents(left, right);
        left.clear();right.clear();//Added by Harsh Singh 3rd May 2016
        return result;
    }

    private List<studentWrapper> mergeSortStudents(List<studentWrapper> left, List<studentWrapper> right){
        List<studentWrapper> result = new List<studentWrapper>();
        while(left.size() > 0 || right.size() > 0){
            if(left.size() > 0 && right.size() > 0){
                if(left[0].student.Student_Last_Name__c < right[0].student.Student_Last_Name__c){
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

    private boolean extractData(){
        if(fileBlob == null){
            errorMessage('Please select a file.');
            return false;
        } else if(!fileName.toLowerCase().endsWith('.csv')){
            errorMessage('Error: The file type ' + fileContentType + ' is not supported. Please export assessments from the system before uploading.');
            return false;
        }
        String blobString = fileBlob.toString();
        fileBlob = null;
        inputWrapper.studentData = new CSVUtils.CSVParser(blobString.subString(blobString.indexOf('\n')+1), true);
        inputWrapper.studentData.parse();
        if(inputWrapper.studentData.parseError){
            errorMessage(inputWrapper.studentData.errorMessage);
            return false;
        }
        if(inputWrapper.studentData.parsedData.size() < 1){
            errorMessage('Error: Provided file is not properly formatted. Please export assessments from the system before uploading.');
            return false;
        }
      
        return true;
    }

    private boolean splitData(){
        integer numFields = inputWrapper.studentData.headers.size();
        boolean error = false;
        System.debug('maps'+assessmentLabelMap);
        string apiString = '';
        for(String s:inputWrapper.studentData.headers){
            if(assessmentLabelMap.containsKey(s)){
                string field = assessmentLabelMap.get(s);
                apiString = ',' + field;
                inputWrapper.displayLabels.add(new fieldWrapper(assessmentSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
                inputWrapper.apiList.add(assessmentLabelMap.get(s));
            } else {
                errorMessage('Error: Import failed. Field ' + s + ' was not found in the system. Please do not modify the field names.');
                return false;
            }
        }
        inputWrapper.fieldAPIs = apiString;
//logic to take only first 600 Ids fromt the Set
        for(integer i=0; i<inputWrapper.studentData.parsedData.size() && i<recordsCount ; i++){
            List<String> singleStudent = inputWrapper.studentData.parsedData[i];
            try{
                inputWrapper.assessmentIds.add(singleStudent[singleStudent.size()-1]);
            } catch (Exception e){
                errorMessage('Error: Import Failed. For student ' + singleStudent[singleStudent.size()-1] + ': Invalid id. Please do not edit the id fields.');
                error = true;
            }
        }
        List<Assesment__c> assessments = Assessment_SoqlUtils.getAssessmentById(inputWrapper.AssessmentIds, inputWrapper.fieldAPIs);
        if(assessments.size() != inputWrapper.assessmentIds.size()){
            errorMessage('Error: Import failed. ' + (inputWrapper.assessmentIDs.size()-assessments.size()) + ' ids were not found in the system. Pleaese do not change the ID field.');
            error = true;
        }
        studentMap = new Map<ID, String>();
        for(Assesment__c a:assessments){
            inputWrapper.assessmentMap.put(a.id, (sObject)a);
            if(a.Student__c != null){
                studentMap.put(a.id, a.Student__r.Student_Last_Name__c + ', ' + a.Student__r.Student_First_Name__c);
                pastMode = false;
            } else {
                pastMode = true;
            }
        }
        assessments.clear();//Added on 5th May 2016
        return !error;
    }

    private boolean parseStudentData(){
        Boolean success = false;
        Integer numOfFields = inputWrapper.fieldLabels.size() + inputWrapper.skipColumns;
        Integer skipColumns = inputWrapper.skipColumns;
        Integer startColumn = inputWrapper.skipColumns - 1;
        Schema.sObjectType assessmentToken = new Assesment__c().getSObjectType();
        Map<String, Schema.SObjectField> mapFields = assessmentToken.getDescribe().fields.getMap();

        Integer counter = 0;
        Integer theRecordLimit = Integer.valueOf(Label.AssessmentWizardImportProcessRecordsLimit);
        for(integer i=0; i<=inputWrapper.studentData.parsedData.size()-1 && i<recordsCount-1; i++){
            List<String> singleStudent = inputWrapper.studentData.parsedData[i];
            sobject s = inputWrapper.assessmentMap.get(singleStudent[singleStudent.size()-1]);

            for(integer j=startColumn; j<singleStudent.size()-1; j++){
                if(j==startColumn){
                    string field = ((isManagedPackage)?'SchoolForce__':'') + 'Student_Name__c';
                    s.put(field, singleStudent[startColumn]);
                    if(!pastMode){
                        if(studentMap.get((ID)s.get('ID')) != s.get(field)){
                            errorMessage('Error: For student ' + s.get(field) + ' the assessment result does not match the student name. Please do not reorder the students.');
                            success = false;
                        }
                    }
                } else {
                    string value = singleStudent[j];
                    string fieldAPI = assessmentLabelMap.get(inputWrapper.studentData.headers[j-skipColumns]);
                    if(fieldAPI == 'Date__c')
                        continue;
                    string fieldType = fieldTypeMap.get(fieldAPI);
                    integer fieldLength = fieldLengthMap.get(fieldAPI);
                    if(value.length() > fieldLength){
                        errorMessage('Error: For student ' + s.get('Student_Name__c') + ': ' + assessmentSystemLabels.get(fieldAPI) + ' has a maximum length of ' + fieldLength +'. Please check your data.');
                        success = false;
                        continue;
                    }
                    if(fieldType == 'BOOLEAN'){
                        value = value.toLowerCase();
                        Boolean bValue = (value == 'true' || value == 'yes' || value == 'y')? true: false;
                        s.put(fieldAPI, bValue);
                    } else if(fieldType == 'DOUBLE' || fieldType == 'PERCENT'){
                        try{
                            Double dValue = String.isNotEmpty(value)? Double.valueOf(value): null;
                            s.put(fieldAPI, dValue);
                        } catch (Exception e){
                            if(value != null && value != '') {
                            errorMessage(assessmentSystemLabels.get(fieldAPI) + ' is a number field. Please enter only numeric characters.');
                           }                           
                        }
                    } else if(fieldType == 'DATE'){
                        s.put(fieldAPI, null);
                        try{
                            s.put(fieldAPI, Date.parse(value));//checkDate=true;
                        } catch (System.Typeexception e){
                          //  callDateError='<script> dateValError(); </script>';inputWrapper.assessments.clear();return true;//added by harsh singh
                            errorMessage(assessmentSystemLabels.get(fieldAPI) + ' is a Date field. Please enter a valid date in the following format MM/DD/YYYY.');
                        }
                    } else if(fieldType == 'PICKLIST'){
                        Boolean isFound = false;
                        List<Schema.PicklistEntry> picklistValues = mapFields.containsKey(fieldAPI)? mapFields.get(fieldAPI).getDescribe().getPickListValues(): new List<Schema.PicklistEntry>();
                        for(Schema.PicklistEntry pe: picklistValues){
                            if(value == pe.value || value == pe.label){
                                s.put(fieldAPI, pe.value);
                                isFound = true;
                            }
                        }
                        if(!isFound && String.isNotBlank(value) ){
                            s.put(fieldAPI, null);
                            errorMessage('Import error: For student ' + s.get('Student_Name__c') + ': ' + assessmentSystemLabels.get(fieldAPI) + ' should has a valid value('+value+').');
                        }
                    }else {
                        s.put(fieldAPI, value);
                    }
                }
            }

            counter++;
            if(counter > theRecordLimit) {
                infoMessage('You are attempting to import more then ' + theRecordLimit + ' records at once. Only the first ' + theRecordLimit + ' records will be displayed below.');
                break;
            }
            inputWrapper.assessments.add(s);
            System.debug('@@@ s: '+s);
        }

        inputWrapper.assessmentMap.clear();
        assessmentToken=null;//added on 9th May 2016
        showDataPane = success? true: false;

        return success? true: false;
    }

    public Integer selRow {get;set;}
    public void removeAssessment(){
        System.debug('@@@ selRow: AAAAA');
        System.debug('@@@ selRow: '+selRow);
    }
    /* END HELPER METHODS */


    /* WRAPPER OBJECTS */
    public class fieldWrapper{
        public string apiName       {get;set;}
        public string labelName     {get;set;}
        public boolean selected     {get;set;}
        public string fieldType     {get;set;}
        private Integer fieldLength {get;set;}

        public fieldWrapper(string label, string api){
            selected = false;
            apiName = api;
            labelName = label;
        }

        public fieldWrapper(string label, string api, string field, integer length){
            this(label, api);
            fieldType = field;
            fieldLength = length;
        }
    }

    public class studentWrapper{
        public Student__c student   {get;set;}
        public boolean selected     {get;set;}
        public List<SelectOption> schools   {get;set;}
        public string school        {get;set;}
        public List<SelectOption> indicatorAreas   {get;set;}//Added for T-493156
        public string indicatorArea  {get;set;} //Added for T-493156
        Public String localId {get;set;} //Added for T-493156
        Public Boolean nullDateAdminister {get;set;}//Added for T-493159
        public studentWrapper(){
            student = new Student__c(Active__c = true);
            selected = false;
            Schools = new List<SelectOption>();
            school = '';
            indicatorAreas=new List<SelectOption>();
            indicatorArea='';
            nullDateAdminister=false;
            
        }

        private studentWrapper(Student__c stu){
            this();
            student = stu;
        }
    }

    public class sectionWrapper{
        public Section__c section   {get;set;}
        public Course__c course     {get;set;}
        public boolean selected     {get;set;}
        public List<SelectOption> rcdTypes   {get;set;}//Added for T-493158 
        public string rcdType  {get;set;} //Added for T-493158 
        
        
        private sectionWrapper(){
            section = new Section__c();
            course = new Course__c();
            selected = false;
            rcdTypes=new List<SelectOption>();
            rcdType='';//Code added for T-493158  by Harsh Singh start
            DescribeSObjectResult result = Schema.getGlobalDescribe().get('Section__C').getDescribe();
            Set<String> str=new Set<String>();
            Map<String,Schema.RecordTypeInfo> recordTypeInfos = result.getRecordTypeInfosByName();
            rcdTypes.add(new SelectOption('--None--', '--None--'));
            for(Schema.RecordTypeInfo rcdType : recordTypeInfos.values())
            {
            rcdTypes.add(new SelectOption(rcdType.getName(), rcdType.getName()) ); 
            }//Code added for T-493158  by Harsh Singh end
        }
        private sectionWrapper(Section__c sec){
            section = sec;
            course = new Course__c(Name = sec.Course__r.Name);
            selected = false;
        }
    }

    public class assessmentWrapper{
        public Assesment__c assessment  {get;set;}
        public Student__c student       {get;set;}

        private assessmentWrapper(Assesment__c a, Student__c stu){
            assessment = a;
            student = stu;
        }
    }

    public class dataWrapper{
        public String headerInfo                {get;set;}
        public List<fieldWrapper> displayLabels {get;set;}
        public List<String> fieldLabels         {get;set;}
        public String fieldAPIs                 {get;set;}
        public List<String> apiList             {get;set;}
        public List<sObject> assessments        {get;set;}
        public Set<Id> assessmentIDs;
        public Map<Id, sObject> assessmentMap;
        private CSVUtils.CSVParser studentData;
        public Integer skipColumns              {get;set;}

        public dataWrapper(){
             assessmentIDs = new Set<Id>();
             fieldLabels = new List<String>();
             assessmentMap = new Map<Id, sObject>();
             fieldAPIs = '';
             headerInfo = '';
             assessments = new List<sObject>();
             apiList = new List<String>();
             displayLabels = new List<fieldWrapper>();
             skipColumns = 0;
        }
    }
}