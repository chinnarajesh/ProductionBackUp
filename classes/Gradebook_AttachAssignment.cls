public with sharing class Gradebook_AttachAssignment {
	
  	public String fileDesc1	{get;set;}
  	public String fileDesc2	{get;set;}
  	public String fileDesc3	{get;set;}
  	public String fileDesc4	{get;set;}
  	public String fileDesc5	{get;set;}
  	
  	public String fileName1	{get;set;}
  	public String fileName2	{get;set;}
  	public String fileName3	{get;set;}
  	public String fileName4	{get;set;}
  	public String fileName5	{get;set;}
  	
  	public String fileSize1	{get;set;}
  	public String fileSize2	{get;set;}
  	public String fileSize3	{get;set;}
  	public String fileSize4	{get;set;}
  	public String fileSize5	{get;set;}
  	
  	public ContentVersion newAssignDoc1	{get;set;}
  	public ContentVersion newAssignDoc2	{get;set;}
  	public ContentVersion newAssignDoc3	{get;set;}
  	public ContentVersion newAssignDoc4	{get;set;}
  	public  ContentVersion newAssignDoc5	{get;set;}
  	
  	public String fileContentType1	{get;set;}
  	public String fileContentType2	{get;set;}
  	public String fileContentType3	{get;set;}
  	public String fileContentType4	{get;set;}
  	public String fileContentType5	{get;set;}
  	
  	//public list<String> fileDesc	{get;set;}
  	//public list<String> fileName	{get;set;}
    public list<String> fileSize	{get;set;}
	public transient  list<ContentVersion> newAssignDoc	{get;set;}
    

    public list<Attachment> attach	{get;set;}
    
  
    public List<String> fileContentType	{get;set;}
	public boolean error;
 	/*public Attachment attach {
    		get {
      		if (attach == null)
        		attach = new Attachment();
      		return attach;
    		}
    		set;
  	}
  	*/
Assignment_Lib__c assign;
ContentWorkspace cs;
boolean bGradebook = false;

	//US3131
	public String fromQuick = ApexPages.currentPage().getParameters().get('fromQuick');

public Gradebook_AttachAssignment (ApexPages.StandardController controller){
	
	//newAssignDoc 	= new List<ContentVersion>{new ContentVersion(),new ContentVersion(),new ContentVersion(),new ContentVersion(),new ContentVersion()};
	attach			= new List<Attachment>();
	
	newAssignDoc1 = new ContentVersion();
	newAssignDoc2 = new ContentVersion();
	newAssignDoc3 = new ContentVersion();
	newAssignDoc4 = new ContentVersion();
	newAssignDoc5 = new ContentVersion();
	
	error = false;
	try {
		if(test.isRunningTest()){//cannot insert workspaces in test classes
			cs = new ContentWorkspace();
			
		}
		else{
			cs = [select id from ContentWorkspace where name ='Assignments'];
		}
	}
	catch (exception e){
      ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'There is a problem with your content configuration. Make sure you have an "Assignments" workspace or Contact your administrator'));
	}
  	if(ApexPages.currentPage().getParameters().get('id')==null){//hardcode the ID for dev
  		 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Attachment ID not found'));
  	}
	assign = (Assignment_Lib__c)controller.getRecord();
	if (ApexPages.currentPage().getParameters().get('fromGradebook') !=null) bGradebook=true;
	assign = [select Id, Name from Assignment_Lib__c where Id = :assign.Id ];
	
}
public pageReference uploadNew(){
	pageReference p = upload();
	pageReference q = new pageReference('/apex/gradebook_attachAssignment?id='+ApexPages.currentPage().getParameters().get('id')+'&fromGradebook=' + bGradebook);
	return q;
}
	public PageReference upload(){
		system.debug('Upload');
		list<contentVersion> toInsert = new List<ContentVersion>();
		list<String> descriptions = new List<String>();
		list<String> names			= new List<String>();
		try{
			if (newAssignDoc1.PathOnClient != null){
				newAssignDoc1.Title = newAssignDoc1.PathOnClient;
				newAssignDoc1.FirstPublishLocationID = cs.id;
				newAssignDoc1.Assignment_Library__c = assign.Id;
				toInsert.add(newAssignDoc1);
				descriptions.add(fileDesc1);
				names.add(newAssignDoc1.PathOnClient);
			}
			if (newAssignDoc2.PathOnClient != null){
				newAssignDoc2.Title = newAssignDoc2.PathOnClient;
				newAssignDoc2.FirstPublishLocationID = cs.id;
				newAssignDoc2.Assignment_Library__c = assign.Id;
				toInsert.add(newAssignDoc2);
				descriptions.add(fileDesc2);
				names.add(newAssignDoc2.PathOnClient);
			}
			if (newAssignDoc3.PathOnClient != null){
				newAssignDoc3.Title = newAssignDoc3.PathOnClient;
				newAssignDoc3.FirstPublishLocationID = cs.id;
				newAssignDoc3.Assignment_Library__c = assign.Id;
				toInsert.add(newAssignDoc3);
				descriptions.add(fileDesc3);
				names.add(newAssignDoc3.PathOnClient);
			}
			if (newAssignDoc4.PathOnClient != null){
				newAssignDoc4.Title = newAssignDoc4.PathOnClient;
				newAssignDoc4.FirstPublishLocationID = cs.id;
				newAssignDoc4.Assignment_Library__c = assign.Id;
				toInsert.add(newAssignDoc4);
				descriptions.add(fileDesc4);
				names.add(newAssignDoc4.PathOnClient);
			}
			if (newAssignDoc5.PathOnClient != null){
				newAssignDoc5.Title = newAssignDoc5.PathOnClient;
				newAssignDoc5.FirstPublishLocationID = cs.id;
				newAssignDoc5.Assignment_Library__c = assign.Id;
				toInsert.add(newAssignDoc5);
				descriptions.add(fileDesc5);
				names.add(newAssignDoc5.PathOnClient);
			}
	
			try {
				if(toInsert.size()>0) insert toInsert;
			}
			catch (exception e){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error on insert: ' + e));
				error=true;
				throw new Error_Handling.schoolForceException('Gradebook_AttachAssignment: Error on content setup: ' + e);
			}
			if (!error){
				integer index2 = 0;
				for(ContentVersion cv : toInsert){
					Attachment a = new Attachment();
					a.ParentId = assign.id;
					a.Body = cv.VersionData;
					a.Description = descriptions[index2];
					a.Name= names[index2];
					attach.add(a);
					index2++;
				}
				try {
					insert attach;
					//Preventing from hitting view state limits is a pain
					for (Attachment att: attach)
					{
						att = null;
						att = new Attachment();
						att.Name = null;
						att.Body = null;
					}
				}
				catch (exception e){
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error on insert: ' + e));
					Global_Error__c ge = Error_Handling.handleError('', 'Gradebook', 'Attach Assignment failure.', e);
					insert ge;
					//throw new Error_Handling.schoolForceException('Gradebook_AttachAssignment: Error on insert - ' + e.getStackTraceString());
					system.debug('Exception: ' + e);
					system.debug('Exception Stack: ' + e.getStackTraceString());
				}finally
				{
					//Preventing from hitting view state limits is a pain
					attach = new List<Attachment>();
					
					newAssignDoc1 = null;
					newAssignDoc2 = null;
					newAssignDoc3 = null;
					newAssignDoc4 = null;
					newAssignDoc5 = null;
					
					newAssignDoc1 = new ContentVersion();
					newAssignDoc2 = new ContentVersion();
					newAssignDoc3 = new ContentVersion();
					newAssignDoc4 = new ContentVersion();
					newAssignDoc5 = new ContentVersion();
					
					toInsert = null;
					toInsert = new List<ContentVersion>();
				}
			}
			//EE 8/21 commented out because it doesn't work
			if (ApexPages.hasMessages()){
				return null;
			}
			else if (fromQuick == 'true') {
				return new PageReference('javascript:window.close()');
			}
			else {
				//EE 7/26 commented out for DE1641
				//AQ 8/31/2012 used the Page.Gradebook_Redirect to correctly return to the right gradebook based on setup.
				//if (!bGradebook){
				//	return new PageReference('/'+ assign.Id);
				//}
				//else {
					return Page.Gradebook_Redirect;
				//}

			}
		}
		catch (exception e){
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error attaching file.  Contact your administrator'));
			Global_Error__c ge = Error_Handling.handleError('', 'Gradebook', 'Attach Assignment failure.', e);
			insert ge;
			return null;
		}
	}
	
	public PageReference cancel(){
		if (fromQuick == 'true') {
			return new PageReference('javascript:window.close()');
		}
		if (!bGradebook){
			return new PageReference('/'+ assign.Id);
		}
		else return Page.Gradebook_Redirect;
	}
}