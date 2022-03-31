/************************************************************
|Author					|       Date        |    Comments
|************************************************************
|Aidar Assylbekov		|    01/??/2022     |    Broken out the KivaPostLoanDraft as an invocable class and help methods here
*/

public class KivaPostLoanRepayments {
    
    
    @InvocableMethod(label='POSTKivaLoanRepayments' description='Make callout to PA2 of loan balance being paid back.' category= 'Kiva Loan')
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
            
            system.debug('====== INSIDE POSTKivaLoanRepayments =======');
            
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
            endpoint = KivaAPIEndpoint_cmdt + '/v3/partner/' + KivaPartnerId +'/repayments';
            
            body = KivaPostLoanRepayments.formJSON_KivaLoanRepayments(input.RepayingKivaLoans);
                
            httpRequest loanBalances = new httpRequest();
            loanBalances.setMethod('POST');
            loanBalances.setEndpoint(endpoint);
            loanBalances.setHeader('Accept', 'application/json');
            loanBalances.setHeader('Content-Type', 'application/json');
            loanBalances.setHeader('Authorization', 'Bearer ' + KivaAccessToken);
            loanBalances.setBody(body);
            httpResponse loanBalancesResponse = (new Http()).send(loanBalances);
            system.debug('response status code: ' + loanBalancesResponse.getStatusCode() );
            system.debug('response body: ' + loanBalancesResponse.getBody() );
        }
    }
    // END of POST

    // Method for forming JSON string for Kiva Loan Repayments
    public static String formJSON_KivaLoanRepayments(List<Id> LoanIds) {
        
        // Variable that holds the result
        string KivaLoanRepaymentsJSONresult;
        
        List<WrapperLoanRepayments> lstWrapperLoanRepayments = new List<WrapperLoanRepayments>();
        List<Kiva_Loan__c> KivaLoans = [SELECT Outstanding_Principal_Balance__c, Total_Loan_Amount__c, Total_Amount_Paid_to_Date__c, Name, Kiva_ID__c, Id FROM Kiva_Loan__c WHERE Id in : LoanIds];
        
        for(Kiva_Loan__c objLoan : KivaLoans) {
            //CONSIDER a try/catch to stop if any fields are null
            WrapperLoanRepayments objWlr = new WrapperLoanRepayments();
            // Later we will need to have a switch to allow two ways of reporting repayment (total paid vs outstanding balance)
            if(objLoan.Outstanding_Principal_Balance__c == NULL ){
            	objWlr.amount = 0;
            } else {
                objWlr.amount = objLoan.Outstanding_Principal_Balance__c;
            }
            // objWlr.amount = objLoan.Total_Loan_Amount__c - objLoan.Total_Amount_Paid_to_Date__c; // THis formula is old, use new field created
            // objWlr.client_id = '0';
            // objWlr.loan_id = objLoan.Name; //This was harder to match... we would need to change the names in KIVA...
            objWlr.loan_id = objLoan.Kiva_ID__c;
            lstWrapperLoanRepayments.add(objWlr);
        }
        
        WrapperRepayments objWr = new WrapperRepayments(lstWrapperLoanRepayments);
        objWr.user_id = '0'; //hardcoded to 0, doesn't matter yet
        
        system.debug(JSON.serialize(objWr));
        
        KivaLoanRepaymentsJSONresult = JSON.serialize(objWr);
        system.debug(KivaLoanRepaymentsJSONresult);       
        return KivaLoanRepaymentsJSONresult;
        
    }
    // End of formJSON_KivaLoanRepayments

    // Wrappers
	// Wrapper Class for POSTing Repayments (looking at Loans records)
    public class WrapperRepayments {
        
        public String user_id {get;set;}
        public List<WrapperLoanRepayments> repayments {get;set;}
        
        public WrapperRepayments(List<WrapperLoanRepayments> loans) {
            
            this.user_id = null;
            repayments = loans;
            
        }
    }
    
    // Wrapper Class for POSTing Repayments    
    public class WrapperLoanRepayments {
        
        public Decimal amount {get;set;}
        // public String client_id  {get;set;}
        public String loan_id  {get;set;}
        
        
        public WrapperLoanRepayments() {
            
            this.amount = null;
            // this.client_id = null;
            this.loan_id = null;
            
        }
    }
    // End of Wrappers
    
    // Input Resources
    public class InputResource {
        
        @InvocableVariable(label='List of Kiva Loan IDs' required='true' description='List of Kiva Loan IDs')
        public List<Id> RepayingKivaLoans;
        
        
        @InvocableVariable(label='Country Label' required='true' description='Country Label')
        public String CountryLabel;
        
    }
    // End of Input Resources
}