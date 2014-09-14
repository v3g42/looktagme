# Skimlinks product API -> http://api-product.skimlinks.com/query?q=playstation%203%20console&key=aabbccddeeffgghhiijjkk1122334455&rows=1&start=0&format=json
# Skimlinks category API ->  http://api-product.skimlinks.com/categories?key=aabbccddeeffgghhiijjkk1122334455&format=json
declareProps = (model, fields)->
	model = model || {}
	(model[field]= model[field] || null) for field in fields
	model

colors = [
	{name:'Red', color: 'rgb(255,0,0)'},
	{name:'Rose', color: 'rgb(255,0,127)'},
	# {name:'Aquamarine', color: 'rgb(O, 255, 127)'},
	# {name:'Azure', color: 'rgb(O, 127, 255)'},
	{name:'Orange', color: 'rgb(255,127,0)'},
	{name:'Yellow', color: 'rgb(255,255, 0)'},
	{name:'Magenta',color: 'rgb(255, 0, 255)'},
	{name:'Violet', color: 'rgb(127, 0, 255)'},
	{name:'Chartreuse', color: 'rgb(127, 255, 0)'},
	{name:'Blue', color: 'rgb(0, 0, 255)'},
	{name:'Green', color: 'rgb(0, 255, 0)'},

	{name:'Cyan', color: 'rgb(0, 255, 255)'}
	]

Sidebar = (options)->
	this.elem = elem = options.sidebarEl
	this.img = options.img
	this.editor = options.editor


	this.props = ['title', 'description', 'price', 'url', 'image_url', 'image_width', 'image_height', 'currency', 'raw_details', 'seller_name', 'seller_url' ]
	this.currentTag = null
	this.watchable = null
	this.alertTemplate = Handlebars.compile $('#editor-alert').html()
	this.listTemplate = Handlebars.compile $('#editor-list').html()
	this.productsTemplate = Handlebars.compile $('#editor-recent').html()
	this.render = null

	this
Sidebar.prototype.adjustHeights = ->
	height = $('.left_section img').height()
	wHeight = $(window).height()
	fHeight = $('.right_section form').height()
	pt = (wHeight-height-30)/2
	$('.left_section').css('padding-top', pt) if(pt > 0)
	#$('.details').css('max-height', height-fHeight)
	console.log(height-fHeight)
Sidebar.prototype.addFilter = (filter)->

Sidebar.prototype.initSearch = (tag)->
	self = this
	search_elem = self.elem.find('.product_search')
	colorsDiv = self.elem.find('.colors')
	for c in colors
		div = $('<div class="'+c.name.toLowerCase()+' color">')
		div.css('background-color',c.color)
		colorsDiv.append(div)
	suggestionsList = ->
		findMatches = (q, cb) ->
			matches = []
			# $.each ['categories', 'brands'], (i, str)->
			#   matches.push {title: str + " like " + q}
			cb(matches)

	search_elem.typeahead null,
			name: 'products',
			displayKey: 'title',
			source: suggestionsList()
			#self.productsAdpt.ttAdapter()
			# templates: {
			# 	suggestion: self.suggestionTemplate
			# }
		search_elem.on 'typeahead:selected', (evt, obj, name) ->
				evt.preventDefault();
				search_elem.typeahead('val', '');
				self.addFilter search_elem.typeahead('val')
				#self.selectSuggestion(obj)


Sidebar.prototype.selectTag = (tag)->
	self = this

	window.currentTag = this.currentTag = declareProps(tag, this.props)

	self.render = ()->
		$('.right_section').addClass('searching')
		$('.searchForm').submit (event)->
			event.preventDefault()
			self.searchProducts()
		#self.adjustHeights()


	self.render()

	self.initSearch()





Sidebar.prototype.saveTag = (tag)->
	self = this
	for prop in self.props
		self.currentTag[prop] = tag[prop]

	self.editor.update(currentTag)
	page_url = $('#page_url').val()
	domain = $('#domain').val()
	data = $.extend {}, currentTag
	data.image_url = self.img.attr('src')
	data.page_url = page_url
	jQuery.post('/tags', data)
	.done (tag)->
		self.alert("success", "Tags saved!")
		data.id = id;
		self.renderRecent()
		self.currentTag = null
	.fail ->
		self.alert("danger", "Server Error!")

