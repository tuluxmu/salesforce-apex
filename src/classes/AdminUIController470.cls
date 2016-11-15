global with sharing class AdminUIController470 {
    global static String[] whitelist = new String[]{'subject', 'description', 'whoid','whatid','priority', 'activitydate', 'type'};
    global static String autoSaveInstance = 'cloudPhone';
    global static String[] defaultFields = new String[]{'subject', 'whoid', 'whatid', 'description'};
    global static Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('task').getDescribe().fields.getMap();
    global static Schema.DisplayType[] whitelistFieldTypes = new Schema.DisplayType[]{Schema.DisplayType.DATE, Schema.DisplayType.STRING, Schema.DisplayType.PICKLIST, Schema.DisplayType.REFERENCE, Schema.DisplayType.TEXTAREA};

    public AdminUIController470() {

    }

    public PageReference initialize() {

        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            Integer index = 0;
            for (String fieldVal: defaultFields) {
                Schema.SObjectField field = fieldMap.get(fieldVal);
                Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();

                //check object and fls before inserting
                if(Schema.sObjectType.AdminSetting__c.isCreateable()  ){
                    if(Schema.sObjectType.AdminSetting__c.fields.fieldOrder__c.isCreateable()
                    && Schema.sObjectType.AdminSetting__c.fields.Name.isCreateable() ){
                        AdminSetting__c adminSetting = new AdminSetting__c(Name = fieldDescribeResult.getName(), fieldOrder__c = index);
                        insert adminSetting;
                    }
                }
                index++;
            }

            //check object and fls before inserting
            if(Schema.sObjectType.AdminSetting__c.isCreateable()){
                if(Schema.sObjectType.AdminSetting__c.fields.fieldOrder__c.isCreateable()
                && Schema.sObjectType.AdminSetting__c.fields.Name.isCreateable() ){
                    AdminSetting__c adminSetting = new AdminSetting__c(Name = autoSaveInstance, fieldOrder__c = index);
                    insert adminSetting;
                }
            }
        }

        PageReference pageRef = new PageReference('/apex/AdminUI');
        pageRef.setRedirect(true);
        return pageRef;

    }

    public Boolean getIsAutoSave() {
        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            return false;
        }
        return AdminSetting__c.getInstance(autoSaveInstance).AutoSave__c;
    }

    public Boolean getPopOnRinging() {
        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            return false;
        }
        return AdminSetting__c.getInstance(autoSaveInstance).popOnRinging__c;
    }

    public Boolean getSaveOnRinging() {
        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            return false;
        }
        return AdminSetting__c.getInstance(autoSaveInstance).saveOnRinging__c;
    }


    public List<AdminSetting__c> getCustomLogFields() {
        List<AdminSetting__c> result = new List<AdminSetting__c>();
        List<AdminSetting__c> all = AdminSetting__c.getall().values();
        for (AdminSetting__c fieldInstance: all) {
            if (fieldInstance.name != autoSaveInstance) {
                result.add(fieldInstance);
            }
        }
        return result;
    }

    public Boolean isSelected(List<AdminSetting__c> customLogFields, String fieldName) {
        for (AdminSetting__c fieldInstance: customLogFields) {
            if (fieldInstance.name == fieldName) {
                return true;
            }
        }
        return false;
    }

    public static Boolean isInWhitelist(String field) {
        for(Integer i = 0; i < whitelist.size(); i++){
            if(whitelist[i] == field) {
                return true;
            }
        }
        return false;
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

    public static Boolean isValidField(String fieldName, Schema.DescribeFieldResult fieldDescribeResult) {
        return !fieldDescribeResult.isCalculated() && (isInWhitelist(fieldName) || fieldDescribeResult.isCustom()) && isValidType(fieldName, fieldDescribeResult);
    }

    public List<SelectOption> getAvailableLogFields() {
      List<SelectOption> options = new List<SelectOption>();

      List<AdminSetting__c> customLogFields = getCustomLogFields();

      for (String fieldName: fieldMap.keySet()) {
        Schema.SObjectField field = fieldMap.get(fieldName);
        Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
        System.debug(fieldName);

        System.debug(isValidField(fieldName, fieldDescribeResult));
        if (!isSelected(customLogFields,fieldName) && isValidField(fieldName, fieldDescribeResult)) {
          String isRequired = fieldDescribeResult.isNillable() ? 'rc_non_required' : 'rc_required';
          options.add(new SelectOption(fieldName + '-' + isRequired, fieldDescribeResult.getLabel()));
        }
      }
      return options;
    }

    public List<SelectOption> getSelectedLogFields() {
        // preserve order, so read it from custom settings
        List<AdminSetting__c> customLogFields = getCustomLogFields();
        List<SelectOption> options = new List<SelectOption>();
        Integer numOfFields = customLogFields.size();

        for (Integer index = 0; index < numOfFields; index++) {
            for (AdminSetting__c fieldInstance: customLogFields) {
                if (fieldInstance.fieldOrder__c == index) {
                    String fieldName = fieldInstance.name;
                    Schema.SObjectField field = fieldMap.get(fieldName);
                    if (field != null) {
                        Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
                        if (isValidField(fieldName, fieldDescribeResult)) {
                            String isRequired = fieldDescribeResult.isNillable() ? 'rc_non_required' : 'rc_required';
                            options.add(new SelectOption(fieldName + '-' + isRequired, fieldDescribeResult.getLabel()));
                        }
                    }
                }
            }
        }
        return options;
    }

    @RemoteAction
    global static void setIsAutoSave(Boolean newSetting) {
        AdminSetting__c settings = AdminSetting__c.getInstance(autoSaveInstance);
        if (settings == null) {
           return;
        }
        if(Schema.sObjectType.AdminSetting__c.fields.AutoSave__c.isUpdateable()){
            settings.AutoSave__c = newSetting;
            update settings;
        }
    }
    @RemoteAction
    global static void setPopOnRinging(Boolean newSetting) {
        AdminSetting__c settings = AdminSetting__c.getInstance(autoSaveInstance);
        if(settings == null) {
            return;
        }
        if(Schema.sObjectType.AdminSetting__c.fields.popOnRinging__c.isUpdateable()){
            settings.popOnRinging__c = newSetting;
            update settings;
        }
    }

    @RemoteAction
    global static void setSaveOnRinging(Boolean newSetting) {
        AdminSetting__c settings = AdminSetting__c.getInstance(autoSaveInstance);
        if(settings == null) {
            return;
        }
        if(Schema.sObjectType.AdminSetting__c.fields.saveOnRinging__c.isUpdateable()){
            settings.saveOnRinging__c = newSetting;
            update settings;
        }
    }

    @RemoteAction
    global static void saveAutoSaveSettings(Boolean isAutoSave, Boolean saveOnRinging, Boolean popOnRinging) {
        AdminSetting__c settings = AdminSetting__c.getInstance(autoSaveInstance);
        if(settings == null) {
            return;
        }

        if(Schema.sObjectType.AdminSetting__c.fields.AutoSave__c.isUpdateable()){
            settings.AutoSave__c = isAutoSave;
        }
        if(Schema.sObjectType.AdminSetting__c.fields.saveOnRinging__c.isUpdateable()){
            settings.saveOnRinging__c = saveOnRinging;
        }
        if(Schema.sObjectType.AdminSetting__c.fields.popOnRinging__c.isUpdateable()){
            settings.popOnRinging__c = popOnRinging;
        }
        if(Schema.sObjectType.AdminSetting__c.isUpdateable()){
            update settings;
        }
    }

    @RemoteAction
    global static void setCustomLogFields(String[] selectedFieldsArr) {
        // first clear all the custom settings
        List<AdminSetting__c> all = AdminSetting__c.getall().values();
        for (AdminSetting__c fieldInstance: all) {
            if (fieldInstance.name != autoSaveInstance ) {
                if(Schema.sObjectType.AdminSetting__c.isDeletable()){
                    delete fieldInstance;
                }
            }
        }

        Integer index = 0;
        for (String fieldVal: selectedFieldsArr) {
            Schema.SObjectField field = fieldMap.get(fieldVal);
            Schema.DescribeFieldResult fieldDescribeResult = field.getDescribe();
            if(Schema.sObjectType.AdminSetting__c.isCreateable()){
                if(Schema.sObjectType.AdminSetting__c.fields.fieldOrder__c.isCreateable()
                && Schema.sObjectType.AdminSetting__c.fields.Name.isCreateable() ){
                    AdminSetting__c adminSetting = new AdminSetting__c(Name=fieldDescribeResult.getName(), fieldOrder__c = index);
                    insert adminSetting;
                }
            }
            index++;
        }
    }
   public Boolean getInitializeEnable() {
        if (AdminSetting__c.getInstance(autoSaveInstance) == null) {
            return false;
        } else {
            return true;
        }
    }
    @RemoteAction
    global static PageReference redirectInitialize() {
        PageReference pageRef = new PageReference('/apex/initialize470');
        pageRef.setRedirect(true);
        return pageRef;
    }
}