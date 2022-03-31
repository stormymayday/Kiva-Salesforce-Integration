/************************************************************
|Author					|       Date        |    Comments
|************************************************************
|Aidar Assylbekov		|    01/??/2022     |    Broken out the KivaPostLoanDraft as an invocable class and help methods here
|Gordon Lau				|    02/01/2022     |    Take PA2 Responses and edit kiva loan records with it
|Aidar Assylbekov + GL	|    02/08/2022     |    Bulkified by taking 3 Queries out of the formJSON_KivaLoanDraft Method
*/

public class KivaPostLoanDraft {
    
    @InvocableMethod(label='POSTKivaLoanDraft' description='Make callout to PA2 on selected Kiva Loan Drafts.' category= 'Kiva Loan')
    
    public static void POST(List<InputResource> inputs) {
        system.debug('====== INSIDE POST =======');        
        if(inputs != null && inputs.size() > 0) {
            
            InputResource input = inputs.get(0);
            // There is really only one instance of Input resource being used.                 
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
            system.debug('====== Back from GetAccessToken, INSIDE POST =======');
            
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
            
            endpoint = KivaAPIEndpoint_cmdt + '/v3/partner/' + KivaPartnerId +'/loan_draft';
            
            // DO WE ACTUALLY WANT A FOR LOOP here or just take the first Element? (Test to see if it is null first)   
            // KIVA PA2 only expect one loan draft per call
            // therefore we are looping and making multiple calls
            // however, this can cause performance issues or timeouts 
            // for now, it is iDE's responsibility to only push one loan into the list. 
            // CONSIDER only posting the first loan in the list of IDs
            // OR force fail if list is not size of exactly 1.
            // DECISION on 12/13/21 - for now, just iterate the loop once, so ONLY the first element of the list of ids will post.
            // TEST on 1/22/22 - 2 seems to work. Can do more... but how much more? 
            
            // Converts the ID back into a list of Kiva_Loans__c OLD OLD OLD
            // List<Kiva_Loan__c> KivaDraftLoanstoPost = [SELECT Name, Id, Loan_Draft_Post_Response__c, Loan_Draft_Posted_Date__c, CreatedDate FROM Kiva_Loan__c WHERE Id = : input.KivaLoanDrafts ORDER BY CreatedDate ASC];
            
            // Converts the ID back into a list of Kiva_Loans__c
            List<Kiva_Loan__c> KivaDraftLoanstoPost = [SELECT Name, Id, Loan_Draft_Post_Response__c, Loan_Draft_Posted_Date__c, CreatedDate, Activity_ID__c, client_waiver_signed__c, Profile_Photo_Public_URL__c, Currency_KIVA__c, Loan_Description_for_KIVA__c, Date_Disbursed_API__c, Loan_Group_Name__c, Purpose_of_the_Loan__c, Location_KIVA__c, KIVA_Representative_Code__c, Theme_ID__c FROM Kiva_Loan__c WHERE Id = : input.KivaLoanDrafts ORDER BY CreatedDate ASC];
            // IDEALLY - we (1) DO QUERY ONCE For Loan Participations of IDs (input.KivaLoanDrafts) and store it somewhere convenient 
            List<Kiva_Loan_Participation__c> WANTEDKivaLoanParticipants = [SELECT Loan_amount_final__c, Loan_Amount_needed__c, Kiva_Client_ID__c, Client_First_Name__c, Client_Gender__c, Client_Last_Name__c, Name, Kiva_Loan__r.Name, Kiva_Loan__r.loan_Type__c, iD, Kiva_Loan__c FROM Kiva_Loan_Participation__c WHERE Kiva_Loan__c = : input.KivaLoanDrafts ORDER BY Kiva_Loan__c ASC];
            // and again (2) DO QUERY ONCE for Kiva Transactions of IDs (input.KivaLoanDrafts) and store it also the same way
            List<Kiva_Transaction__c> WANTEDKivaTransactions = [SELECT Due_Date_API__c, Admin_fee_for_Payment__c, Kiva_Payment_due__c, RecordType.Name, Id, Kiva_Loan__c, Name FROM Kiva_Transaction__c WHERE Kiva_Loan__c = : input.KivaLoanDrafts AND RecordType.Name = 'Kiva Invoice' ORDER BY Kiva_Loan__c ASC ];
            // THEN WITHIN the FOR LOOP below, we make LIST of a SUBSET of Transactions and Loan Participation
            
            // Create map to store all the LoanParticipations under their parent Loan records
            Map<Id, List<Kiva_Loan_Participation__c>> LoanToLoanParticipation = new Map<Id, List<Kiva_Loan_Participation__c>>();
            
            for(Kiva_Loan_Participation__c thisKLP : WANTEDKivaLoanParticipants) {
                // Iterate through the list of found KivaLoanParticipation
                if(LoanToLoanParticipation.containsKey(thisKLP.Kiva_Loan__c)) {
                    // there is already a key with the same Kiva Loan record ID
                    List<Kiva_Loan_Participation__c> BufferListKLP = LoanToLoanParticipation.get(thisKLP.Kiva_Loan__c);
                    BufferListKLP.add(thisKLP);
                    LoanToLoanParticipation.put(thisKLP.Kiva_Loan__c, BufferListKLP);
                } else {
                    // there is NO KEY with the Kiva Loan record ID, so add one!
                    LoanToLoanParticipation.put(thisKLP.Kiva_Loan__c, new List<Kiva_Loan_Participation__c> { thisKLP });
                }
            }
            
            
            // Create map to store all the LoanToLoanTransactions under their parent Loan records
            Map<Id, List<Kiva_Transaction__c>> LoanToLoanTransactions = new Map<Id, List<Kiva_Transaction__c>>();
            
            for(Kiva_Transaction__c thisKT : WANTEDKivaTransactions) {
                // Iterate through the list of found KivaLoanParticipation
                if(LoanToLoanTransactions.containsKey(thisKT.Kiva_Loan__c)) {
                    // there is already a key with the same Kiva Loan record ID
                    List<Kiva_Transaction__c> BufferListKLP = LoanToLoanTransactions.get(thisKT.Kiva_Loan__c);
                    BufferListKLP.add(thisKT);
                    LoanToLoanTransactions.put(thisKT.Kiva_Loan__c, BufferListKLP);
                } else {
                    // there is NO KEY with the Kiva Loan record ID, so add one!
                    LoanToLoanTransactions.put(thisKT.Kiva_Loan__c, new List<Kiva_Transaction__c> { thisKT });
                }
            }
            
            // TESTING DOUBLE LOOP
            for(Id key: LoanToLoanTransactions.keySet()){
                List<Kiva_Transaction__c> AnswerListKT = LoanToLoanTransactions.get(key);
                System.debug('key: ' + key );
                for (Kiva_Transaction__c testKT : AnswerListKT){
                    System.debug('testKT.name: ' + testKT.Name + ' testKT.Kiva_Payment_due__c: ' + testKT.Kiva_Payment_due__c);
                }
                // System.debug('key: ' + key + '  Value: ' + LoanToLoanParticipation.get(key));
            }


            
            for(Integer i=0; i<KivaDraftLoanstoPost.size(); i++){           
                system.debug('== START Loop iteration #'+ i +', Call formJSON_KivaLoanDraft ==');
                // Change the ID to post a different loan.. DO WE LET someone post a loan that's already past funding? 
                // We let flow do the error checking? Meaning all loans that get to this point is legit?
                
                body = KivaPostLoanDraft.formJSON_KivaLoanDraft(KivaDraftLoanstoPost[i], 
                                                                LoanToLoanParticipation.get(KivaDraftLoanstoPost[i].Id),
                                                               LoanToLoanTransactions.get(KivaDraftLoanstoPost[i].Id)
                                                               );
                
                
                httpRequest draftloan = new httpRequest();
                draftloan.setMethod('POST');
                draftloan.setEndpoint(endpoint);
                draftloan.setHeader('Accept', 'application/json');
                draftloan.setHeader('Content-Type', 'application/json');
                draftloan.setHeader('Authorization', 'Bearer ' + KivaAccessToken);
                draftloan.setBody(body);
                httpResponse draftloanResponse = (new Http()).send(draftloan);
                system.debug('response status code: ' + draftloanResponse.getStatusCode() );
                system.debug('response body: ' + draftloanResponse.getBody() );
                // Consume the response and update the Kiva Loan record SOMEHOW
                KivaDraftLoanstoPost[i].Loan_Draft_Posted_Date__c = Datetime.Now();
                KivaDraftLoanstoPost[i].Loan_Draft_Post_Response__c = draftloanResponse.getStatusCode() + ' ' + draftloanResponse.getBody();
                system.debug('== END Loop iteration #'+ i +' ==');
                
            }
            update KivaDraftLoanstoPost;
        }
    }
    // End of POSTKivaLoanDraft
    
