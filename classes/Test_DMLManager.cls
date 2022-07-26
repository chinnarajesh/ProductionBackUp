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

@isTest
private class Test_DMLManager {
	static testMethod void flsRestrictedInsert(){
		//Account a1 = new Account(Name = 'Test1 Account');
		//System.runAs(new User(Id = UserInfo.getUserId())){
		//	insert new Account[]{a1};
		//}

		Contact c1 = new Contact(firstName='Original1', LastName='Contact', Comments__c = 'test');//AccountId=a1.Id);

		User newUser = ensureRestrictedUser();

		System.runAs(newUser){
			try{
				DMLManager.insertAsUser(new Contact[]{c1});
			}
			catch(DMLManager.FLSException flse){
				//expected
				System.assertEquals(Contact.SObjectType, flse.objType);
				System.assertEquals(DMLManager.Operation.OP_INSERT, flse.op);
				System.assertEquals(Contact.SObjectType.fields.Comments__c, flse.field);
			}
		}

	}

	static testMethod void flsUnrestrictedUpsert(){
		Account a1 = new Account(Name = 'Test1 Account');
		Account c2 = new Account(Name = 'Test2 Account');
		System.runAs(new User(Id = UserInfo.getUserId())){
			insert new Account[]{a1,c2};
		}

		Contact c1 = new Contact(firstName='Original1', LastName='Contact',AccountId=a1.Id);
		DMLManager.upsertAsUser(new Contact[]{c1});
		System.assert(c1.Id != null);

		c1.firstName='Updated1';
		c1.AccountId = c2.Id;

		Contact o2 = new Contact(firstName='Test2', lastName='Contact' ,AccountId=c2.Id);

		DMLManager.upsertAsUser(new Contact[]{c1,o2});

		List<Contact> reload = [SELECT Id, Name, AccountId FROM Contact ORDER BY Id];
		System.assertEquals(reload.size(),2);
		System.assertEquals('Updated1 Contact',reload[0].Name);
		System.assertEquals(c2.Id,reload[0].AccountId);
		System.assertEquals('Test2 Contact',reload[1].Name);
		System.assertEquals(c2.Id,reload[1].AccountId);
		System.assert(reload[1].Id != null);
	}

	static testMethod void flsRestrictedUpsert(){
		Account a1 = new Account(Name = 'Test1 Account');
		Account c2 = new Account(Name = 'Test2 Account');
		Contact c1 = new Contact(firstName='Original1', LastName='Contact',AccountId=a1.Id);

		System.runAs(new User(Id = UserInfo.getUserId())){
			insert new SObject[]{a1,c2,c1};
		}

		System.assert(c1.Id != null);

		c1.firstName='Updated1 Contact';
		c1.AccountId = c2.Id;

		Contact o2 = new Contact(firstName='Test2', LastName='Contact',AccountId=c2.Id);

		User newUser = ensureRestrictedUser();

		//System.runAs(newUser){
		//	try{
		//		DMLManager.upsertAsUser(new Contact[]{c1,o2});
		//	}
		//	catch(DMLManager.FLSException flse){
		//		//expected
		//		System.assertEquals(Contact.SObjectType,flse.objType);
		//		System.assertEquals(DMLManager.Operation.OP_UPDATE,flse.op);
		//		System.assertEquals(Contact.SObjectType.fields.AccountId,flse.field);
		//	}
		//}
	}

	//Tests that FLS is enforced even if field is not selected in SOQL query
	static testMethod void flsRestrictedUpdateOfFieldNotSelected(){
		Account a1 = new Account(Name = 'Test1 Account');
		Account c2 = new Account(Name = 'Test2 Account');
		Contact c1 = new Contact(firstName='Original1', LastName='Contact',AccountId=a1.Id);

		System.runAs(new User(Id = UserInfo.getUserId())){
			insert new SObject[]{a1,c2,c1};
		}

		System.assert(c1.Id != null);

		Contact c1Reload = [SELECT Id, firstName FROM Contact WHERE Id = :c1.Id];
		c1Reload.firstName='Updated1 Contact';
		//c1Reload.AccountId = c2.Id;
		c1Reload.Comments__c = 'test';

		User newUser = ensureRestrictedUser();

		System.runAs(newUser){
			try{
				DMLManager.updateAsUser(new Contact[]{c1Reload});
			}
			catch(DMLManager.FLSException flse){
				//expected
				System.assertEquals(Contact.SObjectType,flse.objType);
				System.assertEquals(DMLManager.Operation.OP_UPDATE,flse.op);
				System.assertEquals(Contact.SObjectType.fields.Comments__c,flse.field);
			}
		}
	}

	static testMethod void crudUnrestrictedInsertUpdateDelete(){
		Account a1 = new Account(Name='Test1 Account');
		DMLManager.insertAsUser(new Account[]{a1});

		//Would blow up if the Account wasn't inserted (List has no rows for assignment)		
		Account a1Reload = [SELECT Id, Name, Phone FROM Account WHERE Id = :a1.Id];
		System.assert(a1Reload.Phone == null);

		a1Reload.Phone = '555-555-5555';	 

		DMLManager.updateAsUser(new Account[]{a1Reload});

		a1Reload = [SELECT Id, Name, Phone FROM Account WHERE Id = :a1.Id];
		System.assertEquals('555-555-5555',a1Reload.Phone);

		DMLManager.deleteAsUser(new Account[]{a1Reload});

		List<Account> reloaded = [SELECT Id FROM Account];
		System.assertEquals(0,reloaded.size());
	}

