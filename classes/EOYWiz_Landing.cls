public without sharing class EOYWiz_Landing {
/*
    Programmer's notes:
    The objective of this Wizard is to direct the user through a step by step process for the end of year (EOY) school process .
    There is an initial step of providing a setting for an 'Org wide setting'.  In this step the system administrator must provide
    the EOY Purge objects for 1 year and 2 years.  Also in this inital step the user must create the net new next year to allow 
    the addition of students to that year if it has not been done yet through the Setup Wizard.  
    Note that once a new year is created, additional setups are created for all of the Schools
    
    After initial steps there are additional steps to close out each school in the org.  Currently there are approximately 7 steps:
        * Validate the schools gradespan 
        * update the student's promotional status and school enrollment
        * Create net new student records for the new year
        * Create snapshot data
        
    These steps actually are not school dependent, should only validate after the above steps are completed
        * Process EOY Data (also known as deactivate Data)
        * Purge EOY Data
        * Purge Historical Data
            
    Enhancement: Module awareness
    With the addition of the Interventions Module, Development has decided that the EOY Process will generate the EOY Records for other
    Modules as necessary.  The detection Method will be querying for the various 'EOY_Landing' pages within the environment.  These pages should 
    be separated via their NamespacePrefix.  From there EOY_Progress records will be generated as appropriate with the note that a EOY_Landing page 
    with a blank NamespacePrefix should typically be the EOY_Landing page from the non-package version of SchoolForce.  The non-package EOY_Progress 
    version will own a Module_Name__c of 'SchoolForce' as well the as the package version of SchoolForce.
    
    Additional enhancement will be to allow this EOY_Landing page to be more cognizant of Schools created and net new Modules installed mid year.  
    Currently EOY_Progress record generation is a one time ordeal, upon arriving the landing page.  New functionality is to always check first and then 
    create as necessary.
*/
    public Map<ID, Setup__c> schoolToCurrentActiveSetup {get; set;}
    public Map<ID, EOY_Progress__c> schoolToEOYProgress {get; set;}
    public Map<String, EOY_Progress__c> currentOrgProgresses {get; set;}
    public Time_Element__c activeYear {get; set;}
    public Time_Element__c nextYear {get; set;}
    public ID EOYrecordType {get; set;}
    
    //display table
    public List<EOY_Progress__c> dEOYProgress {get; set;}
    
    //only for step 0
    public EOY_Progress__c orgWideProgress {get; set;}
    public Boolean orgWideComplete {get; set;}
	public Boolean schoolEOYComplete {get; set;}
	public Boolean moduleEOYComplete {get; set;}
    public String selectedProgress {get; set;}
    
    public Boolean initializationError {get; set;}

    //constructor
    public EOYWiz_Landing() {
        schooltoCurrentActiveSetup = new Map<ID, Setup__c>();       
        schooltoEOYProgress = new Map<ID, EOY_Progress__c>();
        currentOrgProgresses = new Map<String, EOY_Progress__c>();        
        dEOYProgress = new List<EOY_Progress__c>();

        initializationError = false;
        EOYrecordType = core_SoqlUtils.getRecordTypesBySobject('EOY_Progress__c').get('EOY');
        
        populateYearInformation();
    }
    
    //Org redirects
    public PageReference gotoOrgPurgeSettings() {
        pageReference p = new pageReference('/apex/EOYWiz_OrgPurgeSettings');
        //pass EOY_Progress__c record
        p.getParameters().put('EOY_Progress', (String)orgWideProgress.ID);
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoOrgNextSchoolYear() {
        pageReference p = new pageReference('/apex/EOYWiz_OrgNextYear');
        //pass EOY_Progress__c record
        p.getParameters().put('EOY_Progress', (String)orgWideProgress.ID);
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoOrgExport() {
        pageReference p = new pageReference('/apex/EOYWiz_OrgExport');
        //pass EOY_Progress__c record
        p.getParameters().put('EOY_Progress', (String)orgWideProgress.ID);
        p.setRedirect(true);
        return p;       
    }
    
    public void setSelectedProgress() {
        selectedProgress = apexPages.currentPage().getParameters().get('selectedProgress');
        system.debug('selectedProgress: ' + selectedProgress);      
    }
    
    public pageReference gotoSchoolGradeSpan() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolGradeSpan');
        p.getParameters().put('selectedProgress', selectedProgress);
        p.getParameters().put('activeYear', (String)activeYear.ID);
        p.getParameters().put('nextYear', (String)nextYear.ID);
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoSchoolStudentPromotional() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolStudentPromotional');
        p.getParameters().put('selectedProgress', selectedProgress);
        p.getParameters().put('activeYear', (String)activeYear.ID);
        p.getParameters().put('nextYear', (String)nextYear.ID);     
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoSchoolNextYearStudents() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolNextYearStudents');
        p.getParameters().put('selectedProgress', selectedProgress);
        p.getParameters().put('activeYear', (String)activeYear.ID);
        p.getParameters().put('nextYear', (String)nextYear.ID);     
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoSchoolSnapshots() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolSnapshots');
        p.getParameters().put('selectedProgress', selectedProgress);
        p.getParameters().put('activeYear', (String)activeYear.ID);
        p.getParameters().put('nextYear', (String)nextYear.ID);
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoSchoolProcessData() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolProcessData');
        p.getParameters().put('selectedProgress', selectedProgress);
        p.getParameters().put('activeYear', (String)activeYear.ID);
        p.getParameters().put('nextYear', (String)nextYear.ID);     
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoSchoolPurgeEOYData() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolPurgeEOYData');
        p.getParameters().put('selectedProgress', selectedProgress);
        p.getParameters().put('activeYear', (String)activeYear.ID);
        p.getParameters().put('nextYear', (String)nextYear.ID);     
        p.setRedirect(true);
        return p;
    }
    
    public pageReference gotoSchoolPurgeHistoricalData() {
        pageReference p = new pageReference('/apex/EOYWiz_SchoolPurgeHistoricalData');
        p.getParameters().put('selectedProgress', selectedProgress);
        p.getParameters().put('activeYear', (String)activeYear.ID);
        p.getParameters().put('nextYear', (String)nextYear.ID);     
        p.setRedirect(true);
        return p;
    }
    
    //verification and EOY_Progress record generation
    public void orgWideSettingsComplete() {
    	//this getSchoolProgress() is SchoolForce Main Package specific.
    	getSchoolProgress();
    	
        //search for EOY_Progress__c record for the year
        if(!initializationError) {
            try {
            	//updated to look specifically the Org EOY Progress that is SchoolForce or Module_Name__c is null
                for(EOY_Progress__c eoyP : [SELECT ID, EOY_Purge_Settings_Completed__c, EOY_Next_School_Year_Completed__c, Year__r.Name__c, Is_Complete__c, Module_Name__c, Parent_Progress__c FROM EOY_Progress__c WHERE School__c = null AND Year__c =: activeYear.ID AND RecordTypeID =: EOYrecordType AND (Module_Name__c = 'SchoolForce' OR Module_Name__c = null)]) {
                    if(orgWideProgress == null) {
                        orgWideProgress = eoyP;
                    } else {
                    	//DE3252
                        Error_Handling.errorMessage('There are more than one EOY_Progress__c for this year. Please request technical resource to verify the EOY_Progress__c states.');
                    }
                }
                
                //here, check to see if additional Module EOY Progress Records are needed.  Create them here.  Always check to see if there are any that needs to be created. 
                Map<String, EOY_Progress__c> insertOrgProgresses = new Map<String, EOY_Progress__c>();
                
                for(EOY_Progress__c ep : [SELECT ID, Is_Complete__c, Module_Name__c, Parent_Progress__c FROM EOY_Progress__c WHERE (Module_Name__c != 'SchoolForce' AND Module_Name__c != null) AND Year__c =: activeYear.ID]){
                	currentOrgProgresses.put(ep.Module_Name__c, ep);
                }

                //query for the remainder EOY_Landing via ApexPage      
            	for(ApexPage p : [SELECT ID, NamespacePrefix FROM ApexPage WHERE Name = 'EOYWiz_Landing' AND (NamespacePrefix != 'SchoolForce' AND NamespacePrefix != null)]) {
					if(!currentOrgProgresses.containsKey(p.NamespacePrefix) && !String.isBlank(p.NamespacePrefix)) {
						EOY_Progress__c newEP = new EOY_Progress__c();
						newEP.Module_Name__c = p.NamespacePrefix;
						newEP.Parent_Progress__c = orgWideProgress.ID;
						newEP.Year__c = activeYear.ID;
						insertOrgProgresses.put(newEP.Module_Name__c, newEP);
					}
            	}
            	
            	//check to see if there are any Org Progresses to insert
            	if(insertOrgProgresses.size() > 0) {
            		try {
            			insert insertOrgProgresses.Values();
            			//after insertion, place the items in the currentOrgProgresses
            			for(EOY_Progress__c iEP : insertOrgProgresses.Values()) {
            				currentOrgProgresses.put(iEP.Module_Name__c, iEP);
            			}
            		}
            		catch(DMLException d) {
            			ApexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'ERROR Inserting EOY Progress Record for Module: ' + d.getMessage()));
            		}
            	}
            }
            catch(Exception e) {
                Apexpages.addMessage(new apexPages.message(apexPages.severity.ERROR, 'The EOY_Progress__c query must have failed.  Conditional clause: WHERE School__c = null AND Year_Lookup__c =: activeYear.ID'));
            }
            
            //State validation, checks the Org Step 1, Org Step 2, and optional Org Step Export
            try {
            	if(!orgWideProgress.EOY_Purge_Settings_Completed__c || !orgWideProgress.EOY_Next_School_Year_Completed__c) {
            		orgWideComplete = false;
            		apexPages.addMessage(new apexPages.message(apexPages.Severity.WARNING, 'The Org Wide Settings are not completed. Please complete the Org Wide Settings.'));
            		return;
            	}
            	else if(orgWideProgress.EOY_Next_School_Year_Completed__c && nextYear == null) {
            		orgWideComplete = false;
            		apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'The Org Wide Settings step 2 is complete but the next year is null.  Please verify the Year records.'));
            		return;
            	}
                else if(orgWideProgress.EOY_Purge_Settings_Completed__c && orgWideProgress.EOY_Next_School_Year_Completed__c ) {
                    orgWideComplete = true;
                    if(!orgWideProgress.Is_Complete__c) {
                    	apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, 'The Org Wide Settings are completed.'));
                    }
                    //verify here if there are null setup records for the school progress.
                    for(EOY_Progress__c e : dEOYProgress) {
                    	if(e.Setup__c != null) {
                    		if(e.Setup__r.Year__c != activeYear.ID) {
                    			apexPages.addMessage(new apexPages.message(apexPages.Severity.WARNING, 'You have not activated a Setup for the current year for one or more schools.  Any school under School Settings Status that has an entirely gray progress bar is impacted.'));
                    			break;
                    		}
                    	}
                    	else {
                    		apexPages.addMessage(new apexPages.message(apexPages.Severity.WARNING, 'You have not activated a Setup for the current year for one or more schools.  Any school under School Settings Status that has an entirely gray progress bar is impacted.'));
                    		break;
                    	}
                    }
                    
                    if(!schoolEOYComplete) {
                    	apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, 'You have not completed the EOY Process for all of your schools.'));
                    }
                    //school Progresses are complete check module completion
                    else {
                    	moduleEOYComplete = true;
                    	for(EOY_Progress__c ep : currentOrgProgresses.Values()) {
                    		if(!ep.Is_Complete__c) {
                    			moduleEOYComplete = false;
                    			break;
                    		}
                    	}
                    	//final validation check everything:
                    	if(!moduleEOYComplete) {
                    		apexPages.addMessage(new apexPages.message(apexPages.Severity.WARNING, 'You have not completed the EOY Process for all installed modules.'));
                    	}
                    	else {
                    		try {
                    			orgWideProgress.Is_Complete__c = true;
                    			update orgWideProgress;
                    			apexPages.addMessage(new apexPages.message(apexPages.Severity.INFO, 'All school EOY Process is complete. Please activate the next year.'));
                    		}
                    		catch (DMLException d) {
                    			apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'DML update orgWidePRogress has failed: ' + d.getMessage()));
                    		}
                    	}
                    }
                    
                    return;
                }
            }
            //if it cannot verify the states, that means there are no Org level EOY Records to check against.  Create the main one first in the Catch
            catch(Exception e) {
                //query for EOY_Landing.page
                //been added for the spring 2014 release
                List<EOY_Progress__c> insertProgresses = new List<EOY_Progress__c>();
                
                //create the parent EOY_Progress for all child Modules
                for(ApexPage p : [SELECT ID, NamespacePrefix FROM ApexPage WHERE Name = 'EOYWiz_Landing' AND (NamespacePrefix = 'SchoolForce' OR NamespacePrefix = null)]) {
                	//base case: finds the main schoolforce landing page
                	EOY_Progress__c thisEOYProgress = new EOY_Progress__c(Year__c = activeYear.ID, RecordTypeID = EOYrecordType, Module_Name__c = 'SchoolForce');
                	try {
	                	if(orgWideProgress == null) {
	                		orgWideProgress = thisEOYProgress;
	                		insert thisEOYProgress;
	                	}
	                	else {
	                		apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'There are more than one Org Wide EOY Progress Record!  Please verify and correct the EOY_Progress__c record for this year.'));
	                	}
                	}
                	catch(DMLException d) {
                		apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'Org Wide EOY Progress Record failed to insert.'));
                	}
                }
                
				//throw the warning message!
            	apexPages.addMessage(new apexPages.message(apexPages.Severity.WARNING, 'The Org Wide Settings are not completed. Please complete the Org Wide Settings.'));
              	orgWideComplete = false;
                system.debug('*~*~* orgWideProgress: ' + orgWideProgress);  
            } 
        }
    }

    
    private void populateYearInformation() {
        List<Time_Element__c> activeYears = new List<Time_Element__c>();
        List<Time_Element__c> nextYears = new List<Time_Element__c>();
        
        ID rtID = core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Time');
        Picklist_Value__c yearPLV = [SELECT ID FROM Picklist_Value__c WHERE Type__c = 'Time' AND Name='Year' AND RecordTypeID =: rtID LIMIT 1];        
        system.debug('yearPLV: ' + yearPLV);
        
        //for(Time_Element__c year : [SELECT ID, Name__c, Date_Start_Date__c, End_Date__c, Current__c, New_School_Year__c FROM Time_Element__c WHERE ((Current__c = true AND New_School_Year__c = false) OR (New_School_Year__c = true AND Current__c = false)) ORDER BY Current__c DESC]) {
        for(Time_Element__c year : [SELECT ID, Name__c, Date_Start_Date__c, End_Date__c, Current__c, New_School_Year__c FROM Time_Element__c WHERE Picklist_Value__c =: yearPLV.ID ORDER BY Current__c DESC]) {
            if(year.Current__c) {
                activeYears.add(year);
                if(activeYears.size() > 1) {
                    Apexpages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are multiple years that are marked \'Current\'. Please verify the year time elements'));
                    initializationError = true;
                }
            }   
            
            if(year.New_School_Year__c) {
                nextYears.add(year);
                if(nextYears.size() > 1) {
                    Apexpages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are multiple years that are marked \'New School Year\'.  Please verify the year time elements.'));                  
                    initializationError = true;
                }
            }
        }
        
        if(activeYears.size() == 1) {
        	if(activeYears[0].Current__c && activeYears[0].New_School_Year__c) {
        		ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Found a year element that is marked \'Current\' and \'New School Year\'.  Please verify the year time elements.'));
        	}
        	else {
            	activeYear = activeYears[0];
        	}
        }
        else if(activeYears.size() == 0) {
            Apexpages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'There are no years that are marked \'Current\'. Please verify the current year.'));
            initializationError = true;
        }
        
        system.debug('nextYears.size(): ' + nextYears.size());
        if(nextYears.size() == 1) {
        	if(nextYears[0].Current__c && nextYears[0].New_School_Year__c) {
        		ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR, 'Found a year element that is marked \'New School Year\' and \'Current\'.  Please verify the year time elements.'));
        	}
        	else {
            	nextYear = nextYears[0];
        	}
        }
        else if(nextYears.size() == 0) {
            //should warn users to create a net next year! that is part of the process.
        }
    }
    
    //this is called before looking for EOY Org wide records
    
    public void getSchoolProgress() {
        system.debug('getSchoolProgress');
        Map<ID, EOY_Progress__c> updateSchoolProgress = new Map<ID, EOY_Progress__c>();
        //EOY Completion validation
        //true until proven guilty
        schoolEOYComplete = true;
        
        //US3521: modifying to schoolforce to accomdate summer school in EOY process: add to clause Parent = null
        for(Setup__c s : [SELECT ID, School__c, Year__c FROM Setup__c WHERE Active__c = true AND School__r.ParentID = null]) {
            schoolToCurrentActiveSetup.put(s.School__c, s); 
        }
        try {
            for(EOY_Progress__c eoy : [SELECT ID, School__c, School_Grade_Span_Completed__c, School_Student_Promotional_Completed__c, School_Next_Year_Students_Completed__c, School_Snapshots_Completed__c, School_Process_Data_Completed__c, School_Purge_EOY_Data_Completed__c, School_Purge_Historical_Data_Completed__c, Setup__c, Setup__r.Year__c, Year__c FROM EOY_Progress__c WHERE School__c IN: schoolToCurrentActiveSetup.KeySet() AND Year__c =: activeYear.ID AND recordTypeID =: EOYrecordType]){
                if(eoy.Setup__c == null) {
                	if(schoolToCurrentActiveSetup.containsKey(eoy.School__c)) {
                		if(schoolToCurrentActiveSetup.get(eoy.School__c).Year__c == activeYear.ID) {
                			eoy.Setup__c = schoolToCurrentActiveSetup.get(eoy.School__c).ID;
                			updateSchoolProgress.put(eoy.School__c, eoy);
                		}
                	}
                }
                else if(eoy.Setup__c != null) {
                	if(eoy.Setup__r.Year__c != activeYear.ID) {
	                	if(schoolToCurrentActiveSetup.containsKey(eoy.School__c)) {
	                		if(schoolToCurrentActiveSetup.get(eoy.School__c).Year__c == activeYear.ID) {
	                			eoy.Setup__c = schoolToCurrentActiveSetup.get(eoy.School__c).ID;
	                			updateSchoolProgress.put(eoy.School__c, eoy);
	                		}
	                	}
                	}
                }
                
                schoolToEOYProgress.put(eoy.School__c, eoy);
                
                
                //a little late to incorporate the eoy.Is_Complete__c if implemented,
                //then would need to run a script.
                if(!(eoy.School_Grade_Span_Completed__c &&
                    eoy.School_Student_Promotional_Completed__c &&
                    eoy.School_Next_Year_Students_Completed__c &&
                    eoy.School_Snapshots_Completed__c && 
                    eoy.School_Process_Data_Completed__c &&
                    eoy.School_Purge_EOY_Data_Completed__c && 
                    eoy.School_Purge_Historical_Data_Completed__c)){
                     	
					schoolEOYComplete = false;
                } else {
                    eoy.Is_Complete__c = true;
                }
            }
            update updateSchoolProgress.Values();
			
            system.debug('query for EOY Progress');
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'ERROR! Failed to find any EOY Progress for schools.'));
        }
        
        
        try {
            //The query result is probably empty, so create the necessary records for those schools and this year.
            List<EOY_Progress__c> newEOYProgress = new List<EOY_Progress__c>();
            
            for(ID school : schoolToCurrentActiveSetup.KeySet()) {
            	
          		if(!schoolToEOYProgress.containsKey(school)) {
                    EOY_Progress__c newEOY = new EOY_Progress__c( Year__c = activeYear.ID,
                                                                  School__c = school,
                                                                  RecordTypeID = EOYrecordType);
                    if(schoolToCurrentActiveSetup.containsKey(school)) {
                    	if(schoolToCurrentActiveSetup.get(school).Year__c == activeYear.ID) {
                    		newEOY.Setup__c = schoolToCurrentActiveSetup.get(school).ID;
                    	}
                    }
                    schoolToEOYProgress.put(school, newEOY);
                    newEOYProgress.add(newEOY);
          		}
            }
            
            if(newEOYProgress.size() > 0) {
            	upsert newEOYProgress;
            }
            system.debug('after insertion');
        }
        catch(Exception e) {
            apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'ERROR! Failed to insert new EOY Progress for active schools.'));
        }
        
		for(EOY_Progress__c eoy : [SELECT ID, School__c, School_Grade_Span_Completed__c, School_Student_Promotional_Completed__c, School_Next_Year_Students_Completed__c, School_Snapshots_Completed__c, School_Process_Data_Completed__c, School_Purge_EOY_Data_Completed__c, School_Purge_Historical_Data_Completed__c, Setup__c, Setup__r.Year__c, Year__c, Module_Name__c, Parent_Progress__c, Is_Complete__c FROM EOY_Progress__c WHERE School__c IN: schoolToCurrentActiveSetup.KeySet() AND Year__c =: activeYear.ID AND recordTypeID =: EOYrecordType]){
			schoolToEOYProgress.put(eoy.School__c, eoy);
		}
        
        dEOYProgress = schoolToEOYProgress.Values();
    }
    
    public void deactivateCurrentYear() {
        nextYear.New_School_Year__c = false;
        nextYear.Current__c = true;
        update nextYear;
        activeYear.New_School_Year__c = false;
        activeYear.Current__c = false;
        activeYear.Previous_Year__c = true;
        update activeYear;
        
        //call the cleanup batch process
        Batch_EOYDataCleanup cleanupBatch = new Batch_EOYDataCleanup(0);
        Database.executeBatch(cleanupBatch);
    }   
    
    public pageReference redirectToHome() {
        pageReference p = new pageReference('/apex/EOYWiz_Landing');     
        p.setRedirect(true);
        return p;    	
    }
    
}