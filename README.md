
# GoCardless Ruby Client


## Introduction

The GoCardless Ruby client provides a simple Ruby interface to the GoCardless
API. This document covers the usage of the Ruby library. For information on the
structure of the API itself, or for details on particular API resources, read
the [API overview](http://docs.gocardless.com/api/index.html).

### Using the API Sandbox

By default, the {GoCardless::Client client} will use
`https://www.gocardless.com` as the base URL. To use the API sandbox, you need
to set the base URL to `https://sandbox.gocardless.com`:

    GoCardless::Client.base_url = 'https://sandbox.gocardless.com'

This will force all requests to use the sandbox rather than the main site.

### Getting Started

To use the GoCardless API, you'll need to register a new app in the Developer
Panel. Registering an app provides you with an app ID and an app secret. These
are both required to access the API.

To start with, you'll need to create an instance of the {GoCardless::Client}
class, providing your app id and app secret as arguments to the constructor:

    client = GoCardless::Client.new(APP_ID, APP_SECRET)


## <a name="link-merchant-account">Linking a Merchant Account with the App</a>

Every instance of the GoCardless::Client accesses the API on behalf of *one*
merchant.

For this to happen, the merchant must go through a brief authorization process
to generate an access token, which you may then use to act on behalf of the
merchant via the API. Note that an app may have access tokens for many merchant
accounts, but you must create a new instance of GoCardless::Client for each
merchant.

To authorize an app, the merchant must be redirected to the GoCardless servers,
where they will be presented with a page that allows them to link their account
with the app. The URL to which the the merchant is sent contains information
about the app, as well as the URL (`redirect_uri`) where the merchant should be
sent back to once they've completed the process. The Ruby client library takes
care of most of this - only the `redirect_uri` must be provided:

    auth_url = client.new_merchant_url(:redirect_uri => 'http://mywebsite.com/cb')

(`new_merchant_url` is an alias for `authorize_url`, for OAuth followers)

More detail can be found in the [API docs](http://docs.gocardless.com/api/index.html).

The merchant must then be redirect to the generated `auth_url`, where they will
complete a short process to give the app access to their account. If the
merchant hasn't already created a merchant account on GoCardless, they will be
prompted to do so first.

Once the merchant has authorized the app, they will be redirected back to the
URL specified earlier (`http://mywebsite.com/cb` in the example above). The
API servers will include an "authorization code" as a query string parameter
(`code`):

    auth_code = params[:code]

This authorization code may be exchanged for an access token, which may be used
to access the merchant's account through the API. You can use the
{GoCardless::Client client} object to perform the exchange. The `redirect_uri`
that you used in the previous step must also be provided.

Note: providing `redirect_uri` is a OAuth 2.0 requirement to prevent attacks
based on the modification of `redirect_uri` during the earlier
`authorization_url` stage.

    client.fetch_access_token(auth_code, :redirect_uri => 'http://mywebsite.com/cb')

    new_token = client.access_token

The {GoCardless::Client#fetch_access_token fetch_access_token} method will set
`client.access_token` and return that `access_token`. You should store this
access token alongside the merchant's record in your database for future use.

You can also find the merchant's access token in the [Developer
Panel](https://sandbox.gocardless.com/) and set it manually on the client
instance;

    client.access_token = "qU9OXphbgi51hr5ryeQcY9N3e1wZ77PEoSqJulf2pR79DH53a+wtFMJxlco30y4t manage_merchant:74"

Note: ensure `manage_merchant:merchant_id` (the scope) is included if you are
entering the access token manually

To check whether your client is correctly configured, call `client.merchant` -
this should successfully return a {GoCardless::Merchant Merchant} object.

## Creating new Subscriptions, Pre-Authorizations and One-Off Payments

To create new subscriptions, you must have correctly configured the client
object with *both* App ID/Secret and a merchant's access token (see above on
["Linking a Merchant Account"](#link-merchant-account)</a>).

To set up new subscriptions, pre-authorizations and one-off payments between a
user and merchant account, you need to send the user to the GoCardless Connect
site to approve the process. This is broadly similar to the process for linking
merchant accounts with an app; the principal difference being the absence of a
resulting access token here.

Certain attributes for are required for each type of resource, while others are
optional - see the [API documentation](https://sandbox.gocardless.com/) for
full details.

These attributes are sent as query-string arguments. For security purposes, the
request must also contain a `timestamp`, `nonce` (randomly-generated value),
`merchant_id` and a `signature`. The {GoCardless::Client client} object takes
care of this security, so you simply need to provide the relevant attributes;

    url = client.new_subscription_url(:frequency_unit   => :week,
                                      :frequency_length => 1,
                                      :amount           => 3000,
                                      :description      => 'Premium membership')

Note: The amount should be provided in PENCE

Redirecting a user to `url` will take them to a page where they can authorize a
subscription of £30 every week. Once they have authorized the subscription,
they will be taken back to the `redirect_uri` specified on the app in the
Developer Panel. Optionally, you may provide a different `redirect_uri`,
although the host must match your app `redirect_uri`.

After the user has authorized the subscription, he will be sent back to
the `redirect_uri`, with some additional query string parameters appended.
These parameters will contain information about the resource (subscription,
 pre authorization or bill) that has just been created.

Important: Before the resource may be considered active, the app *must* confirm
it via the API. To do so, pass a hash of parameters received above to the
{GoCardless::Client#confirm\_resource} method on the {GoCardless::Client
client} object.

Example:

The app receives the user back at the url

http://mysite.com/confirm?resource_id=35&resource_type=subscription&resource_uri=https%3A%2F%2Fwww.gocardless.com%2Fapi%2Fv1%2Fsubscriptions%2F35&signature=bbf5b6d6d889a0a9af29adaa52175b219ad913bc194a56aadec0b0e994b0a15f

The params are:

    params = {
      :resource_id    => 35,
      :resource_type  => "subscription",
      :resource_uri   => "https://www.gocardless.com/api/v1/subscroptions/35"
      :signature      => "bbf5b6d6d889a0a9af29adaa52175b219ad913bc194a56aadec0b0e994b0a15f"
    }

You should pass these params into {GoCardless::Client#confirm_resource confirm_resource}

    subscription = client.confirm_resource(params)

The confirmed resource object (e.g. {GoCardless::Subscription subscription})
will be returned.

Note: {GoCardless::Client#confirm_resource confirm_resource} is an important
method. First, it validates that the resource parameters received at
`redirect_uri` have not been tampered with by verifying the signature against
one generated by the app secret. Second, it sends a request to the API server
to tell it to confirm the resource creation. If a resource is not confirmed, it
will be removed from the database after a short period of time.

## Creating bills

The GoCardless API may also be used to create and modify bills under an
existing PreAuthorization. To create a bill, use the
{GoCardless::PreAuthorization#create_bill create\_bill} method on
{GoCardless::PreAuthorization PreAuthorization} objects, providing the amount
in pence as the only argument:

    bill = pre_authorization.create_bill(:amount => 1500)
    bill  # => <GoCardless::Bill ...>


## Retrieving Data from the API

To create new subscriptions, you must have correctly configured the client
object with *both* App ID/Secret and a merchant's access token (see above on
["Linking a Merchant Account"](#link-merchant-account)</a>).

Once your {GoCardless::Client client} has a valid access token, you may request
data about the merchant associated with the token. To access the merchant's
information, use the `merchant` attribute on the client object. This returns an
instance of {GoCardless::Merchant}:

    merchant = client.merchant  # => <GoCardless::Merchant ...>
    merchant.name               # => "Harry's Burritos"

The {GoCardless::Merchant merchant} object also provides access to related
data, such as {GoCardless::Bill bills}, {GoCardless::Subscription
subscriptions} and {GoCardless::PreAuthorization pre-authorizations}:

    merchant.bills               # => [<GoCardless::Bill>, ...]
    merchant.subscriptions       # => [<GoCardless::Subscription>, ...]
    merchant.pre_authorizations  # => [<GoCardless::PreAuthorization>, ...]

These may also be filtered with various parameters:

    merchant.bills(:paid => true)          # Only fetches paid bills
    merchant.subscriptions(:user_id => 1)  # User 1's subscriptions

See the [API documentation](https://sandbox.gocardless.com/) for full details
of parameters that you can provide

Note that each time you use the {GoCardless::Client#merchant merchant}
attribute of {GoCardless::Client}, an API call will be made. To prevent many
unnecessary calls to the API server, assign the {GoCardless::Merchant merchant}
object to a variable and use that instead:

    # Rather than this (6 API calls):
    client.merchant.bills
    client.merchant.subscriptions
    client.merchant.pre_authorizations

    # Do this (4 API calls):
    merchant = client.merchant
    merchant.bills
    merchant.subscriptions
    merchant.pre_authorizations

To lookup instances of each resource type by id, accessor methods are provided
on {GoCardless::Client client} objects:

    client.subscription(5)  # => <GoCardless::Subscription ...>
    client.payment(10)      # => <GoCardless::Payment ...>

Some resources also have defined sub-resources. For example, bills are defined
as sub-resources of subscriptions. When a {GoCardless::Resource Resource} is
instantiated, methods will be created if any sub-resources are defined. These
methods return an array of sub-resource objects:

    subscription = merchant.subscriptions.first
    subscription.bills  # => [<GoCardless::Bill>, ...]

## Example usage

This process can be carried out in an IRB shell for testing

    require 'gocardless'

    # Set the `base_url` to sandbox if used in testing
    GoCardless::Client.base_url = "https://sandbox.gocardless.com"

    # These are found in the GoCardless "app" interface in the Developer Panel
    APP_ID = '3QmpV5yi8Ii9Rc2uCwalWRsqkpibtk5ISOk/F+oyzrOoNpjGguZ4IRn2379agARS'
    APP_SECRET = '8oCITH2AVhaUYqJ+5hjyt8JUlSo5m/WTYLH8E/GO+TrBWdRK45lvoRt/zetr+t5Y'

    # Create a new instance of the GoCardless API client
    client = GoCardless::Client.new(APP_ID, APP_SECRET)

    # Generate the OAuth 'authorize endpoint' URL
    url = client.new_merchant_url(:redirect_uri => 'http://mywebsite.com/cb')

    # Now, redirect the user (merchant) to 'url'. In Rails this would
    # look like:
    #
    #   redirect_to url
    #
    # They will be presented with a screen where they confirm the link between
    # their merchant account and the app. Once they are done, they will be
    # redirected back to the 'redirect_uri' provided.

    # Now you need to retrieve the authorization code from the query string
    # parameters:
    #
    #   auth_code = params[:auth_code]
    #
    # Then exchange the authorization code for an access token:

    client.fetch_access_token(auth_code, :redirect_uri => 'http://mywebsite.com/cb')

    # The access token should be saved to the database alongside the merchant.
    # You can get the access token using 'client.access_token'

    # To check the API client is correctly associated with a merchant account
    client.merchant  # => <GoCardless::Merchant ...>

    # To create a new subscription (or pre_authorization or one-off bill),
    # generate the appropriate URL:
    url = client.new_subscription_url(:frequency_unit   => :week,
                                      :frequency_length => 6,
                                      :amount           => 3000,
                                      :description      => 'Premium membership')

    # The client allows you to look up most resources by their id
    client.subscription(5)       # => <GoCardless::Subscription ...>
    client.pre_authorization(5)  # => <GoCardless::PreAuthorization ...>
    client.bill(5)               # => <GoCardless::Bill ...>
    client.payment(5)            # => <GoCardless::Payment ...>

    # Retrieve referenced resources directly from resource objects
    subscription = client.subscription(5)
    subscription.merchant  # => <GoCardless::Merchant ...>

    # Then redirect the user to the URL:
    #
    #   redirect_to url
    #
    # When the user is redirected back to your site, you need to confirm the
    # new subscription (assuming params is a hash of the query-string parameters):
    subscription = client.confirm_resource(params)

    # Create a new bill via the API under a pre_authorization.
    # No user interaction is needed beyond the initial pre_authorization
    pre_authorization = client.pre_authorization(7)
    pre_authorization.create_bill(500) # £5.00 bill

