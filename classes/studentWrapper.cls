global class studentWrapper{
	public String studentName	{get; set;}
	public String studentId		{get; set;}
	public String gradeLevel	{get; set;}
	public String indicatorArea {get; set;}
	public String iaIds			{get; set;}
	public Date enrollmentDate	{get; set;}
	public Boolean checked		{get;set;}
	public String sfStudentID	{get;set;}
		
	public studentWrapper(String inputStudentName, String inputStudentId, String inputGradeLevel, String inputIndicatorArea, String inputIndicatorAreaIds) {
		this.studentName = inputStudentName;
		this.studentId = inputStudentId;
		this.gradeLevel = inputGradeLevel;
		this.indicatorArea = inputIndicatorArea;
		this.iaIds = inputIndicatorAreaIds;
		this.checked = false;
	}

	public studentWrapper(Student__c student, String inputIndicatorArea, String inputIndicatorAreaIds){
		this.studentName = student.Student_Last_Name__c + ', '+ student.Student_First_Name__c;
		this.studentID = student.id;
		this.gradeLevel = student.Grade__c;
		this.indicatorArea = inputIndicatorArea;
		this.iaIds = inputIndicatorAreaIds;
		this.sfStudentID = student.Student_ID__c;
		this.checked = false;
	}
}