global with sharing class RingCentralController400 {
    global static String autoSaveInstance = 'cloudPhone';
    global static Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('task').getDescribe().fields.getMap();
    global static String[] defaultFields = new String[]{'subject', 'whoid','whatid', 'description'};
    global static Schema.DisplayType[] whitelistFieldTypes = new Schema.DisplayType[]{Schema.DisplayType.DATE, Schema.DisplayType.STRING, Schema.DisplayType.PICKLIST, Schema.DisplayType.REFERENCE, Schema.DisplayType.TEXTAREA};

    public RingCentralController400 () {
    }

    public Boolean getIsAutoSave() {
        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            return false;
        }
        return AdminSetting__c.getInstance(autoSaveInstance).AutoSave__c;
    }

    public Boolean getSaveOnRinging() {
        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            return false;
        }
        return AdminSetting__c.getInstance(autoSaveInstance).saveOnRinging__c;
    }

    public Boolean getPopOnRinging() {
        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            return false;
        }
        return AdminSetting__c.getInstance(autoSaveInstance).popOnRinging__c;
    }

    public static String encode(String val) {
        return EncodingUtil.urlEncode(val,'UTF-8');
    }

    public static String stripFieldName(String field) {
        Integer numOfMatches = field.countMatches('__');
        if (numOfMatches >= 1) {
            return field.subString(field.indexOf('__') + 2);
        }
        return field;
    }

    public static Boolean isValidType(String fieldName, Schema.DescribeFieldResult fieldDescribeResult) {
        if (fieldName == 'subject') {
            return true;
        }
        Schema.DisplayType fieldType = fieldDescribeResult.getType();
        for(Integer i = 0; i < whitelistFieldTypes.size(); i++){
            if(whitelistFieldTypes[i] == fieldType) {
                return true;
            }
        }
        return false;
    }

    public static CustomField generateCustomField(String fieldName, Schema.SObjectField field, Integer fieldOrder, Task[] tasks) {
        Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
        Schema.DisplayType fieldType = fieldDescribeResult.getType();
        String fieldValue = fieldName.toLowerCase();
        String fieldLabel = fieldDescribeResult.getLabel();
        Boolean isRequired = fieldDescribeResult.isNillable() ? false : true;
        String[] picklistOptions = new List<String>();
        String[] lookupRef = new List<String>();

        if (fieldType == Schema.DisplayType.Picklist) {
            List<Schema.PicklistEntry> pick_list_values = fieldDescribeResult.getPickListValues();
            for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
                picklistOptions.add(a.getValue());
                picklistOptions.add(a.getLabel());
            }
        }
        if (fieldType == Schema.DisplayType.Reference) {
            List<Schema.SObjectType> ref_objects = fieldDescribeResult.getReferenceTo();
            for (Schema.SObjectType obj : ref_objects) {
                Schema.DescribeSObjectResult describe = obj.getDescribe();
                lookupRef.add(describe.getName());
            }
        }

        CustomField customField = new CustomField();
        customField.fieldValue = fieldValue;
        customField.fieldLabel = fieldLabel;
        customField.fieldType = fieldType.name().toLowerCase();
        customField.isRequired = isRequired;
        customField.referenceObjs = lookupRef;
        customField.picklistOptions = picklistOptions;
        customField.fieldOrder = fieldOrder;
        customField.maxLength = fieldDescribeResult.getLength();
        return customField;
    }

    public static List<String> findPhoneFields(String SobjectApiName) {
        List<String> result = new List<String>();
        Map<String, Schema.SObjectField> objFieldMap =  Schema.getGlobalDescribe().get(SobjectApiName).getDescribe().fields.getMap();

        for(String fieldName : objFieldMap.keyset()) {
            Schema.SObjectField field = objFieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
            if (fieldDescribeResult.getType() == Schema.DisplayType.Phone) {
                result.add(fieldName);
            }
        }
        return result;
    }

    public static String buildQuery(List<String> phoneFields, String SobjectApiName) {
        String commaSepratedFields = 'name';

        for(String fieldName : phoneFields) {
            commaSepratedFields = commaSepratedFields + ', ' + fieldName;
        }
        return 'select ' + commaSepratedFields + ' from ' + SobjectApiName;
    }

    @RemoteAction
    global static List<sfdcContact> getSfdcContacts() {
        List<sfdcContact> result = new List<sfdcContact>();
        List<String> phoneFields = findPhoneFields('Contact');
        String query = buildQuery(phoneFields, 'Contact');

        List<Contact> contactList = Database.query(query);
        for (Contact cont: contactList) {
            String fullName = cont.name;

            for (String field: phoneFields) {
                String pNumber = (String)cont.get(field);
                if (pNumber != '' && pNumber != null) {
                    result.add(new sfdcContact(fullName, pNumber, cont.Id, 'contact', field));
                }
            }
        }

        phoneFields = findPhoneFields('Lead');
        query = buildQuery(phoneFields, 'Lead');
        List<Lead> leadList = Database.query(query);
        for (Lead leadInstance: leadList) {
            String fullName = leadInstance.name;
            String[] numbers = new List<String>();

            System.debug(leadInstance);
            for (String field: phoneFields) {
                String pNumber = (String)leadInstance.get(field);
                if (pNumber != '' && pNumber != null) {
                    result.add(new sfdcContact(fullName, pNumber, leadInstance.Id, 'lead', field));
                }
            }
        }

        phoneFields = findPhoneFields('Opportunity');
        query = buildQuery(phoneFields, 'Opportunity');
        List<Opportunity> opportunitiesList = Database.query(query);
        System.debug(opportunitiesList);
        for (Opportunity opportunityInstance: opportunitiesList) {
            String fullName = opportunityInstance.name;


            for (String field: phoneFields) {
                String pNumber = (String)opportunityInstance.get(field);
                if (pNumber != '' && pNumber != null) {
                    result.add(new sfdcContact(fullName, pNumber, opportunityInstance.Id, 'opportunity', field));
                }
            }
        }


        return result;
    }

    @RemoteAction
    global static List<CustomField> getCustomLogFields() {
        List<CustomField> result = new List<CustomField>();
        List<AdminSetting__c> all = AdminSetting__c.getall().values();

        if (all.isEmpty()) {
            for (String fieldName: defaultFields) {
                Integer fieldOrder = 0;
                Schema.SObjectField field = fieldMap.get(fieldName);
                result.add(generateCustomField(fieldName, field, fieldOrder, null));
                fieldOrder++;
            }
        } else {
            if (all.size() > 1) {
                for (AdminSetting__c fieldInstance: all) {
                    String fieldName = fieldInstance.name;
                    Integer fieldOrder = (Integer)(fieldInstance.fieldOrder__c);
                    if (fieldName != autoSaveInstance) {
                        Schema.SObjectField field = fieldMap.get(fieldName);
                        if (field == null) {
                            fieldName = stripFieldName(fieldName);
                            field = fieldMap.get(fieldName);
                        }
                        if (field != null) {
                            Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
                            if (isValidType(fieldName,fieldDescribeResult)) {
                                result.add(generateCustomField(fieldName, field, fieldOrder, null));
                            }
                        }
                    }
                }
            }
        }

        return result;
    }

    public List<String> getTaskSubjectValues() {
        List<String> values = new List<String>();

        // Get the sObject describe result for the Account object
        Schema.DescribeSObjectResult r = Task.sObjectType.getDescribe();

        // Get the field describe result for the Name field on the Account object
        Schema.DescribeFieldResult f = Schema.sObjectType.Task.fields.Subject;

        // Get the field describe result from the token
        //f = f.getSObjectField().getDescribe();

        List<Schema.PicklistEntry> pick_list_values = f.getSObjectField().getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            values.add(EncodingUtil.urlEncode(a.getLabel(),'UTF-8') +','+ EncodingUtil.urlEncode(a.getValue(),'UTF-8'));  //add the value and label to our final list
        }
        return values;
    }

    /* Custom field class */
    global class CustomField {
        public String fieldValue {get; set;}
        public String fieldLabel {get; set;}
        public Boolean isRequired {get; set;}
        public String[] referenceObjs {get; set;}
        public String[] picklistOptions {get; set;}
        public String fieldType {get; set;}
        public Decimal fieldOrder {get; set;}
        public Integer maxLength {get; set;}

        CustomField(){
        }
    }

    /* Custom Contact class */
    global class sfdcContact {
        public String fullName {get; set;}
        public String phoneNumber {get; set;}
        public String id {get; set;}
        public String type {get; set;}
        public String phoneField {get; set;}

        sfdcContact(String fn, String num, String objId, String objType, String pf) {
            fullName = fn;
            phoneNumber = num;
            id = objId;
            type = objType;
            phoneField = pf;
        }
    }

    @RemoteAction
    global static String upsertCustomTaskNew(Task taskArg, String internalKey) {
        Task[] tasks = null;
        String currentUserId = UserInfo.getUserId();

        tasks = [select Id, CallObject from Task where CallObject = :internalKey and CreatedById=:currentUserId for update];

        Task task = null;
        if (tasks.size() == 0) {
            task = new Task();
        } else {
            task = tasks[0];
        }
        Map<String, Schema.SObjectField> fieldSet = Schema.SObjectType.Task.fields.getMap();
        for(String fName : fieldSet.keySet()) {
            if (taskArg.get(fName) != null) {
                task.put(fName, taskArg.get(fName));
            }
        }

        if (String.valueOf(taskArg.whoid) == 'force-overwrite-with-empty-value') {
            task.whoid = null;
        }

        if (String.valueOf(taskArg.whatid) == 'force-overwrite-with-empty-value') {
            task.whatid = null;
        }

        upsert task;
        return task.id;
    }

    @RemoteAction
    global static String encrypt(String encryptedData) {
        return null;
    }
    @RemoteAction
    global static String decrypt(String encryptedData) {
        return null;
    }
    global static String upsertTaskNew(String taskId, String fromNo, String toNo, String callId,
                                    String callDate, Integer duration, String subject,
                                    String direction, String description, String linkedWith, String relatedTo, boolean isEnded, String result) {
        return null;
    }
    @RemoteAction
    global static String upsertTask(String taskId, String fromNo, String toNo, String callId,
                                    String callDate, Integer duration, String subject,
                                    String direction, String description, String linkedWith, String relatedTo, boolean isEnded) {
        return null;
    }
    @RemoteAction
    global static String upsertCustomTask(String a , String b, String c, Task t) {
        return null;
    }
    @RemoteAction
    global static String upsertCustomTaskObj(Task taskArg, String internalKey, String combKey) {
        return null;
    }
}