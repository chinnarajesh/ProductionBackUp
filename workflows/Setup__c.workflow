<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>School_setup_completion_admin_notification</fullName>
        <description>School setup completion admin notification</description>
        <protected>false</protected>
        <recipients>
            <recipient>App_System_Administrators</recipient>
            <type>group</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/School_setup_requires_publishing</template>
    </alerts>
    <alerts>
        <fullName>School_setup_publication</fullName>
        <description>School setup publication</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/School_setup_publication</template>
    </alerts>
    <alerts>
        <fullName>School_setup_rejection_notification</fullName>
        <description>School setup rejection notification</description>
        <protected>false</protected>
        <recipients>
            <type>owner</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/School_setup_requires_editing</template>
    </alerts>
    <rules>
        <fullName>Notify user of school setup publication</fullName>
        <actions>
            <name>School_setup_publication</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Setup__c.Verification_Status__c</field>
            <operation>equals</operation>
            <value>Verified</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>School setup rejection</fullName>
        <actions>
            <name>School_setup_rejection_notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Setup__c.Verification_Status__c</field>
            <operation>equals</operation>
            <value>Rejected</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>Setup completion notification</fullName>
        <actions>
            <name>School_setup_completion_admin_notification</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Setup__c.Verification_Status__c</field>
            <operation>equals</operation>
            <value>Verification</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
