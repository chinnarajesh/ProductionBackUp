public with sharing class MealsController{
	public String 						mealType		{get;set;}
	public String						studID			{get;set;}
	public List <SelectOption>			mealList		{get;set;}
	public Student__c 					student			{get;set;}
	public core_BaseInfo_v2.cSchool_BaseInfo baseObj	{get;set;}
	public Meals_Setup__c 				mealSetup;
	public Meal_Transaction__c 			dummyMT			{get;set;}
	public Double 						cost			{get;set;}
	public boolean 						showMeal		{get;set;}
	public boolean 						pastDate		{get;set;}
	public List<Meal_Transaction__c> 	studentMealList	{get;set;}
	public DateTime 					daystart		{get;set;}
	public DateTime 					dayend			{get;set;}
	public Integer 						breakfastCnt;
	public Integer 						lunchCnt;
	public String 						studentMealType	{get;set;}
	public boolean 						displayEverything	{get;set;}//boolean to keep the rest of the page showing when the user does not have all the proper credentials
	public boolean 						firstClick			{get;set;}//boolean used to make sure if a different meal type is chosen, it is updated
	public Meal_Transaction__c 			mealTime {get;set;}

	public MealsController(){
		try{
			mealTime = new Meal_Transaction__c();
			pastDate = false;
			firstClick = false;
			displayEverything = false;
			dummyMt = new Meal_Transaction__c();
			breakfastCnt = 0;
			lunchCnt = 0;
			student = new Student__c();
			studentMealList = new List <Meal_Transaction__c>();
			showMeal = false;
			mealList = new List<SelectOption>{new SelectOption('Lunch','Lunch'),new SelectOption('Breakfast','Breakfast')};
			core_BaseInfo_v2.initBaseInfo();
			baseObj = core_BaseInfo_v2.baseInfoObj;
			try {
				Id setupID = baseObj.activeSetup.Id;
				mealSetup = [select m.Id, m.Name, m.Schoolwide_Free_Breakfast__c, m.Reduced_Lunch_Price__c, m.Reduced_Breakfast_Price__c, m.Full_Price_Lunch_Price__c, m.Full_Price_Breakfast_Price__c from Meals_Setup__c m where Setup__c = :setupID Limit 1];
				displayEverything = true;
			} catch(Exception e) {
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'Please contact your system administrator to verify that ' + userInfo.getFirstName() + ' ' + userInfo.getLastName() + ' is associated with a Staff record, an active Setup record, and an active Meals Setup record.'));
			}

		}
		catch(Exception e){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'There was an error loading the page.'));
		}
	}

	public void pullStudent(){
		try{
			Integer year;
			Integer month;
			Integer day;

			if(pastDate&&mealTime.Transaction_Date__c!=null){
				year = mealTime.Transaction_Date__c.year();
				month = mealTime.Transaction_Date__c.month();
				day = mealTime.Transaction_Date__c.day();

			}
			else{
				year = system.now().year();
				month = system.now().month();
				day = system.now().day();
			}
			daystart = datetime.newInstance(year, month, day, 0, 0, 0);
			dayend = datetime.newInstance(year, month, day, 23, 59, 59);

			firstClick = true;
			breakfastCnt = 0;
			lunchCnt = 0;
			studentMealType = 'Free';
			if(studID==''){
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'Please enter a student ID.'));
			}else{
				list<Student__c> tempList = [select ID, Name, Student_Picture__c, Meals_Category__c, Current_Meals_Balance__c from Student__c where Student_Id__c = :studID and Active__c=true and Setup__C =:baseObj.activeSetup.Id];
				if(tempList.size()>0){
					student = tempList[0];
					showMeal=true;
				}else{
					Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'No active student found for the ID that was entered.'));
				}
				if(student.Meals_Category__c=='--None--' || student.Meals_Category__c==null){
					Apexpages.addMessage(new apexpages.message(apexpages.severity.error, student.Name+' has not been assigned a meal category.'));
				}
			}

			cost = 0;
			if(mealType=='Lunch'){
				if(student.Meals_Category__c=='Reduced'){
					cost = mealSetup.Reduced_Lunch_Price__c;
				}
				else if(student.Meals_Category__c=='Full-Priced'){
					cost = mealSetup.Full_Price_Lunch_Price__c;
				}
			}else if(mealType=='Breakfast'){
				if(mealSetup.Schoolwide_Free_Breakfast__c){
					cost = 0;
				}
				else if(student.Meals_Category__c=='Reduced'){
					cost = mealSetup.Reduced_Breakfast_Price__c;
				}
				else if(student.Meals_Category__c=='Full-Priced'){
					cost = mealSetup.Full_Price_Breakfast_Price__c;
				}
			}

			if(mealType=='Lunch'||!mealSetup.Schoolwide_Free_Breakfast__c){
				studentMealType = student.Meals_Category__c;
			}


			studentMealList = [select m.Id, m.Name, m.Void__c, m.Transaction_Date__c, m.Transaction_Amount__c, m.Meal_Type__c From Meal_Transaction__c m where Student__c = :student.ID AND Transaction_Date__c > :daystart AND Transaction_Date__c < :dayend order by Transaction_Date__c asc];


			for(Meal_Transaction__c ms:studentMealList){
				if(!ms.Void__c&&ms.Meal_Type__c=='Lunch'&&(student.Meals_Category__c=='Free'||student.Meals_Category__c=='Reduced')){
					lunchCnt++;
				}
				if(!ms.Void__c&&ms.Meal_Type__c=='Breakfast'&&(student.Meals_Category__c=='Free'||student.Meals_Category__c=='Reduced'||mealSetup.Schoolwide_Free_Breakfast__c)){
					breakfastCnt++;
				}
			}
			dummyMT.Transaction_Amount__c = cost;
		}
		catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('Setup, '+baseObj.activeSetup.id+'; Student, '+studID+'; Meals Setup, '+mealSetup.id, 'Meals', 'error finding student information', e);
			insert ge;
		}
	}

	public void buyMeal(){
		try{
			String errorText = student.Name+' was already served ' + mealType.toLowerCase() + ' today.';
			if(pastDate&&mealTime.Transaction_Date__c!=null){
				errorText = student.Name + ' already has a ' + mealType.toLowerCase() + ' transaction for the date selected.';
			}
			if(mealType=='Lunch'&&lunchCnt>0){
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, errorText));
			}
			else if(mealType=='Breakfast'&&breakfastCnt>0){
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, errorText));
			}
			else if(student.Meals_Category__c=='--None--' || student.Meals_Category__c==null){
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, student.Name+' has not been assigned a meal category.'));
			}
			else{
				Meal_Transaction__c meal = new Meal_Transaction__c();
				meal.student__c = student.Id;
				if(!pastDate||mealTime.Transaction_Date__c==null){
					meal.Transaction_Date__c = system.now();
				}
				else{
					meal.Transaction_Date__c = mealTime.Transaction_Date__c;
				}

				meal.Transaction_Type__c = 'Sale';
				meal.Meal_Type__c = mealType;
				meal.Transaction_Amount__c = cost;
				try{
					insert meal;
				}
				catch(exception e){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was an error saving the meal transaction.'));
					throw e;
				}
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'You successfully bought ' + mealType.toLowerCase() + ' for ' + student.Name + '.'));
				showMeal = false;
				studID = '';
				studentMealList.clear();
				student = new Student__c();
				studentMealType='Free';
			}
		}
		catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('Setup, '+baseObj.activeSetup.id+'; Student, '+studID+'; Meals Setup, '+mealSetup.id, 'Meals', 'error saving meal transaction', e);
			Error_Handling.errorMessage('There was an error processing your request.');
			insert ge;
		}
	}

	public void voidTransactions(){
		try{
			try{
				upsert studentMealList;
			}
			catch(exception e){
				Apexpages.addMessage(new apexpages.message(apexpages.severity.error, 'There was an error voiding the meal transaction.'));
				throw e;
			}
			pullStudent();
		}
		catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('Setup, '+baseObj.activeSetup.id+'; Student, '+studID+'; Meals Setup, '+mealSetup.id, 'Meals', 'error voiding transactions', e);
			insert ge;
		}
	}
}