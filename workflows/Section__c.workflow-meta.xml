<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Update_Section_Name</fullName>
        <description>Update the name of the section to the auto name formula.</description>
        <field>Name</field>
        <formula>Auto_Name__c</formula>
        <name>Update Section Name</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Update Curriculum Section Name</fullName>
        <actions>
            <name>Update_Section_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Section__c.Auto_Name__c</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <criteriaItems>
            <field>Section__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>Curriculum</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Update Intervention Section Name</fullName>
        <actions>
            <name>Update_Section_Name</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Section__c.Auto_Name__c</field>
            <operation>notEqual</operation>
            <value>null</value>
        </criteriaItems>
        <criteriaItems>
            <field>Section__c.RecordTypeId</field>
            <operation>equals</operation>
            <value>Intervention Section</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