Sidebar.prototype.deleteTag = (tag_id)->
	self = this

	page_url = $('#page_url').val()
	domain = $('#domain').val()
	data = {image_url: self.img.attr('src'), id: tag_id, page_url: page_url }
	jQuery.ajax({url: '/tags', data: data, type: 'DELETE'})
	.done((image)->
		self.alert("success", "Tag deleted!")
		self.renderRecent()
		self.currentTag = null
	).fail(()->
		self.alert("danger", "Server Error!")
	)

Sidebar.prototype.init = ()->
	self = this


	#self.adjustHeights()
	# this.productsAdpt = new Bloodhound
	#   	datumTokenizer: Bloodhound.tokenizers.obj.whitespace('title')
	#   	queryTokenizer: Bloodhound.tokenizers.whitespace
	#   	limit: 10
	#
	# this.productsAdpt.initialize()
	#self.renderRecent()



Sidebar.prototype.alert = (type, msg)->
	self = this
	details = self.elem.find('.details')
	details.find('.alert').remove()
	details.prepend(self.alertTemplate({class: type, message: msg}))


Sidebar.prototype.masonry = ($container)->
	$container.imagesLoaded ->
		$container.masonry
			itemSelector : '.item'
			columnWidth : 220
			isAnimated: true

Sidebar.prototype.searchProducts = ()->
	self = this
	$('.details').html('')
	$('.details').addClass('loading')
	search = $('.product_search:eq(1)').val()
	self.results = []
	jQuery.get('/search?q='+search)
	.done((results)->
		console.log(results)
		self.results = results
		$('.details').html(self.listTemplate({results:results}))
		$('.details').removeClass('loading')
		$container = $('.searchProducts')
		self.masonry $container
		jQuery('.searchProduct').click (event, el)->
			$('.searchProduct.selected').removeClass('selected')
			$(event.currentTarget).addClass('selected')
		jQuery('.saveProduct').click (event, el)->
			id = $(event.currentTarget).data('product-id')
			console.log self.results[id]
			self.saveTag(self.results[id])

	).fail(()->
		self.alert("danger", "Server Error!")
		$('.details').removeClass('loading')
	)

Sidebar.prototype.renderRecent = ()->
	self = this
	self.results = []
	$('.details').html('')
	$('.details').addClass('loading')
	$('.right_section').removeClass('searching')
	image_url = self.img.attr('src')
	jQuery.get('/tags/recent?image_url='+image_url)
	.done((image)->
		console.log(image)
		$('.details').html(self.productsTemplate({results:image.tags}))
		$('.details').removeClass('loading')
		search_elem = self.elem.find('.product_search')
		search_elem.typeahead('val', '')
		jQuery('.deleteProduct').click (event, el)->
			id = $(event.currentTarget).data('tag-id')
			self.deleteTag(id)

	).fail(()->
		self.alert("danger", "Server Error!")
		$('.details').removeClass('loading')
	)

jQuery ()->
	fetchTags = (img) ->
		app_id = page_url = $('#page_url').val()
		req = $.ajax(
			url: "/tags?app_id=" + encodeURIComponent(app_id) + "&image_url=" + encodeURIComponent(img.src)
			dataType: "json"
			success: (data) ->

			sidebar.init()
			error: (xhr) ->
				sidebar.init()
		)
	imgEl = jQuery('.left_section img')

	init = ()->
		if window.imageData
			editor = new window.$TAGGER.Editor(imgEl, window.imageData.tags)
		else
			editor = new window.$TAGGER.Editor(imgEl, [])

		sidebar = new Sidebar
			sidebarEl: jQuery('.right_section')
			img: imgEl
			editor: editor

		sidebar.init()
		jQuery('.close_edit').click ->
			try
				page_url = $('#page_url').val()
				domain = $('#domain').val()
				dom_id = $('#dom_id').val()
				data = {image_url: sidebar.img.attr('src'), tags: sidebar.editor.getTags(), page_url:page_url,dom_id : dom_id  }
				window.parent.postMessage(JSON.stringify(data), domain);
			catch e
				console.log e
			#editor.hide();

		editor.on 'selected', (e, item)->
			sidebar.selectTag(item);

	if imgEl[0].width
		init()
	else
		imgEl.on 'load', init
