/**
    ctlAddTimeFLow: Controls the diaglog flow for the Intervention - sessions application. 
*/

public without sharing class ctlAddTimeFlow_dev {
    public static final String SEPARATOR = ', ';
    public static final String SEPKEY = '#';
    private Map<ID, Section__c> sectionMap;
    public Section__c sect  { get;set; }//Added by Harsh Singh
    public Student_Section__c ss {get;set;}//Added by Harsh Singh
    public List<SessionList> searchResults{get;set;}//Added by Harsh Singh
    public Boolean showReport{get;set;}//Added by Harsh Singh to show or hide the report on the basis of the user license T-498243
    public ID reportID{get;set;}
    public Boolean srchop{get;set;}
    public Integer sessionDosage{get; set;} //BGR Declare variable to capture default session time
    public Boolean showTutoringModel{get;set;}
    public Boolean ShowStudentReport{get;set;}
    public Boolean showstudentButton{get;set;}
    public Boolean mainReportchat{get;set;}
    public Boolean titledisplay{get;set;}
    public Boolean showpopup{get;set;}
    public String                   primarySkill                {get; set; } 
    public string studentName {get;set;}
    public boolean showPopwindow {get;set;}
    /**
    *    Wrapper Classes
    */
    
    public class StudentWrapper{
        public boolean selected {get; set;}
        public Date sessiondate {get; set;}
        public Date curricilumDate {get; set;}
        public Student_Section__c stuSecRec {get; private set;}
        
        public StudentWrapper(boolean sel, Student_Section__c stu, Date sDt, Date cDt){
            stuSecRec = stu;
            selected = sel;
            sessiondate = sDt;
            curricilumDate = cDt;
        }
    }
    
    public class SessionList{
        public Intervention_Session__c intervSection{get;set;}
        public String studentList{get;set;}
        public String exitTicket{get;set;}
        public String Timevalue {get;set;}
        //Public String Primaryskill {get;set;}
    }
    /**/
     
    /**/
    /**
    *    Constructor
    */

    public ctlAddTimeFlow_dev(){
        setupWeekValues(Date.today());
        studentsInSection = new List<StudentWrapper>();
        showCalDatePicker = true; // show the calendar popup on the pageAddTime by default
        sect=new Section__c(); 
        ss=new Student_Section__c();
        srchop=false;
        ShowReport=false;
        isLoadPreviousSkills = false;
        showTutoringModel = false;

        studentsInCurriculum = new List<Curriculum__c>();
        studentsInCurriculumDeleted = new List<Curriculum__c>();
        
        initAllAvenues();
        initAvaliableFields();
        initSelectedFields();
        showPopwindow=false;
       
    }
   
    /**
    *    Page 1 BEGINS: Section List
    */
    public String sectionID {get; set;} 
    public String sectionName {get; set;}
    public String sectionNameEscaped {get {
        if (sectionNameEscaped.contains('\'') && !sectionNameEscaped.contains('\\\'')) {
            sectionNameEscaped = String.escapeSingleQuotes(sectionNameEscaped);
        }
        return sectionNameEscaped;
    }
        set;
    }
    public String sectionNickName {get; set;}
    public String sectionELT {get; set;}
    public Boolean showCalDatePicker {get; set;} // Utilized in pageAddTime VFP to show the calendar popup.  Tab Order not supported
    public Section__c currentSection {get; set;}

    private integer totalRecs = 0;     
    private integer index = 0;
    private integer blockSize = 10;  
    private Date passvalue;
    
    private String[] userIDs = null;
    private Staff__c loginStaff = null;
    
    public static String convert18To15ID(String lID){
        return lID.substring(0, 15);
    }

    public static String convert15To18ID(String sID){
        String CASE_DECODE_MATRIX = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456';
        String append = '';
        
        for (Integer block = 0; block < 3; block++){
            String str = sID.subString(block * 5, block * 5 + 5);
            Integer index = 0;
            
            for (Integer i = 1; i <=5 ; i++){
                Integer significance = 1 << (i-1);
                
                String character = str.subString(i-1, i);
                if (character.compareTo('A') >= 0 && character.compareTo('Z') <= 0){
                    index = index + significance;
                }
            }
            append = append + CASE_DECODE_MATRIX.subString(index, index+1);
        }
        return sID + append;
    }

    public String[] getCurrentUserIDs(){
        if (userIDs == null){
            userIDs = new String[2];
            // The line below is purely for debugging purpose.  It uses Adam Volunteer's user ID. 
            // String rUserId = '005c00000018EaE';
            String rUserId = UserInfo.getUserId();
            
            system.debug('KY ----- Raw User ID ' + rUserId);

            if (rUserId.length() == 18){
                userIDs[1] = rUserId;    
                userIDs[0] = convert18To15ID(rUserId);
            }else{
                userIDs[0] = rUserId;
                userIDs[1] = convert15To18ID(rUserId);
            }
        }

        system.debug('KY ----- 15 User ID ' + userIDs[0]);
        system.debug('KY ----- 18 User ID ' + userIDs[1]);

        return userIDs;
    }
    
    public Staff__c getCurrentStaff(){
        if (loginStaff == null){
            String[] uIDs = getCurrentUserIDs();
            List<Staff__c> found = [SELECT Id FROM Staff__c WHERE Individual__r.User__c IN :uIDs];
            if (found.size() > 0){
                loginStaff = found[0];
            }
        }
        return loginStaff;
    }
    
    // Utilized in pageSectionList VFP to display the list of sections available to add students and time to
    public List<Section__c> getSecList() { 
        String firstword ;    
        try {
            String[] currUserIDs = getCurrentUserIDs();
            List<Section__c> allMySections = [SELECT Id,name,In_After_School__c,Section_Nickname__c,School__c,Active__c,First_words__c,Account_Program__r.name
                FROM Section__c 
                WHERE RecordType.DeveloperName IN ('Intervention_Section','Curriculum')
                    AND SkipDosage__c = false 
                    AND ID IN (SELECT  Section__c FROM Staff_Section__c 
                        WHERE Staff__r.Individual__r.User_ID__c IN :currUserIDs
                        AND Section__r.Active__c = true
                        AND Is_Active__c = true
                    )
                ORDER BY Name Asc 
//                LIMIT :blockSize
//                OFFSET :index
            ];
            system.debug('HSB 1 - ' + allMySections);
            for(Section__c se:allMySections){
                se.Account_Program__r.name=se.Account_Program__r.name.remove('/');
                se.Account_Program__r.name=se.Account_Program__r.name.deleteWhitespace();
                se.Account_Program__r.name=se.Account_Program__r.name.replace(':','');
            }
            
            totalRecs = allMySections == null? 0: allMySections.size();
            system.debug('KY ----- Total # of Sections ' + totalRecs);

            return allMySections;
        } catch (QueryException e) {
            ApexPages.addMessages(e);
            return null;
        }
    }
   
    /**
    *    Navigation Action: From Section List ---> Section Detail/Enrolled Students
    */
    // Navigation action when user clicks on the link in the pageSectionList VFP. 
    // It calls the helper method findEnrolledStudentsForSection to populate the list of students enrolled to display
    // in pageSectionStudents VFP
    public PageReference doSectionStudents() {
        findEnrolledStudentsForSection();
        showstudentButton=true;
        mainReportchat=true;
        //Logic to add the report to the page
        List<Profile> prfil=[SELECT Name FROM Profile where UserLicenseId in 
                                    (SELECT Id FROM UserLicense where name ='Customer Community')];
        Set<String> profileName=new Set<String>();

        for (Profile pr : prfil) {
            profileName.add(pr.Name);
        }
        Id id1 = userinfo.getProfileId();
        Profile p = [select Name from profile where id = :id1];
        String str1 = String.valueOf(p.Name);

        System.debug('profileList'+prfil+'ProfileName'+str1);

        if (profileName.contains(str1) == false) {
            showReport=true;
            //query the report ID//'Corps Edition Report1'
            Report rt = [Select ID from Report where Name = :Label.Student_Corps_Edition_Portal_Report Limit 1];
            reportID = rt.ID;
           
        } else {
            showReport=false;
        }

        return currentSection.In_After_School__c=='Curriculum'? Page.CY_StudentCurriculums: Page.CY_Students;
    }
    ///////////////// Rajesh juturi added //////////////////////
    public string searchstudentName {set;get;}
    public string studentSectionName {set;get;}
    public string studentId          {set;get;}
    public List<Student_Section__c> results {get; set;}
    //public List<Student_Section__c> studentResult {set;get;}
    
    
    public void search() {
        System.debug('contactname++'+searchstudentName);
         String NewStudentName = '%'+searchstudentName+'%';
         System.debug('new section+++'+sectionID);
        showPopwindow=true;
     results = [SELECT Student_Name__c, Student_Id__c,Student__r.School_Name__c,Student_Grade__c,Student__c FROM Student_Section__c WHERE Section__c =:sectionID and Student_Name__c LIKE :NewStudentName];
        System.debug('new data+++'+results);
    }
    public PageReference cancelPopUp() {
        showPopwindow=false;
        
        return null;
    }
    
    public PageReference ContactNamepassing(){
        System.debug('contactname2**'+studentSectionName);
        System.debug('studentId%%%'+studentId);
        searchstudentName=studentSectionName;
        showPopwindow=false;
        return null;
    }
    ////////////////// ended by Rajesh juturi //////////////////////

    /**
    *    Page Local Actions
    */
    public PageReference Beginning(){
        index = 0;
        return null;
    }
    
    public PageReference Previous(){
        index -= blockSize;
        system.debug('KY---Previous ' + index);
        return null;
    }
    
    public PageReference Next(){
        index += blockSize;
        system.debug('KY---Next ' + index);
        return null;
    }

    public PageReference End(){
        Integer lastRecs = math.mod(totalRecs,blockSize);
        index = lastRecs == 0? totalrecs -blockSize: totalrecs -lastRecs;
        //if(math.mod(totalRecs,blockSize)==0)
        //    index= totalrecs -blockSize; 
        //else
        //    index = totalrecs - math.mod(totalRecs,blockSize);
         return null;
    }        
    
    public boolean getprev(){//this will disable the previous and beginning buttons
        if (index>0) return false; else return true;
    }  
    
    public boolean getnxt(){//this will disable the next and end buttons
        return (index + blockSize >= totalrecs)? true: false;
    } 

    public Integer getTotal_size() {
        return totalrecs;
    }
 
    public Integer getPageNumber() {
        return index/blockSize + 1;
    }
 
    public Integer getTotalPages() {
        return (totalrecs/blockSize) + (Math.mod(totalrecs, blockSize) > 0? 1: 0);
    }        
    /**
    *    Page 1 ENDS: Section List
    */

    
    /**
    *    Page 2 BEGINS: Section Detail
    */
    public List<Section__c> staffInSectionList { get; private set; }
    public List<StudentWrapper> studentsInSection { get; private set; }
    
    public List<Student_Section__c> selectedstudents { get; private set; }

    /**
    *    Navigation Action: From Section Detail/Enrolled Students ---> Add Time
    */
    
    //Navigation action from the pageSectionStudents VFP to add selected students (checkboxes) to the pageAddTime VFP
    public String slctdStdId{get;set;    }
    
    public PageReference dogetstdata() { 
        return Page.CY_AddTime;
    }

    public String checkState{get;set;}
    
    public PageReference doStudentsAddTime() {//Added by Harsh singh to fix multiselect value
       showTutoringModel = currentSection.Auto_Name__c.contains('Tutoring: Math') || currentSection.Auto_Name__c.contains('Tutoring: Literacy');
       System.debug('@@@@selected ID'+slctdStdId); 
       Set<String> setOfIds = String.isNotBlank(slctdStdId)? new Set<String>(slctdStdId.split(',')): new Set<String>();
        for (StudentWrapper ss : studentsInSection){
            ss.selected = setOfIds.contains(ss.stuSecRec.Student__c);
        }
        if(String.isBlank(slctdStdId)){
            checkState='';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Select the Students')); 
            return Page.CY_Students;
        }
       
        //initialize multiselect picklist values
        if(!isLoadPreviousSkills){
            studentSelectedSkills = '';
            primaryField = '';
        }
        getSelectedStudents();
        
       // slctdStdId='';
        initAvaliableFields();
        initSelectedFields();
        initAllAvenues();
        initSiteDetails();
        changeSection();
        
        return Page.CY_AddTime;
    }
    /// Added by juturi rajesh  *************///
    public PageReference addweeklyTime(){
        
        if(!isLoadPreviousSkills){
            studentSelectedSkills = '';
            primaryField = '';
        }

        initAvaliableFields();
        initSelectedFields();
        initAllAvenues();
        initSiteDetails();
        changeSection();

        return page.CY_AddWeeklyTime;

    }
    Set<string> studentIdSet = new Set<string>();
    public Pagereference StudentReportChart(){
        if(String.isBlank(slctdStdId)){
            checkState='';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Select the Students')); 
            ShowStudentReport=true;
            showReport=true;
            showstudentButton=true;
            mainReportchat=true;
            return Page.CY_Students;
       }
        ShowReport=false;
        ShowStudentReport=false;
        mainReportchat=false;
        showstudentButton=false;
        titledisplay=true;
        System.debug('*******selected ID'+slctdStdId); 
        studentIdSet = String.isNotBlank(slctdStdId)? new Set<String>(slctdStdId.split(',')): new Set<String>();
        System.debug('StudentIdset****'+studentIdSet);
        
         return Page.CY_Students;
    }
    //// edded by juturi rajesh *******************/////////////

    /**
    *    Navigation Action: From Section Detail/Enrolled Students ---> Session List
    */
    // Navigation action from the pageSectionStudents VFP to show the list of intervention sessions where time has been tracked
    public PageReference doShowSessions() {
        showPopwindow=false;
        searchstudentName=null;
        currentSection = new Section__c();
        currentSection =[select id,name,School__c,Start_Date__c,End_Date__c from Section__c where id =: sectionID];
        sect.Start_Date__c = null;
        sect.End_Date__c = null;
        sect.Intervention_Primary_Staff__c = null;
        //ss =[select id,name,Student__c from Student_Section__c where Section__c =: sectionID];
        ss.Student__c = null;
        searchResults=null;
        System.debug('sectSchool***'+sect.School__c);
        sect.School__c = currentSection.School__c;
        isLoadPreviousSkills = false;
        System.debug('curentSchool^^^'+currentSection.School__c);
        return Page.CY_Session;//Added by Harsh Singh on 10 th May 2016
        /*PageReference pg = new PageReference('/apex/CY_Session');
        pg.setRedirect(true);
        return pg;*/
    }
    public PageReference backToSession(){
        currentSection = new Section__c();
        currentSection =[select id,name,School__c,Start_Date__c,End_Date__c from Section__c where id =: sectionID];
        System.debug('curentSchool^^^'+currentSection.School__c);
        System.debug('sectSchool***'+sect.School__c);
        sect.School__c = currentSection.School__c;
        return Page.CY_Session;
    }

    /**
    *    Navigation Action: From Section Detail/Enrolled Students ---> Section List
    */
    // Navigation action on the cancel buttons of pageSectionStudent VFP - sends user back to the list of sections
    public PageReference doStudentsCancel() {
        isLoadPreviousSkills = false;
        //showCalDatePicker = true;
        ShowStudentReport=true;
        return Page.CY_Sections;
    }
    public Pagereference gototheReportchart(){
        ShowStudentReport=true;
        showReport=true;
        showstudentButton=true;
        mainReportchat=true;
        titledisplay=false;
        return Page.CY_Students;
    }
    public PageReference Openpopup(){
        System.debug('show popUp');
        showpopup=true;
        return Page.CY_AddTime;

    }
    
    /**
    *    Private Business Method
    */
    // Helper method to find the students to display in the pageSectionStudents VFP
    private void findEnrolledStudentsForSection(){
        system.debug('KY---Section: ' + sectionID);
        currentSection = [SELECT s.Id, s.Auto_Name__c, s.Start_Date__c, s.End_Date__c, s.Program__c, s.Intervention_Primary_Staff__c,
            School__c, In_After_School__c, Active__c, RecordTypeID,
            (    SELECT Active__c, Name, Student__c, Student__r.Local_Student_ID__c,
                    Student__r.Student_Id__c, Section__c, Student_Name__c, Student_Grade__c,
                    Intervention_Enrollment_Start_Date__c, Enrollment_Start_Date__c, Enrollment_End_Date__c,
                    Dosage_to_Date__c, Student__r.Exit_Date__c, Student__r.Id, Student__r.Name
                    From Student_Section__r
                    WHERE Student__r.Active__c = TRUE
                    AND Active__c = TRUE
                    ORDER BY Student__r.Student_First_Name__c ASC),
            (   SELECT Id, Student__c, Section__c, Student_Section__c, Curriculum_Name__c, Module_Name__c,
                    Module_Assignments__c, Date_of_Module__c, Module_Score__c, Comments__c
                    FROM Curriculums__r
                    ORDER BY Date_of_Module__c DESC, Student__r.Student_First_Name__c ASC),
            (   SELECT Is_Active__c, Staff__r.Name, Intervention_Primary_Staff__c 
                    From Staff_Section__r)
            FROM Section__c s WHERE Id =:sectionID and Active__c = true];

        Map<Id, AggregateResult> mars = new Map<Id, AggregateResult>(
                [SELECT Student_Section__c Id, MAX(Intervention_Session_Date__c) MaxDate
                FROM Intervention_Session_Result__c 
                where Student_Section__c IN :currentSection.Student_Section__r GROUP BY Student_Section__c]);
        System.debug('>>>> mars '+ mars);
        
        mapStudentToCurriculums = new Map<String, List<Curriculum__c>>();
        for(Curriculum__c curr: currentSection.Curriculums__r){
            if(!mapStudentToCurriculums.containsKey(curr.Student__c)){
                mapStudentToCurriculums.put(curr.Student__c, new List<Curriculum__c>());
            }
            mapStudentToCurriculums.get(curr.Student__c).add(curr);
        }

        studentsInSection.clear();
        for (Student_Section__c ss : currentSection.Student_Section__r){
            if(!mapStudentToCurriculums.containsKey(ss.Student__c)){
                mapStudentToCurriculums.put(ss.Student__c, new List<Curriculum__c>());
            }
            System.debug('KY---StudentSectionName:' + ss.Name);
            passvalue = (Date)(mars.containsKey(ss.Id)? mars.get(ss.Id).get('MaxDate'): null);
            System.debug('KY---MaxDate' + passvalue);
            Date curricilumDt = mapStudentToCurriculums.get(ss.Student__c).isEmpty()? null: mapStudentToCurriculums.get(ss.Student__c)[0].Date_of_Module__c;
            StudentWrapper w = new StudentWrapper(false, ss, passvalue, curricilumDt);
            studentsInSection.add(w);
        }

    }

    /**
    *    Page 2 ENDS: Section Detail
    */

    /**
    *    Page 3 BEGINS: SessionList
    */
    public String updateSessionID {get; set;}
//updated by harsh Singh for T-497423    
    public List<SessionList> getSessionList() {
        try {
            List<SessionList> sessList=new   List<SessionList>();
            Map<Id, String> stsectionmap=new  Map<Id, String>();
            Map<Id,String>stsectionExitMap = new Map<Id,String>();
            Map<Id,String> studenttimeMap = new Map<Id,String>();
            Map<Id,String> primaryskillMap = new Map<Id,String>();
            Set<ID> intervIds=new Set<ID>();
            System.debug('sectionID====>'+sectionID);
            List<Intervention_Session__c> interv = [SELECT Id, Name, LastModifiedDate, Date__c,
                    Session_Time_Completed_For__r.Name, Section__c, Section__r.Name,Comments__c,Skill_Primary__c,Skills_Covered_for_the_Session__c,
                    Session_Type__c,Session_Format__c,Site_Details__c,Section__r.Time__c,All_avenues__c,Tutoring_Model__c,Skill_Primary__r.name
            FROM Intervention_Session__c
            WHERE Section__c = :sectionID
            ORDER BY Date__c desc, LastModifiedDate DESC
                    /* LIMIT :blockSize
                     OFFSET :index*/
            ];
            for(Intervention_Session__c inter : interv){
                intervIds.add(inter.ID);
            }
            System.debug('Student***'+ss.Student__c);
            for(Intervention_Session_Result__c st : [SELECT Id,
                    Related_Student_s_Name__c,
                    Intervention_Session__c,Exit_Ticket__c,Amount_of_Time__c,Primary_Skill__c
                    FROM Intervention_Session_Result__c
                    WHERE Intervention_Session__c= :intervIds]){
                    
                if(stsectionmap.containsKey(st.Intervention_Session__c)){
                    String str =String.valueOf(st.Related_Student_s_Name__c);
                    String str2=stsectionmap.get(st.Intervention_Session__c)+','+str;
                    stsectionmap.put(st.Intervention_Session__c,str2);
                }else{
                    stsectionmap.put(st.Intervention_Session__c,st.Related_Student_s_Name__c);
                }
                if(st.Exit_Ticket__c!=null && st.Exit_Ticket__c!=''){
                If(stsectionExitMap.containsKey(st.Intervention_Session__c)){
                    String exitticket = String.valueOf(st.Exit_Ticket__c);
                    String sectionexit = stsectionExitMap.get(st.Intervention_Session__c)+','+exitticket;
                    stsectionExitMap.put(st.Intervention_Session__c,sectionexit);
                }
                else{
                     stsectionExitMap.put(st.Intervention_Session__c,st.Exit_Ticket__c);
                }
                }

               if(studenttimeMap.containsKey(st.Intervention_Session__c)){
                     string Timevalue = String.valueOf(st.Amount_of_Time__c);
                     string sectiontime = studenttimeMap.get(st.Intervention_Session__c)+','+Timevalue;
                     studenttimeMap.put(st.Intervention_Session__c,sectiontime);
                 }
                else
                 {
                     studenttimeMap.put(st.Intervention_Session__c,string.valueOf(st.Amount_of_Time__c));
                 }
                //  if(st.Primary_Skill__c != null && st.Primary_Skill__c !=''){
                //  If(primaryskillMap.containsKey(st.Intervention_Session__c)){
                //     string Primaryskill = String.valueOf(st.Primary_Skill__c);
                //     string sectionprimarySkill = primaryskillMap.get(st.Intervention_Session__c)+','+Primaryskill;
                //     primaryskillMap.put(st.Intervention_Session__c,sectionprimarySkill);
                //  }
                //  else{
                //  primaryskillMap.put(st.Intervention_Session__c,st.Primary_Skill__c);
                //  }
                //  }
                
             }
     
            for(Intervention_Session__c iter : interv){
                SessionList slt=new SessionList();
                 
                if(stsectionmap.containsKey(iter.ID) && studenttimeMap.containsKey(iter.ID)){
                    slt.intervSection=iter;
                    slt.studentList=stsectionmap.get(iter.ID);
                    slt.Timevalue=findmax(studenttimeMap.get(iter.ID));
                   
                    sessList.add(slt);
                   }
                //if(stsectionExitMap.containsKey(iter.ID)){
                //slt.exitTicket=stsectionExitMap.get(iter.ID);
                //sessList.add(slt);
                //}
                //if(studenttimeMap.containsKey(iter.ID)){
                //slt.Timevalue=studenttimeMap.get(iter.ID);
                //sessList.add(slt);
                //}
                //if(primaryskillMap.containsKey(iter.ID)){
                //slt.Primaryskill=primaryskillMap.get(iter.ID);
                //sessList.add(slt);
                //}
                
            }
           system.debug('##sessList'+sessList);
            //Added for T-498243
            totalRecs = sessList.size();//[select count() from Intervention_Session__c WHERE Section__c = :sectionID] ;
            system.debug('KY---Total ' + totalRecs);
            return sessList;

        } catch (QueryException e) {
            ApexPages.addMessages(e);
            return null;
        }
        
    }
    Public string findMax(String valueString){
    
      List<integer> samplevalues = new list<integer>();
        for(String s:valueString.split(',')){
         samplevalues.add(integer.valueof(s));
        }

       Integer maxvalue = samplevalues[0];
        For (integer i =0;i<samplevalues.size();i++)
        {
            
            if( samplevalues[i] > maxvalue){
                maxvalue = samplevalues[i];  
               Break;           
        }
        }    
         system.debug('the max value is'+maxvalue);  
        Integer mini =samplevalues[0];
       
       For (integer i =0;i<samplevalues.size();i++)
        {
            
            if( samplevalues[i] < maxvalue){
                mini = samplevalues[i];  
               Break;           
        }
        }  
        
       String maxminString=''+mini+', '+maxvalue;
       System.debug('maxminString'+maxminString);
        Return maxminstring;
       }
    
    //logic for Search Criteria by Harsh Singh
    public void searchSession(){
        ss.Student__c=null;
        results=null;
        System.debug('search resulrt');
        System.debug('@@@@@@@@'+'Insearch Section'+sectionID);
        System.debug('studentId===='+studentId);
        System.debug('new Student++'+searchstudentName);
        String NewStudentName = '%'+searchstudentName+'%';
        if(String.isBlank(searchstudentName)){
            studentId=null;
        }
        if(!String.isBlank(searchstudentName)){
            results = [SELECT Student_Name__c, Student_Id__c,Student__r.School_Name__c,Student_Grade__c,Student__c FROM Student_Section__c WHERE Section__c =:sectionID and Student_Name__c LIKE :NewStudentName];
        }
        if(!String.isBlank(searchstudentName) && results.isEmpty()){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Student cannot be found in this session.'));
            studentId=null;
        }
        System.debug('data result'+results);
        if(!String.isBlank(searchstudentName) && studentId ==null){
            for(Student_Section__c sec : results){
                if(sec.Student_Name__c != null){
                    ss.Student__c=sec.Student__C;
                  }
                  else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Student cannot be found in this session.'));
                  }
            }
        }
        else{
            ss.Student__c=studentId;
        }
        // if(!String.isBlank(searchstudentName) && ss.Student__c == null){
        //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Student cannot be found in this session.'));
        // }
        System.debug('studentname+++'+ss.Student__c);
        try {
            searchResults=new   List<SessionList>();
            Map<Id, String> stsectionmap=new  Map<Id, String>();
            Map<Id,String> searchExitMap = new Map<Id,String>();
            Map<Id,String> searchTimeMap = new Map<Id,String>();
            Map<Id,String> searchPrimaryMap = new Map<Id,String>();
            String querySession=' SELECT Id,Name,LastModifiedDate, Date__c,  Session_Time_Completed_For__r.Name, Section__c,Section__r.Name,Comments__c,Skill_Primary__c,Skills_Covered_for_the_Session__c,Session_Format__c,Site_Details__c,Session_Type__c,Tutoring_Model__c,All_avenues__c,Skill_Primary__r.name  FROM Intervention_Session__c  WHERE Section__c = :sectionID';
            String queryStSection='SELECT Student__r.Name , Section__c  FROM Student_Section__c where Section__c= :sectionID';
            List<Intervention_Session__c> interv;
            Set<ID> intervIds=new Set<ID>();
            Student__c student;
            Date strtDAte=Date.valueOf(sect.Start_Date__c);
            Date endDate=Date.valueOf(sect.End_Date__c);
            System.debug('sect.Start_Date__c++'+sect.Start_Date__c);
            System.debug('sect.End_Date__c+++'+sect.End_Date__c);
            Boolean exss=False;
            ApexPages.Message message=null;

            if(strtDAte!=null || endDate!=null  || sect.Intervention_Primary_Staff__c!=null ){
                querySession+=sect.Intervention_Primary_Staff__c!=null? ' AND Session_Time_Completed_For__c =\''+sect.Intervention_Primary_Staff__c+'\'':'';
                //exSect=true;
                if(strtDAte!=null && endDate!=null){
                    if(endDate>=strtDAte){   //query for the section
                        querySession+=' AND Date__c>=:strtDAte';
                        querySession+=' AND Date__c<=:endDate';
                    }else if(endDate<strtDAte){
                        //set the parameter and show error message
                        message = new ApexPages.Message(ApexPages.Severity.ERROR,System.Label.StartEndDateError);
                        ApexPages.addMessage(message);
                    }
                } else if(strtDAte==null && endDate!=null ){
                    querySession+=' AND Date__c<=:endDate';
                } else if(strtDAte!=null && endDate==null ){
                    querySession+=' AND Date__c>=:strtDAte';
                }
            }

            System.debug('sectionQuery'+querySession);
            interv =Database.query(querySession);
            for(Intervention_Session__c inter : interv){
                intervIds.add(inter.ID);
            }

            List<Intervention_Session_Result__c> stList = [SELECT ID, Related_Student_s_Name__c,Intervention_Session__c,Exit_Ticket__c,Amount_of_Time__c,Primary_Skill__c FROM Intervention_Session_Result__c where Intervention_Session__c= :intervIds];
            if(stList!=null){
                for(Intervention_Session_Result__c st : stList){
                    if(stsectionmap.containsKey(st.Intervention_Session__c)){
                        String str =String.valueOf(st.Related_Student_s_Name__c);
                        String str2=stsectionmap.get(st.Intervention_Session__c)+','+str;
                        stsectionmap.put(st.Intervention_Session__c,str2);
                    }else{
                        stsectionmap.put(st.Intervention_Session__c,st.Related_Student_s_Name__c);
                    }
                    if(st.Exit_Ticket__c != null && st.Exit_Ticket__c !=''){
                    if(searchExitMap.containsKey(st.Intervention_Session__c)){
                      String exitticket = String.valueOf(st.Exit_Ticket__c);
                      String sectionexit = searchExitMap.get(st.Intervention_Session__c)+','+exitticket;
                      searchExitMap.put(st.Intervention_Session__c,sectionexit);
                    }
                    else{
                    searchExitMap.put(st.Intervention_Session__c,st.Exit_Ticket__c);
                    }
                    }
                    if(searchTimeMap.containsKey(st.Intervention_Session__c)){
                     string Timevalue = String.valueOf(st.Amount_of_Time__c);
                     string sectiontime = searchTimeMap.get(st.Intervention_Session__c)+','+Timevalue;
                     searchTimeMap.put(st.Intervention_Session__c,sectiontime); 
                    }
                    else{
                     searchTimeMap.put(st.Intervention_Session__c,string.valueOf(st.Amount_of_Time__c));
                    }
                    // if(st.Primary_Skill__c != null && st.Primary_Skill__c !=''){
                    // if(searchPrimaryMap.containsKey(st.Intervention_Session__c)){
                    // string Primaryskill = String.valueOf(st.Primary_Skill__c);
                    // string searchPrimarySkill = searchPrimaryMap.get(st.Intervention_Session__c)+','+Primaryskill;
                    // searchPrimaryMap.put(st.Intervention_Session__c,searchPrimarySkill);
                    // }
                    // else{
                    // searchPrimaryMap.put(st.Intervention_Session__c,st.Primary_Skill__c);
                    // }
                    // }
                }
            }
            //Logic to filter Student Name
            //Retrieve Student name from student
            if(ss.Student__c!=null){
                System.debug('StudentId++'+ss.Student__c);
                student=[Select Name from Student__C where ID=:ss.Student__c] ;
                System.debug('studentName**'+student.name);
            }
            if(interv!=null){
                for(Intervention_Session__c iter : interv){
                    SessionList slt=new SessionList();
                    if( stsectionmap.containsKey(iter.ID)==true && searchTimeMap.containsKey(iter.ID) || searchExitMap.containsKey(iter.ID)){
                        System.debug('ItrId'+iter.id);
                        System.debug('stsectionmap++'+stsectionmap);
                        slt.intervSection=iter;
                        slt.studentList=stsectionmap.get(iter.ID);
                        slt.Timevalue=findmax(searchTimeMap.get(iter.ID));
                        slt.exitticket=searchExitMap.get(iter.ID);
                        //searchResults.add(slt);
                    }
                    System.debug('searchResults***'+searchResults);
                    if(ss.Student__c!=null){
                        System.debug('StudentList++'+slt.studentList);
                        if( slt.studentList.contains(student.Name)){
                            searchResults.add(slt);
                        }
                     }//else if(ss.Student__c==null){
                    //     System.debug('blankdata###');
                    //     searchResults.add(slt);
                    // }
                    else if(String.isBlank(searchstudentName) && strtDAte !=null){
                        searchResults.add(slt);
                    }
                     else if(String.isBlank(searchstudentName) && endDate !=null){
                        searchResults.add(slt);
                    }
                    else if(String.isBlank(searchstudentName) && sect.Intervention_Primary_Staff__c!=null){
                        System.debug('Intervention_Primary_Staff__c not equal to null');
                        searchResults.add(slt);
                    }
                    /*if(searchExitMap.containsKey(iter.ID)){
                     slt.exitticket=searchExitMap.get(iter.ID);
                     searchResults.add(slt);
                    }
                    if(searchTimeMap.containsKey(iter.ID)){
                     slt.Timevalue=searchTimeMap.get(iter.ID);
                     searchResults.add(slt);
                    }
                    if(searchPrimaryMap.containsKey(iter.ID)){
                    slt.Primaryskill=searchPrimaryMap.get(iter.ID);
                    searchResults.add(slt);
                    }
                    */
                }
            }
            if(String.isBlank(searchstudentName)){
                if(searchResults.size()==0){
                    if(message==null){
                        message = new ApexPages.Message(ApexPages.Severity.info,System.Label.Empty_Search_Reult);
                        ApexPages.addMessage(message);
                    }
                }
            }
            System.debug('@@@ searchResults: '+searchResults.size());
            totalRecs = [select count() from Intervention_Session__c WHERE Section__c = :sectionID] ;
            system.debug('KY---Total ' + totalRecs);

        } catch (QueryException e) {
            ApexPages.addMessages(e);
        }
        
    }

    /**
    *    Navigation Action: From Session List ---> Add Time
    */
    // Main action on the pageSessionList VFP
    public PageReference doUpdateSession() {
        initializePicklist();
        system.debug('KY---updateSessionID' +updateSessionID);

        showCalDatePicker = true;
        setCurrentSession(updateSessionID);

        // Added For MultiSelect Picklist.
        studentSelectedSkills = currentSession.Skills_Covered_for_the_Session__c;
        primaryField = currentSession.Skill_Primary__c;
        if(studentSelectedSkills == null) {
            studentSelectedSkills = '';
        }

        selectedFields.clear();
        List<String> theAvailableSkills = new List<String>();
        if(studentSelectedSkills != '') {
            for(String key : studentSelectedSkills.split(',')) {
                theAvailableSkills.add(key);
            }
        }
        for(SelectOption opt : avaliableFields) {
            theAvailableSkills.add(opt.getLabel());
        }
        theAvailableSkills.sort();

        Set<String> theUniqueSkills = new Set<String>();
        theUniqueSkills.addAll(theAvailableSkills);

        avaliableFields.clear();
        for(String theSkill : theUniqueSkills) {
            avaliableFields.add(new SelectOption(theSkill, theSkill));
        }

        return Page.CY_AddTime;
    }

    /**
    *    Navigation Action: From Session List ---> Section/Students
    */
    public PageReference doSessionListCancel() {
        ss.Student__c=null;
        results=null;
        studentId=null;
        showCalDatePicker = true;
        updateSessionID = null;
        findEnrolledStudentsForSection();
        return Page.CY_Students;
    }

    /**
    *    Page 3 ENDS: SessionList
    */

    /**
    *    Page 4 BEGINS: Session Detail (Add Time, Update Session)
    */
    //KY_TODO: Clean up these vars.

    public Date sessionDate { get; set;}
    public String sessionSkills { get; set;}
    public String sessionComment { get; set;}
    public Intervention_Session__c currentSession { get; set; }
    public Boolean isLoadPreviousSkills {get; set;}

    // Skills multipicklist values.
    public String               studentSelectedSkills   {get; set; }
    public SelectOption[]       selectedFields          {get; set; }
    public String               selectedFieldsitem      {get; set; }
    public String               primaryField            {get; set; }
    public SelectOption[]       avaliableFields         {get; set; }
    public SelectOption[]       allPrimaryFields        {get; set; }
    public List<Skill__c>       skillList               {get; set; }
    public List<SelectOption>   allAvenuesOptions       {get; set; }
    public List<SelectOption>   siteDetailsOptions      {get; set; }

    // List of students deleted.  Some of the deleted students may not be in the database yet: the user could add the student, then delete before save.
    public List<Intervention_Session_Result__c> studentsInSession {get; set;}
    private List<Intervention_Session_Result__c> studentsDeleted;

    /**
    *    Navigation Action: From Session Detail ---> Section Detail
    */
    // Primary action in pageAddTime for submitting time and skills
    //

    public PageReference doSessionSubmit() {
        //timerOn();
        System.debug('KY---currentSession.Date__c ' + currentSession.Date__c);
        System.debug('@@@ studentSelectedSkills: '+studentSelectedSkills);
        System.debug('@@@ Selected Fields => ' + selectedFieldsitem);
        //Added by Harsh Singh begin
        studentSelectedSkills = selectedFieldsitem;
        Set<String> theSelectedSkills = String.isBlank(selectedFieldsitem)? new Set<String>():
                new Set<String>(selectedFieldsitem.split(','));
        selectedFields = new List<SelectOption>();
        for(String str : theSelectedSkills) {
            selectedFields.add(new SelectOption(str, str));
        }
        selectedFieldsitem='';

        //Added by Harsh Singh end
        showCalDatePicker = true;
        isLoadPreviousSkills = false;

        //added for skills multiselect picklist
        Set<String> theAvailableSkills = new Set<String>();
        if(avaliableFields == null) {
            avaliableFields = new List<SelectOption>();
        }
        for(SelectOption skill : avaliableFields){
            theAvailableSkills.add(skill.getLabel());
        }

        // Validating skills selected by user.
        currentSession.Skill_Primary__c = primaryField;
        if(theAvailableSkills.size() > 0) {
            Set<String> toBeRemoved = new Set<String>();
            for(String theSelectedSkill : theSelectedSkills) {
                if(!theAvailableSkills.contains(theSelectedSkill)) {
                    toBeRemoved.add(theSelectedSkill);
                }
            }
            // Removing invalid skills.
            theSelectedSkills.removeAll(toBeRemoved);

            //if(theSelectedSkills.size() == 0) {
            //    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.CommunityAddTimeInvalidSkillsErrorMessageText ));
            //    return Page.CY_AddTime;
            //}
            currentSession.Skills_Covered_for_the_Session__c = String.join(new List<String>(theSelectedSkills), ',');
        }

        // check to ensure the date of the intervention is within the start and end date for this intervention
       

        if (currentSession.Date__c == null || currentSession.Date__c < currentSection.Start_Date__c ||
                currentSession.Date__c > currentSection.End_Date__c) {
            system.debug('KY---Invalid Session Date ' );
            currentSession.Date__c.addError('Date should be within the start and end of the section.');
            return Page.CY_AddTime;
        }

        // cannot be a date in the future
        if (currentSession.Date__c > Date.today()) {
            system.debug('KY---Invalid Date ' );
            currentSession.Date__c.addError('Date should not be in future.');
            return Page.CY_AddTime;
        }
        // Cannot have blank skills
        if(String.isBlank(currentSession.All_avenues__c)){
            system.debug('KY---Blank Skills ' );
            //currentSession.All_avenues__c.addError('Service is required.');
            ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, '\nPlease select whether you provided the service In-Person Service or Virtual Service.'));
            return Page.CY_AddTime;
        }
        //if(String.isBlank(currentSession.Skill_Primary__c) && currentSession.All_avenues__c=='In-Person Service'){
        //    system.debug('KY---Blank Skills ' );
        //    currentSession.Skill_Primary__c.addError('Primary Skill is required.');
        //    return Page.CY_AddTime;
        //}
        //Ensure required skills are selected
        //if(skillsAvailable.contains('*') && !skills.contains('*')){
        //    currentSession.Skills_Covered_for_the_Session__c.addError(Label.Required_Skill_for_Literacy_Math);
        //    return Page.CY_AddTime;
        //}
        //Ensure skills are <= 2000 characters
        // Ensure skills and comments are <== 255 chars
        //if(currentSession.Skills_Covered_for_the_Session__c <> null )
        //{
        //currentSession.Skills_Covered_for_the_Session__c = currentSession.Skills_Covered_for_the_Session__c.length() > 255 ?
        //currentSession.Skills_Covered_for_the_Session__c.substring(0, 255) : currentSession.Skills_Covered_for_the_Session__c;
        //}
        if(currentSession.Skills_Covered_for_the_Session__c <> null && currentSession.Skills_Covered_for_the_Session__c.length() > 2000){
            currentSession.Skills_Covered_for_the_Session__c.addError(Label.Exceeded_Skill_Length);
            return Page.CY_AddTime;
        }
        if(currentSession.Comments__c <> null ){
            currentSession.Comments__c = currentSession.Comments__c.length() > 255 ?
                    currentSession.Comments__c.substring(0, 255) : currentSession.Comments__c;
        }
        // Must have students selected and times added
        if (studentsInSession == null || studentsInSession.size() <= 0) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'You must add at least one student to this session');
            ApexPages.addMessage(myMsg);
            return Page.CY_AddTime;
        }
        for (Intervention_Session_Result__c s : studentsInSession){
            if (s.Amount_of_Time__c == null || s.Amount_of_Time__c <= 0 || s.Amount_of_Time__c > 500){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Session dosage must be between 1 ~ 500 minutes.');
                ApexPages.addMessage(myMsg);
                return Page.CY_AddTime;
            }
           
        }
        List<String> msgErrors = submitTime();
        Boolean isSuccsess = msgErrors.isEmpty();
        if(!isSuccsess){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'We have get errors when trying to save records.'));
            for(String msg: msgErrors){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, msg));
            }
            return Page.CY_AddTime;
        }

        currentSession = null;
        studentsInSession = new List<Intervention_Session_Result__c>();
        studentsDeleted = null;

        for (StudentWrapper ss : studentsInSection){
            ss.selected = false;
        }
        findEnrolledStudentsForSection();
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Confirm,System.Label.SessionMessage);
        ApexPages.addMessage(myMsg);
        /* PageReference resultPage = Page.CY_Students;//Added by harsh Singh
         resultPage.getParameters().put('urlparm',System.Label.SessionMessage);
      //   resultPage.setRedirect(true);//Added by Harsh Singh
        return  resultPage;*/
        return Page.CY_Students;
    }


    /**
    *    Navigation Action: From Session Detail ---> Section Detail
    */
    public PageReference doSessionCancel() {
        showCalDatePicker = true;
        currentSession = null;
        studentsInSession = null;
        studentsDeleted = null;
        isLoadPreviousSkills = false;
        //setupWeekValues(Date.today());
        return Page.CY_Students;
    }

    /**
    *    Navigation Action: From Session Detail ---> Section Detail ?????
    */

    public PageReference doAddStudentToSession() {
        // sync back list to selected students
        isLoadPreviousSkills = true;
        for (StudentWrapper ss : studentsInSection){
            ss.selected = false;
            if (studentsInSession != null){
                for (Integer i = 0; i < studentsInSession.size(); i++){
                    Intervention_Session_Result__c sr = studentsInSession.get(i);
                    if (sr.Student_Section__c == ss.stuSecRec.Id){
                        ss.selected = true;
                        break;
                    }
                }
            }
        }

        return Page.CY_Students;
    }

    /**
    *    Local Actions
    */
    public PageReference doDeleteStudentFromSession() {
        Id ssID = Apexpages.currentPage().getParameters().get('ssID');
        showCalDatePicker = true;

        for (Integer ind = 0; ind < studentsInSession.size() ;ind++){
            Intervention_Session_Result__c sr = studentsInSession.get(ind);
            if (sr.Student_Section__c == ssID){
                studentsDeleted.add(sr);
                studentsInSession.remove(ind);
                break;
            }
        }
        return null;
    }

    /**
    *    Private Business Method: Initialize new InterventionSession for add
    *    Added by Seema
    */
    private void getSelectedStudents() {
        if (currentSession == null){
            // we just clicked on add time for the first time.
            currentSession = new Intervention_Session__c();
            //currentSession.Date__c = Date.today();
            currentSession.Section__c = sectionID;
            currentSession.All_avenues__c = '';
            // currentSession.Session_Time_Completed_For__c = 'a1KL0000003sizM';
            currentSession.Session_Time_Completed_For__c = getCurrentStaff().Id;

            // Initialize students list
            studentsInSession = new List<Intervention_Session_Result__c>();
            studentsDeleted = new List<Intervention_Session_Result__c>();
            for (StudentWrapper ss : studentsInSection){
                if (ss.selected == true) {
                    // find student section, set student section
                    Intervention_Session_Result__c sr = new Intervention_Session_Result__c();
                    sr.Student_Section__c = ss.stuSecRec.Id;
                    sr.Student_Section__r = ss.stuSecRec;
                    studentsInSession.add(sr);
                }
            }
        } else {
            // we are adding students (not clicking on add time for the first time).
            for (StudentWrapper ss : studentsInSection){
                if (ss.selected == true) {
                    Intervention_Session_Result__c srFound = null;

                    // already in
                    if (studentsInSession != null){
                        for (Integer i = 0; i < studentsInSession.size(); i++){
                            Intervention_Session_Result__c sr = studentsInSession.get(i);
                            if (sr.Student_Section__c == ss.stuSecRec.Id){
                                srFound = sr;
                                break;
                            }
                        }
                    }

                    // previously deleted
                    if (studentsDeleted != null){
                        for (Integer i = 0; i < studentsDeleted.size(); i++){
                            Intervention_Session_Result__c sr = studentsDeleted.get(i);
                            if (sr.Student_Section__c == ss.stuSecRec.Id){
                                srFound = sr;
                                studentsDeleted.remove(i);
                                studentsInSession.add(sr);
                                break;
                            }
                        }
                    }

                    // add for the first time
                    if (srFound == null){
                        srFound = new Intervention_Session_Result__c();
                        srFound.Student_Section__c = ss.stuSecRec.Id;
                        srFound.Student_Section__r = ss.stuSecRec;
                        studentsInSession.add(srFound);
                    }

                } else {
                    Intervention_Session_Result__c srFound = null;

                    // already in
                    if (studentsInSession != null){
                        for (Integer i = 0; i < studentsInSession.size(); i++){
                            Intervention_Session_Result__c sr = studentsInSession.get(i);
                            if (sr.Student_Section__c == ss.stuSecRec.Id){
                                srFound = sr;
                                studentsInSession.remove(i);
                                studentsDeleted.add(sr);
                                break;
                            }
                        }
                    }

                    // previously deleted
                    if (studentsDeleted != null){
                        for (Integer i = 0; i < studentsDeleted.size(); i++){
                            Intervention_Session_Result__c sr = studentsDeleted.get(i);
                            if (sr.Student_Section__c == ss.stuSecRec.Id){
                                srFound = sr;
                                break;
                            }
                        }
                    }

                    // never added before
                }
            }
        }
    }

    /**
    *    Private Business Methods: set Intervention_Session object for update
    */
    private void setCurrentSession(String currSessID){
        try {
            currentSession = [SELECT Id,
                    Date__c,
                    All_avenues__c,
                    Comments__c,
                    Skill_Primary__c,
                    Skills_Covered_for_the_Session__c,
                    Session_Type__c,
                    Tutoring_Model__c,
                    Session_Format__c,
                    Site_Details__c,
                    (SELECT Amount_of_Time__c,
                            Student_Section__c,
                            Exit_Ticket__c,
                            Student_Section__r.Student__r.Id,
                            Student_Section__r.Student__r.Name //  Dosage__c,
                            FROM Intervention_Session_Results__r)
                    FROM Intervention_Session__c
                    WHERE Id = :currSessID];

            // Initialize students list
            studentsInSession = new List<Intervention_Session_Result__c>();
            studentsDeleted = new List<Intervention_Session_Result__c>();

            for (Intervention_Session_Result__c sr : currentSession.Intervention_Session_Results__r){
                studentsInSession.add(sr);
            }
        } catch (QueryException e) {
            ApexPages.addMessages(e);
            currentSession = null;
        }
    }

    private List<String> submitTime(){
        List<String> msgErrors = new List<String>();
        showCalDatePicker = true;
        Boolean isInsertOrUpdate = currentSession.Id == null;

        try{
            try{
                // 1. Insert/Update Session
                upsert currentSession;

                // 2. Collect Session results records
                for (Intervention_Session_Result__c s : studentsInSession){
                    //added to update skills to Intervention Session Result
                    s.SkillsCovered__c = currentSession.Skills_Covered_for_the_Session__c;
                    if(s.Id == null){
                        //for new records
                        s.Intervention_Session__c = currentSession.Id;
                    }
                    if (sessionDosage > 0 && s.Amount_of_Time__c == NULL && isInsertOrUpdate){
                        //BGR adding in default time if default specified and value not provided
                        s.Amount_of_Time__c = sessionDosage;
                    }
                }

                // 3. Insert Session Result
                upsert studentsInSession;   //Bulkify insert records

            }catch(DmlException e){
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    msgErrors.add(e.getDmlMessage(i));
                }
                return msgErrors;
            }}catch(Exception e){
            msgErrors.add(e.getMessage());
        }

        // 4. Delete existing session result in trash can. Discard new session  result
        if (studentsDeleted != null && !isInsertOrUpdate){
            List<Intervention_Session_Result__c> deleteSessResult = new List<Intervention_Session_Result__c>();
            System.debug('BGR Delete Session results' );

            for (Intervention_Session_Result__c s : studentsDeleted){
                if (s.Id != null){// Existing session result
                    deleteSessResult.add(s);    //collect all session results to delete
                }
            }
            delete deleteSessResult;    //Bulkify delete records
        }

        if (studentsDeleted != null) {
            studentsDeleted.clear();
            studentsDeleted = null;
        }
        return msgErrors;
    }

    public static final Map<String, String> mapSchoolProgram2Category = new Map<String, String>{
            'Tutoring: Literacy' => 'Literacy',
            'Tutoring: Math' => 'Math'
    };
    public static final String CATBEHAVIOR = 'SEL/Behavior and Attendance Interventions';
    public void initAvaliableFields(){
        avaliableFields = new List<SelectOption>();
        allPrimaryFields = new List<SelectOption>();
        //allPrimaryFields.add(new SelectOption('', ''));
        //avaliableFields.add(new SelectOption('',''));
        List<Section__c> sectionList = new List<Section__c>([SELECT Account_Program__r.Name
        FROM Section__c WHERE Id = :sectionID]);
        System.debug('Section List>>'+sectionList);

        String schoolProgram = sectionList.isEmpty()? '': sectionList[0].Account_Program__r.Name;
        System.debug('School Program>>'+schoolProgram);
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
        initSiteDetails();
    }

    public void initAllAvenues(){
        allAvenuesOptions = new List<SelectOption>();
        allAvenuesOptions.add(new SelectOption('', 'None', false));
        Map<String, String> mapValues = CT_core_SoqlUtils.getPicklistValues('Intervention_Session__c' ,'All_avenues__c');
        for(String val: mapValues.keySet()){
            allAvenuesOptions.add(new SelectOption(val, mapValues.get(val)));
        }
    }

    public void initSiteDetails(){
        siteDetailsOptions = new List<SelectOption>();
        siteDetailsOptions = ISTool.getSiteDetailsOptions();

    }

    /**
    *    Page 4 ENDS: Session Detail (Add Time, Update Session)
    */

