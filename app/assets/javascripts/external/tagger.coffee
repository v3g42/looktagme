

class Content	
	constructor: (elem, cb) ->
		@logger = new LookTagMe.Logger("Content")
		@elem = $(elem)
		@get_original_size(@url(), cb)
	url: ->
	width: () => @elem.width()
	height: () => @elem.height()
	top: () => @elem.offset().top + parseInt(@elem.css('padding-top').replace('px',''))
	left: () => @elem.offset().left + parseInt(@elem.css('padding-left').replace('px',''))
	bbox: () => {top: @top(), left: @left(), width: @width(), height: @height()}
	original_width: () => @original_w
	original_height: () => @original_h
	scale_top: (y) => Math.floor(y*@height()/@original_height())
	scale_left: (x) => Math.floor(x*@width()/@original_width()) 
	original_top: (y) => Math.floor(y*@original_height()/@height())
	original_left: (x) => Math.floor(x*@original_width()/@width()) 
	on: (evt, handler) => 
		@elem.on(evt, handler)
	trigger: (evt) => 
		@elem.trigger(evt)
	get_original_size: (url, cb) => 
	    t = new Image()
	    @logger.debug('Loading image ' + url)
	    t.src = url
	    t.onload = () =>
	    	@logger.debug('image loaded')
	    	@original_w = t.width
	    	@original_h = t.height
	    	return cb()	
	@create: (elem, ready) ->
		new ImgContent(elem, ready) 

class ImgContent extends Content
	url: => $(@elem).attr('src')

class Container

	constructor: (page, elem, tags, dyn) ->
		@page = page
		@logger = new LookTagMe.Logger("LookTagMeContainer")
#		@tags = [{x:200,y:200,id:"abcdef", currency: "SGD", price: "1000", seller_url: "www.amazon.com", seller_name: "Amazon", image_url: "http://www.spottedfashion.com/wp-content/uploads/2013/07/Givenchy-Pearl-Grey-with-Metal-Hardware-Antigona-Medium-Bag.jpg"}, {x:100,y:100,id:"abcde", currency: "SGD", price: "1000", seller_url: "www.amazon.com", seller_name: "Amazon", image_url: "http://www.spottedfashion.com/wp-content/uploads/2013/07/Givenchy-Pearl-Grey-with-Metal-Hardware-Antigona-Medium-Bag.jpg"}]
		@tags = tags
		@tagmap = {}
		@id = @uuid()
		@popup_hider = undefined
		@elem = Content.create(elem, @ready)
		@logger.debug('Container constructor completed')

	ready: () =>
		@enableAutoCreate()
		@createContainer()
		@popup = @createPopup()

	getId: () => @id
	getUrl: () => @elem.url()

	onTagClick: (tag, ptr) =>

	createPopup: () =>
		p = $('<div class="tagger-popup"><div class="callout"/><div class="container"><div class="pic"><img class="prodimg"/></div><div class="price"/><div class="shopname"/><div class="buy">Buy Now</div></div></div>')
		p.hide()
		@container.append(p);
		@container.mouseleave () => 
			@clearPopupTimeout()
			@popup.hide()
		p.mouseleave () => @startPopupTimeout()
		p.mouseenter () => @clearPopupTimeout()
		return p

	createContainer: () => 		
		@logger.debug('Creating container')
		body = $(document.body)
		@container = $('<div class="tagger-wrap"></div>')
		@container.data('tagger', @)
		@container.attr('id', @id)
		@container.css
			top: @elem.top() + 'px', 
			left: @elem.left() + 'px',
			width: '1px'
			height: '1px'
		body.append(@container)
		@elem.on 'mouseenter', () => @container.trigger('mouseenter')
		@elem.on 'mouseleave', () => @container.trigger('mouseleave')
		@elem.on 'click', () => @container.trigger('click')

		$(window).resize () =>
			@container.css
				top: @elem.top() + 'px', 
				left: @elem.left() + 'px',
				width: '1px', height: '1px'

			for tag in @tags
				$(@tagmap[tag.id]).css
					top: @elem.scale_top(tag.y)
					left: @elem.scale_left(tag.x)
		
	enableAutoCreate: () =>
		$(window).scroll (evt) =>
			@container.css
				top: @elem.top() + 'px'
				left: @elem.left() + 'px'

	startPopupTimeout: =>
		@logger.debug('Start popup timeout')
		clearTimeout(@popup_hider)
		@popup_hider = setTimeout(
			() => @popup.hide()
			1000
		)

	clearPopupTimeout: =>
		@logger.debug('Clear popup timeout')
		clearTimeout(@popup_hider)

	addMenuButton: (c, action) =>
		tag = $('<div class="buttonwrapper"><div class="button"></div><div class="' + c + '"></div></div>');
		tag.mouseover () -> tag.find('.button').addClass('active')
		tag.mouseleave () -> tag.find('.button').removeClass('active')
		tag.click(action)
		@menu.append(tag)

	createMenu: () =>
		@menu = $('<div class="menu"/>');
		@menu.css
			left: (@elem.width() - 60) + 'px'
			height: (@elem.height() - 10) + 'px'	
		if @tags.length == 0 then @menu.hide();
		@container.append(@menu);

		@container.mouseover () =>
			if @tags.length == 0
				@menu.show();
			@menu.find('.button').addClass('bg')	

		@container.mouseleave () =>
			if @tags.length == 0
				@menu.hide()
			@menu.find('.button').removeClass('bg')

	onTagOver: (tag, ptr) =>

		if $(ptr).hasClass('disabled') then return

		@popup.hide()
		@popup.css
			top: ptr.position().top + ptr.height() / 2 - @popup.height() / 2,
			left: ptr.position().left + ptr.width()
		@popup.unbind('click')
		@popup.bind 'click', () -> window.open(tag.seller_url)
		@popup.find('.price').text(tag.currency + ' ' + tag.price)
		@popup.find('.shopname').text(tag.seller_name)
		@popup.find('.prodimg').hide()
		@popup.fadeIn()
		LookTagMe.ImageUtils.imageFit tag.image_url, 90, 90, (res, w, h) =>
			if not res then return 
			@popup.find('.prodimg').css({width: w + 'px', height: h + 'px'})
			@popup.find('.prodimg')[0].src = tag.image_url;
			@popup.find('.prodimg').fadeIn();
		
	newTag: (x, y, show_popup, show_always) =>
		data = {id: @uuid(), y: @elem.original_top(y), x: @elem.original_left(x)}
		console.log(data)
		@tags.push(data)
		@renderTag(data, show_popup, show_always)
		return data

	moveTag: (tag, x,y) =>
		tag.x = @elem.original_left(x)
		tag.y = @elem.original_top(y)
		ptr = @tagmap[tag.id]
		ptr.css({top: y - 10, left: x - 10})

	clearTags: () =>
		for t in @tags
			@tagmap[t.id].remove()
		@tagmap = {}
		@tags = []

	renderTags: (show_popup, show_always) =>
		for tag in @tags
			@renderTag(tag, show_popup, show_always)

	renderTag: (tag, show_popup, show_always) =>
		@logger.debug('Creating tag ' + JSON.stringify(tag))

		ptr = $('<div class="ptrcontainer"><div class="ptrbutton"/><div class="ptr"/></div>')
		@tagmap[tag.id] = ptr
		ptr.attr('id', tag.id)
		ptr.data('tag',tag)
		ptr.css({top: @elem.scale_top(tag.y) - 10, left: @elem.scale_left(tag.x) - 10})
		ptr.click () => @onTagClick(tag, ptr)
		@container.append(ptr)

		if not show_popup
			ptr.addClass('disabled')

		if not show_always
			ptr.hide()
			@container.on 'mouseenter', () => ptr.show()
			@container.on 'mouseleave', () => ptr.hide()

		ptr.on 'mouseover', () => 
			@clearPopupTimeout()
			ptr.show()
		ptr.on 'mouseenter', () => @onTagOver(tag, ptr)
		ptr.on 'mouseleave', () => @startPopupTimeout()


	disablePopup: () =>
		for t in @tags
			ptr = @tagmap[t.id]
			$(ptr).addClass('disabled')

	enablePopup: () =>
		for t in @tags
			ptr = @tagmap[t.id]
			$(ptr).removeClass('disabled')

	uuid: () ->
  		'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    		r = Math.random() * 16 | 0
    		v = if c is 'x' then r else (r & 0x3|0x8)
    		v.toString(16) 
  		)

