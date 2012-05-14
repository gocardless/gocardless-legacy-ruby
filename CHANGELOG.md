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

