
(function() {

	var editor = $('<div class="tagger-editor-container"><iframe/></div>');
	editor.hide();
	$('body').append(editor);

	$(window).resize(function(){
		editor.find('iframe')[0].contentWindow.postMessage('resize', window.$TAGGER.base_url);
	});

	var postListener = function(e){
		if ( e.origin == window.$TAGGER.base_url){
			var obj = JSON.parse(e.data);
			var tagger = $('#' + obj.id).data('tagger');
			tagger.clearTags();
			tagger.tags = obj.tags;
			tagger.showTags();
			editor.hide();
			editor.data('editing',false);
			$(window).off('scroll touchmove mousewheel', editScrollListener);
		}

	};
	var editScrollListener = function(e){
		if($('.tagger-editor-container').data('editing')) {
			e.stopPropagation();
        e.preventDefault();
				return false;
		}
	}
	if (window.addEventListener){
		addEventListener("message", postListener, false)
	} else {
	  attachEvent("onmessage", postListener)
	}

	var createViewer = function(img, tags) {
		var t = new window.$TAGGER.Viewer(img, tags);
		t.on('edit', function(evt, img) {
			$('.tagger-editor-container').data('editing',true);
			$('.tagger-editor-container').show();
			$('.tagger-editor-container').find('iframe').attr(
				'src',
				window.$TAGGER.base_url+"/tags/edit?"
					+ 'image_url=' + encodeURIComponent(img.src)
					+ '&page_url='+encodeURIComponent(window.location.href)
					+ '&domain='+encodeURIComponent(window.location.protocol+"//"+window.location.host)
					+ '&id='+ encodeURIComponent(t.id)
			);

			$(window).on('scroll touchmove mousewheel', editScrollListener);
		});
	}

	var fetchTags = function(img) {

		var req = $.ajax({
			url: window.$TAGGER.base_url +
					"/tags?app_id=" + window.$TAGGER.app_id +
					"&image_url=" + encodeURIComponent(img.src),
			dataType: 'json',
            contentType: "application/json",
			crossDomain: true,
			success: function(data) {
				createViewer(img, data.tags);
			},
			error: function(xhr) {
//				if (xhr.status == 404)
					createViewer(img, []);
			}
		});

	};

	$('img').each(function(i, img) {
		if ($(img).width() > 100 && $(img).height() > 100) {
			fetchTags(img);
		}
	});



})();
