public with sharing class Student_SearchStudent {
	public string mainQuery='SELECT Active__c, Date_of_Birth__c, Exit_Date__c, Exit_Reason__c, ID, Race_Multi__c'+
					',Individual__c, Individual__r.MailingStreet, Grade__c, Name, Primary_Schedule_Group__c'+
					',Reference_ID__c, School__c, Student_First_Name__c, Student_Last_Name__c, Student_Id__c, Individual__r.Original_Member_Of_Cohort__c,Original_Member_Of_Cohort__c, Individual__r.Cohort__c, ELL__c  ' +
					' ,School__r.Reference_ID__c, School_Year__r.name__c, Cohort__c, Entry_Date__c, Gender__c, Setup__r.Course_Catalog__c'+
					' FROM Student__c WHERE Active__c =true'; //only search active students
	public List<Student__c>	studResults	{get; set;}	//results of student search
	public Student__c student			{get; set;} //a student object to use to save the values from the search
	public ID school					{get; set;}

	public Student_SearchStudent(){
		student = new Student__c(Date_Of_Birth__c=null);
		studResults = new List <Student__c>();
	}

	public void searchStudents(){
		try{
			String sFirstName = CT_core_SoqlUtils.getSearchName(student.Student_First_Name__c);
			String sLastName = CT_core_SoqlUtils.getSearchName(student.Student_Last_Name__c);

			studResults.clear();
			String query = mainQuery;
			query += (String.isNotBlank(school))?' AND School__c =\''+school+'\'':'';
			query += (String.isNotBlank(sFirstName))?' AND Student_First_Name__c LIKE \''+sFirstName+'\'':'';
			query += (String.isNotBlank(sLastName))?' AND Student_Last_Name__c LIKE \''+sLastName+'\'':'';
			query += (String.isNotBlank(student.Gender__c))?' AND Gender__c=\''+student.Gender__c+'\'':'';
			query += (String.isNotBlank(student.Race_Multi__c))?' AND (Race_Multi__c '+CT_StringUtils.buildMutliSelectQuery(student.Race_Multi__c.split(';'))+')':'';
			query += (String.isNotBlank(student.Student_Id__c))?' AND Student_Id__c=\''+student.Student_Id__c+'\'':'';
			query += (String.isNotBlank(student.Grade__c))?' AND Grade__c=\''+student.Grade__c+'\'':'';
			query += (String.isNotBlank(student.Cohort__c))?' AND Cohort__c=\'' + student.Cohort__c + '\'':'';

			if(student.Date_of_Birth__c!=null){
				String[] vars = student.Date_of_Birth__c.format().split('/',3);
				if(vars[0].length()==1) vars[0] = '0'+vars[0];
				if(vars[1].length()==1) vars[1] = '0'+vars[1];
				query += ' AND Date_of_Birth__c='+vars[2]+'-'+vars[0]+'-'+vars[1];
			}
			if(student.Entry_Date__c!=null){
				String[] vars = student.Entry_Date__c.format().split('/',3);
				if(vars[0].length()==1) vars[0] = '0'+vars[0];
				if(vars[1].length()==1) vars[1] = '0'+vars[1];
				query += ' AND Entry_Date__c='+vars[2]+'-'+vars[0]+'-'+vars[1];
			}
			
			query += ' ORDER BY Student_Last_Name__c, Student_First_Name__c ASC';
			system.debug(JSON.serializePretty(query));
			studResults = (List<Student__c>) Database.query(query);
		} catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('', 'Student Search Utility', 'An error occured during search.', e);
			insert ge;
		}
	}
}