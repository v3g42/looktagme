window.$TAGGER = window.$TAGGER || {}
window.$TAGGER.Common = {

	init : function(img, tags) {

		var self = this;

		this.id = window.$TAGGER.Common.generateUUID();
		img = $(img);
		this.img = img;
		this.body = $(document.body);
		this.tags = tags ? tags : [];
		this.container = $('<div class="tagger-wrap"></div>');
		this.container.data('tagger', this);
		this.container.attr('id', this.id);
		this.container.css({
			top: img.offset().top + parseInt(img.css('padding-top').replace('px','')),
			left: img.offset().left + parseInt(img.css('padding-left').replace('px','')),
			width: img.width(),
			height: img.height()
		});
		this.body.append(this.container);

		var container = this.container;
		$(window).resize(function(){
			container.css({
				top: img.offset().top + parseInt(img.css('padding-top').replace('px','')),
				left: img.offset().left + parseInt(img.css('padding-left').replace('px','')),
				width: img.width(),
				height: img.height()
			});

			window.$TAGGER.Common.originalSz(self.img, function(sz){
				self.container.find('.ptr').each(function(idx, item){
					var tag = $(item).data('tag');
					$(item).css({
						top: tag.y*self.container.height()/sz.height - 12,
						left: tag.x*self.container.width()/sz.width - 8
					});
				});
			});
		});
		$(window).scroll(function(evt){
			if($('.tagger-editor-container').data('editing')) return evt.stopPropagation();
			container.css({
				top: img.offset().top + parseInt(img.css('padding-top').replace('px','')),
				left: img.offset().left + parseInt(img.css('padding-left').replace('px','')),
				width: img.width(),
				height: img.height()});
		});

	},

	on : function(evt, cb) {
		this.container.bind(evt, cb);
	},

	clearTags : function() {
		this.container.find('.ptr').remove();
	},

	showTags : function(tags, cb, fade) {
		var self = this;

		for (var ctr=0;ctr<tags.length;ctr++) {
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

	generateUUID : function() {
	    var d = new Date().getTime();
	    var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
	        var r = (d + Math.random()*16)%16 | 0;
	        d = Math.floor(d/16);
	        return (c=='x' ? r : (r&0x7|0x8)).toString(16);
	    });
	    return uuid;
	},

	originalSz : function(img, cbk) {
	    var t = new Image();
	    t.src = img[0].src;
	    t.onload = function(){
	    	return cbk({ width: t.width, height: t.height });
	    }
	}

};


window.$TAGGER.Viewer = function(img, tags) {


	this.init(img, tags);
	this.viewer();

	var self = this;
	var p = $('<div class="tagger-popup"><div class="callout"/><div class="container"><div class="pic"><img class="prodimg"/></div><div class="price"/><div class="shopname"/><div class="buy">Buy Now</div></div></div>');
	p.hide();
	this.container.append(p);
	p.mouseleave(function() {
		p.hide();
	});
	p.mouseenter(function() {
		clearTimeout(self.hider);
	});
	this.popup = p;
	this.showTags();

};

window.$TAGGER.Viewer.prototype = {

	init : window.$TAGGER.Common.init,
	on : window.$TAGGER.Common.on,
	clearTags : window.$TAGGER.Common.clearTags,

	showTags : function() {
		var self = this;
		window.$TAGGER.Common.showTags.call(this, this.tags, function(ptr, tag){
			var container = this.container;
			var p = this.popup;
			ptr.mouseenter(function(){
				clearTimeout(self.hider);
				p.hide();
				p.css({
					top: ptr.position().top + ptr.height() / 2 - p.height() / 2,
					left: ptr.position().left + ptr.width()
				});
				p.unbind('click');
				p.bind('click', function(){
					window.open(tag.seller_url);
				})
				p.find('.price').text(tag.currency + ' ' + tag.price);
				p.find('.shopname').text(tag.seller_name);
				p.data('container', container);
				p.find('.prodimg').hide();

				p.fadeIn();

				var img = new Image();
				img.onload = function() {
					var w,h;
					if (img.width > img.height) {
						w = 90;
						h = w * img.height / img.width;
					}
					else {
						h = 90;
						w = img.width * h / img.height;
					}
					p.find('.prodimg').css({width: w + 'px', height: h + 'px'});
					p.find('.prodimg')[0].src = img.src;
					p.find('.prodimg').fadeIn();
				};
				img.onerror = function() {

				};
				img.src = tag.image_url;
			});
			ptr.mouseleave(function(){
				self.hider = setTimeout(function(){
					p.hide();
				}, 1000);
			});
		}, true);

		if (this.tags.length > 0){
			this.menu.show();
		}
		else
			this.menu.hide();
	},

	viewer : function() {

		var self = this;
		var container = this.container;
		var img = this.img;

		container.empty();
		var glass = $('<div class="glass"/>');
		glass.hide();
		container.append(glass);

		var menu = $('<div class="menu"/>');
		menu.hide();
		container.append(menu);
		this.menu = menu;

		var tag = $('<div class="buttonwrapper"><div class="button"></div><div class="t"></div></div>');
		tag.mouseover(function(){
			tag.find('.button').addClass('active');
		});
		tag.mouseleave(function(){
			tag.find('.button').removeClass('active');
		});
		tag.click(function(){
			container.trigger('edit', img);
		});
		menu.append(tag);

		container.mouseover(function() {
			if (self.tags.length == 0)
				menu.show();
			menu.find('.button').addClass('bg')
			glass.fadeIn();
		});
		container.mouseleave(function() {
			if (self.tags.length == 0)
				menu.hide();
			menu.find('.button').removeClass('bg')
			glass.fadeOut();
		});

	}

};


