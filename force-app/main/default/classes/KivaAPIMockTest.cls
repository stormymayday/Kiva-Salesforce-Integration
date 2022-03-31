/************************************************************
|Author					|       Date        |    Comments
|************************************************************
|Gordon Lau				|    12/23/2021     |    Created class, copied from CAMFED's code
|Gordon Lau				|    01/13/2021     |    Added a Mock response for (GET) loans endpoint

*/

global class KivaAPIMockTest implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
         system.debug('=== Start of HttpResponse method ===');

        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        String body;
        
		// Below are mock responses - IT DOES NOT CHECK FOR CORRECTNESS of the call. IT ONLY RETURN SUCCESSES
		// Future consideration - check the payload and response accordingly

        if (req.getEndpoint().contains('oauth/token')) {
        // Token request
			system.debug('token request');
            body = '{"access_token":"eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ik5BQTdIeWlxIn0.eyJhdWQiOlsiaHR0cHM6Ly9wYXJ0bmVyLWFwaS1zdGFnZS5kazEua2l2YS5vcmciXSwic2NvcGUiOlsiY3JlYXRlOmxvYW5fZHJhZnQiLCJyZWFkOmxvYW5zIl0sImlzcyI6Imh0dHBzOi8vYXV0aC1zdGFnZS5kazEua2l2YS5vcmcvIiwicGFydG5lcklkIjoiNDY4IiwiZXhwIjoxNjMxMjM5MDA1LCJqdGkiOiJlckJYcWlrcmRaOFFQMUpsYzFIeWpvSnlvR1EiLCJjbGllbnRfaWQiOiJZeFAzTkxta3FSMEVEN3hMdUJqNzRwOUJYeW5PYWR6NmwifQ.iJwSVINwFxgl-kmEQ9punQ5U8akSsteJyGNx3duWHtNwLOMQ8j50cG4_LnTzNv56HpNX2tn8bKoi0LwmKyu1ec5wHGM_t3m__f5twTxAeIIcwI2E03l5EFVypRPAAB0G0CsHQcXUcRlawOztzMkZhoFMToMuuJq_uG80m3aJygqySpzXtAP2vbTdCE0Q7qL9KIjna-wU-gROwMhiz-m29DLbc4RvKrpmnx-cZzBJnGB1uYSlsZJ97xIFEYB1dh-xhyTkrbphVnzBfWpZrLEWxQShVd608f52lXmiposvrjkBD4vvB_U2dzGcEUuKcmf5b7r_dqQjqiVMM7FXMYciZw","token_type":"bearer","expires_in":"43199","scope":"create:loan_draft read:loans", ';
            body += '"iss":"https://auth-stage.dk1.kiva.org/", "partnerId":"468", "jti":"erBXqikrdZ8QP1Jlc1HyjoJyoGQ"}';

        // Loans
        } else if (req.getEndpoint().contains('loan_draft')) {
            system.debug('loan_draft');
            body = '{"message":"Loan Draft created successfully","code":"api.success"}';
        // Journals
        } else if (req.getEndpoint().contains('journals')) {
            system.debug('journals');
            body = '{"archive_id":"13817907889169db4dfd366bc7c2225c","confirm_url":"https://partners.stage.kiva.org/pa2/journals/csvConfirm?archive_id=13817907889169db4dfd366bc7c2225c"}';
        // Repayments
        } else if (req.getEndpoint().contains('repayments')) {
            system.debug('repayments');
            body = '{"message":"Repayment created successfully","code":"api.success"}';
        // GET Loans
        } else if (req.getEndpoint().contains('loans')) {
            system.debug('GET Loans');
			// This is the mock JSON for 1 loan.
            body = '{'+
		'    \"total_records\": 117,'+
		'    \"data\": ['+
		'        {'+
		'            \"borrower_count\": 1,'+
		'            \"internal_loan_id\": \"325\",'+
		'            \"internal_client_id\": \"508\",'+
		'            \"partner_id\": \"468\",'+
		'            \"partner\": \"iDE Mozambique\",'+
		'            \"kiva_id\": \"KIVA123\",'+
		'            \"uuid\": \"1E3820F5-8CBF-0001-142A-8E40A058BF40\",'+
		'            \"name\": \"Zacarias Macunde\",'+
		'            \"location\": \"Nhamatanda\",'+
		'            \"status\": \"payingBack\",'+
		'            \"status_detail\": \"xyz blah\",'+
		'            \"loan_price\": \"475.00\",'+
		'            \"loan_local_price\": \"30000.00\",'+
		'            \"loan_currency\": \"MZN\",'+
		'            \"create_time\": 1637832110,'+
		'            \"ended_time\": 1641288110,'+
		'            \"refunded_time\": 1641288110,'+
		'            \"expired_time\": 1641288110,'+
		'            \"defaulted_time\": 0,'+
		'            \"planned_expiration_time\": 1642101624,'+
		'            \"planned_inactive_expire_time\": 1641288110,'+
		'            \"delinquent\": false,'+
		'            \"issue_feedback_time\": 1641288110,'+
		'            \"issue_reported_by\": \"xyz blah\",'+
		'            \"flexible_fundraising_enabled\": false,'+
		'            \"fundedAmount\": \"475.00\"'+
		'        }'+
		'    ]'+
		'}';
        } else {
            system.debug('error');
            body = 'SOME STUPID SHIT HAPPENED... none of the above conditions were met, the endpoint was malfromed';
        }
        system.debug('body: ' + body);

        res.setBody(body);
		system.debug('==== End of HttpResponse method ===');
        
        return res;

    }
}