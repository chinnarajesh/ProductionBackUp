public with sharing class IndicatorAreasController {
    public Set<Id> selected                             {get;set;}
    public List<StudentInfoWrapper> StudentsFiltered    {get;set;}
    public List<StudentInfoWrapper> StudentsFilteredTest    {get;set;}
    public Map<String,List<SelectOption>> siteToSchools {get;set;}
    public List<SelectOption> schools                   {get;set;}
    public Map<Id, StudentInfoWrapper> addTo            {get;set;}
    public List<Indicator_Area__c> areas                {get;set;}
    public List<SelectOption> gradeLevels               {get;set;}
    public String selectedGrade                         {get;set;}
    public String[] activeIAId                         {get;set;}
    public List<Id> orderedStudentIdsInAddTo            {get;set;}
    public Map<Id, StudentInfoWrapper> orderedStudentsAddToMap  {get;set;}
    
    public List<Indicator_Area_Student__c> changes;
    public Set<String> changesIDs;
    public String errorMessage                          {get;set;}
    
    public Map<Id, Student__c> StudentMap               {get;set;}
    public Map<Id, StudentInfoWrapper> StudentWrapperMap            {get;set;}
    public Map<String, List<StudentInfoWrapper>> studentsByGradeMap {get;set;}
    public Map<Id, Indicator_Area__c> AreaMap       {get;set;}
    
    public String SchoolFilterParam                 {get;set;}
    public List<SelectOption> sites                 {get;set;}
    public String selectedSite                      {get;set;}
    
    public Boolean hasUnsavedChanges                {get; set;}

    public IndicatorAreasController(){
        StudentsFiltered = new List<StudentInfoWrapper>();
        StudentsFilteredTest = new List<StudentInfoWrapper>();
        addTo = new Map<Id, StudentInfoWrapper>();
        schools = new List<SelectOption>();
        sites = new List<SelectOption>();
        selected = new set<Id>();
        StudentMap = new Map<Id, Student__c>();
        AreaMap = new Map<Id, Indicator_Area__c>();
        StudentWrapperMap = new Map<Id, StudentInfoWrapper>();
        changes= new List<Indicator_Area_Student__c>();
        changesIDs= new Set<String>();
        orderedStudentIdsInAddTo = new List<String>();
        orderedStudentsAddToMap = new Map<Id, StudentInfoWrapper>();

        loadAreas();
        loadSchools();
        hasUnsavedChanges = false;
    }
    
    public void loadSchools(){
        siteToSchools = new Map<String,List<SelectOption>>();
        sites = new List<SelectOption>();
        List<Account> schoolList = [select id, Name, Site__c, (select id from Students__r limit 1) from Account where Site__c != null order by Name];
        for(Account school:schoolList){
            if(school.Students__r.size()>0){
                if(siteToSchools.containsKey(school.Site__c)){
                    siteToSchools.get(school.Site__c).add(new SelectOption(school.ID, school.Name));
                } else {
                    siteToSchools.put(school.Site__c, new List<SelectOption>{new SelectOption(school.ID, school.Name)});
                    sites.add(new SelectOption(school.Site__c, school.Site__c));
                }
            }
        }
        system.debug(siteToSchools.keySet());

        if(siteToSchools.isEmpty()){
            CYUtil.errorMessage('There are no valid schools to load. Please check your data.');
        } else {
            sites.sort();
            selectedSite = sites[0].getValue();
            changeSite();
        }
    }

    public void changeSite(){
        schools = new List<SelectOption>();
        schools.addAll(siteToSchools.get(selectedSite));
    }

    public void changeSchool(){
        selectedGrade = 'all';
        loadStudents();
    }

    public void loadStudents(){
        String query = 
            'SELECT Id, Name, Student_Id__c, Local_Student_ID__c, Student_Last_Name__c, Student_First_Name__c, ' +
                'School__c, Grade__c, Entry_Date__c, Expiration_Date__c, '+
                '(SELECT Indicator_Area__r.name, Student__r.Name, Reference_ID__c, Active__c, IA_Effective_Date__c '+
                'FROM Indicator_Area_Student__r '+
                'ORDER BY Indicator_Area__r.name asc), '+
                '(SELECT Section_Exit_Reason__c, Section__r.Program__r.Indicator_Area__r.Name '+
                'FROM Student_Section__r '+
                'ORDER BY Section__r.Program__r.Indicator_Area__r.Name asc) '+  
                //'(SELECT Program1__r.Name, Program1__r.Indicator_Area__r.Name '+
                //'from Student_Programs__r '+
                //'order by Program1__r.Indicator_Area__r.name asc) '+
            'FROM Student__c '+
            'WHERE School__c=\''+String.escapeSingleQuotes(schoolFilterParam)+'\' '+
            'and Active__c=true '+
            'and Archived__c=false ';

        if(String.isNotBlank(selectedGrade) && selectedGrade != 'all'){
            query += 'and Grade__c = \''+String.escapeSingleQuotes(selectedGrade)+'\' ';
        }
        query += 'order by student_last_name__c, student_first_name__c asc';
        
        List<Student__c> students = (schoolFilterParam != '--None--')? Database.query(query): new List<Student__c>();

        studentsFiltered = new List<StudentInfoWrapper>();
        studentWrapperMap = new Map<Id, StudentInfoWrapper>();

        Set<String> studentGrades = new Set<String>();
        for(Student__c student:students){
            studentGrades.add(student.Grade__c);
            if(studentsFiltered.size()<1000){
                StudentInfoWrapper newSW = new StudentInfoWrapper(student, student.Indicator_Area_Student__r);
                studentsFiltered.add(newSW);
                studentWrapperMap.put(student.ID,newSW);
            }
        }

        if(studentGrades.size()>0 && selectedGrade == 'all'){
            loadGradeLevels(studentGrades);
        }

        if(studentsFiltered.size() > 1000){
            CYUtil.infoMessage('There are more than 1000 students in the selected school. Students must be filtered by a grade for this school.');
            if(gradeLevels[0].getValue() == 'all'){
                gradeLevels.remove(0);
            }
            if(gradeLevels[0].getValue() != ''){
                gradeLevels.add(0, new SelectOption('', 'Choose a grade', true));
            }
            selectedGrade = '';
        }

        if(studentsFiltered.isEmpty()){
            CYUtil.errorMessage('There are no students available using your filters. Please check your filters.');
        }       
    }

    public void filterGrades(){
        loadStudents();
    }
    
    public void loadAreas(){
        //The filter by name was a specific request by CY. Generally they just didn't want that value to display on this page.
        areas = [select name from Indicator_Area__c where Name!='Non-specific IA' order by name asc limit 40000];
        
        activeIAId = new List<string>();
        /**
        for(Indicator_Area__c IndId :areas){
        if(areas.size()>0){
             activeIAId.add(IndId.id);
        }
        }
        **/
        for(Indicator_Area__c ia : areas){
            AreaMap.put(ia.id, ia);
        }
    }

    public void loadGradeLevels(Set<String> studentGrades){
        gradeLevels = new List<SelectOption>{new SelectOption('all','All Grade Levels')};
        
        Schema.DescribeFieldResult possibleGrades = Student__c.Grade__c.getDescribe();
        for(Schema.PicklistEntry pe: possibleGrades.getPicklistValues()){
            if(studentGrades.contains(pe.getValue())){
                gradeLevels.add(new SelectOption(pe.getValue(),pe.getLabel()));
            }
        }
    }

    public String selectStudentParam{get;set;}
    
    public void selectStudent(){
        processSelectedStudents(selectStudentParam);
        if(selected.IsEmpty()){
            ApexPages.addMessage(new ApexPages.Message(apexpages.severity.error,'No students selected.'));
            selectStudentParam=null;
        }
    }

    public void processSelectedStudents(String selectStudentParam){
        for(StudentInfoWrapper studentWrapper: studentsFiltered){
            selected.remove(studentWrapper.student.ID);
            if (orderedStudentIdsInAddTo.contains(studentWrapper.student.ID)) {
                orderedStudentIdsInAddTo.remove(orderedStudentIdsInAddTo.indexOf(studentWrapper.student.ID));
            }
            addTo.remove(studentWrapper.student.ID);
            orderedStudentsAddToMap.remove(studentWrapper.student.ID);
        }

        if(String.isNotBlank(selectStudentParam)){
            List<String> ids = selectStudentParam.split(';');
            Set<Id> selIds = new Set<Id>();
            for(String i : ids){
                selIds.add(i.trim());
            }
            selected.addAll(selIds);
            List<Id> orderedStudents = sortStudentsByLastName(selected);
            for(StudentInfoWrapper studentWrapper: studentsFiltered){
                if(selIds.contains(studentWrapper.student.ID)){
                    orderedStudentsAddToMap.put(studentWrapper.student.ID, studentWrapper);
                }
            }
            System.debug('addToMap ' + orderedStudentsAddToMap);
            for (Id selectedId : orderedStudents) {
                if (orderedStudentsAddToMap.containsKey(selectedId)) {
                    System.debug('addto ' + addTo);
                    orderedStudentIdsInAddTo.add(selectedId);
                    addTo.put(selectedId, orderedStudentsAddToMap.get(selectedId));
                }
            }
        }   
    }

    private List<Id> sortStudentsByLastName(Set<Id> studentIds) {
        List<Id> sortedStudentIds = new List<Id>();
        List<Student__c> students = [SELECT Id, Student_First_Name__c, Student_Last_Name__c FROM Student__c WHERE Id IN :studentIds ORDER BY Student_Last_Name__c ASC];
        for (Student__c student : students) {
            sortedStudentIds.add(student.Id);
        }
        return sortedStudentIds;
    }

//  public void addPrep(){
        //addTo = new List<StudentWrapper>();
        //for(StudentWrapper studentWrapper: studentsFiltered){
        //  if(selected.contains(studentWrapper.student.ID)){
        //      addTo.add(studentWrapper);
        //  }
        //}
//  }
    
    public PageReference resetPage(){
        PageReference returnPage = new PageReference('/apex/IM_Indicator_Areas');
        returnPage.setRedirect(true);
        return returnPage;
            
    }

    public List<SelectOption> getIAList() {
        List<SelectOption> options = new List<SelectOption>();
        for(Indicator_Area__c a :areas){
            options.add(new SelectOption(a.Id, a.Name));
        }
        return options;
    }
    
    public void updateStudents(){
    if(activeIAId !=null && activeIAId.size()>0){
    
       for(string arealistId:activeIAId){
       
        Indicator_Area__c ia = AreaMap.get(arealistId);
       
        for(StudentInfoWrapper s : addTo.values()){
            Indicator_Area_Student__c IA_S = s.areaIds.get(arealistId);
            
            if(IA_S == null){
                IA_S = new Indicator_Area_Student__c();
                IA_S.Indicator_Area__c = ia.id;
                IA_S.Indicator_Area__r = ia;
                IA_S.Student__c = s.student.id;
                IA_S.Student__r = s.student;
                IA_S.Reference_ID__c = s.student.id+'_'+ia.id;
                IA_S.Active__c = true;
                s.addArea(IA_S);
            }

            IA_S.IA_Effective_Date__c = s.dtIA == null? IA_S.IA_Effective_Date__c: s.dtIA;
            IA_S.Active__c = true;
            if(!changesIDs.contains(IA_S.Reference_ID__c)){
                changes.add(IA_S);
                changesIDs.add(IA_S.Reference_ID__c);
            }
            s.refreshIndicatorAreaDisplay();
        }
        }
        hasUnsavedChanges = true;
        selected = new set<Id>();
        addTo = new Map<Id, StudentInfoWrapper>();
       }
       else{
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Please select atleast one Indicator area');
       }
    }
    
    public void saveChanges(){
        for (StudentInfoWrapper studWrap : StudentsFiltered) {
            for (Indicator_Area_Student__c IA_S : changes) {
                if (studWrap.student.Id == IA_S.Student__c) {
                    IA_S.IA_Effective_Date__c = studWrap.dtIA;
                }
            }

        }
        List<String> errorMessages = new List<String>();
        for(Indicator_Area_Student__c IA_S: changes){
            StudentInfoWrapper siw = StudentWrapperMap.containsKey(IA_S.Student__c)?
                    StudentWrapperMap.get(IA_S.Student__c): new StudentInfoWrapper(new Student_Section__c());
            if(siw.dtIA != null && IA_S.IA_Effective_Date__c == null){
                IA_S.IA_Effective_Date__c = StudentWrapperMap.get(IA_S.Student__c).dtIA;
            }
            if(IA_S.IA_Effective_Date__c == null){
                errorMessages.add('Please populate IA date for student: '+siw.name+' and IA: '+AreaMap.get(IA_S.Indicator_Area__c).name+'.');
            }
            if(siw.student.Entry_Date__c > IA_S.IA_Effective_Date__c || siw.student.Expiration_Date__c < IA_S.IA_Effective_Date__c){
                errorMessages.add('Student '+siw.name+' should have the IA Effective Date in the range of '+(siw.student.Entry_Date__c!=null?siw.student.Entry_Date__c.format():'-')+' to '+(siw.student.Expiration_Date__c!=null?siw.student.Expiration_Date__c.format():'-')+'.');
            }
        }
        if(changes.isEmpty()){
            CYUtil.errorMessage('Please choose an indicator area to assign before saving.'); return;
        }

        if(errorMessages.isEmpty()){
            List<Database.UpsertResult> results = Database.upsert(changes,Indicator_Area_Student__c.Reference_ID__c.getDescribe().getSObjectField(),false);
            for(integer i=0; i<results.size(); i++){
                List<Database.Error> errors = results[i].getErrors();
                for(Database.Error er : errors){
                    errorMessages.add('For student '+changes[i].Student__r.Name+'. '+er.getMessage()+'.');
                }
            }
        }

        if(errorMessages.isEmpty()){
            CYUtil.successMessage('Your changes have been saved.');
            changes= new List<Indicator_Area_Student__c>();
            changesIDs.clear();
            hasUnsavedChanges = false;
            for (StudentInfoWrapper studWrap : StudentsFiltered) {
                studWrap.selected = false;
            }
        }else{
            CYUtil.errorMessage(String.join(errorMessages, '<br/>')+'<br/>Please verify that your changes have been saved.');
        }
    }
}