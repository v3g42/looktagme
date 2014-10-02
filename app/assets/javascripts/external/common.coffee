
window.LookTagMe = {}

class MouseTracker 
	constructor: () ->
	start: () =>
		$(window).on 'mousemove', (e) => 
			@x = e.pageX
			@y = e.pageY

class Logger
	constructor: (@source) ->
		@level = 4
	err: (str) => if window.console and @level > 0 then console.log('ERROR: ' + @source + ' - ' + str)
	warn: (str) => if window.console and @level > 1 then console.log('WARNING: ' + @source + ' - ' + str)
	info: (str) => if window.console and @level > 2 then console.log('INFO: ' + @source + ' - ' + str)
	debug: (str) => if window.console and @level > 3 then console.log('DEBUG: ' + @source + ' - ' + str)

class ImageUtils
	@imageFit: (url, width, height, cb) ->
		img = new Image()
		img.onload = () ->
			w = h = 0
			if img.width > img.height
				w = width
				h = w * img.height / img.width
			else
				h = height
				w = img.width * h / img.height
			cb(true, w, h)
		img.onerror = () -> cb(false)
		img.src = url;


window.LookTagMe.Logger = Logger
window.LookTagMe.ImageUtils = ImageUtils

window.LookTagMe.cursor = new MouseTracker()
window.LookTagMe.cursor.start()

