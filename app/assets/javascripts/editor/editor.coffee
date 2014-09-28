# Skimlinks product API -> http://api-product.skimlinks.com/query?q=playstation%203%20console&key=aabbccddeeffgghhiijjkk1122334455&rows=1&start=0&format=json
# Skimlinks category API ->  http://api-product.skimlinks.com/categories?key=aabbccddeeffgghhiijjkk1122334455&format=json
declareProps = (model, fields)->
	model = model || {}
	(model[field]= model[field] || null) for field in fields
	model

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
	colorsDiv.html('')
	for c in window.colors
		div = $('<div class="color"><div class="'+c.name.toLowerCase()+' color-grid"></div></div>')
		div.find('.color-grid').css('background-color',c.color)
		div.data('color', c.id)
		div.find('.color-grid').css('border-style','solid')
		div.find('.color-grid').css('border-width','1px')
		div.find('.color-grid').css('border-color','rgb(200,200,200)')
		div.click ->
			# $('.color').removeClass('selected')
			$(this).toggleClass('selected')
			self.searchProducts() if(self.searched)


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
	$('.details').html('')
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
	delete data.id
	delete data.raw_details
	jQuery.ajax(
		type: 'post'
		url: '/tags'
		beforeSend: (xhr) ->
			xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
		data: data
	).done (tag)->
		self.alert("success", "Tags saved!")
		self.renderRecent()
		self.currentTag = null
	.fail ->
		self.alert("danger", "Server Error!")

Sidebar.prototype.deleteTag = (tag_id, image_id)->
	self = this

	page_url = $('#page_url').val()
	domain = $('#domain').val()
	data = {image_url: self.img.attr('src'), id: tag_id, image_id: image_id, page_url: page_url }
	jQuery.ajax
		url: '/tags'
		data: data
		type: 'DELETE'
		beforeSend: (xhr) ->
			xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
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
	self.renderRecent()



Sidebar.prototype.alert = (type, msg)->
	self = this
	details = self.elem.find('.details')
	details.find('.alert').remove()
	details.prepend(self.alertTemplate({class: type, message: msg}))


Sidebar.prototype.masonry = ($container)->
	$container.imagesLoaded ->
		$container.masonry
			itemSelector : '.item'
			#columnWidth : if $('.tag_editor').hasClass('horizontal-image') then 240 else 220
			columnWidth : 240
			isAnimated: true

Sidebar.prototype.getSearchFilters = ()->
	filters = {}

	# Color Filter
	if $('.color.selected').length>0
		colors = []
		$('.color.selected').each ->
			colors.push $(this).data('color')
		filters["color"] = colors.join("_")

	# Price Filter
	price_range = $('.price-slider').val().split(',')
	gt = window.prices[price_range[0]]["id"]
	lt = window.prices[price_range[1]]["id"]
	filters["price"] = "p"+gt+"_"+lt
	filters
Sidebar.prototype.searchProducts = ()->
	self = this




	$('.details').html('')
	$('.details').addClass('loading')
	search = $('.product_search:eq(0)').val() || $('.product_search:eq(1)').val() || ""
	self.results = []
	jQuery.get('/search?q='+search,self.getSearchFilters())
	.done((results)->
		self.searched = true
		console.log(results)
		self.results = results
		$('.details').html(self.listTemplate({results:results.results}))
		$('.details').removeClass('loading')
		jQuery('.saveProduct').click (event, el)->
			id = $(event.currentTarget).data('product-id')
			console.log self.results[id]
			self.saveTag(self.results[id])

		$container = $('.searchProducts')
		self.masonry $container

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
		$('.details').html(self.productsTemplate({results:image.tags, image_id:image._id.$oid}))
		$('.details').removeClass('loading')
		search_elem = self.elem.find('.product_search')
		search_elem.typeahead('val', '')
		jQuery('.deleteProduct').click (event, el)->
			id = $(event.currentTarget).data('tag-id')
			self.deleteTag(id, image._id.$oid)

	).fail(()->
		#self.alert("danger", "Server Error!")
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

	window.init = init = ()->
		imgEl = jQuery('.left_section img')
		console.log imgEl[0].width
		if window.imageData
			editor = new window.$TAGGER.Editor(imgEl, window.imageData.tags)
		else
			editor = new window.$TAGGER.Editor(imgEl, [])

		sidebar = new Sidebar
			sidebarEl: jQuery('.right_section')
			img: imgEl
			editor: editor

		sidebar.init()

		$('.price-slider').slider()
		$('.price-slider').on "slideStop", (slideEvt) ->
			sidebar.searchProducts() if sidebar.searched

		$('.price-slider').on "slide", (slideEvt) ->
			lt = window.prices[slideEvt.value[0]]["range"][0]
			gt = window.prices[slideEvt.value[1]]["range"][1]
			if gt
				val = lt + "-" + gt + "$"
			else
			  val = "Over " + lt + "$"
			$('.price-range').html(val)
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

	imgEl.imagesLoaded ->
		init()
