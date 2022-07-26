global class Batch_StandardGradeRecalc implements Database.batchable<sObject>, Database.Stateful {
		
		global String query {get; set;}
		global Set<ID> setups = new Set<ID>();
				
		public Batch_StandardGradeRecalc(Set<ID> s) {
			setups = s;
			query = 'SELECT ID, Student__r.Setup__c, Student__c, Standard__c, Reporting_Period__c FROM Standard_Grade__c WHERE Student__r.Setup__c =: setups AND Student__c != null AND Standard__c != null ORDER BY Student__c, Standard__c, Reporting_Period__c';
		}
		
		global Database.QueryLocator start(Database.BatchableContext BC) {
			return Database.getQueryLocator(query);
		}
		
		global void execute(Database.BatchableContext BC, List<sObject> scope) {
			
			Map<Id, Set<Id>> setupStudentMap = new Map<Id, Set<Id>>();
			Map<ID, Set<ID>> setupStandardMap = new Map<ID, Set<ID>>();
			Map<ID, Set<ID>> setupRPMap = new Map<ID, Set<ID>>();			
			
			for(Standard_Grade__c sg : (List<Standard_Grade__c>)scope) {
				if(sg.Student__r.Setup__c != null) {	
					if(!setupStudentMap.containsKey(sg.Student__r.Setup__c)) {
						setupStudentMap.put(sg.Student__r.Setup__c, new Set<ID>{sg.Student__c});
					}
					else {
						setupStudentMap.get(sg.Student__r.Setup__c).add(sg.Student__c);
					}
					
					if(sg.Standard__c != null) {
						if(!setupStandardMap.containsKey(sg.Student__r.Setup__c)) {
							setupStandardMap.put(sg.Student__r.Setup__c, new Set<ID>{sg.Standard__c});
						}
						else {
							setupStandardMap.get(sg.Student__r.Setup__c).add(sg.Standard__c);
						}
					}
					
					if(sg.Reporting_Period__c != null) {
						if(!setupRPMap.containsKey(sg.Student__r.Setup__c)) {
							setupRPMap.put(sg.Student__r.Setup__c, new Set<ID>{sg.Reporting_Period__c});
						}
						else {
							setupRPMap.get(sg.Student__r.Setup__c).add(sg.Reporting_Period__c);
						}
					}
				}
			}
			
			for (ID current: setupStudentMap.KeySet()){
				if (setupStudentMap.get(current) != null){
					if (!setupStudentMap.get(current).isEmpty()){
						//this needs to be a batch just in case the number of records is too great to update.
						Gradebook_CalculationTypes.calculateLater(setupStudentMap.get(current), setupStandardMap.get(current), setupRPMap.get(current), true);	
					}
				}
			}			
		}
		
		global void finish(Database.BatchableContext BC) {
			
		}
}