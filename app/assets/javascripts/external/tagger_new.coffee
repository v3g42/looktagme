

class Content	
	constructor: (elem) ->
		@elem = $(elem)
	url: ->
	width: () => @elem.width()
	height: () => @elem.height()
	top: () => @elem.offset().top + parseInt(@elem.css('padding-top').replace('px',''))
	left: () => @elem.offset().left + parseInt(@elem.css('padding-left').replace('px',''))
	bbox: () => {top: @top(), left: @left(), width: @width(), height: @height()}
	original: (url, cbk) -> 
	    t = new Image()
	    t src = url
	    t onload = () ->
	    	return cbk({ width: t.width, height: t.height })	
	@create: (elem) ->
		new ImgContent(elem) 

class ImgContent extends Content
	url: => $(@elem).attr('src')
	original: (url, cbk) =>
		super(@url(), cbk) 


class LookTagMeContainer

	constructor: (elem, tags) ->
		@tags = if tags then tags else []
		@elem = Content.create(elem)
		@id = @uuid()
		@createContainer()

	createPopup: () =>
		p = $('<div class="tagger-popup"><div class="callout"/><div class="container"><div class="pic"><img class="prodimg"/></div><div class="price"/><div class="shopname"/><div class="buy">Buy Now</div></div></div>')
		@container.append(p);
		p.mouseleave () -> p.hide()
		p.mouseenter () => clearTimeout(@hider)

	createContainer: () => 		
		body = $(document.body)
		@container = $('<div class="tagger-wrap"></div>')
		@container.data('tagger', @)
		@container.attr('id', @id)
		@container.css(@elem.bbox())
		body.append(@container)

		$(window).resize () =>
			@container.css(@elem.bbox())
			@elem.original () =>
				@container find('.ptr') each (idx, item) =>
					tag = $(item) data('tag')
					$(item) css 
						top: tag.y*@container.height()/sz.height - 10
						left: tag.x*@container.width()/sz.width - 10
		
	enableAutoCreate: () =>
		$(window).scroll (evt) =>
			@container.css(@elem.bbox())

	showTags: (cb, fade) =>
	
		for tag in @tags
			var ptr = $('<div class="ptrcontainer"><div class="ptrbutton"/><div class="ptr"/></div>');
					ptr.attr('id', tags[ctr].id);
					ptr.data('tag', tags[ctr]);
					var newtop = Math.floor(tags[ctr].y*self.container.height()/sz.height) - 10;
					var newleft = Math.floor(tags[ctr].x*self.container.width()/sz.width) - 10;
					


		for (var ctr=0;ctr<@tags.length;ctr++) {
			(function(ctr){
				window.$TAGGER.Common.originalSz(self.img, function (sz) {
					var ptr = $('<div class="ptrcontainer"><div class="ptrbutton"/><div class="ptr"/></div>');
					ptr.attr('id', tags[ctr].id);
					ptr.data('tag', tags[ctr]);
					var newtop = Math.floor(tags[ctr].y*self.container.height()/sz.height) - 10;
					var newleft = Math.floor(tags[ctr].x*self.container.width()/sz.width) - 10;
					
					ptr.css({top: newtop, left: newleft});
					if (fade)
						ptr.hide();
					self.container.append(ptr);
					if (fade) {
						self.container.mouseenter(function(){
							ptr.show();
						});
						self.container.mouseleave(function(){
							ptr.hide();
						});
					}
					if (cb)
						cb.call(self, ptr, tags[ctr]);
				});
			})(ctr);

		}

		return tags.length;
	},

	uuid: () ->
  		'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) ->
    		r = Math.random() * 16 | 0
    		v = if c is 'x' then r else (r & 0x3|0x8)
    		v.toString(16) 
  		)


window.$TAGGER.Viewer = LookTagMeContainer







