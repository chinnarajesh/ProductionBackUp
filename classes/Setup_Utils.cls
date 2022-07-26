public without sharing class Setup_Utils {
	public static void deactivateOldSetups(List<Setup__c> newSetups, Map<ID, Setup__c> oldSetupMap){
		Set<ID> schoolIDs = new Set<ID>();
		for(Setup__c setup:newSetups){
			Setup__c oldSetup;
			if(oldSetupMap!= null){
				oldSetup = oldSetupMap.get(setup.ID);
			}

			if((setup.Active__c && oldSetup == null) || (setup.Active__c && setup.Active__c != oldSetup.Active__c)){
				schoolIDs.add(setup.School__c);
			}
		}

		core_TriggerUtils.deactivateSchoolSetups(schoolIds);
	}

	public static void cloneOldSetupConfiguration(List<Setup__c> newSetups){
		List<Setup__c> setupsToCloneData = new List<Setup__c>();
		Set<ID> schoolIDs = new Set<ID>();

		for(Setup__c s:newSetups){
			schoolIDs.add(s.School__c);
		}

		Map<ID, Account> accountMap = new Map<ID, Account>([select id, Is_Active__c, (select id from Setup__r) from Account where ID IN:schoolIDs]);

		for(Setup__c s:newSetups){
			if(accountMap.get(s.School__c).Is_Active__c && accountMap.get(s.School__c).Setup__r.size() > 1){
				setupsToCloneData.add(s);
			}
		}

		if(!setupsToCloneData.isEmpty()){
			Batch_CloneSetupData batch = new Batch_CloneSetupData(setupsToCloneData);
			Database.executeBatch(batch,1);
		}
	}

	public static void validateData(List<Setup__c> newSetups, Map<ID, Setup__c> oldSetupMap){
		for(Setup__c setup:newSetups){
			Setup__c oldSetup = oldSetupMap.get(setup.ID);
			if(setup.Published__c){
				if(setup.Group_Based__c != oldSetup.Group_Based__c){
					setup.Group_Based__c.addError('The group based field is not editable after setup has been published.');
				}

				if(setup.Standards_Based_Grading__c != oldSetup.Standards_Based_Grading__c ||
						setup.Standards_ONLY_Gradebook__c != oldSetup.Standards_ONLY_Gradebook__c){
					setup.addError('Once a setup has been published, it\'s gradbook type cannot be changed.');
				}

				if(!setup.Active__c && setup.Data_Activated__c){
					if(setup.Passing_Grade_Threshold__c != oldSetup.Passing_Grade_Threshold__c){
						setup.Passing_Grade_Threshold__c.addError('This setup is from a past year. You can no longer edit Passing Grade Threshold because it affects grade calculations in the past year. If you need to make a change, please contact the SchoolForce support team so that they can work with you to see if this change is possible.');
					}
					if(setup.Rolling_Standard_Grade__c != oldSetup.Rolling_Standard_Grade__c){
						setup.Rolling_Standard_Grade__c.addError('This setup is from a past year. You can no longer edit Rolling Standard Grade because it affects grade calculations in the past year. If you need to make a change, please contact the SchoolForce support team so that they can work with you to see if this change is possible.');
					}
					if(setup.Calculation_Type__c != oldSetup.Calculation_Type__c){
						setup.Calculation_Type__c.addError('This setup is from a past year. You can no longer edit Calculation Type because it affects grade calculations in the past year. If you need to make a change, please contact the SchoolForce support team so that they can work with you to see if this change is possible.');
					}
					if(setup.Law_of_Decaying_Average_Weight__c != oldSetup.Law_of_Decaying_Average_Weight__c){
						setup.Law_of_Decaying_Average_Weight__c.addError('This setup is from a past year. You can no longer edit Law of Decaying Average Weight because it affects grade calculations in the past year. If you need to make a change, please contact the SchoolForce support team so that they can work with you to see if this change is possible.');
					}
				}
			}
		}
	}

	public static void recalculateStandardGrades(List<Setup__c> newSetups, Map<ID, Setup__c> oldSetupMap){
		Set<ID> setupsToRecalc = new Set<ID>();
		for (Setup__c setup: newSetups){
			Setup__c oldSetup = oldSetupMap.get(setup.ID);
			if(setup.Calculation_Type__c != null && setup.Active__c){
				if(setup.Law_of_Decaying_Average_Weight__c != oldSetup.Law_of_Decaying_Average_Weight__c ||
						setup.Calculation_Type__c != oldSetup.Calculation_Type__c ||
						setup.Rolling_Standard_Grade__c != oldSetup.Rolling_Standard_Grade__c){
					setupsToRecalc.add(setup.ID);
				}
			}
		}
			
		if(!setupsToRecalc.isEmpty()) {
			Batch_StandardGradeRecalc bsg = new Batch_StandardGradeRecalc(setupsToRecalc);
			Database.executeBatch(bsg, 50);
		}
	}
}