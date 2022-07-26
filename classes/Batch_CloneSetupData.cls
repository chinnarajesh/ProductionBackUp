global class Batch_CloneSetupData implements Database.Batchable<sObject>, Database.Stateful{
	
	private List<Setup__c> newSetups;
	private Map<ID, ID> newToOldSetupMap = new Map<ID, ID>();
	private String query;

	//Map key is setupID+PLV Name
	private Map<String,ID> assignmentTypeClones = new Map<String, ID>();
	
	global Batch_CloneSetupData(List<Setup__c> newSetups){
		this.newSetups = newSetups;
		Map<ID, Set<ID>> schoolToNewSetupMap = new Map<ID, Set<ID>>();
		for(Setup__c setup:newSetups){
			if(schoolToNewSetupMap.containsKey(setup.School__c)){
				schoolToNewSetupMap.get(setup.School__c).add(setup.ID);
			} else {
				schoolToNewSetupMap.put(setup.School__c, new Set<ID>{setup.ID});
			}
		}

		List<Setup__c> oldSetups = [select id, School__c from Setup__c where ID NOT IN: newSetups and School__c IN: schoolToNewSetupMap.keySet() and Published__c = true order by Year_End__c desc];

		for(Setup__c oldSetup:oldSetups){
			Set<ID> matchingNewSetupIDs = schoolToNewSetupMap.get(oldSetup.School__c);
			for(ID newSetupID: matchingNewSetupIDs){
				if(!newToOldSetupMap.containsKey(newSetupID)){
					newToOldSetupMap.put(newSetupID, oldSetup.ID);
				} else {
					break;
				}
			}
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC){
		Set<ID> setupIDs = newToOldSetupMap.keySet();
		query = 'select id, School__c from Setup__c where ID IN: setupIDs';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope){
		//Because of the volume of data this batch processes, it works best with batch size one. However it will support higher values.
		List<Setup__c> setups = (List<Setup__c>) scope;
		Map<ID, Set<ID>> oldToNewSetupMap = new Map<ID, Set<ID>>();
		for(Setup__c setup:setups){
			if(newToOldSetupMap.containsKey(setup.ID)){
				ID oldSetupID = newToOldSetupMap.get(setup.ID);
				if(oldToNewSetupMap.containsKey(oldSetupID)){
					oldToNewSetupMap.get(oldSetupID).add(setup.ID);
				} else {
					oldToNewSetupMap.put(oldSetupID, new Set<ID>{setup.ID});
				}
			}
		}
		cloneMealsSetups(oldToNewSetupMap);
		cloneValues(oldToNewSetupMap);
		clonePicklistValues(oldToNewSetupMap);
		cloneDefaultAssignmentWeightings(oldToNewSetupMap);
	}
	
	global void finish(Database.BatchableContext BC){
		
	}

	public String buildCloneFieldQueryString(String objectName){
		String properObjectName = (Schema.SObjectType.Setup__c.getName().replace('__c', '').contains('__')?'SchoolForce__':'')+objectName;
		Map<String, Schema.SObjectField> fMap = Schema.getGlobalDescribe().get(properObjectName.toLowerCase()).getDescribe().Fields.getMap();

		List<String> fields = new List<String>();
		if(fMap != null){
			for(Schema.SObjectField ft: fMap.values()) {
				Schema.DescribeFieldResult fd = ft.getDescribe();
				if(fd.isCreateable()) {
					fields.add(fd.getName());
				}
			}
		}
		return String.join(fields, ',');
	}

	public void cloneMealsSetups(Map<ID, Set<ID>> oldToNewSetupMap){
		List<Meals_Setup__c> toInsert = new List<Meals_Setup__c>();
		Set<ID> setupIds = oldToNewSetupMap.keySet();

		String query = 'select '+buildCloneFieldQueryString('Meals_Setup__c')+
			' from Meals_Setup__c'+
			' where Setup__c IN: setupIds'+
			' and Active__c = true';

		for(Meals_Setup__c ms:Database.query(query)){
			for(ID newSetupID: oldToNewSetupMap.get(ms.Setup__c)){
				Meals_Setup__c clonedSetup = ms.clone();
				clonedSetup.OwnerID = UserInfo.getUserId();
				clonedSetup.Setup__c = newSetupID;
				clonedSetup.Active__c = false; //this is done by the activate data part of setup
				toInsert.add(clonedSetup);
			}
		}

		insert toInsert;
	}

	public void cloneValues(Map<ID, Set<ID>> oldToNewSetupMap){
		List<Value__c> toInsert = new List<Value__c>();
		Set<ID> setupIds = oldToNewSetupMap.keySet();

		query = 'select '+buildCloneFieldQueryString('Value__c')+
			' from Value__c'+
			' where Setup__c IN: setupIds';

		for(Value__c value:Database.query(query)){
			for(ID newSetupID:oldToNewSetupMap.get(value.Setup__c)){
				Value__c clonedValue = value.clone();
				value.OwnerID = UserInfo.getUserId();
				clonedValue.Setup__c = newSetupID;
				toInsert.add(clonedValue);
			}
		}

		insert toInsert;
	}

	public void clonePicklistValues(Map<ID, Set<ID>> oldToNewSetupMap){
		List<Picklist_Value__c> toInsert = new List<Picklist_Value__c>();
		Set<ID> setupIds = oldToNewSetupMap.keySet();

		query = 'select '+buildCloneFieldQueryString('Picklist_Value__c')+',RecordType.Name'+
			' from Picklist_Value__c'+
			' where Setup__c IN: setupIDs';

		for(Picklist_Value__c plv:Database.query(query)){
			for(ID newSetupID:oldToNewSetupMap.get(plv.Setup__c)){
				Picklist_Value__c clonedPLV = plv.clone();
				clonedPLV.OwnerID = UserInfo.getUserId();
				clonedPLV.Setup__c = newSetupID;
				toInsert.add(clonedPLV);
			}
		}

		insert toInsert;

		for(Picklist_Value__c plv:toInsert){
			if(plv.RecordType.Name == 'Assignment Type'){
				assignmentTypeClones.put(plv.Setup__c+plv.Name, plv.ID);
			}
		}
	}

	public void cloneDefaultAssignmentWeightings(Map<ID, Set<ID>> oldToNewSetupMap){
		List<Default_Assignment_Weighting__c> toInsert = new List<Default_Assignment_Weighting__c>();
		Set<ID> setupIds = oldToNewSetupMap.keySet();
		String query = 
			'select '+buildCloneFieldQueryString('Default_Assignment_Weighting__c')+',Picklist_Value__r.Name, Picklist_Value__r.Setup__c'+
			' from Default_Assignment_Weighting__c'+
			' where Picklist_Value__r.Setup__c IN: setupIds';
		for(Default_Assignment_Weighting__c daw:Database.query(query)){
			for(ID newSetupID: oldToNewSetupMap.get(daw.Picklist_Value__r.Setup__c)){
				Default_Assignment_Weighting__c clonedDAW = daw.clone();
				ID newPLVID = assignmentTypeClones.get(newSetupID+clonedDAW.Picklist_Value__r.Name);
				if(newPLVID == null){
					continue;
				}
				clonedDAW.Picklist_Value__c = newPLVID;
				toInsert.add(clonedDAW);
			}
		}

		insert toInsert;
	}
}