@isTest
private class EmailOpportunityInvoiceNumberHandlerTest {
    private static Opportunity createOpportunity( String stageName){
        String oppName = 'Test Opportunity';
        Opportunity opp = new Opportunity(
            Name = oppName,
            StageName = stageName,
            CloseDate = Date.today() + 30
        );
        insert opp;


        Contact contact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'test@test.com'
        );
        insert contact;

        OpportunityContactRole oppContactRole = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = contact.Id
        );
        insert oppContactRole;
        return [
            SELECT Invoice_Number__c, StageName, Name
            FROM Opportunity
            WHERE Name =: oppName
            LIMIT 1 ];
    }
    
    private static Opportunity createInvalidOpportunityOpportunity( String stageName){
        String oppName = 'Test Opportunity';
        Opportunity opp = new Opportunity(
            Name = oppName,
            StageName = stageName,
            CloseDate = Date.today() + 30
        );
        insert opp;

        return [
            SELECT Invoice_Number__c
            FROM Opportunity
            WHERE Name =: oppName
            LIMIT 1 ];
    }
    
    static testMethod void testSuccessfullyChangingOpportunityStageNameToClosedWon(){
        Opportunity insertedOpp = createOpportunity('Prospecting');

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Invoice Number: '+insertedOpp.Invoice_Number__c;
        email.fromAddress = 'test@test.com';
        email.htmlBody = 'Approved';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        Test.startTest();
        EmailOpportunityInvoiceNumberHandler handler = new EmailOpportunityInvoiceNumberHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the result
        List<Schema.PicklistEntry> stageValues = Opportunity.StageName.getDescribe().getPicklistValues();
        for(Integer i = 0; i<stageValues.size(); i++){
            if(stageValues[i].getValue() == insertedOpp.StageName){
                insertedOpp.StageName = stageValues[i+1].getValue();
                break;            
            }
        }
        System.assertEquals(true, result.success);
        System.assertEquals('Update successfully', result.message);

        // Verify the updated Opportunity
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :insertedOpp.Id];
        System.assertEquals(insertedOpp.StageName, updatedOpp.StageName);
    }

    static testMethod void testSuccessfullyChangingOpportunityStageNameToClosedLost(){
        Opportunity insertedOpp = createOpportunity('Prospecting');

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Invoice Number: '+insertedOpp.Invoice_Number__c;
        email.fromAddress = 'test@test.com';
        email.htmlBody = 'Rejected';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        Test.startTest();
        EmailOpportunityInvoiceNumberHandler handler = new EmailOpportunityInvoiceNumberHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the result
        System.assertEquals(true, result.success);
        System.assertEquals('Update successfully', result.message);

        // Verify the updated Opportunity
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :insertedOpp.Id];
        System.assertEquals('Closed Lost', updatedOpp.StageName);
    }

    static testMethod void testChangingOpportunityStageNameThatClosed(){
       
        Opportunity insertedOpp = createOpportunity('Closed Won');

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Invoice Number: '+insertedOpp.Invoice_Number__c;
        email.fromAddress = 'test@test.com';
        email.htmlBody = 'Rejected';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        Test.startTest();
        EmailOpportunityInvoiceNumberHandler handler = new EmailOpportunityInvoiceNumberHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the result
        System.assertEquals(false, result.success);
        System.assertEquals('Opportunity has already been closed', result.message);

    }
    
    static testMethod void testChangingOpportunityWithInvalidSubject(){
       
        Opportunity insertedOpp = createOpportunity('Closed Won');

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Invoice';
        email.fromAddress = 'test@test.com';
        email.htmlBody = 'Rejected';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        Test.startTest();
        EmailOpportunityInvoiceNumberHandler handler = new EmailOpportunityInvoiceNumberHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the result
        System.assertEquals(false, result.success);
        System.assertEquals('Not find matcher: '+ email.subject, result.message);

    }
    
    static testMethod void testNotFoundOpportunity(){
       
        Opportunity insertedOpp = createOpportunity('Closed Won');
        String Invoice_num = 'INV-123456';
        String emailAdress = 'test@test.com';

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.subject = 'Invoice: INV-123456';
        email.fromAddress = 'test@test.com';
        email.htmlBody = 'Rejected';

        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();

        Test.startTest();
        EmailOpportunityInvoiceNumberHandler handler = new EmailOpportunityInvoiceNumberHandler();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, envelope);
        Test.stopTest();

        // Verify the result
        System.assertEquals(false, result.success);
        System.assertEquals('Not find opportunity for : '+ Invoice_num + ' '+ emailAdress, result.message);

    }

}