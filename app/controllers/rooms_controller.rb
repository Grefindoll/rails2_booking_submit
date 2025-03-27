class RoomsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_room, only: [:show]

  def index
    # @rooms = Room.all
    @q = Room.ransack(params[:q])
    @rooms = @q.result(distinct: true)
  end

  def my_rooms
    @user_rooms = current_user.rooms
  end

  def show
  end

  def new
    @room = Room.new
  end

  def create
    @room = current_user.rooms.build(room_params)

    if @room.save
      redirect_to rooms_path, notice: '施設が正常に作成されました。'
    else
      render :new
    end
  end


  private

  def set_room
    @room = Room.find(params[:id])
  end

  def room_params
    params.require(:room).permit(:name, :description, :price_per_night, :address, :room_image)
  end
end
