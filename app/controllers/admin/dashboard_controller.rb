module Admin
  class DashboardController < BaseController
    def index
      @total_outdoors = Outdoor.count
      @total_rents = Rent.count
      @pending_rents = Rent.where(status: 'pending').count
      @paid_rents = Rent.where(status: 'paid').count
      @total_blocked_dates = OutdoorBlockedDate.active.count
      @total_location_blocks = LocationBlockedDate.active.count

      @recent_rents = Rent.includes(:user, :outdoor)
                          .order(created_at: :desc)
                          .limit(10)

      @active_blocked_dates = OutdoorBlockedDate.includes(:outdoor, :admin_user)
                                                 .active
                                                 .order(start_date: :asc)
                                                 .limit(5)

      @active_location_blocks = LocationBlockedDate.includes(:admin_user)
                                                    .active
                                                    .order(start_date: :asc)
                                                    .limit(5)
    end
  end
end


