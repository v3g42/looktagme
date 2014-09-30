class HomeListView
	@listTemplate: null
	@elem: null
	constructor: (elem, json)->
		@listTemplate = Handlebars.compile $('#home-list').html()
		@elem = $(elem)
		@json = json

	initScroll: (cbk)->
		self = this
		@elem.infiniteScroll
		  url: '/home'
			,calculateBottom: ->
					(self.elem.position().top + self.elem.height()) - $(window).height() + 50
			,getData: ->
				{page: $('.next-page:last').data('next-page')}
			,processResults: cbk

	masonry: ->
		self = @
		$container = $('.listProducts:last')
		$container.imagesLoaded ->
			console.log("LOADED")
			self.elem.addClass('loaded')
			$container.masonry
				itemSelector : '.item'
			#columnWidth : if $('.tag_editor').hasClass('horizontal-image') then 240 else 220
				columnWidth : 240
				isAnimated: false

	render: ()->
		self = @
		@elem.html(@listTemplate({results:@json.results, next_page: @json.metadata.page+1,total: @json.metadata.total}))
		@masonry()
		@initScroll  (json,opts)->
			self.elem.append(self.listTemplate({results:json.results, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
			#self.masonry()


$ ->
	homeView = new HomeListView('#home_container', window.json)
	homeView.render()




