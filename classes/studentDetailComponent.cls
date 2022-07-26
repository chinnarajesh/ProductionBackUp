public with sharing class studentDetailComponent{
    private Id studentID;
    private Map<ID, Student_Section__c> mapSectionToStudentSection;
    private Map<ID, Map<Id, Curriculum__c>> mapSectionToCurriculums;
    private ISTool sessionLoader;

    public Student__c student                                       {get;set;}
    public String selectedSectionId                                 {get;set;}
    public List<SelectOption> sectionList                           {get;set;}
    public Section__c selectedSection                               {
        get{
            return mapSectionToStudentSection.containsKey(selectedSectionId)?
                    mapSectionToStudentSection.get(selectedSectionId).Section__r: new Section__c(Name='');
        }
    }
    public Student_Section__c selectedStudentSection                {get;set;}
    public List<StudentInfoWrapper> studentInfos                    {
        get{
        if(selectedSectionId != null){
            selectedStudentSection.Student__r = student;
            }
            return new List<StudentInfoWrapper>{new StudentInfoWrapper(
                    student, selectedStudentSection, true
            )};
            
        }
    }
    public String selectedStaff                                     {get;set;}
    public List<SelectOption> staffList                             {get;set;}
    public List<Curriculum__c> curriculums                          {get;set;}
    public List<ISTool.SessionWrapper> sessions                     {get;set;}
    public Boolean hasCurriculums                                   {get;set;}
    public Boolean hasSessions                                      {get;set;}
    public Boolean isInSection                                      {get;set;}
    public Boolean isCurSection                                     {get;set;}
    public String selectedSessionID                                 {get;set;}

    public Intervention_Session__c          sessionHolder           {get;set;}
    public Intervention_Session_Result__c   resultHolder            {get;set;}
    
    //Skills multipicklist values
    public String                   primarySkill                {get; set; }
    public SelectOption[]           selectedFields              {get; set; }
    public SelectOption[]           avaliableFields             {get; set; }
    public SelectOption[]           allPrimaryFields            {get; set; }
    public List<Skill__c>           skillList                   {get; set; }
    public List<SelectOption>       allAvenuesOptions           {get; set; }

    public studentDetailComponent(){
        studentID = ApexPages.currentPage().getParameters().get('studentID');
        System.debug('studentID'+studentID);
       
        if(studentID == null){
            CYUtil.errorMessage('The system was unable to locate the id of the student you wish to view. Please return to the student detail page and try again.');
        } else {
            loadStartingData();
            sessionHolder = new Intervention_Session__c();
            resultHolder = new Intervention_Session_Result__c();
            //Added for skills multiselect picklist
            initializePicklist();
            
        }
        
    }

    private void loadStartingData(){
        loadStudentInfo();
        
        if(sectionList.isEmpty()){
           CYUtil.errorMessage('The selected student is not currently enrolled in any sections.');
            isInSection = false;
            System.debug('sectionList');
        } else {
            isInSection = true;
            if(ApexPages.currentPage().getParameters().get('sectionID') != null){
                selectedSectionId = ApexPages.currentPage().getParameters().get('sectionID');
                system.debug('##'+selectedSectionId);
            } else {
                selectedSectionId = sectionList[0].getValue();
                system.debug('$$'+selectedSectionId);
            }
            changeSection();
        }
      
        System.debug('Check Selected Section Id>>'+selectedSectionId);
       
     }

    private void loadStudentInfo(){
      
        student = [SELECT ID, Name, Student_First_Name__c, Student_Last_Name__c,Student_ID_Auto_Number__c,
                        (SELECT ID, Dosage_to_Date__c, Section__r.Name,Section__r.Intervention_Primary_Staff__c,
                            Section__r.School__c, Section__r.In_After_School__c, Section__r.Start_Date__c,
                            Section__r.End_Date__c,Enrollment_Start_Date__c,
                            Section__r.Target_Dosage_Section_Goal__c, Section__r.Recommended_Time_per_Session__c,
                            Student__c
                        FROM Student_Section__r
                        WHERE Active__c = true
                        AND Section__r.Active__c = true
                        AND Section__r.RecordType.DeveloperName IN ('Intervention_Section','Curriculum')),
                        (SELECT Id, Name, Student__c, Section__c, Section__r.Name, Section__r.Start_Date__c,
                            Section__r.End_Date__c, Student_Section__c,
                            Date_of_Module__c, Curriculum_Name__c, Module_Name__c, Module_Assignments__c,
                            Module_Score__c, Comments__c
                        FROM Curriculums__r
                        )
                    FROM Student__c
                    WHERE ID =: studentID];
           system.debug('student'+student.Student_Section__r);
           
        sectionList = new List<SelectOption>();
        mapSectionToStudentSection = new Map<ID, Student_Section__c>();
       
        for(Student_Section__c ss:student.Student_Section__r){
        system.debug('studentsection');
            sectionList.add(new SelectOption(ss.Section__c, ss.Section__r.Name));
            mapSectionToStudentSection.put(ss.Section__c, ss);
        }
        
        system.debug('sectionList'+sectionList);
        System.debug('mapSectionToStudentSection'+mapSectionToStudentSection);
        mapSectionToCurriculums = new Map<ID, Map<Id, Curriculum__c>>();
       
        for(Curriculum__c curriculum: student.Curriculums__r){
            if(!mapSectionToCurriculums.containsKey(curriculum.Section__c)){
                mapSectionToCurriculums.put(curriculum.Section__c, new Map<Id, Curriculum__c>());
            }
            mapSectionToCurriculums.get(curriculum.Section__c).put(curriculum.Id, curriculum);
        }
        
    
  }
    public void changeSection(){
    system.debug('changeSection');
        selectedStudentSection = mapSectionToStudentSection.get(selectedSectionId);
        //TODO: Does this need to be here?
        loadStaff();
        if(staffList.isEmpty()){
            CYUtil.errorMessage('There are no staff are available to teach this section.');
        }
        selectedStaff = selectedStudentSection.Section__r.Intervention_Primary_Staff__c;
        isCurSection = selectedStudentSection.Section__r.In_After_School__c == ISTool.SECTION_CURRICULUM;

        hasCurriculums = false;
        hasSessions = false;
        if(isCurSection){
            curriculums = mapSectionToCurriculums.containsKey(selectedSectionId)?
                    mapSectionToCurriculums.get(selectedSectionId).values(): new List<Curriculum__c>();
            hasCurriculums = !curriculums.isEmpty();
        }else{
            if(sessionLoader == null){
                sessionLoader = new ISTool((ID)selectedSectionId,selectedStudentSection.ID);
                sessionLoader.loadSessionData();
            } else {
                sessionLoader.updateSessionSelection(selectedSectionId, selectedStudentSection.ID);
            }

            if(ApexPages.currentPage().getParameters().get('date') != null){
                try{
                    Date filterDate = Date.parse(ApexPages.currentPage().getParameters().get('date'));
                    CYUtil.infoMessage('You are only viewing sessions from '+filterDate.format());
                    sessionLoader.updateSessionSelection(selectedSectionId, selectedStudentSection.ID, filterDate);
                } catch(Exception e){system.debug(e);}
            }

            sessions = sessionLoader.getOrderedSessions();
            system.debug(sessions);
            hasSessions = (sessions.size() > 0);
            System.debug('hasSessions'+hasSessions);
        }

        initializePicklist();
    }

    private void loadStaff(){
        staffList = new List<SelectOption>();
        for(Staff_Section__c ss:
                [select ID, Staff__r.Name, Staff__c
                from Staff_Section__c
                where Is_Active__c = true
                and SEction__c =: selectedSectionId]){
            staffList.add(new SelectOption(ss.Staff__c, ss.Staff__r.Name));
        }
    }

    public void editSession(){
        initializePicklist();
        ISTool.SessionWrapper wrapper = sessionLoader.getSessionByID((ID)selectedSessionID);
        sessionHolder = wrapper.session;
        resultHolder = wrapper.studentResults[0];
        selectedStaff = sessionHolder.Session_Time_Completed_For__c;
        //added for multiSelect Picklist
        //selectedFields.add(new SelectOption('test','test'));
        System.debug('Session Holder>>'+sessionHolder);
        System.debug('Skill>>'+skillList);
        String skillset = sessionHolder.Skills_Covered_for_the_Session__c;
        if(skillset == null){
            skillset = '';
        } 
        List<SelectOption> tempAvailable = new List<SelectOption>();
        List<String> skills = new List<String>();
        Set<String> tempSkills = new Set<String>();
        skills =skillset.split(', ');
        tempSkills.addAll(skills);
        selectedFields.clear();
    //  avaliableFields = new List<SelectOption>();
        primarySkill = sessionHolder.Skill_Primary__c;
        System.debug('@@@ primarySkill: '+primarySkill);
        if(skillset != ''){
            for(String key : skillset.split(', '))
            {
                selectedFields.add(new SelectOption(key,key));
            }
        }
        for(SelectOption opt : avaliableFields){
            if(!tempSkills.contains(opt.getLabel())){
                tempAvailable.add(new SelectOption(opt.getLabel(),opt.getLabel()));
            }
        }
        avaliableFields.clear();
        avaliableFields.addAll(tempAvailable);
    }

    public void saveTime(){
        sessionHolder.Session_Time_Completed_For__c = selectedStaff;
        if(sessionHolder.ID == null){
            sessionHolder.Section__c = selectedSectionId;
        }
        //added for skills multiselect picklist
        List<String> skillOpt = new List<String>();
        for(SelectOption skill : selectedFields) {
            skillOpt.add(skill.getLabel());
        }
        String skills = !skillOpt.isEmpty()? String.join(skillOpt, ', '): '';
        System.debug('Skills>>'+skills);

        sessionHolder.Skill_Primary__c = primarySkill;
        sessionHolder.Skills_Covered_for_the_Session__c = skills;
        SavePoint sp = Database.setSavePoint();
        try{
            upsert sessionHolder;
        } catch(System.DMLException e){
            CYUtil.errorMessage('An error occured while saving the selected session. Please try again.');
            for (Integer idx = 0; idx < e.getNumDml(); idx++) {
                CYUtil.errorMessage(e.getDmlMessage(idx));
            }
            Database.rollback(sp);
            return;
        }

        if(resultHolder.ID == null){
            resultHolder.Intervention_Session__c = sessionHolder.ID;
            resultHolder.Student_Section__c = selectedStudentSection.Id;
          }
        //added to update skills to Intervention Session Result
        resultHolder.SkillsCovered__c = sessionHolder.Skills_Covered_for_the_Session__c;

        try{
            upsert resultHolder;
        } catch (System.DMLException e){
            CYUtil.errorMessage('An error occured while saving the selected session result. Please try again.');
            for (Integer idx = 0; idx < e.getNumDml(); idx++) {
                CYUtil.errorMessage(e.getDmlMessage(idx));
            }
            Database.rollback(sp);
            return;
        }

        sessionLoader.loadSessionData();
        sessions = sessionLoader.getOrderedSessions();
        System.debug(''+sessions);
        loadStudentInfo();
        selectedStudentSection = mapSectionToStudentSection.get(selectedSectionId);
        system.debug('selectedStudentSection@@'+selectedStudentSection);
        resultHolder = new Intervention_Session_Result__c();
        sessionHolder = new Intervention_Session__c();
        hasSessions = true;
    }

    public void modalCancel() {
        resultHolder = new Intervention_Session_Result__c();
        sessionHolder = new Intervention_Session__c();  
    }

    public void initAvaliableFields(){
        allPrimaryFields = new List<SelectOption>();
        avaliableFields = new List<SelectOption>();
        
        List<Section__c> sectionList = [SELECT Account_Program__r.Name FROM Section__c WHERE Id = :selectedSectionId];
        String schoolProgram = !sectionList.isEmpty()? sectionList[0].Account_Program__r.Name: '';
        
        ISTool.getAvaliableSkills(schoolProgram, avaliableFields, allPrimaryFields);
        System.debug('schoolProgram'+schoolProgram);
        system.debug('allPrimaryFields'+allPrimaryFields);
        System.debug('sectionList'+sectionList);
        
    }
    
    void initSelectedFields(){
        selectedFields = new List<SelectOption>();
    }
     
    public void initializePicklist(){
        primarySkill = '';
        initAvaliableFields();
        initSelectedFields();
        initAllAvenues();
        System.debug('initializePicklist');
    }

    public void initAllAvenues(){
        allAvenuesOptions = ISTool.getAllAvenues();
    }
}