Pricebook2 standardPB  = [SELECT ID FROM Pricebook2 WHERE isStandard=true];
for(Product2 prod: [SELECT ID, Name from Product2]){
    Decimal price = Decimal.valueOf(Math.random()*1000+100);
    PricebookEntry pbe = new PriceBookEntry(
        PriceBook2Id= standardPB.Id,
        Product2Id = prod.Id,
        UnitPrice = price,
        IsActive = true,
        UseStandardPrice = false
    );
    insert pbe;
}