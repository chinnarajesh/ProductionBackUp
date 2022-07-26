/**
    ctlAddTimeFLow: Controls the diaglog flow for the Intervention - sessions application. 
*/

public without sharing class ctlAddTimeFlow_dev {

    public Section__c sect  { get;set; }//Added by Harsh Singh
    public Student_Section__c ss {get;set;}//Added by Harsh Singh
    public List<SessionList> searchResults{get;set;}//Added by Harsh Singh
    public Boolean showReport{get;set;}//Added by Harsh Singh to show or hide the report on the basis of the user license T-498243
    public ID reportID{get;set;}
    public Boolean srchop{get;set;}
    public Integer sessionDosage{get; set;} //BGR Declare variable to capture default session time
    public Boolean showTutoringModel{get;set;}
   
    
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
        Public String Primaryskill {get;set;}
    }
    /**/
     
    /**/
    /**
    *    Constructor
    */

    public ctlAddTimeFlow_dev(){
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
        try {
            String[] currUserIDs = getCurrentUserIDs();
            List<Section__c> allMySections = [SELECT Id, Name, In_After_School__c, Section_Nickname__c, Active__c
                FROM Section__c 
                WHERE RecordType.DeveloperName IN ('Intervention_Section','Curriculum')
                    AND SkipDosage__c = false 
                    AND ID IN (SELECT  Section__c FROM Staff_Section__c 
                        WHERE Staff__r.Individual__r.User_ID__c IN :currUserIDs
                        AND Section__r.Active__c = true
                        AND Is_Active__c = true
                    )
                ORDER BY Name
//                LIMIT :blockSize
//                OFFSET :index
            ];
            system.debug('HSB 1 - ' + allMySections);
            
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
        
        return Page.CY_AddTime;
    }

    /**
    *    Navigation Action: From Section Detail/Enrolled Students ---> Session List
    */
    // Navigation action from the pageSectionStudents VFP to show the list of intervention sessions where time has been tracked
    public PageReference doShowSessions() {
        sect.Start_Date__c = null;
        sect.End_Date__c = null;
        sect.Intervention_Primary_Staff__c = null;
        ss.Student__c = null;
        searchResults=null;
        sect.School__c = currentSection.School__c;
        isLoadPreviousSkills = false;
        return Page.CY_Session;//Added by Harsh Singh on 10 th May 2016
        /*PageReference pg = new PageReference('/apex/CY_Session');
        pg.setRedirect(true);
        return pg;*/
    }
    public PageReference backToSession(){
        sect.School__c = currentSection.School__c;
        return Page.CY_Session;
    }

    /**
    *    Navigation Action: From Section Detail/Enrolled Students ---> Section List
    */
    // Navigation action on the cancel buttons of pageSectionStudent VFP - sends user back to the list of sections
    public PageReference doStudentsCancel() {
        isLoadPreviousSkills = false;
        showCalDatePicker = true;
        return Page.CY_Sections;
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
                 if(st.Primary_Skill__c != null && st.Primary_Skill__c !=''){
                 If(primaryskillMap.containsKey(st.Intervention_Session__c)){
                    string Primaryskill = String.valueOf(st.Primary_Skill__c);
                    string sectionprimarySkill = primaryskillMap.get(st.Intervention_Session__c)+','+Primaryskill;
                    primaryskillMap.put(st.Intervention_Session__c,sectionprimarySkill);
                 }
                 else{
                 primaryskillMap.put(st.Intervention_Session__c,st.Primary_Skill__c);
                 }
                 }
                
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
        System.debug('@@@@@@@@'+'Insearch Section'+sectionID);
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
                    if(st.Primary_Skill__c != null && st.Primary_Skill__c !=''){
                    if(searchPrimaryMap.containsKey(st.Intervention_Session__c)){
                    string Primaryskill = String.valueOf(st.Primary_Skill__c);
                    string searchPrimarySkill = searchPrimaryMap.get(st.Intervention_Session__c)+','+Primaryskill;
                    searchPrimaryMap.put(st.Intervention_Session__c,searchPrimarySkill);
                    }
                    else{
                    searchPrimaryMap.put(st.Intervention_Session__c,st.Primary_Skill__c);
                    }
                    }
                }
            }
            //Logic to filter Student Name
            //Retrieve Student name from student
            if(ss.Student__c!=null){
                student=[Select Name from Student__C where ID=:ss.Student__c] ;
            }
            if(interv!=null){
                for(Intervention_Session__c iter : interv){
                    SessionList slt=new SessionList();
                    if( stsectionmap.containsKey(iter.ID)==true && searchTimeMap.containsKey(iter.ID) || searchExitMap.containsKey(iter.ID)){
                        slt.intervSection=iter;
                        slt.studentList=stsectionmap.get(iter.ID);
                        slt.Timevalue=findmax(searchTimeMap.get(iter.ID));
                        slt.exitticket=searchExitMap.get(iter.ID);
                    }
                    if(ss.Student__c!=null){
                        if( slt.studentList.contains(student.Name)){
                            searchResults.add(slt);
                        }
                    }else if(ss.Student__c==null){
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
            if(searchResults.size()==0){
                if(message==null){
                    message = new ApexPages.Message(ApexPages.Severity.info,System.Label.Empty_Search_Reult);
                    ApexPages.addMessage(message);
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
    public static List<Data> getChartData() {
        List<Data> data = new List<Data>();
        data.add(new Data('Jan', 30, 90, 55));
        data.add(new Data('Feb', 44, 15, 65));
        data.add(new Data('Mar', 25, 32, 75));
        data.add(new Data('Apr', 74, 28, 85));
        data.add(new Data('May', 65, 51, 95));
        data.add(new Data('Jun', 33, 45, 99));
        data.add(new Data('Jul', 92, 82, 30));
        data.add(new Data('Aug', 87, 73, 45));
        data.add(new Data('Sep', 34, 65, 55));
        data.add(new Data('Oct', 78, 66, 56));
        data.add(new Data('Nov', 80, 67, 53));
        data.add(new Data('Dec', 17, 70, 70));
        return data;
    }
    
    // Wrapper class
    public class Data {
        public String name { get; set; }
        public Integer data1 { get; set; }
        public Integer data2 { get; set; }
        public Integer data3 { get; set; }
        public Data(String name, Integer data1, Integer data2, Integer data3) {
            this.name = name;
            this.data1 = data1;
            this.data2 = data2;
            this.data3 = data3;
        }
    }
}