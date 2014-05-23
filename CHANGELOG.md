## 1.9.0 - May 23, 2014

- Add ability to refund bills
- Add ability to cancel bills
- Add Payout API support
- Stop using the deprecated OpenSSL::Digest::Digest

## 1.8.0 - June 12, 2013

- Add Client#api_delete

## 1.7.0 - April 19, 2013

- Adds `retry!` method to Bill, allowing you to re-attempt collection where a
  bill has a status of `failed`
- Publicise Client#merchant_id
- Deprecate old syntax for setting merchant id / scope
- Add User#name method, for getting a user's full name
- Add `?` methods for checking resource statuses (e.g. `Subscription#active?`)

## 1.6.3 - February 11, 2013

- Handle empty arrays in Utils#flatten_params

## 1.6.2 - January 25, 2013

- Add fee accessors to Bill
- Remove display_name attribute from User class
- Add hide_variable_amount attribute to merchant

## 1.6.1 - November 06, 2012

- Fix - update Client references to base_url so custom base_urls work

## 1.6.0 - November 06, 2012

- Allow setting custom base_urls per-client

## 1.5.0 - October 29, 2012

- Use date_accessor to define next_interval_start methods

## 1.4.0 - October 29, 2012

- Allow app id and secret to be set with environment variables
- Relax the oauth dependency

## 1.3.2 - October 01, 2012

- Fix filtering on sub resource methods, e.g. `merchant.bills(source_id: 'x')`

## 1.3.1 - September 26, 2012

- Remove explicit rubygems requires

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

