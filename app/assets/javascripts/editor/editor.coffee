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
	this.render = null
	this.filters = []

	this
Sidebar.prototype.toggleFilters = ()->
	containers = [$('.right_section .filters')]
	containers.map (container)->
		if(container.find('.searchFilter').length>0)
			container.show()
		else
			container.hide()

Sidebar.prototype.resetFilters = ()->
	$('.right_section .filters').html('')
	$('.right_section .colors .selected').removeClass('selected')
	$('.price-slider').slider('setValue',[0,window.prices.count-1])


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
	img = $('.details').data('loader')
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

	search_elem.typeahead('destroy')
	search_elem.typeahead
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


	search_elem.on 'typeahead:selected', (evt, obj, name) ->
			evt.preventDefault();
			search_elem.typeahead('val', '');
			self.addFilter obj, name


Sidebar.prototype.selectTag = (tag, editMode)->
	self = this
	$('.details').html('')
	window.currentTag = this.currentTag = declareProps(tag, this.props)

	self.render = ()->
		$('.right_section').addClass('searching')

		if editMode
			tag.editMode = true
			$('.details').append(self.listTemplate({results:[tag], next_page: 1,total: 1}))
			$('.search_section .btnSave').removeAttr('disabled')
			self.selectProduct(tag)
		$('.searchForm .btnCancel').click (event)->
			event.preventDefault()
			event.stopPropagation()
			self.renderRecent()
			self.editor.endEditing()
			self.resetFilters()

		$('.searchForm').submit (event)->
			event.preventDefault()
			self.searchProducts(tag, editMode)
			search_elem = self.elem.find('.product_search')
			search_elem.typeahead('val', '');

		$('.search_section .btnSave').click (event)->
			event.preventDefault()
			event.stopPropagation()
			tag = $('.search_section .btnSave').data('tag')
			$('.search_section .btnSave').data('tag', null)
			$('.search_section .btnSave').prop('disabled', true)
			self.saveProduct(tag) if tag


	self.render()


	self.initSearch()




Sidebar.prototype.selectProduct = (tag)->
 $('.search_section').addClass('selected')
 $('.search_section .btnSave').removeAttr('disabled')
 $('.search_section .btnSave').data('tag', tag)

Sidebar.prototype.saveProduct = (tag)->
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
	$container.imagesLoaded ->
		console.log("LOADED")
		$('.details').addClass('loaded')
		$container.masonry
			itemSelector : '.item'
			#columnWidth : if $('.tag_editor').hasClass('horizontal-image') then 180 else 200
			#columnWidth : 200
			isAnimated: false

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
	filters["brands"] = $('.searchFilter.brands, .searchFilter.retailers').map((a,i)-> $(i).data('filter')).get().join("_")
	filters["categories"] = $('.searchFilter.categories').map((a,i)-> $(i).data('category')).get().join("_")
	filters["q"] = $('.searchFilter.search').data('search') || ""
	filters
Sidebar.prototype.searchProducts = (tag, editMode)->
	self = this
	$('.details').html('')
	$('.details').infiniteScroll('destroy') if $('.details').data('infinite-search')
	$('.details').addClass('loading')
	search = $('.product_search:eq(0)').val() || $('.product_search:eq(1)').val()
	if(search)
		$('.searchFilter.search').remove()
		self.addFilter({name:search}, "search", false)
	self.results = {}
	jQuery.get('/search',self.getSearchFilters())
	.done((json)->
		self.searched = true
		console.log(json)
		self.results = json
		results = []
		results.push(tag)	if(editMode && tag)
		results = results.concat(json.results)

		$('.details').html(self.listTemplate({results: results, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
		$('.details').removeClass('loading')
		if results && results.length>0
			self.initScroll (json,opts)->
				if self.results.results
					self.results.results = self.results.results.concat(json.results)
				else
					self.results = json
				$('.details').append(self.listTemplate({results:json.results, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
				$container = $('.searchProducts:last')
				self.masonry $container
		jQuery('.searchProduct').click (event, el)->
			$('.item').removeClass('selected')
			id = $(event.currentTarget).data('product-id')
			$(event.currentTarget).addClass('selected')
			console.log self.results.results[id]
			self.selectProduct(self.results.results[id])


		$container = $('.searchProducts')
		self.masonry $container

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

		$container = $('.listProducts')
		self.masonry $container

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

		aspectRatio = imgEl.width()/imgEl.height()
		jQuery('.tag_editor').addClass('horizontal-image') if aspectRatio>1
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
			#editor.hide();

		editor.onEdit (item, editMode)->
			sidebar.selectTag(item, editMode);

	imgEl.imagesLoaded ->
		init()
