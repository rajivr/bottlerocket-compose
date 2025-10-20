use bottlerocket_modeled_types::Identifier;
use serde::Deserialize;
use std::collections::HashMap;

#[derive(Deserialize, Debug, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub(crate) struct ComposeContainersConfig {
    pub(crate) compose_containers: Option<HashMap<Identifier, ComposeContainer>>,
}

#[derive(Deserialize, Debug, PartialEq)]
#[serde(rename_all = "kebab-case")]
pub(crate) struct ComposeContainer {
    pub(crate) enabled: Option<bool>,
}
