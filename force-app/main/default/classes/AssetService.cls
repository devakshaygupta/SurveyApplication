@RestResource(urlMapping='/lost/*')
global with sharing class AssetService {
    @HttpPost
    global static String reportLostDevice(String assetIdentifier) {
        String responseString = '';
        RestRequest req = RestContext.request;
        RestResponse res = new RestResponse();
        try {
            res.addHeader('X-FRAME-OPTIONS', 'SAMEORIGIN');
            res.addHeader('Cache-control', 'no-store');
            res.addHeader('Pragma', 'no-cache');
            res.addHeader('X-Permitted-Cross-Domain-Policies', 'none');
            res.addHeader('X-XSS-Protection', '1');
            res.addHeader('mode', 'block');
            res.addHeader('Content-Type', 'text/plain; charset=UTF-8');


            // Validate for empty assetIdentifier
            if (String.isBlank(assetIdentifier)) {
                return 'No device found.';
            }

            List<Asset> assetList = [
                SELECT
                    Id,
                    Asset_Identifier__c,
                    Status,
                    (
                        SELECT Id, Active__c, Coverage__c, Asset__c
                        FROM Insurances__r
                        WHERE Active__c = TRUE AND Coverage__c = 'Comprehensive'
                    ),
                    (
                        SELECT Id, Name
                        FROM Claims__r
                        WHERE
                            Type__c = 'Loss'
                            AND Status__c IN ('New', 'In Process')
                    )
                FROM Asset
                WHERE Asset_Identifier__c = :assetIdentifier
                WITH USER_MODE
            ];

            // Validate for non existing assetIdentifier
            if (assetList.isEmpty()) {
                return 'No device found.';
            } else {
                if (assetList[0].Insurances__r.isEmpty()) {
                    Asset device = assetList[0];
                    device.Status = 'Lost';

                    if (
                        Schema.sObjectType.Asset.isUpdateable() &&
                        Schema.sObjectType.Asset.fields.Status.isUpdateable()
                    ) {
                        update device;
                    }

                    return 'No coverage. Asset status adjusted to Lost.';
                }
                // Process the claim for the lost asset
                responseString = processClaim(assetList[0].Asset_Identifier__c);
            }

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(responseString);
            RestContext.response = res;
            return responseString;
        } catch (Exception e) {
            res.statusCode = 500;
            responseString = 'Internal server error: ' + e.getMessage();
            res.responseBody = Blob.valueOf(responseString);
            RestContext.response = res;
            return responseString;
        }
    }

    private static String processClaim(String assetIdentifier) {
        String claimName = '';

        List<Claim__c> existingClaims = [
            SELECT Id, Name, Asset__c
            FROM Claim__c
            WHERE
                Asset__r.Asset_Identifier__c = :assetIdentifier
                AND Type__c = 'Loss'
                AND Status__c IN ('New', 'In Process')
            WITH USER_MODE
        ];

        if (!existingClaims.isEmpty()) {
            claimName = existingClaims[0].Name;
            return claimName + ' already filed.';
        } else {
            Asset device = [
                SELECT
                    Id,
                    Status,
                    ContactId,
                    (
                        SELECT Id, Active__c, Coverage__c, Asset__c
                        FROM Insurances__r
                        WHERE Active__c = TRUE AND Coverage__c = 'Comprehensive'
                    )
                FROM Asset
                WHERE Asset_Identifier__c = :assetIdentifier
                WITH USER_MODE
                LIMIT 1
            ];

            Claim__c newClaim = new Claim__c(
                Asset__c = device.Id,
                Contact__c = device.ContactId,
                Insurance__c = device.Insurances__r[0].Id,
                Type__c = 'Loss',
                Status__c = 'New'
            );

            device.Status = 'Lost';

            upsert new List<SObject>{ newClaim, device };

            claimName = [
                SELECT Id, Name, Asset__c
                FROM Claim__c
                WHERE Id = :newClaim.Id
                WITH USER_MODE
                LIMIT 1
            ]
            .Name;
        }

        return claimName;
    }
}
