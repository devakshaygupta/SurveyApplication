@IsTest
public class RewardsCalloutServiceTest {
    @IsTest
    static void testForRewardCalloutSuccess() {
        // Set mock response for successful callout
        RewardsCalloutServiceMock mock = new RewardsCalloutServiceMock(201);
        Test.setMock(HttpCalloutMock.class, mock);

        String jsonBody = '{"userId": "12345", "rewardType": "Gold"}';
        Integer statusCode = RewardsCalloutService.submitUsersForRewardCallout(
            jsonBody
        );

        System.assertEquals(
            201,
            statusCode,
            'Expected status code 201 for successful callout'
        );
    }

    @IsTest
    static void testForRewardCalloutBadRequest() {
        // Set mock response for bad request
        RewardsCalloutServiceMock mock = new RewardsCalloutServiceMock(400);
        Test.setMock(HttpCalloutMock.class, mock);

        String jsonBody = '{"userId": "", "rewardType": "Gold"}'; // Invalid body
        Integer statusCode = RewardsCalloutService.submitUsersForRewardCallout(
            jsonBody
        );

        System.assertEquals(
            400,
            statusCode,
            'Expected status code 400 for bad request'
        );
    }

    @IsTest
    static void testForRewardCalloutInternalError() {
        // Set mock response for internal error
        RewardsCalloutServiceMock mock = new RewardsCalloutServiceMock(500);
        Test.setMock(HttpCalloutMock.class, mock);

        String jsonBody = '{"userId": "12345", "rewardType": "Gold"}'; // Invalid body
        Integer statusCode = RewardsCalloutService.submitUsersForRewardCallout(
            jsonBody
        );

        System.assertEquals(
            500,
            statusCode,
            'Expected status code 500 for internal error'
        );
    }
}
