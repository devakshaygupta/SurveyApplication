@RestResource(urlMapping='/ProductZoning/*')
global with sharing class ProductZoningService {
    @HttpGet
    global static String getPermissibleFlyZone() {
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

            Map<String, String> reqParamMap = req.params;

            String productCode = (String) reqParamMap.get('ProductCode');

            Map<String, String> reqHeaderMap = req.headers;

            String countryCode = reqHeaderMap.containsKey('CountryCode')
                ? (String) reqHeaderMap.get('CountryCode')
                : 'US'; // default

            // Validate for empty productCode
            if (String.isBlank(productCode)) {
                res.statusCode = 400;
                responseString = 'ProductCode is missing or doesn\'t exist';
                res.responseBody = Blob.valueOf(responseString);
                RestContext.response = res;
                return responseString;
            }

            List<Product2> productList = [
                SELECT Id, ProductCode, Family, Description, Name
                FROM Product2
                WHERE ProductCode = :productCode
                WITH USER_MODE
            ];

            // Validate for non existing productCode
            if (productList.isEmpty()) {
                res.statusCode = 400;
                responseString = 'ProductCode is missing or doesn\'t exist';
                res.responseBody = Blob.valueOf(responseString);
                RestContext.response = res;
                return responseString;
            }

            List<Product_Geo_Mapping__mdt> productGeoMappingList = Product_Geo_Mapping__mdt.getAll()
                .values();

            for (Product_Geo_Mapping__mdt mapping : productGeoMappingList) {
                if (
                    mapping.Country_Code__c == countryCode &&
                    mapping.Product_Family__c == productList[0].Family
                ) {
                    responseString = mapping.Permissible_Fly_Zone__c;
                    break;
                }
            }

            if (String.isBlank(responseString)) {
                responseString = 'Confirm with the local authorities';
            }
            res.statusCode = 200;
            RestContext.response = res;
            return responseString;
        } catch (Exception e) {
            res.statusCode = 500;
            responseString = 'An unexpected error occurred: ' + e.getMessage();
            res.responseBody = Blob.valueOf(responseString);
            RestContext.response = res;
            return responseString;
        }
    }
}
