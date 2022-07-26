public class SetupWizardSidebar {
	public String cSetupId			{get; set{
		if(value!=null && value!=''){
			cSetupId = value;
			schoolSetup = SetupWizard_Utils.getSetupById(cSetupId);
			stepNo = SetupWizard_Utils.calculateStepLocation(cSetupId);
		}
	}}
	public Setup__c schoolSetup		{get;set;}
	public integer stepNo			{get;set;}
	public integer TERMS			{get{ return SetupWizard_Utils.TERMS; } set;}
	public integer SELECTIONS		{get{ return SetupWizard_Utils.SELECTIONS; } set;}
	public integer TEMPLATES		{get{ return SetupWizard_Utils.TEMPLATES; } set;}
	public integer CALENDAR			{get{ return SetupWizard_Utils.CALENDAR; } set;}
	public integer COURSE_CATALOG	{get{ return SetupWizard_Utils.COURSE_CATALOG; } set;}
	public integer ROOMS			{get{ return SetupWizard_Utils.ROOMS; } set;}
	public integer STAFF			{get{ return SetupWizard_Utils.STAFF; } set;}
	public integer GROUP_CONFIG		{get{ return SetupWizard_Utils.GROUP_CONFIG; } set;}
	public integer SCHEDULE			{get{ return SetupWizard_Utils.SCHEDULE; } set;}
	public integer STUDENT_SECTIONS	{get{ return SetupWizard_Utils.STUDENT_SECTIONS; } set;}
	public integer PUBLISH			{get{ return SetupWizard_Utils.PUBLISH; } set;}
	public integer ACTIVATION		{get{ return SetupWizard_Utils.ACTIVATION; } set;}
	
	public SetupWizardSidebar(){
	}
}