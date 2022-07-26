@isTest
private class Test_SchoolSetup_Gradebook {
	private static void setupData(){
		TestDataSetupUtil_v2.setupCoreData(5);
		TestDataSetupUtil_v2.gradeScaleCat = TestDataSetupUtil_v2.getGradeScaleCatalogs(1)[0];
		TestDataSetupUtil_v2.activeSetup.Grade_Scale_Catalog__c = TestDataSetupUtil_v2.gradeScaleCat.id;
		update TestDataSetupUtil_v2.activeSetup;

		PageReference p = Page.SchoolSetup_Gradebook;
		p.getParameters().put('setupId', TestDataSetupUtil_v2.activeSetup.id);
		Test.setCurrentPage(p);
	}

	@isTest static void test_Constructor() {
		setupData();

		Test.startTest();
			SchoolSetup_Gradebook controller = new SchoolSetup_Gradebook();
			System.assertNotEquals(null, controller.cSetup.setup);
			System.assertNotEquals(null, controller.stateTracker);
			System.assertEquals(false, controller.displayCatalogSelection);
			System.assertNotEquals(null, controller.calculationTypeOptions);
			System.assertNotEquals(null, controller.assignmentTypes);
			controller.finalize();
			controller.prev();
		Test.stopTest();
	}
	
	@isTest static void test_setupSave() {
		setupData();

		Test.startTest();
			SchoolSetup_Gradebook controller = new SchoolSetup_Gradebook();
			System.assertEquals(false, controller.cSetup.setup.Published__c);
			controller.schoolType = 'Hybrid';
			controller.selectedRecord = TestDataSetupUtil_v2.gradeScaleCat.id;
			controller.saveOptions();
			System.assertEquals(TestDataSetupUtil_v2.gradeScaleCat.id, controller.cSetup.setup.Grade_Scale_Catalog__c);
			System.assertEquals(true, [select Standards_Based_Grading__c from Setup__c where ID = : TestDataSetupUtil_v2.activeSetup.id].Standards_Based_Grading__c);
		Test.stopTest();
	}

	@isTest static void test_FinalizeGradebookType(){
		setupData();

		Test.startTest();
			SchoolSetup_Gradebook controller = new SchoolSetup_Gradebook();
			controller.schoolType = 'Hybrid';
			controller.finalizeGradebookType();
			System.assertEquals(true, controller.stateTracker.Gradebook_Type_Finalized__c);
		Test.stopTest();
	}

	@isTest static void test_GS_select(){
		setupData();
		List<Grade_Scale_Catalog__c> cats = TestDataSetupUtil_v2.getGradeScaleCatalogs(2); //make two more for this test

		Test.startTest();
			SchoolSetup_Gradebook controller = new SchoolSetup_Gradebook();
			controller.selectedRecord = cats[1].id;
			controller.deleteGSCatalog();
			System.assertEquals(0, [select id from Grade_Scale_Catalog__c where ID =: cats[1].id].size());

			controller.newGSCatalog();
			System.assertEquals(null, controller.selectedCatalog.id);

			controller.selectedRecord = cats[0].id;
			controller.editGSCatalog();
			controller.selectedCatalog.Name = 'Test Catalog';
			controller.saveCatalog();
			System.assertEquals('Test Catalog', [select Name from Grade_Scale_Catalog__c where ID =: controller.selectedCatalog.id].Name);

			controller.viewCatalog();
			System.assertEquals(false, controller.displayCatalogSelection);
			System.assertNotEquals(null, controller.selectedCatalogWrapper);

			controller.showGSCSelect();

		Test.stopTest();
	}

	@isTest static void test_GSC_modify(){
		setupData();
		TestDataSetupUtil_v2.createScalesNormalizations(); //why doesn't this return the list?
		List<Grade_Scale_Catalog_Scale__c> gscsList = new List<Grade_Scale_Catalog_Scale__c>();
		for(PickList_Value__c pv:[select id from Picklist_Value__c where RecordTypeID =: core_SoqlUtils.getRecordTypesBySobject('Picklist_Value__c').get('Grade_Scale')]){
			gscsList.add(new Grade_Scale_Catalog_Scale__c(Picklist_Value__c = pv.id, Grade_Scale_Catalog__c = TestDataSetupUtil_v2.activeSetup.Grade_Scale_Catalog__c));
		}
		insert gscsList;

		Test.startTest();
			SchoolSetup_Gradebook controller = new SchoolSetup_Gradebook();
			System.assertEquals(TestDataSetupUtil_v2.gradeScaleCat.id, controller.selectedCatalogWrapper.catalog.id);
			
			controller.selectedRecord = controller.selectedCatalogWrapper.catalogElementList[0].Grade_Scale.id;
			controller.editGradeScale();
			System.assertNotEquals(null, controller.selectedGrade_Scale);
			Integer startingNormalizations = controller.rangeNormalizations.size();
			controller.addNormalization();
			System.assertEquals(startingNormalizations+1, controller.rangeNormalizations.size());
			controller.rangeNormalizations[0].startVal=100;
			controller.rangeNormalizations[0].representation= 'A+';
			controller.rangeNormalizations[0].GPA=4.0;
			controller.saveGradeScale();

			controller.editGradeScale();
			controller.selectedRecord = String.valueOf(controller.rangeNormalizations.size()-1);
			controller.removeNormalization();
			System.assertEquals(startingNormalizations, controller.rangeNormalizations.size());
			controller.saveGradeScale();
			
			controller.newGradeScale();
			System.assertEquals(null, controller.selectedGrade_Scale.id);
			controller.selectedGrade_Scale.Name = 'Test';
			controller.saveGradeScale();

			controller.selectedRecord = controller.selectedCatalogWrapper.catalogElementList[0].Grade_Scale.id;
			controller.cloneGradeScale();
			controller.saveGradeScale();
			//basically assert the name is the the same as the cloned one + 'Copy of '
			System.assertEquals('Copy of '+ controller.selectedCatalogWrapper.catalogElementList[0].gscs.Picklist_Value__r.Name, controller.selectedGrade_Scale.Name);

			controller.cancelScaleEdit();

			controller.selectedCatalogWrapper.catalogElementList[0].useRecord = true;
			controller.removeScale();
			System.assertEquals(1, controller.wrappedGrade_Scales.size());

			controller.wrappedGrade_Scales[0].useRecord = true;
			controller.addScale();
			System.assertEquals(0, controller.wrappedGrade_Scales.size());
		Test.stopTest();
	}

	@isTest static void Test_AssignmentTypes(){
		setupData();

		Test.startTest();
			SchoolSetup_Gradebook controller = new SchoolSetup_Gradebook();

			controller.newAssignmentType();
			controller.assignmentTypeToEdit.Name = 'Test Type';
			controller.saveAssignmentType();

			controller.selectedRecord = controller.assignmentTypeToEdit.id;
			controller.editAssignmentType();
			controller.deleteAssignmentType();
		Test.stopTest();
	}
	
}