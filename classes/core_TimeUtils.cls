public class core_TimeUtils {
	
	public static Time_Element__c staticParentTe;

	public static integer returnTimeMinute(string inputTime){
		string timeOnly = inputTime.split(' ')[0];
		if (timeOnly.toUpperCase().contains('AM')) timeOnly=timeOnly.toUpperCase().replace('AM','');
		if (timeOnly.toUpperCase().contains('PM')) timeOnly=timeOnly.toUpperCase().replace('PM','');
		integer mins = integer.ValueOf(timeOnly.split(':')[1]);
		return mins;
	}
	
	public static integer returnTimeHour(string inputTime){
		string timeOnly = inputTime.split(' ')[0];
		integer hour = integer.ValueOf(timeOnly.split(':')[0]);
		if (inputTime.contains('AM')&&hour==12) hour=0;
		if (inputTime.contains('PM')&&hour!=12) hour+=12;
		return hour;
	}
	
	public static integer getMinutes(DateTime inputDateTime){
		integer endTimeMins = integer.valueOf(inputDateTime.getTime()/(60*1000));
		return endTimeMins;
	}
	
	public static Time_Element__c translateTimeText(Time_Element__c inputTime){
		integer stHour;
		integer stMinutes;
		integer etHour;
		integer etMinutes;
		if (inputTime.StartTime__c!=null&&inputTime.StartTime__c!=''){
			stHour  	=returnTimeHour(inputTime.StartTime__c);
			stMinutes	=returnTimeMinute(inputTime.StartTime__c);
			inputTime.Start_Time__c=DateTime.newInstance(inputTime.Date_Start_Date__c.year(), inputTime.Date_Start_Date__c.month(), inputTime.Date_Start_Date__c.day(),stHour, stMinutes,0);
		}
		if (inputTime.EndTime__c!=null&&inputTime.EndTime__c!=''){
			etHour		=returnTimeHour(inputTime.EndTime__c);
			etMinutes	=returnTimeMinute(inputTime.EndTime__c);
			inputTime.End_Time__c=DateTime.newInstance(inputTime.End_Date__c.year(), inputTime.End_Date__c.month(), inputTime.End_Date__c.day(),etHour, etMinutes,0);
		}
		
		return inputTime;
	}
	
	public static Time_Element__c mapPeriodTime(Time_Element__c inputTime){
		if (staticParentTe==null){
			staticParentTe =core_SoqlUtils.getTimeElementById(inputTime.Parent_Time_Element__c);
		}
		Time_Element__c parentTe = staticParentTe;
		inputTime.Date_Start_Date__c=parentTe.Date_Start_Date__c;
		inputTime.End_Date__c=parentTe.End_Date__c;
		inputTime = translateTimeText(inputTime);
		return inputTime;
	}
	
	public static DateTime processTimeText(String inputTime){
		DateTime d = dateTime.newInstance(system.today().year(), system.today().month(), system.today().day(), returnTimeHour(inputTime), returnTimeMinute(inputTime), 0);
		return d;
	}
	
	public static DateTime getRoundedTextTime(String inputTime){
		DateTime d = dateTime.newInstance(system.today().year(), system.today().month(), system.today().day(), returnTimeHour(inputTime), roundTime(inputTime), 0);
		return d;
	}
	public static Integer roundTime(String t){
		Integer roundedval;
		Integer temp = core_TimeUtils.returnTimeMinute(t);
		if(core_TimeUtils.returnTimeMinute(t) < 8) roundedval = 0;
		else
		if(core_TimeUtils.returnTimeMinute(t) < 16) roundedval = 15;
		else
		if(core_TimeUtils.returnTimeMinute(t) < 24) roundedval = 15;
		else
		if(core_TimeUtils.returnTimeMinute(t) < 32) roundedval = 30;
		else
		if(core_TimeUtils.returnTimeMinute(t) < 40) roundedval = 30;
		else
		if(core_TimeUtils.returnTimeMinute(t) < 48) roundedval = 45;
		else
		if(core_TimeUtils.returnTimeMinute(t) < 53) roundedval = 45;
		else
		roundedval = 60; 
		
		return roundedval;
	}
}