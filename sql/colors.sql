-- https://www.sukrittan.com/Mod_Apps/JerseyEditor/
-------------------------------------
INSERT OR REPLACE INTO Colors
		(Type,							Color)
VALUES
		("COLOR_STANDARD_IMPERIAL_DK",		"141,0,51,255"),
		("COLOR_STANDARD_INDIGO_MD",		"0,119,168,255"),
		("COLOR_STANDARD_LIME_LT",			"191,219,28,255"),
		("COLOR_STANDARD_INDIGO_LT",		"148,215,234,255"),
		("COLOR_STANDARD_INDIGO_DK",		"0,60,86,255"),
		("COLOR_STANDARD_IMPERIAL_MD",		"181,0,69,255"),
		("COLOR_STANDARD_SAND_DK",		"68,46,26,255"),
		("COLOR_STANDARD_LIME_DK",		"62,74,0,255");

-- SWI
INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_CVS_ESCHER",
			"Unique",

			"COLOR_STANDARD_RED_LT",
			"COLOR_STANDARD_WHITE_LT",

			"COLOR_STANDARD_WHITE_MD2",
			"COLOR_STANDARD_IMPERIAL_MD",

			"COLOR_STANDARD_INDIGO_MD",
			"COLOR_STANDARD_WHITE_LT",

			"COLOR_STANDARD_GREEN_MD",
			"COLOR_STANDARD_WHITE_LT"
		);

-- ahiram
INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_LIME_PHOE_AHIRAM",
			"Unique",

			"COLOR_STANDARD_RED_DK",
			"COLOR_STANDARD_YELLOW_LT",

			"COLOR_STANDARD_PURPLE_DK",
			"COLOR_STANDARD_PURPLE_LT",

			"COLOR_STANDARD_PURPLE_MD",
			"COLOR_STANDARD_WHITE_LT",

			"COLOR_STANDARD_INDIGO_DK",
			"COLOR_STANDARD_WHITE_LT"
		);

-- Ba Trieu
UPDATE PlayerColors SET Alt1PrimaryColor='COLOR_STANDARD_PURPLE_DK', Alt1SecondaryColor='COLOR_STANDARD_YELLOW_LT' WHERE Type='LEADER_LADY_TRIEU';

-- TRISONG
INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_SUK_TRISONG_DETSEN",
			"Unique",

			"COLOR_STANDARD_WHITE_LT",
			"COLOR_STANDARD_GREEN_DK",

			"COLOR_STANDARD_GREEN_DK",
			"COLOR_STANDARD_WHITE_LT",

			"COLOR_STANDARD_RED_DK",
			"COLOR_STANDARD_ORANGE_LT",

			"COLOR_STANDARD_ORANGE_LT",
			"COLOR_STANDARD_RED_DK"
		);

-- al hasan
UPDATE PlayerColors SET PrimaryColor='COLOR_STANDARD_INDIGO_DK', SecondaryColor='COLOR_STANDARD_ORANGE_MD' WHERE Type='
LEADER_SUK_AL_HASAN';

-- Gorgo
UPDATE PlayerColors SET Alt2PrimaryColor='COLOR_STANDARD_IMPERIAL_DK', Alt2SecondaryColor='COLOR_STANDARD_WHITE_MD2' WHERE Type='LEADER_GORGO';

-- Vercingetorix
INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_SUK_VERCINGETORIX",
			"Unique",

			"COLOR_STANDARD_GREEN_DK",
			"COLOR_STANDARD_LIME_LT",

			"COLOR_STANDARD_INDIGO_MD",
			"COLOR_STANDARD_BLUE_DK",

			"COLOR_STANDARD_WHITE_MD2",
			"COLOR_STANDARD_AQUA_DK",

			"COLOR_STANDARD_GREEN_DK",
			"COLOR_STANDARD_IMPERIAL_DK"
		);

INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_SUK_VERCINGETORIX_DLC",
			"Unique",

			"COLOR_STANDARD_GREEN_DK",
			"COLOR_STANDARD_LIME_LT",

			"COLOR_STANDARD_INDIGO_MD",
			"COLOR_STANDARD_BLUE_DK",

			"COLOR_STANDARD_WHITE_MD2",
			"COLOR_STANDARD_AQUA_DK",

			"COLOR_STANDARD_GREEN_DK",
			"COLOR_STANDARD_IMPERIAL_DK"
		);

