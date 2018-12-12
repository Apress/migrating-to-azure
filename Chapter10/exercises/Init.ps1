az acr create --name <<registryName>> --resource-group gc-sandbox --sku Standard
az cdn profile create --name cardstock-nonprod --resource-group gc-sandbox
az storage account create --name cardstocknp01 --resource-group gc-sandbox
az cdn endpoint create --resource-group gc-sandbox --profile-name cardstock-nonprod --name cdn-cardstock-dev --origin cdn-cardstock-dev.gamecorp.us