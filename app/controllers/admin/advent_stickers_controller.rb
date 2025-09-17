class Admin::AdventStickersController < Admin::ApplicationController
  before_action :set_advent_sticker, only: %i[ edit update destroy ]

  def index
    @advent_stickers = ShopItem::AdventSticker.includes(:image_attachment).order(:unlock_on)
    @acquisition_counts = UserAdventSticker.group(:shop_item_id).count
  end

  def new
    @advent_sticker = ShopItem::AdventSticker.new(campfire_only: true, enabled: true)
  end

  def create
    @advent_sticker = ShopItem::AdventSticker.new(advent_params)
    if @advent_sticker.save
      redirect_to admin_advent_stickers_path, notice: "Created Advent sticker."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @advent_sticker.update(advent_params)
      redirect_to admin_advent_stickers_path, notice: "Updated Advent sticker."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @advent_sticker.destroy
      redirect_to admin_advent_stickers_path, notice: "Deleted Advent sticker."
    else
      redirect_to admin_advent_stickers_path, alert: (@advent_sticker.errors.full_messages.first || "Sticker could not be deleted")
    end
  end

  private

  def set_advent_sticker
    @advent_sticker = ShopItem::AdventSticker.find(params[:id])
  end

  def advent_params
    params.require(:shop_item_advent_sticker).permit(:name, :description, :internal_description,
                                                     :unlock_on, :special, :enabled, :campfire_only,
                                                     :image, :silhouette_image)
  end
end
