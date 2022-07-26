@isTest
private class Test_Meals {
	public static void createTestData(){
		TestDataSetupUtil_v2.setUPCoreData(5);
		TestDataSetupUtil_v2.setUpStaffData(5);
		TestDataSetupUtil_v2.setUpStudentData(5);
		system.debug('Soql after create data: ' + limits.getQueries());
	}

	static testMethod void testAllMeals() {
		createTestData();

		Student__c student = TestDataSetupUtil_v2.studentsList[0];
			Student__c student2 = TestDataSetupUtil_v2.studentsList[1];
			
		Meals_Setup__c ms=
			new Meals_Setup__c(
				State_Reduced_Lunch_Reimbursement__c=1, 
				State_Full_Price_Lunch_Reimbursement__c=1, 
				State_Free_Lunch_Reimbursement__c=1, 
				Setup__c= TestDataSetupUtil_v2.activeSetUp.Id, 
				Fed_Reduced_Lunch_Reimbursement__c=1, 
				Fed_Full_Price_Lunch_Reimbursement__c=1, 
				Fed_Free_Lunch_Reimbursement__c=1, 
				Additional_Reimbursement_3_Amount__c=1, 
				Additional_Reimbursement_2_Amount__c=1, 
				Additional_Reimbursement_1_Amount__c=1,
				State_Reduced_Breakfast_Reimbursement__c=1, 
				State_Full_Price_Breakfast_Reimbursement__c=1, 
				State_Free_Breakfast_Reimbursement__c=1, 
				Fed_Reduced_Breakfast_Reimbursement__c=1, 
				Fed_Full_Price_Breakfast_Reimbursement__c=1, 
				Fed_Free_Breakfast_Reimbursement__c=1,
				Additional_Reimbursement_3_Applies_To__c='Both', 
				Additional_Reimbursement_2_Applies_To__c='Lunch', 
				Additional_Reimbursement_1_Applies_To__c='Breakfast',
				Reduced_Lunch_Price__c=1, 
				Reduced_Breakfast_Price__c=1,
				Full_Price_Lunch_Price__c=1, 
				Full_Price_Breakfast_Price__c=1,
				Active__c=true);
		insert ms;
		
		student.Meals_Category__c = 'Reduced';
		student.Student_Id__c = 'abc123';	
		core_triggerUtils.mealsTriggerUpdate(true);	
		update student;
		student2.Meals_Category__c = 'Free';
		student2.Student_Id__c = 'abc321';		
		update student2;

		Test.startTest();       
			system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
				MealsController mc = new MealsController();
				mc.mealType = 'Lunch';
				mc.studID = student.Student_Id__c;
				mc.pullStudent();
				mc.buyMeal();
				mc.mealType = 'Lunch';
				mc.studID = student.Student_Id__c;
				mc.pullStudent();
				mc.studentMealList[0].Void__c=true;
				mc.voidTransactions();
				
				mc.mealType = 'Lunch';
				mc.studID = student.Student_Id__c;
				mc.pullStudent();
				mc.buyMeal();
				mc.mealType = 'Lunch';
				mc.studID = student2.Student_Id__c;
				mc.pullStudent();
				mc.buyMeal();
		
				string key = (String) TestDataSetupUtil_v2.school.Id + system.now().format('MM/dd/yyy');
				Daily_Meal_Summary__c dms = [select d.ID, d.Name, d.Total_Reduced_Lunches__c, d.Total_Lunches__c, d.Total_Free_Lunches__c From Daily_Meal_Summary__c d where key__c = :key Limit 1];
				system.debug('#### dms: '+dms);
				system.assert(dms.Total_Reduced_Lunches__c==1);
				system.assert(dms.Total_Free_Lunches__c==1);
				system.assert(dms.Total_Lunches__c==2);
			}
		test.stopTest();
	}

	static testMethod void testSchoolwideFreeBreakfast(){
		createTestData();
		Student__c student = TestDataSetupUtil_v2.studentsList[0];
		Student__c student2 = TestDataSetupUtil_v2.studentsList[1];
		Student__c student3 = TestDataSetupUtil_v2.studentsList[2];
		Student__c student4 = TestDataSetupUtil_v2.studentsList[3];
		Student__c student5 = TestDataSetupUtil_v2.studentsList[4];
		
		Meals_Setup__c ms = 
			new Meals_Setup__c(
				Setup__c= TestDataSetupUtil_v2.activeSetUp.Id, 
				State_Reduced_Breakfast_Reimbursement__c=1, 
				State_Full_Price_Breakfast_Reimbursement__c=0, 
				State_Free_Breakfast_Reimbursement__c=2, 
				Fed_Reduced_Breakfast_Reimbursement__c=1, 
				Fed_Full_Price_Breakfast_Reimbursement__c=0, 
				Fed_Free_Breakfast_Reimbursement__c=2,
				Schoolwide_Free_Breakfast__c=true,
				Active__c=true);
		insert ms;
		core_triggerUtils.mealsTriggerUpdate(true);
		List<Student__c> students = new List<Student__c>();

		student.Meals_Category__c = 'Reduced';	
		students.add(student);
		student2.Meals_Category__c = 'Reduced';		
		students.add(student2);
		student3.Meals_Category__c = 'Free';		
		students.add(student3);
		student4.Meals_Category__c = 'Free';		
		students.add(student4);
		student5.Meals_Category__c = 'Full-Priced';		
		students.add(student5);

		update students;

		Test.startTest();       
			system.runAs(testDataSetupUtil_v2.staffUsersList[0]){
				MealsController mc = new MealsController();

				mc.mealType = 'Breakfast';
				mc.studID = student.Student_Id__c;
				mc.pullStudent();
				mc.buyMeal();

				mc.mealType = 'Breakfast';
				mc.studID = student2.Student_Id__c;
				mc.pullStudent();
				mc.buyMeal();

				mc.mealType = 'Breakfast';
				mc.studID = student3.Student_Id__c;
				mc.pullStudent();
				mc.buyMeal();

				mc.mealType = 'Breakfast';
				mc.studID = student5.Student_Id__c;
				mc.pullStudent();
				mc.buyMeal();
				
				string key = (String) TestDataSetupUtil_v2.school.Id + system.now().format('MM/dd/yyy');
				Daily_Meal_Summary__c dms = [select d.Total_State_Local_Reimbursement__c, d.Total_Reduced_Breakfasts__c, d.Total_Full_Price_Breakfasts__c, d.Total_Free_Breakfasts__c, d.Total_Federal_Reimbursement__c, d.Total_Breakfasts__c, d.Additional_Breakfasts_Served__c From Daily_Meal_Summary__c d where key__c = :key Limit 1];
				system.debug('#### dms: '+dms);
				system.assertEquals(1, dms.Total_Free_Breakfasts__c);
				system.assertEquals(2, dms.Total_Reduced_Breakfasts__c);
				system.assertEquals(1, dms.Total_Full_Price_Breakfasts__c);
				system.assertEquals(4, dms.Total_Breakfasts__c);
				system.assertEquals(4, dms.Total_Federal_Reimbursement__c);
				system.assertEquals(4, dms.Total_State_Local_Reimbursement__c);
			}
		Test.stopTest();
	}
}