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


	this.props = ['title', 'description', 'price', 'image_url', 'image_width', 'image_height', 'currency', 'seller_name', 'seller_url' ]
	this.currentTag = null
	this.watchable = null
	this.alertTemplate = Handlebars.compile $('#editor-alert').html()
	this.listTemplate = Handlebars.compile $('#editor-list').html()
	this.productsTemplate = Handlebars.compile $('#editor-recent').html()
	this.pasteProductTemplate = Handlebars.compile $('#editor-paste').html()
	this.render = null
	this.filters = []
	this.msnry = null

	this
Sidebar.prototype.toggleFilters = ()->
	containers = [$('.right_section .filters')]
	containers.map (container)->
		if(container.find('.searchFilter').length>0)
			container.show()
		else
			container.hide()

Sidebar.prototype.resetFilters = ()->
	self = this
	$('.right_section .colors .selected').removeClass('selected')
	$('.price-slider').slider('setValue',[0,window.prices.length-1])
	search_elem = self.elem.find('.product_search')
	search_elem.tagsinput('destroy')


Sidebar.prototype.addFilter = (filter, name, force = true)->
	self = this
	console.log(filter + " : " + name)
	container = $('.right_section .filters')
	return if container.find('.searchFilter.'+filter["id"]).length>0
	type = "danger"
	if name == "brands"
		type = "info"
	else if name == "categories"
	  type = "warning"
	filterDiv = $(self.alertTemplate({class: type+" "+name, message: filter["name"],css:"searchFilter " + filter["id"] }))
	if name =="categories"
		filterDiv.data('category', filter["id"])
	else if name in ["brands", "retailers"]
		filterDiv.data('filter', name[0]+filter["id"])
	else if name == "search"
		filterDiv.data('search', filter["name"])

	filterDiv.find('.close').click ->
		filterDiv.remove()
		self.toggleFilters()
		self.searchProducts()
	container.append(filterDiv)
	self.toggleFilters()
	self.searchProducts() unless force == false #if self.searched


Sidebar.prototype.initScroll = (cbk)->
	self = this
	$('.details').infiniteScroll('destroy') if $('.details').data('infinite-search')
	$('.details').infiniteScroll
		url: '/search'
		,calculateBottom: ->
			($('.details').position().top + $('.details').height()) - $(window).height() + 50
		,getData: ->
			data = self.getSearchFilters()
			data.offset = $('.next-page:last').data('next-page')
			data
		,processResults: cbk




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
			$(this).toggleClass('selected')
			self.searchProducts() if(self.searched)
		colorsDiv.append(div)

	#search_elem.typeahead('destroy')
	search_elem.tagsinput
		tagClass: (item)->
			cssClass = "success"
			label = if typeof item == "string" then "search" else item.label
			if item.label == "brands"
				cssClass = "info"
			else if item.label == "categories"
				cssClass = "warning"
			else if item.label == "retailers"
				cssClass = "danger"
			"searchFilter label "+ label + "  label-" + cssClass
		itemText: (item)->
			if typeof item == "string"
				item
			else
				item.name
		itemValue: (item)->
			if typeof item == "string"
				item
			else item
	search_elem.tagsinput('input').typeahead
					highlight: true
					minLength: 2
					hint: false
				,
						name: 'categories',
						displayKey: 'name',
						source: self.categoriesAdapt.ttAdapter()
						templates:
							header: '<p class="typeahead-header">Categories</p>'
				,
						name: 'brands',
						displayKey: 'name',
						source: self.brandsAdapt.ttAdapter()
						templates:
							header: '<p class="typeahead-header">Brands</p>'
				,
						name: 'retailers',
						displayKey: 'name',
						source: self.retailersAdapt.ttAdapter()
						templates:
							header: '<p class="typeahead-header">Retailers</p>'
	search_elem.tagsinput('input').on('typeahead:selected', $.proxy (obj, datum) ->
		if (typeof datum=="string")
			search_elem.tagsinput('add',datum);
		else
			search_elem.tagsinput 'add', datum.name
		search_elem.tagsinput('input').typeahead('val', '');

	, search_elem)

	search_elem.on 'itemAdded', (event)->
		self.searchProducts(window.currentTag)
		search_elem.tagsinput('input').typeahead('val', '');




