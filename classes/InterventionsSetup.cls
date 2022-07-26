public with sharing class InterventionsSetup {
	public String iaPrefix;
	public List<SelectOption> schools	{get;set;}
	public String selectedSchool		{get;set;}
	
	public List<SelectOption> years		{get;set;}
	public String selectedYear			{get;set;}
	
	public String getiaPrefix(){
		return Indicator_Area__c.SObjectType.getDescribe().getKeyPrefix();
	}
	
	public InterventionsSetup(){
		List<Account> schoolList = [select id, name from Account where recordType.name = 'School' order by Name];
		List<Time_Element__c> yearsList = [SELECT Name__c, Id FROM Time_Element__c WHERE Picklist_Value__r.Name = 'Year' ORDER BY Date_Start_Date__c DESC];
		schools = new List<SelectOption>();
		years = new List<SelectOption>();
		if(schoolList.size()>0 && yearsList.size()>0){
			for(Account a: schoolList){
				schools.add(new SelectOption(a.id,a.Name));
			}
			for(Time_Element__c te: yearsList){
				years.add(new SelectOption(te.id,te.Name__c));
			}
		}
	}
	
	public PageReference goToStaffStudentLoad(){
		boolean bError = false;
		if(selectedSchool==null || selectedSchool==''){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'Please select a school to set up.'));
			bError = true;
		}
		if(selectedYear==null || selectedYear==''){
			ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'Please select a year for which the setup will be valid.'));
			bError = true;
		}
		if(!bError){
			List<Setup__c> setupList = [SELECT id FROM Setup__c WHERE School__c=:selectedSchool AND Year__c=:selectedYear];
			Setup__c schoolSetup;
			if(setupList.size()==0){
				schoolSetup = new Setup__c(School__c=selectedSchool, Year__c=selectedYear);
				try{
					DMLManager.insertAsUser(new Setup__c[]{schoolSetup});
				} catch(DMLManager.CRUDException e){
					CyUtil.errorMessage('User lacks permissions to create setup records.');
				} catch(DMLManager.FLSException e){
					CyUtil.errorMessage('User lacks permissions to key fields on Setup.');
				} catch(System.DMLException e){
					CyUtil.errorMessage('Unexpected exception while creating setup.');
				}
			} else if(setupList.size()==1){
				schoolSetup = setupList[0];
			} else{
				//DE3540
				//more than 1 setup, throw error
				String schoolName='';
				String yearName='';
				for(SelectOption so: schools){
					if(so.getValue()==selectedSchool) schoolName = so.getLabel();
				}
				for(SelectOption so: years){
					if(so.getValue()==selectedYear) yearName = so.getLabel();
				}
				ApexPages.addMessage(new apexpages.message(apexpages.severity.ERROR,'There are multiple setup objects for '+schoolName+' for the year '+yearName+'.  You may only have 1 setup record.  Please go to the Setup Object to delete any unwanted setups and try again.'));
				return null;
			}
			PageReference pr = Page.SchoolSetup_Staff;
			pr.getParameters().put('setupId',schoolSetup.id);
			pr.setRedirect(true);
			return pr;
		}
		else{
			return null;
		}
	}
}