//===============================Start curriculum methods===================================
    public Curriculum__c currenCurriculum { get; set; }
    public List<Curriculum__c> studentsInCurriculum {get; set;}
    public List<Curriculum__c> studentsInCurriculumDeleted {get; set;}
    public Map<String, List<Curriculum__c>> mapStudentToCurriculums {get; set;}

    public PageReference doStudentsAddCurriculum() {//Added by Harsh singh to fix multiselect value
        System.debug('@@@ selected ID: '+slctdStdId);
        Set<String> setOfIds = String.isNotBlank(slctdStdId)? new Set<String>(slctdStdId.split(',')): new Set<String>();
        for (StudentWrapper ss : studentsInSection){
            ss.selected = setOfIds.contains(ss.stuSecRec.Student__c);
        }
        if(String.isBlank(slctdStdId)){
            checkState='';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Select the Students'));
            return Page.CY_StudentCurriculums;
        }

        //initialize curriculums
        initCurriculums();

        return Page.CY_AddCurriculum;
    }

    public void initCurriculums(){
        currenCurriculum = currenCurriculum==null? new Curriculum__c(): currenCurriculum;
        currenCurriculum.Section__c = sectionID;
        //currenCurriculum.Date_of_Module__c = Date.today();

        Map<String, Curriculum__c> mapExistingCurriculums = new Map<String, Curriculum__c>();
        if(!studentsInCurriculum.isEmpty()){
            for(Curriculum__c curr: studentsInCurriculum){
                mapExistingCurriculums.put(curr.Student__c, curr);
            }
        }
        if(!studentsInCurriculumDeleted.isEmpty()){
            for(Curriculum__c curr: studentsInCurriculumDeleted){
                mapExistingCurriculums.put(curr.Student__c, curr);
            }
        }

        studentsInCurriculum = new List<Curriculum__c>();
        studentsInCurriculumDeleted = new List<Curriculum__c>();
        for (StudentWrapper ss : studentsInSection){
            if(ss.selected) {
                Curriculum__c selCurriculum = new Curriculum__c(
                        Student__c = ss.stuSecRec.Student__c,
                        Student__r = ss.stuSecRec.Student__r,
                        Section__c = ss.stuSecRec.Section__c,
                        Student_Section__c = ss.stuSecRec.Id,
                        Student_Section__r = ss.stuSecRec
                );
                if(mapExistingCurriculums.containsKey(ss.stuSecRec.Student__c)){
                    selCurriculum = mapExistingCurriculums.get(ss.stuSecRec.Student__c);
                }
                studentsInCurriculum.add(selCurriculum);
            }
        }
    }

    public PageReference doAddStudentToCurriculum() {
        // sync back list to selected students
        for (StudentWrapper ss : studentsInSection){
            ss.selected = false;
            for (Curriculum__c curr: studentsInCurriculum){
                if (curr.Student__c == ss.stuSecRec.Student__c){
                    ss.selected = true;
                    break;
                }
            }
        }

        return Page.CY_StudentCurriculums;
    }

    public PageReference doDeleteStudentFromCurriculum() {
        Id sID = Apexpages.currentPage().getParameters().get('sID');
        showCalDatePicker = true;

        for (Curriculum__c curr: studentsInCurriculum){
            if (curr.Student__c == sID){
                studentsInCurriculumDeleted.add(curr);
                studentsInCurriculum.remove(studentsInCurriculum.indexOf(curr));
                break;
            }
        }

        return Page.CY_AddCurriculum;
    }

    public PageReference doCurriculumSubmit(){
        if (currenCurriculum.Date_of_Module__c == null || currenCurriculum.Date_of_Module__c < currentSection.Start_Date__c ||
                currenCurriculum.Date_of_Module__c > currentSection.End_Date__c) {
            currenCurriculum.Date_of_Module__c.addError('Date should be within the start and end of the section.');
            return Page.CY_AddCurriculum;
        }
        // cannot be a date in the future
        if (String.isBlank(currenCurriculum.Curriculum_Name__c)) {
            currenCurriculum.Curriculum_Name__c.addError('Curriculum Name is required.');
            return Page.CY_AddCurriculum;
        }
        // Cannot have blank skills
        if (String.isBlank(currenCurriculum.Module_Name__c)) {
            currenCurriculum.Module_Name__c.addError('Module Name is required.');
            return Page.CY_AddCurriculum;
        }
        if (String.isBlank(currenCurriculum.Module_Assignments__c)) {
            currenCurriculum.Module_Assignments__c.addError('Module Assignments is required.'); 
            return Page.CY_AddCurriculum;
        }
        for(Curriculum__c curr: studentsInCurriculum){
            if (curr.Module_Score__c == null) {
                curr.Module_Score__c.addError('Module Score is required.'); 
                return Page.CY_AddCurriculum;
            }
        }

        try{
            for(Curriculum__c curr: studentsInCurriculum){
                curr.Date_of_Module__c = currenCurriculum.Date_of_Module__c;
                curr.Curriculum_Name__c = currenCurriculum.Curriculum_Name__c;
                curr.Module_Name__c = currenCurriculum.Module_Name__c;
                curr.Module_Assignments__c = currenCurriculum.Module_Assignments__c;
                curr.Comments__c = currenCurriculum.Comments__c;
            }
            insert studentsInCurriculum;
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'We have get errors when trying to save records.'));
            return Page.CY_AddCurriculum;
        }

        currenCurriculum = new Curriculum__c();
        studentsInCurriculum = new List<Curriculum__c>();
        studentsInCurriculumDeleted = new List<Curriculum__c>();
        
        for (StudentWrapper ss : studentsInSection){
            ss.selected = false;
        }
        findEnrolledStudentsForSection();
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Confirm, System.Label.CurriculumMessage);
        ApexPages.addMessage(myMsg);

        return Page.CY_StudentCurriculums;
    }

    public PageReference doCurriculumCancel() {
        showCalDatePicker = true;
        currenCurriculum = new Curriculum__c();
        studentsInCurriculum = new List<Curriculum__c>();
        studentsInCurriculumDeleted = new List<Curriculum__c>();

        return Page.CY_StudentCurriculums;
    }
