import { api, track } from 'lwc';
import LightningModal from 'lightning/modal';

export default class OpportunityEntryModal extends LightningModal {
    @api oppId;
    @api oppName;
    @api opportunityLineItems;

    handleOkay() {
        this.close('okay');
    }

    get isProductsLoad(){
        return this.opportunityLineItems;
    }

    get products() {
        if (this.opportunityLineItems) {
            return [...this.opportunityLineItems].map(item => {
                return {
                    Id: item.Product2.Id,
                    name: item.Product2.Name,
                    code: item.Product2.ProductCode,
                    priceOne: item.TotalPrice/item.Quantity,
                    quantity: item.Quantity,
                    totalPrice: item.TotalPrice
                };
            });
        }
        return [];
    }

    prodColumns = [
        {label: 'Id', fieldName: 'Id' },
        {label: 'Product Name', fieldName:'name', type: 'text'},
        {label: 'Product Code', fieldName: 'code', type: 'text'},
        {label: 'Price For One', fieldName: 'priceOne', type: 'currency'},
        {label: 'Quantity', fieldName: 'quantity', type: 'number'},
        {label: 'Total Price', fieldName: 'totalPrice', type: 'currency'},
    ]
}