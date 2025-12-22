@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.ExcessiveParameterList')
@IsTest
global class BillingCalloutServiceMock implements WebServiceMock {
    Boolean isStatusOk;

    global BillingCalloutServiceMock(Boolean isStatusOk) {
        this.isStatusOk = isStatusOk;
    }

    // This method is called when a generated WSDL class performs a callout
    global void doInvoke(
        Object stub,
        Object soapRequest,
        Map<String, Object> responseMap,
        String endpoint,
        String soapAction,
        String requestName,
        String responseNamespace,
        String responseName,
        String responseType
    ) {
        BillingServiceProxy.billProjectResponse_element respElement = new BillingServiceProxy.billProjectResponse_element();
        respElement.status = isStatusOk ? 'ok' : 'error';
        responseMap.put('response_x', respElement);
    }
}
