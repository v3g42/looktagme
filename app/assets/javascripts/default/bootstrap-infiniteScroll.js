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

        var that = this;

        $(window).scroll(function () {
            if ($(window).scrollTop() >= that.$options.calculateBottom()) {
                that.loadMore();
            }
        });
    };

    InfiniteScroll.prototype = {
        constructor: InfiniteScroll,

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
                data = $this.data('infinite-search'),
                options = $.extend({}, $.fn.infiniteScroll.defaults, typeof option == 'object' && option);
            if (!data) $this.data('infinite-search', (data = new InfiniteScroll(this, options)));
            if (typeof options == 'string') data[options]();
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