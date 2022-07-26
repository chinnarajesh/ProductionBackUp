public with sharing class Scheduler_UpsertHolding {
	public core_SetupWrapper				cSetup					{get;set;}
	public Scheduler_UpsertHolding(core_SetupWrapper inputSetup){
    	
	    if (inputSetup != null){
			cSetup=inputSetup;
	    
	    }
    }
    
     public void upsertHoldingRecordsForScheduledSec(List<Scheduled_Section__c> scheduledSections){
    	Map <String, Scheduled_Section__c> ssMap 	= new Map <String, Scheduled_Section__c>();
    	Set <Id>	 scheduleGroupIds					= new Set <Id>();
    	Map <Id, List <Student_Section__c>> 		    scheduleGroupMap = new Map <Id, List <Student_Section__c>>();//updated for Chicago
    	Map <String, List <String>>	ssPeriodMap	= new Map <String, List <String>>(); //Used if Section is across multiple periods to keep track of which periods it should get
    	List <HoldingObj__c> holdingObjectList 		= new List <HoldingObj__c>();
    	Set <Id> studIds 											= new Set <Id>();
    	Set <Id> studentSectionIds 							= new Set <Id>();
    	Map <Id, Student__c> studentMap				= new Map <Id, Student__c>();

	
		 //Logic specific for group based setup/publish; schedule group section for Chicago
 			for (Scheduled_Section__c ss:  scheduledSections){
 				string scheduleKey = cSetup.school.id+'-'+ss.Reporting_Period__c+'-'+ss.Schedule_Group_Section__c+'-'+ss.Course__c;  
 				ssMap.put(scheduleKey, ss);
 				System.debug('-------ssMap------------'+ssMap);
 				scheduleGroupIds.add(ss.Schedule_Group_Section__c);
 				scheduleGroupMap.put(ss.Schedule_Group_Section__c, new List <Student_Section__c>());
 				system.debug('~~~~~ schedule group section: '+ss.Schedule_Group_Section__c);
 				system.debug('~~~~~ scheduleGroupMap '+scheduleGroupMap);
 			}
 			
			for (Scheduled_Section__c ss: ssMap.values()){
				HoldingObj__c  ho = ImportMappers.createSectionMapper().generate(ss, cSetup.setup.group_based__c); //Create the holding object record for Sections
				holdingObjectList.add(ho ); //Add Holding object section to List
				System.debug('-------ho------------'+ho);
			}

			system.debug('~~~~~ scheduleGroupMap.keySet() '+scheduleGroupMap.keySet());
			system.debug('~~~~~ with active field '+[select  id, section__c, student__c from Student_Section__c where Section__c in:scheduleGroupMap.keySet() AND Active__c=true]);
			system.debug('~~~~~ with record type '+[select  id, section__c, student__c from Student_Section__c where Section__c in:scheduleGroupMap.keySet() AND Section__r.RecordType.DeveloperName = 'Schedule_Group']);
			for (Student_Section__c ss: [select  id, section__c, student__c from Student_Section__c where Section__c in:scheduleGroupMap.keySet() AND Active__c=true and Section__r.RecordType.DeveloperName = 'Schedule_Group']){
				studIds.add(ss.student__c);
				scheduleGroupMap.get(ss.section__c).add(ss);
			}
			
			for (Student__c stu : [select id, Entry_Date__c,Student_Id__c, Disability_Flag__c, Date_of_Birth__c, Ell__c, Student_First_Name__c, Student_Last_Name__c, Ethnicity__c, Lep_Flag__c, Gender__c, Reference_Id__c, Grade__c, Address__c, City__c, State__c, Zip_Code__c, Mobile_Phone__c 
												FROM Student__c
												where Id in: studIds]){
				studentMap.put(stu.id, stu);											
			}
					
			for (Scheduled_Section__c ss: ssMap.values()){
				for (Student_Section__c groupStud: scheduleGroupMap.get(ss.schedule_group_section__c)){
					Student__c stud = studentMap.get(groupStud.student__c);
					system.debug('stud~~~~~'+stud);
					HoldingObj__c  ho = ImportMappers.createStudentSchoolGradeMapper().generate(stud, ss); //Create the holding object record for Sections
					holdingObjectList.add(ho);
				}
			}
			

			if (!holdingObjectList.isEmpty()){

				try {
					upsert holdingObjectList  Reference_Id__c;	
					for(Scheduled_Section__c ss: scheduledSections) ss.Needs_Publish__c = false;
					update scheduledSections;
				//	cSetup.setup.Published__c = true; DE 1202
				//	update cSetup.setup;
					}
				catch (exception e){
					 Global_Error__c ge = Error_Handling.handleError('Scheduler_UpsertHoldingObject', 'Scheduler', 'Upserting to Holding Object for: '+cSetup.setup.Id, e);
					insert ge;
				}
			}
	
	    }
    
    public void upsertHoldingRecordsForPeriods(List<Scheduled_Section__c> scheduledSections){
    	Map <String, Scheduled_Section__c> 		ssMap 					= 	new Map <String, Scheduled_Section__c>();
	    Set <Id>	 							scheduleGroupIds		= 	new Set <Id>();
	    Map <Id, List <Student__c>> 		    scheduleGroupMap 		= 	new Map <Id, List <Student__c>>();
	  //PU   Map <String, List <String>>				ssPeriodMap				= 	new Map <String, List <String>>(); //Used if Section is across multiple periods to keep track of which periods it should get
	    List <HoldingObj__c> 					holdingObjectList 		= 	new List <HoldingObj__c>();
	    	
	    	for (Scheduled_Section__c ss:  scheduledSections){
				string scheduleKey = cSetup.school.id+'-'+ss.Reporting_Period__c+'-'+ss.Section__r.Reference_Id__c+'-'+ss.Course__c+'-'+ss.Staff__c;  //School - Reporting Period - Schedule Group - Course -Staff (US592) Need to add logic for if course spans multiple reporting periods and how we will 'keep' the same section
					System.debug('LE map key: '+scheduleKey+ ' exists in map? '+ssMap.containsKey(scheduleKey));
					ssMap.put(scheduleKey, ss);
 			}
		
	
/* Update the list that is looped over here for proper multiple teacher sections*/ 
    	for (Scheduled_Section__c ss: ssMap.values()){
    		string scheduleKey = cSetup.school.id+'-'+ss.Reporting_Period__c+'-'+ss.Section__r.Reference_Id__c+'-'+ss.Course__c+'-'+ss.Staff__c;
    		HoldingObj__c  ho = ImportMappers.createSectionMapper().generate(ss, cSetup.setup.group_based__c); //Create the holding object record for Sections
    					   ho.Reference_Id__c = scheduleKey;
    		holdingObjectList.add(ho ); //Add Holding object section to List

    	}
	
    	if (!holdingObjectList.isEmpty()){

    		try {
    			upsert holdingObjectList  Reference_Id__c;
    			for(Scheduled_Section__c ss: scheduledSections) ss.Needs_Publish__c = false;
				update scheduledSections;	
    			cSetup.setup.Published__c = true;
    			update cSetup.setup;
    		 	}
    		catch (exception e){
    			  System.debug('Publish failed'+e.getMessage());
    		}
    	}
	
	    }
}