public with sharing class CT_ImportMappers {
	/**
	 * Factory method to create SchoolMapper.
	 */
	public static SchoolMapper createSchoolMapper() {
		return new SchoolMapper();
	}
	//Dummy comment
	/**
	 * Factory method to create StudentContactMapper.
	 */
	public static StudentMapper createStudentContactMapper() {
		return new StudentMapper();
	}
	
	/**
	 * Factory method to create StudentSchoolGradeMapper.
	 */
	public static StudentSchoolGradeMapper createStudentSchoolGradeMapper() {
		return new StudentSchoolGradeMapper();
	}
	
	/**
	 * Factory method to create SectionMapper.
	 */
	public static SectionMapper createSectionMapper() {
		return new SectionMapper();
	}
	
	/**
	 * Factory method to create StaffMapper.
	 */
	public static StaffMapper createStaffMapper() {
		return new StaffMapper();
	}
	
	
	/**
	 * Factory method to create NetworkMapper.
	 */
	 /*
	public static NetworkMapper createNetworkMapper() {
		return new NetworkMapper();
	}*/
	
	/**
	 * Factory method to create StaffSectionMapper.
	 */
	public static StaffSectionMapper createStaffSectionMapper() {
		return new StaffSectionMapper();
	}
	
	/**
	 * Factory method to create StaffSchoolMapper.
	 */
	public static StaffSchoolMapper createStaffSchoolMapper() {
		return new StaffSchoolMapper();
	}
	/* School Mapper is refactored for SchoolForce, since Schools are always Accounts with a record type of school, not from School__c object*/
	public class SchoolMapper {
		public Account generate(HoldingObj__c holder) {
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Account');
			Account school = new Account();
			//EE 12/20 removed US3513
			//school.RecordTypeId =  rtMap.get('School');
				school.Reference_Id__c = holder.School_Dbn__c;
				school.Name = holder.School_Dbn__c;
				school.Holding_Source__c = holder.Id; 
				school.Is_Active__c = true;
			return school;
		}
	}

	
	public class StudentMapper {
		public Contact generate(HoldingObj__c holder){
			Contact contact = new Contact(); 
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Contact');
			contact.RecordTypeId =  rtMap.get('Student');
			if (holder.Admission_Date__c!=null) contact.Entry_Date__c = holder.Admission_Date__c;
			if (holder.Disability_Flag__c!=null) contact.Disability_Flag__c = holder.Disability_Flag__c;
			if (holder.DOB__c!=null)  contact.Birthdate = holder.DOB__c;
			if (holder.ELL__c!=null)  contact.ELL__c = CT_ImportUtils.isTrue(holder.ELL__c);
			if (holder.First_Name__c!=null)  contact.FirstName = holder.First_Name__c;
			if (holder.Ethnic_Cde__c!=null)  contact.Ethnicity__c = holder.Ethnic_Cde__c;
			if (holder.Last_Name__c!=null)  contact.LastName = holder.Last_Name__c;
			if (holder.Lep_Flag__c!=null)  contact.Lep_Flag__c = holder.Lep_Flag__c; 
			contact.AccountId = CT_core_SoqlUtils.getDummyOrganization().Id;
			if (holder.Sex__c!=null) contact.Gender__c = holder.Sex__c;
			if (holder.Student_Id__c!=null)  contact.Reference_Id__c = CT_ImportUtils.stripLeadingZeroes(holder.Student_Id__c);
			//contact.Grade__c= CT_ImportUtils.normalizeGrade(holder.Grade_Level__c);
			contact.Holding_Source__c = holder.Id; 
			contact.Active__c = true;
			contact.is_Active__c = true;
			if (holder.Email__c!=null) contact.Email = holder.Email__c; 
			if (holder.Phone__c!=null) contact.Phone = holder.Phone__c;
			if (holder.Address__c!=null) contact.MailingStreet = holder.Address__c;
			if (holder.City__c!=null) contact.MailingCity = holder.City__c;
			if (holder.State__c!=null) contact.MailingState = holder.State__c;
			if (holder.zip__c!=null) contact.MailingPostalCode = holder.zip__c;
			  
			return contact;
		}
	}
	
	public class SectionMapper {
		public Section__c generate(HoldingObj__c holder, Time_Element__c year) {
			Section__c section = new Section__c();
			section.RecordTypeId = CT_core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Published');
				//section.Reference_Id__c = CT_ImportUtils.createClassSectionKey(holder); \
				 section.Reference_Id__c = CT_ImportUtils.createClassSectionKey(holder);
				section.School__r = new Account(Reference_Id__c=holder.School_Dbn__c);
				section.Name = holder.Class_Id__c;
				section.Is_Section__c = true;
				section.Holding_Source__c = holder.Id;
				section.isNeedActivate__c = true;//Active__c = true; //Use Active__c homework/gradebook/etc need this
				section.all_grades__c = CT_ImportUtils.normalizeGrade(holder.Grade_Level__c); //changed grade_level to all_grades
				section.Reporting_period__c = holder.Reporting_period_Id__c;
		   		if(holder.Reporting_Period_Id__c!=null) section.time__c = CT_ImportUtils.getYearTe(holder.Reporting_period_Id__c).parent_time_element__r.parent_time_element__c;
		   		else if(year!=null) section.time__c = year.id;
		   		else section.time__c = null;
				section.Daily_Attendance__c = holder.Daily_Attendance__c;
				section.Record_Attendance__c=holder.Record_Attendance__c; 
				//PU: US1743- Period is populated via Section/RP trigger or manually
				//section.Period__c = holder.Period__c;		 	
				system.debug(LoggingLevel.info, 'Section: '+section);			
			return section;			
		}
		
		public Section__c generateForStudent(HoldingObj__c holder, Time_Element__c year) {
			Section__c section = new Section__c();
				//section.RecordTypeId = core_SoqlUtils.getRecordTypesBySobject('Section__c').get('Published');
				section.Reference_Id__c = CT_ImportUtils.createClassSectionKey(holder);
				section.School__r = new Account(Reference_Id__c=holder.School_Dbn__c);
				section.Name = holder.Class_Id__c;
				//section.Is_Section__c = true;
				section.Holding_Source__c = holder.Id;
				section.isNeedActivate__c = true;//Active__c = true; //Use Active__c homework/gradebook/etc need this
				//section.all_grades__c = CT_ImportUtils.normalizeGrade(holder.Grade_Level__c); //changed grade_level to all_grades
				section.Reporting_period__c = holder.Reporting_period_Id__c;
				if(holder.Reporting_Period_Id__c!=null) section.time__c = CT_ImportUtils.getYearTe(holder.Reporting_period_Id__c).parent_time_element__r.parent_time_element__c;
		   		else if(year!=null) section.time__c = year.id;
		   		else section.time__c = null;
				//PU: US1743- Period is populated via Section/RP trigger or manually
				//section.Period__c = holder.Period__c;			
				system.debug(LoggingLevel.info, 'Section: '+section);			
			return section;			
		}
		
		public HoldingObj__c generate (Scheduled_Section__c schedSection, boolean bGroupBased){
			HoldingObj__c ho= new HoldingObj__c();
			system.debug('schedSection: '+schedSection);
			system.debug(schedSection.reporting_period__r.parent_time_element__r.parent_time_element__r.Name__c);
			ho.School_Dbn__c = schedSection.account__r.reference_Id__c;
			ho.Course_Name__c = schedSection.course_name__c;
			ho.Room__c = schedSection.Room__r.Name;
			
			if (bGroupBased) {
				ho.School_Year__c = schedSection.reporting_period__r.parent_time_element__r.parent_time_element__r.Name__c; 
				ho.Class_Id__c = 	   schedSection.schedule_group_Name__c+' - '+schedSection.course_name__c;
				ho.Class_Name__c = 	   schedSection.schedule_group_Name__c;
				ho.Grade_Level__c = schedSection.Grade_Levels__c; // changed grade_level to grade_levels
				ho.Record_Attendance__c	= schedSection.Record_Attendance__c;
				ho.Daily_Attendance__c = schedSection.Daily_Attendance__c;
				ho.No_Meeting__c =schedSection.No_Meeting__c;
				system.debug('schedSection~~~~'+schedSection);
				ho.Reporting_Period_Id__c =schedSection.reporting_period__c;
			}
			else {
				ho.School_Year__c = schedSection.section__r.time__r.Name__c;
				ho.Class_Id__c = 	   schedSection.section__r.Name;
				ho.Class_Name__c = 	 schedSection.section__r.Name;
				ho.Grade_Level__c = schedSection.section__r.all_grades__c; //changed grade_level to all_grades
				ho.Record_Attendance__c	= schedSection.section__r.Record_Attendance__c;
				ho.Daily_Attendance__c = schedSection.section__r.Daily_Attendance__c;
				ho.No_Meeting__c =schedSection.section__r.No_Meeting__c;
				//ho.Period__c = schedSection.period_key__c;
				ho.Reporting_Period_Id__c = schedSection.Section_ReportingPeriod__r.Time__c;
			}
			if (schedSection.staff__r.reference_Id__c.contains('_')) ho.Staff_Id__c	 = schedSection.staff__r.reference_Id__c.split('_')[0];
			ho.First_Name__c = schedSection.staff__r.First_Name_Staff__c;
			ho.Last_Name__c = schedSection.staff__r.Staff_Last_Name__c;
			ho.staff_code__c = schedSection.staff__r.Individual__r.Staff_Code__c;
			ho.username__c = schedSection.staff__r.Individual__r.User_Name__c;
			ho.Email__c = schedSection.staff__r.Individual__r.Email;
			ho.Phone__c = schedSection.staff__r.Individual__r.Phone;
			ho.Address__c =  schedSection.staff__r.Individual__r.MailingStreet;
			ho.City__c = schedSection.staff__r.Individual__r.MailingCity;
			ho.state__c = schedSection.staff__r.Individual__r.MailingState;
			ho.zip__c = schedSection.staff__r.Individual__r.MailingPostalCode;
			ho.sex__c = schedSection.staff__r.Individual__r.Gender__c;	
			//refKey  = cSetup.setup.School__c + '-' + gavw.currentGroup.Id + '-'+ courseId + '-' + reptPeriod+ '-'+schedTempId;
			
			ho.reference_Id__c =   schedSection.reference_id__c;
			
			//ho.Reference_Id__c = schedSection.account__r.id+'_'+ho.School_Dbn__c+'_'+ho.Staff_Id__c+'_'+	ho.Class_Id__c; //Unique key for Staff - Section
			ho.Type__c = 'Staff';
			return ho;
		}
		
		
				
	}
	
	public class StaffMapper {
		public Contact generate(HoldingObj__c holder) {
			Contact contact = new Contact();
			Map<String, Id> rtMap = CT_core_SoqlUtils.getRecordTypesBySobject('Contact');
			contact.RecordTypeId =  rtMap.get('Staff');
			contact.Reference_Id__c = CT_ImportUtils.stripLeadingZeroes(holder.Staff_ID__c);
			contact.Id__c = CT_ImportUtils.stripLeadingZeroes(holder.Staff_ID__c); //Keep both in sync
			contact.FirstName = holder.First_Name__c;
			contact.LastName = holder.Last_Name__c;
			contact.Staff_Code__c = holder.Staff_Code__c; 
			contact.User_Name__c = holder.Username__c;
			contact.Is_Active__c = true;
			contact.Holding_Source__c = holder.Id;
			contact.AccountId=CT_core_SoqlUtils.getDummyOrganization().Id;
			contact.Email = holder.Email__c;
			contact.Phone = holder.Phone__c;
			contact.MailingStreet = holder.Address__c;
			contact.MailingCity = holder.City__c;
			contact.MailingState = holder.State__c;
			contact.MailingPostalCode = holder.zip__c;
			contact.Gender__c = holder.Sex__c;
			return contact;
		}
	}
	
	
	
	public class StaffSectionMapper {
		public Staff_Section__c generate(HoldingObj__c holder) {
			Staff_Section__c staffSection = new Staff_Section__c();
				staffSection.Reference_Id__c = CT_ImportUtils.createStaffSectionKey(holder);
				staffSection.Staff__r = new Staff__c(Reference_Id__c=CT_ImportUtils.createStaffSchoolKey(holder));
				staffSection.Is_Active__c = true;
			staffSection.Holding_Source__c = holder.Id;
				String classKey = CT_ImportUtils.createClassSectionKey(holder);
				if (classKey != null) {
					staffSection.Section__r = new Section__c(Reference_Id__c=classKey);
				}
			return staffSection;
		}
		
		
	} 
	
	public class StaffSchoolMapper {
		public Staff__c generate(HoldingObj__c holder) {
			Staff__c staffSchool = new Staff__c();	
			staffSchool.Reference_Id__c = CT_ImportUtils.createStaffSchoolKey(holder);
			staffSchool.Organization__r = new Account(Reference_Id__c=holder.School_Dbn__c);
			staffSchool.Individual__r = new Contact (Reference_Id__c=holder.Staff_Id__c);
			staffSchool.First_Name_Staff__c=holder.First_Name__c;
			staffSchool.Staff_Last_Name__c=holder.Last_Name__c;
			staffSchool.Active__c = true; 
			staffSchool.Address_1__c = holder.Address__c;
			staffSchool.City__c = holder.City__c;
			staffSchool.State__c = holder.State__c;
			staffSchool.Zip_Code__c = holder.Zip__c;
			staffSchool.Personal_Phone__c = holder.Phone__c;
			staffSchool.ID__c = holder.Staff_Id__c;
			staffSchool.Email__c = holder.email__c;
			staffSchool.Holding_Source__c = holder.Id;
			
			
			return staffSchool;
		}
	}
	
	public class StudentSchoolGradeMapper {
		public Student__c generate(HoldingObj__c holder, boolean isSummerSchool) {
		Student__c student = new Student__c();
			student.Reference_Id__c = CT_ImportUtils.createStudentSchoolYearKey(holder, isSummerSchool);
			If (holder.Student_Id__c!=null) {
				student.Student_Id__c = holder.Student_Id__c;
			}
			student.Individual__r = new Contact(Reference_Id__c=CT_ImportUtils.stripLeadingZeroes(holder.Student_Id__c));
			student.School__r = new Account(Reference_Id__c=holder.School_Dbn__c);
			If (holder.Admission_Date__c!=null) student.Entry_Date__c = holder.Admission_Date__c;
			If (holder.Disability_Flag__c!=null) student.Disability_Flag__c = holder.Disability_Flag__c;
			If (holder.DOB__c!=null) student.Date_of_Birth__c = holder.DOB__c;
			If (holder.ELL__c!=null) student.ELL__c = CT_ImportUtils.isTrue(holder.ELL__c);
			If (holder.First_Name__c!=null) student.Student_First_Name__c = holder.First_Name__c;
			If (holder.Last_Name__c!=null) student.Student_Last_Name__c = holder.Last_Name__c;
			If (holder.Ethnic_Cde__c!=null) student.Ethnicity__c = holder.Ethnic_Cde__c;
			If (holder.First_Name__c!=null&&holder.Last_Name__c!=null) student.Name = holder.First_Name__c + ' ' + holder.Last_Name__c;
			If (holder.Lep_Flag__c!=null) student.Lep_Flag__c = holder.Lep_Flag__c; 
			If (holder.Sex__c!=null) student.Gender__c = holder.Sex__c;
			If (holder.Grade_Level__c!=null) student.Grade__c= CT_ImportUtils.normalizeGrade(holder.Grade_Level__c);
			student.Holding_Source__c = holder.Id;
			student.isNeedActivate__c = true;//Active__c = true;
			return student;
		}
		
		
		public HoldingObj__c generate(Student__c student, Scheduled_Section__c ss) {
		HoldingObj__c holder = new HoldingObj__c();
			holder.School_Year__c = ss.reporting_period__r.parent_time_element__r.parent_time_element__r.Name__c;
			holder.School_Dbn__c = ss.account__r.reference_Id__c;
			holder.Course_Name__c = ss.course_name__c;
			holder.Type__c = 'Student';
			holder.Admission_Date__c=student.Entry_Date__c;
			holder.Disability_Flag__c=student.Disability_Flag__c ;
			holder.DOB__c=student.Date_of_Birth__c ;
				holder.ELL__c=String.valueOf(student.Ell__c);
				holder.First_Name__c=student.Student_First_Name__c;
				holder.Last_Name__c =student.Student_Last_Name__c;
			holder.Ethnic_Cde__c=student.Ethnicity__c;
				holder.Lep_Flag__c= student.Lep_Flag__c;
				holder.Sex__c=student.Gender__c;
				holder.Student_Id__c=student.Student_Id__c;
				holder.Class_Id__c= ss.schedule_group_Name__c+' - '+ss.course_name__c;
				holder.Class_Name__c=ss.schedule_group_Name__c;
				holder.Grade_Level__c=CT_ImportUtils.normalizeGrade(student.Grade__c);
				holder.Address__c=student.Address__c;
			holder.City__c=student.City__c;
			holder.State__c=student.State__c;
			holder.Zip__c=student.Zip_Code__c;
			holder.Phone__c=student.Mobile_Phone__c;
			holder.Reporting_Period_Id__c = ss.reporting_period__c;
			holder.Reference_Id__c = holder.School_Year__c+'_'+holder.School_Dbn__c+'_'+holder.Student_Id__c+'_'+holder.Class_Id__c; //Unique key for Staff - Section
			return holder;			

		}
		
		
		
	}
	
	
	
}