global class EmailOpportunityInvoiceNumberHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        String subject = email.subject;
        Pattern pattern = Pattern.Compile('\\bINV-\\d{6,}\\b');
        Matcher matcher = pattern.matcher(subject);

        if(matcher.find()){
            String invoiceNum = matcher.group();
            String addressFrom = email.fromAddress;
                List<OpportunityContactRole> oppContacts = [
                    SELECT Opportunity.Id  
                    FROM OpportunityContactRole 
                    WHERE Opportunity.Invoice_Number__c =:invoiceNum AND Contact.Email =:addressFrom
                    ];
                if(oppContacts.size()>0){
                    Opportunity opp = [
                        SELECT Id, StageName, IsClosed 
                        FROM Opportunity
                        WHERE Id=:oppContacts[0].Opportunity.Id
                        LIMIT 1
                            ];
                    if(!opp.IsClosed){
                        String answer = email.htmlBody.toLowerCase();
                        if(answer.contains('approved')){
                            List<Schema.PicklistEntry> stageValues = Opportunity.StageName.getDescribe().getPicklistValues();
                                for(Integer i = 0; i<stageValues.size(); i++){
                                  if(stageValues[i].getValue() == opp.StageName){
                                    	opp.StageName = stageValues[i+1].getValue();
                                      break;
                                  }
                                }
                        }else if (answer.contains('rejected')){
                            opp.StageName = 'Closed Lost';
                        } 
                        
                        update opp;
                        result.success = true;
                        result.message = 'Update successfully';
                    } else{
                        result.success = false;
                        result.message = 'Opportunity has already been closed';
                    }
                    
                }
                else{
                    result.success = false;
                    result.message = 'Not find opportunity for : '+ invoiceNum + ' '+ email.fromAddress;
                }
        
        }else{
            result.success = false;
            result.message = 'Not find matcher: '+ subject;
        }



        return result;
    }
}