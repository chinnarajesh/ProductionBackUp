public with sharing class CT_ReportingPeriodCalendarWrapper {
		
	public List<WeekWrapper> weekWrapperList							{get; set;}
	public List<DayWrapper> dayWrapperList								{get;set;}
	public List<MonthWrapper> monthWrapperList							{get;set;}
	public List<Time_Element__c> timeList								{get;set;}
	public Map<Id,Schedule_Template__c> rpIdToMasterTemplateMap			{get;set;}
	public String repPeriod												{get;set;}
	public String currentRP													{get;set;}
	public Map<Integer,List<DayWrapper>> dayOfWeekToDayWrapperList 		{get; set;}
	public Map<Id,String> repPeriodIdToName 							{get; set;}

	public List<ScheduleTemplateWrapper> scheduleTempsList				{get; set;}
	List<String> colorCodes												{get;set;}
	Map<String,Schedule_Day__c> dateToScheduleDay							{get;set;}
	public	CT_core_SetupWrapper			cSetup							{get;set;}
	public Map<String,List<FormatMonthsWrapper>> rpIdToFormatWrapperList;
	public Map<String,List<ScheduleTemplateWrapper>> rpIdToScheduleClassesList;
	
	
	
/* ---------------------Wrapper Classes---------------------------------------------------------------------------*/	
		
	public with sharing class DayWrapper {
		
				/* Wrapper class that stores information about the Schedule_day
				*/
				public Schedule_Day__c schedDay  {get;set;}
				public String schedDayId  {get;set;}
				public Date day           {get; set;}
				public String className   {get; set;}
				public String color   	  {get; set;}
				public String textColor	{get;set;}
				public integer dayNum	{get;set;}
				
				
			    public DayWrapper(Schedule_Day__c sd,String sdid,Date d, String style,String co){
			    	this.schedDay = sd;
			    	this.schedDayId = sdid;
			    	this.day = d;
			    	this.className = style;
			    	if (style=='blank') this.color='#D3D3D3';
			    	else if (style=='read') this.color = '#000080';
			    	if (co!=null&&co!='') {
			    		this.color = co;
			    	}
			    	this.textColor = CT_core_ColoringUtils.getTextColor(this.color);
			    	if (d!=null) this.dayNum = d.day();
			    }  
	}
	
	/*Wrapper class that stores List of 7 DayWrapper records for each Week*/
	public with sharing class WeekWrapper {
		
				public Integer dayOfWeek          {get; set;}
				public List<DayWrapper> dayWrapperList  {get; set;}
				
				
			    public WeekWrapper(Integer weekDay, List<DayWrapper> dates){
			    	this.dayOfWeek = weekDay;
			    	this.dayWrapperList = dates;
			    }  
	}
	
	/*Wrapper class that stores List of WeekWrapper records for each month*/
	public with sharing class MonthWrapper {
		
				public Date month          {get; set;}
				public List<WeekWrapper> weeksList  {get; set;}
				
				
				
			    public MonthWrapper(Date m, List<WeekWrapper> weeks){
			    	this.month = m;
			    	this.weeksList = weeks;
			    	
			    }  
	}
	
	/*Wrapper class that stores List of 2 MonthWrapper records*/
	/* This wrapper is used for formatting purposes to display 2 months in each row*/
	public with sharing class FormatMonthsWrapper {
		
				public List<MonthWrapper> monthsList  {get; set;}
				public Integer countMon  {get; set;}
				
				
				
			    public FormatMonthsWrapper(Integer cm, List<MonthWrapper> monsL){
			    	this.countMon = cm;
			    	this.monthsList = monsL;
			    	
			    }  
	}
	
	/* The wrapper class stores Schedule_Template__c information */
	public with sharing class ScheduleTemplateWrapper {
		
				public Schedule_Template__c schedTemp  {get; set;}
				public String color  {get; set;}
				public String startTime  {get; set;}
				public String endTime  {get; set;}
				
				
				
			    public ScheduleTemplateWrapper(Schedule_Template__c st, String c){
			    	this.schedTemp = st;
			    	this.color = c;
			    	if (this.color==null) this.color='white';
			    	if(st.Start_Time__c != null)
			    	startTime = st.Start_Time__c.format('hh:mm a');
			    	if(st.End_Time__c != null)
			    	endTime = st.End_Time__c.format('hh:mm a');
			    	
			    	
			    }  
	}
	
/*------------------------ End Wrapper Classes---------------------------------------------------------------------*/
/*------------------------ Constructor ----------------------------------------------------------------------------*/
public CT_ReportingPeriodCalendarWrapper(Id setUp){
	this.cSetup= new CT_core_SetupWrapper(CT_core_SoqlUtils.getSetupById(setUp),'calendar');
	getReportingPeriods();
	getScheduleTemps();
	getCalendarDaysByRP();
}

/*------------------------ End Constructor ------------------------------------------------------------------------*/

public void getCalendarDaysByRP(){
	rpIdToFormatWrapperList = new Map<String,List<FormatMonthsWrapper>>();
	System.debug('\n\n timeList.size() => ' + timeList.size() + '\n');
	
	for(Time_Element__c te : timeList){
		System.debug('\n\n buildCalendar \n');
		rpIdToFormatWrapperList.put(te.Id,buildCalendar(te.Id));
	}
}
public List<FormatMonthsWrapper> buildCalendar(Id rpId){
//	system.debug('~~~rpId:'+rpId);
		List<FormatMonthsWrapper> 	formatWrapperList = new List<FormatMonthsWrapper>();
		//currentRP = rpId;
		getScheduleDays(rpId);
		Time_Element__c t = CT_core_SoqlUtils.getTimeElementById(rpId);
		Date semStartDate = t.Date_Start_Date__c;
		Date semEndDate = t.End_Date__c;
		
		Set<Integer> availableDays = getAvailableDays(t.Days_of_Week__c);
		
		Integer numberOfMonths = semStartDate.monthsBetween(semEndDate)+ 1;	
		monthWrapperList = new List<monthWrapper>();
		
	    Date monthStartDate;	
	    Date actualStartDate;
		Integer monNum = 0;
		for(Integer i = 0; i < numberOfMonths ; i++){
			weekWrapperList = new List<WeekWrapper>();
			dayWrapperList = new List<DayWrapper>();
			
			if(i == 0){
			monthStartDate = Date.newinstance(semStartDate.year(),semStartDate.month(),1);
			actualStartDate = Date.newinstance(semStartDate.year(),semStartDate.month(),semStartDate.day());
			}
			else{
				monthStartDate = Date.newinstance(semStartDate.year(),semStartDate.addmonths(i).month(),1);
				if (monthStartDate.month()==1){
					semStartDate = semStartDate.addYears(1);
					monthStartDate= monthStartDate.addYears(1);
				}
				actualStartDate = monthStartDate;
			}
			Integer k = 1;
			Integer l = 0;
			Integer m = 1;
			Integer weekNum = 1;
			
			
			Integer daysInMonth = monthStartDate.toStartOfWeek().daysBetween(monthStartDate)+ Date.daysInMonth(monthStartDate.year(), monthStartDate.month());
			for(Integer j = 0 ; j < daysInMonth ; j++){
				
				
				if(monthStartDate.toStartOfWeek().addDays(l) < monthStartDate){
					
							
							dayWrapperList.add(new DayWrapper(new Schedule_Day__c(),'',null,'blank',''));
					l++;
				}
				else{
					if(!availableDays.contains(k) || ((Date.newinstance(monthStartDate.year(),monthStartDate.month(),m)) < actualStartDate) || ((Date.newinstance(monthStartDate.year(),monthStartDate.month(),m)) > semEndDate)){
					
						dayWrapperList.add(new DayWrapper(new Schedule_Day__c(),'',Date.newinstance(monthStartDate.year(),monthStartDate.month(),m),'read',''));
					
					m++;
					}
					
					else{ 
						if(dateToScheduleDay.containsKey(rpId+'-'+Date.newinstance(monthStartDate.year(),monthStartDate.month(),m))){
					
						dayWrapperList.add(new DayWrapper(dateToScheduleDay.get(rpId+'-'+Date.newinstance(monthStartDate.year(),monthStartDate.month(),m)),dateToScheduleDay.get(rpId+'-'+Date.newinstance(monthStartDate.year(),monthStartDate.month(),m)).Schedule_Template__c,Date.newinstance(monthStartDate.year(),monthStartDate.month(),m),'readwrite',dateToScheduleDay.get(rpId+'-'+Date.newinstance(monthStartDate.year(),monthStartDate.month(),m)).Schedule_Template__r.Color__c));
					
						}
						else{
							if(rpIdToMasterTemplateMap.get(rpId) != null)
								dayWrapperList.add(new DayWrapper(new Schedule_Day__c(Schedule_Template__c = rpIdToMasterTemplateMap.get(rpId).Id,Day__c = Date.newinstance(monthStartDate.year(),monthStartDate.month(),m)),rpIdToMasterTemplateMap.get(rpId).Id,Date.newinstance(monthStartDate.year(),monthStartDate.month(),m),'write',rpIdToMasterTemplateMap.get(rpId).Color__c));
						}
					   m++;
					
					}
					
				}
				
				k++;
				if(k == 8){
					k =1;
					weekWrapperList.add(new WeekWrapper(weekNum,dayWrapperList));
					dayWrapperList = new List<DayWrapper>();
					weekNum++;
				}
				
			
			}
				if(dayWrapperList.size() > 0)
				weekWrapperList.add(new WeekWrapper(weekNum,dayWrapperList));
				
			monthWrapperList.add(new MonthWrapper(actualStartDate,weekWrapperList));
		}
		
		List<MonthWrapper> temp = new List<MonthWrapper>();
		Integer monthcount = 1;
		for(MonthWrapper mw: monthWrapperList){
			temp.add(mw);
			 monNum++;
			
			if(monNum == 2){
				formatWrapperList.add(new FormatMonthsWrapper(monthcount,temp));
				monNum = 0;
				temp = new List<MonthWrapper>();
				monthcount++;
			}
		}
			if((math.mod(monNum,2) !=0) &&(temp.size() > 0))
		    formatWrapperList.add(new FormatMonthsWrapper(monthcount,temp));
//		system.debug('formatWrapperList~~~'+formatWRapperList);    
		return formatWrapperList;
		
	}
	
	
	public List<Time_Element__c> getReportingPeriods(){
		List<Time_Element__c> reportingPeriods = new List<Time_Element__c>();
		repPeriodIdToName = new Map<Id,String>();
		timeList = new List<Time_Element__c>();
		timeList = CT_core_SoqlUtils.getTimeElementsByTerm(cSetup.setup.term__c, true);
		for(Time_Element__c t : timeList){
			reportingPeriods.add(t);
			repPeriodIdToName.put(t.Id,t.Name__c);
		}
		return reportingPeriods;
	}
	
	public void getScheduleTemps(){
		rpIdToScheduleClassesList = new Map<String,List<ScheduleTemplateWrapper>>();
		//scheduleTempsList = new List<ScheduleTemplateWrapper>();
		rpIdToMasterTemplateMap = new Map<Id,Schedule_Template__c>();
			for(Schedule_Template__c s :CT_scheduler_SoqlUtils.getScheduleTemplateBySetup(cSetup.setup.Id)){
				if(rpIdToScheduleClassesList.containskey(s.Reporting_Period__c))
					rpIdToScheduleClassesList.get(s.Reporting_Period__c).add(new ScheduleTemplateWrapper(s,s.Color__c));
					
				else
					rpIdToScheduleClassesList.put(s.Reporting_Period__c,new List<ScheduleTemplateWrapper>{new ScheduleTemplateWrapper(s,s.Color__c)});	
				//scheduleTempsList.add(new ScheduleTemplateWrapper(s,s.Color__c)) ;
//				System.debug('-------rpIdToScheduleClassesList---------------'+rpIdToScheduleClassesList);
				if(s.is_Master__c){
				rpIdToMasterTemplateMap.put(s.Reporting_Period__c,s);
				}
			}	
	}
	
	
	public void getScheduleDays(Id rpId){
		
		dateToScheduleDay	= new Map<String,	Schedule_Day__c>();
		for(Schedule_Day__c sd: [SELECT Id,Day__c,Color__c,ReferenceId__c,Schedule_Template__c,Schedule_Template__r.Setup__c,Schedule_Template__r.Color__c
								 FROM Schedule_Day__c
								 WHERE Reporting_Period__c  = : rpId
								 AND Schedule_Template__r.Setup__c = : cSetup.setup.Id
								 order by Day__c]){
		 	dateToScheduleDay.put(rpId+'-'+sd.Day__c, sd);
		}
	}
	
	public Set<Integer> getAvailableDays(String dayString){
		Set<Integer> availableDays = new Set<Integer>();
		//EE 10/16 if days of week not set, default to MTWHF
		if(dayString==null || dayString==''){
			availableDays.add(2);
			availableDays.add(3);
			availableDays.add(4);
			availableDays.add(5);
			availableDays.add(6);
		}
		else{
			if(dayString.contains('M')) availableDays.add(2);
			if(dayString.contains('T')) availableDays.add(3);
			if(dayString.contains('W')) availableDays.add(4);
			if(dayString.contains('H')) availableDays.add(5);
			if(dayString.contains('F')) availableDays.add(6);
			if(dayString.contains('S')) availableDays.add(7);
			if(dayString.contains('U')) availableDays.add(1);
		}
		return availableDays;
	}
}