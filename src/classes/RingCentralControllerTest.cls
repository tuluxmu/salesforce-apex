global with sharing class RingCentralControllerTest {

    public RingCentralControllerTest () {
    }

    public List<String> getTaskSubjectValues() 
    {
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
    
    //public String getTaskDesscriptionValues(){   
        //Schema.DescribeFieldResult f = Schema.sObjectType.Task.fields.Description;
        //can get description label, but not the value
        //String s = f.getSObjectField().getDescribe().getLabel();
        //return s;
    //}
    
    @RemoteAction
    global static String getTaskDescriptionValues(String taskId, String fromNo, String toNo, String callId){
       Task[] tasks = null;
                           
        String internalKey = fromNo + '->' + toNo;
         String currentUserId =UserInfo.getUserId() ;
        if (taskId != null) {
            tasks = [select Id, CallObject from Task where Id = :taskId for update];
        } else {
            tasks = [select Id, CallObject from Task where CallObject = :internalKey and CreatedById=:currentUserId limit 1 for update];
            
            if (tasks.size() == 0 && callId != null) {
                tasks = [select Id, CallObject from Task where CallObject = :callId and CreatedById=:currentUserId limit 1 for update];
            }
        }
                             
        Task task = null;
        String s;
        if (tasks.size() != 0) {
            task = tasks[0];
            s = task.Description;
        }

        return s;
    }
    
    @RemoteAction
    global static boolean replaceInternalKeyWithCallId(String fromNo, String toNo, String callId) {
        Task[] tasks = null;
        
        String internalKey = fromNo + '->' + toNo;
        String currentUserId =UserInfo.getUserId() ;
        tasks = [select Id, CallObject from Task where CallObject = :internalKey and CreatedById=:currentUserId limit 1 for update];
        
        if (tasks.size() == 1 && callId != null) {
            Task task = tasks[0];
            
            task.CallObject = callId;
            update task;
            
            return true;
        } else {
            return false;
        }
    }

    @RemoteAction
    global static String encrypt(String plainText) {
        KeyStorage__c ks = KeyStorage__c.getInstance(UserInfo.getUserId());
        
        Blob cryptoKey;
            
        if (ks.key__c == null) {
            cryptoKey = Crypto.generateAesKey(256);
            ks.key__c = EncodingUtil.base64Encode(cryptoKey);
            upsert ks;
        } else {
            cryptoKey = EncodingUtil.base64Decode(ks.key__c);
        }
        
        Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, Blob.valueOf(plainText));
        
        return EncodingUtil.base64Encode(encryptedData);
    }

    @RemoteAction
    global static String decrypt(String encryptedData) {
        KeyStorage__c ks = KeyStorage__c.getInstance(UserInfo.getUserId());
        
        if (ks.key__c == null) {
            return null;
        }
        
        Blob cryptoKey = EncodingUtil.base64Decode(ks.key__c);
            
        Blob decryptedData = Crypto.decryptWithManagedIV('AES256', cryptoKey, EncodingUtil.base64Decode(encryptedData));
        
        return decryptedData.toString();
    }
}