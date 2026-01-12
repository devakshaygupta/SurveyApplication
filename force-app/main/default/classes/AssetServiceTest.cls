@IsTest
public class AssetServiceTest {
    @TestSetup
    static void makeData() {
        Account acct = new Account(Name = 'Trailhead');
        insert acct;

        Contact testContact = new Contact(
            FirstName = 'Trailhead',
            LastName = 'User',
            AccountId = acct.Id,
            Email = 'trailhead.user@company.com'
        );
        insert testContact;

        Asset testAsset = new Asset(
            Name = 'Trailhead Test',
            AccountId = acct.Id,
            Asset_Identifier__c = '12345678',
            ContactId = testContact.Id,
            Status = 'Purchased'
        );
        insert testAsset;
    }

    @IsTest
    static void testInvalidAssetIdentifier() {
        Test.startTest();

        RestRequest req = new RestRequest();

        req.requestUri = '/services/apexrest/lost';
        req.httpMethod = 'POST';

        RestContext.request = req;

        String response = AssetService.reportLostDevice('INVALID_ID');

        RestResponse res = RestContext.response;

        Test.stopTest();

        Assert.areEqual(
            'No device found.',
            response,
            'Expected error message for invalid asset identifier'
        );
    }

    @IsTest
    static void testBlankAssetIdentifier() {
        Test.startTest();

        RestRequest req = new RestRequest();

        req.requestUri = '/services/apexrest/lost';
        req.httpMethod = 'POST';

        RestContext.request = req;

        String response = AssetService.reportLostDevice('');

        RestResponse res = RestContext.response;

        Test.stopTest();

        Assert.areEqual(
            'No device found.',
            response,
            'Expected error message for invalid asset identifier'
        );
    }

    @IsTest
    static void testMissingComprehensiveCoverage() {
        Test.startTest();

        RestRequest req = new RestRequest();

        req.requestUri = '/services/apexrest/lost';
        req.httpMethod = 'POST';

        RestContext.request = req;

        String response = AssetService.reportLostDevice('12345678');

        RestResponse res = RestContext.response;

        Test.stopTest();

        Assert.areEqual(
            'No coverage. Asset status adjusted to Lost.',
            response,
            'Expected message for asset without comprehensive coverage'
        );
        Assert.areEqual(
            'Lost',
            [
                SELECT Status
                FROM Asset
                WHERE Asset_Identifier__c = '12345678'
                LIMIT 1
            ]
            .Status,
            'Expected asset status to be updated to Lost'
        );
    }

    @IsTest
    static void testExistingOpenClaim() {
        Test.startTest();

        Asset testAsset = [
            SELECT Id
            FROM Asset
            WHERE Asset_Identifier__c = '12345678'
            LIMIT 1
        ];

        Insurance__c comprehensiveInsurance = new Insurance__c(
            Coverage__c = 'Comprehensive',
            Active__c = true,
            Asset__c = testAsset.Id
        );
        insert comprehensiveInsurance;

        Claim__c existingClaim = new Claim__c(
            Asset__c = testAsset.Id,
            Type__c = 'Loss',
            Status__c = 'New',
            Insurance__c = comprehensiveInsurance.Id
        );
        insert existingClaim;

        String existingClaimName = [SELECT Name FROM Claim__c WHERE Id = :existingClaim.Id LIMIT 1].Name;

        RestRequest req = new RestRequest();

        req.requestUri = '/services/apexrest/lost';
        req.httpMethod = 'POST';

        RestContext.request = req;

        String response = AssetService.reportLostDevice('12345678');

        RestResponse res = RestContext.response;

        Test.stopTest();

        Assert.areEqual(
            existingClaimName + ' already filed.',
            response,
            'Expected error message for invalid asset identifier'
        );
    }

    @IsTest
    static void testNewClaim() {
        Test.startTest();

        Asset testAsset = [
            SELECT Id
            FROM Asset
            WHERE Asset_Identifier__c = '12345678'
            LIMIT 1
        ];

        Insurance__c comprehensiveInsurance = new Insurance__c(
            Coverage__c = 'Comprehensive',
            Active__c = true,
            Asset__c = testAsset.Id
        );
        insert comprehensiveInsurance;

        RestRequest req = new RestRequest();

        req.requestUri = '/services/apexrest/lost';
        req.httpMethod = 'POST';

        RestContext.request = req;

        String response = AssetService.reportLostDevice('12345678');

        RestResponse res = RestContext.response;

        Test.stopTest();

        Assert.areEqual(
            [SELECT Name FROM Claim__c WHERE Asset__c = :testAsset.Id LIMIT 1].Name,
            response,
            'Expected error message for invalid asset identifier'
        );
        Assert.areEqual(
            'Lost',
            [
                SELECT Status
                FROM Asset
                WHERE Asset_Identifier__c = '12345678'
                LIMIT 1
            ]
            .Status,
            'Expected asset status to be updated to Lost'
        );
    }

}
