class SearchIndicesController < ApplicationController

  include ApplicationHelper

  require 'modules/delayed_solr_index.rb'
  
  before_filter :authenticate
  
  def show
    

  end

  def update


    if Delayed::Job.where('handler like "%!ruby/struct:DelayedSolrIndex%"').blank?

      if params[:type] == "full"

        Delayed::Job.enqueue DelayedSolrIndex.new('full'), :priority => 2
      
      else

        Delayed::Job.enqueue DelayedSolrIndex.new('delta'), :priority => 2
      
      end

    end

    redirect_to "/"

  end
  
end