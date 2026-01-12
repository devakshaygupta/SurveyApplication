@IsTest
public class BillingCalloutServiceTest {
    @IsTest
    static void testBillingService() {

        Test.startTest();

        // Use WebServiceMock since BillingServiceProxy uses WebServiceCallout.invoke (WSDL-based)
        Test.setMock(
            WebServiceMock.class,
            new BillingCalloutServiceMock(true)
        );

        Workshop__c yogaWorkshop = new Workshop__c(
            Name = 'Yoga Workshop',
            Capacity__c = 35,
            Date__c = Date.today().addDays(10),
            DHH_Accessible__c = true
        );
        insert yogaWorkshop;

        Test.stopTest();

        Assert.areEqual(
            'Complete',
            [SELECT Id, Status__c FROM Accessibility_Project__c LIMIT 1].Status__c,
            'Accessibility Project status should be Complete after successful billing callout'
        );
    }
}
