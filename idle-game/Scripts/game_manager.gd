extends Node

## Signal emited when a new dinossaur is purchased (for the 3D scene to instanciate the model)
signal dino_spawned(dino_data: DinoData, total_owned: int)

## Base values before upgrades
var base_click_power: float = 1.0
var base_passive_production: float = 1.0

## Upgrade levels
var click_upgrade_level: int = 0
var passive_upgrade_level: int = 0

## Inventory: [dino_id (String) -> amount (int)]
var owned_dinos: Dictionary = {}

## Catalogue: [dino_id (String) -> DinoData]
var dino_catalog: Dictionary = {}