window.$TAGGER.Editor = function(img, tags) {
	this.init(img, tags);
	this.editor();
	this.showTags(this.tags);

	var self = this;
	self.container.mousemove(function(e){
		if (!self.dragging)
			return;

		var x = e.pageX - self.container.offset().left;
		if (x < 0) x = 0;
		if (x > self.container.width()) x = self.container.width();
		var y = e.pageY - self.container.offset().top;
		if (y < 0) y = 0;
		if (y > self.container.height()) y = self.container.height();

		self.dragging.tag.css({left: x - self.dragging.x, top: y - self.dragging.y});

	});
	self.container.mouseup(function(e){

		if (self.dragging)
			return;

		window.$TAGGER.Common.originalSz(self.img, function(sz){
			var x = e.pageX - self.container.offset().left;
			var y = e.pageY - self.container.offset().top;
			var newtag = {
				id: window.$TAGGER.Common.generateUUID(),
				x: x*sz.width/self.container.width(),
				y: y*sz.height/self.container.height()
			};
			self.tags.push(newtag);
			self.showTags([newtag]);
			self.container.find('.ptr').removeClass('selected');
			self.container.find('#' + newtag.id).addClass('selected');
			self.container.trigger('selected', newtag);
		});

	});

};

window.$TAGGER.Editor.prototype = {

	init : window.$TAGGER.Common.init,
	on : window.$TAGGER.Common.on,
	clearTags : window.$TAGGER.Common.clearTags,
	getTags: function(){
		return this.tags;
	},


	showTags : function(tags) {
		window.$TAGGER.Common.showTags.call(this, tags, function(ptr, tag){

		});
	},

/*
	showTags : function(tags) {
		window.$TAGGER.Common.showTags.call(this, tags, function(ptr, tag){
			ptr.css({cursor: 'move'});
			var self = this;
			ptr.mousedown(function(e){
				self.container.find('.ptr').removeClass('selected');
				ptr.addClass('selected');
				self.dragging = {tag: ptr, x: e.pageX - ptr.offset().left, y: e.pageY - ptr.offset().top};
				self.container.trigger('selected', tag);
				e.stopPropagation();
			});
			ptr.mouseup(function(e){

				var trash = self.container.find('.trash');

				if (
					e.pageX > trash.offset().left && e.pageX < trash.offset().left + trash.width() &&
					e.pageY > trash.offset().top && e.pageY < trash.offset().top + trash.height()
					)
				{
						console.log('Removing ' + JSON.stringify(tag));
						self.remove(tag.id);
						ptr.remove();
				}
				else {
					window.$TAGGER.Common.originalSz(self.img, function(sz){
						tag.x = ptr.position().left * sz.width / self.container.width() + 8;
						if (tag.x < 0) tag.x = 0;
						if (tag.x > sz.width) tag.x = sz.width;
						tag.y = ptr.position().top * sz.height / self.container.height() + 12;
						if (tag.y < 0) tag.y = 0;
						if (tag.y > sz.height) tag.y = sz.height;
					});


				}

				self.dragging = undefined;
				e.stopPropagation();
			});

		});
	},
*/
	editor : function() {

		var self = this;
		var container = this.container;
		var img = this.img;

		container.empty();

	},

	update : function(tag) {
		for (var ctr=0;ctr< this.tags.length;ctr++) {
			if (this.tags[ctr].id == tag.id) {
				for (p in tag)
					this.tags[ctr][p] = tag[p];
				return;
			}
		}
	},

	remove : function(id) {
		var idx = -1;
		for (var ctr=0;ctr<this.tags.length;ctr++) {
			if (this.tags[ctr].id == id) {
				idx = ctr;
				break;
			}
		}
		if (idx < 0) return;
		this.tags.splice(idx,1);
	}

};
