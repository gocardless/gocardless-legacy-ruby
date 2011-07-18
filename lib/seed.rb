require 'grapi'

app_id = "ZQ9LRPdzi+6NfpYZGuChAsQLCREuI/H74FWeIWBw1r9mJ0je2zpkDjNrlCHaJoox"
app_secret = "Fmk5AuNoL/l+VDLl3WDmEAWW3UcO5o+JNl+dt705aQ1FwPv3klt0d5sn5XH6Ak5Q"

token = "kIxGsOyBgSrKTy5zkILh0y0x1gC/j3p9Ny6LFF/9iBBhd5ezucFbZX7/pqLlmsPB"

$c = Grapi::Client.new(app_id, app_secret, "#{token} manage_merchant:61")
$r_uri = 'http://localhost:3000/cb'