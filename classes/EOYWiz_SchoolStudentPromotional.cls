public with sharing class EOYWiz_SchoolStudentPromotional {

    //School Progress
    public EOY_Progress__c schoolProgress {get; set;}
    private String EOYID {get; set;}
    public ID EOYrecordType {get; set;}
    
    //pass back parameters
    private String activeYear {get; set;}
    private String nextYear {get; set;} 
    
    //Display List for Page
    //public List<Student__c> dStudents {get; set;}
    public List<Student__c> failedStudents {get; set;}
    
    //public thousandLimitWrapper [] thousandBlocks = new thousandLimitWrapper[] {};
    public List<thousandLimitWrapper> thousandBlocks {get; set;}
    private final Integer listLimit = 999;
    
    public List<SelectOption> selectSchoolOptions {get; set;}
    
    //CSV process
    public String fileContentType {get; set;}
    public String fileName {get; set;}
    public String fileSize {get; set;}
    public Blob fileBlob {get; set;}
    public String csvData {get; set;}
    private String fileString;
    private CSVUtils.CSVParser parser;
    
    //used to check for changes in student records?
    public Boolean unsaved {get; set;}
    private Boolean initializationError {get; set;}
    
    public static String warning1 = 'Please review students\' promotional statuses.';
    public static String warning2 = 'There are changes made, please save when done.';
    public static String success1 = 'Success! The students\' promotional statuses has been updated.';
    public static String success2 = 'Success! The students\' promotional statuses have been finalized.';
    public static String error1 = 'Error! There was a problem, please start from the EOY home page.';
    public static String error2 = 'Error! The students\' promotional statuses were not finalized.';
    
    public EOYWiz_SchoolStudentPromotional() {
        schoolProgress = new EOY_Progress__c();
        EOYID = '';
        activeYear = apexPages.currentPage().getParameters().get('activeYear');
        nextYear = apexPages.currentPage().getParameters().get('nextYear');
        
        //dStudents = new List<Student__c>();
        failedStudents = new List<Student__c>();
        
        fileName= 'testing';
        
        unsaved = false;
        initializationError = false;
        
        EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');
        
        initialize();
    }
    
    private void initialize() {     
        //just need to call these two methods for re-initalization
        getSchoolProgress();
        getInitialStudents();
        
        selectSchoolOptions = getActiveSchools();
        if(!schoolProgress.School_Student_Promotional_Completed__c && !initializationError) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.WARNING, warning1));
        }
    }
    
    public pageReference gotoSchoolGradeSpan() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolGradeSpan');
        p.getParameters().put('selectedProgress', EOYID);
        p.getParameters().put('activeYear', activeYear);
        p.getParameters().put('nextYear', nextYear);
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoSchoolNextYearStudents() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolNextYearStudents');
        p.getParameters().put('selectedProgress', EOYID);
        p.getParameters().put('activeYear', activeYear);
        p.getParameters().put('nextYear', nextYear);
        p.setRedirect(true);
        return p;
    }
    
    public void closeInput() {
        //just to reset the message
        apexPages.addMessage(new apexPages.message(apexPages.Severity.WARNING, warning1));
    }
    
    public void uploadCSV() {
        system.debug('*~*~* uploadCSV');
        system.debug('*~*~* fileBlob: ' + fileBlob);
        try {
            if(fileBlob != null) {
                fileString = fileBlob.toString();
                fileBlob = null;
            }
            else {
                apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'Please select a file.'));
                return;
            }
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, e.getMessage()));
            throw e;            
        }
        
        parser = new CSVUtils.CSVParser(fileString, true);
        fileString = '';
        parser.parse();
        if(parser.errorMessage != null && parser.errorMessage != '') {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, parser.errorMessage));
        }
        
        //dStudents.clear();
        thousandBlocks.clear();
    	//thousandBlocks = new thousandLimitWrapper []{};
    	
    	integer counter = 0;
    	integer loopcount = 0;
    	Student__c [] local = new Student__c[] {};		
		
        try {
            for(String[] line : parser.parsedData) {
                system.debug('line: ' + line);
                Student__c temp = new Student__c(
                    Id = (ID)line[0],
                    Student_Id__c = line[1],
                    Name = line[2],
                    Grade__c = line[3],
                    Eligible_For_Enrollment__c = (line[4].contains('t')||line[4].contains('T')),
                    Intent_to_Return_Following_Year__c = (line[5].contains('t')||line[5].contains('T')),
                    Promoted__c = (line[6].contains('t')||line[6].contains('T')),
                    //Next_School__c = (line[6],
                    Final_Grade_Level__c = (line[7].contains('t')||line[7].contains('T'))
                );
                if(line[8] != '') {
                    temp.Next_School__c = line[8];
                }
                //DE3405
                else {
                	temp.Next_School__c = null;
                }
	    		if(counter < listLimit) {
	    			local.add(temp);
	    			counter++;
	    		}
	    		else {
	    			loopCount++;
	    			local.add(temp);
	    			thousandBlocks.add(new thousandLimitWrapper(local, loopCount));
	    			local = new Student__c []{};
	    			counter = 0;
	    		}            
            }
            
	    	loopCount++;
	    	thousandBlocks.add(new thousandLimitWrapper(local, loopCount));

        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, e.getMessage()));
            throw e;
        }
        //if it gets here must be succeses!
        apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, 'Success! File uploaded.'));
        system.debug('*~*~* thousandBlocks: ' + thousandBlocks);
    }
    
    public pageReference downloadCSV() {
        String genDate = system.today().month() + '-' + system.today().day() + '-' + system.today().year();
        fileName = 'StudentPromotionalStatus_' + genDate;
        pageReference p = new pageReference('/apex/EOYWiz_SchoolCSV');
        return p;       
    }
    
    public Boolean saveFunction() {
        Database.saveResult[] results;
        List<Student__c> toUpdate = new List<Student__c>();
        
        for(thousandLimitWrapper tlw : thousandBlocks) { 
			toUpdate.addAll(tlw.students);
        }
        
        try {
            //system.debug('before updating: ' + dStudents);       
        	results = Database.update(toUpdate);
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.FATAL, e.getMessage()));
            throw e;
        }
        
        //commented out with thousanBlocks logic added
        Boolean successFlag = true;
        if(results != null) {
            for(Database.saveResult result : results) {
                if(!result.isSuccess()) {
                    if(successFlag) {
                        successFlag = false;
                    }
                    Database.Error[] errs = result.getErrors();
                    for(Database.Error err : errs) {
                        system.debug(err.getStatusCode() + ' - ' + err.getMessage());
                    }
                }
            }
        }
        return successFlag;    	
    }
    
    public void saveStudentUpdates() {
        if(saveFunction()) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, success1));
        }      
        
        setLastModified();
        getSchoolProgress();
        getStudents();      
    }
    
    public void finalizeStudentUpdates() {
        
        //perform some heavy validation here!
        //need to know grade span of the following year?
        Map<ID, Set<String>> schoolToNextYearGradeSpan = getNextYearGradeSpan();
        Boolean success = true;

    	Map<String, String> gradeToNextGrade = getGradeNextGrade();
		failedStudents.clear();
        List<String> studentsNoNextSchool = new List<String>();
        
        for(thousandLimitWrapper tlw : thousandBlocks) {
	        //for(Student__c s : dStudents) {
	        for(Student__c s : tlw.students) { 
	            //intending to return then...
	            if(s.Intent_to_Return_Following_Year__c && s.Eligible_For_Enrollment__c) {
	                //this must be populated!
	                if(s.Next_School__c == null) {
	                    if(success) {
	                        success = false;
	                    }
	                    failedStudents.add(s);
	                }
	                else {
	                    if(s.Promoted__c) {
	                        system.debug('*~*~* student: ' + s.Name);
	                        system.debug('*~*~* current grade: ' + s.Grade__c);
	                        if(gradeToNextGrade.containsKey(s.Grade__c)) {
	                            if(!schoolToNextYearGradeSpan.get(s.Next_School__c).contains(gradeToNextGrade.get(s.Grade__c))) {
	                                //this is an error, the next year school's gradespan does not include the promoted grade level.
	                                if(success) {
	                                    success = false;
	                                }
	                                failedStudents.add(s);                      
	                            }
	                        }
	                        else {
	                            //we are in trouble!
	                        }
	                    }
	                    else if(!s.Promoted__c) {
	                        if(!schoolToNextYearGradeSpan.get(s.Next_School__c).contains(s.Grade__c)) {
	                            //this is an error, the next year school's gradespan does not include the current grade level.
	                            //what to do with student?
	                            if(success) {
	                                success = false;
	                            }
	                            failedStudents.add(s);
	                        }
	                    }
	                }
	            }
	            //DE3176
	            else if(!s.Eligible_For_Enrollment__c && s.Intent_to_Return_Following_Year__c) {
	                failedStudents.add(s);
	                if(success) {
	                    success = false;
	                }
	            }
	            //DE3311
	            else if(!s.Eligible_For_Enrollment__c && !s.Intent_To_Return_Following_Year__c) {
	            	if(s.Next_School__c != null) {
	            		failedStudents.add(s);
	            		if(success) {
	            			success = false;
	            		}
	            	}
	            	else {
	            		//don't throw an error...
	            	}
	            }
	            else if(s.Eligible_For_Enrollment__c && !s.Intent_To_Return_Following_Year__c) {
	            	//pointless but should not throw an error
	            	if(s.Next_School__c != null) {
	            		failedStudents.add(s);
	            		if(success) {
	            			success = false;
	            		}
	            	}
	            }
	            //DE3261
	            else {
	            	//technically, do nothing, this should capture the cases where:
	            	//if(!s.Intent_to_Return_Following_Year__c && !s.Eligible_For_Enrollment__c)
	            	//if(!s.Intent_to_Return_Following_Year__c && s.Eligible_For_Enrollment__c)
	            	//if that is true, Batch_CreateStudents ignore this case anyways, well checks for Intent to return = true
	            }
	        }
        }
        
        if(success) {
            schoolProgress.School_Student_Promotional_Completed__c = true;
            //saveStudentUpdates();
            if(saveFunction()) {
            	apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, success2));
        	}      
        
        	setLastModified();
        	getSchoolProgress();
        	getStudents();             	
        }
        else {
            String students = ' Please review these students: ';
            for(Integer i = 0; i < failedStudents.size(); i++) {
                students += failedStudents[i].Name;
                if(i != failedStudents.size()-1) {
                    students += ', ';
                }
            }
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, error2 + students));
        }
    }
    
    public void setLastModified() {
        user u = [SELECT ID, Name FROM User WHERE ID =: UserInfo.getUserID() LIMIT 1];
        String timeZone = UserInfo.getTimeZone().getID();
        schoolProgress.School_Student_Promotional_Last_Modified__c = u.Name + ' ' + dateTime.now().format('MM/dd/yyyy hh:mm:ss a', timeZone);
        upsert schoolProgress;
    }   
    
    public void getSchoolProgress() {
        if(!initializationError) {
            EOYID = apexPages.currentPage().getParameters().get('selectedProgress');
            if(EOYID != null) {
                system.debug('eoyID: ' + EOYID);
                schoolProgress = [SELECT ID, School_Student_Promotional_Completed__c, School_Student_Promotional_Last_Modified__c, School__c, School__r.Name, Setup__c, Year__c FROM EOY_Progress__c WHERE ID =: EOYID AND RecordTypeID =: EOYrecordType];
            }
            else {
                //should display an error message here
                initializationError = true;
                apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, error1));
            }
        }
    }
    
    public void getInitialStudents() {
        if(!initializationError) {
            try {
            	/*
            	Map<ID, Set<String>> nextYearGradeSpan = getNextYearGradeSpan();
            	Map<String, String> gradeToNextGrade = getGradeNextGrade();

            	dStudents.clear();
            	for(Student__c s : [SELECT ID, Student_ID__c, Name, Grade__c, Intent_to_Return_Following_Year__c, Promoted__c, School__c, Next_School__c, Final_Grade_Level__c, Eligible_For_Enrollment__c FROM Student__c WHERE School_Year__c =: schoolProgress.Year__c AND School__c =: schoolProgress.School__c AND (Active__c = true OR Setup__c =: schoolProgress.Setup__c)]) {
            		if(s.School__c != null && s.Next_School__c == null && s.Eligible_For_Enrollment__c)	{
            			if(nextYearGradeSpan.get(s.School__c).contains(gradeToNextGrade.get(s.Grade__c))) {
            				s.Next_School__c = s.School__c;
            			}
            		}
            		dStudents.add(s);
            	}
                //dStudents = [SELECT ID, Student_ID__c, Name, Grade__c, Intent_to_Return_Following_Year__c, Promoted__c, Next_School__c, Final_Grade_Level__c, Eligible_For_Enrollment__c FROM Student__c WHERE School_Year__c =: schoolProgress.Year__c AND School__c =: schoolProgress.School__c AND (Active__c = true OR Setup__c =: schoolProgress.Setup__c)];
            	*/
            	thousandBlocks = getInitialThousandBlocks();
            } 
            catch(Exception e) {
                apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, e.getMessage()));
                throw e;
            }
        }    
    }
    public void getStudents() {
        if(!initializationError) {
            try {
            	/*
            	Map<ID, Set<String>> nextYearGradeSpan = getNextYearGradeSpan();
            	Map<String, String> gradeToNextGrade = getGradeNextGrade();
            	
            	dStudents = [SELECT ID, Student_ID__c, Name, Grade__c, Intent_to_Return_Following_Year__c, Promoted__c, School__c, Next_School__c, Final_Grade_Level__c, Eligible_For_Enrollment__c FROM Student__c WHERE School_Year__c =: schoolProgress.Year__c AND School__c =: schoolProgress.School__c AND (Active__c = true OR Setup__c =: schoolProgress.Setup__c)];
                //dStudents = [SELECT ID, Student_ID__c, Name, Grade__c, Intent_to_Return_Following_Year__c, Promoted__c, Next_School__c, Final_Grade_Level__c, Eligible_For_Enrollment__c FROM Student__c WHERE School_Year__c =: schoolProgress.Year__c AND School__c =: schoolProgress.School__c AND (Active__c = true OR Setup__c =: schoolProgress.Setup__c)];
            	*/
            	getThousandBlocks();
            } 
            catch(Exception e) {
                apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, e.getMessage()));
                throw e;
            }
        }
    }
    
    private Map<ID, Set<String>> getNextYearGradeSpan() {
        Map<ID, Set<String>> returnValue = new Map<ID, Set<String>>();
        
        for(Setup__c setup : [SELECT ID, Grade_Span__c, School__c, Year__c, New_School_Year__c FROM Setup__c WHERE Year__c =: nextYear AND New_School_Year__c = true]) {
            if(setup.School__c != null && setup.Grade_Span__c != null) {
                if(!returnValue.containsKey(setup.School__c)) {
                    //parse the grade span into a set!
                    Set<String> tGradeLevels = new Set<String>();
                    tGradeLevels.addAll(setup.Grade_Span__c.split(';'));
                    returnValue.put(setup.School__c, tGradeLevels);
                }
                else {
                    //should not get here!!!
                    system.debug('why are there multiple setup records for the next school year??? ' + setup);
                }
            }
            else {
                //should not get here!!!
                system.debug('why is the school and gradespan empty for this record???: ' + setup);
            }
        }
        return returnValue;
    }
    
    private Map<String, String> getGradeNextGrade() {
	    //DE3088
	    //get picklist value for grade
	    //create the map for grade comparison
	    Map<String, String> gNG = new Map<String, String>();
	    Schema.DescribeFieldResult gradePicklist = Student__c.Grade__c.getDescribe();
	    List<Schema.Picklistentry> gradePicklistEntry = gradePicklist.getPicklistValues();
	    for(Integer i = 0; i < gradePicklistEntry.size(); i++) {
	        if(i != gradePicklistEntry.size() - 1) {
	            Integer j = i + 1;
	            gNG.put(gradePicklistEntry[i].getValue(), gradePicklistEntry[j].getValue());
	        }
	        else {
	            gNG.put(gradePicklistEntry[i].getValue(), '');
	        }
	    }    
	    return gNG;	
    }
    
    private List<SelectOption> getActiveSchools() {
        List<SelectOption> options = new List<SelectOption>();
        String rtID = core_SoqlUtils.getRecordTypesbySobject('Account').get('School');
        options.add(new SelectOption('', ''));
        for(Account school : [SELECT ID, Name FROM Account WHERE recordTypeID =: rtID AND Is_Active__c = true]) {
            options.add(new SelectOption(school.ID, school.Name));
        }
        return options;
    }
    
    public class thousandLimitWrapper {
    	public Student__c [] students {get; set;}
    	public integer blockNumber {get; set;}
    	
    	public thousandLimitWrapper (Student__c [] sl, Integer i) {
    		students = sl;
    		blockNumber = i;
    	}
    }
    
    public thousandLimitWrapper[] getInitialThousandBlocks() {
    	Map<ID, Set<String>> nextYearGradeSpan = getNextYearGradeSpan();
        Map<String, String> gradeToNextGrade = getGradeNextGrade();
    
    	thousandBlocks = new thousandLimitWrapper []{};
    	
    	integer counter = 0;
    	integer loopcount = 0;
    	Student__c [] local = new Student__c[] {};
    	
    	//for(List<Student__c> ls : [SELECT ID, Student_ID__c, Name, Grade__c, Intent_to_Return_Following_Year__c, Promoted__c, School__c, Next_School__c, Final_Grade_Level__c, Eligible_For_Enrollment__c FROM Student__c WHERE School_Year__c =: schoolProgress.Year__c AND School__c =: schoolProgress.School__c AND (Active__c = true OR Setup__c =: schoolProgress.Setup__c)]) {
		for(List<Student__c> ls : [SELECT ID, Student_ID__c, Name, Grade__c, Intent_to_Return_Following_Year__c, Promoted__c, School__c, Next_School__c, Final_Grade_Level__c, Eligible_For_Enrollment__c FROM Student__c WHERE School_Year__c =: schoolProgress.Year__c AND School__c =: schoolProgress.School__c AND (Active__c = true OR (Setup__c =: schoolProgress.Setup__c AND Active__c = false AND Created_Next_Year_Student__c = true))]) {	    

	    	for(Student__c s : ls) {
	    		if(s.School__c != null && s.Next_School__c == null && s.Eligible_For_Enrollment__c && !schoolProgress.School_Student_Promotional_Completed__c)	{
	    			if(nextYearGradeSpan.get(s.School__c).contains(gradeToNextGrade.get(s.Grade__c))) {
	    				s.Next_School__c = s.School__c;
	    			}
	    		}
	    		
	    		if(counter < listLimit) {
	    			local.add(s);
	    			counter++;
	    		}
	    		else {
	    			loopCount++;
	    			local.add(s);
	    			thousandBlocks.add(new thousandLimitWrapper(local, loopCount));
	    			local = new Student__c []{};
	    			counter = 0;
	    		}
	    	}
    	}
		
    	loopCount++;
    	thousandBlocks.add(new thousandLimitWrapper(local, loopCount));

    	return thousandBlocks;
    }
    
	public thousandLimitWrapper[] getThousandBlocks() {		
    	
    	thousandBlocks = new thousandLimitWrapper []{};
    	
    	integer counter = 0;
    	integer loopcount = 0;
    	Student__c [] local = new Student__c[] {};
    	
    	//for(List<Student__c> ls : [SELECT ID, Student_ID__c, Name, Grade__c, Intent_to_Return_Following_Year__c, Promoted__c, School__c, Next_School__c, Final_Grade_Level__c, Eligible_For_Enrollment__c FROM Student__c WHERE School_Year__c =: schoolProgress.Year__c AND School__c =: schoolProgress.School__c AND (Active__c = true OR Setup__c =: schoolProgress.Setup__c)]) {
    	for(List<Student__c> ls : [SELECT ID, Student_ID__c, Name, Grade__c, Intent_to_Return_Following_Year__c, Promoted__c, School__c, Next_School__c, Final_Grade_Level__c, Eligible_For_Enrollment__c FROM Student__c WHERE School_Year__c =: schoolProgress.Year__c AND School__c =: schoolProgress.School__c AND (Active__c = true OR (Setup__c =: schoolProgress.Setup__c AND Active__c = false AND Created_Next_Year_Student__c = true))]) {

	    	for(Student__c s : ls) {
	    		
	    		if(counter < listLimit) {
	    			local.add(s);
	    			counter++;
	    		}
	    		else {
	    			loopCount++;
	    			local.add(s);
	    			thousandBlocks.add(new thousandLimitWrapper(local, loopCount));
	    			local = new Student__c []{};		
	    			counter = 0;
	    		}
	    	}
    	}

    	loopCount++;
    	thousandBlocks.add(new thousandLimitWrapper(local, loopCount));

    	return thousandBlocks;
    }
}