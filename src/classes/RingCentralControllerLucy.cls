global with sharing class RingCentralControllerLucy {
    global static String autoSaveInstance = 'cloudPhone';
    global static Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('task').getDescribe().fields.getMap();
    global static String[] defaultFields = new String[]{'subject', 'whoid','whatid', 'description'};
    global static Schema.DisplayType[] whitelistFieldTypes = new Schema.DisplayType[]{Schema.DisplayType.DATE, Schema.DisplayType.STRING, Schema.DisplayType.PICKLIST, Schema.DisplayType.REFERENCE, Schema.DisplayType.TEXTAREA};

    public RingCentralControllerLucy () {
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
    @remoteAction
    global static List<String> findPhoneFields(String fieldsName) {
       List<String> result = new List<String>();

    if( fieldsName == 'Contact' ) {


        for(Schema.SObjectField sField : Contact.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dField = sField.getDescribe();
            if(dField.getType() == Schema.DisplayType.Phone) {
                result.add(dField.getName());
            }
        }

    }
    if( fieldsName == 'Lead' ) {
        for(Schema.SObjectField sField : Lead.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dField = sField.getDescribe();
            if(dField.getType() == Schema.DisplayType.Phone) {
              result.add(dField.getName());
            }
        }

    }
    if( fieldsName == 'Opportunity') {
        for(Schema.SObjectField sField : Opportunity.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dField = sField.getDescribe();
            if(dField.getType() == Schema.DisplayType.Phone) {
              result.add(dField.getName());
            }
        }
    }

    return result;
    }
    @remoteAction
    global static Map<String, List<String>> getPhoneFields() {
        Map<String, List<String>> results = new Map<String, List<String>>();
        List<String> fields;

        // Contact
        fields = new List<String>();
        for(Schema.SObjectField sField : Contact.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dField = sField.getDescribe();
            if(dField.getType() == Schema.DisplayType.Phone) {
                fields.add(dField.getName());
            }
        }
        results.put('Contact', fields);

        //Lead
        fields = new List<String>();
        for(Schema.SObjectField sField : Lead.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dField = sField.getDescribe();
            if(dField.getType() == Schema.DisplayType.Phone) {
                fields.add(dField.getName());
            }
        }
        results.put('Lead', fields);

        //Opportunity
        fields = new List<String>();
        for(Schema.SObjectField sField : Opportunity.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dField = sField.getDescribe();
            if(dField.getType() == Schema.DisplayType.Phone) {
                fields.add(dField.getName());
            }
        }
        results.put('Opportunity', fields);

        //Account
        fields = new List<String>();
        for(Schema.SObjectField sField : Account.SObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult dField = sField.getDescribe();
            if(dField.getType() == Schema.DisplayType.Phone) {
                fields.add(dField.getName());
            }
        }
        results.put('Account', fields);

        return results;
    }

    public static String buildQuery(List<String> phoneFields, String SobjectApiName) {
        String commaSepratedFields = 'name';

        for(String fieldName : phoneFields) {
            commaSepratedFields = commaSepratedFields + ', ' + fieldName;
        }
        return 'select ' + commaSepratedFields + ' from ' + SobjectApiName;
    }
    public static String joinArray(List<String> phoneFields) {
        String commaSepratedFields = 'NAME';

        for(String fieldName : phoneFields) {
            commaSepratedFields = commaSepratedFields + ', ' + fieldName;
        }
        return commaSepratedFields;
    }
    @RemoteAction
    global static List<sfdcContact> getSfdcContacts() {
        return new List<sfdcContact>();
    }
    @RemoteAction
    global static String phoneOr(List<String> phoneNumbers) {
        String phoneOrResult = '';
        if(phoneNumbers.size() == 1) {
            phoneOrResult = phoneOrResult + phoneNumbers[0];
            return phoneOrResult;
        }
        for(Integer i = 0; i < phoneNumbers.size()-1; i++) {
            phoneOrResult = phoneOrResult + phoneNumbers[i] + ' OR ';
        }
        phoneOrResult = phoneOrResult + phoneNumbers[phoneNumbers.size()-1];
        return phoneOrResult;
    }
    @RemoteAction
    global static Map<String, List<SObject>> getSfdcContacts450(List<String> phoneNumbers) {
        Map<String, List<SObject>> result = new Map<String, List<SObject>>();

        result.put('Contact', new List<SObject>());
        result.put('Lead', new List<SObject>());
        result.put('Opportunity', new List<SObject>());

        Map<String, List<String>> phoneFields = getPhoneFields();

        //for(String phoneNumber : phoneNumbers) {
            List<List<SObject>> queryResult = search.query(
                'FIND \'' + phoneOr(phoneNumbers) + '\' IN ALL FIELDS RETURNING '

                + 'Contact ( ' + joinArray(phoneFields.get('Contact')) + '), '
                + 'Lead ( ' + joinArray(phoneFields.get('Lead')) + ' ), '
                + 'Opportunity ( ' + joinArray(phoneFields.get('Opportunity')) + ' )'
                + 'LIMIT 20'
            );

            result.get('Contact').addAll(queryResult.get(0));
            result.get('Lead').addAll(queryResult.get(1));
            result.get('Opportunity').addAll(queryResult.get(2));
        //}
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
    //legacy function that cannot be deleted due to managed classes
    @RemoteAction
    global static Boolean replaceInternalKeyWithCallId(String a, String b, String c) {
        return null;
    }
    public Boolean getAccountRelatedTo() {
        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            return false;
        }
        return AdminSetting__c.getInstance(autoSaveInstance).accountRelatedTo__c;
    }
    public String getUserInfoLocale() {
        return UserInfo.getLocale();
    }
    @RemoteAction
global static List<Task> upsertCustomTaskNew480(List<Task> taskArg, List<String> internalKey) {
    List<Task> tasks = new List<Task>{};
    List<Task> newTasks = new List<Task>{};
    String currentUserId = UserInfo.getUserId();
    tasks = [select Id, CallObject from Task where CallObject IN :internalKey and CreatedById=:currentUserId for update];
    System.debug('tasks-start');
    System.debug(tasks);
    System.debug('tasks-end');
    for(String aInternalKey : internalKey) {
        Boolean flag = false;
        Task aNewTask = null;
        for(Task aTask : tasks) {
            if(String.valueOf(aTask.CallObject) == aInternalKey) {
                flag = true;
                aNewTask = aTask;
                break;
            }
        }
        if(!flag) {
            aNewTask = new Task();
        }
        System.debug('aNewTask-start');
        System.debug(aNewTask);
        System.debug('aNewTask-end');

        Task updateTask = null;
        for(Task aTaskArg : taskArg) {
            if(String.valueOf(aTaskArg.CallObject) == aInternalKey) {
                updateTask = aTaskArg;
                break;
            }
        }
        System.debug('updateTask-start');
        System.debug(updateTask);
        System.debug('updateTask-end');

        Map<String, Schema.SObjectField> fieldSet = Schema.SObjectType.Task.fields.getMap();
        for(String fName : fieldSet.keySet()) {
            if (updateTask.get(fName) != null) {
                aNewTask.put(fName, updateTask.get(fName));
            }
        }

        if (String.valueOf(updateTask.whoid) == 'force-overwrite-with-empty-value') {
            aNewTask.whoid = null;
        }

        if (String.valueOf(updateTask.whatid) == 'force-overwrite-with-empty-value') {
            aNewTask.whatid = null;
        }
        System.debug('aNewTask-start');
        System.debug(aNewTask);
        System.debug('aNewTask-end');
        newTasks.add(aNewTask);
        System.debug('newTasks-add-start');
        System.debug(newTasks);
        System.debug('newTasks-add-end');
    }
    System.debug('newTasks-start');
    System.debug(newTasks);
    System.debug('newTasks-end');
    upsert newTasks;
    return newTasks;

}


}