    // Method for forming JSON string for Kiva Loan Draft
    public static String formJSON_KivaLoanDraft(Kiva_Loan__c ThisKivaLoan, List<Kiva_Loan_Participation__c> KLPin, List<Kiva_Transaction__c> KTin) {
	// public static String formJSON_KivaLoanDraft(Id ThisKivaLoanID) {
        
        // Variable that holds the result
        string KivaJSONresult;
        
        // Kiva Loan Participation
        List<WrapperKivaLoanParticipation> listOfWrapperKivaLoanParticipation = new List<WrapperKivaLoanParticipation>();
        
        for(Kiva_Loan_Participation__c objKivaLoanParticipation: KLPin) {
            
            WrapperKivaLoanParticipation objwKLP = new WrapperKivaLoanParticipation();
            system.debug('Start of kivaLoanParticipation Wrapping');            
            objwKLP.amount = objKivaLoanParticipation.Loan_amount_final__c;
            objwKLP.client_id = objKivaLoanParticipation.Kiva_Client_ID__c;
            objwKLP.first_name = objKivaLoanParticipation.Client_First_Name__c;
            objwKLP.gender = objKivaLoanParticipation.Client_Gender__c.toLowerCase(); //Kiva PA2 accepts lower case only
            objwKLP.last_name = objKivaLoanParticipation.Client_Last_Name__c;
            
            If(objKivaLoanParticipation.Kiva_Loan__r.loan_Type__c == 'Individual'){
                //NOTE: for Individual loans, we should use the NAME of the parent Kiva Loan record.
                objwKLP.loan_id = objKivaLoanParticipation.Kiva_Loan__r.Name;
            } else {
                //NOTE: for Group loans, we should use 
                objwKLP.loan_id = objKivaLoanParticipation.Name;
                system.debug('??? the loan ID: ' + objwKLP.loan_id);   
            }
            
            listOfWrapperKivaLoanParticipation.add(objwKLP);
            system.debug('End of kivaLoanParticipation Wrapping');
        }
        
        // Kiva Transactions
        List<WrapperKivaTransactions> listOfWrapperKivaTransactions = new List<WrapperKivaTransactions>();
        
        for(Kiva_Transaction__c objKivaTransactions: KTin) {
            
            WrapperKivaTransactions objwKT = new WrapperKivaTransactions();
            system.debug('Start of kivaTransaction Wrapping');
            // handle it with validation rules such that invoices must have the following fields filled in.
            // CONSIDER - try/throw for more robust code so that it will fail to send to PA2 if any invoices are misshapen
            objwKT.date_x = objKivaTransactions.Due_Date_API__c;
            objwKT.interest = objKivaTransactions.Admin_fee_for_Payment__c;
            objwKT.principal = objKivaTransactions.Kiva_Payment_due__c;
            
            
            listOfWrapperKivaTransactions.add(objwKT);
            system.debug('End of kivaTransaction Wrapping');
        }
        
        // Kiva Loan
        Kiva_Loan__c objKivaLoan = ThisKivaLoan;
        WrapperKivaLoan objwKL = new WrapperKivaLoan(listOfWrapperKivaLoanParticipation, listOfWrapperKivaTransactions);
        
        // CONSIDER LOGIC HERE TO DIFFERENTIATE BETWEEN INDIVIDUAL LOAN vs GROUP LOAN using the Loan_Type__c
        
        objwKL.activity_id = objKivaLoan.Activity_ID__c;
        objwKL.client_waiver_signed = objKivaLoan.client_waiver_signed__c;
        objwKL.currency_x = objKivaLoan.Currency_KIVA__c;
        objwKL.description = objKivaLoan.Loan_Description_for_KIVA__c;
        // Manually Setting Description Language Id to 1
        objwKL.description_language_id = 1;    
        objwKL.disburse_time = objKivaLoan.Date_Disbursed_API__c;
        objwKL.group_name = objKivaLoan.Loan_Group_Name__c;
        // This uses the profile photo PUBLIC URL - which needs a different flow to run FIRST to generate 
        objwKL.image_url = objKivaLoan.Profile_Photo_Public_URL__c;
        // this internal client id shows as the loan_group_name
        objwKL.internal_client_id = objKivaLoan.Loan_Group_Name__c;
        objwKL.internal_loan_id = objKivaLoan.Name;
        objwKL.loanuse = objKivaLoan.Purpose_of_the_Loan__c;
        objwKL.location = objKivaLoan.Location_KIVA__c;
        
        // Manually Setting Not_Pictured array to true at index 0 (we will just ignore this)
        // objwKL.not_pictured[0] = true;
        
        objwKL.rep_person_id = objKivaLoan.KIVA_Representative_Code__c; //this is a formula field hardcoded to 1
        
        // Converting String to Integer and assigning the value
        objwKL.theme_type_id = integer.valueof(objKivaLoan.Theme_ID__c);
        
        KivaJSONresult = JSON.serialize(objwKL);
        KivaJSONresult = KivaJSONresult.replaceAll('"date_x"', '"date"'); // change it back to date for KIVA PA2
        KivaJSONresult = KivaJSONresult.replaceAll('"currency_x"', '"currency"'); // change it back to currency for KIVA PA2
        
        // Return the formed JSON string 
        system.debug(KivaJSONresult);       
        return KivaJSONresult;
        
    }
    // End of formJSON_KivaLoanDraft
    
