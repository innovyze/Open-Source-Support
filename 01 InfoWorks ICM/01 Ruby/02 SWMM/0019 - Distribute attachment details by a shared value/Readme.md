This script was based on a client request, where they have a PDF attached to a single survey which is related to multiple surveys. 
The surveys share the job_number field value.

The script will identify CCTV Surveys which have a single PDF attachment, wite the attributes to an array, then go through the CCTV Surveys which don't have a PDF attachment and if there is attributes in the aray matching the survey's job_number field, wite the values to the survey's attachments blob.