//=====================================End curriculum methods=====================================

    public class ReportWrapper{
        //public Integer year {get; set;}
        //public Integer month {get; set;}
        public String intersessiondate{set;get;}
        public decimal AmountOftime{set;get;}
        public string studentname{set;get;}
    } 
    public List<ReportWrapper> getReportWrapper() {
            return  getReportWrapperItems();
            
    }
    public List<ReportWrapper> getReportWrapperItems(){
        List<ReportWrapper> reportlist = new List<ReportWrapper>();
        //List<Intervention_Session_Result__c> intersesseionList2 =[select id,name,Student__r.name,Amount_of_Time__c,Related_Student_s_Name__c,Intervention_Session_Date__c,Student_Section__r.Dosage_to_Date__c from Intervention_Session_Result__c where Student_Section__r.Section__c =: sectionID and Student_Section__r.Active__c =True and Amount_of_Time__c > 0 ORDER BY Intervention_Session_Date__c Asc ];
        List<AggregateResult> intersesseionList =[select Intervention_Session_Date__c,SUM(Amount_of_Time__c) amounttime from Intervention_Session_Result__c where Intervention_Session__r.Section__c =:sectionID and Student_Section__r.active__c = true  group BY Intervention_Session_Date__c,Student__r.name ORDER BY Intervention_Session_Date__c Asc ];
        //Set<date> newdate = new Set<date>();
           
        //for(Intervention_Session_Result__c intsess:intersesseionList2){
          for(AggregateResult agg :intersesseionList){
              Date dt =Date.valueOf(agg.get('Intervention_Session_Date__c'));
            //if(!newdate.contains(newdate){
            //newdate.add(intsess.Intervention_Session_Date__c);
            //Date dt = intsess.Intervention_Session_Date__c;
            Integer day = dt.Day(); //get day
            Integer month = dt.Month(); //get month
            Integer year = dt.Year(); //get year
            
            ReportWrapper wrapper = new ReportWrapper();
            wrapper.intersessiondate=month + '/' + day ;
            wrapper.AmountOftime =Integer.valueOf(agg.get('amounttime'));
            reportlist.add(wrapper);
            
            System.debug('reportlist'+reportlist);
            System.debug('intersesseionList'+intersesseionList);
        //}
        }
        return reportlist;
    }
    public class StudentReport{
        public Decimal AmountOfTime{set;get;}
        public string studentName{set;get;}
        public string intersessionDate {set;get;}
    }
    public List<StudentReport> getStudentReport(){
         return getStudentReportItems();
    }
    Public List<StudentReport> getStudentReportItems(){
        List<StudentReport> studentReportList = new List<StudentReport>();
        List<Student_Section__c> studentLists =[select id,name,Dosage_to_Date__c,Student__r.name from Student_Section__c where Section__c =: sectionID and Student__c IN: studentIdSet];
        System.debug('studentList###'+studentLists);
        Set<Id> studentSectionId = new Set<Id>();

        for(Student_Section__c se:studentLists){
            studentSectionId.add(se.id);
        }
        List<AggregateResult> intersesseionList =[select Intervention_Session_Date__c,SUM(Amount_of_Time__c) amounttime FROM Intervention_Session_Result__c where Student_Section__c IN: studentSectionId GROUP BY Intervention_Session_Date__c ORDER BY Intervention_Session_Date__c];
        set<Date> newdate = new set<Date>();
        Decimal amount;
        Map<date,Decimal> mapdateMaxdate = new Map<date,Decimal>();

        // for(AggregateResult result:intersesseionList){
        //     Date dt =Date.valueOf(result.get('MaxDate'));
        //     amount=Integer.valueOf(result.get('amounttime'));

        //    if(mapdateMaxdate.containsKey(dt)){
        //        amount=amount+mapdateMaxdate.get(dt);
        //    }
        //    mapdateMaxdate.put(dt,amount);
        // }
        for(AggregateResult result:intersesseionList){
            Date dt =Date.valueOf(result.get('Intervention_Session_Date__c'));
            Integer day = dt.Day(); 
            Integer month = dt.Month(); 
            Integer year = dt.Year(); 
            
            StudentReport wrapper = new StudentReport();
             //wrapper.AmountOfTime=mapdateMaxdate.get(dt);
             wrapper.AmountOfTime=Integer.valueOf(result.get('amounttime'));
             wrapper.intersessionDate=month + '/' + day ;
             studentReportList.add(wrapper);
             System.debug('reportlist'+studentReportList);
            
        }
        System.debug('reportlist****'+studentReportList);
        return studentReportList;
    }
    /////*****************/////
    public transient static final String BEFORESTART = 'Cannot enter time for a date that falls before the section start date.';
    public transient static final String AFTEREND = 'Cannot enter time for a date that falls after the section end date.';
    public transient static final String FUTURE = 'Cannot enter time for a date in the future.';
   
    public List<SessionResultsWrapper> resultsData                  {get;set;}
    public Date currentWeek                                         {get;set;}
    private List<Student_Section__c> studentSections;
    public List<DayWrapper> tableHeaders                            {get;set;}
    private Map<Integer, DayWrapper> tableHeaderMap;
    public Intervention_Session__c weekEndHolder        {get;set;}
    public String                   allAvenuesSelected          {get; set; }
    public String                   sessionTypeSelected         {get; set; }
    public String                   sessionFormatSelected       {get; set; }
    public Boolean showSiteDetails                              {get; set; }
    public String                   siteDetailsSelected         {get; set; }
    public string                   Exitticket                  {get;set;} 
    public boolean timer                                        {get; set;}      
    private void setupWeekValues(Date dayInWeek){
        System.debug('dayInweek***'+dayInWeek);
        currentWeek = dayInWeek.toStartOfWeek();
        System.debug('currentWeek###'+currentWeek);
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
    public void changeWeek(){
        System.debug('changeWeek');
        if(weekEndHolder.Date__c!=null){
            currentWeek = weekEndHolder.Date__c.toStartOfWeek();
            loadSessionData();
        } else {
            CYUtil.errorMessage('Please select a week to view.');
        }
    }

    public void lastWeek(){
        System.debug('Lastweek++');
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

    private String getDayTitle(Date day){
        if(String.isBlank(sectionID)){
            if(day>Date.today()){
                return FUTURE;
            }
        } else {
            Section__c section = sectionMap.get(sectionID);
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
    public void changeSection(){
        System.debug('newSection###'+sectionID);
        sectionMap = new Map<ID, Section__c>();
         for(Section__c section:[select id,name,Auto_Name__c,Account_Program__r.Name,End_Date__c,Start_Date__c,Intervention_Primary_Staff__c from Section__c where Id =: sectionID]){
            System.debug('SectionId^^^'+section.Id);
            sectionMap.put(section.id,section);
         }
        System.debug('sectionMap@@@'+sectionMap);
        resultsData = new List<SessionResultsWrapper>();
        if(!String.isBlank(sectionID) && sectionID != 'none'){
            currentSection = sectionMap.get(sectionID);
            //added to get skills
            initializePicklist();
            //load data
            loadSessionData();
            showTutoringModel = currentSection.Auto_Name__c.contains('Tutoring: Math') || currentSection.Auto_Name__c.contains('Tutoring: Literacy');
            showSiteDetails = siteDetailsOptions != null && siteDetailsOptions.size() > 0;
        }
    }
    public void loadSessionData(){
     
        if(String.isBlank(sectionID) || sectionID == 'none'){
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
   
    private void loadStudentSections(){
        studentSections=
            [select id, Student_Name__c, Student__c, Section__r.Auto_Name__c
            from Student_Section__c
            where Active__c = true
            and Student__r.Active__c = true
            and Section__c =: sectionID
            order by Student_Name__c, Student__c];
    }
    private Intervention_Session_Result__c[] getSessionData(){
        return [select Id, Amount_of_Time__c, Student_Section__c,Exit_Ticket__c,
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
                where Intervention_Session__r.Section__c =: sectionID
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
    public void saveNewSessions(){
        timerOn();
         String flag='proceed false';
         System.debug('Exitticket++'+Exitticket);
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
                  if(day.session.ID == null && sectionMap!=null && sectionMap.containsKey(sectionID)){ //this fixes issues because an error was thrown later on.
                      day.session.Session_Time_Completed_For__c = sectionMap.get(sectionID).Intervention_Primary_Staff__c;
                      day.session.Section__c = sectionID;
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
            System.debug('update++');
              for(Integer i=0;i<7;i++){
                  String key = srw.studentId+SEPKEY+i;
                  ISRWrapper rw = srw.dosages[i];
                  Decimal amountOfTime = rw.isr.Amount_of_Time__c;
                  Id isrID = rw.isr.Id;
                  System.debug('isrID###'+isrID);
                  if((amountOfTime != null && amountOfTime != rw.amount)
                          && (isrID != null || daysToSave.contains(i+1))){
                            System.debug('update##');
                      if(isrID == null){
                          System.debug('allAvunes Options');
                          Intervention_Session__c session = sessionsTosave.get(i+1);
                          rw.isr.Intervention_Session__c = session.ID;
                          //added to update skills to Intervention Session Result
                          rw.isr.SkillsCovered__c = session.Skills_Covered_for_the_Session__c;
                          rw.isr.Exit_Ticket__c=Exitticket;
                      }
                      rw.isr.Exit_Ticket__c=Exitticket;
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
                              //ApexPages.addMessage(new apexPages.Message(apexPages.Severity.ERROR, '\nPlease confirm whether service happened In-Person Service or Virtual Service by clicking on the blue speech bubble next to a date column.'));
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
            System.debug('result record');
              for(Integer i=0;i<7;i++){
                  String key = srw.studentId+SEPKEY+i;
                  if(resultsToSave.containsKey(key)){
                      srw.dosages[i].isr.Id = resultsToSave.get(key).Id;
                      srw.dosages[i].isr.Exit_Ticket__c=Exitticket;
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
    
    /////////**************//////
   
 
}