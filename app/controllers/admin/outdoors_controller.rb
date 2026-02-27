module Admin
  class OutdoorsController < BaseController
    def index
      add_breadcrumb('Outdoors')

      @outdoors = Outdoor.includes(:user, :blocked_dates, :rents)
                        .order(created_at: :desc)
    end

    def show
      @outdoor = Outdoor.includes(:user, :blocked_dates, :rents).find(params[:id])
      add_breadcrumb('Outdoors', admin_outdoors_path)
      add_breadcrumb("Outdoor ##{@outdoor.id}")

      @blocked_dates = @outdoor.blocked_dates.order(start_date: :desc)
      @rents = @outdoor.rents.includes(:user).order(created_at: :desc)
    end
  end
end


