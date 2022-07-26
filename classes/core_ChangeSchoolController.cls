public class core_ChangeSchoolController {
	public List<SelectOption> schoolListChoices    {get;set;}
	public String selectedSchoolID                 {get;set;}
	public User loggedInUser                       {get;set;}

	public core_ChangeSchoolController(){
		loggedInUser = [select id, School__c from User where id =: UserInfo.getUserId()];
		if(String.isNotBlank(loggedInUser.School__c)){
			selectedSchoolID = loggedInUser.School__c;
		}
		schoolListChoices = new List<SelectOption>();
		Contact con = core_SoqlUtils.getLoggedInContact();
		if(con==null){
			schoolListChoices.add(new SelectOption('none', '-None-'));
		} else {
			for(Staff__c s:core_SoqlUtils.getContactStaffList(con.id)){
				if(s.Organization__c!=null){
					schoolListChoices.add(new SelectOption(s.organization__c, s.Organization__r.Name));
				}
			}
		}
	}
	
	public void change(){
		try{
			if(String.isBlank(loggedInUser.School__c)){
				loggedInUser.School__c = schoolListChoices[0].getValue();
				update loggedInUser;
			}else{
				loggedInUser.School__c = selectedSchoolID;
				update loggedInUser;
			}
		}catch(Exception e){
			Global_Error__c ge = Error_Handling.handleError('', 'Other', 'error updating user', e);
			insert ge;
		}
	}
}