/************************************************************
|Author					|       Date        |    Comments
|************************************************************
|Aidar Assylbekov		|    12/22/2021     |    Created setup() method
|Gordon Lau				|    12/23/2021     |    Created testPOSTLoanDraft(), testPOSTRepayment() , testPOSTJournals() method
|Aidar Assylbekov		|    01/14/2022     |    Created testGETLoans() 
|Gordon Lau				|    01/25/2022     |    Modified class to test invocable methods
*/

@isTest
public class KivaTest {
    
    private static Kiva_Loan__c testKivaLoan;
    private static Kiva_Journal__c testKivaJournal;
    
    
    private static void setup()
    {
        system.debug('======== setup begins ========');
        // ********** CREATE TEST RECORDS IN RUNTIME ********
        // Creating Test Kiva Client A
        Kiva_Client__c testKivaClientA = new Kiva_Client__c (
            Client_First_Name__c = 'Test Client A First Name',
            Client_Last_Name__c = 'Test Client A Last Name',
            Client_Phone__c = '1234567890',
            Gender__c = 'Female'
        );
        insert testKivaClientA;
        
        // Creating Test Kiva Client B
        Kiva_Client__c testKivaClientB = new Kiva_Client__c (
            Client_First_Name__c = 'Test Client B First Name',
            Client_Last_Name__c = 'Test Client B Last Name',
            Client_Phone__c = '0987654321',
            Gender__c = 'Male'
        );
        insert testKivaClientB;
        
        // Creating Test Kiva Loan
        Id MozambiqueKivaLoanRecordType = Schema.SObjectType.Kiva_Loan__c.getRecordTypeInfosByName()
            .get('Mozambique').getRecordTypeId();
        
        KivaTest.testKivaLoan = new Kiva_Loan__c (
            Main_Applicant_Name__c = testKivaClientA.id,
            Kiva_ID__c = 'KIVA123',
            Loan_Type__c = 'Group',
            Loan_Status__c = 'Approved',
            Category_of_Loan__c = 'Agricultural Equipment,96',
            Sector__c = 'Agriculture',
            Activity__c = 'Agriculture,120',
            Profile_Photo_Public_URL__c = 'https://upload.wikimedia.org/wikipedia/commons/5/5a/John_Doe%2C_born_John_Nommensen_Duchac.jpg',
            Loan_Application_Date__c = date.newInstance(2021, 12, 13),
            Date_Disbursed__c = DateTime.newInstance(2021, 12, 1, 7, 8, 16),
            Loan_Description_for_KIVA__c = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
            description_language_id__c = 'English',
            Loan_Group_Name__c = 'Test Group Name',
            RecordTypeId = MozambiqueKivaLoanRecordType
        );
        insert testKivaLoan;
        
        // Creating Test Kiva Participation A
        Id MozambiqueKivaLoanParticipationRecordType = Schema.SObjectType.Kiva_Loan_Participation__c.getRecordTypeInfosByName()
            .get('Mozambique').getRecordTypeId();
        
        Kiva_Loan_Participation__c testKivaLoanParticipationA = new Kiva_Loan_Participation__c (
            Kiva_Client__c = testKivaClientA.id,
            Kiva_Loan__c = testKivaLoan.id,
            Loan_amount_final__c = 20000,
            Loan_Amount_needed__c = 20000,
            RecordTypeId = MozambiqueKivaLoanParticipationRecordType
        );
        insert testKivaLoanParticipationA;
        
        // Creating Test Kiva Participation B         
        Kiva_Loan_Participation__c testKivaLoanParticipationB = new Kiva_Loan_Participation__c (
            Kiva_Client__c = testKivaClientB.id,
            Kiva_Loan__c = testKivaLoan.id,
            Loan_amount_final__c = 40000,
            Loan_Amount_needed__c = 40000,
            RecordTypeId = MozambiqueKivaLoanParticipationRecordType
        );
        insert testKivaLoanParticipationB;
        
        // Kiva Transaction Record Type Invoice
        Id InvoiceKivaTransactionRecordType = Schema.SObjectType.Kiva_Transaction__c.getRecordTypeInfosByName()
            .get('Kiva Invoice').getRecordTypeId();
        
        // Creating Test Kiva Transaction First Invoice
        Kiva_Transaction__c testKivaTransactionFirstInvoice = new Kiva_Transaction__c (
            Kiva_Loan__c = testKivaLoan.id,
            Date_due__c = date.newInstance(2022, 1, 1),
            Total_of_scheduled_Payments__c = 3,
            Payment_Order__c = 1,
            Admin_fee_for_Payment__c = 2000,
            Kiva_Payment_due__c = 20000,
            RecordTypeId = InvoiceKivaTransactionRecordType
        );
        insert testKivaTransactionFirstInvoice;
        
        // Creating Test Kiva Transaction Second Invoice
        Kiva_Transaction__c testKivaTransactionSecondInvoice = new Kiva_Transaction__c (
            Kiva_Loan__c = testKivaLoan.id,
            Date_due__c = date.newInstance(2022, 2, 1),
            Total_of_scheduled_Payments__c = 3,
            Payment_Order__c = 2,
            Admin_fee_for_Payment__c = 2000,
            Kiva_Payment_due__c = 20000,
            RecordTypeId = InvoiceKivaTransactionRecordType
        );
        insert testKivaTransactionSecondInvoice;
        
        // Creating Test Kiva Transaction Third Invoice
        Kiva_Transaction__c testKivaTransactionThirdInvoice = new Kiva_Transaction__c (
            Kiva_Loan__c = testKivaLoan.id,
            Date_due__c = date.newInstance(2022, 3, 1),
            Total_of_scheduled_Payments__c = 3,
            Payment_Order__c = 3,
            Admin_fee_for_Payment__c = 2000,
            Kiva_Payment_due__c = 20000,
            RecordTypeId = InvoiceKivaTransactionRecordType
        );
        insert testKivaTransactionThirdInvoice;
        
        // Creating Test Kiva Transaction Type Payment In
        Id PaymentInKivaTransactionRecordType = Schema.SObjectType.Kiva_Transaction__c.getRecordTypeInfosByName()
            .get('Kiva Payment In').getRecordTypeId();
        
        Kiva_Transaction__c testKivaTransactionPaymentIn = new Kiva_Transaction__c (
            Kiva_Loan__c = testKivaLoan.id,
            Payment_received_date__c = date.newInstance(2022, 2, 8),
            Payment_received__c = 2222,
            RecordTypeId = PaymentInKivaTransactionRecordType
        );
        insert testKivaTransactionPaymentIn;
        
        // Creating Test Kiva Journal
        KivaTest.testKivaJournal = new Kiva_Journal__c (
            Kiva_Loan__c = testKivaLoan.id,
            Date_of_Entry__c = date.newInstance(2021, 12, 21),
            Final_Body_Text__c = 'Test Final Body Text',
            Subject__c = 'Test Subject',
            URL_for_Attached_Image__c = 'https://i.kym-cdn.com/entries/icons/facebook/000/005/608/nyan-cat-01-625x450.jpg'        
        );
        insert testKivaJournal;
        
        system.debug('======== setup end ========');        
        // ************* Call METHODS to execute tests
    }
    
