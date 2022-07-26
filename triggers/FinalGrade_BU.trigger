trigger FinalGrade_BU on Final_Grade__c (before insert, before update, after update) {
	if (!core_triggerUtils.bTriggersDisabled()){
		if(!core_triggerUtils.b){
			Set <String> allowSet = gradebook_soqlUtils.getAllowedNaValues();

			CT_Gradebook_GradeUtils gradeUtils = new CT_Gradebook_GradeUtils();
			gradeUtils.setOverrideValues();

			if (Trigger.isBefore && Trigger.isInsert){
				List <Final_Grade__c> fgList = new List <Final_Grade__c>();
				for(Final_Grade__c fg:trigger.new){
					if (!fg.final__c){
						fg.final__c = (!fg.Student_Setup_Active__c && fg.Student_Setup_Year_End_Date__c < system.today()) ? true : false;
					}

					if (fg.Grade_Override__c!=null) {
						fgList.add(fg);
					} else if (!allowSet.contains(fg.Grade_Override__c)){
						if (fg.Final_Grade_Letter_v2__c==null) fg.Final_Grade_Letter_v2__c.addError('Letter Grade must be populated');
						if (fg.Final_Grade_Value__c==null) fg.Final_Grade_Value__c.addError('Grade Value must be populated');
						if (fg.Final_GPA_Value__c==null) fg.Final_GPA_Value__c.addError('Unweighted GPA must be populated');
						if (fg.Weighted_GPA__c==null) fg.Weighted_GPA__c.addError('Weighted GPA must be populated');
					}
				 }

				if (!fgList.isEmpty()){
					if(gradeUtils.bCourseGradeScalesEmpty()) {
						gradeUtils.setCourseGradeScalesFromSObject(trigger.new);
					}

					gradeUtils.FG_processOverride(fgList);					
				}
			}

			if (Trigger.isBefore && Trigger.isUpdate) {
				List <Final_Grade__c> fgList = new List <Final_Grade__c>();
				for(Final_Grade__c fg:trigger.new){
					if(trigger.oldMap.get(fg.id).Grade_Override__c!=fg.Grade_Override__c&&fg.Grade_Override__c!=null){
						fgList.add(fg);
						fg.Grade_Overridden__c = true;
					}
					if(trigger.oldMap.get(fg.id).Grade_Override__c!=fg.Grade_Override__c&&fg.Grade_Override__c==null){
						fg.Grade_Overridden__c = false;
					}
					if (!fg.Grade_Overridden__c){
						if (!allowSet.contains(fg.Grade_Override__c)){
							if (fg.Final_Grade_Letter_v2__c==null) fg.Final_Grade_Letter_v2__c.addError('Letter Grade must be populated');
							if (fg.Final_Grade_Value__c==null) fg.Final_Grade_Value__c.addError('Grade Value must be populated');
							if (fg.Final_GPA_Value__c==null) fg.Final_GPA_Value__c.addError('Unweighted GPA must be populated');
							if (fg.Weighted_GPA__c==null) fg.Weighted_GPA__c.addError('Weighted GPA must be populated');
						}
					}
				}
				if (!fgList.isEmpty()){
					if(gradeUtils.bCourseGradeScalesEmpty()) {
						gradeUtils.setCourseGradeScalesFromSObject(fgList);
					}

					gradeUtils.FG_processOverride(fgList);					
				}
			}
		}
	}
}