public with sharing class AccountContoller {
    public class AccountWrapper {
        @AuraEnabled
        public Id Id { get; set; }
        @AuraEnabled
        public String Name { get; set; }
        @AuraEnabled
        public Decimal TotalOpportunityAmount { get; set; }
    }

    @AuraEnabled(cacheable=true)
    public static Account getAccountById(String accountId){
        return [SELECT Id, Name
                FROM Account
                WHERE Id = :accountId
                LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountWrapper> getAccounts(){
        List<AccountWrapper> accounts = new List<AccountWrapper>();
        
        for (Account acc : [
            SELECT Id, Name, (
                SELECT StageName, Amount
                FROM Opportunities
            )
            FROM Account
            WHERE Id in (SELECT AccountId FROM Opportunity Where StageName='Closed Won')
        ]) {
            Decimal sumAmount = 0;
            for (Opportunity opp : acc.Opportunities) {
                if(opp.StageName=='Closed Won')
                    sumAmount += opp.Amount;
            }
            
            AccountWrapper accountWrapper = new AccountWrapper();
            accountWrapper.Id = acc.Id;
            accountWrapper.Name = acc.Name;
            accountWrapper.TotalOpportunityAmount = sumAmount;
            
            accounts.add(accountWrapper);
        }
        
        return accounts;
    }

    @AuraEnabled(cacheable=true)
    public static AggregateResult getAccountCloseWonSum(String accountId){
        AggregateResult result =  [SELECT SUM(Amount) totalAmount
                FROM Opportunity
                WHERE StageName = 'Closed Won' AND AccountId=:accountId
                ];
        return result;
    }

    
    @AuraEnabled(cacheable=true)
    public static List<AggregateResult> findAccounts(){
        return [SELECT AccountId, Account.Name, SUM(Amount) totalAmount
                FROM Opportunity
                WHERE Opportunity.StageName='Closed Won'
                GROUP BY AccountId, Account.Name];
    }

    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getOpportunityByAccountId(String accountId){
        return [
            SELECT Id, Name, Amount, CloseDate, CreatedDate FROM Opportunity WHERE AccountId=:accountId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItemByOppId(String opportunityId){
        return [
            SELECT Product2.Id ,Product2.Name, Product2.ProductCode, Quantity, TotalPrice 
            FROM OpportunityLineItem
            WHERE OpportunityId=:opportunityId 
        ];
    }
    
}