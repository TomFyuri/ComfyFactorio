--This will add a new game mechanic so that containers with certain fluids explode when they get damaged or are destroyed.
--Made by MewMew

local event = require 'utils.event'

local damage_per_fluid = 6 -- default damage value for all fluids
local empty_tile_damage_decay = 75
local out_of_map_tile_health = 1500

local container_types = {
	["storage-tank"] = true,
	["pipe"] = true,
	["pipe-to-ground"] = true
}

local custom_fluid_damage = { -- custom damage for fluids
	["crude-oil"] = 4,
	["heavy-oil"] = 6,
	["light-oil"] = 7,
	["petroleum-gas"] = 8
}

local fluid_blacklist = {  -- ignored fluids
	["water"] = true,
	["steam"] = true,
	["lubricant"] = true,
	["sulfuric-acid"] = true
}

local circle_coordinates = {
	[1] = {{x = 0, y = 0}},
	[2] = {{x = -1, y = -1},{x = 1, y = -1},{x = 0, y = -1},{x = -1, y = 0},{x = -1, y = 1},{x = 0, y = 1},{x = 1, y = 1},{x = 1, y = 0}},
	[3] = {{x = -2, y = -1},{x = -1, y = -2},{x = 1, y = -2},{x = 0, y = -2},{x = 2, y = -1},{x = -2, y = 1},{x = -2, y = 0},{x = 2, y = 1},{x = 2, y = 0},{x = -1, y = 2},{x = 1, y = 2},{x = 0, y = 2}},
	[4] = {{x = -1, y = -3},{x = 1, y = -3},{x = 0, y = -3},{x = -3, y = -1},{x = -2, y = -2},{x = 3, y = -1},{x = 2, y = -2},{x = -3, y = 0},{x = -3, y = 1},{x = 3, y = 1},{x = 3, y = 0},{x = -2, y = 2},{x = -1, y = 3},{x = 0, y = 3},{x = 1, y = 3},{x = 2, y = 2}},
	[5] = {{x = -3, y = -3},{x = -2, y = -3},{x = -1, y = -4},{x = -2, y = -4},{x = 1, y = -4},{x = 0, y = -4},{x = 2, y = -3},{x = 3, y = -3},{x = 2, y = -4},{x = -3, y = -2},{x = -4, y = -1},{x = -4, y = -2},{x = 3, y = -2},{x = 4, y = -1},{x = 4, y = -2},{x = -4, y = 1},{x = -4, y = 0},{x = 4, y = 1},{x = 4, y = 0},{x = -3, y = 3},{x = -3, y = 2},{x = -4, y = 2},{x = -2, y = 3},{x = 2, y = 3},{x = 3, y = 3},{x = 3, y = 2},{x = 4, y = 2},{x = -2, y = 4},{x = -1, y = 4},{x = 0, y = 4},{x = 1, y = 4},{x = 2, y = 4}},
	[6] = {{x = -1, y = -5},{x = -2, y = -5},{x = 1, y = -5},{x = 0, y = -5},{x = 2, y = -5},{x = -3, y = -4},{x = -4, y = -3},{x = 3, y = -4},{x = 4, y = -3},{x = -5, y = -1},{x = -5, y = -2},{x = 5, y = -1},{x = 5, y = -2},{x = -5, y = 1},{x = -5, y = 0},{x = 5, y = 1},{x = 5, y = 0},{x = -5, y = 2},{x = -4, y = 3},{x = 4, y = 3},{x = 5, y = 2},{x = -3, y = 4},{x = -2, y = 5},{x = -1, y = 5},{x = 0, y = 5},{x = 1, y = 5},{x = 3, y = 4},{x = 2, y = 5}},
	[7] = {{x = -4, y = -5},{x = -3, y = -5},{x = -2, y = -6},{x = -1, y = -6},{x = 0, y = -6},{x = 1, y = -6},{x = 3, y = -5},{x = 2, y = -6},{x = 4, y = -5},{x = -5, y = -4},{x = -5, y = -3},{x = -4, y = -4},{x = 4, y = -4},{x = 5, y = -4},{x = 5, y = -3},{x = -6, y = -1},{x = -6, y = -2},{x = 6, y = -1},{x = 6, y = -2},{x = -6, y = 1},{x = -6, y = 0},{x = 6, y = 1},{x = 6, y = 0},{x = -5, y = 3},{x = -6, y = 2},{x = 5, y = 3},{x = 6, y = 2},{x = -5, y = 4},{x = -4, y = 4},{x = -4, y = 5},{x = -3, y = 5},{x = 3, y = 5},{x = 4, y = 4},{x = 5, y = 4},{x = 4, y = 5},{x = -1, y = 6},{x = -2, y = 6},{x = 1, y = 6},{x = 0, y = 6},{x = 2, y = 6}},
	[8] = {{x = -1, y = -7},{x = -2, y = -7},{x = 1, y = -7},{x = 0, y = -7},{x = 2, y = -7},{x = -5, y = -5},{x = -4, y = -6},{x = -3, y = -6},{x = 3, y = -6},{x = 4, y = -6},{x = 5, y = -5},{x = -6, y = -3},{x = -6, y = -4},{x = 6, y = -4},{x = 6, y = -3},{x = -7, y = -1},{x = -7, y = -2},{x = 7, y = -1},{x = 7, y = -2},{x = -7, y = 1},{x = -7, y = 0},{x = 7, y = 1},{x = 7, y = 0},{x = -7, y = 2},{x = -6, y = 3},{x = 6, y = 3},{x = 7, y = 2},{x = -5, y = 5},{x = -6, y = 4},{x = 5, y = 5},{x = 6, y = 4},{x = -3, y = 6},{x = -4, y = 6},{x = -2, y = 7},{x = -1, y = 7},{x = 0, y = 7},{x = 1, y = 7},{x = 3, y = 6},{x = 2, y = 7},{x = 4, y = 6}},
	[9] = {{x = -4, y = -7},{x = -3, y = -7},{x = -2, y = -8},{x = -1, y = -8},{x = 0, y = -8},{x = 1, y = -8},{x = 3, y = -7},{x = 2, y = -8},{x = 4, y = -7},{x = -5, y = -6},{x = -6, y = -6},{x = -6, y = -5},{x = 5, y = -6},{x = 6, y = -5},{x = 6, y = -6},{x = -7, y = -4},{x = -7, y = -3},{x = 7, y = -4},{x = 7, y = -3},{x = -8, y = -2},{x = -8, y = -1},{x = 8, y = -1},{x = 8, y = -2},{x = -8, y = 0},{x = -8, y = 1},{x = 8, y = 1},{x = 8, y = 0},{x = -7, y = 3},{x = -8, y = 2},{x = 7, y = 3},{x = 8, y = 2},{x = -7, y = 4},{x = -6, y = 5},{x = 6, y = 5},{x = 7, y = 4},{x = -5, y = 6},{x = -6, y = 6},{x = -4, y = 7},{x = -3, y = 7},{x = 3, y = 7},{x = 5, y = 6},{x = 4, y = 7},{x = 6, y = 6},{x = -2, y = 8},{x = -1, y = 8},{x = 0, y = 8},{x = 1, y = 8},{x = 2, y = 8}},
	[10] = {{x = -3, y = -9},{x = -1, y = -9},{x = -2, y = -9},{x = 1, y = -9},{x = 0, y = -9},{x = 3, y = -9},{x = 2, y = -9},{x = -5, y = -7},{x = -6, y = -7},{x = -5, y = -8},{x = -4, y = -8},{x = -3, y = -8},{x = 3, y = -8},{x = 5, y = -7},{x = 5, y = -8},{x = 4, y = -8},{x = 6, y = -7},{x = -7, y = -5},{x = -7, y = -6},{x = -8, y = -5},{x = 7, y = -5},{x = 7, y = -6},{x = 8, y = -5},{x = -9, y = -3},{x = -8, y = -4},{x = -8, y = -3},{x = 8, y = -4},{x = 8, y = -3},{x = 9, y = -3},{x = -9, y = -1},{x = -9, y = -2},{x = 9, y = -1},{x = 9, y = -2},{x = -9, y = 1},{x = -9, y = 0},{x = 9, y = 1},{x = 9, y = 0},{x = -9, y = 3},{x = -9, y = 2},{x = -8, y = 3},{x = 8, y = 3},{x = 9, y = 3},{x = 9, y = 2},{x = -7, y = 5},{x = -8, y = 5},{x = -8, y = 4},{x = 7, y = 5},{x = 8, y = 5},{x = 8, y = 4},{x = -7, y = 6},{x = -6, y = 7},{x = -5, y = 7},{x = 5, y = 7},{x = 7, y = 6},{x = 6, y = 7},{x = -5, y = 8},{x = -4, y = 8},{x = -3, y = 8},{x = -3, y = 9},{x = -2, y = 9},{x = -1, y = 9},{x = 0, y = 9},{x = 1, y = 9},{x = 3, y = 8},{x = 2, y = 9},{x = 3, y = 9},{x = 5, y = 8},{x = 4, y = 8}},
	[11] = {{x = -5, y = -9},{x = -4, y = -9},{x = -3, y = -10},{x = -1, y = -10},{x = -2, y = -10},{x = 1, y = -10},{x = 0, y = -10},{x = 3, y = -10},{x = 2, y = -10},{x = 5, y = -9},{x = 4, y = -9},{x = -7, y = -7},{x = -6, y = -8},{x = 7, y = -7},{x = 6, y = -8},{x = -9, y = -5},{x = -8, y = -6},{x = 9, y = -5},{x = 8, y = -6},{x = -9, y = -4},{x = -10, y = -3},{x = 9, y = -4},{x = 10, y = -3},{x = -10, y = -2},{x = -10, y = -1},{x = 10, y = -1},{x = 10, y = -2},{x = -10, y = 0},{x = -10, y = 1},{x = 10, y = 1},{x = 10, y = 0},{x = -10, y = 2},{x = -10, y = 3},{x = 10, y = 3},{x = 10, y = 2},{x = -9, y = 4},{x = -9, y = 5},{x = 9, y = 5},{x = 9, y = 4},{x = -8, y = 6},{x = -7, y = 7},{x = 7, y = 7},{x = 8, y = 6},{x = -6, y = 8},{x = -5, y = 9},{x = -4, y = 9},{x = 4, y = 9},{x = 5, y = 9},{x = 6, y = 8},{x = -3, y = 10},{x = -2, y = 10},{x = -1, y = 10},{x = 0, y = 10},{x = 1, y = 10},{x = 2, y = 10},{x = 3, y = 10}},
	[12] = {{x = -3, y = -11},{x = -2, y = -11},{x = -1, y = -11},{x = 0, y = -11},{x = 1, y = -11},{x = 2, y = -11},{x = 3, y = -11},{x = -7, y = -9},{x = -6, y = -9},{x = -5, y = -10},{x = -4, y = -10},{x = 5, y = -10},{x = 4, y = -10},{x = 7, y = -9},{x = 6, y = -9},{x = -9, y = -7},{x = -7, y = -8},{x = -8, y = -8},{x = -8, y = -7},{x = 7, y = -8},{x = 8, y = -7},{x = 8, y = -8},{x = 9, y = -7},{x = -9, y = -6},{x = -10, y = -5},{x = 9, y = -6},{x = 10, y = -5},{x = -11, y = -3},{x = -10, y = -4},{x = 10, y = -4},{x = 11, y = -3},{x = -11, y = -2},{x = -11, y = -1},{x = 11, y = -1},{x = 11, y = -2},{x = -11, y = 0},{x = -11, y = 1},{x = 11, y = 1},{x = 11, y = 0},{x = -11, y = 2},{x = -11, y = 3},{x = 11, y = 3},{x = 11, y = 2},{x = -10, y = 5},{x = -10, y = 4},{x = 10, y = 5},{x = 10, y = 4},{x = -9, y = 7},{x = -9, y = 6},{x = -8, y = 7},{x = 8, y = 7},{x = 9, y = 7},{x = 9, y = 6},{x = -8, y = 8},{x = -7, y = 8},{x = -7, y = 9},{x = -6, y = 9},{x = 7, y = 8},{x = 7, y = 9},{x = 6, y = 9},{x = 8, y = 8},{x = -5, y = 10},{x = -4, y = 10},{x = -3, y = 11},{x = -2, y = 11},{x = -1, y = 11},{x = 0, y = 11},{x = 1, y = 11},{x = 2, y = 11},{x = 3, y = 11},{x = 4, y = 10},{x = 5, y = 10}},
	[13] = {{x = -5, y = -11},{x = -4, y = -11},{x = -3, y = -12},{x = -1, y = -12},{x = -2, y = -12},{x = 1, y = -12},{x = 0, y = -12},{x = 3, y = -12},{x = 2, y = -12},{x = 4, y = -11},{x = 5, y = -11},{x = -8, y = -9},{x = -7, y = -10},{x = -6, y = -10},{x = 6, y = -10},{x = 7, y = -10},{x = 8, y = -9},{x = -10, y = -7},{x = -9, y = -8},{x = 9, y = -8},{x = 10, y = -7},{x = -11, y = -5},{x = -10, y = -6},{x = 10, y = -6},{x = 11, y = -5},{x = -11, y = -4},{x = -12, y = -3},{x = 11, y = -4},{x = 12, y = -3},{x = -12, y = -1},{x = -12, y = -2},{x = 12, y = -1},{x = 12, y = -2},{x = -12, y = 1},{x = -12, y = 0},{x = 12, y = 1},{x = 12, y = 0},{x = -12, y = 3},{x = -12, y = 2},{x = 12, y = 3},{x = 12, y = 2},{x = -11, y = 5},{x = -11, y = 4},{x = 11, y = 4},{x = 11, y = 5},{x = -10, y = 7},{x = -10, y = 6},{x = 10, y = 6},{x = 10, y = 7},{x = -9, y = 8},{x = -8, y = 9},{x = 9, y = 8},{x = 8, y = 9},{x = -7, y = 10},{x = -5, y = 11},{x = -6, y = 10},{x = -4, y = 11},{x = 5, y = 11},{x = 4, y = 11},{x = 7, y = 10},{x = 6, y = 10},{x = -3, y = 12},{x = -2, y = 12},{x = -1, y = 12},{x = 0, y = 12},{x = 1, y = 12},{x = 2, y = 12},{x = 3, y = 12}},
	[14] = {{x = -3, y = -13},{x = -1, y = -13},{x = -2, y = -13},{x = 1, y = -13},{x = 0, y = -13},{x = 3, y = -13},{x = 2, y = -13},{x = -7, y = -11},{x = -6, y = -11},{x = -5, y = -12},{x = -6, y = -12},{x = -4, y = -12},{x = 5, y = -12},{x = 4, y = -12},{x = 7, y = -11},{x = 6, y = -11},{x = 6, y = -12},{x = -10, y = -9},{x = -9, y = -9},{x = -9, y = -10},{x = -8, y = -10},{x = 9, y = -9},{x = 9, y = -10},{x = 8, y = -10},{x = 10, y = -9},{x = -11, y = -7},{x = -10, y = -8},{x = 11, y = -7},{x = 10, y = -8},{x = -11, y = -6},{x = -12, y = -6},{x = -12, y = -5},{x = 11, y = -6},{x = 12, y = -6},{x = 12, y = -5},{x = -13, y = -3},{x = -12, y = -4},{x = 12, y = -4},{x = 13, y = -3},{x = -13, y = -2},{x = -13, y = -1},{x = 13, y = -1},{x = 13, y = -2},{x = -13, y = 0},{x = -13, y = 1},{x = 13, y = 1},{x = 13, y = 0},{x = -13, y = 2},{x = -13, y = 3},{x = 13, y = 3},{x = 13, y = 2},{x = -12, y = 5},{x = -12, y = 4},{x = 12, y = 5},{x = 12, y = 4},{x = -11, y = 6},{x = -11, y = 7},{x = -12, y = 6},{x = 11, y = 7},{x = 11, y = 6},{x = 12, y = 6},{x = -10, y = 8},{x = -10, y = 9},{x = -9, y = 9},{x = 9, y = 9},{x = 10, y = 9},{x = 10, y = 8},{x = -9, y = 10},{x = -8, y = 10},{x = -7, y = 11},{x = -6, y = 11},{x = 7, y = 11},{x = 6, y = 11},{x = 8, y = 10},{x = 9, y = 10},{x = -6, y = 12},{x = -5, y = 12},{x = -4, y = 12},{x = -3, y = 13},{x = -2, y = 13},{x = -1, y = 13},{x = 0, y = 13},{x = 1, y = 13},{x = 2, y = 13},{x = 3, y = 13},{x = 5, y = 12},{x = 4, y = 12},{x = 6, y = 12}},
	[15] = {{x = -5, y = -13},{x = -6, y = -13},{x = -4, y = -13},{x = -3, y = -14},{x = -1, y = -14},{x = -2, y = -14},{x = 1, y = -14},{x = 0, y = -14},{x = 3, y = -14},{x = 2, y = -14},{x = 5, y = -13},{x = 4, y = -13},{x = 6, y = -13},{x = -9, y = -11},{x = -8, y = -11},{x = -8, y = -12},{x = -7, y = -12},{x = 7, y = -12},{x = 8, y = -12},{x = 8, y = -11},{x = 9, y = -11},{x = -11, y = -9},{x = -10, y = -10},{x = 10, y = -10},{x = 11, y = -9},{x = -12, y = -7},{x = -11, y = -8},{x = -12, y = -8},{x = 11, y = -8},{x = 12, y = -8},{x = 12, y = -7},{x = -13, y = -5},{x = -13, y = -6},{x = 13, y = -5},{x = 13, y = -6},{x = -13, y = -4},{x = -14, y = -3},{x = 13, y = -4},{x = 14, y = -3},{x = -14, y = -2},{x = -14, y = -1},{x = 14, y = -1},{x = 14, y = -2},{x = -14, y = 0},{x = -14, y = 1},{x = 14, y = 1},{x = 14, y = 0},{x = -14, y = 2},{x = -14, y = 3},{x = 14, y = 3},{x = 14, y = 2},{x = -13, y = 4},{x = -13, y = 5},{x = 13, y = 5},{x = 13, y = 4},{x = -13, y = 6},{x = -12, y = 7},{x = 12, y = 7},{x = 13, y = 6},{x = -11, y = 9},{x = -11, y = 8},{x = -12, y = 8},{x = 11, y = 8},{x = 11, y = 9},{x = 12, y = 8},{x = -9, y = 11},{x = -10, y = 10},{x = -8, y = 11},{x = 9, y = 11},{x = 8, y = 11},{x = 10, y = 10},{x = -7, y = 12},{x = -8, y = 12},{x = -6, y = 13},{x = -5, y = 13},{x = -4, y = 13},{x = 5, y = 13},{x = 4, y = 13},{x = 7, y = 12},{x = 6, y = 13},{x = 8, y = 12},{x = -3, y = 14},{x = -2, y = 14},{x = -1, y = 14},{x = 0, y = 14},{x = 1, y = 14},{x = 2, y = 14},{x = 3, y = 14}},
	[16] = {{x = -3, y = -15},{x = -1, y = -15},{x = -2, y = -15},{x = 1, y = -15},{x = 0, y = -15},{x = 3, y = -15},{x = 2, y = -15},{x = -7, y = -13},{x = -8, y = -13},{x = -5, y = -14},{x = -6, y = -14},{x = -4, y = -14},{x = 5, y = -14},{x = 4, y = -14},{x = 7, y = -13},{x = 6, y = -14},{x = 8, y = -13},{x = -9, y = -12},{x = -10, y = -11},{x = 9, y = -12},{x = 10, y = -11},{x = -11, y = -10},{x = -12, y = -9},{x = 11, y = -10},{x = 12, y = -9},{x = -13, y = -7},{x = -13, y = -8},{x = 13, y = -7},{x = 13, y = -8},{x = -14, y = -6},{x = -14, y = -5},{x = 14, y = -5},{x = 14, y = -6},{x = -15, y = -3},{x = -14, y = -4},{x = 15, y = -3},{x = 14, y = -4},{x = -15, y = -2},{x = -15, y = -1},{x = 15, y = -1},{x = 15, y = -2},{x = -15, y = 0},{x = -15, y = 1},{x = 15, y = 1},{x = 15, y = 0},{x = -15, y = 2},{x = -15, y = 3},{x = 15, y = 3},{x = 15, y = 2},{x = -14, y = 5},{x = -14, y = 4},{x = 14, y = 5},{x = 14, y = 4},{x = -13, y = 7},{x = -14, y = 6},{x = 13, y = 7},{x = 14, y = 6},{x = -13, y = 8},{x = -12, y = 9},{x = 12, y = 9},{x = 13, y = 8},{x = -11, y = 10},{x = -10, y = 11},{x = 10, y = 11},{x = 11, y = 10},{x = -9, y = 12},{x = -8, y = 13},{x = -7, y = 13},{x = 7, y = 13},{x = 8, y = 13},{x = 9, y = 12},{x = -6, y = 14},{x = -5, y = 14},{x = -4, y = 14},{x = -3, y = 15},{x = -2, y = 15},{x = -1, y = 15},{x = 0, y = 15},{x = 1, y = 15},{x = 2, y = 15},{x = 3, y = 15},{x = 4, y = 14},{x = 5, y = 14},{x = 6, y = 14}},
	[17] = {{x = -5, y = -15},{x = -6, y = -15},{x = -3, y = -16},{x = -4, y = -16},{x = -4, y = -15},{x = -1, y = -16},{x = -2, y = -16},{x = 1, y = -16},{x = 0, y = -16},{x = 3, y = -16},{x = 2, y = -16},{x = 5, y = -15},{x = 4, y = -15},{x = 4, y = -16},{x = 6, y = -15},{x = -9, y = -13},{x = -10, y = -13},{x = -8, y = -14},{x = -7, y = -14},{x = 7, y = -14},{x = 9, y = -13},{x = 8, y = -14},{x = 10, y = -13},{x = -11, y = -12},{x = -11, y = -11},{x = -12, y = -11},{x = -10, y = -12},{x = 11, y = -11},{x = 11, y = -12},{x = 10, y = -12},{x = 12, y = -11},{x = -13, y = -10},{x = -13, y = -9},{x = -12, y = -10},{x = 13, y = -9},{x = 13, y = -10},{x = 12, y = -10},{x = -14, y = -7},{x = -14, y = -8},{x = 14, y = -7},{x = 14, y = -8},{x = -15, y = -6},{x = -15, y = -5},{x = 15, y = -5},{x = 15, y = -6},{x = -15, y = -4},{x = -16, y = -4},{x = -16, y = -3},{x = 15, y = -4},{x = 16, y = -3},{x = 16, y = -4},{x = -16, y = -2},{x = -16, y = -1},{x = 16, y = -1},{x = 16, y = -2},{x = -16, y = 0},{x = -16, y = 1},{x = 16, y = 1},{x = 16, y = 0},{x = -16, y = 2},{x = -16, y = 3},{x = 16, y = 3},{x = 16, y = 2},{x = -16, y = 4},{x = -15, y = 4},{x = -15, y = 5},{x = 15, y = 5},{x = 15, y = 4},{x = 16, y = 4},{x = -15, y = 6},{x = -14, y = 7},{x = 14, y = 7},{x = 15, y = 6},{x = -13, y = 9},{x = -14, y = 8},{x = 13, y = 9},{x = 14, y = 8},{x = -13, y = 10},{x = -12, y = 10},{x = -12, y = 11},{x = -11, y = 11},{x = 11, y = 11},{x = 12, y = 11},{x = 12, y = 10},{x = 13, y = 10},{x = -11, y = 12},{x = -10, y = 12},{x = -10, y = 13},{x = -9, y = 13},{x = 9, y = 13},{x = 10, y = 13},{x = 10, y = 12},{x = 11, y = 12},{x = -8, y = 14},{x = -7, y = 14},{x = -6, y = 15},{x = -5, y = 15},{x = -4, y = 15},{x = 4, y = 15},{x = 5, y = 15},{x = 7, y = 14},{x = 6, y = 15},{x = 8, y = 14},{x = -4, y = 16},{x = -3, y = 16},{x = -2, y = 16},{x = -1, y = 16},{x = 0, y = 16},{x = 1, y = 16},{x = 2, y = 16},{x = 3, y = 16},{x = 4, y = 16}},
	[18] = {{x = -3, y = -17},{x = -4, y = -17},{x = -1, y = -17},{x = -2, y = -17},{x = 1, y = -17},{x = 0, y = -17},{x = 3, y = -17},{x = 2, y = -17},{x = 4, y = -17},{x = -9, y = -15},{x = -8, y = -15},{x = -7, y = -15},{x = -7, y = -16},{x = -6, y = -16},{x = -5, y = -16},{x = 5, y = -16},{x = 7, y = -15},{x = 7, y = -16},{x = 6, y = -16},{x = 9, y = -15},{x = 8, y = -15},{x = -11, y = -13},{x = -10, y = -14},{x = -9, y = -14},{x = 9, y = -14},{x = 11, y = -13},{x = 10, y = -14},{x = -13, y = -11},{x = -12, y = -12},{x = 13, y = -11},{x = 12, y = -12},{x = -15, y = -9},{x = -14, y = -10},{x = -14, y = -9},{x = 14, y = -10},{x = 14, y = -9},{x = 15, y = -9},{x = -15, y = -8},{x = -15, y = -7},{x = -16, y = -7},{x = 15, y = -8},{x = 15, y = -7},{x = 16, y = -7},{x = -16, y = -6},{x = -16, y = -5},{x = 16, y = -5},{x = 16, y = -6},{x = -17, y = -3},{x = -17, y = -4},{x = 17, y = -3},{x = 17, y = -4},{x = -17, y = -1},{x = -17, y = -2},{x = 17, y = -1},{x = 17, y = -2},{x = -17, y = 1},{x = -17, y = 0},{x = 17, y = 1},{x = 17, y = 0},{x = -17, y = 3},{x = -17, y = 2},{x = 17, y = 3},{x = 17, y = 2},{x = -17, y = 4},{x = -16, y = 5},{x = 16, y = 5},{x = 17, y = 4},{x = -15, y = 7},{x = -16, y = 7},{x = -16, y = 6},{x = 15, y = 7},{x = 16, y = 7},{x = 16, y = 6},{x = -15, y = 9},{x = -15, y = 8},{x = -14, y = 9},{x = 14, y = 9},{x = 15, y = 9},{x = 15, y = 8},{x = -14, y = 10},{x = -13, y = 11},{x = 13, y = 11},{x = 14, y = 10},{x = -12, y = 12},{x = -11, y = 13},{x = 11, y = 13},{x = 12, y = 12},{x = -10, y = 14},{x = -9, y = 14},{x = -9, y = 15},{x = -8, y = 15},{x = -7, y = 15},{x = 7, y = 15},{x = 9, y = 14},{x = 9, y = 15},{x = 8, y = 15},{x = 10, y = 14},{x = -7, y = 16},{x = -6, y = 16},{x = -5, y = 16},{x = -4, y = 17},{x = -3, y = 17},{x = -2, y = 17},{x = -1, y = 17},{x = 0, y = 17},{x = 1, y = 17},{x = 2, y = 17},{x = 3, y = 17},{x = 4, y = 17},{x = 5, y = 16},{x = 6, y = 16},{x = 7, y = 16}},
	[19] = {{x = -7, y = -17},{x = -6, y = -17},{x = -5, y = -17},{x = -3, y = -18},{x = -4, y = -18},{x = -1, y = -18},{x = -2, y = -18},{x = 1, y = -18},{x = 0, y = -18},{x = 3, y = -18},{x = 2, y = -18},{x = 5, y = -17},{x = 4, y = -18},{x = 7, y = -17},{x = 6, y = -17},{x = -10, y = -15},{x = -9, y = -16},{x = -8, y = -16},{x = 9, y = -16},{x = 8, y = -16},{x = 10, y = -15},{x = -13, y = -13},{x = -11, y = -14},{x = -12, y = -14},{x = -12, y = -13},{x = 11, y = -14},{x = 13, y = -13},{x = 12, y = -13},{x = 12, y = -14},{x = -13, y = -12},{x = -14, y = -12},{x = -14, y = -11},{x = 13, y = -12},{x = 14, y = -11},{x = 14, y = -12},{x = -15, y = -10},{x = -16, y = -9},{x = 15, y = -10},{x = 16, y = -9},{x = -17, y = -7},{x = -16, y = -8},{x = 16, y = -8},{x = 17, y = -7},{x = -17, y = -5},{x = -17, y = -6},{x = 17, y = -6},{x = 17, y = -5},{x = -18, y = -3},{x = -18, y = -4},{x = 18, y = -4},{x = 18, y = -3},{x = -18, y = -1},{x = -18, y = -2},{x = 18, y = -2},{x = 18, y = -1},{x = -18, y = 1},{x = -18, y = 0},{x = 18, y = 0},{x = 18, y = 1},{x = -18, y = 3},{x = -18, y = 2},{x = 18, y = 2},{x = 18, y = 3},{x = -17, y = 5},{x = -18, y = 4},{x = 17, y = 5},{x = 18, y = 4},{x = -17, y = 7},{x = -17, y = 6},{x = 17, y = 7},{x = 17, y = 6},{x = -16, y = 9},{x = -16, y = 8},{x = 16, y = 9},{x = 16, y = 8},{x = -15, y = 10},{x = -14, y = 11},{x = 14, y = 11},{x = 15, y = 10},{x = -14, y = 12},{x = -13, y = 12},{x = -13, y = 13},{x = -12, y = 13},{x = 12, y = 13},{x = 13, y = 13},{x = 13, y = 12},{x = 14, y = 12},{x = -12, y = 14},{x = -11, y = 14},{x = -10, y = 15},{x = 10, y = 15},{x = 11, y = 14},{x = 12, y = 14},{x = -9, y = 16},{x = -7, y = 17},{x = -8, y = 16},{x = -5, y = 17},{x = -6, y = 17},{x = 5, y = 17},{x = 7, y = 17},{x = 6, y = 17},{x = 8, y = 16},{x = 9, y = 16},{x = -3, y = 18},{x = -4, y = 18},{x = -1, y = 18},{x = -2, y = 18},{x = 1, y = 18},{x = 0, y = 18},{x = 3, y = 18},{x = 2, y = 18},{x = 4, y = 18}},
	[20] = {{x = -3, y = -19},{x = -4, y = -19},{x = -1, y = -19},{x = -2, y = -19},{x = 1, y = -19},{x = 0, y = -19},{x = 3, y = -19},{x = 2, y = -19},{x = 4, y = -19},{x = -9, y = -17},{x = -7, y = -18},{x = -8, y = -17},{x = -5, y = -18},{x = -6, y = -18},{x = 5, y = -18},{x = 7, y = -18},{x = 6, y = -18},{x = 9, y = -17},{x = 8, y = -17},{x = -11, y = -16},{x = -11, y = -15},{x = -12, y = -15},{x = -10, y = -16},{x = 11, y = -15},{x = 11, y = -16},{x = 10, y = -16},{x = 12, y = -15},{x = -13, y = -14},{x = -14, y = -13},{x = 13, y = -14},{x = 14, y = -13},{x = -15, y = -12},{x = -15, y = -11},{x = -16, y = -11},{x = 15, y = -11},{x = 15, y = -12},{x = 16, y = -11},{x = -17, y = -9},{x = -16, y = -10},{x = 16, y = -10},{x = 17, y = -9},{x = -17, y = -8},{x = -18, y = -7},{x = 17, y = -8},{x = 18, y = -7},{x = -18, y = -6},{x = -18, y = -5},{x = 18, y = -5},{x = 18, y = -6},{x = -19, y = -4},{x = -19, y = -3},{x = 19, y = -3},{x = 19, y = -4},{x = -19, y = -2},{x = -19, y = -1},{x = 19, y = -1},{x = 19, y = -2},{x = -19, y = 0},{x = -19, y = 1},{x = 19, y = 1},{x = 19, y = 0},{x = -19, y = 2},{x = -19, y = 3},{x = 19, y = 3},{x = 19, y = 2},{x = -19, y = 4},{x = -18, y = 5},{x = 18, y = 5},{x = 19, y = 4},{x = -18, y = 7},{x = -18, y = 6},{x = 18, y = 7},{x = 18, y = 6},{x = -17, y = 9},{x = -17, y = 8},{x = 17, y = 9},{x = 17, y = 8},{x = -16, y = 10},{x = -16, y = 11},{x = -15, y = 11},{x = 15, y = 11},{x = 16, y = 11},{x = 16, y = 10},{x = -15, y = 12},{x = -14, y = 13},{x = 14, y = 13},{x = 15, y = 12},{x = -13, y = 14},{x = -12, y = 15},{x = -11, y = 15},{x = 11, y = 15},{x = 12, y = 15},{x = 13, y = 14},{x = -11, y = 16},{x = -10, y = 16},{x = -9, y = 17},{x = -8, y = 17},{x = 9, y = 17},{x = 8, y = 17},{x = 10, y = 16},{x = 11, y = 16},{x = -7, y = 18},{x = -5, y = 18},{x = -6, y = 18},{x = -4, y = 19},{x = -3, y = 19},{x = -2, y = 19},{x = -1, y = 19},{x = 0, y = 19},{x = 1, y = 19},{x = 2, y = 19},{x = 3, y = 19},{x = 4, y = 19},{x = 5, y = 18},{x = 7, y = 18},{x = 6, y = 18}},
	[21] = {{x = -7, y = -19},{x = -5, y = -19},{x = -6, y = -19},{x = -3, y = -20},{x = -4, y = -20},{x = -1, y = -20},{x = -2, y = -20},{x = 1, y = -20},{x = 0, y = -20},{x = 3, y = -20},{x = 2, y = -20},{x = 5, y = -19},{x = 4, y = -20},{x = 7, y = -19},{x = 6, y = -19},{x = -11, y = -17},{x = -10, y = -17},{x = -9, y = -18},{x = -8, y = -18},{x = 9, y = -18},{x = 8, y = -18},{x = 10, y = -17},{x = 11, y = -17},{x = -13, y = -15},{x = -14, y = -15},{x = -12, y = -16},{x = 13, y = -15},{x = 12, y = -16},{x = 14, y = -15},{x = -15, y = -14},{x = -15, y = -13},{x = -14, y = -14},{x = 15, y = -13},{x = 15, y = -14},{x = 14, y = -14},{x = -17, y = -11},{x = -16, y = -12},{x = 16, y = -12},{x = 17, y = -11},{x = -17, y = -10},{x = -18, y = -9},{x = 17, y = -10},{x = 18, y = -9},{x = -19, y = -7},{x = -18, y = -8},{x = 18, y = -8},{x = 19, y = -7},{x = -19, y = -6},{x = -19, y = -5},{x = 19, y = -6},{x = 19, y = -5},{x = -20, y = -4},{x = -20, y = -3},{x = 20, y = -3},{x = 20, y = -4},{x = -20, y = -2},{x = -20, y = -1},{x = 20, y = -1},{x = 20, y = -2},{x = -20, y = 0},{x = -20, y = 1},{x = 20, y = 1},{x = 20, y = 0},{x = -20, y = 2},{x = -20, y = 3},{x = 20, y = 3},{x = 20, y = 2},{x = -20, y = 4},{x = -19, y = 5},{x = 19, y = 5},{x = 20, y = 4},{x = -19, y = 7},{x = -19, y = 6},{x = 19, y = 7},{x = 19, y = 6},{x = -18, y = 9},{x = -18, y = 8},{x = 18, y = 9},{x = 18, y = 8},{x = -17, y = 11},{x = -17, y = 10},{x = 17, y = 11},{x = 17, y = 10},{x = -16, y = 12},{x = -15, y = 13},{x = 15, y = 13},{x = 16, y = 12},{x = -15, y = 14},{x = -14, y = 14},{x = -14, y = 15},{x = -13, y = 15},{x = 13, y = 15},{x = 14, y = 15},{x = 14, y = 14},{x = 15, y = 14},{x = -12, y = 16},{x = -11, y = 17},{x = -10, y = 17},{x = 11, y = 17},{x = 10, y = 17},{x = 12, y = 16},{x = -9, y = 18},{x = -8, y = 18},{x = -7, y = 19},{x = -5, y = 19},{x = -6, y = 19},{x = 5, y = 19},{x = 6, y = 19},{x = 7, y = 19},{x = 9, y = 18},{x = 8, y = 18},{x = -4, y = 20},{x = -3, y = 20},{x = -2, y = 20},{x = -1, y = 20},{x = 0, y = 20},{x = 1, y = 20},{x = 2, y = 20},{x = 3, y = 20},{x = 4, y = 20}},
	[22] = {{x = -3, y = -21},{x = -4, y = -21},{x = -1, y = -21},{x = -2, y = -21},{x = 1, y = -21},{x = 0, y = -21},{x = 3, y = -21},{x = 2, y = -21},{x = 4, y = -21},{x = -10, y = -19},{x = -9, y = -19},{x = -8, y = -19},{x = -7, y = -20},{x = -5, y = -20},{x = -6, y = -20},{x = 5, y = -20},{x = 7, y = -20},{x = 6, y = -20},{x = 9, y = -19},{x = 8, y = -19},{x = 10, y = -19},{x = -13, y = -17},{x = -12, y = -17},{x = -11, y = -18},{x = -10, y = -18},{x = 11, y = -18},{x = 10, y = -18},{x = 13, y = -17},{x = 12, y = -17},{x = -15, y = -15},{x = -13, y = -16},{x = -14, y = -16},{x = 13, y = -16},{x = 15, y = -15},{x = 14, y = -16},{x = -17, y = -13},{x = -16, y = -14},{x = -16, y = -13},{x = 17, y = -13},{x = 16, y = -13},{x = 16, y = -14},{x = -17, y = -12},{x = -18, y = -11},{x = 17, y = -12},{x = 18, y = -11},{x = -19, y = -10},{x = -19, y = -9},{x = -18, y = -10},{x = 18, y = -10},{x = 19, y = -10},{x = 19, y = -9},{x = -19, y = -8},{x = -20, y = -7},{x = 19, y = -8},{x = 20, y = -7},{x = -20, y = -6},{x = -20, y = -5},{x = 20, y = -6},{x = 20, y = -5},{x = -21, y = -4},{x = -21, y = -3},{x = 21, y = -3},{x = 21, y = -4},{x = -21, y = -2},{x = -21, y = -1},{x = 21, y = -1},{x = 21, y = -2},{x = -21, y = 0},{x = -21, y = 1},{x = 21, y = 1},{x = 21, y = 0},{x = -21, y = 2},{x = -21, y = 3},{x = 21, y = 3},{x = 21, y = 2},{x = -21, y = 4},{x = -20, y = 5},{x = 20, y = 5},{x = 21, y = 4},{x = -20, y = 7},{x = -20, y = 6},{x = 20, y = 7},{x = 20, y = 6},{x = -19, y = 9},{x = -19, y = 8},{x = 19, y = 9},{x = 19, y = 8},{x = -19, y = 10},{x = -18, y = 11},{x = -18, y = 10},{x = 18, y = 11},{x = 18, y = 10},{x = 19, y = 10},{x = -17, y = 13},{x = -17, y = 12},{x = -16, y = 13},{x = 16, y = 13},{x = 17, y = 13},{x = 17, y = 12},{x = -16, y = 14},{x = -15, y = 15},{x = 15, y = 15},{x = 16, y = 14},{x = -14, y = 16},{x = -13, y = 16},{x = -13, y = 17},{x = -12, y = 17},{x = 13, y = 16},{x = 13, y = 17},{x = 12, y = 17},{x = 14, y = 16},{x = -11, y = 18},{x = -10, y = 18},{x = -10, y = 19},{x = -9, y = 19},{x = -8, y = 19},{x = 9, y = 19},{x = 8, y = 19},{x = 11, y = 18},{x = 10, y = 18},{x = 10, y = 19},{x = -7, y = 20},{x = -6, y = 20},{x = -5, y = 20},{x = -3, y = 21},{x = -4, y = 21},{x = -1, y = 21},{x = -2, y = 21},{x = 1, y = 21},{x = 0, y = 21},{x = 3, y = 21},{x = 2, y = 21},{x = 4, y = 21},{x = 5, y = 20},{x = 7, y = 20},{x = 6, y = 20}},
	[23] = {{x = -8, y = -21},{x = -7, y = -21},{x = -6, y = -21},{x = -5, y = -21},{x = -3, y = -22},{x = -4, y = -22},{x = -1, y = -22},{x = -2, y = -22},{x = 1, y = -22},{x = 0, y = -22},{x = 3, y = -22},{x = 2, y = -22},{x = 5, y = -21},{x = 4, y = -22},{x = 7, y = -21},{x = 6, y = -21},{x = 8, y = -21},{x = -12, y = -19},{x = -11, y = -19},{x = -10, y = -20},{x = -9, y = -20},{x = -8, y = -20},{x = 9, y = -20},{x = 8, y = -20},{x = 11, y = -19},{x = 10, y = -20},{x = 12, y = -19},{x = -14, y = -17},{x = -13, y = -18},{x = -12, y = -18},{x = 13, y = -18},{x = 12, y = -18},{x = 14, y = -17},{x = -15, y = -16},{x = -16, y = -15},{x = 15, y = -16},{x = 16, y = -15},{x = -17, y = -14},{x = -18, y = -13},{x = 17, y = -14},{x = 18, y = -13},{x = -19, y = -12},{x = -19, y = -11},{x = -18, y = -12},{x = 18, y = -12},{x = 19, y = -12},{x = 19, y = -11},{x = -20, y = -10},{x = -20, y = -9},{x = 20, y = -10},{x = 20, y = -9},{x = -21, y = -8},{x = -21, y = -7},{x = -20, y = -8},{x = 20, y = -8},{x = 21, y = -8},{x = 21, y = -7},{x = -21, y = -6},{x = -21, y = -5},{x = 21, y = -6},{x = 21, y = -5},{x = -22, y = -4},{x = -22, y = -3},{x = 22, y = -3},{x = 22, y = -4},{x = -22, y = -2},{x = -22, y = -1},{x = 22, y = -1},{x = 22, y = -2},{x = -22, y = 0},{x = -22, y = 1},{x = 22, y = 1},{x = 22, y = 0},{x = -22, y = 2},{x = -22, y = 3},{x = 22, y = 3},{x = 22, y = 2},{x = -22, y = 4},{x = -21, y = 5},{x = 21, y = 5},{x = 22, y = 4},{x = -21, y = 7},{x = -21, y = 6},{x = 21, y = 7},{x = 21, y = 6},{x = -21, y = 8},{x = -20, y = 9},{x = -20, y = 8},{x = 20, y = 8},{x = 20, y = 9},{x = 21, y = 8},{x = -19, y = 11},{x = -20, y = 10},{x = 19, y = 11},{x = 20, y = 10},{x = -19, y = 12},{x = -18, y = 13},{x = -18, y = 12},{x = 18, y = 13},{x = 18, y = 12},{x = 19, y = 12},{x = -17, y = 14},{x = -16, y = 15},{x = 16, y = 15},{x = 17, y = 14},{x = -15, y = 16},{x = -14, y = 17},{x = 14, y = 17},{x = 15, y = 16},{x = -13, y = 18},{x = -12, y = 18},{x = -12, y = 19},{x = -11, y = 19},{x = 11, y = 19},{x = 13, y = 18},{x = 12, y = 18},{x = 12, y = 19},{x = -10, y = 20},{x = -9, y = 20},{x = -8, y = 20},{x = -8, y = 21},{x = -7, y = 21},{x = -6, y = 21},{x = -5, y = 21},{x = 5, y = 21},{x = 7, y = 21},{x = 6, y = 21},{x = 8, y = 20},{x = 9, y = 20},{x = 8, y = 21},{x = 10, y = 20},{x = -4, y = 22},{x = -3, y = 22},{x = -2, y = 22},{x = -1, y = 22},{x = 0, y = 22},{x = 1, y = 22},{x = 2, y = 22},{x = 3, y = 22},{x = 4, y = 22}}
	}
	
