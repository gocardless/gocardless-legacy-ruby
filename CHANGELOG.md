## 1.3.0 - August 30, 2012

- Add cancel! method to pre_authorization
- Add paid_at accessor to the bill resource

## 1.2.1 - July 11, 2012

- Fix bug which caused Client#merchant to fail after #fetch_access_token was
  called during the merchant authorization flow (this only concerns partners).

## 1.2.0 - June 19, 2012

- Add some extra attributes to resources (e.g. status, merchant's balance, etc)
- Add a response_params_valid? method to check that resource response data is
  valid (including signature)

## 1.1.1 - June 07, 2012

- Fix handling of cancel_uri


## 1.1.0 - May 25, 2012

- Accept merchant_id as a client constructor param


## 1.0.1 - May 14, 2012

- Update oauth2 dependency version, fixes installation issue


## 1.0.0 - April 24, 2012

- Add plan_id to selected resources
- Remove deprecated resource attributes
- Fix sorting issue in Utils.normalize_params
- Add rake console task
- Add rake version:bump tasks
- Fix user agent formatting
- Relax multi_json dependency


## 0.2.0 - April 3, 2012

- Add `cancel!` method to `Subscription`
- Depend on multi_json rather than json
- Include the API version in the user agent header


## 0.1.3 - February 22, 2012

- Fix parameter encoding in `Client#new_merchant_url` (related to Faraday issue
  #115)
- Allow changing environment / base_url after client init


## 0.1.2 - February 2, 2012

- Add `webhook_valid?` method to `Client`
- Make `confirm_resource` play nicely with `HashWithIndifferentAccess`
- More RFC compliant parameter encoding


## 0.1.1 - January 12, 2012

- Add `name` to `Bill`
- Add `state` support to `new_{subscription,pre_authorization,bill}_url`


## 0.1.0 - November 23, 2011

- Initial release

