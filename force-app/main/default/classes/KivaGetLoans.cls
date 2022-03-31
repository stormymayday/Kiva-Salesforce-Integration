/************************************************************
|Author					|       Date        |    Comments
|************************************************************
|Aidar Assylbekov		|    01/??/2022     |    Broken out the KivaPostLoanDraft as an invocable class and help methods here
|Gordon Lau				|    02/01/2022     |    Added lines to pull more data from response JSON and update the matching record
*/

public class KivaGetLoans {
    
    @InvocableMethod(label='Get Kiva Loans' description='Method for GETTING Kiva Loans' category='Kiva Loan')
    public static void GET(List<InputResource> inputs) {
        
        if(inputs != null && inputs.size() > 0) {
            
            system.debug('====== INSIDE GET =======');
            
            InputResource input = inputs.get(0);
            
            // variables to store token response
            string KivaAccessToken = '';
            string KivaAccessScope = '';
            string KivaAccessIss = '';
            string KivaPartnerId = '';
            string KivaTokenJti = '';
            string KivaMessage = '';
            string KivaErrorCode = '';
            
            // Create map to hold the JWT JSON response
            // call the GetAccessToken method
            Map<String, Object> ATResponseMap = KivaGetAccessToken.GetAccessToken(input.CountryLabel);
            
            // This PROCESS checks the Access Token -is there in the map	
            if ((boolean)ATResponseMap.containsKey('access_token')) {
                
                system.debug('response OK');           
                KivaAccessToken = (string)ATResponseMap.get('access_token');
                system.debug('access token: ' + KivaAccessToken );
                
                KivaAccessScope = (string)ATResponseMap.get('scope');
                system.debug('access Scope: ' + KivaAccessScope );
                
                KivaAccessIss = (string)ATResponseMap.get('iss');
                system.debug('Issuer: ' + KivaAccessIss );
                
                KivaPartnerId = (string)ATResponseMap.get('partnerId');
                system.debug('Partner ID: ' + KivaPartnerId );
                
                KivaTokenJti = (string)ATResponseMap.get('jti');
                system.debug('Token jti: ' + KivaTokenJti );
                
            } else {
                // MAYBE SET AN ERROR FLAG SOMEWHERE HERE SO it doesn't attempt to make any further calls
                system.debug('response error');
                KivaMessage = (string)ATResponseMap.get('error');
                system.debug('error: ' + KivaMessage );
                KivaErrorCode = (string)ATResponseMap.get('error_description');
                system.debug('error description: ' + KivaErrorCode );
                
            }    
            
            //system.debug('From this point on, if there are no errors, you can the actual POST/GET calls to get stuff done');
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            
            // Fetching KIVA API Endpoint URL from Custom Metadata
            List<Auth_Credentials__mdt> kivaCredentials = [SELECT API_Audience_Endpoint_Part__c FROM Auth_Credentials__mdt WHERE Label = : input.CountryLabel LIMIT 1];
            // Kiva_API_Endpoint__c variable declaration and assignment
            string KivaAPIEndpoint_cmdt = kivaCredentials[0].API_Audience_Endpoint_Part__c;
            
            string Queryinput = '';
            if (input.queryValue != null){
                system.debug('query: '+ input.queryValue);
                Queryinput = '&query='+ input.queryValue;
                system.debug('query: '+ Queryinput);
            }
            string GETEndpoint = KivaAPIEndpoint_cmdt + '/v3/partner/' + KivaPartnerId +'/loans?limit='+ input.limitValue +'&offset='+ input.offsetValue +'&status='+ input.statusValue + Queryinput;
            
            request.setEndpoint(GETEndpoint);            
            system.debug('Endpoint set: '+ GETEndpoint);
            
            request.setMethod('GET');
            request.setHeader('Accept', 'application/json');
            request.setHeader('Authorization', 'Bearer ' + KivaAccessToken);
            HttpResponse response = http.send(request);
            
            // If the request is successful, parse the JSON response.
            if(response.getStatusCode() == 200) {
                
                // Instantiating instance of the JSON2Apex class
                KivaJSON2Apex obj = KivaJSON2Apex.parse(response.getBody());
                
                // Placeholder List of Kiva Loans (for later when we know enough to find the ID)
                List <Kiva_Loan__c> KivaLoans2Update;
                List <String> LoansIDreturned = new List<String>() ;
                
                // Assigning values to the placeholder object
                for(integer i = 0; i < obj.data.size(); i++) {
                   LoansIDreturned.add(obj.data[i].kiva_id); // Uses Kiva ID
                }
                
                KivaLoans2Update = [SELECT Loan_Price__c, Id, Name, Kiva_ID__c, LATEST_Data_Pull_from_Kiva__c FROM Kiva_Loan__c WHERE Kiva_ID__c in: LoansIDreturned];
                System.debug(KivaLoans2Update);
                
                // Creating List of JSON2Apex.Data - note this is something we can pull data out of later.
                List<KivaJSON2Apex.Data> json2ApexListData = New List<KivaJSON2Apex.Data>();
                // Assigning values from obj to the new List
                for(KivaJSON2Apex.Data kivaLoan : obj.data){
                    
                    json2ApexListData.add(kivaLoan);
                    
                }
                
                // Create a map of NAME to INDEX of Json2apexListData
                Map<String, Integer> json2ApexMapData = New Map<String, Integer>();
                
                for(integer i = 0; i < json2ApexListData.size(); i++){
                    json2ApexMapData.put(json2ApexListData[i].kiva_id, i);
                }
                
                // Creating a map from the KivaLoans2Update List 
                Map<String, Kiva_Loan__c> namesOfKivaLoans = New Map<String, Kiva_Loan__c>();
                
                // Assigning values to the namesOfKivaLoans map
                for(Kiva_Loan__c kivaLoan : KivaLoans2Update){
                    namesOfKivaLoans.put(kivaLoan.Kiva_ID__c, kivaLoan);                    
                }
                
                // Iterating through the List and assigning values from the Map
                for(Kiva_Loan__c loan : KivaLoans2Update) {
                    
                    if(json2ApexMapData.containsKey(loan.Kiva_ID__c)) {
                        
                        system.debug('Loan Name (autonumber): '+ loan.Name + ' Loan Record Id: ' + loan.Id);
                        
                        integer TEMP_index = json2ApexMapData.get(loan.Kiva_ID__c);
                        loan.Loan_Price__c = decimal.valueOf(json2ApexListData[TEMP_index].loan_price);
                        loan.LATEST_Data_Pull_from_Kiva__c = datetime.now();
                        // AIDAR - please see if you can improve this using Ternary Operator
                        loan.Create_Time_KIVA__c = datetime.newinstance(long.valueOf(json2ApexListData[TEMP_index].create_time)); // time
                        if(json2ApexListData[TEMP_index].defaulted_time != NULL){
                            loan.Defaulted_Time_KIVA__c = datetime.newinstance(long.valueOf(json2ApexListData[TEMP_index].defaulted_time)); // time
                        }
                        if(json2ApexListData[TEMP_index].delinquent != NULL){
                            loan.Delinquent_per_KIVA__c = json2ApexListData[TEMP_index]?.delinquent; // boolean
                        }
                        if(json2ApexListData[TEMP_index].ended_time != NULL){
                            loan.End_Date__c = datetime.newinstance(long.valueOf(json2ApexListData[TEMP_index].ended_time)); // time
                        }
                        if(json2ApexListData[TEMP_index].expired_time != NULL){
                            loan.Expired_Time_KIVA__c = datetime.newinstance(long.valueOf(json2ApexListData[TEMP_index].expired_time)); // time
                        }
                        if(json2ApexListData[TEMP_index].issue_feedback_time != NULL){                        
                            loan.Issue_Feedback_Time_KIVA__c = datetime.newinstance(long.valueOf(json2ApexListData[TEMP_index].issue_feedback_time)); // time
                        }
                        if(json2ApexListData[TEMP_index].issue_reported_by != NULL){                        
                            loan.Issue_Reported_by__c = json2ApexListData[TEMP_index].issue_reported_by; // string
                        }
                        if(json2ApexListData[TEMP_index].planned_expiration_time != NULL){                        
                            loan.Planned_Expiration_Time_KIVA__c = datetime.newinstance(long.valueOf(json2ApexListData[TEMP_index].planned_expiration_time)); // time
                        }
                        if(json2ApexListData[TEMP_index].planned_inactive_expire_time != NULL){
                            loan.Planned_Inactive_Expire_Time_KIVA__c = datetime.newinstance(long.valueOf(json2ApexListData[TEMP_index].planned_inactive_expire_time)); // time
                        }
                        if(json2ApexListData[TEMP_index].refunded_time != NULL){                        
                            loan.Refunded_Time_KIVA__c = datetime.newinstance(long.valueOf(json2ApexListData[TEMP_index].refunded_time)); // time
                        }
                        if(json2ApexListData[TEMP_index].status != NULL){
                            loan.Kiva_Status__c = json2ApexListData[TEMP_index].status; // string
                        }
                        if(json2ApexListData[TEMP_index].status_detail != NULL){
                            loan.Status_Detail_KIVA__c = json2ApexListData[TEMP_index]?.status_detail; // string
                        }
                        loan.UUID_Kiva__c = json2ApexListData[TEMP_index]?.uuid; // string
                        
                        /* MAYBE For RECONCILATION? 
                        loan.fieldNAME__c = decimal.valueOf(json2ApexListData[TEMP_index].borrower_count); // int - 
                        loan.CurrencyIsoCode = json2ApexListData[TEMP_index].loan_currency; // string
                        loan.fieldNAME__c = decimal.valueOf(json2ApexListData[TEMP_index].loan_local_price); // decimal
                        
                        loan.fieldNAME__c = json2ApexListData[TEMP_index].partner; // This is the name of the org - no need
                        loan.fieldNAME__c = json2ApexListData[TEMP_index].partner_id; // This is the code eg. 468 - no need
                        loan.fieldNAME__c = json2ApexListData[TEMP_index].name; // lead borrower name - already there as lookup
                        loan.Location_KIVA__c = json2ApexListData[TEMP_index].location; // location - READ ONLY
                        loan.fieldNAME__c = json2ApexListData[TEMP_index].internal_client_id; // string
                        loan.Name = json2ApexListData[TEMP_index].internal_loan_id; // Name field is AutoNumber - cannot be written to
                        loan.Kiva_ID__c = json2ApexListData[TEMP_index].kiva_id; // No resason to update the ID we just 
                        */
                    }
                    
                    system.debug(loan.Loan_Price__c);
                    
                }
                
                // Updating Records
                update KivaLoans2Update;
                
            }
            
        }
        
    }    
    // End of GETKivaLoans
    
    // Input Resources
    public class InputResource {
        
        @InvocableVariable(label='Limit Value' required='true' description='Limit Value')
        public String limitValue;
        
        @InvocableVariable(label='Offset Value' required='true' description='Offset Value')
        public String offsetValue;
        
        @InvocableVariable(label='Status Value' required='true' description='Status Value')
        public String statusValue;
        
        @InvocableVariable(label='Query String' required='false' description='Query String (optional)')
        public String queryValue;
        
        @InvocableVariable(label='Country Label' required='true' description='Country Label')
        public String CountryLabel;
        
    }
    // End of Input Resources
    
}