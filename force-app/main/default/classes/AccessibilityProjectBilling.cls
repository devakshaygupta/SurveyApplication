@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class AccessibilityProjectBilling {
    @Future(callout=true)
    public static void callBillingService(
        String projectId,
        Decimal billingAmount
    ) {
        //Setup username, password, billAmount, and projectid in BillingServiceProxy.project and then call billProject method
        BillingServiceProxy.project proj = new BillingServiceProxy.project();
        proj.username = '{!$Credential.BillingServiceCredential.username}';
        proj.password = '{!$Credential.BillingServiceCredential.password}';
        proj.projectid = projectId;
        proj.billAmount = Double.valueOf(billingAmount);

        BillingServiceProxy.InvoicesPortSoap11 invoicePortSoap = new BillingServiceProxy.InvoicesPortSoap11();

        String response = invoicePortSoap.billProject(proj);

        //If response is ok set Accessibility Project Status = Complete
        if (response == 'ok') {
            Accessibility_Project__c accProj = [
                SELECT Id, Status__c
                FROM Accessibility_Project__c
                WHERE Id = :projectId
                WITH USER_MODE
                LIMIT 1
            ];
            accProj.Status__c = 'Complete';
            if (Schema.sObjectType.Accessibility_Project__c.isUpdateable()) {
                update accProj;
            }
        }
    }
}
