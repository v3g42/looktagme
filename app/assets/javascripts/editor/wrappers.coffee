skimlinksWrapper = (api)->
  $.map api.skimlinksProductAPI.products, (product) ->
    {
      title: product.title,
      description: product.description,
      price: product.price,
      image_url: product.images.imageThumb1Url
      image_width: product.images.imageThumb1Width
      image_height: product.images.imageThumb1Height
    }
semanticsWrapper = (list)->
  $.map list.results, (product) ->
    {
      title: product.name,
      description: product.description,
      price: product.price,
      image_url: product.images[0]
    }