    static testMethod void testPOSTLoanDraft() {
        Test.setMock(HttpCalloutMock.class, new KivaAPIMockTest());
        // calls the setup above to create dummy records in runtime
        KivaTest.setup();
        List<Id> TESTLoanDraftIds = new List<Id>();
        TESTLoanDraftIds.add(KivaTest.testKivaLoan.id);
        
        Test.startTest();
        // Make the calls!
        
        List<Id> TESTLoanIdsfromFLOW = new List<Id>();
        // IN the proper implemention this List will be done by querying the loans that are in Repayment status, and invoked by Flow.
        // For now, we manually add the IDs of the loan records.
        TESTLoanIdsfromFLOW.add(testKivaLoan.Id);
        //TESTLoanIdsfromFLOW.add('aAS010000004JW8GAM'); 
        String CLabelfromFLOW = 'Kiva Credentials Moz';
        KivaPostLoanDraft.InputResource ONEFlowInput = new KivaPostLoanDraft.InputResource();
        ONEFlowInput.CountryLabel = CLabelfromFLOW;
        ONEFlowInput.KivaLoanDrafts = TESTLoanIdsfromFLOW;
        
        List<KivaPostLoanDraft.InputResource> FLOWinputs = new List<KivaPostLoanDraft.InputResource>();
        FLOWinputs.add(ONEFlowInput);
        
        system.debug('=== Calling KivaPostLoanDraft ===');
        KivaPostLoanDraft.POST(FLOWinputs);
        system.debug('=== KivaPostLoanDraft FINISHED ===');
        
        Test.stopTest();
        
        
    }
    