    // Wrappers
    public class WrapperKivaLoan {
        
        // Kiva Loan attributes
        public String activity_id {get;set;}
        public Boolean client_waiver_signed {get;set;}
        public String currency_x {get;set;} //Reserved name
        public String description {get;set;}
        public Integer description_language_id {get;set;}
        public String disburse_time {get;set;}
        public String group_name {get;set;}
        public String image_url {get;set;}
        public String internal_client_id {get;set;}
        public String internal_loan_id {get;set;}
        public String loanuse {get;set;}
        public String location {get;set;}        
        
        // public List<Boolean> not_pictured {get;set;}
        
        public Decimal rep_person_id {get;set;}
        
        public Integer theme_type_id {get;set;}
        
        public List<WrapperKivaLoanParticipation> entreps {get;set;}
        public List<WrapperKivaTransactions> schedule {get;set;}
        
        public WrapperKivaLoan(List<WrapperKivaLoanParticipation> listOfKivaLoanParticipants, List<WrapperKivaTransactions> listOfKivaTranscations) {
            
            this.activity_id = null;
            this.client_waiver_signed = true;
            this.currency_x = null; //again to avoid the reserved name
            this.description = null;
            this.description_language_id = null;
            this.disburse_time = null;
            this.group_name = null;
            this.image_url = null;
            this.internal_client_id = null;
            this.internal_loan_id = null;
            this.loanuse = null;
            this.location = null;            
            
            // this.not_pictured = null;  //PA2 expects an array of boolean to say which client is pictured or not. We just ignore this. 
            // The Kiva coordinator of each country will have to manually sort this out in PA2 prior to post.          
            
            this.rep_person_id = null;
            
            this.theme_type_id = null;
            
            entreps = listOfKivaLoanParticipants;
            schedule = listOfKivaTranscations;
            
        }
        
    }
    
