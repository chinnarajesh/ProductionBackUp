public with sharing class AttendanceWrapper {
	//Declare variables
	public string 	rowStyle		{get;set;}
	public ID studID {get; set;}
	public String FirstName {get; set;}
	public String LastName {get; set;}
	public Attendance__c atn {get; set;}
	public String statusVal			{get;set;}
	public String studName {get; set;}
	public Time_Element__c te {get;set;} //Time element is used in this instance to pull in arrival/departure times from page, translate them to start time/end time and mapped to attendance arrival/departure date times
	public Integer tardyCnt {get;set;}
	public Integer absentCnt {get;set;}

	//Constructor if an attendance record is existing for the student
	public AttendanceWrapper(ID sId, String fname, String lname, Attendance__c atten, Time_Element__c inputTe){
		this.studID = sId;
		this.FirstName = fname;
		this.LastName = lname;
		this.tardyCnt = 0;
		this.absentCnt = 0;
		this.atn = atten;
		this.te = new Time_Element__c(Parent_Time_Element__r=inputTe);
		this.studName = fname + ' ' + lname;

	}
	//Constructor if a new attendance record needs to be created for the student
	public AttendanceWrapper(ID sId, String fname, String lname, Time_Element__c inputTe){

		this.studID = sId;
		this.FirstName = fname;
		this.LastName = lname;
		this.tardyCnt = 0;
		this.absentCnt = 0;
		this.atn = new Attendance__c(Student__c = sId);
		this.te = new Time_Element__c(Parent_Time_Element__r=inputTe);
		this.studName = fname + ' ' + lname;

	}
	//No argument constructor used to hold temporary values while sorting alphabetically
	public AttendanceWrapper(){
		this.atn = new Attendance__c();
		this.te = new Time_Element__c();
	}

	public List<AttendanceWrapper> sortDisplayData(List<AttendanceWrapper> pList){
		// utility lists
		List<String> names = new List<String>(); // list of student names
		List<AttendanceWrapper> retList = new List<AttendanceWrapper>(); // sorted list ready to be returned
		Map <String, AttendanceWrapper> studentWrapperMap = new Map<String, AttendanceWrapper>();


		// obtain the student's name
		for(AttendanceWrapper h : pList){
			string key = h.LastName+h.FirstName+h.studID;
			names.add(key); // add the student's name to the list for sorting purposes
			studentWrapperMap.put(key, h);
		}

		names.sort(); // sort the list of names

		// prepare the output data list to match the order of sorted name list
		for(String s : names) {
			retList.add(studentWrapperMap.get(s));

		}
		return retList;
	}
}