local function process_explosion_tile(pos, explosion_index, current_radius)
	local surface = game.surfaces[global.explosion_schedule[explosion_index].surface]					
	local target_entities = surface.find_entities_filtered({area={{pos.x - 0.5, pos.y - 0.5},{pos.x + 0.499, pos.y + 0.499}}}) 
	local explosion_animation = "explosion"
	
	local tile = surface.get_tile(pos)	
	if tile.name == "out-of-map" then						
		if global.explosion_schedule[explosion_index].damage_remaining >= out_of_map_tile_health then
			explosion_animation = "big-explosion"
			surface.set_tiles({{name = "dirt-5", position = pos}}, true)
		end
		global.explosion_schedule[explosion_index].damage_remaining = global.explosion_schedule[explosion_index].damage_remaining - out_of_map_tile_health
	else
		local decay_explosion = true
		for _, entity in pairs(target_entities) do
			if entity.health then
				decay_explosion = false
			end			
		end
		if decay_explosion then global.explosion_schedule[explosion_index].damage_remaining = global.explosion_schedule[explosion_index].damage_remaining - empty_tile_damage_decay end
	end	
	
	for _, entity in pairs(target_entities) do
		if entity.health then						
			if entity.health < global.explosion_schedule[explosion_index].damage_remaining then
				explosion_animation = "big-explosion"
				if entity.health > 500 then explosion_animation = "big-artillery-explosion" end
				global.explosion_schedule[explosion_index].damage_remaining = global.explosion_schedule[explosion_index].damage_remaining - entity.health
				if entity then entity.damage(2097152, "player", "explosion") end			
			else				
				entity.damage(global.explosion_schedule[explosion_index].damage_remaining, "player", "explosion")
				global.explosion_schedule[explosion_index].damage_remaining = global.explosion_schedule[explosion_index].damage_remaining - entity.health				
			end
		end
	end
	
	if global.explosion_schedule[explosion_index].damage_remaining > 5000 and current_radius < 2 then
		if math.random(1,2) ==  1 then
			explosion_animation = "big-explosion"
		else
			explosion_animation = "big-artillery-explosion"
		end
	end
	
	surface.create_entity({name = explosion_animation, position = pos})
	
	if global.explosion_schedule[explosion_index].damage_remaining <= 0 then return false end
	
	return true		
