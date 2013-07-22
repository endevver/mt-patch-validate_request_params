mt-patch-validate_request_params
================================

A patch to MT::App to fix an issue with uploading content from a mobile device.

When using the public mt-cp.cgi endpoint to post an entry with an 'image' custom field, the validate_request_params sub in MT::App is called to verify the encoding of the parameters is equal to the encoding of the MT installation.  However, the regular expression to extract the 'charset' from the CONTENT_TYPE HTTP header has a bug in it so it sometimes extracts a string that is too long, and the subsequent code that re-encodes the parameter values assumes any parameter that has a value which is a reference must be an ARRAY reference, which breaks down in case it is actually a filehandle (as is the case with image custom field uploads).

A bug report has been sent to Six Apart about this: https://movabletype.fogbugz.com/default.asp?110256

This patch replaces the broken validate_request_params with a working version.  It was tested on MTE 4.37.