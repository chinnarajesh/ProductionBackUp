@isTest
public class CT_Test_core_LoadCSVData_v2 {

	public static void setupData() {
		TestDataSetupUtil_v2.setupCoreData(2);
		TestDataSetupUtil_v2.setupStaffData(2);
		TestDataSetupUtil_v2.setUpStudentData(2);
	}

	public static testMethod void baseCase_Initialization() {
		setupData();

		Test.startTest();
			CT_core_LoadCSVData_v2 cLSD = new CT_core_LoadCSVData_v2();
			Test.setCurrentPageReference(new PageReference('Page.CT_core_LoadCSVData_v2'));				
		Test.stopTest();
	}

	public static testMethod void baseCase_FileSelection() {
		setupData();

		Test.startTest();
			CT_core_LoadCSVData_v2 cLSD = new CT_core_LoadCSVData_v2();
			Test.setCurrentPageReference(new PageReference('Page.CT_core_LoadCSVData_v2'));
			cLSD.downloadTemplate();
		Test.stopTest();
	}

	public static testMethod void baseCase_InsertData() {
		setupData();

		Test.startTest();
			CT_core_LoadCSVData_v2 cLSD = new CT_core_LoadCSVData_v2();
			Test.setCurrentPageReference(new PageReference('Page.CT_core_LoadCSVData_v2'));

			//build a sample file?
			List<Schema.FieldSetMember> fsmList = cLSD.getFields();
			List<String> passHeader = new List<String>();
			List<List<String>> passData = new List<List<String>>();
			List<String> tempRow = new List<String>();
			for(Schema.FieldSetMember fsm : fsmList) {
				passHeader.add(fsm.getLabel());
				tempRow.add('SomeString');
			}
			passData.add(tempRow);

			CT_core_LoadCSVData_v2.CSVDataHandler pdh = new CT_core_LoadCSVData_v2.CSVDataHandler();
			pdh.csvData = passData;
			pdh.totalRows = 100;
			pdh.selectOptionString = cLSD.selectedTemplate;
			pdh.header = passHeader;
			CT_core_LoadCsvData_v2.handleData(pdh);
		Test.stopTest();		
	}

	public static testMethod void baseCase_InsertDataWithSetup() {
		setupData();
		PageReference p = Page.CT_core_LoadCSVData_v2;
		p.getParameters().put('setupid',TestDataSetupUtil_v2.activeSetup.ID);
		Test.setCurrentPageReference(p);

		Test.startTest();
			CT_core_LoadCSVData_v2 cLSD = new CT_core_LoadCSVData_v2();
			system.assertNotEquals(null, cLSD.cSetup.setup.ID);
			
			//build a sample file?
			String templateName;
			if(cLSD.bManagedPackage){
				templateName = 'SchoolForce__Behavior_Types_Picklist_Value_Template';
			} else {
				templateName = 'Behavior_Types_Picklist_Value_Template';
			}

			cLSD.selectedTemplate = 'Picklist_Value__c - '+templateName;
			cLSD.setSelectedTemplateParameters();
			system.assertEquals(Picklist_Value__c.sObjectType,cLSD.selectedTemplateObject);
			String fieldSetName = (cLSD.selectedTemplateFieldSet.split('__',0).size()==2)?cLSD.selectedTemplateFieldSet.split('__',0)[1]:cLSD.selectedTemplateFieldSet;
			system.assertEquals(Picklist_Value__c.sObjectType.getDescribe().fieldSets.getMap().get(templateName).getName(),fieldSetName);
			system.assertEquals('Picklist_Value__c - '+templateName,cLSD.selectedTemplate);

			List<Schema.FieldSetMember> fsmList = cLSD.getFields();
			List<String> passHeader = new List<String>();
			List<List<String>> passData = new List<List<String>>();
			List<String> tempRow = new List<String>();
			for(Schema.FieldSetMember fsm : fsmList) {
				passHeader.add(fsm.getLabel());
			}
			String rtID = CT_core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Behavior_Type');
			passData.add(new List<String>{
				'Test', //Display Value
				'Test', //Behavior Cat
				'Test', //Behavior Incident Level
				'10', //corasponding value
				'false', //involves weapon
				'Behavior Type', //Type
				rtID //record type ID
			});

			CT_core_LoadCSVData_v2.CSVDataHandler pdh = new CT_core_LoadCSVData_v2.CSVDataHandler();
			pdh.csvData = passData;
			pdh.totalRows = 100;
			pdh.selectOptionString = ((cLSD.bManagedPackage)?'SchoolForce__':'')+cLSD.selectedTemplate;
			pdh.header = passHeader;
			pdh.setupId = TestDataSetupUtil_v2.activeSetup.ID;
			CT_core_LoadCSVData_v2.handleData(pdh);
		Test.stopTest();		
	}

	public static testMethod void Test_TemplateDownload(){
		setupData();
		Test.setCurrentPageReference(Page.CT_core_LoadCsvData_v2);

		Test.startTest();
			CT_core_LoadCSVData_v2 controller = new CT_core_LoadCSVData_v2();

			controller.selectedTemplate = controller.templateList[0].getValue();
			PageReference returnedRef = controller.downloadTemplate();
			//clear the params here because the getURL later appends them and fails the test
			returnedRef.getParameters().clear();

			system.assertEquals(Page.CT_core_LoadCSVData_dlTemplate.getURL().tolowerCase(),returnedRef.getURL().tolowerCase());
		Test.stopTest();
	}
}