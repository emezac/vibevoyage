# app/controllers/admin/analytics_controller.rb
class Admin::AnalyticsController < ApplicationController
  def dashboard
    @metrics = AnalyticsService.get_performance_dashboard(params[:timeframe] || '24h')
    render json: @metrics
  end
  
  def health
    @health = AnalyticsService.get_service_health
    render json: @health
  end
  
  def languages
    @stats = AnalyticsService.get_language_stats(params[:timeframe] || '7d')
    render json: @stats
  end
end
