trigger Daily_Meal_Summary_BIAIAU on Daily_Meal_Summary__c (after insert, after update, before insert) {
	if (!core_triggerUtils.bTriggersDisabled()){	
		Set<ID> dmsIDSet = new Set<ID>();
		Set<ID> schoolIDSet = new Set<ID>();
		try{
		if(trigger.isbefore){
			for(Daily_Meal_Summary__c dms: trigger.new){
				if(dms.Key__c==null||dms.Key__c==''){
					dms.Key__c = (String)dms.School__c + system.now().format('MM/dd/yyy');
				}
			}
		}
		
		if(Trigger.isAfter){
			
			if(trigger.isInsert){
				for(Daily_Meal_Summary__c dms: trigger.new){
					if(dms.Non_Scan_Reimbursable_Breakfasts__c!=0){
						dmsIDSet.add(dms.Id);
						schoolIDSet.add(dms.School__c);
					}
				}
			}
			
			if(trigger.isUpdate){
				integer i=0;
				for(Daily_Meal_Summary__c dms:trigger.new){
					if(trigger.old[i].Non_Scan_Reimbursable_Breakfasts__c!=trigger.new[i].Non_Scan_Reimbursable_Breakfasts__c){
						dmsIDSet.add(dms.Id);
						schoolIDSet.add(dms.School__c);
					}
				}
			}
			
			if(dmsIDSet.size()>0){
				Map<ID,Setup__c> setupMap = new Map<ID,Setup__c>();
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
				
				Meals_ProcessTransactions.rollupDMSTotals(dmsIDSet, mealsetup);
			}
		}
		}
		catch(Exception e){
			string links;
			for(Daily_Meal_Summary__c s: trigger.new){
		        			if(s.id != null){
		        				if(links==''){
		        					links = s.id + ',' + s.id;
		        				}
		        				else{
		        					links = links + ';' + s.id + ',' + s.id;
		        				}
		        			}
		        		}
			Global_Error__c ge = Error_Handling.handleError(links, 'Meals', 'Meal transaction trigger error', e);
	    		insert ge;
	    		Apexpages.addMessage(new apexpages.message(apexpages.severity.ERROR,'' ));
		}
}
}