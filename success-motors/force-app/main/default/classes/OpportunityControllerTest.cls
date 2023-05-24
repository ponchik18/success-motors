@IsTest
private class OpportunityControllerTest {
    @IsTest
    static void testGetOpportunity() {
        // Create test Opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName='Prospecting',Amount=500,  CloseDate = Date.today() + 30);
        insert testOpportunity;
        testOpportunity = [Select id, Name, StageName, CloseDate, Invoice_Number__c, Amount From Opportunity where Name= 'Test Opportunity'];

        // Call the method being tested
        Opportunity result = OpportunityController.getOpportunity(testOpportunity.Id);

        // Verify the returned Opportunity
        System.assertNotEquals(null, result);
        System.assertEquals(testOpportunity.Id, result.Id);
        System.assertEquals(testOpportunity.Amount, result.Amount);
        System.assertEquals(testOpportunity.Name, result.Name);
        System.assertEquals(testOpportunity.Invoice_Number__c, result.Invoice_Number__c);

    }

    @IsTest
    static void testGetContactRole() {
    	 Opportunity opp = new Opportunity(Name = 'Test Opportunity', CloseDate = Date.today() + 10, StageName = 'Closed Lost');
        insert opp;
        opp = [SELECT Id, Name From Opportunity];
        Contact contact = new Contact(FirstName = 'Test', LastName ='Test', Email ='test@test.com', Phone = '9999');
        insert contact;
        contact = [SELECT id,Name, Email, Phone FROM Contact WHERE Name = 'Test Test'];
        OpportunityContactRole contactRole = new OpportunityContactRole(
            OpportunityId = opp.Id,
            ContactId = contact.Id,
            IsPrimary = true
        );
        insert contactRole;

        // Call the method to test
        Test.startTest();
        OpportunityContactRole result = OpportunityController.getContactRole(opp.Id);
        Test.stopTest();

        // Verify the result
        System.assertEquals(contact.Name, result.Contact.Name);
        System.assertEquals(contact.Email, result.Contact.Email);   
    }

    @IsTest
    static void testGetMyTemplate() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs (thisUser) {
        // Create test Opportunity
        Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName='Prospecting',  CloseDate = Date.today() + 40, Amount = 120);
        insert testOpportunity;

        // Create test EmailTemplate
        EmailTemplate testTemplate = new EmailTemplate (DeveloperName = 'test', FolderId = UserInfo.getUserId(), TemplateType= 'Text', Name = 'test');
		testTemplate.Body =  '{!Contact.Name} {!Opportunity.Amount} {!Organization.Name} {!Opportunity.OwnerFullName}';
        testTemplate.Subject = '{!Opportunity.Invoice_Number__c}';
        testTemplate.IsActive=True;
        insert testTemplate;
            
		Opportunity opp = new Opportunity(Name = 'Test Opportunity', CloseDate = Date.today() + 10, StageName = 'Closed Won');
        insert opp;
            
        opp = [SELECT Id, Name, Amount, Owner.Name, Account.Name, Invoice_Number__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
            
        OpportunityContactRole contact = new OpportunityContactRole();
        Contact oppContact= new Contact(FirstName = 'Test', LastName ='Test',Email = 'test@test.com',Phone = '9999' );
        insert oppContact;
            
        contact.ContactId = [SELECT Id, Name, Email, Phone FROM Contact WHERE Name = 'Test Test' LIMIT 1].Id;
        contact.OpportunityId = opp.Id;
        contact.isPrimary= True;
        insert contact;
           

        // Call the method being tested
        Test.startTest();
        EmailTemplate result = OpportunityController.getMyTemplate(testOpportunity.Id, testTemplate.DeveloperName);
        Test.stopTest();

        // Verify the returned EmailTemplate
        System.assertNotEquals(null, result);
        System.assertEquals(testTemplate.Id, result.Id);
        System.assertNotEquals('Hello {!OpportunityContactRole.Contact}', result.Body);
        System.assertNotEquals('{!Opportunity.Invoice_Number__c}', result.Body);
        System.assertNotEquals('{!Opportunity.Amount}', result.Body);
    
        
        }
    }

  @isTest
    static void testGetLatestInvoice() {
          // Create test data
        Opportunity opp = new Opportunity(Name = 'Test Opportunity', CloseDate = Date.today() + 10, StageName = 'Closed Lost');
        insert opp;
        ContentVersion cv = new ContentVersion(
            Title = 'Invoice-123456',
            VersionData = Blob.valueOf('Test Content'),
            PathOnClient ='test'
        );
        insert cv;
        cv = [SELECT Id FROM  ContentVersion WHERE Title='Invoice-123456' AND PathOnClient ='test'];
        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId
        );
        insert link;

        // Call the method to test
        Test.startTest();
        Id result = OpportunityController.getLastInvoice(opp.Id);
        Test.stopTest();

        // Verify the result
        System.assertEquals([SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId, result);
    }
    
    
  @isTest
    static void testGetLatestInvoiceNull() {
        
        // Call the method to test
        Test.startTest();
        Id result = OpportunityController.getLastInvoice('');
        Test.stopTest();

        // Verify the result
		System.assertEquals(null, result);     
    }



    @IsTest
    static void testSendEmail() {
    Opportunity opp = new Opportunity(Name = 'Test Opportunity', StageName = 'Closed Lost', CloseDate = Date.today() + 10);
    insert opp;
 	opp = [SELECT Id, Name, Amount, Owner.Name, Account.Name, Invoice_Number__c FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];    
        
	ContentVersion cv = new ContentVersion(
            Title = 'INV-123456',
            VersionData = Blob.valueOf('Test Content'),
            PathOnClient ='test'
        );
        insert cv;
        cv = [SELECT Id FROM  ContentVersion WHERE Title='INV-123456' AND PathOnClient ='test'];
        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = opp.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId
        );
        insert link;

       Test.StartTest();
        OpportunityController.sendEmail('test@test.com', opp.Invoice_Number__c,'Hello my dear friend', link.ContentDocumentId);
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();
 
        System.assertEquals(1, invocations, 'An email has not been sent');
    }
}