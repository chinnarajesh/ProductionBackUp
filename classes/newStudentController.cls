public with sharing class newStudentController {
	public Student__c stu {get;set;}
	private ApexPages.StandardController con;
	public newStudentController(ApexPages.StandardController controller) {
		con = controller;
   		stu = new Student__c();
    }
    public List<String> addInfo {
		get {
			if(addInfo == null) {
				addInfo = new List<String>();
				addInfo.add('Strengths__c');
				addInfo.add('Hobbies__c');
				addInfo.add('Additional_Information__c');
			}
			return addInfo;
		}
		private set;
	}
	public List<String> sysInfo {
		get {
			if(sysInfo == null) {
				sysInfo = new List<String>();
				sysInfo.add('Individual__c');
				sysInfo.add('Active__c');
				sysInfo.add('Student_Id__c');
				sysInfo.add('Archived__c');
			}
			return sysInfo;
		}
		private set;
	}
	
	public Pagereference saveStudent() {
		stu.Name = stu.Student_First_Name__c +' '+stu.Student_Last_Name__c;
		
		try {
			DMLManager.insertAsUser(new List<Student__c>{stu});
			return new Pagereference('/'+stu.Id);
		} catch(DMLManager.CRUDException e){
			CyUtil.errorMessage('User lacks permissions to create student records.');
		} catch(DMLManager.FLSException e){
			CyUtil.errorMessage('User lacks permissions to key fields on the student record.');
		} catch(System.DMLException e){
			CyUtil.errorMessage(e.getMessage());
		}
		return null;
	}
	
	public Pagereference saveAndNewStudent() {
		saveStudent();

		if(!ApexPages.hasMessages()){
			Schema.DescribeSObjectResult describeResult = con.getRecord().getSObjectType().getDescribe();
            Pagereference pr = new PageReference('/' + describeResult.getKeyPrefix() + '/e');
            pr.setRedirect(true);
            return pr;
        } else {
        	return null;
        }
	}
}