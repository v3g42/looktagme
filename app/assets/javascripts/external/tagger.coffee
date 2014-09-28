

class Content	
	constructor: (elem) ->
		@elem = $(elem)
	url: ->
	width: () => @elem.width()
	height: () => @elem.height()
	top: () => @elem.offset().top + parseInt(@elem.css('padding-top').replace('px',''))
	left: () => @elem.offset().left + parseInt(@elem.css('padding-left').replace('px',''))
	bbox: () => {top: @top(), left: @left(), width: @width(), height: @height()}
	on: (evt, handler) => 
		@elem.on(evt, handler)
	trigger: (evt) => 
		@elem.trigger(evt)
	original_size: (url, cbk) => 
	    t = new Image()
	    t.src = url
	    t.onload = () =>
	    	return cbk({ width: t.width, height: t.height })	
	@create: (elem) ->
		new ImgContent(elem) 

class ImgContent extends Content
	url: => $(@elem).attr('src')
	original: (cbk) =>
		@original_size(@url(), cbk) 


class Container

	constructor: (elem, tags, dyn) ->
		@logger = new LookTagMe.Logger("LookTagMeContainer")
		@tags = [{x:100,y:100,id:"abcde", currency: "SGD", price: "1000", seller_url: "www.amazon.com", seller_name: "Amazon", image_url: "http://www.spottedfashion.com/wp-content/uploads/2013/07/Givenchy-Pearl-Grey-with-Metal-Hardware-Antigona-Medium-Bag.jpg"}]
		@elem = Content.create(elem)
		@id = @uuid()
		@popup_hider = undefined
		@createContainer()
		@popup = @createPopup()
		@showTags(dyn)

	createPopup: () =>
		p = $('<div class="tagger-popup"><div class="callout"/><div class="container"><div class="pic"><img class="prodimg"/></div><div class="price"/><div class="shopname"/><div class="buy">Buy Now</div></div></div>')
		p.hide()
		@container.append(p);
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

		$(window).resize () =>
			@container.css
				top: @elem.top() + 'px', 
				left: @elem.left() + 'px',
				width: '1px', height: '1px'
			@elem.original () =>
				@container.find('.ptr') each (idx, item) =>
					tag = $(item) data('tag')
					$(item).css 
						top: tag.y*@elem.height()/sz.height - 10
						left: tag.x*@elem.width()/sz.width - 10
		
	enableAutoCreate: () =>
		$(window).scroll (evt) =>
			@container.css(@elem.bbox())

	startPopupTimeout: =>
		@logger.debug('Start popup timeout')
		clearTimeout(@popup_hider)
		@popup_hider = setTimeout(
			() => @popup.hide()
			700
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
	#	@menu.hide();
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
		
			
	showTags: (dyn) =>
	
		for tag in @tags
			@logger.debug('Creating tag ' + JSON.stringify(tag))
			@elem.original (sz) =>
				ptr = $('<div class="ptrcontainer"><div class="ptrbutton"/><div class="ptr"/></div>')
				ptr.attr('id', tag.id)
				ptr.data('tag',tag)
				newtop = Math.floor(tag.y*@elem.height()/sz.height) - 10;
				newleft = Math.floor(tag.x*@elem.width()/sz.width) - 10;
				ptr.css({top: newtop, left: newleft})
				if dyn then ptr.hide()
				@container.append(ptr)
				if dyn
					ptr.on 'mouseover', () => 
						@clearPopupTimeout()
						ptr.show()
					@container.on 'mouseenter', () => ptr.show()
					@container.on 'mouseleave', () => ptr.hide()
				ptr.on 'mouseenter', () => @onTagOver(tag, ptr)
				ptr.on 'mouseleave', () => @startPopupTimeout()


	uuid: () ->
  		'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    		r = Math.random() * 16 | 0
    		v = if c is 'x' then r else (r & 0x3|0x8)
    		v.toString(16) 
  		)

class Viewer extends Container

	constructor: (elem, tags) ->
		super(elem, tags, true)
		@createMenu()
		@addMenuButton 't', () => @edit(@id, @elem.url())

	onEdit: (cb) => @edit = cb 


class Editor extends Container

	constructor: (elem, tags) ->
		super(elem, tags, false)

window.LookTagMe.Viewer = Viewer
window.LookTagMe.Editor = Editor