-- tekinich ii
INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_LL_TEKINICH_II",
			"Unique",

			"COLOR_STANDARD_PURPLE_DK",
			"COLOR_STANDARD_AQUA_MD",

			"COLOR_STANDARD_RED_DK",
			"COLOR_STANDARD_RED_LT",

			"COLOR_STANDARD_GREEN_DK",
			"COLOR_STANDARD_AQUA_MD",

			"COLOR_STANDARD_YELLOW_MD",
			"COLOR_STANDARD_ORANGE_DK"
		);

-- Wilfier Laurier
UPDATE PlayerColors SET Alt2PrimaryColor='COLOR_STANDARD_BLUE_DK', Alt2SecondaryColor='COLOR_STANDARD_BLUE_LT' WHERE Type='LEADER_LAURIER';

-- Wilhelmine
UPDATE PlayerColors SET Alt2PrimaryColor='COLOR_STANDARD_BLUE_MD', Alt2SecondaryColor='COLOR_STANDARD_ORANGE_LT' WHERE Type='LEADER_WILHELMINA';

UPDATE PlayerColors SET Alt3PrimaryColor='COLOR_STANDARD_INDIGO_MD', Alt3SecondaryColor='COLOR_STANDARD_ORANGE_LT' WHERE Type='LEADER_WILHELMINA';

-- Spearthrower Owl
UPDATE PlayerColors SET Alt1PrimaryColor='COLOR_STANDARD_ORANGE_DK', Alt1SecondaryColor='COLOR_STANDARD_YELLOW_MD' WHERE Type='LEADER_LIME_TEO_OWL';

-- san martin
INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_LEU_SANMARTIN",
			"Unique",

			"COLOR_STANDARD_INDIGO_LT",
			"COLOR_STANDARD_ORANGE_MD",

			"COLOR_STANDARD_INDIGO_MD",
			"COLOR_STANDARD_WHITE_LT",

			"COLOR_STANDARD_GREEN_LT",
			"COLOR_STANDARD_WHITE_LT",

			"COLOR_STANDARD_ORANGE_MD",
			"COLOR_STANDARD_WHITE_MD"
		);

-- mannerheim
INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_MER_MANNERHEIM",
			"Unique",

			"COLOR_STANDARD_WHITE_MD2",
			"COLOR_STANDARD_BLUE_DK",

			"COLOR_STANDARD_BLUE_DK",
			"COLOR_STANDARD_WHITE_MD2",

			"COLOR_STANDARD_YELLOW_MD",
			"COLOR_STANDARD_INDIGO_MD",

			"COLOR_STANDARD_WHITE_MD",
			"COLOR_STANDARD_WHITE_LT"
		);

-- iskandar
INSERT OR REPLACE INTO PlayerColors
		(
			Type,
			Usage,

			PrimaryColor,
			SecondaryColor,

			Alt1PrimaryColor,
			Alt1SecondaryColor,

			Alt2PrimaryColor,
			Alt2SecondaryColor,

			Alt3PrimaryColor,
			Alt3SecondaryColor
		)
VALUES
		(
			"LEADER_CVS_ISKANDAR",
			"Unique",

			"COLOR_STANDARD_PURPLE_MD",
			"COLOR_STANDARD_BLUE_LT",

			"COLOR_STANDARD_SAND_DK",
			"COLOR_STANDARD_ORANGE_LT",

			"COLOR_STANDARD_INDIGO_DK",
			"COLOR_STANDARD_AQUA_LT",

			"COLOR_STANDARD_GREEN_DK",
			"COLOR_STANDARD_YELLOW_LT"
		);

-- amanitore
UPDATE PlayerColors SET Alt2PrimaryColor='COLOR_STANDARD_LIME_DK', Alt2SecondaryColor='COLOR_STANDARD_YELLOW_LT' WHERE Type='LEADER_AMANITORE';

-- tomyris
UPDATE PlayerColors SET Alt3PrimaryColor='COLOR_STANDARD_WHITE_MD2', Alt3SecondaryColor='COLOR_STANDARD_SAND_DK' WHERE Type='LEADER_TOMYRIS';




