json.metadata do
  json.total @total
  json.page @page
  json.limit @limit
end

json.results @images do |image|
  json.image_url image.image_url
  json.page_url image.page_url
  json.tags image.tags, :x,:y,:title,:description,:price,:seller_url,:seller_name,:image_url,:image_width,:image_height,:currency,:page_url
end