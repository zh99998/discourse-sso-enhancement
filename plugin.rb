# name: discourse-sso-enhancement
# about:  https://meta.discourse.org/t/should-we-expect-avatars-to-be-propagated-using-discourse-sso-provider/35332/5?u=zh99998
# version: 0.1
# authors: ckamps, zh99998 <zh99998@gmail.com>


after_initialize do
  
  # logout
  Discourse::Application.routes.append do
    get "logout" => "session#destroy"
  end
  SessionController.class_eval do
    skip_before_filter :preload_json, :check_xhr, only: ['destroy']
    def destroy
      reset_session
      log_off_user
      if params[:redirect]
        redirect_to params[:redirect]
      else
        render nothing: true
      end
    end 
    
    # avatar
    def sso_provider(payload=nil)
      payload ||= request.query_string
      if SiteSetting.enable_sso_provider
        sso = SingleSignOn.parse(payload, SiteSetting.sso_secret)
        if current_user
          sso.name = current_user.name
          sso.username = current_user.username
          sso.email = current_user.email
          sso.external_id = current_user.id.to_s
          sso.admin = current_user.admin?
          sso.moderator = current_user.moderator?
          sso.avatar_url = (SiteSetting.use_https? ? 'https:' : 'http:') + current_user.avatar_template_url.gsub("{size}", "36");
          sso.avatar_force_update = !!current_user.uploaded_avatar_id
          if request.xhr?
            cookies[:sso_destination_url] = sso.to_url(sso.return_sso_url)
          else
            redirect_to sso.to_url(sso.return_sso_url)
          end
        else
          session[:sso_payload] = request.query_string
          redirect_to path('/login')
        end
      else
        render nothing: true, status: 404
      end
    end
  end
end
