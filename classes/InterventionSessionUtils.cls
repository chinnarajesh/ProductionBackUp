public without sharing class InterventionSessionUtils {
	public static Boolean isSkipValidtion = false;

	public static void validateCountISR(List<Intervention_Session__c> listIS, Map<Id, Intervention_Session__c> oldMap){
		for(Intervention_Session__c is: listIS){
			if(isSkipValidtion==false && is.ISR_Count__c==0 && oldMap.get(is.Id).ISR_Count__c!=0){
				is.addError(System.Label.Validation_Intervention_Session);
			}
		}
	}

	public static void runRemoveISs(List<Intervention_Session__c> listIS, Map<Id, Intervention_Session__c> oldMap){
		Set<Id> isIds = new Set<Id>();
		for(Intervention_Session__c is: listIS){
			if(isSkipValidtion==true && is.ISR_Count__c==0 && oldMap.get(is.Id).ISR_Count__c!=0){
				isIds.add(is.Id);
			}
		}

		if(!isIds.isEmpty()){
			removeISs(isIds);
		}
	}

	@future
	public static void removeISs(Set<Id> isIds){
		List<Intervention_Session__c> lstISs = new List<Intervention_Session__c>();
		for(Id idx: isIds){
			lstISs.add(new Intervention_Session__c(Id=idx));
		}

		delete lstISs;
	}

}