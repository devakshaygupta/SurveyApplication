public without sharing class GuestReviewProcessor {

    //TO-DO Build out Invocable method processReviews with label and description
    @InvocableMethod(
        label='Process Guest Reviews'
        description='Process the guest reviews'
    )
    public static List<GuestReviewResponse> processReviews(List<GuestReviewRequest> requests){
        try {
            List<GuestReviewResponse> reviewResponses = new List<GuestReviewResponse>();
            List<Guest_Review__c> guestReviewsToInsert = new List<Guest_Review__c>();
            Map<Id, Contact> recurringCampaignParticipantByContactId= new Map<Id, Contact>();
            for (GuestReviewRequest request : requests) {
                //TO-DO Insert Guest_Review__c record with contact (Contact__c), experience (Experience__c), rating (Rating__c), and review (Comments__c) variables in the processReviews method
                Guest_Review__c guestReview  = new Guest_Review__c();
                guestReview.Contact__c = request.contact.Id;
                guestReview.Experience__c = request.experience.Id;
                guestReview.Comments__c = request.review;
                guestReview.Rating__c = request.rating;
                guestReviewsToInsert.add(guestReview);
                recurringCampaignParticipantByContactId.put(request.contact.Id, request.contact);
            }

            if (guestReviewsToInsert.size() > 0) {
                insert guestReviewsToInsert;
            }
            CampaignMemberController.createCampaignMemberforRelatedCampaigns(recurringCampaignParticipantByContactId);
            for(Guest_Review__c guestReview : guestReviewsToInsert) {
                GuestReviewResponse response = new GuestReviewResponse();
                response.message = 'Guest Review created';
                reviewResponses.add(response);
            }
            return reviewResponses;
        } catch (Exception ex) {
            GuestReviewResponse response = new GuestReviewResponse();
            response.message = ex.getMessage();

            return new List<GuestReviewResponse> { response };
        }

    }

    public class GuestReviewRequest{
        //TO-DO Build out GuestReviewRequest class with Invocable variables
        @InvocableVariable(
            required=true
            description='Reference to the contact record of the guest.'
        )
        public Contact contact;
        @InvocableVariable(
            required=true
            description='Reference to the experience record of the guest.'
        )
        public Experience__c experience;
        @InvocableVariable(
            required=true
            description='Review written about the experience by the guest.'
        )
        public String review;
        @InvocableVariable(
            required=true
            description='Rating given about the experience by the guest.'
        )
        public String rating;

    }


    public class GuestReviewResponse{
        //TO-DO Build out GuestReviewResponse class with Invocable variables
        @InvocableVariable(
            label='status'
            description='Information on the guest review created.'
        )
        public String message;

    }

}
