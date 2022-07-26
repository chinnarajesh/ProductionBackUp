<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>School_setup_School_was_marked_as_SDS</fullName>
        <ccEmails>juturi.rajesh@jaxconsult.com</ccEmails>
        <description>School setup: School was marked as SDS</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/School_setup_School_was_marked_as_SDS</template>
    </alerts>
    <alerts>
        <fullName>School_setup_School_was_marked_as_Split</fullName>
        <ccEmails>juturi.rajesh@jaxconsult.com</ccEmails>
        <description>School setup: School was marked as Split</description>
        <protected>false</protected>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/School_setup_School_was_marked_as_Split</template>
    </alerts>
    <rules>
        <fullName>School setup%3A School was marked as SDS</fullName>
        <actions>
            <name>School_setup_School_was_marked_as_SDS</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.SDS_School__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>School setup%3A School was marked as Split</fullName>
        <actions>
            <name>School_setup_School_was_marked_as_Split</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.Split_School__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>School setup: School was marked as Split</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