end

local function create_explosion_schedule(entity)

	if not entity.fluidbox[1] then return end
	if fluid_blacklist[entity.fluidbox[1].name] then return end
	
	local explosives_amount = math.floor(entity.fluidbox[1].amount)
	
	if explosives_amount < 1 then return end		
	local center_position = entity.position
	
	if not global.explosion_schedule then global.explosion_schedule = {} end
	global.explosion_schedule[#global.explosion_schedule + 1] = {}
	global.explosion_schedule[#global.explosion_schedule].surface = entity.surface.name
	
	local d = damage_per_fluid
	if custom_fluid_damage[entity.fluidbox[1].name] then d = custom_fluid_damage[entity.fluidbox[1].name] end
	global.explosion_schedule[#global.explosion_schedule].damage_remaining = d * explosives_amount
	
	for current_radius = 1, 23, 1 do
		
		global.explosion_schedule[#global.explosion_schedule][current_radius] = {}
		global.explosion_schedule[#global.explosion_schedule][current_radius].trigger_tick = game.tick + (current_radius * 8)
		
		local circle_coords = circle_coordinates[current_radius]
		
		for index, tile_position in pairs(circle_coords) do												
			local pos = {x = center_position.x + tile_position.x, y = center_position.y + tile_position.y} 											
			global.explosion_schedule[#global.explosion_schedule][current_radius][index] = {x = pos.x, y = pos.y}
		end	
		
	end
	entity.die("player")
end

local function on_entity_damaged(event)
	local entity = event.entity
	if not container_types[entity.type] then return end
	if not entity.fluidbox[1] then return end
	
	if math.random(1,3) == 1 or entity.health <= 0 then create_explosion_schedule(event.entity) return end	
end

local function on_tick(event)
	if global.explosion_schedule then		
		local tick = game.tick
		local explosion_schedule_is_alive = false
		for explosion_index = 1, #global.explosion_schedule, 1 do			
			if #global.explosion_schedule[explosion_index] > 0 then
				explosion_schedule_is_alive = true
				local surface = game.surfaces[global.explosion_schedule[explosion_index].surface]
				for radius = 1, #global.explosion_schedule[explosion_index], 1 do														
					if global.explosion_schedule[explosion_index][radius].trigger_tick == tick then	
						for tile_index = 1, #global.explosion_schedule[explosion_index][radius], 1 do							
							local continue_explosion = process_explosion_tile(global.explosion_schedule[explosion_index][radius][tile_index], explosion_index, radius)
							if not continue_explosion then
								global.explosion_schedule[explosion_index] = {}
								break
							end														
						end							
						if radius == #global.explosion_schedule[explosion_index] then global.explosion_schedule[explosion_index] = {} end
						break
					end																					
				end				
			end			
		end
		if not explosion_schedule_is_alive then global.explosion_schedule = nil end
	end
end

event.add(defines.events.on_entity_damaged, on_entity_damaged)
event.add(defines.events.on_tick, on_tick)