
# GoCardless Ruby Client


## Introduction

The GoCardless Ruby client provides a simple Ruby interface to the GoCardless
API. This document covers the usage of the Ruby library, for information on the
structure of the API itself, or for details on particular API resources, read
the [API overview](../).

To use the GoCardless API, you'll need to register your app in the Developer
Panel. Registering an app provides you with an app ID and an app secret. These
are both required to access the API.

To start with, you'll need to create an instance of the {GoCardless::Client}
class, providing your app id and app secret as arguments to the constructor:

    client = GoCardless::Client.new(APP_ID, APP_SECRET)


### Using the API Sandbox

By default, the {GoCardless::Client client} will use
`https://www.gocardless.com` as the base URL. To use the API sandbox, you need
to set the base URL to `https://sandbox.gocardless.com`:

    GoCardless::Client.base_url = 'https://sandbox.gocardless.com'

This will force all requests to use the sandbox rather than the main site.


## Linking a Merchant Account with the App

The API allows you to act on behalf of a merchant. For this to happen, the
merchant must give your app access to their account. This authorization process
results in an access token, which you may then use to act as the merchant via
the API. Note that an app may have access tokens for many merchant accounts.

To authorize your app the merchant must be redirected to the GoCardless
servers, where they will be presented with a page that allows them to link
their account with your app. The URL that you send the merchant to contains
information about your app, as well as the URL where the merchant should be
sent back to once they've completed the process. The Ruby client library takes
care of most of this for you, all you need to provide is the URL:

    auth_url = client.authorize_url(:redirect_uri => 'http://mywebsite.com/cb')

Now you need to redirect the merchant to `auth_url`, so the merchant can give
your app access to their account. If the merchant hasn't already created a
merchant account on GoCardless, they will be prompted to do so first.

Once the merchant has authorized your app, they will be redirected back to the
URL you specified earlier (`http://mywebsite.com/cb` in the example above). The
API servers will include an "authorization code" as a query string parameter
(`code`):

    auth_code = params[:code]

This authorization code may be exchanged for an access token, which may be used
to access the merchant's account through the API. You can use the
{GoCardless::Client client} object to perform the exchange. The `redirect_uri`
that you used in the previous step must also be provided:

    client.fetch_access_token(auth_code, :redirect_uri => 'http://mywebsite.com/cb')
    token = client.access_token

The `token` is the access token that gives your app access to the merchant's
account. You should store this access token alongside the merchant's record in
your database.


## Retrieving Data from the API

To access the API on behalf of a merchant, you need to provide the
{GoCardless::Client client} object with the access token that corresponds to
the merchant. This may be done by assigning the token to the `access_token`
attribute. Note that the access token should be followed by its associated
scope (e.g. `'8qtbMqLdBTHZEBDQ2NO7eEBLmBo8QHi8g3L5XWuL5DnpDXpYuiby5nwGCh8X3WfJ
manage_merchant:123'`):

    # token should be in format '<token> <scope>'
    client.access_token = token

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

