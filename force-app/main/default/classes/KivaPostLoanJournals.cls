/************************************************************
|Author					|       Date        |    Comments
|************************************************************
|Aidar Assylbekov		|    01/??/2022     |    Broken out the KivaPostLoanDraft as an invocable class and help methods here
*/

public class KivaPostLoanJournals {
    
    @InvocableMethod(label='POSTKivaLoanJournals' description='Take a list of all journal ready to post and sent to PA2 with one call' category= 'Kiva Journals')
    public static void POST(List<InputResource> inputs) {
        
        if(inputs != null && inputs.size() > 0) {
            
            system.debug('====== INSIDE POST =======');
            
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
            
            system.debug('From this point on, if there are no errors, you can the actual POST/GET calls to get stuff done');
            string body = '';
            string endpoint = '';
            
            // Fetching KIVA API Endpoint URL from Custom Metadata
            List<Auth_Credentials__mdt> kivaCredentials = [SELECT API_Audience_Endpoint_Part__c FROM Auth_Credentials__mdt WHERE Label = : input.CountryLabel LIMIT 1];
            // Kiva_API_Endpoint__c variable declaration and assignment
            string KivaAPIEndpoint_cmdt = kivaCredentials[0].API_Audience_Endpoint_Part__c;     
            endpoint = KivaAPIEndpoint_cmdt + '/v3/partner/' + KivaPartnerId +'/journals';
            
            body = KivaPostLoanJournals.formJSON_KivaJournals(input.JournalsForPosting);
            
            system.debug('Endpoint: ' + endpoint );		
            httpRequest journalinfo = new httpRequest();
            journalinfo.setMethod('POST');
            journalinfo.setEndpoint(endpoint);
            journalinfo.setHeader('Accept', 'application/json');
            journalinfo.setHeader('Content-Type', 'application/json');
            journalinfo.setHeader('Authorization', 'Bearer ' + KivaAccessToken);
            journalinfo.setBody(body);
            httpResponse journalResponse = (new Http()).send(journalinfo); // This is a nonstatic method???
            system.debug('response status code: ' + journalResponse.getStatusCode() );
            system.debug('response body: ' + journalResponse.getBody() );
            
            string ConfirmURLforBatch = '';
            // Deserializes the JSON string into collections of primitive data types.
            Map<String, Object> ResponseMap = (Map<String, Object>) JSON.deserializeUntyped(journalResponse.getBody());
            
            if(journalResponse.getStatusCode() == 200) {
                // Response
                system.debug('Response is GOOD!');
                ConfirmURLforBatch = (string)ResponseMap.get('confirm_url');
                system.debug('Confirmation URL is: ' + ConfirmURLforBatch );        
            	// LOOP - for all the IDs of the journal that was fed in, update the field for Confirmation URL
            	List<kiva_journal__c> JournalsToUpdate = [SELECT Id, URL_for_confirmation__c,Date_synced_to_Kiva__c FROM kiva_journal__c WHERE Id in: input.JournalsForPosting];
                for(kiva_journal__c ThisJournal : JournalsToUpdate){
                    system.debug('This Journal iD is: ' + ThisJournal.Id );
                    ThisJournal.URL_for_confirmation__c = ConfirmURLforBatch;
                    ThisJournal.Date_synced_to_Kiva__c = Date.TODAY();
                }
                update JournalsToUpdate;
                
            } else {
                system.debug('Response is BAD!!');
            }
            

            
            
        }
    }    
    // End of POST
    
    // Method for POSTing Kiva Journals
    public static String formJSON_KivaJournals(List<Id> JournalIds) {
        
        // Variable that holds the result
        string KivaJournalsJSONresult;
        
        List<WrapperClientJournals> lstWrapperClientJournals = new List<WrapperClientJournals>();
        
        List<Kiva_Journal__c> KivaJournals = [SELECT Final_Body_Text__c, URL_for_Attached_Image__c, Client_ID__c, Kiva_Loan__r.Name, Kiva_Loan__r.Kiva_Id__c, Subject__c FROM Kiva_Journal__c WHERE Id in : JournalIds];
        
        for(Kiva_Journal__c objJournal : KivaJournals) {
            
            WrapperClientJournals objWcj = new WrapperClientJournals();
            // CONSIDER a try/catch here to stop if any fields are null (maybe pictures can be blank?)
            objWcj.body = objJournal.Final_Body_Text__c;
            objWcj.image_url = objJournal.URL_for_Attached_Image__c;
            objWcj.internal_client_id = objJournal.Client_ID__c;
            // objWcj.internal_loan_id = objJournal.Kiva_Loan__r.Name;
            objWcj.internal_loan_id = objJournal.Kiva_Loan__r.Kiva_Id__c; 
            objWcj.subject = objJournal.Subject__c;
            
            lstWrapperClientJournals.add(objWcj);
        }
        
        WrapperJournals objWr = new WrapperJournals(lstWrapperClientJournals);
        
        system.debug(JSON.serialize(objWr));
        
        KivaJournalsJSONresult = JSON.serialize(objWr);
        system.debug(KivaJournalsJSONresult);       
        return KivaJournalsJSONresult;
        
    }
    // End of formJSON_KivaLoanJournals
    
    // Wrappers
    // Wrapper Class for POSTing Journals 
    public class WrapperJournals {
        
        public List<WrapperClientJournals> journals {get;set;}
        
        public WrapperJournals(List<WrapperClientJournals> clientJournals) {
            
            journals = clientJournals;
            
        }
    }
    
    // Wrapper Class for POSTing Journals    
    public class WrapperClientJournals {
        
        public String body {get;set;}
        public String image_url {get;set;}
        public String internal_client_id {get;set;}
        public String internal_loan_id {get;set;}
        public String subject {get;set;}
        
        
        public WrapperClientJournals() {
            
            this.body = null;
            this.image_url = null;
            this.internal_client_id = null;
            this.internal_loan_id = null;
            this.subject = null;
            
            
        }
    }
    // End of Wrappers
    
    // Input Resources
    public class InputResource {
        
        @InvocableVariable(label='Journals For Posting' required='true' description='Journals For Posting')
        public List<Id> JournalsForPosting;
        
        
        @InvocableVariable(label='Country Label' required='true' description='Country Label')
        public String CountryLabel;
        
    }
    // End of Input Resources
}