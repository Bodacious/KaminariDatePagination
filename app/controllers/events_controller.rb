class EventsController < ApplicationController
  def index
    @events = Event.page(params[:page]).per(5)
  end
end