class Viewer extends Container

	constructor: (page, elem, tags) ->
		super(page, elem, tags, true)

	updateTags: (tags) =>
		@clearTags()
		@tags = tags
		@renderTags(true, false)

	ready: () =>
		super()
		@renderTags(true, false)
		@createMenu()
		@addMenuButton 't', () => @page.onEdit(@)


class Editor extends Container

	constructor: (page, elem, tags) ->
		super(page, elem, tags, false)
		@logger.debug('Initialising editor')

	initNewTag: () =>
   		x = Math.floor(@elem.width() / 2) - 10
   		y = Math.floor(@elem.height() / 2) - 10
   		tag = @newTag(x, y, false, true)
   		@startEditing(tag.id)

	ready: () =>
		@logger.debug('Editor almost ready')
		super()
		@renderTags(false, true)
		editing = undefined
		@enablePopup()
		if @tags.length == 0
			@initNewTag()
		@elem.on('click', (e) => @onContainerClick(e)) 
		@logger.debug('Editor ready')
			

	onContainerClick: (e) =>
		parentOffset = @container.offset()
		relX = e.pageX - parentOffset.left
		relY = e.pageY - parentOffset.top
		if @editing != undefined
			@moveTag(@editing, relX, relY)
		else
			tag = @newTag(relX, relY, false, true)
			@startEditing(tag.id)

	onTagClick: (tag, ptr) =>
		@startEditing(tag.id)

	onEdit: (cb) =>
		@edit_cb = cb

	startEditing: (id) =>
		if @editing != undefined then return
		@disablePopup()
		for i in @tags
			if i.id != id then $(@tagmap[i.id]).children('.ptrbutton').addClass('notediting')
			else @editing = i
		$(@tagmap[id]).children('.ptrbutton').addClass('editing')
		@edit_cb(@editing)

	copyTag: (src, dst) ->
		reserved = ['x','y','id']
		for i in src
			if (reserved.indexOf(i) < 0) 
				dst[i] = src[i]

	endEditing: (data) =>
		@copyTag(data, @editing)
		@editing = undefined
		@enablePopup()
		for i in @tags
			$(@tagmap[i.id]).children('.ptrbutton').removeClass('notediting')
			$(@tagmap[i.id]).children('.ptrbutton').removeClass('editing')
		



window.LookTagMe.Viewer = Viewer
window.LookTagMe.Editor = Editor









