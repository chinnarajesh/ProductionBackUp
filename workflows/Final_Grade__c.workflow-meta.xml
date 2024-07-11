<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>Set_Final_Credit_Value</fullName>
        <field>Final_GPA_Value__c</field>
        <formula>Course_Credits__c *  Final_GPA_Value__c</formula>
        <name>Set Final Credit Value</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Final_Credits_Value</fullName>
        <field>Total_GPA_Credit_Value__c</field>
        <formula>Course_Credits__c *  Unweighted_GPA__c</formula>
        <name>Set Final Credits Value</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>Set_Final_Weighted_Credits_Value</fullName>
        <field>Total_Weighted_GPA_Credit_Value__c</field>
        <formula>Course_Credits__c * Weighted_GPA__c</formula>
        <name>Set Final Weighted Credits Value</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <reevaluateOnChange>false</reevaluateOnChange>
    </fieldUpdates>
    <rules>
        <fullName>Set Final Credit</fullName>
        <actions>
            <name>Set_Final_Credits_Value</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Final_Grade__c.Course_Credits__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Final_Grade__c.Final_GPA_Value__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>Set Final Weighted Credit</fullName>
        <actions>
            <name>Set_Final_Weighted_Credits_Value</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Final_Grade__c.Course_Credits__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Final_Grade__c.Final_GPA_Value__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
