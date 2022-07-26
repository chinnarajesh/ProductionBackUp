/**
 * Created by TarasTorubka on 24.09.2020.
 */

public with sharing class ModalAddSessionCtrl {
    public Section__c               section                     {get;set;}
    public List<StudentInfoWrapper> studentSections             {get;set;}

    //Add time
    public String selectedStaff                                 {get;set;}
    public List<SelectOption> availableStaff                    {get;set;}
    public Integer dosage                                       {get;set;}

    //Edit time
    public String selectedSessionID                             {get;set;}
    public String sessionID                                     {get;set;}
    public ISTool.SessionWrapper selectedSession                {get;set;}


    //Add Students to Session
    public List<StudentInfoWrapper> addableStudents             {get;set;}

    //Remove Students from Session
    public String                   studentSectionIDToRemove    {get;set;}

    private ISTool sessionLoader;

    //Skills multipicklist values
    public String                   primarySkill                {get; set; }
    public SelectOption[]           selectedFields              {get; set; }
    public SelectOption[]           avaliableFields             {get; set; }
    public SelectOption[]           allPrimaryFields            {get; set; }
    public List<SelectOption>       allAvenuesOptions           {get; set; }

    public List<SelectOption>       siteDetailsOptions          {get; set; }
    public Boolean showTutoringModel                            {get; set; }


    public ModalAddSessionCtrl(){
        selectedSession = new ISTool.SessionWrapper(new Intervention_Session__c());
        initAllPicklist();
        showTutoringModel = false;
    }

    /* Add New Time */
    public void startAddTime(){
        Boolean isStaffs = initAvaliableStaff(section);
        if(isStaffs == false){
            return;
        }

        selectedStaff = availableStaff[0].getValue();
        selectedSession = new ISTool.SessionWrapper(new Intervention_Session__c());
        selectedSession.session.All_avenues__c = CT_core_SoqlUtils.getPicklistDefaultValue('Intervention_Session__c' ,'All_avenues__c');
        dosage = 0;

        for(StudentInfoWrapper sew: studentSections){
            if(sew.selected){
                selectedSession.studentResults.add(
                        new Intervention_Session_Result__c(
                                Student_Section__r = sew.studentSection,
                                Amount_of_Time__c = dosage,
                                Student_Section__c = sew.studentSection.ID
                        )
                );
            }
        }

        if(selectedSession.studentResults.isEmpty()){
            CyUtil.errorMessage('Please select a student to add time for.');
        }
        //added for multiselect picklist
        initializePicklist();
        showTutoringModel = section.Auto_Name__c.contains('Tutoring: Math') || section.Auto_Name__c.contains('Tutoring: Literacy');
    }

    public void loadSession(){
        if(section==null || section.Id==null){
            return;
        }
        sessionLoader = new ISTool(section.Id, false);

        initializePicklist();
        sessionLoader.setSingleSession(selectedSessionID);
        sessionLoader.updateResultSelection(true);
        sessionLoader.loadSessionData();
        selectedSession = sessionLoader.getSessionByID((ID)selectedSessionID);
        selectedStaff = selectedSession.session.Session_Time_Completed_For__c;
        availableStaff.add(new SelectOption(selectedStaff, selectedSession.session.Session_Time_Completed_For__r.Name));

        if(selectedSession.studentResults.size()>0){
            dosage = Integer.valueOf(selectedSession.studentResults[0].Amount_of_Time__c);
        } else {
            dosage = 0;
        }
        //added for multiSelect Picklist
        primarySkill = selectedSession.session.Skill_Primary__c;
        String skillset = selectedSession.session.Skills_Covered_for_the_Session__c != null? selectedSession.session.Skills_Covered_for_the_Session__c: '';
        List<SelectOption> tempAvailable = new List<SelectOption>();
        Set<String> setSkills = new Set<String>();
        List<String> skills = skillset.split(',');
        selectedFields.clear();
        for(String key : skills){
            String opt = key.removeStart(' ').removeEnd(' ');
            setSkills.add(opt);
            selectedFields.add(new SelectOption(opt, opt));
        }
        for(SelectOption opt : avaliableFields){
            if(!setSkills.contains(opt.getLabel())){
                tempAvailable.add(new SelectOption(opt.getLabel(),opt.getLabel()));
            }
        }
        avaliableFields.clear();
        avaliableFields.addAll(tempAvailable);
    }

    public void saveTime(){
        if(selectedSession.studentResults.isEmpty()){
            CYUtil.errorMessage('Please add one student to the session before saving.');
            return;
        }
       // if(String.isBlank(primarySkill) && selectedSession.session.All_avenues__c!='Virtual Service'){
       //   CYUtil.errorMessage('You should select the primary skill!');
       //   return;
       // }
        if(selectedSession.session.ID == null){
            selectedSession.session.Section__c = section.ID;
        }
        selectedSession.session.Session_Time_Completed_For__c = selectedStaff;
        //added for skills multiselect picklist
        List<String> lstSkills = new List<String>();
        for(SelectOption skill : selectedFields){
            lstSkills.add(skill.getLabel());
        }
        String skills = String.join(lstSkills, ', ');
        System.debug('Skills>>'+skills);

        selectedSession.session.Skill_Primary__c = primarySkill;
        selectedSession.session.Skills_Covered_for_the_Session__c = skills;
        try{
            upsert selectedSession.session;
        } catch(System.DMLException e){
            for(Integer i=0; i<e.getNumDml(); i++){
                CyUtil.errorMessage(e.getDMLMessage(i));
            }
            return;
        }

        for(Intervention_Session_Result__c isr:selectedSession.studentResults){
            if(isr.ID == null){
                isr.Intervention_Session__c = selectedSession.session.ID;
                isr.Student_Section__c = isr.Student_Section__r.ID;
            }
            //added to update skills to Intervention Session Result
            isr.SkillsCovered__c = selectedSession.session.Skills_Covered_for_the_Session__c;
            //commented ref Task# T-417933
            //isr.Amount_of_Time__c = dosage;
        }

        try{
            upsert selectedSession.studentResults;
            CyUtil.successMessage('Your time has been entered successfully.');
        }catch(System.DMLException e){
            for(Integer i=0; i<e.getNumDml(); i++){
                CyUtil.errorMessage(e.getDMLMessage(i));
            }
        }

//        loadSectionData(section.ID);
    }

    public void startAddStudents(){
        addableStudents = new List<StudentInfoWrapper>();
        Set<ID> studentsInSession = new Set<ID>();
        for(Intervention_Session_Result__c isr:selectedSession.studentResults){
            if(isr.ID == null){
                studentsInSession.add(isr.Student_Section__r.ID);
            } else {
                studentsInSession.add(isr.Student_Section__c);
            }
        }

        for(StudentInfoWrapper sw:studentSections){
            if(!studentsInSession.contains(sw.studentSection.ID) && sw.studentSection.Active__c){
                sw.selected = false;
                addableStudents.add(sw);
            }
        }
    }

    public void addStudentsToSession(){
        Integer oldSessionSize = selectedSession.studentResults.size();
        for(StudentInfoWrapper sew: addableStudents){
            if(sew.selected){
                selectedSession.studentResults.add(
                        new Intervention_Session_Result__c(
                                Student_Section__r = sew.studentSection,
                                Amount_of_Time__c = (dosage!=null)?dosage:0,
                                Student_Section__c = sew.studentSection.ID
                        )
                );
            }
        }

        if(selectedSession.studentResults.size() == oldSessionSize){
            CyUtil.errorMessage('Please select a student to add to the session.');
        }
    }

    public void removeStudentFromSession(){
        system.debug(studentSectionIDToRemove);
        Intervention_Session_Result__c toDelete;
        for(Integer i=0;i<selectedSession.studentResults.size();i++){

            if(selectedSession.studentResults[i].Student_Section__c == studentSectionIDToRemove){
                toDelete = selectedSession.studentResults.remove(i);
                break;
            }
        }
        if(toDelete == null){
            CYUtil.errorMessage('The system was unable to locate the student to be deleted. Please reload the session and check that the student is still present.');
            return;
        }

        if(toDelete.ID != null){
            delete toDelete;
        }
    }

//=============================================Init skill functions==========================================================
    public void initAvaliableAndAllFields(){
        allPrimaryFields = new List<SelectOption>();
        avaliableFields = new List<SelectOption>();
        String schoolProgram = section.Account_Program__r.Name;
        ISTool.getAvaliableSkills(schoolProgram, avaliableFields, allPrimaryFields);
        allAvenuesOptions = ISTool.getAllAvenues();
        siteDetailsOptions = ISTool.getSiteDetailsOptions();
    }

    public void initSelectedFields(){
        selectedFields = new List<SelectOption>();
    }

    public void initializePicklist(){
        primarySkill = '';
        avaliableFields = new List<SelectOption>();
        selectedFields = new List<SelectOption>();
        allPrimaryFields = new List<SelectOption>();
        initAvaliableAndAllFields();
        initSelectedFields();
    }

    public void initAllPicklist(){
        primarySkill = '';
        availableStaff = new List<SelectOption>();
        avaliableFields = new List<SelectOption>();
        selectedFields = new List<SelectOption>();
        allPrimaryFields = new List<SelectOption>();
        allAvenuesOptions = new List<SelectOption>();
        siteDetailsOptions = new List<SelectOption>();
    }

    public Boolean initAvaliableStaff(Section__c sec){
        availableStaff = new List<SelectOption>();
        if(sec == null || sec.Staff_Section__r.isEmpty()){
            CyUtil.errorMessage('There are currently no active staff for this section.');
            return false;
        }

        for(Staff_Section__c s:sec.Staff_Section__r){
            availableStaff.add(new SelectOption(s.Staff__c, s.Staff__r.Name));
        }
        return true;
    }

    public PageReference getRecordPage() {
        String sessionRecordUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + sessionID ;
        PageReference sessionPage = new PageReference(sessionRecordUrl);
        return sessionPage;
    }
}