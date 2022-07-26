public with sharing class core_DateUtils {
	
	public static List<integer> returnWeekDays(string[] weekDays){
		List<Integer> weekDaysList = new List<Integer>();
		for(String w :weekDays){
			if(w.contains('Sun'))
				weekDaysList.add(0);
			else
			if(w.contains('Mon'))
				weekDaysList.add(1);
			else	
			if(w.contains('Tue'))
				weekDaysList.add(2);
			else	
			if(w.contains('Wed'))
				weekDaysList.add(3);
			else	
			if(w.contains('Thur'))
				weekDaysList.add(4);
			else	
			if(w.contains('Fri'))
				weekDaysList.add(5);
			else	
			if(w.contains('Sat'))
				weekDaysList.add(6);
		}
		return weekDaysList;
	}

}