public class KivaGetAccessToken {
    
    public Static Map<String, Object> GetAccessToken(string CountryLabel) {    
        // Class for obtaining Access Token - this returns a map that needs to be deserialized (allows for better error handling)
        // the Endpoint will now be passed in as an argument. So that we can control if it is going to Stage or real PA2
        
        system.debug('====== INSIDE GetAccessToken Method ======== ');
        // Set variables to form the initial JWT Client Credential flow 
        
        // Querying ClientId and ClientSecret from Custom Metadata Type for the given Country Label       
        List<Auth_Credentials__mdt> kivaCredentials = [SELECT Client_Id__c, Client_Secret__c, Auth_Endpoint__c, API_Audience_Endpoint_Part__c FROM Auth_Credentials__mdt WHERE Label = : CountryLabel LIMIT 1];
        
        // ClientId and ClientSecret variable declaration and assignment
        string ClientId_cmdt = kivaCredentials[0].Client_Id__c;
        string ClientSecret_cmdt = kivaCredentials[0].Client_Secret__c;
        string KivaAuthEndpoint_cmdt = kivaCredentials[0].Auth_Endpoint__c;
        string KivaAPIEndpoint_cmdt = kivaCredentials[0].API_Audience_Endpoint_Part__c;
        
        // Set the scope - for simplicity we will make this token able to DO IT ALL. (Consider restricting it later.)
        // ***NOTE, consider adding a new argument so that there is a switch of the AUDIENCE parameter below (stage and production)
        // string body = 'grant_type=client_credentials&audience=https://partner-api-stage.dk1.kiva.org&scope=create:journal_update create:loan_draft create:repayment read:loans';
        string body = 'grant_type=client_credentials&audience=' + KivaAPIEndpoint_cmdt + '&scope=create:journal_update create:loan_draft create:repayment read:loans';
        
        // variables to store token response if we are successful (can get rid of these variables)
        string KivaAccessToken = '';
        string KivaAccessScope = '';
        string KivaAccessIss = '';
        string KivaPartnerId = '';
        string KivaTokenJti = '';
        
        Blob headerValue = Blob.valueOf(ClientId_cmdt + ':' + ClientSecret_cmdt);
        String authorizationHeader = 'Basic ' +  EncodingUtil.base64Encode(headerValue);
        system.debug('Encoder Value: ' + EncodingUtil.base64Encode(headerValue));
        
        // Construct the request
        http http = new http();
        httpRequest request = new httpRequest();
        request.setMethod('POST');
        request.setEndpoint(KivaAuthEndpoint_cmdt);
        request.setHeader('Accept', 'application/json');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Authorization', authorizationHeader);
        request.setBody(body);
        
        // Send the request
        httpResponse Res = (new Http()).send(request); //created an instance of http
        system.debug('response status code ' + Res.getStatusCode() );
        
        // Deserializes the JSON string into collections of primitive data types.
        Map<String, Object> ResponseMap = (Map<String, Object>) JSON.deserializeUntyped(Res.getBody());
        
        
        // This part below is to allow for debugging with the method (can get rid of this IF)
        if (Res.getStatusCode() == 200) {
            // Success, see what the parsed response is
            system.debug('response OK ' + Res.getBody() );
            
            KivaAccessToken = (string)ResponseMap.get('access_token');
            system.debug('access token: ' + KivaAccessToken );
            
            KivaAccessScope = (string)ResponseMap.get('scope');
            system.debug('access Scope: ' + KivaAccessScope );
            
            KivaAccessIss = (string)ResponseMap.get('iss');
            system.debug('Issuer: ' + KivaAccessIss );
            
            KivaPartnerId = (string)ResponseMap.get('partnerId');
            system.debug('Partner ID: ' + KivaPartnerId );
            
            KivaTokenJti = (string)ResponseMap.get('jti');
            system.debug('Token jti: ' + KivaTokenJti );
            
        } else {
            // something is wrong - see the response
            system.debug('response error ' + Res.getBody() );
            // determine cases and throw the right exceptions here... Let Aidar work on this 
            // STOP EXECUTION.  
            // see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_exception_trycatch_example.htm
            
        }    
        // Return the map to the level that called it for JSON Deserialization
        return ResponseMap;
        
    }
}