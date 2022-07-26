public with sharing class GroupAgendaViewWrapper {
	
	public Id currentGroup										{get; set;}
	public core_SetupWrapper  cSetup											{get;set;}
	public Schedule_Template__c schedTemp										{get; set;}
	public  List<Scheduled_Section__c> schedSectionsList						{get;set;}	
	public List<scheduleSectionRowWrapper>	ssecRowWrappList					{get;set;}
	public Map<String,Scheduled_Section__c> scheduledSectionMap 				{get;set;}
//	public Map<String,Scheduled_Section__c> dateToscheduledSectionMap 		{get;set;}														
	public List<timeWrapper> strtTime												{get;set;}
	public Set<Id> schedGrpIds													{get;set;}
	public List <SelectOption> roomOptionList									{get;set;}
	public List <SelectOption> courseOptionList 								{get;set;}
	public List <SelectOption> staffOptionList									{get;set;}
	public List<String> staffOptions											{get;set;}
	public String selectedRoom 													{get;set;}
	public String selectedCourse 												{get;set;}
	public String selectedStaff 												{get;set;}
	public String selectedRoom2 													{get;set;}
	public String selectedCourse2 												{get;set;}
	public String selectedStaff2 												{get;set;}
	public String selectedDailyAtt 												{get;set;}
	public String selectedRecordtt 												{get;set;}
	public List<Scheduled_Section__c> schedSectionsDNMList							{get;set;}
	public Map<Id,List<Scheduled_Section__c>> groupIdToSchedSecs;
	public List<Section__c> schedGrpsList							{get;set;}
	public Map<Id,List<scheduleSectionRowWrapper>> groupIdToSchedSecWrapperList;
	public Map<Id,Section__c> idToScheduleGroupMap;
	public List<Scheduled_Section__c> alldayClasses										{get;set;}
	public List<scheduleSectionRowWrapper> regularClasses 						  {get;set;}
	public integer iHeight	{get;set;}
	
	public with sharing class scheduleSectionRowWrapper {
			
		public String startTime  					{get; set;}
		public String endTime						{get;set;}
		public String displayStartTime			{get;set;}
		public String displayEndTime				{Get;set;}		
		public Scheduled_Section__c schedsec 		{get; set;}
		public Boolean isHeader						{get;set;}
		public String color							{get;set;}
		public String textColor					{get;set;}	
		public integer iPosition					{get;set;}
		public integer iHeight						{get;set;}
		public integer iTop							{get;set;}
		public integer iMaxHeight				{get;set;}
		
					
					
		public scheduleSectionRowWrapper(String st,String et, Scheduled_Section__c ss,Boolean h,String c, Schedule_Template__c template){
				    	this.startTime = st;
				    	this.endTime = et;
				    	this.schedsec = ss;
				    	this.isHeader = h; 
				    	this.color = c;
				    	system.debug('thiscolor~~~'+this.color);
				    	if (this.color!=null&&this.color!='LemonChiffon') this.textColor = core_ColoringUtils.getTextColor(this.color);
				    	if (ss.start_time__c!=null) this.displayStartTime = ss.start_time__c.format('hh:mm a');
				    	if (ss.end_time__c!=null) this.displayEndTime= ss.end_time__c.format('hh:mm a');
				    	if (ss.start_time__c!=null && ss.end_Time__c!=null) this.iHeight =( core_TimeUtils.getMinutes(ss.End_Time__c)-core_TimeUtils.getMinutes(ss.Start_Time__c))*2;
				    	if (ss.start_time__c!=null && ss.end_Time__c!=null) this.iTop = (core_TimeUtils.getMinutes(ss.Start_Time__c)-core_TimeUtils.getMinutes(DateTime.newInstance(ss.Start_Time__c.year(),ss.Start_Time__c.month(), ss.Start_Time__c.day(),  template.Start_Time__c.hour(),template.Start_Time__c.minute(),0) ))*2;
				    	if (this.iTop==0) this.iTop=1;
		}  
	}
	
	public class timeWrapper{
		
		public string sTime {get;set;}
		public integer iTop {get;set;}
		
		public timeWrapper(string inputTime){
			this.sTime = inputTime;
		}
	}
	
	
	public GroupAgendaViewWrapper(Id setUp,Id schedTempId){
				
				roomOptionList = new List<SelectOption>();
				courseOptionList = new List<SelectOption>();
				staffOptionList = new List<SelectOption>();
				
				cSetup= new core_SetupWrapper(core_SoqlUtils.getSetupById(setUp),'Agenda');
				this.schedTemp = scheduler_SoqlUtils.getScheduleTemplateById(schedTempId)[0]; 
				iHeight = (core_TimeUtils.getMinutes(this.schedTemp.End_Time__c)-core_TimeUtils.getMinutes(this.schedTemp.Start_Time__c))*2;
				roomOptionList = scheduler_SoqlUtils.getRoomOptionsBySchool(cSetup.setup.School__c);
				courseOptionList = scheduler_SoqlUtils.getCourseOptionsByCCatId(cSetup.setUp.course_catalog__c);
				staffOptionList = scheduler_SoqlUtils.getStaffOptionsBySchool(cSetup.setup.School__c);
				getscheduleGroups();
				currentGroup = schedGrpsList[0].Id;
				getStartTime(); 
				refreshClasses();
	}
	
	public void getscheduleGroups(){
		schedGrpsList = new List<Section__c>();
			schedGrpsList = scheduler_SoqlUtils.getGroupsBySetupId(csetup.setup.Id);
	}

	public List<Scheduled_Section__c> getscheduledSections(){
		schedGrpIds = new Set<Id>();
		DateTime ssStartTime;
		DateTime ssEndTime;
			schedSectionsList = new List<Scheduled_Section__c>();
			scheduledSectionMap = new Map<String,Scheduled_Section__c>();
			schedSectionsList = scheduler_SoqlUtils.getScheduledSectionsByTempId(schedTemp.Id);
			 System.debug('$$$$$$$$schedSectionsList$$$$$$$$$$$$$$$'+schedSectionsList);
			
			groupIdToSchedSecs = new Map<Id,List<Scheduled_Section__c>>();
		
			for(Scheduled_Section__c ss : schedSectionsList){
			   if(groupIdToSchedSecs.containskey(ss.Schedule_Group_Section__c)){
					groupIdToSchedSecs.get(ss.Schedule_Group_Section__c).add(ss);
				}
				else{
					groupIdToSchedSecs.put(ss.Schedule_Group_Section__c,new List<Scheduled_Section__c>{ss});
				}	
			}	

			
		return schedSectionsList;
	}
	
	
	
	
	
	public List<TimeWrapper> getStartTime(){
		strtTime = new List<TimeWrapper>(); 
		Datetime actualDayStartTime = core_TimeUtils.processTimeText(schedTemp.Start_Time_Text__c);
		Datetime actualDayEndTime = core_TimeUtils.processTimeText(schedTemp.End_Time_Text__c);
		Datetime dayStartTime = core_TimeUtils.getRoundedTextTime(schedTemp.Start_Time_Text__c); 
		Datetime dayEndTime = core_TimeUtils.getRoundedTextTime(schedTemp.End_Time_Text__c); 
		Integer 	startMinutes = core_TimeUtils.getMinutes(actualDayStartTime);
		Integer k = 0;
		for(;actualDayStartTime < actualDayEndTime; ){
				timeWrapper tw ;
				if(core_TimeUtils.returnTimeMinute(actualDayStartTime.format('hh:mm a')) == 0){
					tw = new TimeWrapper(actualDayStartTime.format('h a'));
				}
				else {
					tw = new TimeWrapper (actualDayStartTime.format('h:mm a'));
				}
				tw.iTop = (core_TimeUtils.getMinutes(actualDayStartTime)-startMinutes)*2;
				k++;
				actualDayStartTime = actualDayStartTime.addminutes(15);
				strtTime.add(tw);
			}

	     return strtTime;
	}
	
	public void refreshClasses(){
			getscheduledSections();
			getSchedSectionsByCurrGroupId();
	}
	
	public void getSchedSectionsByCurrGroupId(){
			alldayClasses = new List<Scheduled_Section__c>();
			regularClasses = new List<scheduleSectionRowWrapper>();
			List <Scheduled_Section__c> groupsScheduledSections;
			groupsScheduledSections = new List <Scheduled_Section__c>();
			if(groupIdToSchedSecs.containskey(currentGroup)) groupsScheduledSections= groupIdToSchedSecs.get(currentGroup);
				for (Scheduled_Section__c tempSS: groupsScheduledSections){
					if (tempSS.daily_attendance__c==false&&tempSS.no_meeting__c ==false){
						scheduleSectionRowWrapper newClassWrapper = new scheduleSectionRowWrapper(tempSS.start_Time__c.format('hh:mm a'),tempSS.end_Time__c.format('hh:mm a'),tempSS,true,tempSS.color__c, schedTemp);
						if (!regularClasses.isEmpty()) {
							scheduleSectionRowWrapper prevClassWrapper = regularClasses[regularClasses.size()-1];
							prevClassWrapper.iMaxHeight = newClassWrapper.iTop- prevClassWrapper.iTop ;
							system.debug(prevClassWrapper);
							regularClasses[regularClasses.size()-1]=prevClassWrapper;
						}
						regularClasses.add(newClassWrapper);
					}
					else alldayClasses.add(tempSS);
				}
	}	
}