    public class WrapperKivaLoanParticipation {
        
        // Kiva Loan Participation attributes
        public Decimal amount {get;set;}
        public String client_id {get;set;}
        public String first_name {get;set;}
        public String gender {get;set;}
        public String last_name {get;set;}
        public String loan_id {get;set;}
        
        
        public WrapperKivaLoanParticipation() {
            
            this.amount = null;
            this.client_id = null;
            this.first_name = null;
            this.gender = null;
            this.last_name = null;
            this.loan_id = null;
            
        }
        
    }
    
    public class WrapperKivaTransactions {
        
        // Kiva Loan Transaction attributes
        public String date_x {get;set;} // avoid reserved name "date"
        public Decimal interest {get;set;}
        public Decimal principal {get;set;}
        
        public WrapperKivaTransactions() {
            
            this.date_x = null;
            this.interest = null;
            this.principal = null;
            
        }
        
    }
    // End of Wrappers
    
    // Input Resources
    public class InputResource {
        
        // Decided on 1/25/22 to take a list of IDs as parameter
        // Because it only adds one more query and there might be some sort of operations like adding/averaging as we iterate through the 
        // list of found records... like setting a flag... 
        
        @InvocableVariable(label='List of Kiva Loan IDs' required='true' description='List of Kiva Loan IDs')
        public List<Id> KivaLoanDrafts;
                
        @InvocableVariable(label='Country Label' required='true' description='Country Label')
        public String CountryLabel;
        
    }
    // End of Input Resources
}