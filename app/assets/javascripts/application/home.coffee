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
		  url: '/home'
			,calculateBottom: ->
					(self.elem.position().top + self.elem.height()) - $(window).height() + 50
			,getData: ->
				{page: $('.next-page:last').data('next-page')}
			,processResults: cbk


	createViewer: (masonryImage, parent)->
		self = @
		json.results.map (image)->
			return if image.id != $(masonryImage).data('image-id')
			self.viewers[image.id] = new LookTagMe.Viewer(self,masonryImage,image.tags) unless self.viewers[image.id]
			parent.find('a').click (e)->
				e.stopPropagation()
				e.preventDefault()
				self.onEdit self.viewers[image.id]

	masonry: ($container)->
		self = @
		self.msnry = msnry = $container.masonry
			itemSelector : '.item'
			transitionDuration: 0

		$container.imagesLoaded( ->
			msnry.masonry()
		).progress (int, image)->
			setTimeout ->
				msnry.masonry()
				parent = $(image.img).parents('.item')
				parent.addClass('loaded')
				self.createViewer(image.img, parent)
			, 0


		$(window).resize ->
			self.msnry.masonry()


	render: ()->
		self = @
		listResults = $('<div class="listProducts"/>')
		listResults.html(@listTemplate({results:@json.results, next_page: @json.metadata.page+1,total: @json.metadata.total}))
		@elem.html(listResults)
		$container = $('.listProducts:last')
		@masonry $container
		@initScroll  (json,opts)->
			$resultsHTML = $(self.listTemplate({results:json.results, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
			self.elem.find('.listProducts').append($resultsHTML)
			#self.msnry.masonry( 'appended', $resultsHTML, true )

	initGlass: (@min_width=100, @min_height=100) ->
		@editing = undefined
		$(window).on('scroll touchmove mousewheel', @editScrollListener)
		@glass = $('<div class="tagger-editor-glass"/>')
		@glass.hide()
		@editor = $('<div class="tagger-editor-container"><div class="clearfix editor-header"><a class="pull-left" href="/">LookTagMe</a> <a href="#" class="editor-close pull-right">Close</</a></div></div>')
		$(@editor).find('.editor-close').on 'click', (event) => @onEditorClose(event)
		@editor.hide()
		$('body').append(@editor)
		$('body').append(@glass)
		$(window).resize () =>
			@editor.find('iframe').each (idx, itm) => itm.contentWindow.postMessage('resize', @base_url)

	onEditorClose: (event) =>
		event.preventDefault()
		event.stopPropagation()
		@glass.hide()
		@editor.hide()
		@editor.children('iframe').remove()
		@editing = undefined
		window.location.reload()

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




