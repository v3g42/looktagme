

class Injector
	constructor: (@items) ->

	inject_script: (url, index) =>
		script = document.createElement("script")
		script.src = url + '?v=' + parseInt(Math.random()*99999999)
		script.onload = () =>
			@inject_item(index+1)
		document.getElementsByTagName("head")[0].appendChild(script);

	inject_css: (url, index) =>
		link = document.createElement("link");
		link.rel = 'stylesheet';
		link.type = 'text/css';
		link.href = url + '?v=' + parseInt(Math.random()*99999999);
		document.getElementsByTagName("head")[0].appendChild(link);
		@inject_item(index+1)

	inject_item: (index) =>
		if @items.length < (index+1)
			if (@done) then @done()
			return
		script = @items[index] 
		if script.indexOf('.js') == script.length - 3
			@inject_script(script, index)
		else if script.indexOf('.css') == script.length - 4
			@inject_css(script, index)
		else
			@inject_item(index++)

	inject: =>
		@inject_item(0)


injector = new Injector([
	"https://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.1/jquery.min.js"
 	window.$TAGGER.base_url + "/assets/includes/external.css"
 	window.$TAGGER.base_url + "/assets/external/common.js"
    window.$TAGGER.base_url + "/assets/external/tagger.js"
    window.$TAGGER.base_url + "/assets/external/embed.js"
])
injector.inject()



