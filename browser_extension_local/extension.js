  /************************************************************************************
  This is your Page Code. The appAPI.ready() code block will be executed on every page load.
  For more information please visit our docs site: http://docs.crossrider.com
*************************************************************************************/
var BASE_URL= 'http://localhost:4000/';

var JS = [
    "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"
    , BASE_URL + "/assets/external/common.js"
    , BASE_URL + "/assets/external/tagger.js"
    , BASE_URL + "/assets/external/embed.js"
];

var CSS = [
        BASE_URL + "/assets/includes/external.css"
];

appAPI.ready(function($) {

	appAPI.dom.addInlineJS('window.$TAGGER= {};window.$TAGGER.base_url = "'+BASE_URL+'";');
    appAPI.dom.addInlineJS('window.LookTagMe = {};window.LookTagMe.base_url = window.$TAGGER.base_url;');

	CSS.map(function(str){
		appAPI.dom.addRemoteCSS(str);
	})
	JS.map(function(str){
		appAPI.dom.addRemoteJS(str);
	})
  	

    // Place your code here (you can also define new functions above this scope)
    // The $ object is the extension's jQuery object

    var appId = appAPI.appInfo.id;
    var appName = appAPI.appInfo.name;
    var appDesc = appAPI.appInfo.description;
    var appVersion = appAPI.appInfo.version;
    // The browser specific id of the user who installed the extension via the browser
    var appUserId = appAPI.appInfo.userId;
    // The environment, staging or production, in which the extension is running
    var appEnv = appAPI.appInfo.environment;
    
    console.log('The following information is available about your extension:\n' +
          '    Id: ' + appId + '\n' +
          '    Name: ' + appName + '\n' +
          '    Description: ' + appDesc + '\n' +
          '    Version: ' + appVersion + '\n' +
          '    User Id: ' + appUserId + '\n' +
          '    Environment: ' + appEnv);



});
