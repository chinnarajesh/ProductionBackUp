public with sharing class WeeklyDosageController {
    public static final String SEPARATOR = ', ';
    public static final String SEPKEY = '#';
    //Filter Holders
    public List<SelectOption> schools   {get;set;}
    public List<SelectOption> staff     {get;set;}
    public List<SelectOption> sections  {get;set;}
    public String selectedSchool        {get;set;}
    public String selectedStaff         {get;set;}
    public String selectedSection       {get;set;}
    public List<SelectOption>   siteDetailsOptions  {get; set; }
    
    public boolean timer {get; set;}
    //General
    private String profileName;
    private String userType;
    private Map<ID, Section__c> sectionMap;
    private Map<Integer, DayWrapper> tableHeaderMap;
    private List<Student_Section__c> studentSections;

    //Week table
    public Section__c currentSection                    {get;set;}
    public Date currentWeek                                         {get;set;}
    //need datepicker on the page, so we have to use an sobject...
    public Intervention_Session__c weekEndHolder        {get;set;}
    public List<DayWrapper> tableHeaders                            {get;set;}
    public List<SessionResultsWrapper> resultsData                  {get;set;}

    public transient static final String BEFORESTART = 'Cannot enter time for a date that falls before the section start date.';
    public transient static final String AFTEREND = 'Cannot enter time for a date that falls after the section end date.';
    public transient static final String FUTURE = 'Cannot enter time for a date in the future.';
    
    //Skills multipicklist values
    public String                   primarySkill                {get; set; }    
    public SelectOption[]           selectedFields              {get; set; }
    public SelectOption[]           avaliableFields             {get; set; }
    public SelectOption[]           allPrimaryFields            {get; set; }
    public String                   skills                      {get; set; }
    public String                   allAvenuesSelected          {get; set; }
    public String                   tutoringModelSelected       {get; set; }
    public String                   sessionTypeSelected         {get; set; }
    public String                   sessionFormatSelected       {get; set; }
    public String                   siteDetailsSelected         {get; set; }
    public List<SelectOption>       allAvenuesOptions           {get; set; }
    public Boolean showTutoringModel                            {get; set; }
    public Boolean showSiteDetails                              {get; set; }


    public WeeklyDosageController(){
        setupWeekValues(Date.today());
        determineUserType();

        if(userType != null){
            loadSchools();
        }
        initAvaliableFields();
        initSelectedFields();
        initAllAvenues();
        initSiteDetails();
        showTutoringModel = false;
        showSiteDetails = false;
    }

    public void initSiteDetails(){
        siteDetailsOptions = new List<SelectOption>();
        siteDetailsOptions = ISTool.getSiteDetailsOptions();

    }

    private void setupWeekValues(Date dayInWeek){
        currentWeek = dayInWeek.toStartOfWeek();
        weekEndHolder = new Intervention_Session__c(Date__c=currentWeek.addDays(6));

        tableHeaders = new List<DayWrapper>();
        tableHeaderMap = new Map<Integer, DayWrapper>();
        //added for multiselect picklist
        //initializePicklist();
        for(Integer i=0;i<7;i++){
            Date dayOfWeek = currentWeek.addDays(i);
            String formattedDate = DateTime.newInstance(dayOfWeek.year(), dayOfWeek.month(), dayOfWeek.day()).format('EEE (MM/d/yyy)').toUpperCase();
            DayWrapper day = new DayWrapper(currentWeek.addDays(i),formattedDate,getDayTitle(dayOfWeek),i+1);
            tableHeaders.add(day);
            tableHeaderMap.put(day.positionIdentifer, day);
        }
    }

    private String getDayTitle(Date day){
        if(String.isBlank(selectedSection)){
            if(day>Date.today()){
                return FUTURE;
            }
        } else {
            Section__c section = sectionMap.get(selectedSection);
            if(day>Date.today()){
                return FUTURE;
            } else if(day > section.End_Date__c){
                return AFTEREND;
            } else if(day < section.Start_Date__c){
                return BEFORESTART;
            }
        }
        return null;
    }

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
        } else { //yep real secure here... defaults to god mode, but that's how it works, so I can't change it
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
//          User u = [SELECT id, Site__c FROM User WHERE id=:UserInfo.getUserId()];
//          query += 'AND Site__c=\''+u.Site__c+'\'';
        }
        //base query is the full query for system users, so we don't need a check condition for them
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

    private void loadStaff(){
        if(selectedSchool != 'none'){
            for(Staff__c s : getStaffAtSchool(selectedSchool)){
                staff.add(new SelectOption(s.id, s.Name));
            }
        }

        if(selectedSchool == 'none'){
            staff.add(new SelectOption('none', 'Select Staff Member'));
            selectedStaff = 'none';
        } else if(staff.size() > 1){
            staff.add(0, new SelectOption('none', 'Select Staff Member'));
            selectedStaff = 'none';
        } else if(staff.size() == 1){
            selectedStaff = staff[0].getValue();
        }
        changeStaff();
    }

    private void loadSections(){
        if(selectedStaff != 'none'){
            sectionMap = new Map<ID, Section__c>();
            for(Staff_Section__c ss : getStaffSectionsForStaff(selectedStaff)) {
                sections.add(new SelectOption(ss.Section__r.ID, ss.Section__r.Name));
                sectionMap.put(ss.Section__r.ID, ss.Section__r);
            }
        }
        
        if(selectedStaff == 'none'){
            selectedSection = 'none';
            sections.add(new SelectOption('none', 'Select Section'));
        } else if(staff.size()>1){
            selectedSection = 'none';
            if(sections.isEmpty()){
                sections.add(new SelectOption('none', 'Select Section'));
            }else{
                sections.add(0,new SelectOption('none', 'Select Section'));
            }
        } else if(sections.size() == 1){
            selectedSection = sections[0].getValue();
        }
        changeSection();
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

    private List<Staff_Section__c> getStaffSectionsForStaff(ID staffID){
        return [SELECT Section__c, Section__r.Name, Section__r.Account_Program__r.Name,
                    Section__r.End_Date__c, Section__r.Start_Date__c,
                    Section__r.Intervention_Primary_Staff__c, Section__r.Auto_Name__c
                FROM Staff_Section__c
                WHERE Is_Active__c = true
                AND Section__r.Active__c = true
                AND Section__r.SkipDosage__c = false
                AND Section__r.RecordType.Name='Intervention Section'
                AND Staff__c =: staffID
                ORDER BY Section__r.Name];
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
        sections = new List<SelectOption>();
        if(!String.isBlank(selectedStaff)){
            loadSections();
        }
    }

    public void changeSection(){
        resultsData = new List<SessionResultsWrapper>();
        if(!String.isBlank(selectedSection) && selectedSection != 'none'){
            currentSection = sectionMap.get(selectedSection);
            //added to get skills
            initializePicklist();
            //load data
            loadSessionData();
            showTutoringModel = currentSection.Auto_Name__c.contains('Tutoring: Math') || currentSection.Auto_Name__c.contains('Tutoring: Literacy');
            showSiteDetails = siteDetailsOptions != null && siteDetailsOptions.size() > 0;

            //List<String> skillsSelected = new List<String>();
            //List<String> skillsAvailable = new List<String>();
            //for(SelectOption skill : avaliableFields){
            //  skillsAvailable.add(skill.getLabel());
            //}
            //for(SelectOption skill : selectedFields){
            //  skillsSelected.add(skill.getLabel());
            //}
            //String skillSelected = String.join(skillsSelected, ', ');
            //String skillAvailable = String.join(skillsAvailable, ', ');

            //for(DayWrapper dw : tableHeaders){
            //  dw.availableSkills = skillAvailable;
            //  dw.selectedSkills = skillSelected;
            //  dw.primarySkill = '';//clear primary skill for every new session
            //}
        }
    }

    public void loadSessionData(){
     
        if(String.isBlank(selectedSection) || selectedSection == 'none'){
            return;
        }
        resultsData = new List<SessionResultsWrapper>();
        setupWeekValues(currentWeek);
        loadStudentSections();
        Intervention_Session_Result__c[] results = getSessionData();
        processWeeklyData(results);

        //update the table list so we disable the rows that have data already.
        for(Integer i=0;i<tableHeaders.size();i++){
            tableHeaders[i] = tableHeaderMap.get(tableHeaders[i].positionIdentifer);
        }
    }

    private void loadStudentSections(){
        studentSections=
            [select id, Student_Name__c, Student__c, Section__r.Auto_Name__c
            from Student_Section__c
            where Active__c = true
            and Student__r.Active__c = true
            and Section__c =: selectedSection
            order by Student_Name__c, Student__c];
    }

    private Intervention_Session_Result__c[] getSessionData(){
        return [select Id, Amount_of_Time__c, Student_Section__c,
                    Student_Section__r.Student__r.Name,
                    Student_Section__r.Student__c,
                    Intervention_Session__r.Id,
                    Intervention_Session__r.Date__c,
                    Intervention_Session__r.Skill_Primary__c,
                    Intervention_Session__r.Skills_Covered_for_the_Session__c,
                    Intervention_Session__r.Comments__c,
                    Intervention_Session__r.All_avenues__c,
                    Intervention_Session__r.Tutoring_Model__c,
                    Intervention_Session__r.Session_Type__c,
                    Intervention_Session__r.Session_Format__c,
                    Intervention_Session__r.Site_Details__c
                from Intervention_Session_Result__c
                where Intervention_Session__r.Section__c =: selectedSection
                and Student_Section__c IN: studentSections
                and Intervention_Session__r.Date__c>=:currentWeek
                and Intervention_Session__r.Date__c<=:currentWeek.addDays(6)
                //group by Intervention_Session__r.Date__c,
                //      Student_Section__r.Student__c,
                //      Student_Section__r.Student__r.Name
                order by Student_Section__r.Student__r.Name, 
                        Student_Section__r.Student__c,
                        Intervention_Session__r.Date__c];
    }   

    private void processWeeklyData(Intervention_Session_Result__c[] results){
        //Don't like this, but I have to be able to detect any session result before I process any of them.
        Set<String> skillsAvailable = new Set<String>();
        for(SelectOption skill : avaliableFields){
            skillsAvailable.add(skill.getLabel());
        }
        //populate default dayinfo
        for(DayWrapper dayInfo: tableHeaderMap.values()){
            dayInfo.primarySkill = null;
            dayInfo.selectedSkills = '';
            dayInfo.availableSkills = String.join(new List<String>(skillsAvailable), SEPARATOR);
        }

        Map<Integer,Map<String, List<Intervention_Session_Result__c>>> studentDailyResults = new Map<Integer,Map<String, List<Intervention_Session_Result__c>>>();
        for(Intervention_Session_Result__c ar:results){
            Integer daysFromStart = currentweek.daysBetween(ar.Intervention_Session__r.Date__c);
            if(!studentDailyResults.containsKey(daysFromStart)){
                studentDailyResults.put(daysFromStart, new Map<String, List<Intervention_Session_Result__c>>());
            }
            if(!studentDailyResults.get(daysFromStart).containsKey((String)ar.Student_Section__r.Student__c)){
                studentDailyResults.get(daysFromStart).put((String)ar.Student_Section__r.Student__c, new List<Intervention_Session_Result__c>());
            }
            studentDailyResults.get(daysFromStart).get((String)ar.Student_Section__r.Student__c).add(ar);
        }
        for(Student_Section__c ss: studentSections){
            ID studentID = ss.Student__c;
            ISRWrapper[] dosages = new ISRWrapper[7];
            for(Integer i=0;i<7;i++){
                DayWrapper dayInfo = tableHeaderMap.get(i+1);
                List<Intervention_Session_Result__c> isrs = (studentDailyResults.containsKey(i) && studentDailyResults.get(i).containsKey(studentID))?
                    studentDailyResults.get(i).get(studentID): new List<Intervention_Session_Result__c>();
                Decimal amount = 0;
                for(Intervention_Session_Result__c isr: isrs){
                    amount += isr.Amount_of_Time__c>=0? isr.Amount_of_Time__c: 0;
                }
                Intervention_Session_Result__c isr = isrs.size()==1? isrs.get(0):
                    new Intervention_Session_Result__c(Student_Section__c = ss.ID, Amount_of_Time__c = isrs.size()==0? null: amount);
                dayInfo.session = isrs.size()==1? isr.Intervention_Session__r: dayInfo.session;
                dayInfo.primarySkill = isrs.size()==1? isr.Intervention_Session__r.Skill_Primary__c: dayInfo.primarySkill;
                dayInfo.selectedSkills = isrs.size()==1? isr.Intervention_Session__r.Skills_Covered_for_the_Session__c: dayInfo.selectedSkills;
                dayInfo.selectedSkills = String.isNotBlank(dayInfo.selectedSkills)? dayInfo.selectedSkills: '';
                List<String> skillsSelected = dayInfo.selectedSkills.split(SEPARATOR);
                Set<String> skillsAvailables = skillsAvailable.clone();
                skillsAvailables.removeAll(skillsSelected);
                dayInfo.availableSkills = String.join(new List<String>(skillsAvailables), SEPARATOR);
                dayInfo.isDisabled = isrs.size()>1;//studentDailyResults.containsKey(i) || String.isNotBlank(dayInfo.title);//disable dossage
                dosages[i] = new ISRWrapper(
                    isr,
                    dayInfo.isDisabled,//true,
                    dayInfo.title,
                    dayInfo.day.format(),
                    isrs.size()==0? null: amount//amount
                );
            }

            SessionResultsWrapper holder = new SessionResultsWrapper(ss.Student_Name__c,ss.Student__c,ss.ID);
            holder.dosages = dosages;
            resultsData.add(holder);
        }
    }

    public void saveNewSessions(){
      timerOn();
       String flag='proceed false';
       Boolean primarySkillIsEmpty;
        Set<Integer> daysToSave = new Set<Integer>();
        Map<Integer, Intervention_Session__c> sessionsToSave = new Map<Integer, Intervention_Session__c>();
        for(DayWrapper day: tableHeaders){
          
          System.debug('day##'+day.day);
          System.debug('day.isProceed===='+day.isProceed);
             primarySkillIsEmpty = String.isBlank(day.primarySkill);
            
            if( day.day <= System.today() && day.isDisabled==false && day.isProceed==true && (!primarySkillIsEmpty ||
               (primarySkillIsEmpty&& day.session.All_avenues__c !='' ))){
                day.session.Skills_Covered_for_the_Session__c = day.selectedSkills;
                day.session.Skill_Primary__c = !primarySkillIsEmpty ? day.primarySkill: null;
                
                daysToSave.add(day.positionIdentifer);
                if(day.session.ID == null && sectionMap!=null && sectionMap.containsKey(selectedSection)){ //this fixes issues because an error was thrown later on.
                    day.session.Session_Time_Completed_For__c = sectionMap.get(selectedSection).Intervention_Primary_Staff__c;
                    day.session.Section__c = selectedSection;
                }
                day.isError = day.isProceed;
                sessionsToSave.put(day.positionIdentifer, day.session.clone(true, false));
                flag='proceed true';
            }
            
             if(day.day <= System.today() && day.isProceed==false && flag =='proceed false'){
                 flag='data not mapped';
             }
            
             if(day.day > System.today() &&  day.isProceed==true){
                flag='true';
            }
            System.debug('sessionsToSave##'+sessionsToSave);
            
        }
       
        Savepoint sp = Database.setSavepoint();
        try{
            upsert sessionsToSave.values();
        } catch(System.DMLException e){
            for(Integer i=0; i<e.getNumDml(); i++){
                CYUtil.errorMessage(e.getDmlMessage(i));
            }           
            CYUtil.errorMessage('There was an error while trying to save your sessions. Please check your data and try again.');
            return;
        }

        Map<String, Intervention_Session_Result__c> resultsToSave = new Map<String, Intervention_Session_Result__c>();
        Boolean hasBadResults = false;
        for(SessionResultsWrapper srw: resultsData){
            for(Integer i=0;i<7;i++){
                String key = srw.studentId+SEPKEY+i;
                ISRWrapper rw = srw.dosages[i];
                Decimal amountOfTime = rw.isr.Amount_of_Time__c;
                Id isrID = rw.isr.Id;
                
                if((amountOfTime != null && amountOfTime != rw.amount)
                        && (isrID != null || daysToSave.contains(i+1))){
                    if(isrID == null){
                        System.debug('allAvunes Options');
                        Intervention_Session__c session = sessionsTosave.get(i+1);
                        rw.isr.Intervention_Session__c = session.ID;
                        //added to update skills to Intervention Session Result
                        rw.isr.SkillsCovered__c = session.Skills_Covered_for_the_Session__c;
                    }
                   
                    tableHeaders[i].isError = false;
                    resultsToSave.put(key, rw.isr.clone(true, false));
                }
                
                else if(!daysToSave.contains(i+1) && !rw.isDisabled){
                     
                      if(amountOfTime != null && isrID == null){
                        //System.debug('Not selected Allavunues Options');
                        tableHeaders[i].isError = true;
                        hasBadResults = true;
                        if(flag=='data not mapped'){
                            CYUtil.errorMessage('Please confirm whether service happened In-Person Service or Virtual Service by clicking on the blue speech bubble next to a date column.');
                         }
                        if(flag=='true'){
                        CYUtil.errorMessage('Cannot enter time for a date in the future.');
                       }
                        //CYUtil.errorMessage('You have entered time for '+currentWeek.addDays(i).format()+' but have not populated the skills covered. Please enter the skills covered.');
                         loadSessionData();
                   }
                }
                //System.debug('daysToSave##'+daysToSave);
                //System.debug('rw.isDisabled##'+rw.isDisabled);
                //System.debug('amountOfTime##'+amountOfTime);
                //System.debug('isrID##'+isrID);
            }
        }

        Boolean hasNoSessions = sessionsToSave.isEmpty();
        Boolean hasNoResults = resultsToSave.isEmpty();
        for(DayWrapper day: tableHeaders){
            hasNoResults = hasNoResults || day.isError;
        }
        system.debug('hasBadResults'+hasBadResults);
        system.debug('hasNoResults'+hasNoResults);
        //if(hasNoSessions && hasNoResults){
        //   CYUtil.errorMessage('In order to save, click on the blue bubble by the date and enter the skills covered.');
        //   CYUtil.errorMessage('Please select primary skill.');
        //}
        //if(hasNoResults){ 
        //CYUtil.errorMessage('Please enter time.'); 
        //}
        if(hasBadResults ){
            Database.rollback(sp);
            return;
        }

        try{
            upsert resultsToSave.values();
        } catch(System.DMLException e){
            Database.rollback(sp);
            for(Integer i=0; i<e.getNumDml(); i++){
                CYUtil.errorMessage(e.getDmlMessage(i));
            }           
            CYUtil.errorMessage('There was an error while trying to save your sessions. Please check your data and try again.');
            return;
        }
        //populate id from cloned objects
        for(Integer pos: sessionsToSave.keySet()){//update id
            tableHeaderMap.get(pos).session.Id = sessionsToSave.get(pos).Id;
        }           
        for(SessionResultsWrapper srw: resultsData){//update ids
            for(Integer i=0;i<7;i++){
                String key = srw.studentId+SEPKEY+i;
                if(resultsToSave.containsKey(key)){
                    srw.dosages[i].isr.Id = resultsToSave.get(key).Id;
                }
            }
        }
        
        CYUtil.successMessage('All changes have been saved successfully.');

        loadSessionData();
        
    }
     public void clearMessage(){
        ApexPages.getMessages().clear();

    }

    public void timerOn(){
        timer = true;
    }

    public void timerOff(){
        timer = false;
    }

    public PageReference resetPage(){
        PageReference returnPage = Page.IM_weekly;
        returnPage.setRedirect(true);
        return returnPage;
    }

    public void changeWeek(){
        if(weekEndHolder.Date__c!=null){
            currentWeek = weekEndHolder.Date__c.toStartOfWeek();
            loadSessionData();
        } else {
            CYUtil.errorMessage('Please select a week to view.');
        }
    }

    public void lastWeek(){
        if(weekEndHolder.Date__c != null){
            weekEndHolder.Date__c = weekEndHolder.Date__c.addDays(-7);
        }
        
        changeWeek();
    }

    public void nextWeek() {
        if(weekEndHolder.Date__c != null){
            weekEndHolder.Date__c = weekEndHolder.Date__c.addDays(7);
        }
        
        changeWeek();
    }

    public void toggleSortDirection(){
        List<SessionResultsWrapper> holder = new List<SessionResultsWrapper>();
        for(Integer i=resultsData.size()-1;i>=0;i--){
            holder.add(resultsData[i]);
        }
        resultsData = holder;
    }
    
    //*****************************************************************************
    //Wrapper classes

    public class SessionResultsWrapper{
        public List<ISRWrapper> dosages {get;set;}
        public String studentId         {get;set;}
        public String studentName       {get;set;}

        private String studentSectionID;

        public SessionResultsWrapper(String studentName, String studentID, ID studentSectionID){
            this.studentName = studentName;
            this.studentID = studentID;
            this.studentSectionId = studentSectionID;
            this.dosages = new ISRWrapper[7];
        }
    }

    public class DayWrapper{
        public Integer      positionIdentifer                   {get;set;}
        public Date         day                                 {get;set;}
        public String       displayHeader                       {get;set;}
        public String       title                               {get;set;}
        public Boolean      isDisabled                          {get;set;}
        public Intervention_Session__c session                  {get;set;}
        public String       availableSkills                     {get;set;}
        public String       selectedSkills                      {get;set;}
        public String       primarySkill                        {get;set;}
        public String       tutoringModel                       {get;set;}
        public String       sessionType                         {get;set;}
        public String       sessionFormat                       {get;set;}
        public String       siteDetails                         {get;set;}
        public Boolean      isProceed                           {get;set;}
        public Boolean      isError                             {get;set;}

        public DayWrapper(Date dayOfWeek, String displayHeader, String title, Integer positionIdentifer){
            this.day = dayOfWeek;
            this.displayHeader = displayHeader;
            this.title = title;
            this.isDisabled = title!=null;
            this.positionIdentifer = positionIdentifer;
            this.primarySkill = null;
            this.isProceed = false;
            this.isError = false;
            session = new Intervention_Session__c(Date__c = dayOfWeek);
            //this.availableSkills = availableSkills;
            //this.selectedSkills = selectedSkills;
        }
    }

    public class ISRWrapper{
        public Intervention_Session_Result__c   isr                 {get;set;}
        public Boolean                          isDisabled          {get;set;}
        public String                           title               {get;set;}
        public String                           dateString          {get;set;}
        public Decimal                          amount              {get;set;}

        public ISRWrapper(Intervention_Session_Result__c isr, Boolean isDisabled, String msg, String dateString, Decimal amount){
            this.isr = isr;
            this.isDisabled = isDisabled;
            this.title = msg;
            this.dateString = dateString;
            this.amount = amount;
        }
    }
    
    public static final Map<String, String> mapSchoolProgram2Category = new Map<String, String>{
        'Tutoring: Literacy' => 'Literacy',
        'Tutoring: Math' => 'Math'
    };
    public static final String CATBEHAVIOR = 'SEL/Behavior and Attendance Interventions';
    public void initAvaliableFields(){
        avaliableFields = new List<SelectOption>();
        allPrimaryFields = new List<SelectOption>();

        String schoolProgram = (currentSection!=null)? currentSection.Account_Program__r.Name: '';
        String category = mapSchoolProgram2Category.containsKey(schoolProgram)? mapSchoolProgram2Category.get(schoolProgram): CATBEHAVIOR;
        Set<String> categoryList = new Set<String>{CATBEHAVIOR};
        categoryList.add(category);

        for(Skill__c s :[SELECT Id, Category__c, Name, IsPrimary__c FROM Skill__c 
                        WHERE Category__c IN :categoryList ORDER BY Name, Category__c ASC]){
            if(s.IsPrimary__c && s.Category__c == category){
                allPrimaryFields.add(new SelectOption(s.Id, s.Name));
            }
            avaliableFields.add(new SelectOption(s.Id, s.Name));
        }
    }
    
    void initSelectedFields(){
        selectedFields = new List<SelectOption>();
    }
    
    public void initializePicklist(){
        avaliableFields = new List<SelectOption>();
        selectedFields = new List<SelectOption>();
        allPrimaryFields = new List<SelectOption>();
        initAvaliableFields();
        initSelectedFields();
    }
    
    public void initAllAvenues(){
        allAvenuesOptions = new List<SelectOption>();
        allAvenuesOptions.add(new SelectOption('', 'None', true));
        Map<String, String> mapValues = CT_core_SoqlUtils.getPicklistValues('Intervention_Session__c' ,'All_avenues__c');
        for(String val: mapValues.keySet()){
            allAvenuesOptions.add(new SelectOption(val, mapValues.get(val)));
        }
    }    
}