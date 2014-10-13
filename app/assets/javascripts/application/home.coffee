class HomeListView
	@listTemplate: null
	@elem: null
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


	createViewers: (json)->
		self = @
		json.results.map (image)->
			imgCont = $('.item.product[data-image-id=' + image.id + ']')
			self.viewers[image.id] = new LookTagMe.Viewer(self,imgCont.find('img'),image.tags) unless self.viewers[image.id]
			imgCont.find('a').click (e)->
				e.stopPropagation()
				e.preventDefault()
				self.onEdit self.viewers[image.id]


	masonry: (msnry)->
		self = @
		msnry.imagesLoaded ->
			console.log("LOADED")
			self.createViewers(self.json)
			self.elem.addClass('loaded')
			msnry.masonry('reloadItems')
			msnry.masonry()


	render: ()->
		self = @
		listResults = $('<div class="listProducts"/>')
		listResults.html(@listTemplate({results:@json.results, next_page: @json.metadata.page+1,total: @json.metadata.total}))
		@elem.html(listResults)
		$container = $('.listProducts:last')
		msnry = $container.masonry
			itemSelector : '.item'
			isAnimated: false
		@masonry msnry
		@initScroll  (json,opts)->
			self.elem.find('.listProducts').append(self.listTemplate({results:json.results, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
			self.masonry msnry

	initGlass: (@min_width=100, @min_height=100) ->
		@editing = undefined
		$(window).on('scroll touchmove mousewheel', @editScrollListener)
		@glass = $('<div class="tagger-editor-glass"/>')
		@glass.hide()
		@editor = $('<div class="tagger-editor-container"><div class="close"/></div>')
		$(@editor).children('.close').on 'click', () => @onEditorClose()
		@editor.hide()
		$('body').append(@editor)
		$('body').append(@glass)
		$(window).resize () =>
			@editor.find('iframe').each (idx, itm) => itm.contentWindow.postMessage('resize', @base_url)

	onEditorClose: () =>
		@glass.hide()
		@editor.hide()
		@editor.children('iframe').remove()
		@editing = undefined

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




