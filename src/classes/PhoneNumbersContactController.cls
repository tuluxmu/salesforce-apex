global with sharing class PhoneNumbersContactController{
    public Contact currentContact {get;set;}
    public List<String> allPhoneFields;
    public Map<String, String> phoneFieldNameToLabel {get;set;}
    public Map<String, String> phoneFieldNameToPhoneNumber {get;set;}
    public List<String> nonEmptyPhoneFieldNameList {get; set;}
    public Id currentId {get; set;}
    
    public List<String> allPhoneLabelsList {get; set;}

    public PhoneNumbersContactController(ApexPages.StandardController controller){
        findAllPhoneFields();
        currentId = ApexPages.currentPage().getParameters().get('id');
        String queryString = buildQuery(currentId);
        if (queryString != '') {
            List<Contact> contactList = (list<Contact>)database.query(queryString);
            if (contactList != null && contactList.size() > 0) {
                currentContact = contactList.get(0);
            }
        } else {
            currentContact = null;
        }
        
        if (currentContact != null) {
            populatePhoneNumber();
        }
    }
    
    public void populatePhoneNumber() {
        phoneFieldNameToPhoneNumber  = new Map<String, String>();
        nonEmptyPhoneFieldNameList  = new List<String>();
        for (String phoneFieldName : allPhoneFields) {
            String phoneNumber = String.valueOf(currentContact.get(phoneFieldName));
            if (phoneNumber != NULL && phoneNumber != '') {
                phoneFieldNameToPhoneNumber.put(phoneFieldName, phoneNumber);
                nonEmptyPhoneFieldNameList .add(phoneFieldName);
            }
        }
    }
    
    public void findAllPhoneFields() {
        allPhoneFields = new List<String>();
        phoneFieldNameToLabel = new Map<String, String>();
        String objType = 'contact';
        // get a list of my objects
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType ObjectSchema = schemaMap.get(objType);
        Map<String, Schema.SObjectField> fieldMap = ObjectSchema.getDescribe().fields.getMap();   
        
        for (String fieldName: fieldMap.keySet()) {
            // get the field and describe result
            Schema.SObjectField field = fieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
            if (fieldDescribeResult.getType() == Schema.DisplayType.Phone) {
                allPhoneFields.add(fieldName);
                phoneFieldNameToLabel.put(fieldName, fieldDescribeResult.getLabel() + ': ');
            }
        }
    }
    
    public String buildQuery(Id currentId) {
        if (allPhoneFields.size() > 0) {
            return 'SELECT ' + String.join(allPhoneFields, ',') + ' FROM Contact' + ' WHERE id = \''+ currentId + '\' ';
        }
        return '';
    }
    
    @RemoteAction
    @AuraEnabled
    global static void setSmsNumber(String num, String objectId) {
        System.debug(num);
        Contact currentContact = [SELECT Id, SMS_Number__c FROM Contact WHERE Id = :objectId];
        System.debug(currentContact);
        currentContact.SMS_Number__c = num;
        upsert currentContact;
    }
}