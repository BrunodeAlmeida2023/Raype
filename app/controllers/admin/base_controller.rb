module Admin
  class BaseController < ApplicationController
    include AdminAuthentication

    layout 'admin'

    private

    def admin_breadcrumb
      @breadcrumbs ||= [{ name: 'Admin', path: admin_dashboard_path }]
    end
    helper_method :admin_breadcrumb

    def add_breadcrumb(name, path = nil)
      @breadcrumbs ||= admin_breadcrumb
      @breadcrumbs << { name: name, path: path }
    end
    helper_method :add_breadcrumb
  end
end

