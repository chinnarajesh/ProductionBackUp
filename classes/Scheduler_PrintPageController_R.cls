global with sharing class Scheduler_PrintPageController_R{
	/* Why this class exists
		The print schedule page uses the same controller as the pdf generation page.
		This cuts down on the need to duplicate some of the logic required to do the bulk generation in tandom with the
		single generation which use two different controllers.
		However there is a undocumented standard in salesforce, which is triggered by that setup.
		In  short, when a controller makes a getConentAsPDF call, it uses a page reference. 
		Page references used in getContentAsPDF do not respect the setRedirect(false) call,
		which means the server tries to pass the viewstate rather then call the constructor again. 
		However, because get contentAsPDF runs on it's own "instance", this viewstate cannot be passed,
		making the schedule always generaete as blank.
		To bypass this, we use an extension of the primary controller. 
		This, when listed as an extension on the pdfSchedule page, forces the constructor to run,
		which allows the schedule to generate properly.
	*/
	public Scheduler_PrintPageController_R(scheduler_printPageController controller){}
	//Depricated - cannot remove from package
	@RemoteAction
	global static String emailSched(String a, String b, String c){return null;}
	//Depricated - cannot remove from package
	@RemoteAction
	global static String emailSched_v2(String a, String b, String c, String d){return null;}
}