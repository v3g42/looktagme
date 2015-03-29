class HomeListView
	@listTemplate: null
	@elem: null
	@msnry: null
	viewers: {}
	constructor: (elem, json)->
		@listTemplate = Handlebars.compile $('#home-list').html()
		@elem = $(elem)
		@json = json
		@initGlass()


	initScroll: (cbk)->
		self = this
		@elem.infiniteScroll
			url: '/'
			calculateBottom: -> (self.elem.position().top + self.elem.height()) - $(window).height() + 50
			getData: -> {page: $('.next-page:last').data('next-page')}
			processResults: cbk



	createViewer: (masonryImage, parent)->
		self = @
		json.results.map (image)->
			return if image.id != $(masonryImage).data('image-id')
			self.viewers[image.id] = new LookTagMe.Viewer(self,masonryImage,image.tags) unless self.viewers[image.id]
			parent.find('a').click (e)->
				e.stopPropagation()
				e.preventDefault()
				self.onEdit self.viewers[image.id]

	masonry: ($container, $content, callback, first=false)->
		self = this
		$cachedContainer = $('#cachedImages')

		if first
			$cachedContainer.html($content)
			self.msnry = $container.masonry
				itemSelector : '.item'
				transitionDuration: 0
			$(window).resize ->
				self.msnry.masonry()
		else
			$cachedContainer.append($content)

		$cachedContainer.imagesLoaded().progress (int, image)->
			parent = $(image.img).parents('.item')
			parent.detach()
			$container.append(parent)
			$container.masonry( 'appended', parent )
			$container.masonry()
			callback(parent)

	render: ()->
		self = @
		initAppendedSearch = (parent) ->
			self.createViewer(parent.find('img'), parent)


		$content = @listTemplate({results:@json.results, next_page: @json.metadata.page+1,total: @json.metadata.total})
		$container = $('<div class="listProducts" />')
		@elem.html($container)

		self.masonry $container, $content,initAppendedSearch, true
		@initScroll  (json,opts)->
			json.results  = JSON.parse(json.results) unless json.results instanceof Array
			$content = $(self.listTemplate({results:json.results, next_page: json.metadata.page+1,total: json.metadata.total}))
			self.masonry $container, $content,initAppendedSearch, false

		@initHistory()

	initGlass: (@min_width=100, @min_height=100) ->
		@editing = undefined
		$(window).on('scroll touchmove mousewheel', @editScrollListener)
		@glass = $('<div class="tagger-editor-glass"/>')
		@glass.hide()
		@editor = $('<div class="tagger-editor-container"><div class="clearfix editor-header"><a class="pull-left" href="/">HeyTagMe</a> <a href="#" class="editor-close pull-right">Close</</a></div></div>')
		$(@editor).find('.editor-close').on 'click', (event) ->
			event.preventDefault()
			event.stopPropagation()
			history.back()
		@editor.hide()
		$('body').append(@editor)
		$('body').append(@glass)
		$(window).resize () =>
			@editor.find('iframe').each (idx, itm) => itm.contentWindow.postMessage('resize', @base_url)


	initHistory:() =>
		location = window.history.location or window.location
		@base_location = location.href
		$(window).on "popstate", (e) =>
			@onEditorClose() if @base_location==location.href

	onEditorClose: () =>
		@glass.hide()
		@editor.hide()
		@editor.children('iframe').remove()
		@fetchTags(@editing)
		@editing = undefined



	fetchTags: (viewer) =>
		req = $.ajax
			url: "/tags?image_url=" + encodeURIComponent(viewer.getUrl())
			dataType: 'json'
			success: (data) => viewer.updateTags(data.tags)
			error: (xhr) =>
			contentType: 'application/json'
			crossDomain: true

	onEdit: (v) =>
		target_url = "/tags/edit?" +
			'image_url=' + encodeURIComponent(v.getUrl()) +
			'&page_url='+encodeURIComponent(window.location.href) +
			'&domain='+encodeURIComponent(window.location.protocol+"//"+window.location.host) +
			'&dom_id='+ encodeURIComponent(v.getId())

		console.log(target_url)
		@editing = v
		@glass.show()
		@editor.show()
		history.pushState null, null, target_url
		iframe = $('<iframe/>')
		@editor.append(iframe)
		iframe.attr('src', target_url)

	postListener: (e) =>
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


$ ->
	homeView = new HomeListView('#home_container', window.json)
	homeView.render()


	#show bookmarklet link
#	bool = $.cookie("show_bookmarklet_notification") || true
#	if true || bool != "false"
#		$.bootstrapGrowl $('#downloads').html(), {type: 'notice', delay: 0, offset: {from: 'top', amount: 300}}
#		$.cookie("show_bookmarklet_notification", false)






