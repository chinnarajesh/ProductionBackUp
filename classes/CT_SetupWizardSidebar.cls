public class CT_SetupWizardSidebar {
	public String cSetupId			{get; set{
		if(value!=null && value!=''){
			cSetupId = value;
			schoolSetup = CT_SetupWizard_Utils.getSetupById(cSetupId);
			stepNo = CT_SetupWizard_Utils.calculateStepLocation(cSetupId);
		}
	}}

	public Setup__c schoolSetup		{get;set;}
	public integer stepNo			{get;set;}
	public integer TERMS			{get{ return CT_SetupWizard_Utils.TERMS; } set;}
	public integer SELECTIONS		{get{ return CT_SetupWizard_Utils.SELECTIONS; } set;}
	public integer TEMPLATES		{get{ return CT_SetupWizard_Utils.TEMPLATES; } set;}
	public integer CALENDAR			{get{ return CT_SetupWizard_Utils.CALENDAR; } set;}
	public integer COURSE_CATALOG	{get{ return CT_SetupWizard_Utils.COURSE_CATALOG; } set;}
	public integer ROOMS			{get{ return CT_SetupWizard_Utils.ROOMS; } set;}
	public integer STAFF			{get{ return CT_SetupWizard_Utils.STAFF; } set;}
	public integer GROUP_CONFIG		{get{ return CT_SetupWizard_Utils.GROUP_CONFIG; } set;}
	public integer SCHEDULE			{get{ return CT_SetupWizard_Utils.SCHEDULE; } set;}
	public integer STUDENT_SECTIONS	{get{ return CT_SetupWizard_Utils.STUDENT_SECTIONS; } set;}
	public integer PUBLISH			{get{ return CT_SetupWizard_Utils.PUBLISH; } set;}
	public integer ACTIVATION		{get{ return CT_SetupWizard_Utils.ACTIVATION; } set;}

	public String currentTermName { get; set; }

	public CT_SetupWizardSidebar() {
		if (ApexPages.currentPage().getParameters().get('setupId') != null && ! String.isBlank(ApexPages.currentPage().getParameters().get('setupId'))) {
			String customSetupId = ApexPages.currentPage().getParameters().get('setupId');

			Setup__c customSetup = CT_SetupWizard_Utils.getSetupById(customSetupId);
			this.currentTermName = customSetup.Term__r.Name__c;
		}
	}

	public PageReference activateSDSSchool(){
		update new Account(Id=schoolSetup.School__c, SDS_School__c = true);
		return CT_SetupWizard_Utils.goToSchoolStep(CT_SetupWizard_Utils.FINISH,true,schoolSetup);
	}
}