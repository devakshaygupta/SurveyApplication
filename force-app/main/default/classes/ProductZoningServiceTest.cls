@IsTest
public class ProductZoningServiceTest {
    @TestSetup
    static void makeData() {
        Test.startTest();
        // Insert Product2 records
        Product2 blackHornet = new Product2(
            Name = 'Black Hornet',
            ProductCode = 'IN7060',
            Family = 'MALE',
            IsActive = true
        );

        Product2 wingtraOne = new Product2(
            Name = 'Wingtra One',
            ProductCode = 'IN7040',
            Family = 'Fixed-Wing',
            IsActive = true
        );

        Product2 djiPhantom = new Product2(
            Name = 'DJI Phantom',
            ProductCode = 'GC1020',
            Family = 'Multi-Rotor',
            IsActive = true
        );

        Product2 vertic = new Product2(
            Name = 'Vertic',
            ProductCode = 'GC3040',
            Family = 'HALE',
            IsActive = true
        );

        Product2 djiMini = new Product2(
            Name = 'DJI Mini',
            ProductCode = 'AK1040',
            Family = 'Flexible-Wing',
            IsActive = true
        );

        insert new List<Product2>{
            blackHornet,
            wingtraOne,
            djiPhantom,
            vertic,
            djiMini
        };

        Test.stopTest();
    }

    @IsTest
    static void testMissingParams() {
        // Create a mock REST request with missing params
        Test.startTest();

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';

        RestContext.request = req;
        // Call the method
        ProductZoningService.getPermissibleFlyZone();

        RestResponse res = RestContext.response;

        Test.stopTest();

        Integer responseCode = res.statusCode;

        // Validate the response
        System.assertEquals(
            400,
            responseCode,
            'Expected status code 400 for missing parameters'
        );
    }

    @IsTest
    static void testMissingProductCode() {
        // Create a mock REST request with missing ProductCode
        Test.startTest();
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/ProductZoning/US';
        req.httpMethod = 'GET';
        req.addParameter('ProductCode', '');

        RestContext.request = req;

        // Call the method
        ProductZoningService.getPermissibleFlyZone();

        RestResponse res = RestContext.response;

        Test.stopTest();

        // Validate the response
        System.assertEquals(
            400,
            res.statusCode,
            'Expected status code 400 for missing ProductCode'
        );
    }

    @IsTest
    static void testNonExistingProductCode() {
        // Create a mock REST request with valid countryCode and ProductCode
        Test.startTest();

        RestRequest req = new RestRequest();

        req.requestUri = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'FR');
        req.addParameter('ProductCode', 'IN8040');

        RestContext.request = req;

        String responseBody = ProductZoningService.getPermissibleFlyZone();

        RestResponse res = RestContext.response;

        Test.stopTest();

        Integer responseCode = res.statusCode;

        // Validate the response
        Assert.areEqual(400, responseCode, 'Expected status code 400');
        Assert.isTrue(
            responseBody.contains('ProductCode is missing or doesn\'t exist'),
            'Expected error message for non-existing ProductCode'
        );
    }

    @IsTest
    static void testGetMissingPermissibleFlyZone() {
        // Create a mock REST request with valid countryCode and ProductCode
        Test.startTest();

        RestRequest req = new RestRequest();

        req.requestUri = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'FR');
        req.addParameter('ProductCode', 'AK1040');

        RestContext.request = req;

        String responseBody = ProductZoningService.getPermissibleFlyZone();

        RestResponse res = RestContext.response;

        Test.stopTest();

        Integer responseCode = res.statusCode;
        // Validate the response
        Assert.areEqual(200, responseCode, 'Expected status code 200');
        Assert.areEqual(
            responseBody,
            'Confirm with the local authorities',
            'Expected response to contain default message'
        );
    }

    @IsTest
    static void testGetPermissibleFlyZone() {
        // Create a mock REST request with valid countryCode and ProductCode
        Test.startTest();

        RestRequest req = new RestRequest();

        req.requestUri = '/services/apexrest/ProductZoning';
        req.httpMethod = 'GET';
        req.addHeader('CountryCode', 'FR');
        req.addParameter('ProductCode', 'IN7040');

        RestContext.request = req;

        String responseBody = ProductZoningService.getPermissibleFlyZone();

        RestResponse res = RestContext.response;

        Test.stopTest();

        Integer responseCode = res.statusCode;
        // Validate the response
        Assert.areEqual(200, responseCode, 'Expected status code 200');
        Assert.areEqual(
            responseBody,
            'Regulated',
            'Expected response to contain zoning information'
        );
    }

    @IsTest
    static void testCoversCatchWithNullRequest() {
        // Arrange: simulate an unexpected platform error by clearing RestContext.request
        Test.startTest();
        RestContext.request = null;

        // Act
        String out = ProductZoningService.getPermissibleFlyZone();
        RestResponse res = RestContext.response;
        Test.stopTest();

        // Assert: catch block sets 500 and an error message
        System.assertNotEquals(
            null,
            res,
            'RestContext.response should be set in catch'
        );
        System.assertEquals(
            500,
            res.statusCode,
            'Expected 500 from catch path'
        );
        System.assert(
            out != null && out.startsWith('An unexpected error occurred:'),
            'Catch should return error message string'
        );
    }
}
