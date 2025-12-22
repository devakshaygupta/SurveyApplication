@IsTest
public class WellnessJourneyRewardsBatchTest {
    @TestSetup
    static void makeData() {
        // Create test Users
        Profile standardUseProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Standard User'
            LIMIT 1
        ];
        User user1 = new User(
            Alias = 'testuser',
            Email = 'wellnessuser1.' +
                UserInfo.getOrganizationId() +
                '@' +
                UserInfo.getOrganizationName() +
                '.com',
            Username = 'wellnessuser1.' +
                UserInfo.getOrganizationId() +
                '@' +
                UserInfo.getOrganizationName() +
                '.com',
            ProfileId = standardUseProfile.Id,
            LastName = 'User1',
            FirstName = 'Wellness1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        User user2 = new User(
            Alias = 'testuser',
            Email = 'testuser2.' +
                UserInfo.getOrganizationId() +
                '@' +
                UserInfo.getOrganizationName() +
                '.com',
            Username = 'testuser2.' +
                UserInfo.getOrganizationId() +
                '@' +
                UserInfo.getOrganizationName() +
                '.com',
            ProfileId = standardUseProfile.Id,
            LastName = 'User2',
            FirstName = 'Wellness2',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );

        insert new List<User>{ user1, user2 };

        Wellness_Journey__c wellnessJourney1 = new Wellness_Journey__c();
        wellnessJourney1.Name = 'Balance and Stability Workout';
        wellnessJourney1.Type__c = 'Physical';
        wellnessJourney1.Status__c = 'Complete';
        wellnessJourney1.Completion_Date__c = Date.today().addMonths(-4);

        Wellness_Journey__c wellnessJourney2 = new Wellness_Journey__c();
        wellnessJourney2.Name = 'Einstein\'s Puzzle Quest';
        wellnessJourney2.Type__c = 'Mental';
        wellnessJourney2.Status__c = 'Complete';
        wellnessJourney2.Completion_Date__c = Date.today().addMonths(-4);

        System.runAs(user1) {
            List<Wellness_Journey__c> journeysToInsert = new List<Wellness_Journey__c>();
            for (Integer i = 0; i < 12; i++) {
                Wellness_Journey__c wj = wellnessJourney1.clone(false, true);
                wj.Completion_Date__c = Date.today().addMonths(-4).addDays(i);
                journeysToInsert.add(wj);
            }
            insert journeysToInsert;
        }

        System.runAs(user2) {
            insert wellnessJourney2;
        }
    }

    @IsTest
    static void testWellnessJourneyRewardsBatch() {
        // Set mock response for successful callout
        Test.startTest();
        RewardsCalloutServiceMock mock = new RewardsCalloutServiceMock(201);
        Test.setMock(HttpCalloutMock.class, mock);

        // Execute the batch
        WellnessJourneyRewardsBatch batch = new WellnessJourneyRewardsBatch();
        Id batchJobId = Database.executeBatch(batch);

        Test.stopTest();

        Assert.areEqual(
            'Completed',
            [
                SELECT Id, Status, JobItemsProcessed
                FROM AsyncApexJob
                WHERE Id = :batchJobId
            ][0]
            .Status,
            'Batch job should be completed'
        );
    }
}
