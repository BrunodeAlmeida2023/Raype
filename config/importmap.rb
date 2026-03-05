# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Seus scripts customizados (não precisa do "to:" se o nome do arquivo for igual)
pin "documento_mask"
pin "home_carousel"
pin "home_scroll"
pin "password_toggle"
pin "flash_messages"
pin "date_validation"
pin "choose_art"
pin "location_map"
pin "location_video"
pin "checkout_payment"
pin "order_status"

# Admin modules
pin "admin_dashboard"
pin "admin_validations"

