## [UIIE-PDFDistribute_Single.rb](./UIIE-PDFDistribute_Single.rb)  
This script was based on a client request, where they have a PDF attached to a single survey which is related to multiple surveys.  
The surveys share the job_number field value.  
The script will identify CCTV Surveys which have a single PDF attachment, wite the attributes to an array, then go through the CCTV Surveys which don't have a PDF attachment and if there is attributes in the aray matching the survey's job_number field, wite the values to the survey's attachments blob.  

## [UIIE-PDFDistribute_Multi.rb](./UIIE-PDFDistribute_Multi.rb)  
Similar to the *_Single script but this example will copy the attachment details for multiple files linked to the same job_number field value and update all surveys with the same shared value to have matching attachments values.  

## [UIIE-CCTVVideoDistribute_Multi.rb](./UIIE-CCTVVideoDistribute_Multi.rb)  
This is the same as [UIIE-PDFDistribute_Multi.rb](./UIIE-PDFDistribute_Multi.rb) but this run on the Manhole Survey object (lines 24 & 58), taking the values for the attachments which have the 'Purpose' value of "CCTV Video" (line 31), mapping these no the Node ID (lines 25 & 38) of the surveys to be updated on all surveys which have the same Node ID value (lines 60 & 64).  
