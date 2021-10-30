import { LightningElement, wire } from 'lwc';
import submitResponses from '@salesforce/apex/SurveyController.submitResponses';
import getDetails from '@salesforce/apex/SurveyController.getDetails';

export default class SurveyComponent extends LightningElement {

    surveyWrapper;
    errorMessage;
    questions = [];
    responseWrapper = [];
    selectedValue;
    showSurvey = true;
    showError = false;
    showSuccess = false;
    successMessage = 'Your responses have been submitted.'
    noOfResponses = this.responseWrapper.length;

    @wire(getDetails) 
    wiredSurvey({data, error}) {
        if(data) {
            this.surveyWrapper = data;
            this.questions = data.questions;                                                 
        } else if(error) {
            this.errorMessage = error.body.message;
            this.showError = true;
        }
    };

    handleSelection(event) {
        var answer = {
            response : event.detail.response,
            questionId : event.detail.questionId,
            surveyId : this.surveyWrapper.surveyId
        }
        console.log(answer);
        if(this.noOfResponses > 0) {
            for(let i = 0; i < noOfResponses; i++) {
                if(this.responseWrapper[i].questionId == answer.questionId && this.responseWrapper[i].response != answer.response) {
                    this.responseWrapper[i].response = answer.response;
                } else if(this.responseWrapper[i].questionId != answer.questionId && this.responseWrapper[i].response != answer.response) {
                    this.responseWrapper.push(answer);
                } 
            }
        } else {
            this.responseWrapper.push(answer);
        }
        console.log(this.responseWrapper);
    }

    handleSave(event) {
        submitResponses({responseWrapper : JSON.stringify(this.responseWrapper)})
        .then(() => {
            this.hideButton = true;            
            this.showSurvey = false;
            this.showSuccess = true;
        })
        .catch(error => {
            this.hideButton = true;
            this.showError = true;
            this.errorMessage = error.body.message;
        });
    }

    handleReset(event) {
        window.location.reload();
    }    

}