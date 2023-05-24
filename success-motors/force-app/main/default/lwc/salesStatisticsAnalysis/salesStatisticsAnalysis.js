import { LightningElement, api, wire, track  } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

import getAccountById from '@salesforce/apex/AccountContoller.getAccountById';
import getAccounts from '@salesforce/apex/AccountContoller.getAccounts';


export default class SalesStatisticsAnalysis extends LightningElement {
    @api recordId;
    @wire(CurrentPageReference) currentPageReference;
    @track account;
    @track allAccount;

    @track currentPage;
    @track itemsPerPage = 10;
    @track displayedData;
    @track findData;
    @track keyword='';
    @track keyName = '';
    @track keyAmount ='';



    get isAccountDetailPage() {
        return (
            this.currentPageReference &&
            this.currentPageReference.type === 'standard__recordPage' &&
            this.currentPageReference.attributes.objectApiName === 'Account' &&
            this.currentPageReference.attributes.recordId === this.recordId
        );
    }

    @wire(getAccountById, { accountId: '$recordId' })
    wiredGetAccountById({error, data}){
        if(data){
            this.account = data;
            console.log("Update 8.0");
            console.log("Data about account ", data);
        }
        else if(error){
            console.log('Something went wrong while receive account: ', error);
        }
    }

    connectedCallback() {
        this.retrieveAccounts();
        this.currentPage=1;
    }

    retrieveAccounts() {
        getAccounts()
            .then(result => {
                this.allAccount = result;
                console.log("all accounts loaded", result);
                this.updateDisplayedData();
            })
            .catch(error => {
                console.log('all accounts:', error);
            });
    }

    get isFirstPage() {
    
        return !(this.currentPage > 1);
    }

    get isLastPage() {
        return !(this.currentPage < Math.ceil(this.findData.length  / this.itemsPerPage));
    }

    previousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
            this.updateDisplayedData();
        }
    }

    nextPage() {
        if (this.currentPage < Math.ceil(this.findData.length  / this.itemsPerPage)) {
            this.currentPage += 1;
            this.updateDisplayedData();
        }
    }

    updateDisplayedData() {
            const startIndex = (this.currentPage - 1) * this.itemsPerPage;
            this.findData = this.allAccount.filter(item=>item.Name.toLowerCase().startsWith(this.keyName))
                                            .filter(item=>{
                                                console.log('param '+item.TotalOpportunityAmount.toString()+' '+this.keyAmount.toString());
                                                console.log(typeof item.TotalOpportunityAmount);
                                                console.log(typeof this.keyAmount+ '"'+this.keyAmount+'"');
                                                return item.TotalOpportunityAmount.toString().startsWith(this.keyAmount.toString())
                                            });
            this.displayedData = this.findData.slice(startIndex, startIndex + this.itemsPerPage);
    }

    handleKeyWordChange(event){
        this.keyword=event.target.value;
        this.currentPage = 1;
        const amount = this.keyword.match(/\d+/);
        console.log("amount "+amount);
        if(amount){
            this.keyAmount = amount[0];
            this.keyName = this.keyword.split(amount)[0].trim();
        }
        else{
            this.keyAmount='';
            this.keyName = this.keyword.trim();
        }
        console.log(this.keyAmount);
        console.log(this.keyName);
        this.updateDisplayedData();    
    }
}