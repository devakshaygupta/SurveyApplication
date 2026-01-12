global with sharing class CredentialVerificationService {
    webService static String verifyCredential(
        String lastName,
        String certificationName
    ) {
        try {
            String result = 'No record found';

            if (String.isBlank(lastName) || String.isBlank(certificationName)) {
                throw new CredentialVerificationServiceException('Missing input parameters');
            }

            List<Contact_Certification__c> contactCerts = [
                SELECT Id, Name, Contact__r.LastName, IsActive__c
                FROM Contact_Certification__c
                WHERE
                    Contact__r.LastName = :lastName
                    AND Name = :certificationName
                WITH USER_MODE
                LIMIT 1
            ];

            if (!contactCerts.isEmpty()) {
                Contact_Certification__c cert = contactCerts[0];
                if (cert.IsActive__c) {
                    result = 'Valid';
                } else {
                    result = 'Needs Renewal';
                }
            }

            return result;
        } catch (Exception ex) {
            return 'Error: ' + ex.getMessage();
        }
    }

    global class CredentialVerificationServiceException extends Exception {}

}
