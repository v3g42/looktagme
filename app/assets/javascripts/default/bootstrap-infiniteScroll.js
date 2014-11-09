/* ============================================
 * bootstrap-infiniteScroll.js
 * ============================================ */

!function ($) {
    'use strict';
    var InfiniteScroll = function (el, options) {
        this.$element = $(el);
        this.$data = $(el).data();
        this.$options = options;

        this.executing = false;
        this.endOfResults = false;
        this.currentPage = 1;
        this.initialized = true;

        var that = this;
        that.scrollListener =  function () {
            if ($(window).scrollTop() >= that.$options.calculateBottom()) {
                that.loadMore();
            }
        };
        $(window).on('scroll',that.scrollListener);
    };

    InfiniteScroll.prototype = {
        constructor: InfiniteScroll,
        destroy: function(){
            var $this = this;
            $(window).off('scroll',$this.scrollListener);
            $this.endOfResults = false;
            $this.executing = false;
            console.log("Infinite scroll destroyed")
        },
        loadMore: function () {
            var $this = this;
            if ($this.executing || $this.endOfResults) return;

            $this.$element.append('<div class="spinner" />');

            $this.executing = true;
            $this.currentPage += 1;

            var data = $this.$options.getData();
            data.page = $this.currentPage;

            $.ajax({
                contentType: 'application/json; charset=UTF-8',
                data: data,
                url: $this.$options.url,
                type: 'GET'
            }).done(function (retVal) {
                $this.$options.processResults(retVal);
                var metadata = retVal.metadata;
                if (metadata && metadata.offset  > metadata.total) {
                    $this.endOfResults = true;
                }

                $this.$element.find('.spinner').remove();
                $this.executing = false;
            });
        }
    };

    $.fn.infiniteScroll = function (option) {


        return this.each(function () {
            var $this = $(this),
                data = $this.data('infinite-search');
            if (typeof option == 'string' && data && data[option]) data[option]();
            else if (typeof option == "object"){
                var options = $.extend({}, $.fn.infiniteScroll.defaults, option);
                $this.data('infinite-search', (data = new InfiniteScroll(this, options)));
            } else {
                //$.error( 'Method ' +  option + ' does not exist on jQuery.infiniteScroll' );
            }

        });
    };

    $.fn.infiniteScroll.defaults = {
        calculateBottom: function () { },
        getData: function () { },
        processResults: function () { },
        url: ''
    };

    $.fn.infiniteScroll.Constructor = InfiniteScroll;
} (window.jQuery);