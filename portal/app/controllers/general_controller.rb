class GeneralController < ApplicationController
  def home
  end
  
  def redirect
    params[:redirect_url] ||= '/'
    redirect_to params[:redirect_url]
  end
end
