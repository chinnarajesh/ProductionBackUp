/**
* Copyright (c), 2014, Patron Holdings LLC
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
*   are permitted provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice,
*      this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice,
*      this list of conditions and the following disclaimer in the documentation
*      and/or other materials provided with the distribution.
* - Neither the name of the Patron Holdings nor the names of its contributors
*      may be used to endorse or promote products derived from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
*  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
*  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
*  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
*  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
*  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
*  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

public class DMLManager {
	// Items in the following set must be entered in lower case
	private static Set<String> exceptionValues = new Set<String> {'id','isdeleted','createddate','systemmodstamp','lastmodifiedbyid','createdbyid','lastmodifieddate'};

	private static Map<Operation,Map<SObjectType,List<String>>> cachedRestrictedFields = new Map<Operation,Map<SObjectType,List<String>>>();
	private static Map<String, Map<String, Boolean>> cachedFieldAvaiablity = new Map<String, Map<String, Boolean>>();

	public enum Operation {OP_INSERT,OP_UPDATE,OP_DELETE,OP_UPSERT}

	// CRUD/FLS-safe DML operations. These honor the CRUD and FLS permissions of the running user
	public static void insertAsUser(List<SObject> objList){performDMLOperation(objList,Operation.OP_INSERT);}
	public static void updateAsUser(List<SObject> objList){performDMLOperation(objList,Operation.OP_UPDATE);}
	public static void upsertAsUser(List<SObject> objList){performDMLOperation(objList,Operation.OP_UPSERT);}
	public static void deleteAsUser(List<SObject> objList){performDMLOperation(objList,Operation.OP_DELETE);}

	/*public static void upsertAsUser(sObject obj, Schema.SobjectField upsertField){performExternalIDUpsertOperation(new List<sObject>{obj},upsertField);}*/
	public static void upsertAsUser(List<SObject> objList, Schema.SobjectField upsertField){performExternalIDUpsertOperation(objList,upsertField);}

	public static List<Database.SaveResult> insertAsUser(List<SObject> objList, Boolean allOrNone){
		return (List<Database.SaveResult>) performDMLOperation(objList, Operation.OP_INSERT, allOrNone);
	}

	public static List<Database.SaveResult> updateAsUser(List<sObject> objList, Boolean allorNone){
		return (List<Database.SaveResult>) performDMLOperation(objList, Operation.OP_UPDATE, allOrNone);
	}

	public static List<Database.UpsertResult> upsertAsUser(List<sObject> objList, Boolean allorNone){
		return (List<Database.UpsertResult>) performDMLOperation(objList, Operation.OP_UPSERT, allOrNone);
	}

	public static List<Database.DeleteResult> deleteAsUser(List<sObject> objList, Boolean allorNone){
		return (List<Database.DeleteResult>) performDMLOperation(objList, Operation.OP_DELETE, allOrNone);
	}

	// Custom Exception Classes
	public virtual class DMLManagerException extends Exception{
		public SObjectType objType {get; private set;}
		public Operation op{get; private set;}
	}

	public class CRUDException extends DMLManagerException{
		public CRUDException(SObjectType objType, Operation op){
			this('Access Denied: ' + op + ' on ' + objType);
			this.objType = objType;
			this.op = op;
		}
	}
 
	public class FLSException extends DMLManagerException{
		public SObjectField field{get; private set;}	
		public FLSException(SObjectType objType, SObjectField field, Operation op){
			this('Access Denied: ' + op + ' on ' + objType + '.' + field);
			this.objType = objType;
			this.op = op;
			this.field = field;
		}
	}

	public static void checkFieldAccessability(String objectType, Set<String> fields){
		Map<String, Schema.SObjectType> objects;
		Map<String, Schema.SObjectField> objectFields;
		Set<String> blockedFields = new Set<String>();

		if(cachedFieldAvaiablity.containsKey(objectType)){
			for(String fieldName: fields){
				if(cachedFieldAvaiablity.get(objectType).containsKey(fieldName)){
					if(!cachedFieldAvaiablity.get(objectType).containsKey(fieldName)){
						blockedFields.add(fieldName);
					}
				} else{
					if(objects == null){
						objects = Schema.getGlobalDescribe();
						objectFields = objects.get(objectType).getDescribe().fields.getMap();
					}
					boolean isAccessible = objectFields.get(fieldName).getDescribe().isAccessible();
					cachedFieldAvaiablity.get(objectType).put(fieldName, isAccessible);
					if(!isAccessible){
						blockedFields.add(fieldName);
					}
				}
			}
		} else {
			objects = Schema.getGlobalDescribe();
			objectFields = objects.get(objectType).getDescribe().fields.getMap();
			Map<String, Boolean> fieldMap = new Map<String, Boolean>();
			for(String fieldName: fields){
				if(objectFields.containsKey(fieldName)){
					boolean isAccessible = objectFields.get(fieldName).getDescribe().isAccessible();
					fieldMap.put(fieldName, isAccessible);
					if(!isAccessible){
						blockedFields.add(fieldName);
					}
				} else {
					blockedFields.add(fieldName);
				}
			}
			cachedFieldAvaiablity.put(objectType, fieldMap);
		}

		if(!blockedFields.isEmpty()){
			throw new FLSException('User lacks access to the following fields on '+objectType+': '+String.join(new List<String>(blockedFields), ', '));
		}
	}

	private static void performDMLOperation(List<SObject> objList, Operation dmlOperation){
		checkUserPermissions(objList, dmlOperation);

		// If no errors have been thrown to this point, execute the dml operation.
		if(dmlOperation == Operation.OP_INSERT){insert objList;} 
			else if (dmlOperation == Operation.OP_UPDATE){update objList;} 
				else if (dmlOperation == Operation.OP_UPSERT){upsertCollection(objList, null);}
					else if (dmlOperation == Operation.OP_DELETE){delete objList;}
	}

	private static List<Object> performDMLOperation(List<Sobject> objList, Operation dmlOperation, Boolean allOrNone){
		checkUserPermissions(objList, dmlOperation);

		if(dmlOperation == Operation.OP_INSERT){
			return Database.insert(objList, allOrNone);
		} else if(dmlOperation == Operation.OP_UPDATE){
			return Database.update(objList, allOrNone);
		} else if(dmlOperation == Operation.OP_UPSERT){ 
			if(objList.size() == 1){
				return new List<Object>{Database.upsert(objList.get(0), allOrNone)};
			} else {
				return (List<Object>) Database.upsert(objList, allOrNone);
			}
		} else if(dmlOperation == Operation.OP_DELETE){
			return Database.delete(objList, allOrNone);
		}
		return null;
	}

	private static void performExternalIDUpsertOperation(List<SObject> objList, Schema.SobjectField upsertField){
		checkUserPermissions(objList, Operation.OP_UPSERT);
		
		// If no errors have been thrown to this point, execute the upsert operation.
		upsertCollection(objList, upsertField);
	}

	public static void checkUserPermissions(List<SObject> objList, Operation dmlOperation){
		Map<SObjectType,List<Id>> objTypeMap = analyzeDMLCollection(objList, dmlOperation);

		checkCRUDPermission(objTypeMap.keySet(),dmlOperation);

		if(dmlOperation == Operation.OP_INSERT){
			for(SObject obj : objList){
				checkCreateAction(obj);
			}
		} else if (dmlOperation == Operation.OP_UPDATE || dmlOperation == Operation.OP_UPSERT){

			Map<Id,SObject> existingRecords = getExistingRecords(objTypeMap);

			for(SObject obj : objList){
				SObject existingRecord = existingRecords.get(obj.Id);
				if(obj.id != null){
					checkUpdateAction(obj,existingRecord);
				} else {
					checkCreateAction(obj);
				}
			}
		}
	}

	private static void upsertCollection(List<SObject> objList, Schema.SobjectField upsertField){
		// This is to deal with a call to upsertAsUser with a singular object.
		// Since we wrap that into a List<SObject> (which can't be passed into an upsert)
		// we unpack it and upsert the object individually.
		if(upsertField == null){
			if(objList.size() == 1){
				upsert objList.get(0);
			} else {
				upsert objList;
			}
		} else {
			if(objList.size() == 1){
				database.upsert(objList.get(0), upsertField);
			} else {
				database.upsert(objList, upsertField);
			}
		}
	} 

	private static Map<String,Object> getFieldMapFromExistingSObject(SObject obj){
		// Get actual fields present in object.  This serialization technique removes implicit nulls.
		String s = JSON.serialize(obj);
		Map<String,Object> fieldsMap = (Map<String,Object>) JSON.deserializeUntyped(s);
		fieldsMap.remove('attributes');
		return fieldsMap;
	}

	private static void checkCreateAction(SObject obj){
		List<String> restrictedFields = cachedRestrictedFields.get(Operation.OP_INSERT).get(obj.getSObjectType());
		//Save ourselves a trip through the loop below if there are no restricted fields
		if(restrictedFields == null || restrictedFields.isEmpty()){
			return;
		}

		Map<String,Object> fieldsMap = getFieldMapFromExistingSObject(obj);

		// If any restricted fields are present, throw an exception
		for(String fieldName : restrictedFields){
			if(fieldsMap.get(fieldName) != null){ // if any of the restricted fields are present in the candidate, throw an exception
				throw new FLSException(obj.getSObjectType(),obj.getSObjectType().getDescribe().fields.getMap().get(fieldName),Operation.OP_INSERT);
			}
		}  
	}

	private static void checkUpdateAction(SObject obj, SObject existingRecord){
		List<String> restrictedFields = cachedRestrictedFields.get(Operation.OP_UPDATE).get(obj.getSObjectType());
		//Save ourselves a trip through the loop below if there are no restricted fields
		if(restrictedFields == null || restrictedFields.isEmpty()){
			return;
		}

		if(existingRecord == null){
		    throw new DMLManagerException('DMLManager ERROR:  An existing record could not be found for object with Id = ' + obj.Id);
		}

		Map<String,Object> fieldsMap = getFieldMapFromExistingSObject(obj);

		// If any of the restricted values are present and have changed in the dml candidate object, throw an exception
		for(String fieldName : restrictedFields){
			if(fieldsMap.get(fieldName) != null && fieldsMap.get(fieldName) != existingRecord.get(fieldName) ){
				throw new FLSException(obj.getSObjectType(),obj.getSObjectType().getDescribe().fields.getMap().get(fieldName),Operation.OP_UPDATE);
			}
		}	 
	}

	// For update and upsert operations, retrieve a Map of all existing records, for each object that has an ID.
	// objects without an Id are skipped, because there is no existing record in the database.
	private static Map<Id,SObject> getExistingRecords(Map<SObjectType,List<Id>> objTypeMap){
		Map<ID, SObject> result = new Map<Id,SObject>();

		Map<SObjectType,List<String>> operationRestrictedFields = cachedRestrictedFields.get(Operation.OP_UPDATE);

		for(SObjectType objType : objTypeMap.keySet()){
			List<String> restrictedFields = operationRestrictedFields.get(objType);

			if(restrictedFields == null || restrictedFields.isEmpty()){
				continue;
			}

			List<Id> seenIds = objTypeMap.get(objType);
			if(seenIds.isEmpty()){
				continue;
			}

			String fieldList = String.join(restrictedFields,',');
			fieldList = String.escapeSingleQuotes(fieldList); //this prevents the security scanner from freaking out
			result.putAll((Database.query('SELECT ' + fieldList + ' FROM ' + String.escapeSingleQuotes(objType.getDescribe().getName()) + ' WHERE Id IN :seenIds')));
		}

		return result;
	}

	// Check CRUD permissions for the current user on the object
	private static void checkCRUDPermission(Set<SObjectType> objTypeList, Operation dmlOperation){
		for(SObjectType objType : objTypeList){
			DescribeSObjectResult describeObject = objType.getDescribe();
			if((dmlOperation == Operation.OP_INSERT && !describeObject.isCreateable()) ||
				(dmlOperation == Operation.OP_UPDATE && !describeObject.isUpdateable()) ||
				(dmlOperation == Operation.OP_DELETE && !describeObject.isDeletable()) ||
				(dmlOperation == Operation.OP_UPSERT && !(describeObject.isCreateable() && describeObject.isUpdateable()))) {
				throw new CRUDException(objType,dmlOperation);
			}
		}
	}

	// Get a Map of all the object types in the dml request and the list of fields for each 
	// that the current user cannot update, based on FLS security settings
	private static Map<SObjectType,List<Id>> analyzeDMLCollection(List<SObject> objList, Operation dmlOperation){
		Map<SObjectType,List<Id>> result = new Map<SObjectType,List<Id>>();

		for(SObject obj : objList){
			ensureRestrictedFieldsEntry(obj, dmlOperation);

			List<Id> seenIds = result.get(obj.getSObjectType());
			if(seenIds == null){
				seenIds = new List<Id>();
				result.put(obj.getSObjectType(),seenIds);
			}

			if(obj.Id == null){
				continue;
			}	

			seenIds.add(obj.Id);

		}
		return result;
	}

	private static void ensureRestrictedFieldsEntry(SObject obj, Operation dmlOperation){
		if(dmlOperation == Operation.OP_UPSERT){
			ensureRestrictedFields(obj,Operation.OP_INSERT);
			ensureRestrictedFields(obj,Operation.OP_UPDATE);
		}
		else{
			ensureRestrictedFields(obj,dmlOperation);
		}
	}

	private static void ensureRestrictedFields(SObject obj, Operation dmlOperation){
		Map<SObjectType,List<String>> operationRestrictedFields = cachedRestrictedFields.get(dmlOperation);
		if(operationRestrictedFields == null){
			operationRestrictedFields = new Map<SObjectType,List<String>>();
			cachedRestrictedFields.put(dmlOperation,operationRestrictedFields);
		}

		if(!operationRestrictedFields.containsKey(obj.getSObjectType())){

			DescribeSObjectResult describeObject = obj.getSObjectType().getDescribe();

			Map<String, Schema.SObjectField> objectFields = describeObject.fields.getMap();

			List<String> restrictedFields = new List<String>();

			for(String nm : objectFields.keyset()){
				if(!exceptionValues.contains(nm.toLowerCase())){
					DescribeFieldResult fr = objectFields.get(nm).getDescribe();
					if((!fr.isCalculated()) && ((dmlOperation == Operation.OP_INSERT && !fr.isCreateable()) ||
					   (dmlOperation == Operation.OP_UPDATE && !fr.isUpdateable())) 
					){
						restrictedFields.add(fr.getName());
					}  // there is not an isDeletable method at the field level
				}
			}
			operationRestrictedFields.put(obj.getSObjectType(),restrictedFields);
		}
	}
}