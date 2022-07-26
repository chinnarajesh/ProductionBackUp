public with sharing class Meals_ProcessTransactions {

	public static void isafter(List <Meal_Transaction__c> mtList, Boolean isDeleted, Meals_Setup__c mealSetup, ID schoolID){
	
		Set<String> dailyKeySet = new Set<String>();
		Set<ID> dailyIDSet = new Set<ID>();
		Set<ID> studentIDs = new Set<ID>();
		Map<String, Daily_Meal_Summary__c> dailyMap = new Map<String, Daily_Meal_Summary__c>();
		List<Daily_Meal_Summary__c> newDailyList = new List<Daily_Meal_Summary__c>();
		Map<String, Date> sumDateMap = new Map<String, Date>();
		List<Meal_Transaction__c> updateMealList = new List<Meal_Transaction__c>();
		
		
		for(Meal_Transaction__c mt: mtList){
			if(mt.Transaction_Type__c == 'Sale'){
				dailyKeySet.add((String) schoolID + mt.Transaction_Date__c.format('MM/dd/yyy'));
				sumDateMap.put((String) schoolID + mt.Transaction_Date__c.format('MM/dd/yyy'),mt.Transaction_Date__c.date());
				studentIDs.add(mt.Student__c);
			}
		}
		for(Daily_Meal_Summary__c dms:[select ID, Key__c, Name from Daily_Meal_Summary__c where Key__c IN :dailyKeySet]){
			dailyMap.put(dms.Key__c, dms);
			dailyIDSet.add(dms.Id);
		}
		
		if(!isDeleted){
			
			for(String s:dailyKeySet){
				if(!dailyMap.keyset().contains(s)){
					newDailyList.add(new Daily_Meal_Summary__c(School__c=schoolID, Key__c=s, Summary_Date__c = sumDateMap.get(s)));
				}
			}
			if(newDailyList.size()>0){
				insert newDailyList;
			}
			
			for(Daily_Meal_Summary__c dms:newDailyList){
				dailyMap.put(dms.Key__c, dms);
				dailyIDSet.add(dms.Id);
			}
			for(Meal_Transaction__c mt:mtList){
				if(mt.Daily_Meal_Summary__c==null&&mt.Transaction_Type__c == 'Sale'){
					updateMealList.add(new Meal_Transaction__c(Id=mt.Id, Daily_Meal_Summary__c = dailyMap.get((String) schoolID + mt.Transaction_Date__c.format('MM/dd/yyy')).Id));
				}
			}
			try{
				core_triggerUtils.recursiveHelper(true);
				update updateMealList;
				core_triggerUtils.recursiveHelper(false);
			}
			catch(exception e){
				system.debug('#### An error occurred while updating the link from Meal Transaction to Daily Meal Summary');
			}
		}
		
		rollupDMSTotals(dailyIDSet, mealSetup);

		if(!studentIDs.isEmpty()){
			Map<Id, Student__c> students = new Map<ID, Student__c>([select id, Setup__c from Student__C where ID IN: studentIDs]);
			rollupStats(students);
		}		
	}
	
	public static void rollupStats(Map<ID,Student__c> studMap){
		Map<ID,Meals_Setup__c> mealsSetupMap = new Map<ID, Meals_Setup__c>();
		Map<ID,Double> totalMap = new Map<ID, Double>();
		Map<ID,Double> freeReducedMap = new Map<ID, Double>();
		Set<ID> schoolIDSet = new Set<ID>();
		for(ID sid:studMap.keyset()){
			schoolIDSet.add(studMap.get(sid).Setup__c);
		}
		for(Meals_Setup__c ms : [Select Id, Setup__r.School__c, of_Students_Receiving_Free_Meals__c, of_Students_Receiving_Reduced_Meals__c, of_Students_Receiving_Full_Price_Meals__c, Students_Eligible_for_Free_Reduced__c From Meals_Setup__c where Setup__c IN :schoolIDSet AND Active__c = true]){
			mealsSetupMap.put(ms.Setup__r.School__c, ms);
			totalMap.put(ms.Setup__r.School__c,0);
			freeReducedMap.put(ms.Setup__r.School__c,0);
			mealsSetupMap.get(ms.Setup__r.School__c).of_Students_Receiving_Free_Meals__c = 0;
			mealsSetupMap.get(ms.Setup__r.School__c).of_Students_Receiving_Reduced_Meals__c = 0;
			mealsSetupMap.get(ms.Setup__r.School__c).of_Students_Receiving_Full_Price_Meals__c = 0;
		}
		
		AggregateResult[] groupedResults = 
            [
            SELECT School__c s, Meals_Category__c m,
            count(ID) cnt
            FROM Student__c 
            WHERE School__c IN :mealsSetupMap.keyset()
            AND School__c != null 
            AND Active__c = true
            GROUP BY School__c, Meals_Category__c];
			
		
		for (AggregateResult ar : groupedResults)  { 
			Meals_Setup__c msTemp = new Meals_Setup__c();
			msTemp = mealsSetupMap.get((ID)ar.get('s'));
			Integer arCount = (Integer)ar.get('cnt');
			double tempTotal = totalMap.get((ID)ar.get('s'));
			double tempFreeTotal = freeReducedMap.get((ID)ar.get('s'));
			
			if((ID)ar.get('s')==null){}
			else{
				if((String)ar.get('m')=='Free'){
					msTemp.of_Students_Receiving_Free_Meals__c = arCount;
					tempTotal += arCount;
					tempFreeTotal += arCount;
				}
				else if((String)ar.get('m')=='Reduced'){
					msTemp.of_Students_Receiving_Reduced_Meals__c = arCount;
					tempTotal += arCount;
					tempFreeTotal += arCount;
				}
				else if((String)ar.get('m')=='Full-Priced'){
					msTemp.of_Students_Receiving_Full_Price_Meals__c = arCount;
					tempTotal += arCount;
				}
				else if((String)ar.get('m')==null){
					tempTotal += arCount;
				}
			}
			totalMap.put((ID)ar.get('s'),tempTotal);
			freeReducedMap.put((ID)ar.get('s'),tempFreeTotal);
		}
		
		for(ID sid:mealsSetupMap.keyset()){
			if(totalMap.get(sid)==0){
				//?
			}
			else{
				mealsSetupMap.get(sid).Students_Eligible_for_Free_Reduced__c = (freeReducedMap.get(sid)/totalMap.get(sid))*100;
			}
			
		}
		
		try{
			update mealsSetupMap.values();
		}
		catch(exception e){
			system.debug('##### Error while updating MealSetup object.'+e);
		}
		
	}
	
	public static void rollupDMSTotals(Set<ID> dailyIDSet, Meals_Setup__c mealsetup){
		
		Map<ID,Daily_Meal_Summary__c> updateDailyMap = new Map<ID,Daily_Meal_Summary__c>();
		Map<ID,Double> nonScanMap = new Map<ID,Double>();
		
		for(ID dailyid : dailyIDSet){
			nonScanMap.put(dailyid,0);
		}
		
		for(Daily_Meal_Summary__c dms:[Select Id, Non_Scan_Reimbursable_Breakfasts__c from Daily_Meal_Summary__c where Id IN :nonScanMap.keyset()]){
				nonScanMap.put(dms.Id, dms.Non_Scan_Reimbursable_Breakfasts__c);
		}
		
		AggregateResult[] groupedResults = 
                [
                SELECT Daily_Meal_Summary__c d, 
                sum(Transaction_Amount__c) ta
                FROM Meal_Transaction__c 
                WHERE Daily_Meal_Summary__c IN :dailyIDSet
                AND Transaction_Type__c = 'Sale'
                AND Void__c = false
                GROUP BY Daily_Meal_Summary__c];		
				
			for (AggregateResult ar : groupedResults)  {								
				updateDailyMap.put((ID)ar.get('d'),new Daily_Meal_Summary__c(Id = (ID)ar.get('d'), Total_Monies_Received__c = (Decimal)ar.get('ta'), Total_Free_Breakfasts__c = 0,
				Total_Reduced_Breakfasts__c = 0,
				Total_Full_Price_Breakfasts__c = 0,
				Total_Free_Lunches__c = 0,
				Total_Reduced_Lunches__c = 0,
				Total_Full_Price_Lunches__c = 0,
				Total_Federal_Reimbursement__c = 0,
				Total_State_Local_Reimbursement__c = 0));
			}
			
			
			AggregateResult[] groupedResults2 = 
                [
                SELECT Daily_Meal_Summary__c d, Meal_Type__c m, Cost_Type__c c,
                count(Name) cnt
                FROM Meal_Transaction__c 
                WHERE Daily_Meal_Summary__c IN :dailyIDSet
                AND Transaction_Type__c = 'Sale'
                AND Void__c = false
                GROUP BY ROLLUP(Daily_Meal_Summary__c, Meal_Type__c, Cost_Type__c)];
				
			
			for (AggregateResult ar : groupedResults2)  {	
				Daily_Meal_Summary__c tempDMS = new Daily_Meal_Summary__c();
				tempDMS = updateDailyMap.get((ID)ar.get('d'));
				Integer arCount = (Integer)ar.get('cnt');
											
				if((String)ar.get('m')=='Breakfast'){
					if((String)ar.get('c')=='Free'){
						tempDMS.Total_Free_Breakfasts__c = arCount;
					}
					if((String)ar.get('c')=='Reduced'){
						tempDMS.Total_Reduced_Breakfasts__c = arCount;
					}
					if((String)ar.get('c')=='Full-Priced'){
						tempDMS.Total_Full_Price_Breakfasts__c = arCount;
					}					
				}
				else if((String)ar.get('m')=='Lunch'){
					if((String)ar.get('c')=='Free'){
						tempDMS.Total_Free_Lunches__c = arCount;
					}
					if((String)ar.get('c')=='Reduced'){
						tempDMS.Total_Reduced_Lunches__c = arCount;
					}
					if((String)ar.get('c')=='Full-Priced'){
						tempDMS.Total_Full_Price_Lunches__c = arCount;
					}					
				}
			}
			
			for(ID dmsID: updateDailyMap.keyset()){
				Double fedamt = 0;
				Double stateamt = 0;
				Daily_Meal_Summary__c tempDMS = updateDailyMap.get(dmsID);
				fedamt = (tempDMS.Total_Reduced_Lunches__c * mealSetup.Fed_Reduced_Lunch_Reimbursement__c) + 
						 (tempDMS.Total_Free_Lunches__c * mealSetup.Fed_Free_Lunch_Reimbursement__c) + 
						 (tempDMS.Total_Full_Price_Lunches__c * mealSetup.Fed_Full_Price_Lunch_Reimbursement__c) +
						 (tempDMS.Total_Reduced_Breakfasts__c * mealSetup.Fed_Reduced_Breakfast_Reimbursement__c) +
						 (tempDMS.Total_Free_Breakfasts__c * mealSetup.Fed_Free_Breakfast_Reimbursement__c) +
						 (tempDMS.Total_Full_Price_Breakfasts__c * mealSetup.Fed_Full_Price_Breakfast_Reimbursement__c) +
						 (nonScanMap.get(dmsID) * mealSetup.Fed_Free_Breakfast_Reimbursement__c);
						 
				Double temptotalLunch = tempDMS.Total_Reduced_Lunches__c + tempDMS.Total_Free_Lunches__c + tempDMS.Total_Full_Price_Lunches__c;
				Double temptotalBreakfast = tempDMS.Total_Reduced_Breakfasts__c + tempDMS.Total_Free_Breakfasts__c + tempDMS.Total_Full_Price_Breakfasts__c + nonScanMap.get(dmsID);
				Double additional1total = 0;
				Double additional2total = 0;
				Double additional3total = 0;
				
				if(mealSetup.Additional_Reimbursement_1_Applies_To__c=='Lunch'||mealSetup.Additional_Reimbursement_1_Applies_To__c=='Both'){
					additional1total += temptotalLunch*mealSetup.Additional_Reimbursement_1_Amount__c;
				}
				if(mealSetup.Additional_Reimbursement_1_Applies_To__c=='Breakfast'||mealSetup.Additional_Reimbursement_1_Applies_To__c=='Both'){
					additional1total += temptotalBreakfast*mealSetup.Additional_Reimbursement_1_Amount__c;
				}
				if(mealSetup.Additional_Reimbursement_2_Applies_To__c=='Lunch'||mealSetup.Additional_Reimbursement_2_Applies_To__c=='Both'){
					additional2total += temptotalLunch*mealSetup.Additional_Reimbursement_2_Amount__c;
				}
				if(mealSetup.Additional_Reimbursement_2_Applies_To__c=='Breakfast'||mealSetup.Additional_Reimbursement_2_Applies_To__c=='Both'){
					additional2total += temptotalBreakfast*mealSetup.Additional_Reimbursement_2_Amount__c;
				}
				if(mealSetup.Additional_Reimbursement_3_Applies_To__c=='Lunch'||mealSetup.Additional_Reimbursement_3_Applies_To__c=='Both'){
					additional3total += temptotalLunch*mealSetup.Additional_Reimbursement_3_Amount__c;
				}
				if(mealSetup.Additional_Reimbursement_3_Applies_To__c=='Breakfast'||mealSetup.Additional_Reimbursement_3_Applies_To__c=='Both'){
					additional3total += temptotalBreakfast*mealSetup.Additional_Reimbursement_3_Amount__c;
				}
				
				stateamt = (tempDMS.Total_Reduced_Lunches__c * mealSetup.State_Reduced_Lunch_Reimbursement__c) + 
						   (tempDMS.Total_Free_Lunches__c * mealSetup.State_Free_Lunch_Reimbursement__c) + 
						   (tempDMS.Total_Full_Price_Lunches__c * mealSetup.State_Full_Price_Lunch_Reimbursement__c) +
						   (tempDMS.Total_Reduced_Breakfasts__c * mealSetup.State_Reduced_Breakfast_Reimbursement__c) +
						   (tempDMS.Total_Free_Breakfasts__c * mealSetup.State_Free_Breakfast_Reimbursement__c) +
						   (tempDMS.Total_Full_Price_Breakfasts__c * mealSetup.State_Full_Price_Breakfast_Reimbursement__c) +
						   (nonScanMap.get(dmsID) * mealSetup.State_Free_Breakfast_Reimbursement__c) +
						   (additional1total + additional2total + additional3total);
				
				tempDMS.Total_Federal_Reimbursement__c = fedamt;
				tempDMS.Total_State_Local_Reimbursement__c = stateamt;   
			}
			
			if(groupedResults.size()==0){
				Double additional = 0;
				if(mealSetup.Additional_Reimbursement_1_Applies_To__c=='Breakfast'||mealSetup.Additional_Reimbursement_1_Applies_To__c=='Both'){
					additional += mealSetup.Additional_Reimbursement_1_Amount__c;
				}
				if(mealSetup.Additional_Reimbursement_2_Applies_To__c=='Breakfast'||mealSetup.Additional_Reimbursement_2_Applies_To__c=='Both'){
					additional += mealSetup.Additional_Reimbursement_2_Amount__c;
				}
				if(mealSetup.Additional_Reimbursement_3_Applies_To__c=='Breakfast'||mealSetup.Additional_Reimbursement_3_Applies_To__c=='Both'){
					additional += mealSetup.Additional_Reimbursement_3_Amount__c;
				}
				Double fedamt = mealSetup.Fed_Free_Breakfast_Reimbursement__c;
				Double stateamt = mealSetup.State_Free_Breakfast_Reimbursement__c + additional;
			
				for(ID dailyid : nonScanMap.keyset()){
					updateDailyMap.put(dailyid,new Daily_Meal_Summary__c(Id = dailyid, Total_Monies_Received__c = 0, Total_Free_Breakfasts__c = 0,
					Total_Reduced_Breakfasts__c = 0,
					Total_Full_Price_Breakfasts__c = 0,
					Total_Free_Lunches__c = 0,
					Total_Reduced_Lunches__c = 0,
					Total_Full_Price_Lunches__c = 0,
					Total_Federal_Reimbursement__c = fedamt * nonScanMap.get(dailyid),
					Total_State_Local_Reimbursement__c = stateamt * nonScanMap.get(dailyid)));
				}
			}
			
			try{
				update updateDailyMap.values();
			}
			catch(exception e){
				system.debug('##### Error updating the Daily Meal Summary records.');
			}
	}
	
	
}