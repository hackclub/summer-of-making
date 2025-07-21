module Admin
  class CachesController < ApplicationController
    CACHES = {
      all_shop_items_with_variants_v2: "Vanilla shop items",
      all_black_market_shop_items_with_variants: "Black market shop items"
    }

    def index = @caches = CACHES

    def zap
      key = params[:id].to_sym
      unless CACHES[key].present?
        flash[:alert] = "huh?"
        redirect_to admin_caches_path
        return
      end

      if Rails.cache.delete(key)
        flash[:success] = [ "burninated." "BALEETED.", "it's gone. you don't have to worry about it anymore.", "so long, #{key}!" ].sample
      else
        flash[:notice] = "couldn't do it. either there was an error, or nothing was cached there. probably the latter."
      end
      redirect_to admin_caches_path
    end
  end
end
