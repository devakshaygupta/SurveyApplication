public with sharing class RewardsCalloutService {
    public static Integer submitUsersForRewardCallout(String jsonBody) {
        //Set Endpoint from Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:IntegrationSB__BalancedLiving/rewards');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(jsonBody);

        //Make HTTP Callout
        Http http = new Http();
        HttpResponse res = http.send(req);

        return res.getStatusCode();
    }
}
