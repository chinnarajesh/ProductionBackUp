global without sharing class CT_Scheduler_HoldingProcessor implements Database.Batchable<SObject>, Database.Stateful { 
    private List<HoldingObj__c>                 batch;
    private transient Map<Id,HoldingObj__c>     batchById;
    private transient Map<String,Account>       schoolsByDBN;
    private transient Map<String,Contact>       staffByExternalId;
    private transient Map<String,Staff__c>      staffSchoolByExternalIdDBN;
    private transient Map<String,Contact>       studentsByExternalId;
    private transient Map<String,Section__c>    sectionsByKey;
    private transient Map<String,Student__c>    studentSchoolGradesByKey;
    private transient Map<String,Set<String>>   gradesBySchoolDBN;
    private  Map<String,Course__c>              coursesByKey;
    private transient Map<String, Room__c>      roomsByKey;
    private  Map<Id, Course__c>                 courseById;
    private transient Map<String, Time_Element__c>      yearNameMap; //This map is used to connect Student__c records to the appropriate Year
    private transient Map<String,Student_Section__c>    studentSectionsByKey;
    private transient Map<String, Section__c>   scheduleGroupsbyKey;
    private transient Map<Id, Map<String,Course_Weightings__c>>     courseWeightingsByCourse;
    private transient Map<Id, Map<String, Time_Element__c>>         sectionReportingPeriodMap;
    private static final List<String> FIELDSSTAFF = new List<String>{
        'Network__c', 'School_Name__c', 'Staff_Code__c', 'Staff_ID__c', 'Subject__c', 'Username__c'
    };
    private static final List<String> FIELDSSTUDENT = new List<String>{'Admission_Date__c', 'Disability_Flag__c', 
        'DOB__c', 'ELL__c', 'Ethnic_Cde__c', 'Lep_Flag__c', 'Network_Code__c', 'Student_Id__c', 'Student_Propagated__c', 
        'School_Propagated__c', 'Section_Propagated__c'
    };
    private static final Map<String, String> mapSheduleExecuteMode = new Map<String, String>{
        'Staff' => 'Student',
        'Student' => 'StudentSection'
    };

    public String                   query;
    global String                   mode;
    global String                   schoolDbn;
    public Setup__c                 cSetup;
    global Id                       reportingPeriod;
    global boolean                  continueBatch;
    public static boolean           bAutoCreateUsers = false;
    global Data_Load_Log__c         log;
    global List<String>             lstMsgs;


    global CT_Scheduler_HoldingProcessor() {
        System.debug('Constructing ct scheduler holding processor');
        lstMsgs = new List<String>();
        log = new Data_Load_Log__c(Status__c='Pending', Class_Name__c='CT_Scheduler_HoldingProcessor');
        insert log;
        continueBatch = false;
    }

    public static string processQueryForPropagator(string mode, Setup__c cSetup, String schoolDbn){
        String queryToProcess = 'SELECT First_Name__c,Last_Name__c,Class_Id__c,Class_Name__c,Grade_Level__c,Reference_Id__c,Lunch_Status__c,';
        queryToProcess += 'School_Dbn__c,Propagated__c,Password__c,Email__c,Source_System__c,Course_Name__c,Period__c,Record_Attendance__c,';
        queryToProcess += 'Daily_Attendance__c,Phone__c,Address__c,City__c,State__c,Zip__c,Age__c,Sex__c,Reporting_Period_Id__c,';
        queryToProcess += 'Room__c,School_Year__c,Local_Student_ID__c,'+String.join(mode=='Staff'? FIELDSSTAFF: FIELDSSTUDENT, ',');
        queryToProcess += ' FROM HoldingObj__c';
        queryToProcess += ' WHERE Type__c = \''+mode+'\'';
        System.debug('queryToProcess##'+queryToProcess);
        if(cSetup!=null){
            queryToProcess+=' AND School_Dbn__c =\''+String.escapeSingleQuotes(cSetup.School__r.Reference_Id__c)+'\''; //If based on setup pass in School DBN or Reference ID
            System.debug('\n\n cSetup.school.Reference_Id__c => ' + cSetup.School__r.Reference_Id__c + '\n');
            queryToProcess+=' AND School_Year__c =\''+String.escapeSingleQuotes(cSetup.year__r.Name__c)+'\''; //If based on setup pass in School Year Name
            System.debug('\n\n cSetup.setup.year__r.Name__c => ' + cSetup.year__r.Name__c + '\n');
        }
        else if (schoolDbn!=null){
            queryToProcess+=' AND School_Dbn__c =\''+String.escapeSingleQuotes(schoolDbn)+'\''; //School DBN if loading flat roster 
            System.debug('\n\n schoolDbn => ' + schoolDbn + '\n');
        }
        queryToProcess+=' AND Propagated__c = false';
        return queryToProcess;
    }
      
    global Database.QueryLocator start(Database.BatchableContext ctx) {
        try{
            System.debug('\n\n reportingPeriod in CT_Scheduler_HoldingProcessor => ' + reportingPeriod + '\n');
            query = CT_Scheduler_HoldingProcessor.processQueryForPropagator(mode, cSetup, schoolDBN);
            if(cSetup!=null) log.Setup__c = cSetup.Id;
            if(reportingPeriod!=null) log.Reporting_Period__c = reportingPeriod;
            log.Batch_ID__c = ctx.getJobId();
            log.Status__c = 'Running';
            log.Type__c = mode;
            log.Total_Records__c = 0;
            log.Failed_Records__c = 0;
            log.Start_Time__c = System.now();
            log.Start_Time_Text__c = log.Start_Time__c.format('MM/dd/yyyy hh:mm a');
            update log;
            return Database.getQueryLocator(query);
        }
        catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
            Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.Id+'; Reporting Period, '+reportingPeriod, 'Propagator', 'QueryLocator error during '+mode+' propagation', e);
            insert ge;
            return null;
        }
    }
    
    global void execute(Database.BatchableContext ctx, List<SObject> scope) {
        try{
            CT_core_TriggerUtils.scheduler=true;//US1250 need to set the flag for Scheduler
            batch = (HoldingObj__c[])scope;
            System.debug('\n\n batch in hol \n');
            batchById = new Map<Id,HoldingObj__c>(batch);
            schoolsByDBN = new Map<String,Account>();
            staffByExternalId = new Map<String,Contact>();
            studentsByExternalId  = new Map<String,Contact> ();
            staffSchoolByExternalIdDBN =  new Map<String,Staff__c>();
            studentSchoolGradesByKey = new Map <String, Student__c>();
            sectionsByKey = new Map<String,Section__c>();
            coursesByKey = new Map<String,Course__c>();
            gradesBySchoolDBN = new Map<String,Set<String>>();
            courseWeightingsByCourse = new Map <Id, Map <String, Course_Weightings__c>>();
            studentSectionsByKey = new Map<String,Student_Section__c> ();
            sectionReportingPeriodMap = new Map <Id, Map<String, Time_Element__c>>();
            yearNameMap = new Map <String, Time_Element__c>();
            roomsByKey = new Map <String, Room__c>();
            courseById = new Map <Id, Course__c>();
            scheduleGroupsbyKey= new Map <String, Section__c>();
            clearErrors();
            if (mode=='Staff'){    
                processSchoolYearMap();
                processSchools();
                processCourses();
                processSections(mode);
                //processStaff();
                processStaffSchools();
                processStaffSections();
                if (Test.isRunningTest() || CT_Scheduler_HoldingProcessor.bAutoCreateUsers) {
                    createStaffUsers(staffByExternalId.values());
                }
            }else if(mode=='StudentSection'){
                processStudentSections();
            } else {//if(mode=='Student'){
                processSchoolYearMap();
                processSchools();
                processCourses();
                processSections(mode);
                processStudentContacts();
                processStudentSchools();
                If(Test.isRunningTest()) processStudentSections();
                //PU 09/18/11 - Moving section grades creation to triger
                //processStudentSectionGrades();
            }
            
            // Save Propogated flags and/or error messages
//            update batchById.values();
            List<Database.SaveResult> results = Database.update(batchById.values(), false);
            List<String> lstSRErrors = new List<String>();
            for (Database.SaveResult sr: results) {
                if (!sr.isSuccess()) {
                    lstSRErrors.add(sr.getErrors()[0].getMessage());
                }
            }
            if(!lstSRErrors.isEmpty()){
                insert CT_Error_Handling.handleError('Setup, '+cSetup.Id+'; Reporting Period, '+reportingPeriod, 'Propagator', 'error during '+mode+' propagation. '+String.join(lstSRErrors, '; '));
            }
            
            log.Total_Records__c += batch.size();
            countFailures();
        }
        catch(Exception e){
            if(cSetup != null){
                Global_Error__c ge = CT_Error_Handling.handleError('Setup, '+cSetup.Id+'; Reporting Period, '+reportingPeriod, 'Propagator', 'error during '+mode+' propagation', e);
                insert ge;
            }
            System.debug(e);            
        }
    }
    
    global void finish(Database.BatchableContext ctx) {
        String batchId = null;
        if(continueBatch){
            if(mapSheduleExecuteMode.containsKey(mode)){//run student propagator
                CT_Scheduler_HoldingProcessor shp = new CT_Scheduler_HoldingProcessor();
                shp.continueBatch = true;
                shp.cSetup = cSetup;
                shp.mode = mapSheduleExecuteMode.get(mode);
                shp.reportingPeriod = reportingPeriod;
                batchId = Database.executeBatch(shp);
            }else{
                //run session propagator
                System.debug('\n\n goes to session insert \n');
                CT_BatchInsertSessions pubSess = new CT_BatchInsertSessions(cSetup.Id, reportingPeriod);
                pubSess.holdingSource = [SELECT id FROM HoldingObj__c WHERE Reporting_Period_Id__c=:reportingPeriod 
                    AND School_DBN__c=:cSetup.School__r.Reference_Id__c AND School_Year__c=:cSetup.Year__r.Name__c];
                batchId = Database.executeBatch(pubSess, 50);
            }
        }

        log.Status__c = 'Completed';
        log.End_Time__c = System.now();
        log.End_Time_Text__c = log.End_Time__c.format('MM/dd/yyyy hh:mm a');
        log.Messages__c = String.join(lstMsgs, ';');
        log.BatchNext_ID__c = batchId;
        update log;
    }
    
    private void processSchoolYearMap(){
        Set <String> yearNameSet = new Set <String>();
         for (HoldingObj__c holder : batch) {
            if (holder.School_Year__c!=null){
                yearNameSet.add(holder.school_year__c);
            }
         }
         if (!yearNameSet.isEmpty()){
            for (Time_Element__c te: [select id, name__c from Time_Element__c where name__c in: yearNameSet and Picklist_Value__r.Name='Year']){
                yearNameMap.put(te.name__c, te);
            }
         }
    }
    
    /*private void processStaff() {
        system.debug('process staff');
        //Iterate over each HOS, add staff to the staff list
        for (HoldingObj__c holder : batch) {
            String staffId = CT_ImportUtils.stripLeadingZeroes(holder.Staff_ID__c);
            if (!staffByExternalId.containsKey(staffId)) {
                Contact staff = CT_ImportMappers.createStaffMapper().generate(holder);
                staffByExternalId.put(staffId, staff);
            }

        }
        processErrors(
                staffByExternalId.values(),
                Database.upsert(staffByExternalId.values(), Contact.Reference_ID__c, false),
                Contact.Holding_Source__c);
    }*/
    
    private void processStaffSections() {
        system.debug('process staff sections');
        //Iterate over each hos, create new Staff/Section object and Staff/School object
        Map<String,Staff_Section__c> staffSectionsByKey = new Map<String,Staff_Section__c>();
        Map<String,Staff__c> staffSchoolsByKey = new Map<String,Staff__c>();
        // Joiners for special sections (ELL and Disability)
        
        for (HoldingObj__c holder : batch) {
            String staffSectionKey = CT_ImportUtils.createStaffSectionKey(holder);
            if ((staffSectionKey != null) && !staffSectionsByKey.containsKey(staffSectionKey)) {
                system.debug('hooray!  in the right if');
                Staff_Section__c staffSection = CT_ImportMappers.createStaffSectionMapper().generate(holder);
                staffSectionsByKey.put(staffSectionKey, staffSection);
            }
        }
        
        processErrors(
                staffSectionsByKey.values(),
                Database.upsert(staffSectionsByKey.values(), Staff_Section__c.Reference_Id__c, false),
                Staff_Section__c.Holding_Source__c);
    }
    
    private void processStaffSchools() {
        system.debug('process staff schools');
        Map<String,Staff__c> staffSchoolsByKey = new Map<String,Staff__c>();
        
        for (HoldingObj__c holder : batch) {
            String staffSchoolKey = CT_ImportUtils.createStaffSchoolKey(holder);
            if ((staffSchoolKey != null) && !staffSchoolsByKey.containsKey(staffSchoolKey)) {
                Staff__c staffSchool = CT_ImportMappers.createStaffSchoolMapper().generate(holder);
                staffSchoolsByKey.put(staffSchoolKey, staffSchool);
            }
        }
        
        processErrors(
                staffSchoolsByKey.values(),
                Database.upsert(staffSchoolsByKey.values(),Staff__c.Reference_Id__c, false),
                Staff__c.Holding_Source__c);
    }
    
    private void processCourses() {
        system.debug('process courses');
        //Iterate over each HOS, add staff to the staff list
        Set <String> courseKeys = new Set<String>();
        Set <String> roomKeys = new Set<String>();
        Set <String> groupKeys = new Set <String>();
        for (HoldingObj__c holder : batch) {
            String courseKey = holder.Course_Name__c;
            String roomKey = CT_ImportUtils.createRoomKey(holder);
            String groupKey = CT_ImportUtils.createScheduleGroupKey(holder);
            System.debug('-------GroupKey------------'+groupKey);
            courseKeys.add(courseKey);
            roomKeys.add(roomKey);
            groupKeys.add(groupKey);
        }
        for (Course__c course: [select id, name, reference_id__c, number_of_reporting_periods__c,Homework_Based__c from Course__c where Name in :courseKeys and RecordType.Name = 'Course']){
            
            coursesByKey.put(course.name, course);
            courseById.put(course.id, course);
        }
        for (Room__c room: [select id, name, Reference_Id__c from Room__c where Reference_Id__c in: roomKeys]){
            roomsByKey.put(room.reference_Id__c, room);
        }
        //Start US1254 Updates
        ID grpSectionRtId = CT_core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Schedule_Group');
        for (Section__c sg: [select id, name, Reference_Id__c from Section__c where Reference_Id__c in :groupKeys and RecordType.DeveloperName='Schedule_Group']){
            scheduleGroupsbyKey.put(sg.Reference_Id__c, sg);
        }
         //End US1254 Updates

    }
    
    private void processSections(String mode) {
        Set <String> secRefKeys = new Set<String>();
        //Iterate over each HOS, add staff to the staff list
        for (HoldingObj__c holder : batch) {System.debug('$$$$$Batch$$$'+batch);
            System.debug('\n\n Holding obj => ' + holder + '\n');
            String sectionKey = CT_ImportUtils.createClassSectionKey(holder);
            String roomKey =    CT_ImportUtils.createRoomKey(holder);
            String groupKey;
            if (cSetup!=null) {
                if (cSetup.group_based__c) groupKey = CT_ImportUtils.createScheduleGroupKey(holder);
            }
            else groupKey = null;
            
            if ((sectionKey != null) && !sectionsByKey.containsKey(sectionKey)) {
                Section__c section = new Section__c();
                if (mode=='Staff'){
                    System.debug('\n\n When mode is staff \n');
                    System.debug('\n\n CT_ImportMappers.createSectionMapper().generate(holder,yearNameMap.get(holder.School_Year__c)) => ' + CT_ImportMappers.createSectionMapper().generate(holder,yearNameMap.get(holder.School_Year__c)) + '\n');
                    section = CT_ImportMappers.createSectionMapper().generate(holder,yearNameMap.get(holder.School_Year__c));
                }else{
                    section = CT_ImportMappers.createSectionMapper().generateForStudent(holder,yearNameMap.get(holder.School_Year__c));
                }            
                if (RoomKey!=null && roomsByKey.containsKey(roomKey)) section.Room__c = roomsByKey.get(roomKey).id;
                if(holder.Course_Name__c != null){
                    section.Course__c = coursesByKey.get(holder.Course_Name__c).Id;
                    section.Number_of_Reporting_Periods__c = String.valueOf(coursesByKey.get(holder.Course_Name__c).number_of_reporting_periods__c);
                    section.Active__c = cSetup.Active__c;
                    /*PU Populate Homework_Based__c flag on section if the setup is  Standards_ONLY_Gradebook__c*/
                    if(cSetup.Standards_ONLY_Gradebook__c)
                    section.Homework_Based__c = coursesByKey.get(holder.Course_Name__c).Homework_Based__c;
                    
                    /* Need to get the Group Id*/  
                    string SchedulerRefKey; 
                    System.debug('----Schedule Groups By Key-------'+scheduleGroupsbyKey);
                    /*PN 10/11 Scheduler Rerference Id is still needed on Section to connect schedule groups with sections; CT_scheduler_SoqlUtils. getGroupsBySections*/
                      if (groupKey!=null){
                        if (scheduleGroupsbyKey.get(groupKey)!=null){  //Specific logic needed for group based schools to get session information
                            SchedulerRefKey =schoolsByDBN.get(holder.school_dbn__c).id+'-'+scheduleGroupsbyKey.get(groupKey).id+'-'+section.course__c+'-'+holder.Reporting_Period_Id__c;
                            section.scheduler_reference_Id__c = SchedulerRefKey;
                        
                            section.Schedule_Group__c = scheduleGroupsbyKey.get(groupKey).id;
                            system.debug('Sect.schedule_group__c'+section.Schedule_Group__c);
                            system.debug('Sect'+scheduleGroupsbyKey.get(groupKey));
                        }
                      }
                    secRefKeys.add(section.Reference_Id__c);
                }
                sectionsByKey.put(sectionKey, section);
            }
        }
        System.debug('==> In modified batch processor, upserting sections '+sectionsByKey.values());
        processErrors(
                sectionsByKey.values(),
                Database.upsert(sectionsByKey.values(), Section__c.Reference_Id__c, false),
                Section__c.Holding_Source__c
        );
            
//      updateSectionReportingPeriods(secRefKeys,batch[0].Reporting_Period_Id__c);
        updateSectionReportingPeriods(secRefKeys,batch[0].Reporting_Period_Id__c);

    }
    /*  PU 09/23/11 - Updating the record type on Section_ReportingPeriod__c to published*/
    private void updateSectionReportingPeriods(Set<String> refKeys,Id repPeriod){
        List<Id> repPerIds = new List<Id>();
        if(batch.size() > 1) {
            for (HoldingObj__c holdingObj : batch) {
                repPerIds.add(holdingObj.Reporting_Period_Id__c);
            }
        }
        List<Section_ReportingPeriod__c>  sectionRpList = new  List<Section_ReportingPeriod__c>();
        for(Section_ReportingPeriod__c secRp : [SELECT ReferenceId__c,Id FROM Section_ReportingPeriod__c
                                                        WHERE Section__r.Reference_Id__c in: refKeys 
//                                                      AND Time__c =: repPeriod
                                                        AND Time__c IN : repPerIds
                                                        order by Section__c]){
            secRp.RecordTypeId = CT_core_SoqlUtils.getRecordTypesBySobject('Section_ReportingPeriod__c').get('Published');
            sectionRpList.add(secRp); 
        }
        try{
            if(sectionRpList.size() > 0) 
                update sectionRpList;
        }
        catch(Exception ex){
            System.debug(ex);
        }
    }
    private void processSchools() {
        system.debug('process schools');
        for (HoldingObj__c holder : batch) {
            if(!schoolsByDBN.containsKey(holder.School_Dbn__c)) {
                Account school = CT_ImportMappers.createSchoolMapper().generate(holder);
                schoolsByDBN.put(holder.School_Dbn__c, school);
            }
        }
        processErrors(
                schoolsByDBN.values(),
                Database.upsert(schoolsByDBN.values(), Account.Reference_Id__c, false),
                Account.Holding_Source__c);
    }
    
    private void clearErrors(){
        for (HoldingObj__c ho: batchById.values()){
            ho.error_message__c = null;
            ho.Propagated__c = true;
        }
        
    }
    
    private void processErrors(List<SObject> records, List<Database.UpsertResult> results, Schema.SobjectField sourceField) {
        System.assertEquals(records.size(), results.size(), 'Records and results arrays must of equal size');
        for (Integer i=0;i<results.size();i++) {
            System.debug('results~~~'+results[i]);
            if (!results[i].isSuccess()) {
                Id holdingId = (Id)records[i].get(sourceField);
                HoldingObj__c tempHo = batchById.get(holdingId);
                System.debug('ho~~~' + tempHo);                
                if (batchById.containsKey(holdingId) && tempHo.Propagated__c) { //only run if propagated is true which is set by default at start of batch
                    // Do not overwrite previous error message as it's most likely the root cause.       
                    tempHo.Propagated__c = false;
                    if (tempHo.Error_Message__c==null){
                        String msg = results[i].getErrors()[0].getMessage();
                        lstMsgs.add(msg+'. <a href="/'+tempHo.Id+'">Template</a>');
                        tempHo.Error_Message__c = (String.isNotBlank(msg) && msg.length()>255)? msg.substring(0,254): msg;
                        batchById.put(holdingId, tempHo);
                        System.debug('tempHo~~' + tempHo);
                    }
                }
            }
        }
    }
    
    private void countFailures() {
        for (HoldingObj__c staff : batch) {
            if (staff.Propagated__c == false) {
                log.Failed_Records__c++;
            }
        }
    }           
    
    private void createStaffUsers(List<Contact> staffs) {
        staffs = [SELECT Name, LastName, FirstName, User_Name__c, User__c, Reference_ID__c FROM Contact WHERE Id IN :staffs];
        List<User> users = new List<User>();
        for (Contact staff : staffs) {
            if (staff.User__c == null || Test.isRunningTest()) {
                users.add(createUser(staff));
            }
        }
        insert users;
        
        staffs = new List<Contact>();
        // Now update the User lookup on Staff__c records.
        for (User usr : users) {
            staffs.add(new Contact(Reference_Id__c=usr.Reference_Id__c,User__c=usr.Id));
        }
        upsert staffs reference_Id__c; 
    }
    
    private User createUser(Contact staffContact) {
        User usr = new User(IsActive=true);
        usr.Alias = staffContact.FirstName.substring(0,1) + staffContact.LastName;
        if (usr.Alias.length() > 4) {
            usr.Alias = usr.Alias.substring(0,4);
        }
        usr.Email = 'nycdoedev@gmail.com';
        usr.EmailEncodingKey = 'UTF-8';
        usr.FirstName = staffContact.FirstName;
        usr.LastName =staffContact.LastName; 
        usr.LanguageLocaleKey = 'en_US';
        usr.LocaleSidKey = 'en_US'; 
        usr.ProfileId = [select id from Profile where Name ='Standard User'].id;
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        usr.Username = staffContact.User_Name__c + '@schools.nyc.gov.dev';
        if (Test.isRunningTest()) usr.Username +='x';
        usr.Reference_Id__c = staffContact.Reference_Id__c;
        return usr;
    }
    
    private void processStudentSchools(){ 
        //Primary External Key for Student is Reference_Id__c
        core_triggerUtils.studentTriggerUpdate(true);
        for (HoldingObj__c holder : batch) {
            holder.Propagated__c = true;
            holder.Error_Message__c = null;
            //String studentSchoolGradeKey = CT_ImportUtils.createStudentSchoolGradeKey(holder);
            String studentSchoolGradeKey = CT_ImportUtils.createStudentSchoolYearKey(holder, cSetup.School__r.RecordType.Name == 'Summer School');
            if ((studentSchoolGradeKey != null) && !studentSchoolGradesByKey.containsKey(studentSchoolGradeKey)) {
                Student__c student = CT_ImportMappers.createStudentSchoolGradeMapper().generate(holder, cSetup.School__r.RecordType.Name == 'Summer School');
//                student.Reference_Id__c = studentSchoolGradeKey;
                if (yearNameMap.get(holder.school_year__c)!=null){
                    student.School_Year__c = yearNameMap.get(holder.school_year__c).id; //Map the string name value for the year to the actual time element value
                }
                if(cSetup!=null) {
                    student.Setup__c = cSetup.Id;
                    student.isNeedActivate__c = cSetup.Active__c;//Active__c = cSetup.Active__c;
                }
                studentSchoolGradesByKey.put(studentSchoolGradeKey, student);
                Set<String> grades = gradesBySchoolDBN.get(holder.School_Dbn__c);
                if (grades == null) {
                    grades = new Set<String>();
                    gradesBySchoolDBN.put(holder.School_Dbn__c, grades);
                }
                grades.add(CT_ImportUtils.normalizeGrade(holder.Grade_level__c));
            }else{
                lstMsgs.add('Student '+holder.First_Name__c + ' '+holder.Last_Name__c+' was skipped. <a href="/'+holder.Id+'">Template</a>');
            }
        }
        processErrors(
                studentSchoolGradesByKey.values(),
                Database.upsert(studentSchoolGradesByKey.values(), Student__c.Reference_Id__c, false),
                Student__c.Holding_Source__c);
        core_triggerUtils.studentTriggerUpdate(true);
    }
    
    private void processStudentContacts() {
        //Primary External Key for Contacts is Reference_Id__c
        core_triggerUtils.studentTriggerUpdate(false);
        for (HoldingObj__c holder : batch) {
        
            if (!studentsByExternalId.containsKey(holder.Local_Student_ID__c)) {
                Contact studentContact = CT_ImportMappers.createStudentContactMapper().generate(holder);
                studentsByExternalId.put(holder.Local_Student_ID__c, studentContact); 
            }
        }
        processErrors(
                studentsByExternalId.values(),
                Database.upsert(studentsByExternalId.values(), Contact.Reference_Id__c, false),
                Contact.Holding_Source__c);
        core_triggerUtils.studentTriggerUpdate(true);    
    }

    private void processStudentSections() {
        core_triggerUtils.studentTriggerUpdate(false);
        Boolean isSummerSchool = cSetup.School__r.RecordType.Name == 'Summer School';

        //retrieve student and section ids
        for (HoldingObj__c holder : batch) {
            holder.Propagated__c = true;
            holder.Error_Message__c = null;

            Section__c section = new Section__c(Reference_Id__c = CT_ImportUtils.createClassSectionKey(holder));
            sectionsByKey.put(section.Reference_ID__c, section);
            Student__c student = new Student__c(Reference_ID__c = CT_ImportUtils.createStudentSchoolYearKey(holder, isSummerSchool));
            studentSchoolGradesByKey.put(student.Reference_ID__c, student);
        }
        Database.upsert(sectionsByKey.values(), Section__c.Reference_ID__c , false); 
        Database.upsert(studentSchoolGradesByKey.values(), Student__c.Reference_ID__c , false);

        // Create the StudentSection Joiners
        for (HoldingObj__c holder : batch) {
            Section__c section = sectionsByKey.get(CT_ImportUtils.createClassSectionKey(holder));
            Student__c student = studentSchoolGradesByKey.get(CT_ImportUtils.createStudentSchoolYearKey(holder, isSummerSchool));
            if (student!=null && section!=null) {
                Student_Section__c studentSection = new Student_Section__c();
                studentSection.Student__c = student.Id;
                studentSection.Section__c = section.Id;
                studentSection.Holding_Source__c = holder.id;
                studentSection.Reference_ID__c = CT_ImportUtils.createStudentSectionKey(holder);
                studentSectionsByKey.put(studentSection.Reference_ID__c, studentSection);
            }
        }

        processErrors(
                studentSectionsByKey.values(),
                Database.upsert(studentSectionsByKey.values(), student_section__c.Reference_ID__c , false), 
                Student_Section__c.Holding_Source__c); 

        core_triggerUtils.studentTriggerUpdate(true);
    }

}