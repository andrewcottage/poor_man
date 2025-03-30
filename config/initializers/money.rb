# encoding : utf-8

MoneyRails.configure do |config|

  config.locale_backend = :i18n

  config.rounding_mode = BigDecimal::ROUND_HALF_UP

  # To set the default currency
  #
  config.default_currency = :usd

  # Set default bank object
  #
  # Example:
  # config.default_bank = EuCentralBank.new

  # Add exchange rates to current money bank object.
  # (The conversion rate refers to one direction only)
  #
  # Example:
  config.add_rate "USD", "CAD", 1.24515
  config.add_rate "CAD", "USD", 0.803115
  config.add_rate "USD", "EUR", 0.863422
  config.add_rate "EUR", "USD", 1.15715
  config.add_rate "USD", "JPY", 110.463
  config.add_rate "JPY", "USD", 0.00906048
  config.add_rate "USD", "CNY", 6.36785
  config.add_rate "CNY", "USD", 0.15705
  config.add_rate "USD", "INR", 74.8825
  config.add_rate "INR", "USD", 0.01335
  config.add_rate "USD", "BRL", 5.23815
  config.add_rate "BRL", "USD", 0.19105
  config.add_rate "USD", "RUB", 73.8825
  config.add_rate "RUB", "USD", 0.0135
  config.add_rate "USD", "KRW", 1130.0
  config.add_rate "KRW", "USD", 0.000885
  config.add_rate "USD", "MXN", 20.23815
  config.add_rate "MXN", "USD", 0.04945
  config.add_rate "USD", "AUD", 1.33815
  config.add_rate "AUD", "USD", 0.74705
  config.add_rate "USD", "GBP", 0.73815
  config.add_rate "GBP", "USD", 1.35705
  config.add_rate "USD", "CHF", 0.93815
  config.add_rate "CHF", "USD", 1.06705
  config.add_rate "USD", "SEK", 8.23815
  config.add_rate "SEK", "USD", 0.12105
  config.add_rate "USD", "NOK", 8.23815
  config.add_rate "NOK", "USD", 0.12105

  # To handle the inclusion of validations for monetized fields
  # The default value is true
  #
  # config.include_validations = true

  # Default ActiveRecord migration configuration values for columns:
  #
  # config.amount_column = { prefix: '',           # column name prefix
  #                          postfix: '_cents',    # column name  postfix
  #                          column_name: nil,     # full column name (overrides prefix, postfix and accessor name)
  #                          type: :integer,       # column type
  #                          present: true,        # column will be created
  #                          null: false,          # other options will be treated as column options
  #                          default: 0
  #                        }
  #
  # config.currency_column = { prefix: '',
  #                            postfix: '_currency',
  #                            column_name: nil,
  #                            type: :string,
  #                            present: true,
  #                            null: false,
  #                            default: 'USD'
  #                          }

  # Register a custom currency
  #
  # Example:
  # config.register_currency = {
  #   priority:            1,
  #   iso_code:            "EU4",
  #   name:                "Euro with subunit of 4 digits",
  #   symbol:              "€",
  #   symbol_first:        true,
  #   subunit:             "Subcent",
  #   subunit_to_unit:     10000,
  #   thousands_separator: ".",
  #   decimal_mark:        ","
  # }

  # Specify a rounding mode
  # Any one of:
  #
  # BigDecimal::ROUND_UP,
  # BigDecimal::ROUND_DOWN,
  # BigDecimal::ROUND_HALF_UP,
  # BigDecimal::ROUND_HALF_DOWN,
  # BigDecimal::ROUND_HALF_EVEN,
  # BigDecimal::ROUND_CEILING,
  # BigDecimal::ROUND_FLOOR
  #
  # set to BigDecimal::ROUND_HALF_EVEN by default
  #
  # config.rounding_mode = BigDecimal::ROUND_HALF_UP

  # Set default money format globally.
  # Default value is nil meaning "ignore this option".
  # Example:
  #
  # config.default_format = {
  #   no_cents_if_whole: nil,
  #   symbol: nil,
  #   sign_before_symbol: nil
  # }

  # If you would like to use I18n localization (formatting depends on the
  # locale):
  # config.locale_backend = :i18n
  #
  # Example (using default localization from rails-i18n):
  #
  # I18n.locale = :en
  # Money.new(10_000_00, 'USD').format # => $10,000.00
  # I18n.locale = :es
  # Money.new(10_000_00, 'USD').format # => $10.000,00
  #
  # For the legacy behaviour of "per currency" localization (formatting depends
  # only on currency):
  # config.locale_backend = :currency
  #
  # Example:
  # Money.new(10_000_00, 'USD').format # => $10,000.00
  # Money.new(10_000_00, 'EUR').format # => €10.000,00
  #
  # In case you don't need localization and would like to use default values
  # (can be redefined using config.default_format):
  # config.locale_backend = nil

  # Set default raise_error_on_money_parsing option
  # It will be raise error if assigned different currency
  # The default value is false
  #
  # Example:
  # config.raise_error_on_money_parsing = false
end
