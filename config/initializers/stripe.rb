Rails.configuration.stripe = {
  publishable_key: 'pk_test_key',
  secret_key:      'sk_test_key'
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]