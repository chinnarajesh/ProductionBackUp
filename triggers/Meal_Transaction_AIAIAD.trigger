trigger Meal_Transaction_AIAIAD on Meal_Transaction__c (after delete, after insert, after update, before insert) {
	if (!core_triggerUtils.bTriggersDisabled()){  
		if(!core_triggerUtils.b){        // should the recordset be processed?
	    
			Set<ID> studentIDSet = new Set<ID>();
			Set<ID> schoolIDSet = new Set<ID>();
			List<ID>schoolList = new List<ID>();
			List<Meal_Transaction__c> mealList = new List<Meal_Transaction__c>();
			if(trigger.isdelete){
				mealList=trigger.old;      // mealList should equal the current records
			}
			else{
				mealList=trigger.new;      // mealList should equal the future records
			}
			Map<ID,Setup__c> setupMap = new Map<ID,Setup__c>();
			for(Meal_Transaction__c mt:mealList){
				studentIDSet.add(mt.Student__c);
			}
			for(Student__c s:[select ID, School__c from Student__c where ID IN :studentIDSet]){
				schoolIDSet.add(s.School__c);
				schoolList.add(s.School__c);
			}
			setupMap = core_SoqlUtils.getActiveSetups(schoolIDSet);
			Id setupID = setupMap.values()[0].Id;
			
			Meals_Setup__c mealSetup = [Select m.Schoolwide_Free_Breakfast__c, 
	                       m.State_Reduced_Lunch_Reimbursement__c, 
	                       m.State_Full_Price_Lunch_Reimbursement__c, 
	                       m.State_Free_Lunch_Reimbursement__c, 
	                       m.Setup__c, 
	                       m.Fed_Reduced_Lunch_Reimbursement__c, 
	                       m.Fed_Full_Price_Lunch_Reimbursement__c, 
	                       m.Fed_Free_Lunch_Reimbursement__c, 
	                       m.Additional_Reimbursement_3_Amount__c, 
	                       m.Additional_Reimbursement_2_Amount__c, 
	                       m.Additional_Reimbursement_1_Amount__c,
	                       m.State_Reduced_Breakfast_Reimbursement__c, 
	                       m.State_Full_Price_Breakfast_Reimbursement__c, 
	                       m.State_Free_Breakfast_Reimbursement__c, 
	                       m.Fed_Reduced_Breakfast_Reimbursement__c, 
	                       m.Fed_Full_Price_Breakfast_Reimbursement__c, 
	                       m.Fed_Free_Breakfast_Reimbursement__c,
	                       m.Additional_Reimbursement_3_Applies_To__c, 
	                       m.Additional_Reimbursement_2_Applies_To__c, 
	                       m.Additional_Reimbursement_1_Applies_To__c  
	                       From Meals_Setup__c m 
	                       where Setup__c = :setupID 
	                       AND Active__c = true Limit 1];
	                       
			if(trigger.isBefore){          // trigger is executing prior to insertion of record
				Map<ID,String> codeMap = new Map<Id,String>();
				for(Meal_Transaction__c mt:trigger.new){
					if(mt.Transaction_Type__c == 'Sale'){
						codeMap.put(mt.Student__c, null);
					}
				}
				for(Student__c s:[select Id, Name, Meals_Category__c from Student__c where Id IN :codeMap.keyset()]){
					codeMap.put(s.Id, s.Meals_Category__c);
				}
				for(Meal_Transaction__c mt:trigger.new){
					mt.Cost_Type__c = codeMap.get(mt.Student__c);
				}
			}
	
			if(trigger.isDelete){          // trigger executes upon deletion
				Meals_ProcessTransactions.isafter(trigger.old, true, mealSetup, schoolList[0]);
			}
	  
			if(trigger.isafter&&(trigger.isInsert||trigger.isUpdate)){      // trigger executes after insertion and is either an insert or update operation
				Meals_ProcessTransactions.isafter(trigger.new, false, mealSetup, schoolList[0]);
			}
		}
	}
}