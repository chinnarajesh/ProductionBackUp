public with sharing class Points_RedeemWrapper {
	public Points__c redeemPoint	{get;set;}
	public string studentName                   {get;set;}
    public id studentID                         {get;set;}
    public boolean isActive                     {get;set;}
    private id ssID;
    public id schoolId;
    
    public Points_RedeemWrapper(){
        redeemPoint = new Points__c();
        studentName = '';
        isActive = true;
    }
    
    public Points_RedeemWrapper(Student_Section__c studentSection){
    	ssID = studentSection.id;
    	studentName = studentSection.Student__r.Name;
		studentID = studentSection.Student__c;
		schoolId = studentSection.Student__r.School__c;
    	if(!studentSection.Points_Transactions__r.isEmpty())
			redeemPoint = studentSection.Points_Transactions__r[0];
		else
			fillEmptyPoints();
			
		
		isActive = true;
	}
	
	public Points_RedeemWrapper(Student__c student){
		studentName = student.Name;
		studentID = student.id;
		schoolId = student.School__c;
		if(!student.Points_Transactions__r.isEmpty())
			redeemPoint = student.Points_Transactions__r[0];
		else
			fillEmptyPoints();
			
		
		isActive = true;
	}
    
    private void fillEmptyPoints(){			
		redeemPoint = new Points__c(Student__c = studentID
                            ,Reference_Id__c=studentID
                            ,is_Redeem__c = true);
		if(ssID != null){
			redeemPoint.Student_Section__c = ssID;
			redeemPoint.Reference_Id__c += '_'+ssID;
		}
    }
}