	static testMethod void crudRestrictedInsertUpdateDelete(){
		User newUser = ensureRestrictedUser();

		Account a1 = new Account(Name='Test1 Account');
		System.runAs(new User(Id = UserInfo.getUserId())){
			insert a1;
		}

      	System.runAs(newUser) {
			// First try to insert a new object (including field two)
			try{
				Account c2 = new Account(Name='Test2  Account');
				DMLManager.insertAsUser(new Account[]{c2});
				System.assert(false,'Expected a DML Error!, newUser shouldn\'t be able to insert a Account');
			}
			catch(DMLManager.CRUDException crude){
				//expected
				System.assertEquals(Account.SObjectType,crude.objType);
				System.assertEquals(DMLManager.Operation.OP_INSERT,crude.op);
			}

			// Second, try to update the already inserted (previously) object, including field two
			try{
				a1.Name = 'Updated1 Account';
				DMLManager.updateAsUser(new Account[]{a1});
				System.assert(false,'Expected a DML Error!, newUser shouldn\'t be able to update a Account');
			}
			catch(DMLManager.CRUDException crude){
				//expected
				System.assertEquals(Account.SObjectType,crude.objType);
				System.assertEquals(DMLManager.Operation.OP_UPDATE,crude.op);
			}

			try{
				DMLManager.deleteAsUser(new Account[]{a1});
				System.assert(false,'Expected a DML Error!, newUser shouldn\'t be able to delete a Account');
			}
			catch(DMLManager.CRUDException crude){
				//expected
				System.assertEquals(Account.SObjectType,crude.objType);
				System.assertEquals(DMLManager.Operation.OP_DELETE,crude.op);
			}
      	}
	}

	static testmethod void testFailedUpdateWithErroneousId(){
		Account a1 = new Account(Name = 'Test1 Account');
		Id aId = null;

		insert new SObject[]{a1};
		aId = a1.Id;
		delete a1;

		try{
			Account a1Resurrected = new Account(Id = aId, Name = 'Resurrected Account');
			DMLManager.upsertAsUser(new Account[]{a1Resurrected});
			System.assert(false,'Expected a DMLManagerException! Attempting to update a record with an erroneous Id should fail');
		}
		catch(DMLManager.DMLManagerException dmle){
			//expected
			System.assert(dmle.getMessage().contains('An existing record could not be found'));
		}
	}

	static testmethod void testUpsertWithExternalID(){
		Account a1 = new Account(Name = 'Test1 Account');

		try{
			DMLManager.upsertAsUser(new List<Account>{a1}, Account.ID);
		} catch(DMLManager.DMLManagerException dmle){
			System.assert(false, 'Expected DML to succeed');
		}
		
		System.assertNotEquals(null, a1.ID, 'Expected the Account to have an ID if it was upserted properly.');
		System.assertEquals(1, [select id from Account where ID =: a1.ID].size(),'Expected to be able to query the Account after it was upserted.');
	}

	static testmethod void testAllOrNoneOperation(){
		List<Account> accounts = new List<Account>{
			new Account(Name = 'Account 1'),
			new Account(Name = 'Account 2')
		};

		try{
			DMLManager.insertAsUser(accounts, false);
		} catch(Exception e){
			System.assert(false, 'Expected DML to succeed.');
		}

		for(Account a:accounts){
			a.Phone = '555-555-5555';
		}

		try{
			DMLManager.updateAsUser(accounts, false);
		} catch(Exception e){
			System.assert(false, 'Expected DML to succeed.');
		}
		
		try{
			DMLManager.deleteAsUser(accounts, false);
		} catch(Exception e){
			System.assert(false, 'Expected DML to succeed.');
		}
	}

	private static User ensureRestrictedUser(){
		Profile p = [SELECT Id FROM Profile WHERE Name='Read Only']; 

		User newUser = new User(Alias = 'standt', Email='standarduser@testorg.com', 
	      	EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
    	  	LocaleSidKey='en_US', ProfileId = p.Id, 
      		TimeZoneSidKey='America/Los_Angeles', UserName='crudmanageruser1@testorg.com');
      		
      	insert newUser;
      	
      	assignObjectPermission(newUser,'Contact',true,true,false);
      	
      	return newUser;
	}

	private static void assignObjectPermission(User u, String objectType, Boolean create, Boolean edit, Boolean remove){
      	PermissionSet ps = new PermissionSet(Name = 'Enable' + objectType, Label = 'Enable ' + objectType);
  		insert ps;									
  											
  		ObjectPermissions oPerm = new ObjectPermissions(ParentId = ps.Id,
  			PermissionsRead = true,
  			PermissionsCreate = create,
  			PermissionsEdit = edit,
  			PermissionsDelete = remove,
  			PermissionsViewAllRecords = true, //need this if org has private on contacts
  			SObjectType = objectType);
  		insert oPerm;

  		insert new FieldPermissions(ParentId = ps.Id, Field = objectType+'.Comments__c', PermissionsEdit = false, PermissionsRead = true, SobjectType = objectType);

  		PermissionSetAssignment assign = new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);						
		insert assign;
	}
}