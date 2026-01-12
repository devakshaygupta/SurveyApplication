public with sharing class GuestReviewRatingCalculator {
    public Experience__c generateRatingParams(String experienceId){
        
        Map<String, String> experience = new Map<String, String>();
        experience.put('id',experienceId);
        ConnectApi.WrappedValue experienceValue = new ConnectApi.WrappedValue();
        experienceValue.value = experience;
        Map<String, ConnectApi.WrappedValue> inputParams = new Map<String, ConnectApi.WrappedValue>();
        
        //TO-DO Configure Prompt Template Input API Name(Input:experience)
        inputParams.put('Input:experience', experienceValue);
        
        // Configure invocation parameters
        ConnectApi.EinsteinPromptTemplateGenerationsInput executeTemplateInput = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
        executeTemplateInput.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
        executeTemplateInput.additionalConfig.applicationName = 'PromptBuilderPreview';
        executeTemplateInput.isPreview = false;
        executeTemplateInput.inputParams = inputParams;
        
        try {
            //TO-DO Call the service generateMessagesForPromptTemplate to generate response by specifying the prompt template API name and input parameters
            ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput = ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                'Experience_Guest_Reviews_Evaluator',
                executeTemplateInput
            );            
            //TO-DO Extract the response text from generations property
            ConnectApi.EinsteinLLMGenerationItemOutput response = generationsOutput.generations[0]; 
          
            //Deserialize the response 
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.text);
            Decimal accuracy = jsonMap.containsKey('Accuracy') ? (Decimal) jsonMap.get('Accuracy') : 0;
            Decimal value = jsonMap.containsKey('Value') ? (Decimal) jsonMap.get('Value') : 0;
            Decimal communication = jsonMap.containsKey('Communication') ? (Decimal) jsonMap.get('Communication') : 0;
            
            //Update the Experience record with the deserialized response
            Experience__c exp = new Experience__c(Id=experienceId, Value__c =value,  Accuracy__c=accuracy, Communication__c = communication);
            update exp;
            return exp;
        } catch (Exception e){
            System.debug(e.getMessage());
            throw e;
        }
    }
}