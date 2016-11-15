global with sharing class PhoneNumbersLeadController{
    public Lead currentLead {get;set;}
    public List<String> allPhoneFields;
    public Map<String, String> phoneFieldNameToLabel {get;set;}
    public Map<String, String> phoneFieldNameToPhoneNumber {get;set;}
    public List<String> nonEmptyPhoneFieldNameList {get; set;}
    
    public List<String> allPhoneLabelsList {get; set;}

    public PhoneNumbersLeadController(ApexPages.StandardController controller){
        findAllPhoneFields();
        Id currentId = ApexPages.currentPage().getParameters().get('id');
        String queryString = buildQuery(currentId);
        if (queryString != '') {
            List<Lead> leadList = (list<Lead>)database.query(queryString);
            if (leadList != null && leadList.size() > 0) {
                currentLead = leadList.get(0);
            }
        } else {
            currentLead = null;
        }
        
        if (currentLead != null) {
            populatePhoneNumber();
        }
    }
    
    public void populatePhoneNumber() {
        phoneFieldNameToPhoneNumber  = new Map<String, String>();
        nonEmptyPhoneFieldNameList  = new List<String>();
        for (String phoneFieldName : allPhoneFields) {
            String phoneNumber = String.valueOf(currentLead.get(phoneFieldName));
            if (phoneNumber != NULL && phoneNumber != '') {
                phoneFieldNameToPhoneNumber.put(phoneFieldName, phoneNumber);
                nonEmptyPhoneFieldNameList .add(phoneFieldName);
            }
        }
    }
    
    public void findAllPhoneFields() {
        allPhoneFields = new List<String>();
        phoneFieldNameToLabel = new Map<String, String>();
        String objType = 'lead';
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
            return 'SELECT ' + String.join(allPhoneFields, ',') + ' FROM Lead' + ' WHERE id = \''+ currentId + '\' ';
        }
        return '';
    }
}