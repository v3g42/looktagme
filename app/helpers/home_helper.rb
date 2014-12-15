module HomeHelper

	def embed_looktag_me(user)
		app_id = user.present? ? user.app_id : -1  
		a = "<script type='text/javascript'>window.$TAGGER={base_url: '<%= absolute_link %>', app_id: '<%= app_id %>'};s=document.createElement('script');s.type='text/javascript';s.src='<%= absolute_link(asset_path('external/inject.js')) %>?v='+parseInt(Math.random()*99999999);document.body.appendChild(s);</script>"
		a.html_safe
	end

end
