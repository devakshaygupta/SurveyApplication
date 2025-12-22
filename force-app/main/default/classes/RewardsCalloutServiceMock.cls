@SuppressWarnings('PMD.AvoidGlobalModifier')
@isTest
global class RewardsCalloutServiceMock implements HttpCalloutMock {
    Integer mockStatusCode;

    global RewardsCalloutServiceMock(Integer mockStatusCode) {
        this.mockStatusCode = mockStatusCode;
    }

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        String endPoint = req.getEndpoint();

        if (this.mockStatusCode == 201) {
            res.setBody('{"message": "Success"}');
            res.setStatusCode(201);
        } else if (this.mockStatusCode == 400) {
            res.setBody('{"message": "Bad request"}');
            res.setStatusCode(400);
        } else {
            res.setStatusCode(500);
        }
        return res;
    }
}