    static testMethod void testPOSTRepayment() {
        Test.setMock(HttpCalloutMock.class, new KivaAPIMockTest());
        // calls the setup above to create dummy records in runtime
        KivaTest.setup();
        List<Id> TESTRepayingLoanIds = new List<Id>();
        TESTRepayingLoanIds.add(KivaTest.testKivaLoan.id);
        // Country Label
        String CountryLabel = 'Kiva Credentials Moz';
        
        KivaPostLoanRepayments.InputResource TestInputForPOSTRepayments = new KivaPostLoanRepayments.InputResource();
        TestInputForPOSTRepayments.RepayingKivaLoans = TESTRepayingLoanIds;
        TestInputForPOSTRepayments.CountryLabel = CountryLabel;
        List<KivaPostLoanRepayments.InputResource> FLOWinputs = new List<KivaPostLoanRepayments.InputResource>();
        FLOWinputs.add(TestInputForPOSTRepayments);
        
        Test.startTest();
        // Make the calls!
        system.debug('=== Calling KivaPostLoanRepayments ===');
        KivaPostLoanRepayments.POST(FLOWinputs);    
        system.debug('=== KivaPostLoanRepayments FINISHED ===');
        Test.stopTest();
    }
    
    static testMethod void testPOSTJournal() {
        Test.setMock(HttpCalloutMock.class, new KivaAPIMockTest());
        // calls the setup above to create dummy records in runtime
        KivaTest.setup();
        List<Id> TESTJournalIds = new List<Id>();
        TESTJournalIds.add(KivaTest.testKivaJournal.id);
        
        // Country Label
        String CountryLabel = 'Kiva Credentials Moz';
        
        KivaPostLoanJournals.InputResource TestInputForPOSTJournals = new KivaPostLoanJournals.InputResource();
        TestInputForPOSTJournals.JournalsForPosting = TESTJournalIds;
        TestInputForPOSTJournals.CountryLabel = CountryLabel;
        
        List<KivaPostLoanJournals.InputResource> FLOWinputs = new List<KivaPostLoanJournals.InputResource>();
        FLOWinputs.add(TestInputForPOSTJournals);
        
        
        Test.startTest();
        // Make the calls!
		system.debug('=== Calling KivaPostLoanJournals ===');
        KivaPostLoanJournals.POST(FLOWinputs);
		system.debug('=== KivaPostLoanJournals FINISHED ===');        
        Test.stopTest();
        
    }
    
    static testMethod void testGETLoans() {
        Test.setMock(HttpCalloutMock.class, new KivaAPIMockTest());
        // calls the setup above to create dummy records in runtime
        KivaTest.setup();
        
        String limitValue = '500';
        String offsetValue = '0';
        String statusValue = 'payingBack';
        String CountryLabel = 'Kiva Credentials Moz';
        String queryValue = '403';        

        // setup Input Resource for GET Loans as parameters
        KivaGetLoans.InputResource TestInputForGETLoans = new KivaGetLoans.InputResource();
        TestInputForGETLoans.limitValue = limitValue;
        TestInputForGETLoans.offsetValue = offsetValue;
        TestInputForGETLoans.statusValue = statusValue;
        TestInputForGETLoans.CountryLabel = CountryLabel;
        TestInputForGETLoans.queryValue = queryValue;
        List<KivaGetLoans.InputResource> FLOWinputs = new List<KivaGetLoans.InputResource>();
        FLOWinputs.add(TestInputForGETLoans);

        Test.startTest();
        // Make the calls!        
        system.debug('=== Calling KivaGetLoans ===');
        KivaGetLoans.GET(FLOWinputs);
        system.debug('=== KivaGetLoans FINISHED ===');    
        Test.stopTest();
        
    }
    
}