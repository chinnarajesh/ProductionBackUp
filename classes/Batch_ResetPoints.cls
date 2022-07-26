global class Batch_ResetPoints implements Database.Batchable<SObject>, Database.Stateful{
    global String                               query;
    global Set<String> 						setupIds;
    
   
    
    public static String processQuery(Set<String> setupIds){
        string queryToProcess;
            if(setupIds!=null){
                queryToProcess = ' SELECT Final_Grade_Level__c,Reference_Id__c,Zip_Code__c, X504_Plan__c, Title_1_Status_Date__c, Student_Last_Name__c,'
                                +' Student_Id__c, Student_First_Name__c, State__c, Special_Ed__c, Special_Ed_Type__c, Special_Ed_Type_Notes__c,'
                                +'Service_Hours_YTD__c, School__c, School_Year__c, School_Name__c, School_Counseling__c, School_Bus__c, School_Bus_Route__c,'
                                +'Retained_in_a_previous_grade_level__c, Residence_After_Exiting_School__c, Race__c, Race_Multi__c, Primary_Schedule_Group__c,'
                                +'Previous_School_2__c, Previous_School_2_Type__c, Previous_School_1__c, Previous_School_1_Type__c, Official_Exit_Type__c,'
                                +'Mobile_Phone__c, Migrant__c, Meals_Sub_Category__c, Meals_Category__c , Lep_Flag__c, Individual__c, Immigrant__c, '
                                +'Immigrant_Program_Participant__c, IEP_Program__c, Home_Language__c, Grades_Overridden__c, Grade_Track__c, Gifted__c,'
                                +'Gender__c, GPA_To_Date__c, Final_GPA_Value__c, Exit_Status__c, Exit_Date__c, Exit_Reason__c,  Exit_Comments__c, '
                                +'Evaluation_Type__c, Evaluation_Date__c, Evaluated_for_special_education__c, Ethnicity__c, Entry_Type__c, Entry_Date__c, '
                                +'Emergency_Contact_2_Name__c, Emergency_Contact_1_Work_Phone__c, Emergency_Contact_1_Name__c, Economically_Disadvantaged__c,'
                                +'ELL__c, ELL_Test__c, ELL_Test_Date__c, ELL_Student_in_a_US_School_Less_Than_1_Y__c, ELL_Level__c, ELL_Hours__c,' 
                                +'EContact_2_Work_Phone__c, EContact_2_Home_Phone__c, EContact_2_Cell_Phone__c, EContact_1_Home_Phone__c,' 
                                +'EContact_1_Cell_Phone__c, EC_1_Relationship_to_Student__c, Disability_Flag__c, Days_Enrolled__c, Date_of_Birth__c,'
                                +'Current_School_Year__c, Current_Meals_Balance__c, Country_of_Origin__c, Combined_Final_Grade_Values__c, City__c,' 
                                +'Birth_Place_State__c, Birth_Place_City__c, Asian__c, Archived__c, American_Indian_or_Alaska_Native__c,' 
                                +'Alternate_Lang_Comments__c, Next_School__c,Age__c, Address__c, Grade__c,Intent_to_Return_Following_Year__c,Setup__c,Promoted__c,'
								+'Setup__r.Points_Reset_Value__c, Setup__r.Points_Reset_Date__c'
                                +' FROM Student__c';
                
                    queryToProcess+='  WHERE Setup__c in : setupIds';
                    queryToProcess+='  AND Setup__r.Active__c = true';
                    queryToProcess+='  AND Active__c = true';
                }
            
        
        return queryToProcess;
    }
 
    
    global Database.QueryLocator start(Database.BatchableContext ctx) {
        
        try{
            
            if(setupIds !=null){
                query = Batch_ResetPoints.processQuery(setupIds);
			}
            return Database.getQueryLocator(query); 
        }
        catch(Exception e){
            Global_Error__c ge = Error_Handling.handleError('Setup Ids, '+setupIds, 'Batch_Points', 'QueryLocator error during Batch_Points', e);
            insert ge;
            return null;
        }
    }
    
    global void execute(Database.BatchableContext ctx, List<Student__c> scope) {
        try{    
                 
                   Points_Utils.updatePointsBalance(scope); 
        }
        
        catch(Exception e){
            Global_Error__c ge = Error_Handling.handleError('School Ids, '+setupIds, 'Batch_ResetStudentPoints', 'Error while updating points balances on students', e);
            insert ge;
        }
    }
    global void finish(Database.BatchableContext ctx) { 
      
    }
    
 
}