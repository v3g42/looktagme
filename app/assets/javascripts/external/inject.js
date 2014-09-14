(function(){

	var localurl = window.$TAGGER.base_url;

	var injectScript = function(url, cb) {

		var done = false;
		var script = document.createElement("script");
		script.src = url + '?v=' + parseInt(Math.random()*99999999);
		script.onload = script.onreadystatechange = function(){
			if (!done && (!this.readyState || this.readyState == "loaded" || this.readyState == "complete")) {
				done = true;
				cb();
			};
		};
		document.getElementsByTagName("head")[0].appendChild(script);
	};

	var injectCss = function(url, cb) {
		var link = document.createElement("link");
		link.rel = 'stylesheet';
		link.type = 'text/css';
		link.href = url + '?v=' + parseInt(Math.random()*99999999);
		document.getElementsByTagName("head")[0].appendChild(link);
		cb();
	};

	function endsWith(str, suffix) {
	    return str.indexOf(suffix, str.length - suffix.length) !== -1;
	};

	var inject = function(url, cb) {
		if (endsWith(url, '.js'))
			injectScript(url, cb);
		else if (endsWith(url, '.css'))
			injectCss(url, cb);
	};

//	var scripts = [
//		localurl + "/assets/includes/external.css",
//		localurl + "/assets/includes/external.js"
//	];
    var scripts = [
            "https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js",
            localurl + "/assets/includes/external.css",
            localurl + "/assets/external/tagger.js",
            localurl + "/assets/external/embed.js"
    ];
	var currIdx = 0;

	var injected = function() {
		currIdx++;
		if (currIdx < scripts.length) {
			inject(scripts[currIdx], injected);
		}
	};

	inject(scripts[currIdx], injected);

})();
