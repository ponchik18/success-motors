public with sharing class OpportunityController {

    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunity(String recordId){
        return [SELECT Id, Amount, Name, Invoice_Number__c,Owner.Email, Owner.FirstName, Owner.LastName, Account.Name FROM Opportunity WHERE Id = :recordId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static OpportunityContactRole getContactRole(String recordId){
       return [SELECT Contact.Name, Contact.Email FROM OpportunityContactRole WHERE isPrimary=TRUE AND OpportunityId=:recordId LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static EmailTemplate getMyTemplate(String recordId, String developerName){
        EmailTemplate template = [SELECT Id, Body, Subject  FROM EmailTemplate WHERE IsActive = true AND TemplateType = 'text' AND DeveloperName=:developerName LIMIT 1];
        Organization orgInfo = [SELECT Id, Name, Division, TimeZoneSidKey FROM Organization];

        Opportunity currentOpp = getOpportunity(recordId);
        template.Body = template.Body.replace('{!OpportunityContactRole.Contact}', getContactRole(recordId).Contact.Name);
        template.Body = template.Body.replace('{!Opportunity.Invoice_Number__c}', currentOpp.Invoice_Number__c);
        template.Body = template.Body.replace('{!TODAY()}', Date.today().format());
        template.Body = template.Body.replace('{!Organization.Name}', orgInfo.Name);
        template.Body = template.Body.replace('{!Opportunity.Amount}', String.valueOf(currentOpp.Amount));
        template.Body = template.Body.replace('{!Opportunity.OwnerEmail}', currentOpp.Owner.Email);
        template.Body = template.Body.replace('{!Opportunity.OwnerFullName}', currentOpp.Owner.FirstName+ ' '+ currentOpp.Owner.LastName);

        template.Subject = template.Subject.replace('{!Opportunity.Invoice_Number__c}', currentOpp.Invoice_Number__c);
        template.Subject = template.Subject.replace('{!Organization.Name}', orgInfo.Name);
        System.debug(template);
        return template;
    }


    @AuraEnabled(cacheable=true)
    public static String getLastInvoice(String recordId){
        List<ContentDocumentLink> documentLinks = [
            SELECT ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink
             WHERE LinkedEntityId = :recordId AND
              ContentDocument.LatestPublishedVersionId != null ORDER BY ContentDocument.CreatedDate DESC];

        if (!documentLinks.isEmpty()) {
            Id latestVersionId = documentLinks[0].ContentDocument.LatestPublishedVersionId;
            ContentVersion latestVersion =  [
                SELECT Id, Title, ContentDocumentId, VersionNumber FROM ContentVersion
                 WHERE id = :latestVersionId ORDER BY VersionNumber DESC LIMIT 1];
            return latestVersion.ContentDocumentId;
        }
        else return null;
    }

    @AuraEnabled
    public static String sendEmail(String to, String subject, String body, String idDoc){

        ContentDocument doc = [SELECT Title, FileType FROM ContentDocument WHERE Id = :idDoc];
        ContentVersion contentVersion = [SELECT Id, VersionData FROM ContentVersion WHERE ContentDocumentId = :idDoc];

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setContentType('application/pdf');
        attachment.setFileName(doc.Title);
        attachment.setBody(contentVersion.VersionData);
    
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject(subject);
        email.setHtmlBody(body);
        email.setReplyTo('test@1sp5m25g0wntezjg112fyy4ken8botgl637pfuuf8qzohvt8yx.2w-rs9bpeab.ap16.apex.salesforce.com');
        email.setToAddresses(new String[]{to});
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });


        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        return 'success';
    }
}