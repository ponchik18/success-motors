import { LightningElement, api, track } from 'lwc';
import OpportunityEntryModal from 'c/opportunityEntryModal';

import getOpportunityByAccountId from '@salesforce/apex/AccountContoller.getOpportunityByAccountId';
import getAccountCloseWonSum from '@salesforce/apex/AccountContoller.getAccountCloseWonSum';
import getOpportunityLineItemByOppId from '@salesforce/apex/AccountContoller.getOpportunityLineItemByOppId';

export default class AccountLine extends LightningElement {
    @api account;
    @api recordId;
    @track opportunities;
    @track sum;
    @track modalContainer;

    get isDataPass(){
        return this.account && this.opportunities && this.recordId;
    }

    get accountLabel(){
        return this.account.Name + ' '+this.sum+ ' $'
    }

    connectedCallback() {
        this.retrieveSum();
        this.retrieveOpportunities();
    }

    retrieveOpportunities() {
        getOpportunityByAccountId({accountId:this.recordId})
            .then(result => {
                this.opportunities = result;
                console.log("opportunities loaded", result);
            })
            .catch(error => {
                console.log('error opportunities:', error);
            });
    }

    retrieveSum() {
        getAccountCloseWonSum({accountId:this.recordId})
            .then(result => {
                this.sum = result['totalAmount'];
                if(this.sum===undefined)
                    this.sum ='0.00';
                else this.sum= this.sum.toFixed(2);
                console.log("sum loaded", result);
            })
            .catch(error => {
                console.log('error sum:', error);
            });
    }

    handleRowActions(event){
        console.log(event);
        const row = event.detail.row;
        const oppId = row.Id;
        const oppName = row.oppName;
        getOpportunityLineItemByOppId({opportunityId:oppId})
            .then(result => {
                const opportunityLineItems = result;
                console.log("opportunityLineItems loaded", result);
                OpportunityEntryModal.open({oppId:oppId,oppName:oppName,opportunityLineItems:opportunityLineItems });
            })
            .catch(error => {
                console.log('error opportunityLineItems:', error);
            });
        }



    get oppData() {
        if (this.opportunities) {
            return [...this.opportunities].map(opportunity => {
                return {
                    Id: opportunity.Id,
                    urlOpp: '/' + opportunity.Id,
                    oppName: opportunity.Name,
                    createdDate: opportunity.CreatedDate,
                    closeDate: opportunity.CloseDate,
                    amount: opportunity.Amount,
                    view: 'view Product'
                };
            });
        }
        return [];
    }

    oppColumns = [
        {label: 'Id', fieldName: 'Id' },
        {label: 'Opportunity Name', fieldName:'urlOpp', type: 'url',typeAttributes: {
            label: { fieldName: 'oppName' },
            target: '_blank'
          },},
        {label: 'Created Date', fieldName: 'createdDate', type: 'date'},
        {label: 'Close Date', fieldName: 'closeDate', type: 'date'},
        {label: 'Amount', fieldName: 'amount', type: 'currency'},
        {
            type: 'button',
            typeAttributes:{
                label: 'View Product',
                title: 'Preview',
                variant: 'border-filled',
                name: 'view',
                iconName: 'action:preview'
            }
        }
    ];


}