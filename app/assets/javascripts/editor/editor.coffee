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
	this.filters = []

	this
Sidebar.prototype.toggleFilters = ()->
	containers = [$('.brands'),$('.retailers')]
	containers.map (container)->
		if(container.find('.searchFilter').length>0)
			container.show()
		else
			container.hide()
Sidebar.prototype.addFilter = (filter, name)->
	self = this
	console.log(filter + " : " + name)
	container = $('.'+name)
	return if container.find('.searchFilter.'+filter["id"]).length>0
	filterDiv = $(self.alertTemplate({class: "info", message: filter["name"],css:"searchFilter " + filter["id"] }))
	filterDiv.data('filter', name[0]+filter["id"])
	filterDiv.find('.close').click ->
		filterDiv.remove()
		self.toggleFilters()
	container.find('.filters').append(filterDiv)
	self.toggleFilters()
	self.searchProducts() if self.searched


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


	search_elem.typeahead
			highlight: true
			minLength: 2
			hint: true
		,
			name: 'brands',
			displayKey: 'name',
			source: self.brandsAdapt.ttAdapter()
			templates:
				header: '<h3 class="typeahead-header">Brands</h3>'
		,
			name: 'retailers',
			displayKey: 'name',
			source: self.retailersAdapt.ttAdapter()
			templates:
				header: '<h3 class="typeahead-header">Retailers</h3>'

	search_elem.on 'typeahead:selected', (evt, obj, name) ->
			evt.preventDefault();
			search_elem.typeahead('val', '');
			self.addFilter obj, name


Sidebar.prototype.selectTag = (tag)->
	self = this
	$('.details').html('')
	window.currentTag = this.currentTag = declareProps(tag, this.props)

	self.render = ()->
		$('.right_section').addClass('searching')
		$('.searchForm').submit (event)->
			event.preventDefault()
			self.searchProducts()


	self.render()

	self.initSearch()





Sidebar.prototype.saveTag = (tag)->
	self = this
	for prop in self.props
		self.currentTag[prop] = tag[prop]

	self.editor.endEditing(currentTag)
	page_url = $('#page_url').val()
	domain = $('#domain').val()
	tag_data = $.extend {}, currentTag
	delete tag_data.id
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
	this.brandsAdapt = new Bloodhound
		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name')
		queryTokenizer: Bloodhound.tokenizers.whitespace
		limit: 5
		prefetch:
			url: $('.search_section').data('brands-url')
			filter: (json)->
				json.brandHistogram

	this.retailersAdapt = new Bloodhound
		datumTokenizer: Bloodhound.tokenizers.obj.whitespace('name')
		queryTokenizer: Bloodhound.tokenizers.whitespace
		limit: 5
		prefetch:
			url: $('.search_section').data('retailers-url')
			filter: (json)->
					json.retailers
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
			#columnWidth : if $('.tag_editor').hasClass('horizontal-image') then 240 else 220
			columnWidth : 240
			isAnimated: false

Sidebar.prototype.getSearchFilters = ()->
	search = $('.product_search:eq(0)').val() || $('.product_search:eq(1)').val() || ""
	filters = {}
	filters["q"] = search
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
	filters["brands"] = $('.searchFilter').map((a,i)-> $(i).data('filter')).get().join("_")
	filters
Sidebar.prototype.searchProducts = ()->
	self = this
	$('.details').html('')
	$('.details').addClass('loading')
	self.results = {}
	jQuery.get('/search',self.getSearchFilters())
	.done((json)->
		self.searched = true
		console.log(json)
		self.results = json
		$('.details').html(self.listTemplate({results:json.results, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
		$('.details').removeClass('loading')
		self.initScroll (json,opts)->
			self.results.results = self.results.results.concat(json.results)
			$('.details').append(self.listTemplate({results:json.results, next_page: json.metadata.offset+json.metadata.limit,total: json.metadata.total}))
			$container = $('.searchProducts:last')
			self.masonry $container
		jQuery('.saveProduct').click (event, el)->
			id = $(event.currentTarget).data('product-id')
			console.log self.results.results[id]
			self.saveTag(self.results.results[id])

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
			editor = new LookTagMe.Editor(imgEl, window.imageData.tags)
		else
			editor = new LookTagMe.Editor(imgEl, [])

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

		editor.onEdit (item)->
			sidebar.selectTag(item);

	imgEl.imagesLoaded ->
		init()
