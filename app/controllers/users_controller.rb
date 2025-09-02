class UsersController < ApplicationController
  def index
    # @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      # flash[:notice] = "プロフィールを更新しました。" # 必要であればflashメッセージを設定
      redirect_to user_path(@user)
    else
      # バリデーションエラーの場合、編集ページを再描画
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :bio, :profile_image,)
  end
end
