@IsTest
public class CredentialVerificationServiceTest {
    @TestSetup
    static void setupTestData() {
        // Create test data needed for the tests
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        Test.startTest();

        Contact testContact1 = new Contact(
            FirstName = 'Test',
            LastName = 'User1',
            AccountId = acct.Id,
            Email = 'test@example.com'
        );

        Contact testContact2 = new Contact(
            FirstName = 'Test',
            LastName = 'User2',
            AccountId = acct.Id,
            Email = 'test2@example.com'
        );

        insert new List<Contact>{ testContact1, testContact2 };

        Certification__c cert = new Certification__c(
            Name = 'Operator Certification',
            IsActive__c = true
        );
        insert cert;

        Contact_Certification__c contactCert1 = new Contact_Certification__c(
            Contact__c = testContact1.Id,
            Certification__c = cert.Id,
            IsActive__c = true,
            Issue_Date__c = Date.today().addMonths(-6)
        );

        Contact_Certification__c contactCert2 = new Contact_Certification__c(
            Contact__c = testContact2.Id,
            Certification__c = cert.Id,
            IsActive__c = true,
            Issue_Date__c = Date.today().addMonths(-6)
        );

        insert new List<Contact_Certification__c>{ contactCert1, contactCert2 };

        Test.stopTest();
    }

    @IsTest
    static void testVerifyValidCredential() {
        Contact_Certification__c certToUpdate = [
            SELECT Id, Name, IsActive__c
            FROM Contact_Certification__c
            WHERE Contact__r.LastName = 'User1'
            LIMIT 1
        ];

        Test.startTest();

        String result = CredentialVerificationService.verifyCredential(
            'User1',
            certToUpdate.Name
        );

        Test.stopTest();

        Assert.areEqual('Valid', result, 'Expected credential to be valid');
    }

    @IsTest
    static void testVerifyRenewalPendingCredential() {
        Contact_Certification__c certToUpdate = [
            SELECT Id, Name, IsActive__c
            FROM Contact_Certification__c
            WHERE Contact__r.LastName = 'User1'
            LIMIT 1
        ];

        certToUpdate.IsActive__c = false;
        update certToUpdate;

        Test.startTest();

        String result = CredentialVerificationService.verifyCredential(
            'User1',
            certToUpdate.Name
        );

        Test.stopTest();

        Assert.areEqual(
            'Needs Renewal',
            result,
            'Expected credential to need renewal'
        );
    }

    @IsTest
    static void testVerifyNonExistentCredential() {
        Contact_Certification__c certToUpdate = [
            SELECT Id, Name, IsActive__c
            FROM Contact_Certification__c
            WHERE Contact__r.LastName = 'User2'
            LIMIT 1
        ];

        certToUpdate.IsActive__c = false;
        update certToUpdate;

        Test.startTest();

        String result = CredentialVerificationService.verifyCredential(
            'User1',
            certToUpdate.Name
        );

        Test.stopTest();

        Assert.areEqual(
            'No record found',
            result,
            'Expected credential to be non-existent'
        );
    }
}
