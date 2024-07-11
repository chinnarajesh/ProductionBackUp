public with sharing class SessionInterventionBulkUploadController {
    /* PAGE CONTROL */
    private Integer recordsCount {get;set;}

    public Boolean showDownloadTemplate {get; set;}
    public Boolean showImportSessionsButton {get; set;}
    public Boolean showCreatedSessions {get; set;}
    public Boolean showUpdatedSessions {get; set;}
    public Boolean showISRImportSection {get; set;}
    public Boolean showMainPanel {get; set;}
    public Boolean showSessionsImportSection {get; set;}
    public Boolean showImportSection {get; set;}
    public string staffName ;
    public String selectStudentParam{get;set;}
    public string conditionParam  {get;set;}
    public string Unselectedsstudents {get;set;}

    ///////////
    public SelectOption[] selectedAllStaff { get; set; }
    public SelectOption[] selectedSections { get; set; }
    public SelectOption[] allSections { get; set; }
    public Boolean openMultipicklist {set;get;}
    public Boolean checkcondition=false;

    public SelectOption[] leftOptions { get; set; }
    public SelectOption[] rightOptions { get; set; }
    public SelectOption[] AllDataTo { get; set; }
    public Set<Id> multiSelectStaffIdSet {set;get;}
    public Set<string> MultltiselectSectionIdSet ;
    public set<string> SectionIdSetDuplicate {set;get;}
    ///////////

    //General
    private String profileName;
    private String userType;
    private Map<ID, Section__c> sectionMap;
    private List<Student_Section__c> studentSections;
    private Map<String, Student__c> studentIdtoStudentMap;
    private static List<String> otherSkills;
    public Boolean tooManyStudentsError;

    private Map<String, String> intSessionResultAPIMap;
    private Map<String, String> intSessionResultLabelMap;
    private Map<String, String> intSessionResultSystemLabels;
    private Map<String, String> fieldTypeMap;
    private Map<String, Integer> fieldLengthMap;

    //Filter Holders
    public List<SelectOption> schools	{get;set;}
    public List<SelectOption> staff		{get;set;}
    public List<SelectOption> sections	{get;set;}
    public String selectedSchool		{get;set;}
    public String selectedStaff			{get;set;}
    public String selectedSection		{get;set;}

    public List<SessionResultsWrapper> resultsData		{get;set;}
    public List<SessionResultsWrapper> checkedData		{get;set;}
    public Section__c currentSection					{get;set;}

    /* IMPORT CONTAINERS */
    public String fileContentType       {get;set;}
    public String fileSize              {get;set;}
    public Transient Blob fileBlob      {get;set;}
    public dataWrapper inputWrapper     {get;set;}
    public List<Intervention_Session__c> createdSessions {get; set;}

    /* EXPORT CONTAINERS */
    public  List<ISRWrapper> newISRs   {get;set;}
    public  List<SessionWrapper> newSessions   {get;set;}
    public String fileName              {get;set;}
    transient public string csvData     {get;set;}

    public SessionInterventionBulkUploadController(){
        intSessionResultAPIMap = new Map<String, String>();
        intSessionResultLabelMap =  new Map<String, String>();
        studentIdToStudentMap = new Map<String, Student__c>();
        selectedSections = new List<SelectOption>();
        selectedAllStaff = new List<SelectOption>();
        SectionIdSetDuplicate = new Set<string>();
        sections = new List<SelectOption>();

        showDownloadTemplate = false;
        showCreatedSessions = false;
        showUpdatedSessions = false;
        showISRImportSection = true;
        showMainPanel = false;
        showSessionsImportSection = true;
        showImportSection = false;
        tooManyStudentsError = false;
        openMultipicklist=true;
        checkcondition=false;

        determineUserType();
        if(userType != null){
            loadSchools();
        }

        try{
            recordsCount = 1000;
            if(ApexPages.currentPage().getParameters().get('goodimport') != null){
                infoMessage('The data was imported successfully.');
            }
        } catch (Exception e){
            errorMessage('Error during load. Please contact your system administrator.');
        }
    }
      ///////////////
      private void setOptions(SelectOption[] options, String value) {
        options.clear();
        String[] parts = value.split('&');
        for (Integer i=0; i<parts.size()/2; i++) {
            options.add(new SelectOption(EncodingUtil.urlDecode(parts[i*2], 'UTF-8'), 
              EncodingUtil.urlDecode(parts[(i*2)+1], 'UTF-8')));
        }
    }
    // Backing for hidden text field containing the options from the
    // left list
    public String leftOptionsHidden { get; set {
            leftOptionsHidden = value;
            setOptions(leftOptions, value);
        }
    }
    // Backing for hidden text field containing the options from the
    // right list
    public String rightOptionsHidden { get; set {
           rightOptionsHidden = value;
           setOptions(rightOptions, value);
        }
        
    }
      ///////////////
    private void determineUserType(){
        profileName = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
        Map<String,SharingControls__c> controls = SharingControls__c.getAll();

        if(controls == null){
            CYUtil.errorMessage('Sharing controls are not set.  Please verify that the Sharing Controls custom setting is populated and try again.');
            return;
        }

        if(controls.containsKey('CM') && profileName.contains(controls.get('CM').Profile_Name__c)){
            userType = 'Corps';
        } else if(controls.containsKey('SA') && profileName.contains(controls.get('SA').Profile_Name__c)){
            userType = 'School';
        }else if(controls.containsKey('Site') && profileName.contains(controls.get('Site').Profile_Name__c)){
            userType = 'Site';
        } else {
            userType = 'System';
        }
    }

    private void loadSchools(){
        schools = new List<SelectOption>();
        ID AccountRTID = CYUtil.getRecordTypeID('School');
        String query = 'SELECT Id, Name FROM Account WHERE RecordTypeId=: AccountRTID ';
        Set<ID> schoolsToQuery = new Set<ID>();
        if(userType == 'Corps' || userType == 'School'){
            ID userID = UserInfo.getUserId();
            List<Staff__c> staffRecords = [select Organization__c FROM Staff__c WHERE Individual__r.User__c=:userID AND Active__c=true];
            for(Staff__c s:staffRecords){
                schoolsToQuery.add(s.Organization__c);
            }
            query += 'AND Id IN: schoolsToQuery ';
        } else if(userType == 'Site'){
            List<String> lstLocations = new List<String>();
            for(UserTerritory2Association ut2a: [SELECT Id, Territory2.Name, Territory2.Territory2Model.Name
            FROM UserTerritory2Association
            WHERE UserId = :Userinfo.getUserId()]){
                lstLocations.add(ut2a.Territory2.Name);
            }
            query += 'AND Site__c IN (\''+String.join(lstLocations, '\',\'')+'\')';
        }
        query += ' ORDER BY Name ASC';
        for(Account a:Database.query(query)){
            schools.add(new SelectOption(a.ID, a.Name));
        }
        if(schools.isEmpty()){
            CYUtil.errorMessage('No schools were found for your user.');
        } else {
            if(schools.size()>1){
                selectedSchool = 'none';
                schools.add(0, new SelectOption('none','Select School'));
            } else {
                selectedSchool = schools[0].getValue();
            }
        }
        changeSchool();
    }
    public void changeSchool(){
        staff = new List<SelectOption>();
        if(String.isBlank(selectedSchool)){
            return;
        } else{
            loadStaff();
        }
    }

    public void changeStaff(){
        //sections = new List<SelectOption>();
        if(!String.isBlank(selectedStaff)){
            //loadSections();
        }
    }
    public void listOfselectedSections(){
        //System.debug('selectedSections '+selectedSections);
        resultsData = new List<SessionResultsWrapper>();
        checkedData = new List<SessionResultsWrapper>();
        MultltiselectSectionIdSet = new Set<string>();

            SectionIdSetDuplicate = new Set<string>();
        
        for ( SelectOption so : selectedSections ) {
            MultltiselectSectionIdSet.add(so.getValue());
            SectionIdSetDuplicate.add(so.getValue());
         }
        if(selectedSections.size()>0 && !selectedSections.isEmpty()){
            if (!showMainPanel) {
                showMainPanel = true;
            }
            //currentSection = sectionMap.get(selectedSection);
            loadStudentSections();
            populateResultsData();
            showImportSection = true;

        } else {
            showMainPanel = false;
            showImportSection = false;
        }
    }
    
   // public void changeSection(){
        // resultsData = new List<SessionResultsWrapper>();
        // checkedData = new List<SessionResultsWrapper>();
        // MultltiselectSectionIdSet = new Set<id>();

        // for ( SelectOption so : selectedSections ) {
        //     MultltiselectSectionIdSet.add(so.getValue());
        //     System.debug('selected sections++'+so.getValue());
        //  }
        //  System.debug('MultltiselectSectionIdSet '+MultltiselectSectionIdSet);

        // if(selectedSections.size()>0 && !selectedSections.isEmpty()){
        //     if (!showMainPanel) {
        //         showMainPanel = true;
        //     }
        //     currentSection = sectionMap.get(selectedSection);
        //     loadStudentSections();
        //     populateResultsData();
        //     showImportSection = true;

        // } else {
        //     showMainPanel = false;
        //     showImportSection = false;
        // }
    // }

    private void loadStaff(){
        if(selectedSchool != 'none'){
            for(Staff__c s : getStaffAtSchool(selectedSchool)){
                staff.add(new SelectOption(s.id, s.Name));
            }
        }

        if(selectedSchool == 'none'){
            //staff.add(new SelectOption('none', 'Select Staff Member'));
            selectedStaff = 'none';
        } else if(staff.size() > 1){
            //staff.add(0, new SelectOption('none', 'Select Staff Member'));
            selectedStaff = 'none';
        } else if(staff.size() == 1){
            selectedStaff = staff[0].getValue();
        }
        changeStaff();
    }

    public void loadSections(){ 
        multiSelectStaffIdSet = new Set<Id>();
        sections = new List<SelectOption>();
        System.debug('selectedAllStaff '+selectedAllStaff);
        for ( SelectOption so : selectedAllStaff ) {
                multiSelectStaffIdSet.add(so.getValue());
         }
        
        if(selectedAllStaff.size()>0 && !selectedAllStaff.isEmpty()){
            allSections = new List<SelectOption>();

            sectionMap = new Map<ID, Section__c>();
            for(Staff_Section__c ss : getStaffSectionsForStaff(multiSelectStaffIdSet)) {
                staffName=ss.Staff__r.name;
                List<Student_Section__c> studentsection = [select id,name from Student_Section__c where Section__c =: ss.Section__r.ID];
                if(!studentsection.isEmpty() && !SectionIdSetDuplicate.contains(ss.Section__r.ID)){
                    sections.add(new SelectOption(ss.Section__r.ID, ss.Section__r.Name));
                 }
                 sectionMap.put(ss.Section__r.ID, ss.Section__r);
            }
        }

        if(selectedStaff == 'none'){
            selectedSection = 'none';
            //sections.add(new SelectOption('none', 'Select Section'));
        } else if(staff.size()>1){
            selectedSection = 'none';
            if(sections.isEmpty()){
                //sections.add(new SelectOption('none', 'Select Section'));
            }else{
                //sections.add(0,new SelectOption('none', 'Select Section'));
            }
        } else if(sections.size() == 1){
            selectedSection = sections[0].getValue();
        }
        //changeSection();
    }

    private void loadStudentSections(){
        studentSections = [select id, Student_Name__c, Student__c,
                            Student__r.Local_Student_ID__c, Student__r.Student_Id__c,Section__r.name,Student__r.Legacy_Id__c
                            from Student_Section__c
                            where Active__c = true
                            and Student__r.Active__c = true
                            and Section__c =: MultltiselectSectionIdSet
                            order by Student_Name__c, Student__c];
    }

    private List<Staff__c> getStaffAtSchool(ID schoolID){
        String query =
                'select id, Name from Staff__c'+
                        ' where Active__c = true'+
                        ' and Organization__c =: schoolID';

        SharingControls__c sc = SharingControls__c.getInstance('CM');
        if(sc != null && profileName.contains(sc.Profile_Name__c)){
            query+=' AND Individual__r.User__c =\''+Userinfo.getUserId()+'\'';
        } else {
            query+=' AND Id IN (Select Staff__c'+
                    +' FROM Staff_Section__c'
                    +' WHERE Is_Active__c=true)';
        }

        query+=' order by Staff_Last_Name__c, First_Name_Staff__c';
        return Database.query(query);
    }

    private List<Staff_Section__c> getStaffSectionsForStaff(Set<ID> staffID){
        return [SELECT Section__c, Section__r.Name, Section__r.Account_Program__r.Name,
                        Section__r.End_Date__c, Section__r.Start_Date__c,
                        Section__r.Intervention_Primary_Staff__c,Staff__r.name
                FROM Staff_Section__c
                WHERE Is_Active__c = true
                AND Section__r.Active__c = true
                AND Section__r.SkipDosage__c = false
                AND Section__r.RecordType.Name = 'Intervention Section'
                AND Staff__c =: staffID
                ORDER BY Section__r.Name];
    }

    private void populateResultsData() {
        Map<Id,Staff_Section__c> staffMap= new Map<Id,Staff_Section__c>();
        for(Staff_Section__c staffsection : [select id,name,Section__c,Staff__r.name from Staff_Section__c where Staff__c IN: multiSelectStaffIdSet]){
            staffMap.put(staffsection.Section__c,staffsection);
        }
        for(Student_Section__c ss: studentSections){
            string staffName =staffMap.get(ss.Section__c).Staff__r.name;
            ID studentID = ss.Student__c;
            resultsData.add(new SessionResultsWrapper(ss.Section__r.name,staffName,ss.Student_Name__c,ss.Student__c,ss.ID, ss.Student__r.Local_Student_ID__c, ss.Student__r.Student_Id__c,ss.Student__r.Legacy_Id__c));
        }
        System.debug('resultsData '+resultsData);
    }

    public void toggleSortDirection(){
        List<SessionResultsWrapper> holder = new List<SessionResultsWrapper>();
        for(Integer i=resultsData.size()-1;i>=0;i--){
            holder.add(resultsData[i]);
        }
        resultsData = holder;
    }

    public PageReference resetPage(){
        PageReference returnPage = Page.SessionInterventionBulkUpload;
        returnPage.setRedirect(true);
        return returnPage;
    }
    public void checkAndUncheckAllstudents(){
        system.debug('conditionParam'+conditionParam);
        for(SessionResultsWrapper wrap : resultsData) {
            if(conditionParam =='true'){
                wrap.isChecked=true;
            }else if(conditionParam =='false') {
                wrap.isChecked=false;
            }
        }
    }

    public void confirmSelectedStudents(){
        List<SessionResultsWrapper> selectedStudents = new List<SessionResultsWrapper>();
        Set<string> selIds = new Set<string>();
        set<string> unselectedIdSet = new set<string>();
        if(String.isNotBlank(selectStudentParam)){
            List<String> ids = selectStudentParam.split(';');
            for(String i : ids){
                selIds.add(i.trim());
            }
        }
        if(String.isNotBlank(Unselectedsstudents)){
            List<String> ids = Unselectedsstudents.split(';');
            for(String i : ids){
                unselectedIdSet.add(i.trim());
            }
        }
        if(conditionParam =='true'){
            for(SessionResultsWrapper wrap : resultsData) {
                if(conditionParam =='true'){
                    wrap.isChecked=true;
             }
           }
        }
        for(SessionResultsWrapper wrap : resultsData) {
            if(unselectedIdSet.contains(wrap.studentId+'-'+wrap.sectionName)){
                wrap.isChecked=false;
            }
        }
        for(SessionResultsWrapper wrap : resultsData) {
            if(selIds.contains(wrap.studentId+'-'+wrap.sectionName)){
                wrap.isChecked=true;
            }
        }
        for(SessionResultsWrapper wrap : resultsData) {
            if( wrap.isChecked==true) {
                selectedStudents.add(wrap);
            }
        }
        if (selectedStudents.size() > 0) {
            checkedData = selectedStudents;
            showDownloadTemplate = true;
        } else {
            errorMessage('Please, select some students.');
        }

    }

    public void prepareStudentsTemplate(){
        newISRs = new List<ISRWrapper>();
        Set<Id> studentsIds = new Set<Id>();
        for(SessionResultsWrapper sessionResultWrapper : checkedData) {
            studentsIds.add(sessionResultWrapper.studentId);
        }
        Map<Id, Student__c> selectedStudents = new Map<Id, Student__c>([
                SELECT Id, Legacy_Id__c, Student_Id__c, Student_Last_Name__c, Student_First_Name__c
                FROM Student__c
                WHERE Id IN :studentsIds
        ]);
        for(SessionResultsWrapper sessionResult : checkedData) {
            newISRs.add(new ISRWrapper(selectedStudents.get(sessionResult.studentId)));
        }
        for(Student__c stud : selectedStudents.values()) {
            studentIdtoStudentMap.put(stud.Student_Id__c, stud);
        }
    }

    public PageReference saveForExport(){
        prepareStudentsTemplate();
        generateStudentsCSV();
        return Page.SessionInterventionBulkUploadExport;
    }
    //////added by juturi/////
    public PageReference DownloadBlankTemplate(){
        BlankgenerateStudentsCSV();
        return Page.SessionInterventionBulkUploadExport;
    }
    private void BlankgenerateStudentsCSV(){
        String genDate = System.Today().month() + '-' + System.Today().day() + '-' + System.Today().year();
        fileName = 'InterventionSession_' + genDate;
        List<String> allRows = new List<String>();
        allRows.add('Intervention Session ,Generated ' + genDate);
        allRows.add('Student Internal Id, Student USID, *REQ* Student Id, *REQ* Intervention Section Name, *REQ* Session Time Completed For, *REQ* Date, *REQ* Amount of Time (in minutes) (Amount_of_Time__c), Exit Ticket (Exit_Ticket__c),Add\'l Comments for Session (Comments__c), Primary Skill (Skill_Primary__c), Other Skills (Skills_Covered_for_the_Session__c), Site Details (Site_Details__c), Session Type (Session_Type__c), Session Format (Session_Format__c)');
        csvData = String.join(allRows,'\n');
        allRows.clear();
    }

    ////// ended by juturi /////
    public void prepareSessionsTemplate(){
        newSessions = new List<SessionWrapper>();
        for(Intervention_Session__c session : createdSessions) {
            newSessions.add(new SessionWrapper(session));
        }
    }

    public void saveSessionsForExport(){
        showImportSessionsButton = true;
    }

    public PageReference exportSessionTemplate(){
        prepareSessionsTemplate();
        generateSessionsCSV();
        return Page.SessionInterventionBulkUploadExport;
    }

    private void generateStudentsCSV(){
        String genDate = System.Today().month() + '-' + System.Today().day() + '-' + System.Today().year();
        fileName = 'InterventionSessionResults_' + genDate;
        List<String> allRows = new List<String>();
        allRows.add('Intervention Session Results,Generated ' + genDate);
        allRows.add('Student Internal Id, Student USID, *REQ* Student Id, *REQ* Intervention Section Name, *REQ* Session Time Completed For, *REQ* Date, *REQ* Amount of Time (in minutes) (Amount_of_Time__c), Exit Ticket (Exit_Ticket__c),Add\'l Comments for Session (Comments__c), Primary Skill (Skill_Primary__c), Other Skills (Skills_Covered_for_the_Session__c), Site Details (Site_Details__c), Session Type (Session_Type__c), Session Format (Session_Format__c)');
        for(SessionResultsWrapper sessionResult : checkedData) {
            List<String> dataRow = new List<String>();
            dataRow.add(sessionResult.studentID+',');
            dataRow.add(sessionResult.legacyId+',');
            dataRow.add(sessionResult.studentCYId+',');
            dataRow.add(sessionResult.sectionName+',');
            dataRow.add(sessionResult.staffName+',');
            //dataRow.add('"' + isr.student.Student_Last_Name__c + ', ' + isr.student.Student_First_Name__c + '",');
            allRows.add(String.join(dataRow,''));
        }
        // for(ISRWrapper isr: newISRs){
        //     List<String> dataRow = new List<String>();
        //     string sectionName = studentsectionMap.get(isr.student.Id).Section__r.name;
        //     dataRow.add(isr.student.Id+',');
        //     dataRow.add(isr.student.Legacy_Id__c+',');
        //     dataRow.add(isr.student.Student_Id__c+',');
        //     dataRow.add(sectionName+',');
        //     dataRow.add(staffName+',');
        //     //dataRow.add('"' + isr.student.Student_Last_Name__c + ', ' + isr.student.Student_First_Name__c + '",');
        //     allRows.add(String.join(dataRow,''));
        // }
        csvData = String.join(allRows,'\n');
        allRows.clear();
    }

    private void generateSessionsCSV(){
        String genDate = System.Today().month() + '-' + System.Today().day() + '-' + System.Today().year();
        fileName = 'InterventionSessions_' + genDate;
        List<String> allRows = new List<String>();
        allRows.add('Intervention Sessions,Generated ' + genDate);
        allRows.add('Session Internal ID, Session ID, Date, Add\'l Comments for Session (Comments__c), *REQ* In-Person Service or Virtual Service (All_avenues__c), Primary Skill (Skill_Primary__c), Other Skills (Skills_Covered_for_the_Session__c), Site Details (Site_Details__c), Session Type (Session_Type__c), Session Format (Session_Format__c)');
        for(SessionWrapper sessionWrapper: newSessions){
            List<String> dataRow = new List<String>();
            dataRow.add(sessionWrapper.session.Id+',');
            dataRow.add(sessionWrapper.session.Name+',');
            dataRow.add(sessionWrapper.session.Date__c+',');
            allRows.add(String.join(dataRow,''));
        }
        csvData = String.join(allRows,'\n');
        allRows.clear();
    }

    public pageReference startImport(){
        return Page.SessionInterventionBulkUploadImport;
    }
    public pageReference homePageButton(){
        PageReference pageRef = new PageReference('/apex/SessionInterventionBulkUploadImport');
        pageRef.setRedirect(true);
        return pageRef;
    }

    public PageReference startSessionImport(){
        PageReference pageRef = new PageReference('/apex/SessionInterventionBulkUploadImportSess');
        pageRef.setRedirect(true);
        return pageRef;
    }

    public void processInput(){
        inputWrapper = new dataWrapper();
        boolean success = false;
        success = extractData('student');
        if(!success){
            return;
        }
    //     inputWrapper.skipColumns = 4;
    //     inputWrapper.isrData.headers.remove(0);
    //     inputWrapper.isrData.headers.remove(0);
    //     inputWrapper.isrData.headers.remove(0);
    //     inputWrapper.isrData.headers.remove(0);
    //     inputWrapper.isrData.headers.remove(inputWrapper.isrData.headers.size()-1);
    //     List <String> msgErrors = splitStudentsData();
    //     if (tooManyStudentsError) {
    //         CYUtil.infoMessage('You are trying to import too many students. Only first 1000 will be imported.');
    //     }
    //     if(!msgErrors.isEmpty()){
    //         for(String errorMsg : msgErrors) {
    //             CYUtil.errorMessage(errorMsg);
    //         }
    //     } else {
    //         // CYUtil.successMessage('Please, download a template for Intervention Sessions and add some information to it. Then upload a file again.');
    //         // displayCreatedSessions();
    //         CYUtil.successMessage('Intervention Sessions and Intervention Sessions Results Created with new values from the template.');
    //         displayUpdatedSessions();
    //     }
    // } 
        inputWrapper.skipColumns = 5;
        inputWrapper.isrData.headers.remove(0);
        inputWrapper.isrData.headers.remove(0);
        inputWrapper.isrData.headers.remove(0);
        inputWrapper.isrData.headers.remove(0);
        inputWrapper.isrData.headers.remove(0);
        inputWrapper.isrData.headers.remove(inputWrapper.isrData.headers.size()-1);
        List <String> msgErrors = splitStudentsDataWithBlankTemplateValues();
        if (tooManyStudentsError) {
            CYUtil.infoMessage('You are trying to import too many students. Only first 1000 will be imported.');
        }
        if(!msgErrors.isEmpty()){
            for(String errorMsg : msgErrors) {
                CYUtil.errorMessage(errorMsg);
            }
        } else {
            CYUtil.successMessage('Intervention Sessions and Intervention Sessions Results Created with new values from the template.');
            displayUpdatedSessions();
        }
    }

    public void processSessionsInput(){
        inputWrapper = new dataWrapper();
        boolean success = false;
        success = extractData('session');
        if(!success){
            return;
        }
        inputWrapper.skipColumns = 3;
        inputWrapper.isrData.headers.remove(0);
        inputWrapper.isrData.headers.remove(0);
        inputWrapper.isrData.headers.remove(0);
        inputWrapper.isrData.headers.remove(inputWrapper.isrData.headers.size()-1);
        List<String> msgErrors = splitSessionsData();
        if(!msgErrors.isEmpty()){
            for(String errorMsg : msgErrors) {
                CYUtil.errorMessage(errorMsg);
            }
        } else {
            CYUtil.successMessage('Intervention Sessions are updated with new values from the template.');
            displayUpdatedSessions();
        }
    }

    private boolean extractData(String exportEntityName){
        if(fileBlob == null){
            errorMessage('Please select a file.');
            return false;
        } else if(!fileName.toLowerCase().endsWith('.csv')){
            errorMessage('Error: The file type ' + fileContentType + ' is not supported. Please export ' + exportEntityName + 's from the system before uploading.');
            return false;
        }
        String blobString = fileBlob.toString();
        fileBlob = null;
        inputWrapper.isrData = new CSVUtils.CSVParser(blobString.subString(blobString.indexOf('\n')+1), true);
        inputWrapper.isrData.parse();
        if(inputWrapper.isrData.parseError){
            errorMessage(inputWrapper.isrData.errorMessage);
            return false;
        }
        if(inputWrapper.isrData.parsedData.size() < 1){
            errorMessage('Error: Provided file is not properly formatted. Please export ' + exportEntityName + 's from the system before uploading.');
            return false;
        }

        return true;
    }

    // private List<String> splitStudentsData(){
    //     List<String> msgErrors = new List<String>();
    //     this.createObjectFieldSet('student');
    //     this.createObjectFieldSet('session');
    //     Map<String, Id> skillNameToIdMap = new Map<String, Id>();
    //     integer numFields = inputWrapper.isrData.headers.size();
    //     string apiString = '';
    //     for(String s: inputWrapper.isrData.headers){
    //         s = s.replace('*REQ* ', '');
    //         if(intSessionResultLabelMap.containsKey(s)){
    //             string field = intSessionResultLabelMap.get(s);
    //             apiString = ',' + field;
    //             inputWrapper.displayLabels.add(new fieldWrapper(intSessionResultSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
    //             inputWrapper.apiList.add(intSessionResultLabelMap.get(s));
    //         } else if (s == 'Date'){
    //         }
    //         else if(s != 'Primary Skill (Skill_Primary__c)' && intSessionResultLabelMap.containsKey(s)){
    //             String field = intSessionResultLabelMap.get(s);
    //             apiString = ',' + field;
    //             inputWrapper.displayLabels.add(new fieldWrapper(intSessionResultSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
    //             inputWrapper.apiList.add(intSessionResultLabelMap.get(s));
    //         } else if (s == 'Primary Skill (Skill_Primary__c)'){

    //         }
    //         // else if (s == 'In-Person Service or Virtual Service (All_avenues__c)') {
    //         //     String originValue = 'All avenues (All_avenues__c)';
    //         //     String field = intSessionResultLabelMap.get(originValue);
    //         //     apiString = ',' + field;
    //         //     inputWrapper.displayLabels.add(new fieldWrapper(intSessionResultSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
    //         //     inputWrapper.apiList.add(intSessionResultLabelMap.get(originValue));
    //         // }
    //          else {
    //             msgErrors.add('Error: Import failed. Field ' + s + ' was not found in the system. Please do not modify the field names.');
    //         }
    //     }
    //     inputWrapper.fieldAPIs = apiString;
    //     if (inputWrapper.isrData.parsedData.size() > 1000) {
    //         tooManyStudentsError = true;
    //     }
    //     System.debug('msgErrors ' + msgErrors.size());
    //     List<Intervention_Session_Result__c> isrs = new List<Intervention_Session_Result__c>();
    //     Set<Date> dates = new Set<Date>();
    //     Map<Id, Id> studentToStudentSectionIds = new Map<Id, Id>();
    //     Set<Id> uploadedStudents = new Set<Id>();
    //     for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
    //         List<String> isrFieldValues = inputWrapper.isrData.parsedData[i];
    //         try{
    //             inputWrapper.isrIDs.add(isrFieldValues[0]);
    //         } catch (Exception e){
    //             msgErrors.add('Error on a Student: ' + isrFieldValues[2] + ' - ' + isrFieldValues[3] +  '. Invalid Id - ' + isrFieldValues[0] + '. Please do not edit the Id fields.');
    //         }
    //         try{
    //             if (isrFieldValues[4] == '') {
    //                 msgErrors.add('Error on a Student: '+isrFieldValues[2]+ ' - ' + isrFieldValues[3] +'. Empty date. Please enter a valid date in the following format MM/DD/YYYY. ');
    //             } else {
    //                 dates.add(Date.parse(isrFieldValues[4]));
    //             }
    //             if (isrFieldValues.size() < 6 || isrFieldValues[5] == '') {
    //                 msgErrors.add('Error on a Student: '+isrFieldValues[2]+ ' - ' + isrFieldValues[3] +'. Empty Amount Of Time. Please enter a valid value.');
    //             } else {
    //                 try{
    //                     Decimal.valueOf(isrFieldValues[5]);
    //                 } catch (Exception e){
    //                     msgErrors.add('Error on a Student: '+isrFieldValues[2]+ ' - ' + isrFieldValues[3] +'. Invalid Amount of Time. Please, enter a Decimal value.');
    //                 }
    //             }
    //         } catch (System.TypeException e){
    //             msgErrors.add('Error on a Student: '+isrFieldValues[2]+ ' - ' + isrFieldValues[3] +'. Invalid date : ' + isrFieldValues[4] +
    //                     '. Please enter a valid date in the following format MM/DD/YYYY. ');
    //         }
    //         try{
    //             uploadedStudents.add(isrFieldValues[0]);
    //         } catch (Exception e){
    //         }
    //         if (msgErrors.size() > 900) {
    //             msgErrors.add('Too many errors. Only first 900 are displayed.');
    //             return msgErrors;
    //         }
    //     }
    //     /////////Added by juturi rajesh///////
    //     Set<String> skillNames = new Set<String>();
    //     for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
    //         List<String> singleSession = inputWrapper.isrData.parsedData[i];
    //         try{
    //             skillNames.add(singleSession[9]);
    //         } catch (Exception e) {
    //         }
    //     }
    //     skillNameToIdMap = getSkillsMap(skillNames);
    //     for (List<String> isrFieldValues : inputWrapper.isrData.parsedData) {
    //         Integer fieldsNumber = isrFieldValues.size();
    //         if (fieldsNumber > 10 && !skillNameToIdMap.containsKey(isrFieldValues[9])) {
    //             msgErrors.add('Error: Import failed. Primary Skill ' + isrFieldValues[9] + ' doesn\'t exist for Session ' + isrFieldValues[1]);
    //         } else if ((isrFieldValues[0] instanceOf Id) && fieldsNumber >= 10 && skillNameToIdMap.containsKey(isrFieldValues[9])){
    //             if (fieldsNumber >= 11) {
    //                 if (isrFieldValues[10].contains(isrFieldValues[9])) {
    //                     msgErrors.add('Invalid Other Skills for Session ' + isrFieldValues[1] + '. Other Skills should not duplicate Primary Skills.');
    //                 }
    //                 List<String> otherSkillsParsed = isrFieldValues[10].split(';');
    //                 for (String skill : otherSkillsParsed) {
    //                     if (!otherSkills.contains(skill) && skill != '') {
    //                         msgErrors.add('Invalid Other Skill for Session ' + isrFieldValues[1] + ' - ' + skill + '.');
    //                     }
    //                 }
    //             }
    //             if (isrFieldValues[8] == 'In-Person Service' || isrFieldValues[8] == 'Virtual Service') {
    //                 //sessions.add(generateInterventionSessionFromWrapper(isrFieldValues,skillNameToIdMap));
    //             } else {
    //                 msgErrors.add('Invalid All avenues value for Session ' + isrFieldValues[1] + '. It should be either In-Person Service or Virtual Service');
    //             }
    //         }
    //         if (fieldsNumber < 11) {
    //             msgErrors.add('Please, verify that ALL fields have been set for Session ' + isrFieldValues[1] + ' : All avenues, Primary Skill, Other Skills.');
    //         }
    //     }
    //     ////////ended by juturi rajesh ////////
    //     if (!msgErrors.isEmpty()) {
    //         return msgErrors;
    //     }
    //     List<Student_Section__c> relatedStudentSections = [SELECT Id, Student__c FROM Student_Section__c WHERE Section__c = :selectedSection];
    //     for(Student_Section__c studentSection : relatedStudentSections) {
    //         studentToStudentSectionIds.put(studentSection.Student__c, studentSection.Id);
    //     }
    //     List<Intervention_Session__c> sessions = new List<Intervention_Session__c>();
    //     Map<string, Intervention_Session__c> dateToSessionMap = new Map<string, Intervention_Session__c>();
    //     // for(Date sessionDate :dates) {
    //     //     sessions.add(new Intervention_Session__c(
    //     //             Date__c = sessionDate,
    //     //             All_avenues__c = 'In-Person Service',
    //     //             Section__c = selectedSection,
    //     //             Session_Time_Completed_For__c = selectedStaff
    //     //     ));
    //     // }
    //     /////////////added juturi rajesh/////////////
    //     Set<String> datavalues = new Set<String>();
    //     Map<string,string> avoideTheduplicatestudents = new Map<string,string>();

    //     for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
    //         List<String> isrFieldValues = inputWrapper.isrData.parsedData[i];
    //         Integer listSize = isrFieldValues.size();
    //         Date sessionDate2;
    //         String setvalue =isrFieldValues[4]+isrFieldValues[8]+isrFieldValues[9]+isrFieldValues[10]+isrFieldValues[11]+isrFieldValues[12]+isrFieldValues[13];
    //        // System.debug('setvalue++'+setvalue);
    //         sessionDate2 = Date.parse(isrFieldValues[4]);
    //         if(!datavalues.contains(setvalue)){
    //         sessions.add(new Intervention_Session__c(
    //                 Date__c = sessionDate2,
    //                 Section__c = selectedSection,
    //                 Session_Time_Completed_For__c = selectedStaff,
    //                 Comments__c = isrFieldValues[7],
    //                 All_avenues__c = isrFieldValues[8],
    //                 Skill_Primary__c = skillNameToIdMap.get(isrFieldValues[9]),
    //                 Skills_Covered_for_the_Session__c = listSize >= 11 ? isrFieldValues[10] : '',
    //                 Site_Details__c = listSize >= 12 ? isrFieldValues[11] : '',
    //                 Session_Type__c = listSize >= 13 ? isrFieldValues[12] : '',
    //                 Session_Format__c = listSize >= 14 ? isrFieldValues[13] : ''
    //         ));
    //         datavalues.add(isrFieldValues[4]+isrFieldValues[8]+isrFieldValues[9]+isrFieldValues[10]+isrFieldValues[11]+isrFieldValues[12]+isrFieldValues[13]);
    //         }
    //     }
    //     //System.debug('datavalues++'+datavalues);
    //     /////////////ended juturi rajesh////////////
    //     try {
    //         insert sessions;
    //     } catch (Exception e) {
    //         msgErrors.add(e.getMessage());
    //     }
    //     if (!msgErrors.isEmpty()) {
    //         return msgErrors;
    //     }
    //     Set<Id> skillPrimaryIds = new Set<Id>();
    //     for (Intervention_Session__c session : sessions) {
    //         skillPrimaryIds.add(session.Skill_Primary__c);
    //     }
    //     Map<Id, Skill__c> skillMap = new Map<Id, Skill__c>([SELECT Id, Name FROM Skill__c WHERE Id IN :skillPrimaryIds]);
        
    //     for(Intervention_Session__c session : sessions) {
    //         Date dToday = session.Date__c;
    //         String dateStr = dToday.month()+ '/' + dToday.day()+ '/' + dToday.year() ;
    //         Skill__c skill = skillMap.get(session.Skill_Primary__c);
    //         String skillName = (skill != null) ? skill.Name : '';
    //         String comparevalue=dateStr+'#'+session.All_avenues__c+'#'+skillName+'#'+session.Skills_Covered_for_the_Session__c+'#'+session.Site_Details__c+'#'+session.Session_Type__c+'#'+session.Session_Format__c;
    //         comparevalue=comparevalue.deleteWhitespace();
    //         dateToSessionMap.put(comparevalue, session);
    //     }
    //     //System.debug('dateToSessionMap++'+dateToSessionMap);
    //     ///////
    //     Decimal totalAmount;
    //     for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
    //         List<String> isrFieldValues = inputWrapper.isrData.parsedData[i];
    //         Date sessionDate;
    //         sessionDate = Date.parse(isrFieldValues[4]);
    //         String dateStr2 = sessionDate.month()+ '/' + sessionDate.day()+ '/' + sessionDate.year() ;
    //         String setvalue2 =isrFieldValues[2]+'#'+dateStr2+'#'+isrFieldValues[8]+'#'+isrFieldValues[9]+'#'+isrFieldValues[10]+'#'+isrFieldValues[11]+'#'+isrFieldValues[12]+'#'+isrFieldValues[13];
    //         //setvalue2=setvalue2.deleteWhitespace();
    //         if(avoideTheduplicatestudents.containskey(setvalue2)){
    //             totalAmount=decimal.valueOf(avoideTheduplicatestudents.get(setvalue2));
    //             totalAmount=totalAmount+decimal.valueOf(isrFieldValues[5]);
    //             avoideTheduplicatestudents.put(setvalue2,String.valueOf(totalAmount));
    //         }
    //         else{
    //             avoideTheduplicatestudents.put(setvalue2,isrFieldValues[5]);
    //         }
    //     }
    //     //System.debug('avoideTheduplicatestudents++'+avoideTheduplicatestudents);
    //     ///////
    //     Set<string> deplicateSet = new set<string>();
    //     for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
    //         //for (List<String> isrFieldValues : inputWrapper.isrData.parsedData) {
    //         List<String> isrFieldValues = inputWrapper.isrData.parsedData[i];
    //         Id studentId = isrFieldValues[0];
    //         Date sessionDate;
    //         sessionDate = Date.parse(isrFieldValues[4]);
    //         String dateStr2 = sessionDate.month()+ '/' + sessionDate.day()+ '/' + sessionDate.year() ;
    //         String setvalue =dateStr2+'#'+isrFieldValues[8]+'#'+isrFieldValues[9]+'#'+isrFieldValues[10]+'#'+isrFieldValues[11]+'#'+isrFieldValues[12]+'#'+isrFieldValues[13];
    //         setvalue=setvalue.deleteWhitespace();
    //         System.debug('setvalue++'+setvalue);
    //         // isrs.add(new Intervention_Session_Result__c(
    //         //         Student__c = studentId,
    //         //         Amount_of_Time__c = Decimal.valueOf(isrFieldValues[5]),
    //         //         Exit_Ticket__c = isrFieldValues[6],
    //         //         Intervention_Session__c = dateToSessionMap.get(setvalue).Id,
    //         //         Student_Section__c = studentToStudentSectionIds.get(studentId)
    //         // ));
    //         String setvalue2 =isrFieldValues[2]+'#'+dateStr2+'#'+isrFieldValues[8]+'#'+isrFieldValues[9]+'#'+isrFieldValues[10]+'#'+isrFieldValues[11]+'#'+isrFieldValues[12]+'#'+isrFieldValues[13];
    //         //setvalue2=setvalue2.deleteWhitespace();
    //         System.debug('setvalue2**'+setvalue2);
    //         if(!deplicateSet.contains(setvalue2)){
    //         Intervention_Session_Result__c interventionresult = new Intervention_Session_Result__c();
    //         interventionresult.Student__c = studentId;
    //         interventionresult.Amount_of_Time__c =Decimal.valueOf(avoideTheduplicatestudents.get(setvalue2));
    //         interventionresult.Exit_Ticket__c = isrFieldValues[6];
    //         interventionresult.Intervention_Session__c = dateToSessionMap.get(setvalue).Id;
    //         interventionresult.Student_Section__c = studentToStudentSectionIds.get(studentId);
    //         isrs.add(interventionresult);
    //         deplicateSet.add(setvalue2);
    //        }
    //     }
    //     if (!msgErrors.isEmpty()) {
    //         return msgErrors;
    //     }
    //     try {
    //         System.debug('ISRS SIZE ' + isrs.size());
    //         insert isrs;
    //     } catch (DmlException e) {
    //         msgErrors.add(e.getDmlMessage(0));
    //     }
    //     createdSessions = sessions;
    //     return msgErrors;
    // }
    /////////////// guided process and bulk upload with blank template values added by juturi rajesh ///////////////////
    private List<String> splitStudentsDataWithBlankTemplateValues(){
        List<String> msgErrors = new List<String>();
        this.createObjectFieldSet('student');
        this.createObjectFieldSet('session');
        Map<String, Id> skillNameToIdMap = new Map<String, Id>();
        integer numFields = inputWrapper.isrData.headers.size();
        string apiString = '';
        for(String s: inputWrapper.isrData.headers){
            s = s.replace('*REQ* ', '');
            if(intSessionResultLabelMap.containsKey(s)){
                string field = intSessionResultLabelMap.get(s);
                apiString = ',' + field;
                inputWrapper.displayLabels.add(new fieldWrapper(intSessionResultSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
                inputWrapper.apiList.add(intSessionResultLabelMap.get(s));
            } else if (s == 'Date'){
            }
            // else if(s != 'Primary Skill (Skill_Primary__c)' && intSessionResultLabelMap.containsKey(s)){
            //     String field = intSessionResultLabelMap.get(s);
            //     apiString = ',' + field;
            //     inputWrapper.displayLabels.add(new fieldWrapper(intSessionResultSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
            //     inputWrapper.apiList.add(intSessionResultLabelMap.get(s));
            // } else if (s == 'Primary Skill (Skill_Primary__c)'){

            // }
            // else if (s == 'In-Person Service or Virtual Service (All_avenues__c)') {
            //     String originValue = 'All avenues (All_avenues__c)';
            //     String field = intSessionResultLabelMap.get(originValue);
            //     apiString = ',' + field;
            //     inputWrapper.displayLabels.add(new fieldWrapper(intSessionResultSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
            //     inputWrapper.apiList.add(intSessionResultLabelMap.get(originValue));
            // }

             else {
                msgErrors.add('Error: Import failed. Field' + s + ' was not found in the system. Please do not modify the field names.');
            }
        }
        inputWrapper.fieldAPIs = apiString;
        if (inputWrapper.isrData.parsedData.size() > 1000) {
            tooManyStudentsError = true;
        }
        System.debug('msgErrors ' + msgErrors.size());
        List<Intervention_Session_Result__c> isrs = new List<Intervention_Session_Result__c>();
        Set<Date> dates = new Set<Date>();
        Map<string, Id> studentToStudentSectionIds = new Map<string, Id>();
        Set<Id> uploadedStudents = new Set<Id>();
        Set<String> skillNames = new Set<String>();
        Set<string> sectionNameSet = new Set<string>();
        Set<string> studentIdSet = new Set<string>();
        Set<string> staffNameSet = new Set<string>();
        for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
            List<String> isrFieldValues = inputWrapper.isrData.parsedData[i];
            sectionNameSet.add(isrFieldValues[3]);
            studentIdSet.add(isrFieldValues[2]);
            staffNameSet.add(isrFieldValues[4]);
            try{
                skillNames.add(isrFieldValues[9]);
            } catch (Exception e) {
            }
        }
        skillNameToIdMap = getSkillsMap(skillNames);
        Map<String,Student_Section__c> studentCheckInSection = new Map<String,Student_Section__c>();
        for(Student_Section__c ss : [SELECT Id, Student__r.Student_ID_Auto_Number__c,Section__c,Section__r.name FROM Student_Section__c where Section__r.name =:sectionNameSet]){
            studentCheckInSection.put(ss.Student__r.Student_ID_Auto_Number__c+'-'+ss.Section__r.name,ss);
        }
        Map<string,Section__c> sectionMap = new Map<String,Section__c>();
        for(Section__c se : [select id,name,Auto_Name__c,Intervention_Primary_Staff__c,Start_Date__c,End_Date__c from Section__c where name =: sectionNameSet]){
            sectionMap.put(se.name,se);
        }
        Map<String,Student__c> studentMap = new Map<String,Student__c>();
        for(Student__c st: [select id,Student_ID_Auto_Number__c from Student__c where Student_ID_Auto_Number__c =: studentIdSet]){
            studentMap.put(st.Student_ID_Auto_Number__c,st);
        }
        Map<string,Staff__c> staffMap = new Map<String,Staff__c>();
        for(Staff__c sf : [select id,name from Staff__c where name =: staffNameSet]){
            staffMap.put(sf.name,sf);
        }
        Set<Id> sectionSetIds = new Set<Id>();
        Integer count = 2;
        for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
            List<String> isrFieldValues = inputWrapper.isrData.parsedData[i];
            count++;
            Integer fieldsNumber = isrFieldValues.size();
            Date dateValue;
            if(isrFieldValues[5] !=''){
                 dateValue =  Date.parse(isrFieldValues[5]);
            }
            if(dateValue > System.today()){
                msgErrors.add('error in row '+count+':  The date '+isrFieldValues[5]+' is a future date. Doesn\'t allow time submission on the future date.');
            }
            if(isrFieldValues[2]==''){
                msgErrors.add('error in row '+count+': Please Fill the Student Identifier');
            }
            if (!studentMap.containsKey(isrFieldValues[2])){
                msgErrors.add('error in row '+count+': Please Enter the valid Student Identifier');
            }
            if(!studentCheckInSection.containsKey(isrFieldValues[2]+'-'+isrFieldValues[3])){
                msgErrors.add('error in row '+count+': The student id not exist in the corresponding section :'+isrFieldValues[3]);
            }
            if(isrFieldValues[3] ==''){
                msgErrors.add('error in row '+count+': Please Fill the Intervention Section Name');
            }
            if(!sectionMap.containsKey(isrFieldValues[3])){
                msgErrors.add('error in row '+count+': Please Enter the valid Intervention Section Name: '+isrFieldValues[3]);
            }
            if(isrFieldValues[3] !='' && sectionMap.containsKey(isrFieldValues[3])){
                sectionSetIds.add(sectionMap.get(isrFieldValues[3]).id);
            }
            if(isrFieldValues[4]==''){
                msgErrors.add('error in row '+count+': Please Fill the Staff Name');
            }
            if(!staffMap.containsKey(isrFieldValues[4])){
                msgErrors.add('error in row '+count+': Please Enter the valid Staff Name: '+isrFieldValues[4]);
            }
            Date templateDate;
            if(isrFieldValues[5] !=''){
                 templateDate =  Date.parse(isrFieldValues[5]);
            }
            if(sectionMap.containsKey(isrFieldValues[3])){
                if(templateDate < sectionMap.get(isrFieldValues[3]).Start_Date__c || templateDate > sectionMap.get(isrFieldValues[3]).End_Date__c){
                    msgErrors.add('error in row '+count+':  The date '+isrFieldValues[5]+' should be with in the start and end date of the section');
                 }
            }
            try{
                if (isrFieldValues[5] == '') {
                    msgErrors.add('error in row '+count+': Empty date. Please enter a valid date in the following format MM/DD/YYYY. ');
                } else {
                    dates.add(Date.parse(isrFieldValues[5]));
                }
                if (isrFieldValues.size() < 7 || isrFieldValues[6] == '') {
                    msgErrors.add('error in row '+count+': Empty Amount Of Time. Please enter a valid value.');
                } else {
                    try{
                        Decimal.valueOf(isrFieldValues[6]);
                    } catch (Exception e){
                        msgErrors.add('error in row '+count+': Invalid Amount of Time. Please, enter a Decimal value.');
                    }
                }
            } catch (System.TypeException e){
                msgErrors.add('error in row '+count+': a Student: '+isrFieldValues[2]+'. Invalid date : ' + isrFieldValues[1] +
                        '. Please enter a valid date in the following format MM/DD/YYYY. ');
            }
            if(isrFieldValues[9] !='' && isrFieldValues[9] != null){
            if (fieldsNumber > 10 && !skillNameToIdMap.containsKey(isrFieldValues[9])) {
                msgErrors.add('error in row '+count+': Import failed. Primary Skill  '+ isrFieldValues[9] + ' doesn\'t exist for Session ' + isrFieldValues[2]);
            } else if (fieldsNumber >= 10 && skillNameToIdMap.containsKey(isrFieldValues[9])){
                if (fieldsNumber >= 10) {
                    if (isrFieldValues[10].contains(isrFieldValues[9])) {
                        msgErrors.add('error in row '+count+':Invalid Other Skills for Session Other Skills should not duplicate Primary Skills.');
                    }
                    List<String> otherSkillsParsed = isrFieldValues[10].split(';');
                    for (String skill : otherSkillsParsed) {
                        if (!otherSkills.contains(skill) && skill != '') {
                            msgErrors.add('error in row '+count+':Invalid Other Skill for Session ' + isrFieldValues[2] + ' - ' + skill + '.');
                        }
                    }
                }
                // if (isrFieldValues[9] == 'In-Person Service' || isrFieldValues[9] == 'Virtual Service') {
                   
                // } else {
                //     msgErrors.add('Invalid All avenues value for Session ' + isrFieldValues[2] + '. It should be either In-Person Service or Virtual Service');
                // }
            }
          }
            if (fieldsNumber < 13) {
                msgErrors.add('Please, verify that ALL fields have been set for Session ' + isrFieldValues[2] + ' : All avenues, Primary Skill, Other Skills.');
            }
            try{
                uploadedStudents.add(isrFieldValues[3]);
            } catch (Exception e){
            }
            if (msgErrors.size() > 900) {
                msgErrors.add('Too many errors. Only first 900 are displayed.');
                return msgErrors;
            }
           
        }
        if (!msgErrors.isEmpty()) {
            return msgErrors;
        }
        List<Student_Section__c> relatedStudentSections = [SELECT Id, Student__r.Student_ID_Auto_Number__c,Section__c,Section__r.name FROM Student_Section__c WHERE Section__c = :sectionSetIds];
        for(Student_Section__c studentSection : relatedStudentSections) {
            studentToStudentSectionIds.put(studentSection.Student__c+'-'+studentSection.Section__c, studentSection.Id);
        }
        //System.debug('studentToStudentSectionIds++'+studentToStudentSectionIds);
        List<Intervention_Session__c> sessions = new List<Intervention_Session__c>();

        ////////////////////////
        list<Intervention_Session__c> ISList= new   list<Intervention_Session__c>();// instantiate
        list<Intervention_Session_Result__c> ISRList = new  list<Intervention_Session_Result__c>();
        Map<string,List<Intervention_Session_Result__c>> listToInsert=new Map<string,List<Intervention_Session_Result__c>> ();
        Map<string,Intervention_Session__c> keyVSinterversionMap=new Map<string,Intervention_Session__c>();

        Integer LoopCount=0;
        boolean shouldContinue = true;

        List<List<String>> recordsData = new  List<List<String>>();
        for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
            recordsData.add(inputWrapper.isrData.parsedData[i]);
        }
         System.debug('recordsData'+recordsData.size());
        do{
              // construct unique sessions based on list<rowsToCreate>
              Set<string> sessionkeySet = new Set<string>();
          for(integer i=0; i<recordsData.size() && i<recordsCount ; i++){

            List<String> isrFieldValues = recordsData[i];
            string sessionKeyValue =isrFieldValues[3]+isrFieldValues[4]+isrFieldValues[5]+isrFieldValues[9]+isrFieldValues[10]+isrFieldValues[11]+isrFieldValues[12]+isrFieldValues[13];
            string SessionKey=sessionKeyValue.trim()+''+LoopCount;
            
            if(!sessionkeySet.contains(SessionKey)){
                // System.debug('SessionKey**'+SessionKey);
                Integer listSize = isrFieldValues.size();
                Date sessionDate2 =  Date.parse(isrFieldValues[5]);
                //InterversionSEssion Record, sessionKey= SessionKey
                Intervention_Session__c interventionsession = new Intervention_Session__c(
                        Date__c = sessionDate2,
                        Section__c = sectionMap.get(isrFieldValues[3]).id,
                        Session_Time_Completed_For__c = staffMap.get(isrFieldValues[4]).Id,
                        Comments__c = isrFieldValues[8],
                        //All_avenues__c = isrFieldValues[9],
                        Skill_Primary__c = skillNameToIdMap.get(isrFieldValues[9]),
                        Skills_Covered_for_the_Session__c = listSize >= 11 ? isrFieldValues[10] : '',
                        Site_Details__c = listSize >= 12 ? isrFieldValues[11] : '',
                        Session_Type__c = listSize >= 13 ? isrFieldValues[12] : '',
                        Session_Format__c = listSize >= 13 ? isrFieldValues[13] : '',
                        UniqueSessionKey__c=SessionKey);
                keyVSinterversionMap.put(SessionKey,interventionsession);
                // System.debug('keyVSinterversionMap++'+keyVSinterversionMap);
                sessionkeySet.add(SessionKey);
            }
           
           }
            // create map of session => sessionKeys based on list<sessionRowsToInsert>
            // instantiate map of sessionKeys => list<student>
            Map<string,list<string>> SessionKeyVsStudnetIdMap= New Map<string,List<string>> ();
            //Integer LoopCount1=0;
            Set<string> StudentIdSet2 = new set<string>();
            Integer totalrecords =recordsData.size();
            List<List<String>> parsedData =recordsData;
            // system.debug('parsedDatasize'+parsedData.size());
            for(integer i=parsedData.size()-1; i>=0 ; i--) {
                // System.debug('listSize++'+recordsData.size());
                List<String> isrFieldValues = recordsData[i];
                string sessionKeyValue =isrFieldValues[3]+isrFieldValues[4]+isrFieldValues[5]+isrFieldValues[9]+isrFieldValues[10]+isrFieldValues[11]+isrFieldValues[12]+isrFieldValues[13];
                string SessionKey=sessionKeyValue.trim()+''+LoopCount;
                
                string StudentId = isrFieldValues[2]+SessionKey;
                // System.debug('StudentId before '+isrFieldValues[2] +'#'+ SessionKey);
                //System.debug('SessionKey2 before **'+SessionKey);
                // check if sessionKeys => list<student> contains student
                if(!StudentIdSet2.contains(StudentId) && keyVSinterversionMap.containsKey(SessionKey)) { 
                // System.debug('StudentId after'+isrFieldValues[2]);
                // System.debug('SessionKey2 after**'+SessionKey);
                    // add record for student to list<interventionSessionRowsToInsert>
                    if(!listToInsert.containsKey(SessionKey)){
                        listToInsert.put(SessionKey,New list<Intervention_Session_Result__c>());
                    }
                      //Interversion Record initiate = AddcurrentRow
                      Intervention_Session_Result__c isrs1 = new Intervention_Session_Result__c(
                        Student__c = studentMap.get(isrFieldValues[2]).Id,
                        Amount_of_Time__c =Decimal.valueOf(isrFieldValues[6]),
                        Exit_Ticket__c = isrFieldValues[7],
                        UniqueSessionKey__c =SessionKey
                        //Student_Section__c = studentToStudentSectionIds.get(isrFieldValues[2])
                        );
                        listToInsert.get(SessionKey).add(isrs1);

                        recordsData.Remove(i);
                    StudentIdSet2.add(StudentId);
                }
            }
            LoopCount++;
       }
        while (recordsData.size()>0);
        inputWrapper.isrData.parsedData=recordsData;
        for (Intervention_Session__c intssession : keyVSinterversionMap.values()) {
            if (intssession != null) {
                sessions.add(intssession);
            }
        }
        set<id> interventionSessionIdSet = new Set<id>();
        try {
            insert sessions;
        } catch (Exception e) {
            msgErrors.add(e.getMessage());
        }
        if (!msgErrors.isEmpty()) {
            return msgErrors;
        }

        Map<string,Intervention_Session__c> uniqueVsSFId=new Map<string,Intervention_Session__c>();
        Set<string> checkingSectionData = new Set<string>();

        for(Intervention_Session__c intsession : sessions){
            uniqueVsSFId.put(intsession.UniqueSessionKey__c,intsession);
            checkingSectionData.add(intsession.Section__c);
        }
        List<Intervention_Session_Result__c> istoInsert=new List<Intervention_Session_Result__c>();

        for(List<Intervention_Session_Result__c> lstResult: listToInsert.values()){
            istoInsert.addAll(lstResult);
       }
        for(Intervention_Session_Result__c interventionResult : istoInsert){
            if(uniqueVsSFId.containsKey(interventionResult.UniqueSessionKey__c)){
                interventionResult.Intervention_Session__c=uniqueVsSFId.get(interventionResult.UniqueSessionKey__c).id;
                string sectionId = uniqueVsSFId.get(interventionResult.UniqueSessionKey__c).Section__c;
                interventionResult.Student_Section__c = studentToStudentSectionIds.get(interventionResult.student__c+'-'+sectionId);
                isrs.add(interventionResult);
            }
        }
        if (!msgErrors.isEmpty()) {
            return msgErrors;
        }
        try {
            System.debug('ISRS SIZE ' + isrs.size());
           insert isrs;
        } catch (DmlException e) {
            msgErrors.add(e.getDmlMessage(0));
        }
        createdSessions = sessions;
        return msgErrors;
    }
    /////////////// guided process and bulk upload with blank template values edded by juturi rajesh ///////////////////

    private List<String> splitSessionsData(){
        List<String> msgErrors = new List<String>();
        Map<String, Id> skillNameToIdMap = new Map<String, Id>();
        this.createObjectFieldSet('session');
        String apiString = '';
        for(String s: inputWrapper.isrData.headers){
            s = s.replace('*REQ* ', '');
            if(s != 'Primary Skill (Skill_Primary__c)' && intSessionResultLabelMap.containsKey(s)){
                String field = intSessionResultLabelMap.get(s);
                apiString = ',' + field;
                inputWrapper.displayLabels.add(new fieldWrapper(intSessionResultSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
                inputWrapper.apiList.add(intSessionResultLabelMap.get(s));
            } else if (s == 'Primary Skill (Skill_Primary__c)'){

            } else if (s == 'In-Person Service or Virtual Service (All_avenues__c)') {
                String originValue = 'All avenues (All_avenues__c)';
                String field = intSessionResultLabelMap.get(originValue);
                apiString = ',' + field;
                inputWrapper.displayLabels.add(new fieldWrapper(intSessionResultSystemLabels.get(field), field, fieldTypeMap.get(field), fieldLengthMap.get(field)));
                inputWrapper.apiList.add(intSessionResultLabelMap.get(originValue));
            } else {
                msgErrors.add('Error: Import failed. Field ' + s + ' was not found in the system. Please do not modify the field names.');
            }
        }
        inputWrapper.fieldAPIs = apiString;
        Set<String> skillNames = new Set<String>();
        for(integer i=0; i<inputWrapper.isrData.parsedData.size() && i<recordsCount ; i++){
            List<String> singleSession = inputWrapper.isrData.parsedData[i];
            try{
                inputWrapper.isrIDs.add(singleSession[0]);
            } catch (Exception e){
                msgErrors.add('Error on a Session: ' + singleSession[2] + '. Invalid Id - ' + singleSession[0] + '. Please do not edit the Id fields.');
            }
            try{
                skillNames.add(singleSession[5]);
            } catch (Exception e) {
            }
        }
        skillNameToIdMap = getSkillsMap(skillNames);
        List<Intervention_Session__c> sessions = new List<Intervention_Session__c>();
        for (List<String> isrFieldValues : inputWrapper.isrData.parsedData) {
            Integer fieldsNumber = isrFieldValues.size();
            if (fieldsNumber > 6 && !skillNameToIdMap.containsKey(isrFieldValues[5])) {
                msgErrors.add('Error: Import failed. Primary Skill ' + isrFieldValues[5] + ' doesn\'t exist for Session ' + isrFieldValues[1]);
            } else if ((isrFieldValues[0] instanceOf Id) && fieldsNumber >= 6 && skillNameToIdMap.containsKey(isrFieldValues[5])){
                if (fieldsNumber >= 7) {
                    if (isrFieldValues[6].contains(isrFieldValues[5])) {
                        msgErrors.add('Invalid Other Skills for Session ' + isrFieldValues[1] + '. Other Skills should not duplicate Primary Skills.');
                    }
                    List<String> otherSkillsParsed = isrFieldValues[6].split(';');
                    for (String skill : otherSkillsParsed) {
                        if (!otherSkills.contains(skill) && skill != '') {
                            msgErrors.add('Invalid Other Skill for Session ' + isrFieldValues[1] + ' - ' + skill + '.');
                        }
                    }
                }
                if (isrFieldValues[4] == 'In-Person Service' || isrFieldValues[4] == 'Virtual Service') {
                    sessions.add(generateInterventionSessionFromWrapper(isrFieldValues,skillNameToIdMap));
                } else {
                    msgErrors.add('Invalid All avenues value for Session ' + isrFieldValues[1] + '. It should be either In-Person Service or Virtual Service');
                }
            }
            if (fieldsNumber < 7) {
                msgErrors.add('Please, verify that ALL fields have been set for Session ' + isrFieldValues[1] + ' : All avenues, Primary Skill, Other Skills.');
            }
        }
        if (!msgErrors.isEmpty()) {
            return msgErrors;
        }
        try {
            update sessions;
        } catch(DmlException ex) {
            msgErrors.add(ex.getDmlMessage(0) );
        }
        createdSessions = sessions;
        return msgErrors;
    }

    private Intervention_Session__c generateInterventionSessionFromWrapper(List<String> isrFieldValues, Map<String, Id> skillNameToIdMap) {
        Integer listSize = isrFieldValues.size();
        Intervention_Session__c session = new Intervention_Session__c();
        session.Id = isrFieldValues[0];
        session.Comments__c = isrFieldValues[3];
        session.All_avenues__c = isrFieldValues[4];
        session.Skill_Primary__c = skillNameToIdMap.get(isrFieldValues[5]);
        session.Skills_Covered_for_the_Session__c = listSize >= 7 ? isrFieldValues[6] : '';
        session.Site_Details__c = listSize >= 8 ? isrFieldValues[7] : '';
        session.Session_Type__c = listSize >= 9 ? isrFieldValues[8] : '';
        session.Session_Format__c = listSize >= 10 ? isrFieldValues[9] : '';
        return session;
    }

    private static Map<String, Id> getSkillsMap(Set<String> skillNames){
        Map<String, Id> skillsMap = new Map<String, Id> ();
        otherSkills = new List<String>();
        List<Skill__c> skills = [SELECT Id, Name, Category__c FROM Skill__c LIMIT 1000];
        for(Skill__c skill : skills) {
            if (skillNames.contains(skill.Name)) {
                skillsMap.put(skill.Name, skill.Id);
            }
            else{
                otherSkills.add(skill.Name);
            }
            // if (skill.Category__c == 'SEL/Behavior and Attendance Interventions') {
            //     otherSkills.add(skill.Name);
            // }
        }
        return skillsMap;
    }

    public PageReference cancelImport(){
        return Page.SessionInterventionBulkUpload;
    }

    private void createObjectFieldSet(String objectName){
        intSessionResultSystemLabels = new Map<String, String>();
        fieldTypeMap = new Map<String, String>();
        fieldLengthMap = new Map<String, Integer>();
        Map<String, Schema.SObjectField> describe;
        if (objectName == 'student') {
            describe = Schema.SObjectType.Intervention_Session_Result__c.fields.getMap();
        } else if (objectName == 'session'){
            describe = Schema.SObjectType.Intervention_Session__c.fields.getMap();
        }
        for(Schema.Sobjectfield s: describe.values()){
            string fieldName = String.valueOf(s);
            if(fieldName.contains('__c')){
                string api = fieldName;
                string label = s.getDescribe().getLabel();
                string uniquelabel = label+' (' + api + ')';

                intSessionResultAPIMap.put(api, uniqueLabel);
                intSessionResultSystemLabels.put(api, label);
                intSessionResultLabelMap.put(uniqueLabel, api);
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

    private void displayCreatedSessions() {
        selectSessions();
        showCreatedSessions = true;
        showISRImportSection = false;
    }

    private void displayUpdatedSessions() {
        selectSessions();
        showISRImportSection = false;
        showUpdatedSessions = true;
        showSessionsImportSection = false;
    }

    private void selectSessions() {
        createdSessions = [SELECT Id, Name, All_avenues__c, ISR_Count__c, Section__c, Section__r.Name, Date__c, Session_Time_Completed_For__c,
                Session_Time_Completed_For__r.Name, Comments__c, Skill_Primary__c, Skills_Covered_for_the_Session__c, Session_Type__c, Session_Format__c, Site_Details__c,
                        (SELECT Id, Student__c, Student__r.Name,  Amount_of_Time__c, Exit_Ticket__c FROM Intervention_Session_Results__r LIMIT 50)
                        FROM Intervention_Session__c
                        WHERE Id IN : createdSessions
                        ORDER BY Date__c ASC ];
    }

    private void errorMessage(string error){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, error));
    }

    private void infoMessage(string message){
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
    }

    //*****************************************************************************
    //Wrapper classes

    public class SessionResultsWrapper{
        public String studentId			{get;set;}
        public String studentName		{get;set;}
        public String studentLocalId		{get;set;}
        public String studentCYId		{get;set;}
        public Boolean isChecked		{get;set;}
        public string sectionName {get;set;}
        public string staffName   {get;set;}
        public string legacyId    {get;set;}

        private String studentSectionID;

        public SessionResultsWrapper(string sectionName,string staffName,String studentName, String studentID, ID studentSectionID, String studentLocalId, String studentCYId,string legacyId){
            this.sectionName=sectionName;
            this.staffName=staffName;
            this.studentName = studentName;
            this.studentID = studentID;
            this.studentSectionId = studentSectionID;
            this.studentLocalId = studentLocalId;
            this.studentCYId = studentCYId;
            this.legacyId=legacyId;
            this.isChecked = false;
        }
    }


    public class ISRWrapper{
        public Intervention_Session_Result__c 	isr           {get;set;}
        public Student__c                       student       {get;set;}

        public ISRWrapper(Student__c student){
            this.student = student;
        }
    }

    public class SessionWrapper{
        public Intervention_Session__c session               {get;set;}

        public SessionWrapper(Intervention_Session__c session){
            this.session = session;
        }
    }

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

    public class dataWrapper{
        public String headerInfo                {get;set;}
        public List<fieldWrapper> displayLabels {get;set;}
        public List<String> fieldLabels         {get;set;}
        public String fieldAPIs                 {get;set;}
        public List<String> apiList             {get;set;}
        public List<sObject> intSessionResults        {get;set;}
        public Set<Id> isrIDs;
        public Map<Id, sObject> assessmentMap;
        private CSVUtils.CSVParser isrData;
        public Integer skipColumns              {get;set;}

        public dataWrapper(){
            isrIDs = new Set<Id>();
            fieldLabels = new List<String>();
            assessmentMap = new Map<Id, sObject>();
            fieldAPIs = '';
            headerInfo = '';
            intSessionResults = new List<sObject>();
            apiList = new List<String>();
            displayLabels = new List<fieldWrapper>();
            skipColumns = 0;
        }
    }


}