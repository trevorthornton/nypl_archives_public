class AccessTermsController < ApplicationController
  def index
    @access_terms = AccessTerm.find(:all, :order => :term_original)
  end

  def show
    @access_term = AccessTerm.find params[:id]
  end
end