Sidebar.prototype.selectTag = (tag, editMode)->
	self = this
	$('.details').html('')
	window.currentTag = this.currentTag = declareProps(tag, this.props)

	self.render = ()->
		$('.right_section').addClass('searching')

		if editMode
			tag.editMode = true
			searchResults = $('<div class="searchProducts"/>')
			searchResults.append(self.listTemplate({offset: 0, results:[tag], next_page: 1,total: 1}))
			$('.details').html(searchResults)
			$('.search_section .btnSave').removeAttr('disabled')
			self.selectProduct(tag)
		$('.searchForm .btnCancel').click (event)->
			event.preventDefault()
			event.stopPropagation()
			$.xhrPool.abortAll() if $.xhrPool && $.xhrPool.abortAll
			self.renderRecent()
			self.editor.endEditing()
			self.resetFilters()

		$('.search_section .btnSave').click (event)->
			event.preventDefault()
			event.stopPropagation()
			tag = $('.search_section .btnSave').data('tag')
			$('.search_section .btnSave').data('tag', null)
			$('.search_section .btnSave').prop('disabled', true)
			console.log(tag.price)
			self.saveProduct(tag) if tag


	self.render()


	self.initSearch()




Sidebar.prototype.selectProduct = (tag)->
 $('.search_section').addClass('selected')
 $('.search_section .btnSave').removeAttr('disabled')
 $('.search_section .btnSave').data('tag', tag)
 console.log(tag.price)

Sidebar.prototype.saveProduct = (tag)->
	$.xhrPool.abortAll() if $.xhrPool && $.xhrPool.abortAll
	self = this
	for prop in self.props
		self.currentTag[prop] = tag[prop]

	page_url = $('#page_url').val()
	domain = $('#domain').val()
	tag_data = $.extend {}, currentTag
	delete tag_data.id unless tag_data.editMode
	delete tag_data.editMode
	data = {}
	image_data = {}
	data.image_url = self.img.attr('src')
	data.page_url = page_url
	data.tag = tag_data
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
		self.editor.endEditing(tag)
		self.resetFilters()
		self.renderRecent()
		self.currentTag = null
	.fail ->
		self.alert("danger", "Server Error!")

Sidebar.prototype.deleteTag = (tag_id, image_id)->
	self = this

	self.editor.removeTag(tag_id)
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
	this.brandsAdapt = new Bloodhound
		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name')
		queryTokenizer: Bloodhound.tokenizers.whitespace
		limit: 5
		prefetch:
			url: $('.search_section').data('brands-url')
			filter: (json)->
				json.brandHistogram
	this.categoriesAdapt = new Bloodhound
		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name')
		queryTokenizer: Bloodhound.tokenizers.whitespace
		limit: 5
		prefetch:
			url: $('.search_section').data('categories-url')
			filter: (json)->
				human = (str) ->
					str = str.charAt(0).toUpperCase() + str.slice(1);
					str.replace("-"," ")
				json.categories.map (cat)->
					cat.name = human(cat.localizedId)
					cat

	this.retailersAdapt = new Bloodhound
		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name')
		queryTokenizer: Bloodhound.tokenizers.whitespace
		limit: 5
		prefetch:
			url: $('.search_section').data('retailers-url')
			filter: (json)->
					json.retailers
	this.categoriesAdapt.initialize()
	this.retailersAdapt.initialize()
	this.brandsAdapt.initialize()
	self.renderRecent()



Sidebar.prototype.alert = (type, msg, cssClass)->
	self = this
	details = self.elem.find('.details')
	details.find('.alert').remove()
	details.prepend(self.alertTemplate({class: type, message: msg,css:cssClass }))


