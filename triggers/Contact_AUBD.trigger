trigger Contact_AUBD on Contact (after update, before delete) {
	if (!core_triggerUtils.bTriggersDisabled()){
		try{
		//If delete, remove students associated to those contacts.
			if(Trigger.isDelete){
				Set<Id> contactIDs = new Set<Id>();
				for(Contact c: Trigger.old){
					contactIDs.add(c.id);
				}
				List<Student__c> studentsToDel = [select id from Student__c where Individual__c IN :contactIDs];
				delete studentsToDel;
			}
			
			if(Trigger.isUpdate && Trigger.isAfter && core_triggerUtils.contactTrigger){
				List<Id> activationIDs = new List<Id>();
				List<Id> refUpdateIDs = new List<Id>();
				
				for(Contact c: Trigger.new){
					//If the contact is deactiveated add for student deactivation
					if(c.Active__c != Trigger.oldMap.get(c.Id).Active__c)
						activationIDs.add(c.id);
					
					if(c.Reference_Id__c != Trigger.oldMap.get(c.id).Reference_Id__c)
						refUpdateIDs.add(c.id);
				}
				
				List<Student__c> studentUpdateList = new List<Student__c>();
				if(!activationIDs.isEmpty()){
					List<Student__c> studentActivation = [select id, Individual__r.Id, Active__c from Student__c where Individual__c IN :activationIDs order by Individual__c];
					for(Student__c s: studentActivation){
						if(s.Id == Trigger.newMap.get(s.Individual__r.Id).Student__c){
							if(s.Active__c != Trigger.newMap.get(s.Individual__r.Id).Active__c){
								s.Active__c = Trigger.newMap.get(s.Individual__r.Id).Active__c;
								s.Exit_Date__c = Trigger.newMap.get(s.Individual__r.Id).Exit_Date__c;
								s.Entry_Date__c = Trigger.newMap.get(s.Individual__r.Id).Entry_Date__c;
								s.Student_Exit_Reason__c = CT_core_triggerUtils.SECTIONEXITREASONBYTRIGGER;
								studentUpdateList.add(s);
							}
						}
						else{
							if(s.Archived__c != Trigger.newMap.get(s.Individual__c).Active__c){
								s.Archived__c = Trigger.newMap.get(s.Individual__r.Id).Active__c;
								studentUpdateList.add(s);
							}
						}
					}
				}
				
				if(!refUpdateIDs.isEmpty()){
					List<Student__c> studentIDUpdate = [select id, Individual__r.Id, Reference_Id__c,Student_Id__c,School_Year__r.Name__c,School_Reference_Id__c,Setup_Year_Name__c,Setup_School_RT__c from Student__c where Individual__c IN :refUpdateIDs];
					for(Student__c s: studentIDUpdate){
						//If the id is already the same don't update (prevents trigger loop)
						if(s.Student_Id__c != Trigger.newMap.get(s.Individual__r.Id).Reference_Id__c){
							s.Student_Id__c = Trigger.newMap.get(s.Individual__r.Id).Reference_Id__c;
							s.Reference_Id__c = CT_Student_Utils.generateStudentReference(s);
							studentUpdateList.add(s);
						}
					}
				}
				
				//This prevents a problem with the student trigger trying to writeback to contacts used here.
				if(!studentUpdateList.isEmpty()){
					try{
						core_triggerUtils.studentTrigger = false;
						system.debug('~~~~~~studentUpdateList'+studentUpdateList);
						update studentUpdateList;
						core_triggerUtils.studentTrigger = true;
					}
					catch(Exception e){
						List<String> links = new List<String>();
						for(Student__c s: studentUpdateList){
							if(s.id != null){
								links.add(s.id + ',' + s.id);
							}
						}
						Global_Error__c ge = Error_Handling.handleError(String.join(links, ';'), 'Other', 'Contact update trigger DML failure', e);
						insert ge;
					}
				}
					
			}
		}
		catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('', 'Other', 'Contact update trigger non DML failure', e);
			insert ge;
		}
	}
}