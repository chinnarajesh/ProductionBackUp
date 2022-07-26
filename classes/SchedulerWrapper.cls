public class SchedulerWrapper {


		public 		 List <Course_Course_Catalog__c> 		availableCourses 			{get;set;}
		public		List <Room__c>  		availableRooms 			{get;set;}
		public		List <Staff__c>    		availableStaff				{get;set;}
		public		List <Student__c>		availableStudents			{get;set;}
		public 		Setup__c				activeSetup					{get;set;}
		
		public SchedulerWrapper(Account school){
			
			//Get Active Setup for school
					activeSetup =[SELECT school__c, term__c, Course_Catalog__c 
									  FROM Setup__c
									  WHERE active__c = true
									  AND school__c =:school.id
									  LIMIT 1];
								
			//Get Course Catalog related to setup
					
			//Get Courses on the Course Catalog  &  Store on the available course list
				availableCourses = [SELECT 	course__r.name 
									FROM 	Course_Course_Catalog__c
									WHERE 	Course_Catalog__c =:activeSetup.Course_Catalog__c];
			
			//Get any rooms that are usable and linked to the related school & store as the available rooms
			availableRooms = [SELECT 	name, id, size__c 
								FROM 	Room__c 
								WHERE 	usable__c = true
								AND 		school__c = :school.id
								ORDER BY name asc];
			
			//Get all staff records related to school & store as avilable staff
			availableStaff = [	SELECT 	s.Zip_Code__c, s.User_Name__c, s.User_ID__c, s.Title__c, s.SystemModstamp, s.Supervisor__c, s.State__c, s.Start_Date__c, s.Staff_Last_Name__c, s.Staff_Code__c, s.Secondary_Email__c, s.Reference_Id__c, s.Position__c, s.Position_2__c, s.Personal_Phone__c, s.OwnerId, s.Organization__c, s.Official_First_Name__c, s.New_Returning__c, s.Name, s.Middle_Name_Staff__c, s.LastModifiedDate, s.LastModifiedById, s.LastActivityDate, s.Is_Active__c, s.IsDeleted, s.Individual__c, s.Id, s.ID__c, s.Holding_Source__c, s.Grade__c, s.First_Name_Staff__c, s.Extension__c, s.Email__c, s.CreatedDate, s.CreatedById, s.City__c, s.Campus__c, s.Birthday__c, s.Address_2__c, s.Address_1__c 
								FROM 	Staff__c s
								WHERE 	Organization__c =:school.id];
			
			
			//Get all student records related to school & store as available student
			availableStudents = [ 	SELECT 	s.Name, grade__c, gender__c, student_first_name__c 
									FROM 	Student__c s
									WHERE 	school__c =: school.id];
			
			
			
		}

	public class cSectionWrapper{
		
		public Room__c 				room {get;set;}
		public Time_Element__c 		period {get;set;}
		public List <Student__c> 		studentList {get;set;}
		public List <Staff__c>			staffList	{get;set;} //List of staff to allow for multiple
		public Course__c				course 		{get;set;} // Course associating to room
		public Section__c				section		{get;set;}	//Section that will be created or is already created 
		
		
		public cSectionWrapper(Room__c inputRoom){
			this.room = inputRoom;	
			
		}
	}

}