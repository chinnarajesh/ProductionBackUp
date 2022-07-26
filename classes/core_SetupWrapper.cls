public class core_SetupWrapper {

public boolean 	bHasSetup {get;set;}
public Setup__c 	setup {get;set;}
public Account	school {get;set;}
public List <Time_Element__c> 		reportingPeriodList {get;set;}
public List <Schedule_Template__c> setupScheduleTemplateList {get;set;}
public List <cTime> 		cRPeriodList {get;set;}
public Map <Id, List <Schedule_Template__c>> rpScheduleTemplateMap;
public string selectedTab {get;set;}
public List <Section__c> 	scheduleGroupList {get;set;}

public core_SetupWrapper(){
	
}

public core_SetupWrapper(Setup__c s, string tab){
	bHasSetup = true;
	this.rpScheduleTemplateMap = new Map <Id, List <Schedule_Template__c>>();
	this.cRPeriodList = new List <cTime>();
	this.selectedTab = tab;
	this.setup = s;
	if (setup.term__c!=null) reportingPeriodList = core_SoqlUtils.getTimeElementsByTerm(setup.term__c, true);
	Set <Id> rpIds = new Set <Id>();
	if (reportingPeriodList!=null){
		for (Time_Element__c te: reportingPeriodList){
			rpIds.add(te.id);
		}
		this.setupScheduleTemplateList = scheduler_SoqlUtils.retreiveScheduleTemplates(this.setup, rpIds);
	}
	this.school = core_SoqlUtils.getSchoolMap(new Set<Id>{setup.school__c}).values();
	
	//Start of US1254 changes
	if (setup.Group_Based__c){
		refreshScheduleGroups();
	}
		//End of US1254 changes
	
	if (setupScheduleTemplateList!=null){
		for (Schedule_Template__c st: setupScheduleTemplateList){
			if (rpScheduleTemplateMap.get(st.reporting_period__c) !=null){
				rpScheduleTemplateMap.get(st.reporting_period__c).add(st);
			}
			else {
				rpScheduleTemplateMap.put(st.reporting_period__c, new List <Schedule_Template__c>{st});
			}
		}
	
		for (Time_Element__c te: reportingPeriodList){
			cTime newCTime = new cTime(te, setup.id, rpScheduleTemplateMap.get(te.id));
			cRPeriodList.add(newCTime);
		}
	}
}
	//Start of US1254 changes
public void refreshScheduleGroups(){
	this.scheduleGroupList = new List <Section__c>();
		for (Section__c sect:  [select id, grade_level__c, name, All_Grades__c, Description__c, school__c, name_spanish__c  from Section__c 
											where RecordType.DeveloperName = 'Schedule_Group' 
											and school__c=	:setup.school__c
											and time__c 	= :setup.year__c]){
		     	this.scheduleGroupList.add(sect);
		}
}
	//End of US1254 changes


    public pageReference newScheduleTemplate(){
    	pageReference pr = new PageReference('/apex/core_ScheduleTemplate?setupid='+setup.id+'&new=1');
    	pr.setRedirect(true);
    	return pr;
    }
 
 public class cTime{
	public Time_Element__c rPeriod {get;set;}
	public string				schedLink {get;set;}
	public string				schedIcon {get;set;}
	public List <Schedule_Template__c> scheduleTemplateList {get;set;}
	public cTime(Time_Element__c te, Id setupId, List <Schedule_Template__c> stList){
		this.rPeriod =te;
		this.schedIcon =  '/img/func_icons/util/pencil12.gif';
		this.schedLink='/apex/Scheduler_Grid?setupId='+setupId+'&id='+te.Id;
		this.scheduleTemplateList = stList;
		if (this.scheduleTemplateList == null) this.scheduleTemplateList = new List <Schedule_Template__c>();
	}
}
    
    

}