<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Staff_Name_on_Update</fullName>
        <field>Name</field>
        <formula>First_Name_Staff__c + &apos; &apos; +  Staff_Last_Name__c</formula>
        <name>Set Staff Name on Update</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Update Staff Name</fullName>
        <actions>
            <name>Set_Staff_Name_on_Update</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <formula>OR( isnew(), or( ischanged( First_Name_Staff__c), ischanged( Staff_Last_Name__c )) )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