Sidebar.prototype.masonry = ($container)->
	self = this
	self.msnry = msnry = $container.masonry
		itemSelector : '.item'
		isAnimated: false
	#msnry.masonry('bindResize')
	msnry.imagesLoaded ->
		console.log("LOADED")
		$('.details').addClass('Images loaded')
		msnry.masonry()
	$(window).resize ->
		self.msnry.masonry('reload')


Sidebar.prototype.getSearchFilters = ()->
	self = this

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
	filters["price"] = "p"+gt+":"+lt
	filters["brands"] = $('.searchFilter.brands, .searchFilter.retailers').map((a,i)->
		item = $(i).data('item')
		item.label[0]+item["id"]
	).get().join("_")
	filters["categories"] = $('.searchFilter.categories').map((a,i)->
		item = $(i).data('item')
		item["id"]
	).get().join("_")
	filters["q"] = $('.searchFilter.search').data('item') || ""
	filters

Sidebar.prototype.initAppendedSearch = (items)->
	self = this
	items.find('a.image').click (event, el)->
		event.preventDefault()
		event.stopPropagation()
		$('.searchProduct').removeClass('selected')
		id = $(event.currentTarget).data('product-id')
		$(event.currentTarget).parents('.searchProduct').addClass('selected')
		console.log self.results.results[id]
		self.selectProduct(self.results.results[id])

Sidebar.prototype.renderUrlResults = (tag, json)->
	self = this
	images = json.images.filter (img)->
		valid = true
		w = img.width.replace("px","") if img.width
		h = img.height.replace("px","") if img.height

		valid = w>60 if w
		valid &= h>60 if h
		valid
	json.images = images.splice(0,9)
	return $('.details').html('Sorry cannot find any images') if images.length<1

	enableSave = ()->
		enabled = $('.paste_images .paste_image.selected').length>0 &&  $('.details #paste_price').val()>0
		if enabled
			$('.search_section').addClass('selected')
			$('.search_section .btnSave').removeAttr('disabled')
			tag = $.extend {}, self.currentTag
			image = images[$('.paste_images .paste_image.selected').data('index')]
			tag.image_url = image.src
			tag.image_width = image.width
			tag.image_height = image.height
			tag.seller_url = json.seller_url
			tag.title = $('#paste_title').val()
			tag.description = $('#paste_description').val()
			tag.currency = $('#paste_currency').val()
			tag.price = $('#paste_price').val()


			$('.search_section .btnSave').data('tag', tag)

		else
			$('.search_section').removeClass('selected')
			$('.search_section .btnSave').prop('disabled', true)

	$('.details').html(self.pasteProductTemplate(json))
	$('.details #paste_price').keydown enableSave
	$('.paste_images .paste_image').click (event, el)->
		event.preventDefault()
		event.stopPropagation()
		$('.paste_image').removeClass('selected')
		$(event.currentTarget).addClass('selected')
		enableSave()

