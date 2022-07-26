public with sharing class Points_MatrixWrapper {
    public static List<Picklist_Value__c> cats  {get;set;}
    public List<Points__c> points               {get;set;}
    public string studentName                   {get;set;}
    public id studentID                         {get;set;}
    public boolean isActive                     {get;set;}
    private id ssID;
    private List<Points__c> sorterHolder;
    public string SchoolId						{get;set;}
    
    
    public Points_MatrixWrapper(){
        cats = new List<Picklist_Value__c>();
        points = new List<Points__c>();
        studentName = '';
    }
    
    public Points_MatrixWrapper(Student_Section__c studentSection){
		Map<String ,Points__c> pointMap=new Map<String ,Points__c>();
		
		sorterHolder = studentSection.Points_Transactions__r;
		studentName = studentSection.Student__r.Name;
		studentID = studentSection.Student__c;
		ssID = studentSection.id;
		isActive = true;
		points = new List<Points__c>();
		schoolId = studentSection.Student__r.School__c;
		fillEmptyPoints();
	}
	
	public Points_MatrixWrapper(Student__c student){
		Map<String ,Points__c> pointMap=new Map<String ,Points__c>();
		
		sorterHolder = student.Points_Transactions__r;
		studentName = student.Name;
		studentID = student.id;
		isActive = true;
		points = new List<Points__c>();
		schoolID = student.School__c;
		fillEmptyPoints();
	}
    
    private void fillEmptyPoints(){
        Set<Id> pvIDs = new Set<ID>();
        Map<ID, Points__c> catMap = new Map<ID, Points__c>();
        if(cats == null || cats.isEmpty()){
            return;
        }
        if(!sorterHolder.isEmpty()){
        	for(Points__c p:sorterHolder){
        		catMap.put(p.Category__c, p);
        	}
        }
        for(Picklist_Value__c p:cats){
        	if(catMap.containsKey(p.id)){
        		points.add(catMap.get(p.id));
        	} else {
        		//new points are given a temp ref id to aid in locating them on the page
        		points.add(new Points__c(Student__c = studentID,
                            Student_Section__c = ssID,
                            Category__r = p,
                            Category__c = p.id,
                            Reference_Id__c = studentID + '_' + p.id
                        ));
        	}
        }
    }
}