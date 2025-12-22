trigger WorkshopTrigger on Workshop__c(after insert) {
    Decimal billingAmount = 0;
    for (Workshop__c workshop : Trigger.new) {
        // Check if the DHH_Accessible__c checkbox field is true
        if (workshop.DHH_Accessible__c == true) {
            // Calculate the billing amount
            billingAmount += 50;
        }
    }
    if (billingAmount > 0) {
        //Create an accessibility project for the new workshops
        Accessibility_Project__c ap = new Accessibility_Project__c(
            Amount__c = billingAmount,
            Type__c = 'Sign Language Interpreters',
            Status__c = 'Submitted'
        );
        insert ap;
        AccessibilityProjectBilling.callBillingService(ap.Id, ap.Amount__c);
    }
}