Note that each time you use the {GoCardless::Client#merchant merchant}
attribute of {GoCardless::Client}, an API call will be made. So to prevent many
of unnecessary slow calls to the API server from being made, assign the
{GoCardless::Merchant merchant} object to a variable and use that:

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

Some resources have defined sub-resources. For example, bills are defined as
sub-resources of subscriptions. When a {GoCardless::Resource Resource} is
instantiated, methods will be created if any sub-resources are defined. These
methods return an array of sub-resource objects:

    subscription = merchant.subscriptions.first
    subscription.bills  # => [<GoCardless::Bill>, ...]


## Creating new Subscriptions, Pre Authorizations and One-Off Payments

To set up new subscriptions, pre-authorizations and one-off payments between a
user and merchant account, you need to send the user to the GoCardless site to
approve the process. This is broadly similar to how you link merchant accounts
with your app, the principal difference being that you don't get an access
token at the end of it.

You should pass through certain attributes about the resource that you're
trying to create, such as the payment amount, or the subscription frequency.
These attributes are sent as query-string arguments. For security purposes, the
request must also contain a timestamp, nonce (randomly-generated value),
merchant id and a signature. The {GoCardless::Client client} object does this
for you, so you just need to provide the attributes:

    url = client.new_subscription_url(:frequency_unit   => :week,
                                      :frequency_length => 6,
                                      :amount           => 30,
                                      :description      => 'Premium membership')

Redirecting a user to `url` will take them to a page where they can authorize a
weekly subscription of £30 for a period of 6 weeks. Once they have authorized
the subscription, they will be taken back to your site.

The URL the user is sent back to will include some query string parameters
containing information about the resource (subscription, pre authorization or
bill) that has been created. Before the resource may be considered active, you
must confirm it via the API. To do so, pass a hash of the parameters to the
{GoCardless::Client#confirm\_resource} method on the {GoCardless::Client
client} object. The confirmed resource (e.g. subscription) will be returned:

    subscription = client.confirm_resource(params)


## Creating bills

The GoCardless API may also be used to create and modify bills. Bills must be
created on a pre authorization. To create a bill, use the
{GoCardless::PreAuthorization#create_bill create\_bill} method on
{GoCardless::PreAuthorization PreAuthorization} objects, providing the amount
in pence as the only argument:

    bill = pre_authorization.create_bill(:amount => 150)
    bill  # => <GoCardless::Bill ...>


## Example usage
    require 'gocardless'

    # These are found in the GoCardless app admin interface
    APP_ID = '3QmpV5yi8Ii9Rc2uCwalWRsqkpibtk5ISOk/F+oyzrOoNpjGguZ4IRn2379agARS'
    APP_SECRET = '8oCITH2AVhaUYqJ+5hjyt8JUlSo5m/WTYLH8E/GO+TrBWdRK45lvoRt/zetr+t5Y'

    # Create a new instance of the GoCardless API client
    client = GoCardless::Client.new(APP_ID, APP_SECRET)

    # Generate the OAuth 'authorize endpoint' URL
    authorize_url = client.authorize_url(:redirect_uri => 'http://mywebsite.com/cb')

    # Now, redirect the user (merchant) to 'authorize_url'. In Rails this would
    # look like:
    #
    #   redirect_to authorize_url
    #
    # They will be presented with a screen where they confirm the link between
    # their merchant account and your app. Once they are done, they will be
    # redirected back to the 'redirect_uri' you provided.

    # Now you need to retrieve the authorization code from the query string
    # parameters:
    #
    #   auth_code = params[:auth_code]
    #
    # Then exchange the authorization code for an access token:

    client.fetch_access_token(auth_code, :redirect_uri => 'http://mywebsite.com/cb')

    # The access token should be saved to the database alongside the merchant.
    # You can get the access token using 'client.access_token'

    # The API client will be associated with a merchant account
    client.merchant  # => <GoCardless::Merchant ...>

    # The client allows you to look up most resources by their id
    client.subscription(5)       # => <GoCardless::Subscription ...>
    client.pre_authorization(5)  # => <GoCardless::PreAuthorization ...>
    client.bill(5)               # => <GoCardless::Bill ...>
    client.payment(5)            # => <GoCardless::Payment ...>

    # Retrieve referenced resources directly from resource objects
    subscription = client.subscription(5)
    subscription.merchant  # => <GoCardless::Merchant ...>

    # To create a new subscription, generate the appropirate URL:
    url = client.new_subscription_url(:frequency_unit   => :week,
                                      :frequency_length => 6,
                                      :amount           => 30,
                                      :description      => 'Premium membership')

    # Then redirect the user to the URL:
    #
    #   redirect_to url
    #
    # When the user is redirected back to your site, you need to confirm the
    # new subscription (assuming params is the query-string parameters):
    subscription = client.confirm_resource(params)

    # Create a new bill via the API under a pre authorization:
    client.merchant.pre_authorizations.first.create_bill(500) # £5.00 bill

