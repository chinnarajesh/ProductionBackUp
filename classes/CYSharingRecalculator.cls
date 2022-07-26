global class CYSharingRecalculator{/* implements Database.Batchable<SObject> {
	global static boolean hasBeenScheduled = false;
	global String query = 'SELECT id, Profile.Name FROM User WHERE IsActive=true and Profile.UserType!= \'CSPLitePortal\'';
	global boolean useLog = false;
	
	global CYSharingRecalculator(){
		
	}
	
	global CYSharingRecalculator(boolean bUseLog){
		useLog = bUseLog;
	}
	
	global Iterable<sObject> start(Database.BatchableContext bc) {
		if(useLog){
			List<Data_Load_Log__c> logs = SharingUtils.getAllLogs('Pending');
			Set<String> userIDs = new Set<String>();
			if(logs != null && !logs.isEmpty()){
				for(Data_Load_Log__c dll: logs){
					if(!String.isBlank(dll.Messages__c)){
						userIDs.addAll(dll.Messages__c.split(','));
						dll.Status__c = 'Running';
						dll.Start_Time__c = System.now();
						dll.Start_Time_Text__c = System.now().format('MM/dd/yyyy hh:mm a');
						dll.Batch_ID__c=BC.getJobId();
						dll.Class_Name__c = 'CYSharingRecalculator';
					}
				}
			}

			if(logs == null || logs.isEmpty() || userIDs.isEmpty()){
				System.abortJob(BC.getJobId());
				if(logs == null && !Test.isRunningTest())
					SharingUtils.rescheduleBatch();
				return null;
			} else {
				query += updateQuery(' AND Id IN (',',','\'','\'', new List<String>(userIDs));
			}
			
			
			update logs;
		}

		Map<String,SharingControls__c> controls = SharingControls__c.getAll();
		if(controls.size()!=0){
			List<String> profiles = new List<String>();
			for(SharingControls__c sc: controls.values()) profiles.add(sc.Profile_Name__c);
			query += updateQuery(' AND (',' OR ','Profile.Name LIKE \'%','%\'',profiles);
		}

		if(Test.isRunningTest()){
			query += ' limit 1';
		}
		system.debug('query: ' +query);
		return Database.query(query);
	}
	
	global void execute(Database.BatchableContext bc, List<sObject> batch){
		List<User> users = (List<User>) batch;
		Set<ID> cmUsers = new Set<ID>();
		Set<ID> saUsers = new Set<ID>();
		Map<String,SharingControls__c> controls = SharingControls__c.getAll();
		Set<ID> userIDs = new Set<ID>();
		for(User u: users){
			userIDs.add(u.id);
			//I hate hardcoding but whatever
			if(controls.containsKey('CM')) if(u.Profile.Name.contains(controls.get('CM').Profile_Name__c)) cmUsers.add(u.id);
			if(controls.containsKey('SA')) if(u.Profile.Name.contains(controls.get('SA').Profile_Name__c)) saUsers.add(u.id);
		}
		List<Student__Share> newStudentShares = new List<Student__Share>();
		List<Section__Share> newSectionShares = new List<Section__Share>();
		Map<ID,Map<ID,ID>> existingSharingRules = SharingUtils.getExistingSharing(userIDs);
		calculateCMSharing(cmUsers, newStudentShares, newSectionShares, existingSharingRules);
		calculateSchoolAdminSharing(saUsers, newStudentShares, newSectionShares, existingSharingRules);
		insert newStudentShares;
		insert newSectionShares;
		SharingUtils.deleteRemainingRules(SharingUtils.getIDsToDelete(existingSharingRules));
	}
	
	global void finish(Database.BatchableContext bc){
		try {
			Data_Load_Log__c dll = [SELECT id FROM Data_Load_Log__c WHERE Batch_Id__c=:BC.getJobId() LIMIT 1 FOR UPDATE];
			dll.Status__c = 'Completed';
			dll.End_Time__c = System.now();
			dll.End_Time_Text__c = System.now().format('MM/dd/yyyy hh:mm a');
			update dll;
		} catch (Exception e){ }
	}
	
	global String updateQuery(String startString, String separator, String beginString, String endString, List<String> addStrings){
		
		String newQuery = startString;
		boolean init = true;
		for(String newString: addStrings){
			if(!init) newQuery += separator;
			newQuery += beginString;
			newQuery += newString;
			newQuery += endString;
			init = false;
		}
		newQuery += ')';
		return newQuery;
	}
	
	global void calculateCMSharing(Set<ID> userIDs, List<Student__Share> studentShares, List<Section__Share> sectionShares, Map<ID,Map<ID,ID>> existingSharingRules){
		Map<ID,Set<ID>> sectionToStaff = new Map<ID,Set<ID>>();
		for(Staff_Section__c ss: [SELECT id, Staff__r.Individual__r.User__r.Id, Section__c FROM Staff_Section__c WHERE Staff__r.Individual__r.User__r.Id IN :userIDs AND Is_Active__c=true]){
			ID user = ss.Staff__r.Individual__r.User__r.Id;
			if(!sectionToStaff.containsKey(ss.Section__c))
				sectionToStaff.put(ss.Section__c, new Set<ID>{user});
			else
				sectionToStaff.get(ss.Section__c).add(user);
			//create section shares
			ID share = getExistingShare(user, ss.Section__c, existingSharingRules);
			//if no share exists, create one
			if(share==null) sectionShares.add(SharingUtils.createSectionShare(user, ss.Section__c));
		}
		
		for(Student_Section__c ss: [SELECT id, Student__c, Section__c FROM Student_Section__c WHERE Section__c IN :sectionToStaff.keySet() AND Active__c=true]){
			for(ID user: sectionToStaff.get(ss.Section__c)){
				//create student share
				ID share = getExistingShare(user, ss.Student__c, existingSharingRules);
				//if no share exists, create one
				if(share==null) studentShares.add(SharingUtils.createStudentShare(user, ss.Student__c));
			}
		}
	}
	
	global void calculateSchoolAdminSharing(Set<ID> userIDs, List<Student__Share> studentShares, List<Section__Share> sectionShares, Map<ID,Map<ID,ID>> existingSharingRules){
		Map<ID,Set<ID>> schoolToUsers = new Map<ID,Set<ID>>();
		for(Staff__c staff: [SELECT id, Organization__c, Individual__r.User__r.Id FROM Staff__c WHERE Individual__r.User__r.Id IN :userIDs AND Active__c=true]){
			if(!schoolToUsers.containsKey(staff.Organization__c))
				schoolToUsers.put(staff.Organization__c, new Set<ID>{staff.Individual__r.User__r.Id});
			else
				schoolToUsers.get(staff.Organization__c).add(staff.Individual__r.User__r.Id);
		}

		//added territory share 15.06.2017
		Map<Id, Set<Id>> mapTerritory2School = new Map<Id, Set<Id>>();
		for(ObjectTerritory2Association ota: [SELECT Id, AssociationCause, IsDeleted, ObjectId, SobjectType, Territory2Id FROM ObjectTerritory2Association WHERE Object.Type = 'Account' AND ObjectId IN :schoolToUsers.keySet()]){
			System.debug('@@@ ota: '+ota);
			if(!mapTerritory2School.containsKey(ota.Territory2Id)){
				mapTerritory2School.put(ota.Territory2Id, new Set<Id>());
			}
			mapTerritory2School.get(ota.Territory2Id).add(ota.ObjectId);
		}

		for(UserTerritory2Association uta: [SELECT IsActive, RoleInTerritory2, Territory2Id, UserId FROM UserTerritory2Association WHERE Territory2Id IN :mapTerritory2School.keySet()]){
			System.debug('@@@ uta: '+uta);
			for(Id schoolId: mapTerritory2School.get(uta.Territory2Id)){
				if(!schoolToUsers.containsKey(schoolId)){
					schoolToUsers.put(schoolId, new Set<Id>());
				}
				schoolToUsers.get(schoolId).add(uta.UserId);
			}
		}
		//end territory
		
		for(Student__c student: [SELECT id, School__c FROM Student__c WHERE School__c IN :schoolToUsers.keySet()]){
			for(ID user: schoolToUsers.get(student.School__c)){
				ID share = getExistingShare(user, student.id, existingSharingRules);
				//if no share exists, create one
				if(share==null) studentShares.add(SharingUtils.createStudentShare(user, student.id));
			}
		}
		
		for(Section__c section: [SELECT id, School__c FROM Section__c WHERE School__c IN :schoolToUsers.keySet()]){
			for(ID user: schoolToUsers.get(section.School__c)){
				ID share = getExistingShare(user, section.id, existingSharingRules);
				//if no share exists, create one
				if(share==null) sectionShares.add(SharingUtils.createSectionShare(user, section.id));
			}
		}
	}
	
	global ID getExistingShare(ID user, ID shareRecord, Map<ID,Map<ID,ID>> existingSharingRules){
		Map<ID,ID> temp = existingSharingRules.get(user);
		ID share;
		//remove share if it's valid
		//all invalid sharing rules will remain and be deleted at the end of the batch
		if(temp!=null) share = temp.remove(shareRecord);
		existingSharingRules.put(user,temp);
		return share;
	}
	*/
}