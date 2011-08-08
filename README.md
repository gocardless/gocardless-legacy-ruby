# GoCardless Ruby API

## Introduction

This library provides a simple Ruby wrapper around the GoCardless REST API. To
use the API, you will need a GoCardless app id and app secret. To start with,
you'll need to create an instance of the {GoCardless::Client} class, providing
your app id and app secret as arguments to the constructor:

    client = GoCardless::Client(APP_ID, APP_SECRET)

## Setting up an Access Token

To retrieve data from the API, an access token is required. An access token
corresponds to a single merchant account, and give an app permission to access
and modify the merchant's data via the API. Multiple merchant accounts may be
accessed by using different access tokens.

### Obtaining a new Access Token

![Authorization Flow](http://i.imgur.com/sSgTy.png)

If you don't already have an access token stored, you will need the owner of a
merchant account to authorize your app via the web interface. Once they have
authorized your app, they will be redirected back to your website with an
authorization code. This code should then be exchanged for an access token,
which may be used to make authenticated requests against the API. The
{GoCardless::Client client} object can be used to generate the authorize url:

    auth_url = client.authorize_url(:redirect_uri => 'http://mywebsite.com/cb')
    redirect_to auth_url

The `redirect_uri` parameter specifies where the merchant account owner should
be sent after they have authorized your app. When the user is sent to this url,
the authorization code will be present as a query parameter named +code+. You
can use the {GoCardless::Client client} object to exchange this code for an
access token. Note that you must also provide the same `redirect_uri` used in
the previous step:

    auth_code = params[:code]
    client.fetch_access_token(auth_code, :redirect_uri => 'http://mywebsite.com/cb')

You can access a serialized version of the access token using the
{GoCardless::Client#access_token access\_token} attribute on the
{GoCardless::Client client} object. This should be stored alongside the
merchant for later use:

    merchant = Merchant.new(:name  => session[:merchant_name],
                            :token => client.access_token)
    merchant.save!

### Using an existing Access Token

To use a stored access token, just set the `access_token` attribute of a
{GoCardless::Client client} object to the stored token value, or initialize the
client object with the token as the third argument:

    client.access_token = Merchant.find(123).token

## Retrieving Data from the API

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

## Creating and modifying bills

The GoCardless API may also be used to create and modify bills. Bills must be
created on a pre authorization. To create a bill, use the
{GoCardless::PreAuthorization#create_bill create\_bill} method on
{GoCardless::PreAuthorization PreAuthorization} objects, providing the amount
in pence as the only argument:

    bill = pre_authorization.create_bill(150)  # => <GoCardless::Bill ...>

To modify the bill, alter the attributes and call the
{GoCardless::Resource#save save} method:

    bill.amount = 250
    bill.save

## Example usage
    require 'gocardless'

    # These are found in the GoCardless app admin interface
    APP_ID = '3QmpV5yi8Ii9Rc2uCwalWRsqkpibtk5ISOk/F+oyzrOoNpjGguZ4IRn2379agARS'
    APP_SECRET = '8oCITH2AVhaUYqJ+5hjyt8JUlSo5m/WTYLH8E/GO+TrBWdRK45lvoRt/zetr+t5Y'

    # Create a new instance of the GoCardless API client
    client = GoCardless::Client.new(app_id, app_secret)

    # Generate the OAuth 'authorize endpoint' URL
    client.authorize_url(:redirect_uri => 'http://mywebsite.com/cb')

    # Once the authorization code has been retrieved, exchange it for an access token
    auth_code = params[:auth_code]
    client.fetch_access_token(auth_code, :redirect_uri => 'http://mywebsite.com/cb')

    # The API client will associated with a merchant account
    client.merchant  # => <GoCardless::Merchant ...>

    # The client allows you to look up most resources by their id
    client.subscription(5)       # => <GoCardless::Subscription ...>
    client.pre_authorization(5)  # => <GoCardless::PreAuthorization ...>
    client.bill(5)               # => <GoCardless::Bill ...>
    client.payment(5)            # => <GoCardless::Payment ...>

    # Retrieve referenced resources directly from resource objects
    subscription = client.subscription(5)
    subscription.merchant  # => <GoCardless::Merchant ...>

    # Create a new bill
    client.merchant.pre_authorizations.first.create_bill(500) # £5.00 bill
