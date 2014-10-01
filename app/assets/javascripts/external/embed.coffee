

class LookTagMePage

	constructor: (@viewer, @base_url, @app_id, @min_width, @min_height) ->
		@editing = undefined
		$(window).on('scroll touchmove mousewheel', @editScrollListener)
		@glass = $('<div class="tagger-editor-glass"/>')
		@glass.hide()
		@editor = $('<div class="tagger-editor-container"><div class="close"/><iframe/></div>')
		$(@editor).children('.close').on 'click', () => @onEditorClose()
		@editor.hide()
		$('body').append(@editor)
		$('body').append(@glass)
		$(window).resize () =>
			@editor.find('iframe')[0].contentWindow.postMessage('resize', @base_url)
		if window.addEventListener then addEventListener("message", @postListener, false)
		else attachEvent("onmessage", @postListener)

	onEditorClose: () =>
		@glass.hide()
		@editor.hide()
		@fetchTags(@editing)
		@editing = undefined

	onEdit: (v) =>
		target_url = 
			@base_url + "/tags/edit?" + 
			'image_url=' + encodeURIComponent(v.getUrl()) + 
			'&page_url='+encodeURIComponent(window.location.href) + 
			'&domain='+encodeURIComponent(window.location.protocol+"//"+window.location.host) + 
			'&dom_id='+ encodeURIComponent(v.getId())

		console.log(target_url)
		@editing = v	
		@editor.find('iframe').attr('src', '')
		@glass.show()
		@editor.show()
		@editor.find('iframe').attr('src', target_url)

	fetchTags: (viewer) =>
		req = $.ajax
			url: @base_url + "/tags?app_id=" + @app_id + "&image_url=" + encodeURIComponent(viewer.getUrl())
			dataType: 'json'
			success: (data) => viewer.updateTags(data.tags)
			error: (xhr) => 
			contentType: 'application/json'
			crossDomain: true

	createViewer: (img) =>
		viewer = new @viewer(@, img, [])

	postListener: (e) =>
		if e.origin == @base_url
			obj = JSON.parse(e.data)
			tagger = $('#' + obj.dom_id).data('tagger')
			tagger.clearTags()
			tagger.tags = obj.tags
			tagger.showTags()
			@editor.hide()
			$(window).off('scroll touchmove mousewheel', @editScrollListener)
		
	editScrollListener: (e) =>
		if @editing != undefined
			e.stopPropagation()
			e.preventDefault()
			return false

	apply: =>
		$('img').each (i, img) =>
			if $(img).width() >= @min_width and $(img).height() >= @min_height
				viewer = @createViewer(img)
				@fetchTags(viewer)


	LookTagMe.page = new LookTagMePage(
		LookTagMe.Viewer
		window.$TAGGER.base_url
		window.$TAGGER.app_id
		100, 100
	).apply()

			