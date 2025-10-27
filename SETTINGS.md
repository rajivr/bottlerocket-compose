# compose-containers

### Settings related to compose containers (`settings.compose-containers.*`)

You can use the `compose-containers` settings to define and alter the settings for compose applications. 

These settings will work **only** if `compose.yml` file is present in `/local/compose-containers/<compose_application>/compose.yml` on the Bottlerocket host filesystem. You can use [bootstrap containers](https://bottlerocket.dev/en/os/1.49.x/api/settings/bootstrap-containers/) to setup the required `compose.yml` files.

## Settings list for `settings.compose-containers`

* `settings.compose-containers.<compose_application>.enabled`

## Full reference

### `settings.compose-containers.<compose_application>.enabled`

If `true` the compose application that is present in `/local/compose-containers/<compose_application>/compose.yml` starts automatically at boot.

Accepted values:

* `true`
* `false` (default)
