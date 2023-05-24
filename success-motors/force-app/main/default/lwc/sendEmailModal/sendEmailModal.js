import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import getOpportunity from '@salesforce/apex/OpportunityController.getOpportunity';
import getMyTemplate from '@salesforce/apex/OpportunityController.getMyTemplate';
import getContactRole from '@salesforce/apex/OpportunityController.getContactRole';
import getLastInvoice from '@salesforce/apex/OpportunityController.getLastInvoice'
import sendEmail from '@salesforce/apex/OpportunityController.sendEmail';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import {NavigationMixin} from 'lightning/navigation'

export default class SendEmailModal extends NavigationMixin(LightningElement) {
    @api recordId;
    recordData;
    @track bodyInfo;
    subjectInfo;
    contactRole;
    fileId;

    @wire(getContactRole, { recordId: '$recordId' })
    wiredGetContactRole({error, data}){
        if(data){
            this.contactRole = data;
            console.log("Data has been recieved ", data);
        
        }
        else if(error){
            console.log('Something went wrong: ', error);
        }
    }

    @wire(getOpportunity, { recordId: '$recordId' })
    wiredGetOpportunity({error, data}){
        if(data){
            this.recordData = data;
        }
        else if(error){
            console.log('Something went wrong: ', error);
        }
    }

    @wire(getMyTemplate, { recordId: '$recordId', developerName: 'Send_Invoice' })
    wiredGetMyTemplate({error, data}){
        if(data){
            this.subjectInfo = data.Subject;
            this.bodyInfo = data.Body;
        }
        else if(error){
            console.log('Something went wrong: ', error);
        }
    }

    get Subject(){
        return this.subjectInfo;
    }

    get Body(){
        return this.bodyInfo;
    }
    get ContactName(){
        return this.contactRole?.Contact.Name;
    }
    get ContactEmail(){
        return this.contactRole?.Contact.Email;
    }

    closeAction(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    @wire(getLastInvoice,{recordId: '$recordId'})
    wiredGetLastInvoice({data, error}){
        if(data){
            console.log(data);
            this.fileId = data;
        }
        else if(error){
            console.log('Error: ',JSON.stringify(error));
        }
    }


    previewHandler(){
         console.log('Preview change 5.0');
         this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId: this.fileId
            }
        })
    }

    handleChangeBody(event){
        this.bodyInfo = event.target.value;
    }

    handleSendEmail() {
        console.log('Sending email 3.3 ');

        // Call the email service to send the email
        sendEmail({ 
            to: this.contactRole?.Contact.Email,
            subject: this.subjectInfo,
            body: this.bodyInfo,
            idDoc: this.fileId })
            .then(() => {
                console.log('Success');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Email sent successfully.',
                        variant: 'success',
                    })
                );
            })
            .catch((error) => {
                if(error){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.message,
                            variant: 'error',
                        })
                    );
                }
            });
    }


}