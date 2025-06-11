# frozen_string_literal: true

# This controller has been generated to enable Rails' resource routes.
# More information on https://docs.avohq.io/3.0/controllers.html
module Avo
  class ShopItemsController < Avo::ResourcesController
    def index
      # Hide free stickers by default unless explicitly requested
      if params[:show_free_stickers] != "true"
        @query = @query.where.not(type: "ShopItem::FreeStickers")
      end
      super
    end
  end
end