Sidebar.prototype.renderSearchResults = (tag, json)->
	self = this
	console.log(json)
	self.results = json
	results = []
	results.push(tag)	if(tag && tag.editMode)
	results = results.concat(json.results)
	searchResults = $('<div class="searchProducts"/>')
	searchResults.html(self.listTemplate({offset: json.metadata.offset, results: results, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
	$('.details').html(searchResults)
	$('.details').removeClass('loading')
	$container = $('.searchProducts')
	self.masonry $container
	self.initAppendedSearch($container.find('.searchProduct'))

	if results && results.length>0
		self.initScroll (json,opts)->
			if self.results.results
				self.results.results = self.results.results.concat(json.results)
			else
				self.results = json
			$resultsHTML = $(self.listTemplate({results:json.results, offset:json.metadata.offset, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
			$('.details .searchProducts').append($resultsHTML).imagesLoaded ->
				self.msnry.masonry( 'appended', $resultsHTML, true )
				self.initAppendedSearch($resultsHTML)
Sidebar.prototype.searchProducts = (tag)->
	self = this
	$('.details').html('')
	$('.details').infiniteScroll('destroy') if $('.details').data('infinite-search')
	$('.details').addClass('loading')
	self.results = {}
	jQuery.get('/search',self.getSearchFilters())
	.done((json)->
		self.searched = true
		$('.details').removeClass('loading')
		if json.type == "scraper"
			self.renderUrlResults(tag, json)
		else
			self.renderSearchResults(tag, json)






	).fail(()->
		self.alert("danger", "Server Error!")
		$('.details').removeClass('loading')
	)
Sidebar.prototype.updatePriceRange = ()->
	val = $('.price-slider').val().split(',')
	lt = window.prices[val[0]]["range"][0]
	gt = window.prices[val[1]]["range"][1]
	if gt
		val = lt + "-" + gt + "$"
	else
		val = "Over " + lt + "$"
	$('.price-range').html(val)

Sidebar.prototype.renderRecent = ()->
	self = this
	self.results = {}
	$('.details').html('')
	$('.details').infiniteScroll('destroy') if $('.details').data('infinite-search')
	$('.details').addClass('loading')
	$('.right_section').removeClass('searching')
	image_url = self.img.attr('src')
	jQuery.get('/tags/recent',{image_url:image_url})
	.done((image)->
		console.log(image)
		$('.details').html(self.productsTemplate({results:image.tags, image_id:image.id}))
		$('.details').removeClass('loading')
		$container = $('.listProducts')
		self.masonry $container
		search_elem = self.elem.find('.product_search')
		search_elem.typeahead('val', '')
		jQuery('.editProduct').click ->
			event.stopPropagation()
			event.preventDefault()
			id = $(event.currentTarget).data('tag-id')
			self.editor.startEditing(id, true)
		jQuery('.deleteProduct').click (event, el)->
			event.stopPropagation()
			event.preventDefault()
			id = $(event.currentTarget).data('tag-id')
			self.deleteTag(id, image.id)

		$('.add_button').click ->
			self.editor.initNewTag()



	).fail(()->
		#self.alert("danger", "Server Error!")
		$('.details').removeClass('loading')
	)

jQuery ()->
	fetchTags = (img) ->
		app_id = page_url = $('#page_url').val()
		req = $.ajax(
			url: "/tags"
			data: {app_id:app_id, image_url: img.src}
			dataType: "json"

			success: (data) ->

			sidebar.init()
			error: (xhr) ->
				sidebar.init()
		)
	imgEl = jQuery('.left_section img')

	window.init = init = ()->
		imgEl = jQuery('.left_section img')

		setWindowSizes = ->
			$('.right_section, .search_section').css('width', $(window).width() - $('.left_section img').width()-10)
			$('.right_section').css('margin-left', $('.left_section img').width())
			$('.search_section').css('left', $('.left_section img').width())
		setWindowSizes()

		$(window).resize setWindowSizes
		console.log imgEl[0].width
		if window.imageData && window.imageData.tags
			editor = new LookTagMe.Editor({}, imgEl, window.imageData.tags)
		else
			editor = new LookTagMe.Editor({}, imgEl, [])

		sidebar = new Sidebar
			sidebarEl: jQuery('.right_section')
			img: imgEl
			editor: editor

		sidebar.init()

		self.slider = $('.price-slider').slider()
		$('.price-slider').on "slideStop", (slideEvt) ->
			sidebar.searchProducts(self.currentTag) if sidebar.searched
			sidebar.updatePriceRange()

		$('.price-slider').on "slide", (slideEvt) ->
			sidebar.updatePriceRange()


		jQuery('.close_edit').click ->
			try
				page_url = $('#page_url').val()
				domain = $('#domain').val()
				dom_id = $('#dom_id').val()
				data = {image_url: sidebar.img.attr('src'), tags: sidebar.editor.getTags(), page_url:page_url,dom_id : dom_id  }
				window.parent.postMessage(JSON.stringify(data), domain);
			catch e
				console.log e

		editor.onEdit (item, editMode)->
			sidebar.selectTag(item, editMode);

	imgEl.imagesLoaded ->
		init()
