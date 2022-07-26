global class SharingConfigurator {/*implements Database.Batchable<SObject>{
  
    global Data_Load_Log__c log;            // log used to record information about success/failures    
    
    // constructor
    global SharingConfigurator() {
        log = new Data_Load_Log__c(Type__c='Student Share Calculations',Status__c='Pending');
        insert log;         
    }
    
    // define the query to extract all of the students from the student object
    global final String query   =   'Select a.Id, a.School__c From Student__c a Order By a.School__c';
        
    // implement the interface method "start"
    global Database.QueryLocator start(Database.BatchableContext bc)  {
        
        // set up the Data Load Log object
        log.Status__c = 'Running';
        log.Batch_ID__c = bc.getJobId();
        log.Total_Records__c = 0;
        log.Failed_Records__c = 0;
        update log;
        
        return Database.getQueryLocator(query);
    } // end start()
    
    // implement the interface method "execute"
    global void execute(Database.BatchableContext bc, List<sObject> batch){
        // Create a section share record list
        Set<Section__Share> setSectionShares    =   new Set<Section__Share>();
        
        // Create a student share record list
        Set<Student__Share> setStudShares   =   new Set<Student__Share>();
        
        // process the list of student records into a map indexed by school ID 
        Map<Id, List<Student__c>> mapStudSchoolIndex    =   this.getSchoolStudent(batch);
        
        if( mapStudSchoolIndex.size() > 0 ) {       // there must be at least one student record to process
            
            // obtain a map to associate the students to sections in which they are enrolled
            Set<Id> setStudSchoolIndex  =   mapStudSchoolIndex.keySet();    // set of keys (School Ids)
            
            for( Id acctStudent : setStudSchoolIndex ){  // for each school...
                
                // obtain the students and sections
                List<Student__c> listStuds                      =   mapStudSchoolIndex.get(acctStudent);    // student map indexed by school
                
                //System.debug('>>>>> listStuds: ' + listStuds );   
                Map<Id, List<Student__c>>   mapStudentSections  =   this.getStudentSections(listStuds);     // student map indexed by section
                
                if( mapStudentSections.size() > 0 ) {       // there must be at least one student section record to process
                    // obtain the staff for each section
                    List<Id> listStudentSects   =   new List<Id>();
                    listStudentSects.addAll(mapStudentSections.keySet());                                       // obtain the list of sections with which we are concerned.
                    
                    Map<Id, List<Staff_Section__c>> mapStaffSections    =   this.getSchoolStaff(listStudentSects);      // staff map indexed by section 
                    
                    if( ( mapStaffSections != null ) || ( mapStaffSections.size() > 0 ) ) {     // there must be at least one staff record to process
                    
                        for( Id sec : listStudentSects ) {      // iterate through the sections
                            List<Student__c>    listStudsOfInterest =   mapStudentSections.get(sec);    // obtain the list of students for that section
                            List<Staff_Section__c>  listStaffOfInterest     =   mapStaffSections.get(sec);      // obtain the list of staff that instruct for that section
                            
                            // associate the staff to the section share
                            try{
                                for( Staff_Section__c staffOfInt    :   listStaffOfInterest ){
                                    if( staffOfInt.staff__r.Individual__r.User_ID__c != null ) {    // don't try to create share records with staff who have no user id
                                        Section__Share sectShare    =   new Section__Share( ParentId        =   sec,    
                                                                                            UserOrGroupID   =   staffOfInt.staff__r.Individual__r.User_ID__c,
                                                                                            AccessLevel     =   'Edit',
                                                                                            RowCause        =   Schema.Section__Share.RowCause.Staff_Access_To_Student_Record__c );
                                    
                                        setSectionShares.add(sectShare);    // add the section share record to the list of section share records.
                                    } // end if
                                } // end
        
                                // associate the staff to the student share
                                for( Student__c studOfInterest : listStudsOfInterest ) {    // iterate through the students in a particular section
                                    for( Staff_Section__c staffOfInterest : listStaffOfInterest ){  // iterate through the staff instructors for a particular section
                                        if( staffOfInterest.staff__r.Individual__r.User_ID__c != null ) {   // don't try to create share records with staff who have no user id
                                            Student__Share  studShare   =   new Student__Share( ParentId        =   studOfInterest.Id,          // create the "share" record for the student
                                                                                                UserOrGroupID   =   staffOfInterest.staff__r.Individual__r.User_ID__c,
                                                                                                AccessLevel     =   'Edit',
                                                                                                RowCause        =   Schema.Student__Share.RowCause.Staff_Access_To_Student_Record__c);
                                            
                                            setStudShares.add(studShare);       // add the student share record to the list of student shares.
                                        } // end if
                                    } // end for listStaffOfInterest
                                } // end for listStudsOfInterest
                            } catch (Exception e) {
                                System.debug('>>>>> exception: ' + e);
                            }
                        } // end for listStudentSects
                        
                        if( setStudShares.size() > 0){
                            
                            List<Student__Share> deletables     =   [ Select s.Id From Student__Share s Where s.RowCause =: Schema.Student__Share.RowCause.Staff_Access_To_Student_Record__c And s.ParentId In: listStuds ];
                            List<Section__Share> deletables2    =   [ Select s.Id From Section__Share s Where s.RowCause =: Schema.Section__Share.RowCause.Staff_Access_To_Student_Record__c And s.ParentId In: listStudentSects ];
                            
                            if( deletables.size() > 0 ) {   // delete all of the exising student share records (if any) to insure a clean set of sharing rules
                                delete deletables;  
                            } // end if
                            
                            if( deletables2.size() > 0 ) {  // delete all of the existing section share records (if any) to insure a clean set of sharing rules
                                delete deletables2; 
                            } // end if
                            
                            
                            try {
                                
                                // Database operations do not allow for the insertion of "sets" of data...so convert the sets to lists for insertion
                                List<Section__Share> sectShareLoad          =   new List<Section__Share>();
                                List<Student__Share> studentShareLoad       =   new List<Student__Share>();
                                sectShareLoad.addAll(setSectionShares);     
                                studentShareLoad.addAll(setStudShares);
                                
                                List<Database.SaveResult> sectShareResults  =   Database.insert( sectShareLoad, false );
                            
                                if( sectShareResults != null ){
                                    for( Database.SaveResult sr1 : sectShareResults ){
                                        if( !sr1.isSuccess() ) {
                                            Database.error error    =   sr1.getErrors()[0];
                                            
                                           if( !( error.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  
                                                                 &&  error.getMessage().contains('AccessLevel') ) ){        // no trivial error
                                                log.Status__c   =   error.getMessage();                                     // submit error message to data load log entry
                                                upsert log;
                                           } // end if
                                        } // end if
                                    } // end for sr1
                                } // end if
                                            
                                List<Database.SaveResult> studShareResults  =   Database.insert( studentShareLoad, false );

                                if( studShareResults != null ){
                                    for( Database.SaveResult sr2 : studShareResults ) {
                                        if( !sr2.isSuccess() ) {
                                            Database.error error2   =   sr2.getErrors()[0];
                                            
                                           if( !( error2.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  
                                                                 &&  error2.getMessage().contains('AccessLevel') ) ){       // no trivial error
                                                log.Status__c   =   error2.getMessage();                                    // submit error message to data load log entry
                                                upsert log;
                                           } // end if
                                        } // end if
                                    } // end for
                                } // end if
                
                            } catch( DMLException e ) {
                                log.Messages__c = e.getMessage();   // log the error
                                upsert log;
                                //System.debug('>>>>> DML Errors: ' + e );              
                            } // end try/catch 
                        } // end if                     
                    } else {
                        log.Messages__c = 'There aren\'t any staff section records that meet our needs.';   
                        upsert log;
                    }// end if
                    
                } else {
                    log.Messages__c = 'There aren\'t any student section records to process.';
                    upsert log; 
                } // end if 
                
            } // end for setStudSchoolIndex
            
        } else {
            log.Messages__c = 'There aren\'t any student records to process!';
            upsert log; 
        } // end if
    } // end execute()
    
    // implement the interface method "finish"
    global void finish(Database.BatchableContext bc){
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                            from AsyncApexJob where Id =: bc.getJobId()];
        log.Status__c   = 'Completed';
        log.Messages__c = 'There were ' + a.NumberOfErrors + ' errors and ' + a.JobItemsProcessed + ' batch items processed out of ' + a.TotalJobItems + ' total items. ';
        upsert log;
        
    } // end finish() 

    // create the map of Student records indexed by School
    public Map<Id, List<Student__c>> getSchoolStudent(List<Student__c> pStudents){
        Map<Id, List<Student__c>> mapSchoolStudent  =   new Map<Id, List<Student__c>>();
        List<Account> listSchool                    =   new List<Account>();
        List<Student__c> listStudent                =   new List<Student__c>();
        String schoolComp                           =   '';
        Integer stopSchoolStudCnt                   = pStudents.size() - 1;                         // determine the final iteration value
                            
        Integer i = 0;
        for( Student__c student : pStudents ) {
            
            if (!mapSchoolStudent.keySet().contains(student.School__c)){
                mapSchoolStudent.put(student.School__c, new List <Student__c>{student});
            
            } else {
                mapSchoolStudent.get(student.School__c).add(student);
            } // end if
                                    
            i++;
        } // end for pStudents

        return mapSchoolStudent;
    } // end getSchoolStudent
    
    
    // obtain a list of all students found in the Student_Section__c
    public Map<Id, List<Student__c>> getStudentSections(List<Student__c> pStuds) {
        List<Student_Section__c> listStudSects  =   [Select a.Id, a.Section__c, a.Student__c From Student_Section__c a Where Active__c = true and a.Student__c in :pStuds Order By a.Section__c];
        Map<Id, List<Student__c>> mapStudSects  =   new Map<Id, List<Student__c>>();
        List<Section__c> listSects  =   new List<Section__c>();
        List<Student__c> listStuds  =   new List<Student__c>();
        String sectComp = '';
        Integer stopStudCnt     = listStudSects.size() - 1;                     // determine the final iteration value
        
        Integer j=0;        
        for( Student_Section__c SSect : listStudSects ) {           
            if (!mapStudSects.keySet().contains(SSect.Section__c)){
                mapStudSects.put(SSect.Section__c, new List <Student__c>{new Student__c(Id = SSect.Student__c)});
            
            } else {
                mapStudSects.get(SSect.Section__c).add(new Student__c(Id = SSect.Student__c));
            } // end if     
            j++;            
            
        } // end for
        
        
        return mapStudSects;    
    }
    
    // create the map of Staff records indexed by School
    public Map<Id, List<Staff_Section__c>> getSchoolStaff(List<Id> pSects){
        Map<Id, List<Staff_Section__c>> mapSchoolStaff  =   new Map<Id, List<Staff_Section__c>>();
        List<Staff_Section__c> listStaffSection =   [ Select s.Staff__c, s.Section__c, s.Staff__r.Individual__r.User_ID__c From Staff_Section__c s Where Is_Active__c = true and s.Section__c in :pSects Order By s.Section__c ];
                
        // need to organize the listStaffSection into a map with section as the key                 
        if( listStaffSection.size()<= 0 ) {     // if there are no records with an available user ID, then there is no need to continue
            log.Messages__c = 'There weren\'t any user IDs associated for staff IDs attributed to the list of sections: ' + pSects;
            upsert log;
        } else {
            
            Integer k = 0;
            for (Staff_Section__c stSect : listStaffSection){
                if( !mapSchoolStaff.containsKey(stSect.section__c) ) {  
                    mapSchoolStaff.put(stSect.section__c, new List<Staff_Section__c>{stSect});      // there is a new section to add to the map
                } else {
                    mapSchoolStaff.get(stSect.section__c).add(stSect);  // update the existing map entries that have that key value to include this section includes the additional staff
                } // end if         
                                            
                k++;    
            } // end for
                                
        } // end if
                
        return mapSchoolStaff;

    } // end getSchoolStaff
    */

} // end SharingConfigurator