@isTest
private class GuestReviewProcessorTest {
  @isTest
  static void testProcessReviews() {
    // Create test contact
    Contact testContact = new Contact(
      FirstName = 'John',
      LastName = 'Doe',
      Email = 'john.doe@example.com'
    );
    insert testContact;

    // Create test experience (assuming Experience__c is a custom object)
    // Note: Since Experience__c isn't in the schema, we'll create a mock object
    // In real scenario, you'd need to create actual Experience__c records

    // Create request object
    GuestReviewRequest request = new GuestReviewRequest();
    request.contact = testContact;
    request.experience = new Id('a01XXXXXXXXXXXX'); // Mock experience ID
    request.review = 'Great experience!';
    request.rating = 5;

    // Call method
    List<GuestReviewResponse> responses = GuestReviewProcessor.processReviews(
      new List<GuestReviewRequest>{ request }
    );

    // Verify results
    System.assertEquals(1, responses.size());
    System.assertEquals('Guest Review created', responses[0].message);

    // Verify Guest_Review__c record was created
    List<Guest_Review__c> createdReviews = [
      SELECT Id, Contact__c, Experience__c, Comments__c, Rating__c
      FROM Guest_Review__c
      WHERE Contact__c = :testContact.Id
    ];
    System.assertEquals(1, createdReviews.size());
    System.assertEquals(testContact.Id, createdReviews[0].Contact__c);
    System.assertEquals('Great experience!', createdReviews[0].Comments__c);
    System.assertEquals(5, createdReviews[0].Rating__c);
  }
}
