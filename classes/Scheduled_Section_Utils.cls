public with sharing class Scheduled_Section_Utils {



	public static void processBeforeInsert(List <Scheduled_Section__c> newList){
		updSsFieldsForGroupAgenda(newList);
		updSsFieldsfromSrp(newList, null, null);
		validateGroupAgendaView(newList);
	}
	public static void processAfterInsert(Map <Id, Scheduled_Section__c> newMap){
	
	}
	public static void processBeforeUpdate(Map <Id, Scheduled_Section__c> newMap, Map<Id, Scheduled_Section__c> oldMap){
		updSsFieldsfromSrp(null, newMap, oldMap);
		validateGroupAgendaView(newMap.values());
		updateNeedsPublishFlag(newMap, oldMap);
	}
	public static void processAfterUpdate(Map <Id, Scheduled_Section__c> newMap, Map<Id, Scheduled_Section__c> oldMap){
	
	}
	public static void processBeforeDelete(Map <Id, Scheduled_Section__c> oldMap){
	
	}
	
	public static void updateNeedsPublishFlag (Map <Id, Scheduled_Section__c> newMap, Map<Id, Scheduled_Section__c> oldMap){
		for (Scheduled_Section__c ss: newMap.values()){
			Scheduled_Section__c oldSs = oldMap.get(ss.id);
			if (ss.Staff__c!=oldSs.Staff__c) ss.needs_publish__c = true;
			else if (ss.Room__c!=oldSs.Room__c) ss.needs_publish__c = true;
			else if (ss.Period_Key__c!=oldSs.Period_Key__c) ss.needs_publish__c = true;
		}
	}
	
		public static void updSsFieldsForGroupAgenda(List <Scheduled_Section__c> ssList){
	 		if (core_TriggerUtils.bGroupAgenda){
				for (Scheduled_Section__c ss: ssList){
					ss.Reference_Id__c = ImportUtils.createScheduledSectionKey(ss.Account__c,ss.Schedule_Group_Section__c,ss.Course__c,ss.Reporting_Period__c,ss.Schedule_Template__c);
					ss.Section_Reference_Id__c = ImportUtils.createSectionReferenceKey(ss.Account__c,ss.Schedule_Group_Section__c,ss.course__c,ss.Reporting_Period__c);
				}
			}
	}
	
	public static String generateScheduledSectionReference(Scheduled_Section__c ss){
        return ss.Section_ReportingPeriod__c+'-'+ss.Period_key__c+ss.Staff__c;
    }

	public static void updSsFieldsfromSrp (List <Scheduled_Section__c> ssList, Map <Id, Scheduled_Section__c> newMap, Map<Id, Scheduled_Section__c> oldMap){
		if (!core_TriggerUtils.bGroupAgenda){
			Set <Id> sectionRpIdSet = new Set <Id>();
			if (ssList!=null){
				for (Scheduled_Section__c ss: ssList){
					if (ss.section_reportingPeriod__c!=null){
						sectionRpIdSet.add(ss.section_reportingPeriod__c);
					}
				}
			} 
			else {
				for (Scheduled_Section__c ss: newMap.values()){
					if (ss.Section_ReportingPeriod__c!=null&& ss.Section_ReportingPeriod__c!=oldMap.get(ss.id).Section_ReportingPeriod__c)
						sectionRpIdSet.add(ss.Section_ReportingPeriod__c);
					//EE 8/30 if period changes, update SRP
					if(ss.Period_Key__c!=oldMap.get(ss.id).Period_Key__c){
						sectionRpIdSet.add(ss.Section_ReportingPeriod__c);
					}
				}
				ssList = newMap.values();
			} 
			
			if (!sectionRpIdSet.isEmpty()){
				Map <Id, Section_ReportingPeriod__c> sectionRpMap = new Map<Id, Section_ReportingPeriod__c>([select id, period__c, time__c, section__r.school__c, section__c, section__r.course__c from Section_ReportingPeriod__c where id in:sectionRpIdSet]);
				
				for (Scheduled_Section__c ss: ssList){
					if (sectionRpMap.keySet().contains(ss.Section_ReportingPeriod__c)){
						Section_ReportingPeriod__c srp = sectionRpMap.get(ss.section_reportingPeriod__c);
						ss.Account__c=srp.section__r.school__c;
						ss.Course__c=srp.section__r.course__c;
						ss.Reporting_Period__c= srp.time__c;
						ss.Section__c = srp.section__c;
						ss.reference_id__c = generateScheduledSectionReference(ss);
						if (srp.period__c!=null){
							if (srp.period__c.contains(',')){
								string [] periodArray = srp.period__c.split(',');
								Set <String> periodSet = new Set <String>();
								for (String s: periodArray)	periodSet.add(s);
								if (!periodSet.contains(ss.period_key__c)){
									srp.period__c+=','+ss.period_key__c; //handles multiple periods appropriately DE2482
								}
							}
							else {
								if (!srp.period__c.contains(ss.period_key__c)){
									srp.period__c+=','+ss.period_key__c;
								}
							}
							//EE 8/30 if period changes, remove old period from srp.Period__c DE3571
							if(oldMap!=null && oldMap.get(ss.id).Period_Key__c!=ss.Period_Key__c){
								String[] periods = srp.Period__c.split(',');
								srp.Period__c='';
								for(integer i=0; i<periods.size(); i++){
									if(periods[i]!=oldMap.get(ss.id).Period_Key__c){
										if(srp.Period__c!='') srp.Period__c += ',';
										srp.Period__c+=periods[i]; 
									}
								}
							}
						}
						else srp.period__c=ss.period_key__c;
					}
				}
				if (!sectionRpMap.keySet().isEmpty()){
					update sectionRpMap.values();
				}
			}
			updateKeys(ssList);
		}
	}
	
	public static void updateKeys(List<Scheduled_Section__c> ssList){
		for(Scheduled_Section__c ss: ssList){
			if (ss.Room__c!=null)  ss.room_key__c = ss.reporting_period__c+'-'+ss.Period_Key__c+'-'+ss.Room__c;
			ss.staff_key__c=ss.Reporting_Period__c+'-'+ss.Period_Key__c+'-'+ss.Staff__c;
		}
	}
	
	public static void validateGroupAgendaView ( List <Scheduled_Section__c> ssList){
		if (core_TriggerUtils.bGroupAgenda){
			Scheduled_Section__c enteredSs;
			for (Scheduled_Section__c ss: ssList){
					enteredSs = ss;
					if (enteredSS.start_time_text__c==null ||enteredSs.start_time_text__c==''){
						enteredSS.No_Meeting__c=true;
					}
					break;
			}
			boolean bError = false;
			boolean bTemplateError = false;
			for (Scheduled_Section__c ss: scheduler_SoqlUtils.getScheduledSectionsByTempId(enteredSS.schedule_template__c)){
					if (!enteredSS.No_Meeting__c){
					DateTime templateStartTime = core_TimeUtils.processTimeText(ss.schedule_template__r.start_time_text__c);
					DateTime templateEndTime = core_TimeUtils.processTimeText(ss.schedule_template__r.end_time_text__c);
					DateTime enteredStartTime = core_TimeUtils.processTimeText(enteredSS.start_time_text__c);
					DateTime enteredEndTime = core_TimeUtils.processTimeText(enteredSS.end_time_text__c);
					if (templateStartTime > enteredStartTime){
						bTemplateError = true;
						break;
					}	
					if (templateEndTime < enteredEndTime){ 
						bTemplateError = true;
						break; 
					}
					if (ss.Schedule_Group_Section__c==enteredSs.Schedule_Group_Section__c){
						if (enteredSS.id !=ss.id){
							if (!enteredSS.Daily_Attendance__c&&!ss.Daily_Attendance__c){
								if (enteredSS.end_time_text__c!=null&&enteredSS.end_time_text__c!=null&& ss.start_time_text__c!=null&&ss.end_time_text__c!=null){
									DateTime thisStartTime = core_TimeUtils.processTimeText(ss.start_time_text__c);
									DateTime thisEndTime = core_TimeUtils.processTimeText(ss.end_time_text__c);
								
									if (enteredStartTime< thisStartTime && enteredEndTime>thisStartTime){
										bError = true;
										break; 
									}
									else if (enteredEndTime> thisEndTime&& enteredStartTime < thisEndTime){
										bError = true;
										break;
									}
								}
							}
						}
					}
				}
			}
			if (bError) enteredSs.addError('Section cannot have overlapping times with other sections in the same template & group');
			if (bTemplateError) enteredSs.addError('Section cannot start or end outside of the associated Schedule Template start and end times');
		}
	}
	
}