global with sharing class Points_StudentLedger {
	public Student__c student						{get;set;}
	public String 	  stuId 						{get;set;}
	public List<Points__c> 	  pointsTransactions 	{get;set;}
	//global Points__c redeemedPoints						{get;set;}
	public String fromDateString					{get;set;}
	public String toDateString						{get;set;}
	public Decimal availableBal						{get;set;}
	public List<Selectoption>		sections		{get;set;}
	public String		selectedSection				{get;set;}
	public List<Selectoption>		categories		{get;set;}
	public String		selectedCategory			{get;set;}
	public String staffId							{get;set;}
	public Boolean isAdmin							{get;set;}
	public Boolean isManagedPackage					{get;set;}
	public Boolean showHeader						{get;set;}
	public List<PointsWrapper> pointsLedger				{get;set;}
	private Map<Id, List <Section__c>> staffSections;
	private Contact staffContact;
	private List<Staff__c> staff;
	private Set<String> sectionIds;
	private Map<Id, List <Section__c>> staffSectionsMap;
	
	private String profileId; 
		
	public Points_StudentLedger(){
		isManagedPackage = Schema.SObjectType.Points__c.getName().replace('__c', '').contains('__');
		showHeader = true;
		//redeemedPoints = new Points__c();
		categories = new List<Selectoption>	();
		profileId = Points_SoqlUtils.getPointsAdminProfile();
		if(profileId != null && profileId != ''){
			if(userinfo.getProfileId() == profileId){
				isAdmin = true;
			}
			else
				isAdmin = false;
		}
		else{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The points settings for this org has not been setup.'));
		}
		
		try{
			if(ApexPages.currentPage().getParameters().get('showHeader')!= null){
				showHeader = Boolean.valueOf(ApexPages.currentPage().getParameters().get('showHeader'));
			}
			if(ApexPages.currentPage().getParameters().get('ID')!= null){
				stuId = ApexPages.currentPage().getParameters().get('ID');
				getStudent();
				
				staffContact = core_SoqlUtils.getLoggedInContact();	
				if(staffContact == null){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no Contact associated with this User. Please contact your System administrator.'));
				}
				else{
					staff = core_SoqlUtils.getStaffForContactBySchool(staffContact.Id,student.School__c); System.debug('----------STAFF---------'+staff);
					if(staff == null || staff.size() == 0){
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The staff user does not have access to Student Points Data. Please contact your System administrator.'));
					}
					else{
						Set<Id> staffIds = new Set<Id>();
						for(Staff__c s : staff){
							staffIds.add(s.Id);
						}
						staffId = staff[0].Id;
						staffSectionsMap = core_SoqlUtils.getSectionsbyStaffMap(staffIds);
						if(staffSectionsMap == null && !isAdmin){
							ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You will not be able to enter points for this student because you are not associated to any sections.'));
						}
						else if(staffSectionsMap != null){
							sectionIds = core_SoqlUtils.sectionIds;
						}
						fromDateString = (System.today()).format();
						toDateString = (System.today()).format();
						if(sectionIds != null)
							sections = Points_SoqlUtils.getSectionOptions(sectionIds,stuId);
						else{
							sections = new List<SelectOption>();
							sections.add(new Selectoption('--None--','--None--'));
						}
						categories.add(new Selectoption('--None--','--None--'));
						for(Picklist_Value__c p: Points_SoqlUtils.getCatsBySchool(student.Setup__c,student.Grade__c)){
							categories.add(new Selectoption(p.Id,p.Name));
						}
						System.debug('------------fromDateString------------'+fromDateString);
						getPoints();
					}
				}
			}
			else{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Student Id is blank. Please contact your system administrator.'));
			}
			
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed loading page. Please contact your system administrator.'));
		}
		
	}
	
	public Pagereference refreshPoints(){
		if(!validateDates()){
			getPoints();
			getStudent();
		}
		return null;
	}
	public Boolean validateDates(){
		Boolean flag = false;
		Date fromDate =  Date.newInstance(Integer.valueof(fromDateString.split('/')[2]),Integer.valueof(fromDateString.split('/')[0]),Integer.valueof(fromDateString.split('/')[1]));
		Date toDate =Date.newInstance(Integer.valueof(toDateString.split('/')[2]),Integer.valueof(toDateString.split('/')[0]),Integer.valueof(toDateString.split('/')[1]));
		
		if(fromDate > toDate){
			flag = true;
			Apexpages.addMessage(new apexpages.message(apexpages.severity.Error, 'Start Date cannot be later than End date.'));
		}
		return flag;
	}
	public void getPoints(){
		//Integer year = Integer.valueOf(fromDateString.split('/')[2]) ;
	//	System.debug('FROM$$$'+year);
	//	Integer month =
		string sd = ApexPages.currentPage().getParameters().get('sd');
		string ed = ApexPages.currentPage().getParameters().get('ed');
		if(sd != null){
			fromDateString = sd;
		} 
		if(ed != null){
			toDateString = ed;
		}
		Date fromDate =  Date.newInstance(Integer.valueof(fromDateString.split('/')[2]),Integer.valueof(fromDateString.split('/')[0]),Integer.valueof(fromDateString.split('/')[1]));
		Date toDate =Date.newInstance(Integer.valueof(toDateString.split('/')[2]),Integer.valueof(toDateString.split('/')[0]),Integer.valueof(toDateString.split('/')[1]));
		pointsTransactions = new List<Points__c>();
		pointsLedger = new List<PointsWrapper>();
		System.debug('FROM$$$'+fromDate+'TO::'+toDate);
		string printSize = ApexPages.currentPage().getParameters().get('printsize');
		if(printSize == null){
			pointsTransactions = Points_SOQLUtils.getStudentLedgerPoints(stuId, fromDate,toDate);   
		} else { 
			try{
				pointsTransactions = Points_SOQLUtils.getStudentLedgerPoints(stuId, fromDate,toDate, Integer.valueOf(printSize));
			} catch(Exception e){
				Apexpages.addMessage(new apexpages.message(apexpages.severity.Error, 'The number of records to print is invalid.'));
			}
		}
		
		if(pointsTransactions.size() > 1000){
			pointsTransactions.remove(1000);
			Apexpages.addMessage(new apexpages.message(apexpages.severity.info, ' There are more than 1000 records in the selected date range,please select a  smaller date range to view points.'));
		}
			
		if(pointsTransactions != null){
			availableBal = Points_SOQLUtils.getCurrentBalance(fromDate, toDate, student.Id, sectionIds);
			pointsLedger = getPointsLedgerView(pointsTransactions,availableBal);
		}
		//return null;
	}
	
	public Pagereference getStudent(){
		student = core_SoqlUtils.getStudentById(stuId)[0];
		return null;
	}
	
	public Pagereference deletePoints(){
		String pId;
		if(Apexpages.currentPage().getParameters().get('pId')!=null || Apexpages.currentPage().getParameters().get('pId')!='')
					pId  	=	Apexpages.currentPage().getParameters().get('pId');
		delete [SELECT Id FROM POints__c WHERE Id = : pId];
		return null;
	}
	
	@RemoteAction
     global static string[] submitPoints(String stuId,String points, String cat,String section,String comments,String staff,String pdate, String isRedeem,String isAdmin,String pId) {
    	String[] errorMessages = new String[]{};
    	errorMessages = Points_StudentLedger.validateData(points, cat,section,pdate,isRedeem,isAdmin,pId); 
    	
    	if(errorMessages.isEmpty()){
	    	 try{
	    	 	System.debug('Points$$$$'+points);
	    	 	Points__c upsertPoints = new Points__c();
	    	 	if(pId != '' && pId != null)
	    	 	 upsertPoints = [SELECT Student__c,Points__c,Comments__c,Points_Date__c,Reference_Id__c, Is_Redeem__c,Staff__c,Student_Section__c FROM Points__c WHERE Id =: pId];
	    	 	 if(upsertPoints.Student__c == null)
	    	 	 	upsertPoints.Student__c = stuId;
	    	 	if(points != '' && points!=null)
	    	 		upsertPoints.Points__c = Integer.valueOf(points);
	    	 //	if(comments != '' && comments!=null)
	    	 		upsertPoints.Comments__c = comments;
	    	 	System.debug('----------isRedeem--------'+isRedeem);
	    	 	
	    	 	if(Boolean.valueOf(isRedeem)){
	    	 		if(Integer.valueOf(points) > 0)
	    	 		  upsertPoints.Points__c = -Integer.valueOf(points);
	    	 		if(pdate == null || pdate == '')
	    	 			pdate = System.today().format();
	    	 		upsertPoints.Is_Redeem__c = true;
	    	 		
	    	 		System.debug('----------pdate2--------'+pdate);
	    	 		upsertPoints.Points_Date__c = Date.newInstance(Integer.valueOf(pdate.split('/')[2]), Integer.valueOf(pdate.split('/')[0]), Integer.valueOf(pdate.split('/')[1]));
	    	 		upsertPoints.Reference_Id__c = stuId+'_'+upsertPoints.Points_Date__c.format();
	    	 	}
	    	 	else{
	    	 		upsertPoints.Points_Date__c = Date.newInstance(Integer.valueOf(pdate.split('/')[2]), Integer.valueOf(pdate.split('/')[0]), Integer.valueOf(pdate.split('/')[1]));
	    	 		if(cat != '' && cat != null && cat != '--None--')
	    	 		upsertPoints.Category__c = cat;
	    	 		if(staff != '')
	    	 		upsertPoints.Staff__c	= staff;
	    	 		System.debug('----Section-----------::'+section+isAdmin);
	    	 		if((Boolean.valueOf(isAdmin)) && (section == '--None--')){
	    	 			upsertPoints.Reference_Id__c = stuId+'_'+cat+'_'+upsertPoints.Points_Date__c.format();
	    	 		}
	    	 		else{
	    	 			upsertPoints.Student_Section__c = section;
	    	 			upsertPoints.Reference_Id__c  = stuId+'_'+section+'_'+cat+'_'+upsertPoints.Points_Date__c.format();
	    	 		}	
	    	 	
	    	 	}
	    	    System.debug(upsertPoints+'Upsert Points$$$$$');
	    	    if(upsertPoints.Id == null)
	    	 		upsert upsertPoints Reference_Id__c; 
	    	 	else
	    	 		upsert upsertPoints;
	    	 		
	    	 		return null;	 
	     }
	    	 catch (Exception e) {
	    	 	return null;
	    	 	
	        }
    	}
         else 
         return errorMessages;
    	 //return retList;
    }
    
    global static String[]  validateData(String points, String cat,String section,String pdate, String isRedeem,String isAdmin,String pId){
    	String[] messages = new String[]{};
    	if(points == '' || points == null)
    		messages.add('Please enter a valid number for Points.');
    	if((pId!='' && pId!=null && (pdate == null || pdate == '')) ||  ((pId=='' || pId==null) && (!Boolean.valueOf(isRedeem)) &&(pdate == null || pdate == '')))
    		messages.add('Please enter a valid Date.');
    	if(pdate != '' && pdate != null){
    		Date pointsDate = Date.newInstance(Integer.valueOf(pdate.split('/')[2]), Integer.valueOf(pdate.split('/')[0]), Integer.valueOf(pdate.split('/')[1]));
    		if(pointsdate > system.today()){
    		messages.add('Points date cannot be a future date,please enter a valid Date.');
    		}
    	}	
    	if(!Boolean.valueOf(isRedeem)&&( cat == '' || cat== null || cat== '--None--'))
    		messages.add('Please select a Catagory.');
    	if(!Boolean.valueOf(isAdmin)&&!Boolean.valueOf(isRedeem)&&( section == '' || section== null || section== '--None--'))
    		messages.add('Please select a Section.');	
    	
    	System.debug('Messages'+messages.isEmpty());			
    	if (!messages.isEmpty()){
    		return messages;
    	} else {
    		return messages;
    	}
    }
    
	public List<PointsWrapper> getPointsLedgerView(List<Points__c> pts,Decimal totalBal){
			List<PointsWrapper> pointsWrapperList = new List<PointsWrapper> ();
			Decimal prevBal = 0;
			Decimal runningBal = totalBal;
			for(Integer i = 0; i < pts.size(); i++){
				runningBal = runningBal - prevBal;
				pointsWrapperList.add(new PointsWrapper(pts[i],runningBal));
				prevBal = pts[i].Points__c;
			}
		return 	pointsWrapperList;
	}

	
	public with sharing class PointsWrapper {
		public Points__c points							{get;set;}
		public Decimal   runningBal					{get;set;}
		
		

		public PointsWrapper(Points__c  pts,Decimal rb){
			points = pts;
			runningBal = rb;
		}
	}
}