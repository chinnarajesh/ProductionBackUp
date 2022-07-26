public with sharing class Scheduler_TriggerUtils {
	public static Map <String, Id> srpRecordTypeMap;
    
	public static void createSectionRPs(List<Section__c> sectionsList){
		Set<Id> courseIds = new Set<Id>();
		Set<Id> sectionIds = new Set<Id>();
		Map<Id,Id> sectionIdToGroupId = new Map<Id,Id>();
		srpRecordTypeMap = core_SoqlUtils.getRecordTypesBySobject('Section_ReportingPeriod__c');
		Map <Id, Map <Id, Section_ReportingPeriod__c>> sectionToSectionRpMap= new Map <Id, Map <Id, Section_ReportingPeriod__c>> ();

		
		List <Section_ReportingPeriod__c> upsertSrpList = new List <Section_ReportingPeriod__c>();
		List <Section_ReportingPeriod__c> deleteSrpList = new List <Section_ReportingPeriod__c>();
		Map <String,Map<String, Course_Weightings__c>> courseWeightingsByCourseConfig = new Map <String, Map<String, Course_Weightings__c>>(); //New for US1250

		
		for(Section__c s : sectionsList){
			sectionIds.add(s.Id);
			sectionToSectionRpMap.put(s.id, new Map <Id, Section_ReportingPeriod__c>{});
			courseIds.add(s.course__c);
		}
		sectionIdToGroupId = scheduler_SoqlUtils.getGroupsBySections(sectionIds);
		
		for(Course_Weightings__c cw:[select Id, Name,Time__c, Key__c, Weighting__c, Course__c , Reporting_Period_Type__r.corresponding_Value__c
	        	                                 from Course_Weightings__c 
	        	                                 where Course__c in :courseIds
	        	                                 order by Key__c]) {
	    	     String cwConfigKey = cw.course__c+'-'+cw.Reporting_Period_Type__r.corresponding_Value__c;
	    	     if (courseWeightingsByCourseConfig.get(cwConfigKey)==null){
	    	     	courseWeightingsByCourseConfig.put(cwConfigKey, new Map <String, Course_Weightings__c>{cw.key__c=>cw});
	    	     }
	    	     else {
	    	     	courseWeightingsByCourseConfig.get(cwConfigKey).put(cw.key__c, cw);     
	    	     }                       	
	    }
		
		for (Section_ReportingPeriod__c srp : [select id, time__c, period__c, section__c, course_weighting__c from Section_ReportingPeriod__c where section__c in:sectionIds]){
			sectionToSectionRpMap.get(srp.section__c).put(srp.time__c, srp);
		}
		
            for(Section__c sec : sectionsList){
                integer i=0; 
                String lastPeriod;              
                Id termId = Section_Utils.parentTeMap.get(sec.reporting_period__c);
                List <Time_Element__c> teList = Section_Utils.termRpMap.get(termId);
                for (Time_Element__c te: teList){
                    if (te.id == sec.Reporting_Period__c|| i!=0 && i<Integer.valueOf(sec.number_of_reporting_periods__c)){
              			 if (sectionToSectionRpMap.get(sec.id).get(te.id)!=null){
                			lastPeriod = sectionToSectionRpMap.get(sec.id).get(te.id).period__c;
                		}
                        i++;
                        String cwConfigKey = sec.course__c+'-'+sec.number_of_reporting_periods__c;
	                        if (courseWeightingsByCourseConfig.get(cwConfigKey)!=null){
	                        Course_Weightings__c cw = courseWeightingsByCourseConfig.get(cwConfigKey).get(string.valueOf(i));
	                        Section_ReportingPeriod__c sectionRp = createSectionRp(sec, te.id, cw);
	                        sectionRp.period__c = lastPeriod;
	                        if(sectionIdToGroupId != null){
		                        if(sectionIdToGroupId.containskey(sec.Id))
		                        sectionRp.Scheduler_ReferenceId__c = sec.School__c+'-'+sectionIdToGroupId.get(sec.Id)+'-'+sec.Course__c+'-'+te.Id;
	                        }
	                        upsertSrpList.add(sectionRp);
	                        //Check for finals
	                        //Add for Finals
	                        if (courseWeightingsByCourseConfig.get(cwConfigKey).get(string.valueOf(i+'-Final'))!=null){//First check if weightings actually have a final
	                        	Course_Weightings__c finalCw = courseWeightingsByCourseConfig.get(cwConfigKey).get(string.valueOf(i+'-Final'));
	                        	Section_ReportingPeriod__c finalsectionRp = createSectionRp(sec, Section_Utils.finalRpMap.get(te.id), finalCw);
	                        	upsertSrpList.add(finalsectionRp);
	                        }
	                        else {//If not & sectionrp has one delete it
	                        	if (sectionToSectionRpMap.get(sec.id).get(Section_Utils.finalRpMap.get(te.id))!=null){ //Do current section reporting periods have a final thats no longer valid?
	                        		deleteSrpList.add(sectionToSectionRpMap.get(sec.id).get(Section_Utils.finalRpMap.get(te.id)));  //Then add it to the list to delete
	                        	}
	                        }
	                    }
                    }
                    else {
                    	//check for existing ones that are no longer valid and puge them
                    	if (sectionToSectionRpMap.get(sec.id).get(te.id)!=null){
                    		deleteSrpList.add(sectionToSectionRpMap.get(sec.id).get(te.id));
                    		if (sectionToSectionRpMap.get(sec.id).get(Section_Utils.finalRpMap.get(te.id))!=null){ //Does bad section reporting periods have a final thats no longer valid?
                        		deleteSrpList.add(sectionToSectionRpMap.get(sec.id).get(Section_Utils.finalRpMap.get(te.id)));  //Then add it to the list to delete
                        	}
                    	}
                    }
                }
            }
                if(upsertSrpList.size() > 0){
                    try{
                        upsert upsertSrpList ReferenceId__c;
                            
                        //Summer 2014: need to verify this
                        //Gradebook_ManageGradebook.createSectionGradesForStudents(upsertSrpList);
                    }catch(Exception ex){
                        System.debug('Upsert failed'+ex.getmessage());
                    }       
                }
                if(deleteSrpList.size() > 0){
                    Set <Id> failedSectionRdIds = new Set <Id>();
                    Set <Id> failedSectionIds = new Set <Id>();
                    List<Database.deleteResult> dResults =Database.delete(deleteSrpList,false);
                    core_triggerUtils.b = true;
                    for(Database.DeleteResult d: dResults){
                        if (!d.isSuccess()){
                            failedSectionIds.add(d.getId());
                        }
                    }
                    core_triggerUtils.b = false;
                    for (Section_ReportingPeriod__c srp: deleteSrpList){
                        if(failedSectionIds.contains(srp.id)){
                            failedSectionIds.add(srp.section__c);
                        }
                    }
                    for (Section__c sect: sectionsList){
                        if(failedSectionIds.contains(sect.id)){
                            sect.addError('Not Allowed');
                        }
                    }
                    system.debug('----------deleteSrpList--------------'+deleteSrpList);
                }
                 
     			if (!upsertSrpList.isEmpty()){
     				//Summer 2014: need to verify this
     				Gradebook_ManageGradebook.createSectionGradesForStudents(upsertSrpList);
     			}
    } 
    
    public static Section_ReportingPeriod__c createSectionRp(Section__c sec, Id teId, Course_Weightings__c cw){
    	Section_ReportingPeriod__c sectionRp = new Section_ReportingPeriod__c();
        if(sec.Number_of_Periods__c != null)  sectionRp.Number_of_Periods__c= sec.Number_of_Periods__c;
        sectionRp.Section__c = sec.Id;
        sectionRp.Time__c = teId;     
        sectionRp.RecordTypeId = srpRecordTypeMap.get('UnPublished');
        sectionRp.ReferenceId__c = sec.Id+'-'+teId;
        sectionRp.Course_Weighting__c = cw.id;
        return sectionRp;
    }
    
    public static void processAfterInsert(Map<Id,Section_ReportingPeriod__c> newSectionRPMap){
    	Scheduler_TriggerUtils.updateSectionPeriod(newSectionRPMap,null);
    }
    
     public static void processAfterUpdate(Map<Id,Section_ReportingPeriod__c> newSectionRPMap, Map<Id,Section_ReportingPeriod__c> oldSectionRPMap){
    	Scheduler_TriggerUtils.updateSectionPeriod(newSectionRPMap,oldSectionRPMap);
    }
    
    public static void updateSectionPeriod(Map<Id,Section_ReportingPeriod__c> newSectionRPMap, Map<Id,Section_ReportingPeriod__c> oldSectionRPMap){
    	Map<Id, Section__c> sectionMap = new Map<Id, Section__c>();
    	for(Section_ReportingPeriod__c srp: [SELECT Period__c, Time__c,Section__r.Period__c,Section__r.Reporting_Period__c
    										 FROM Section_ReportingPeriod__c WHERE Id in: newSectionRPMap.keyset() AND Period__c <> null]){
    		if((oldSectionRPMap == null) || (oldSectionRPMap!=null && oldSectionRPMap.get(srp.Id).Period__c != newSectionRPMap.get(srp.Id).Period__c)	){							 	
	    		if(srp.Time__c == srp.Section__r.Reporting_Period__c && srp.Period__c != '' && srp.Period__c != null){
	    			srp.Section__r.Period__c = srp.Period__c;
	    			sectionMap.put(srp.Section__c,srp.Section__r);
	    		}									 	
    		}
    	}
		if(sectionMap.values().size() > 0){
			update sectionMap.values();
		}
    } 
}