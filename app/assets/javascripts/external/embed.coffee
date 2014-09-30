

class LookTagMePage

	constructor: (@viewer, @base_url, @app_id, @min_width, @min_height) ->
		@editor = $('<div class="tagger-editor-container"><iframe/></div>')
		@editor.hide();
		$('body').append(@editor)
		$(window).resize () =>
			@editor.find('iframe')[0].contentWindow.postMessage('resize', @base_url)
		if window.addEventListener then addEventListener("message", @postListener, false)
		else attachEvent("onmessage", @postListener)

	fetchTags: (img) =>
		req = $.ajax
			url: @base_url + "/tags?app_id=" + @app_id + "&image_url=" + encodeURIComponent(img.src)
			dataType: 'json'
			success: (data) => @createViewer(img, data.tags)
			error: (xhr) => @createViewer(img, [])
			contentType: 'application/json'
			crossDomain: true

	createViewer: (img, tags) =>
		console.log(tags)
		t = new @viewer(img, tags)
		t.onEdit (id, img_url) =>
			target_url = 
				@base_url + "/tags/edit?" + 
				'image_url=' + encodeURIComponent(img_url) + 
				'&page_url='+encodeURIComponent(window.location.href) + 
				'&domain='+encodeURIComponent(window.location.protocol+"//"+window.location.host) + 
				'&dom_id='+ encodeURIComponent(id)

			$('.tagger-editor-container').data('editing',true)
			$('.tagger-editor-container').show()
			$('.tagger-editor-container').find('iframe').attr('src', target_url)
			$(window).on('scroll touchmove mousewheel', @editScrollListener)

	postListener: (e) =>
		if e.origin == @base_url
			obj = JSON.parse(e.data)
			tagger = $('#' + obj.dom_id).data('tagger')
			tagger.clearTags()
			tagger.tags = obj.tags
			tagger.showTags()
			@editor.hide()
			@editor.data('editing',false)
			$(window).off('scroll touchmove mousewheel', @editScrollListener)
		
	editScrollListener: (e) =>
		if $('.tagger-editor-container').data('editing')
			e.stopPropagation()
			e.preventDefault()
			return false

	apply: =>
		$('img').each (i, img) =>
			if $(img).width() >= @min_width and $(img).height() >= @min_height
				@fetchTags(img)


	new LookTagMePage(
		LookTagMe.Viewer
		window.$TAGGER.base_url
		window.$TAGGER.app_id
		100, 100
	).apply()

			