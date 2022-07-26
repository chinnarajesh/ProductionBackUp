public with sharing class CT_ImportUtils {


	public static Time_Element__c yearTe {get;set;}
	
	public static Time_Element__c getYearTe (String ReportingPeriodId){ 
		if (yearTe==null){
			yearTe = [select parent_time_element__r.parent_time_element__c from Time_Element__c where id =:ReportingPeriodId];
		}
		return yearTe;
	} 
	
	public static String normalizeGrade(String grade) {
		if ((grade != null) && 
				(grade.equalsIgnoreCase('0k') || 
						grade.equalsIgnoreCase('k') || 
						grade.equalsIgnoreCase('0') || 
						grade.equalsIgnoreCase('kindergarden'))) {
    		return 'K'; //Updated per Schoolforce we want K not 0
    	}
		return stripLeadingZeroes(grade);
	}
	
	public static String createClassSectionKey(HoldingObj__c holder) {
		if (isNull(holder.Class_Id__c) || isNull(holder.School_Dbn__c) || isNull(holder.School_Year__c)) {
			return null;
		}
		String key = holder.Class_Id__c + holder.School_Dbn__c + holder.School_Year__c;
		return key.toLowerCase();
		//return holder.Class_Id__c + holder.School_Dbn__c + holder.School_Year__c;
	}

	public static String createStudentSectionKey(HoldingObj__c holder) {
		String key = (String.isNotBlank(holder.Student_Id__c)? holder.Student_Id__c: '') +'_'+ 
			(String.isNotBlank(holder.Class_Id__c)? holder.Class_Id__c: '') + '_' + 
			(String.isNotBlank(holder.School_Dbn__c)? holder.School_Dbn__c: '') + '_' + 
			(String.isNotBlank(holder.School_Year__c)? holder.School_Year__c: '');
		return key.toLowerCase();
		//return holder.Student_Id__c +'_'+ holder.Class_Id__c +'_'+ holder.School_Dbn__c +'_'+ holder.School_Year__c;
	}

	public static String createStudentSchoolGradeKey(HoldingObj__c holder) {
		String key = (String.isNotBlank(holder.Student_Id__c)? holder.Student_Id__c: '') + '_' + 
			(String.isNotBlank(holder.School_Dbn__c)? holder.School_Dbn__c: '')	+ '_' + 
			CT_ImportUtils.normalizeGrade(holder.Grade_Level__c);
		return key.toLowerCase();
		//return holder.Student_Id__c +'_' + holder.School_Dbn__c+'_'+CT_ImportUtils.normalizeGrade(holder.Grade_Level__c);
	}
	
	public static String createStudentSchoolYearKey(HoldingObj__c holder, boolean isSummerSchool) {
		if (isNull(holder.Student_Id__c) || isNull(holder.School_Dbn__c) || isNull(holder.School_Year__c) ) {
			return null;
		}
		String key = holder.Student_Id__c +'_'+holder.School_Dbn__c+'_'+ holder.School_Year__c +((isSummerSchool)?'SS':'');
		return key.toLowerCase();
		//return holder.Student_Id__c +'_' +holder.School_Year__c +((isSummerSchool)?'SS':'');
	}
	
	public static String createStaffSectionKey(HoldingObj__c holder) {
		if (isNull(holder.Staff_Id__c) || isNull(holder.Class_Id__c) || isNull(holder.School_Year__c)) {
			return null;
		}
		return stripLeadingZeroes(holder.Staff_Id__c) +'_' + holder.Class_Id__c+'_'+holder.School_Year__c;
	}
	
	public static String createStaffSchoolKey(HoldingObj__c holder) {
		if (isNull(holder.Staff_Id__c) || isNull(holder.School_Dbn__c) ) {
			return null;
		}
		return stripLeadingZeroes(holder.Staff_Id__c) +'_' + holder.School_Dbn__c ;
	}
	
	public static String createStaffSchoolRoleKey(HoldingObj__c holder) {
		if (isNull(holder.Staff_Id__c) || isNull(holder.School_Dbn__c) || isNull(holder.Staff_Code__c)) {
			return null;
		}
		return stripLeadingZeroes(holder.Staff_Id__c) +'_'  + holder.School_Dbn__c  +'_' + holder.Staff_Code__c;
	}
	
	public static String createRoomKey(HoldingObj__c holder){
		if (isNull(holder.School_Dbn__c) || isNull(holder.Room__c)) {
			return null;
		}
		return holder.School_Dbn__c  +'-' + holder.Room__c;
	}
	public static String createScheduleGroupKey (HoldingObj__c holder){
			if (isNull(holder.Class_Name__c) || isNull(holder.School_Dbn__c) || isNull(holder.School_Year__c)) {
			return null;
		}
		return holder.Class_Name__c + holder.School_Dbn__c + holder.School_Year__c;
	}
	

	
	public static Boolean isNull(String value) {
		return CT_StringUtils.isBlank(value) || (value.equalsIgnoreCase('null'));
	}
	
	public static Boolean isTrue(String value) {
		return (!CT_StringUtils.isBlank(value) &&
				(value.equalsIgnoreCase('y') || value.equalsIgnoreCase('yes') ||
						value.equalsIgnoreCase('1') || value.equalsIgnoreCase('t') ||
						value.equalsIgnoreCase('true')));
	}
	
	public static String stripLeadingZeroes(String value) {
		if (CT_StringUtils.isBlank(value) || !value.startsWith('0') || (value == '0')) {
			return value;
		}
		return stripLeadingZeroes(value.substring(1));
	}
	
	public static String createScheduledSectionKey(String schoolId,String grpId,String courseId,String rpId,String schedTempId) {
		if (CT_StringUtils.isBlank(schoolId) || CT_StringUtils.isBlank(grpId) || CT_StringUtils.isBlank(courseId) || CT_StringUtils.isBlank(rpId) || CT_StringUtils.isBlank(schedTempId)) {
			return null;
		}
		return schoolId+'-'+grpId+'-'+courseId+'-'+rpId+'-'+schedTempId;
	}
	
	public static String createSectionReferenceKey(String schoolId,String grpId,String courseId,String rpId) {
		if (CT_StringUtils.isBlank(schoolId) || CT_StringUtils.isBlank(grpId) || CT_StringUtils.isBlank(courseId) || CT_StringUtils.isBlank(rpId)) {
			return null;
		}
		return schoolId+'-'+grpId+'-'+courseId+'-'+rpId;
	}
	
}