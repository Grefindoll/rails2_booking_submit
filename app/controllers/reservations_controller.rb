class ReservationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_room, only: [:new, :create]

  def new
    @reservation = Reservation.new
  end

  def create
    @reservation = current_user.reservations.build(reservation_params)
    @reservation.room = @room

    if @reservation.save
      redirect_to confirmation_reservation_path(@reservation), notice: '予約が完了しました'
    else
      render :new
    end
  end

  def confirmation
    @reservation = Reservation.find(params[:id])
  end

  def my_reservations
    @reservations = current_user.reservations.includes(:room)
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def reservation_params
    params.require(:reservation).permit(:check_in, :check_out, :number_of_guests)
  end
end
