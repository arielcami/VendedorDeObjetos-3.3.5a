-- // Datos de Configuracion del comportamiento del Scritp //

local NPC_ID = 00000 -- Entry del NPC que correrá el script
local MAX_RESULTS = 25
local COEFFICIENT_PRICE = 1 -- Multiplicador global del precio de compra de los objetos
local FLAT_PRICE = 10000 -- Precio fijo que se le otorga a los objetos que tienen un buyPrice = 0, por ejemplo: "Abismo primigenio" id 23572
local FORBIDDEN_CHARACTERS = { '"', "'", '\\', '%', '_', ';', '#', '`', '/', '-', '$', '*' }

-- Elegir iconos
local function ico(sel)
    return (sel==1) and "|TInterface\\Icons\\inv_misc_spyglass_01:42:42:-21:0|t" or 
           (sel==2) and "|TInterface\\Icons\\inv_inscription_scroll:42:42:-21:0|t" or 
           (sel==3) and "|TInterface\\Icons\\inv_misc_coin_02:42:42:-21:0|t" 
end

-- Consultas dinámicas
local function GetQuery()
    local query = {

        CREATE_DATABASE = function()
            return [[CREATE TABLE IF NOT EXISTS aa_itemvendor (entry INT UNSIGNED NOT NULL PRIMARY KEY, `name` VARCHAR(70) NOT NULL, 
                    buyPrice INT UNSIGNED NOT NULL, maxCount TINYINT UNSIGNED NOT NULL)]]
        end,

        CREATE_LOG_TABLE = function()
            return [[CREATE TABLE IF NOT EXISTS aa_itemvendor_log (id INT NOT NULL AUTO_INCREMENT PRIMARY KEY, player_name VARCHAR(12) NOT NULL,
                    player_id INT UNSIGNED NOT NULL, purchased VARCHAR(70) NOT NULL, item_id MEDIUMINT UNSIGNED NOT NULL,
                    amount MEDIUMINT UNSIGNED NOT NULL, expense INT UNSIGNED NOT NULL, purchase_time TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP)]]
        end,

        CREATE_FRECUENT_TABLE = function()
            return [[CREATE TABLE IF NOT EXISTS aa_itemvendor_frecuent (entry int unsigned NOT NULL, name varchar(70) NOT NULL, 
                    buyPrice int unsigned NOT NULL, maxCount tinyint unsigned NOT NULL, times int unsigned NOT NULL DEFAULT '1', 
                    player_id int unsigned NOT NULL, UNIQUE KEY uniq_entry_player (entry,player_id))]]
        end,

        INSERT_INTO_LOG = function(player_name, player_id, purchased, item_id, amount, expense)
            return string.format(
                "INSERT INTO aa_itemvendor_log (player_name, player_id, purchased, item_id, amount, expense) VALUES ('%s', %d, '%s', %d, %d, %d)",
                player_name, player_id, purchased, item_id, amount, expense
            )
        end,

        INSERT_OR_UPDATE_FREQUENT_PURCHASE = function(entry, name, buyPrice, maxCount, player_id)
            return string.format(
                "INSERT INTO aa_itemvendor_frecuent (entry, `name`, buyPrice, maxCount, times, player_id) " ..
                "VALUES (%d, '%s', %d, %d, 1, %d) ON DUPLICATE KEY UPDATE times = times + 1",
                entry, name, buyPrice, maxCount, player_id
            )
        end,

        INSERT_ITEM_INTO_VENDOR_TABLE = function(entry, name, buyPrice, maxCount)
            return string.format(
                "INSERT INTO aa_itemvendor (entry, `name`, buyPrice, maxCount) VALUES (%d, '%s', %d, %d)", entry, name, buyPrice, maxCount
            )
        end,

        SELECT_ITEM_BY_NAME = function(name)
            return string.format(
                "SELECT * FROM aa_itemvendor WHERE `name` LIKE '%%%s%%' LIMIT %d", name, (MAX_RESULTS > 30 and 30 or MAX_RESULTS)
            )
        end,

        SELECT_FRECUENT_PURCHASES_BY_PLAYER_ID = function(player_id)
            return string.format("SELECT * FROM aa_itemvendor_frecuent WHERE player_id = %d ORDER BY times DESC LIMIT 10", player_id)
        end,

        SELECT_ONE_BY_ENTRY = function(entry)
            return string.format("SELECT 1 FROM aa_itemvendor WHERE entry = %d LIMIT 1", entry)
        end,

        UPDATE_ITEM_BUY_PRICE = function(input, option)
            return string.format("UPDATE aa_itemvendor SET buyPrice = %d WHERE `entry` = %d", input, option)
        end,

        DELETE_ONE_BY_ENTRY = function (entry)
            return string.format("DELETE FROM aa_itemvendor WHERE entry = %d", entry)
        end,

        CHECK_IF_TABLE_IS_POPULATED = function ()
            return "SELECT 1 FROM aa_itemvendor LIMIT 1"
        end,

        SELECT_ONE_FROM_LOG_BY_PLAYER_ID = function (player_id)
            return string.format("SELECT 1 FROM aa_itemvendor_log WHERE player_id = %d", player_id)
        end,

        SELECT_LAST_20_FROM_LOG_BY_PLAYER_ID = function(player_id)
            return string.format("SELECT amount, item_id, purchase_time FROM aa_itemvendor_log WHERE player_id = %d ORDER BY purchase_time DESC LIMIT 20", player_id
        )
        end,

        SELECT_BUYPRICE_AND_MAXCOUNT_BY_ITEM_ENTRY = function (item_entry)
            return string.format("SELECT BuyPrice, maxcount FROM item_template WHERE entry = %d", item_entry)
        end,

        SELECT_BUYPRICE_BY_ITEM_ENTRY = function (item_entry)
            return string.format("SELECT buyPrice FROM aa_itemvendor WHERE entry = %d", item_entry)
        end,

        SELECT_ITEM_ENTRY_BY_ITEM_ENTRY = function (item_entry)
            return string.format("SELECT entry FROM aa_itemvendor WHERE entry = %d", item_entry)
        end
    }
    return query
end


--// Configuración del Dumping //
local CONF = {                              -- Por defecto:
    ['ARMAS']                           = 'TRUE',  -- TRUE
    ['ARMADURAS']                       = 'TRUE',  -- TRUE
    ['ARMAS_EPICAS']                    = 'FALSE', -- FALSE
    ['ARMADURAS_EPICAS']                = 'FALSE', -- FALSE
    ['ITEMS_QUE_NO_SE_LIGAN']           = 'TRUE',  -- TRUE
    ['ITEMS_QUE_SE_LIGAN_AL_RECOGER']   = 'FALSE', -- FALSE
    ['ITEMS_QUE_SE_LIGAN_AL_EQUIPAR']   = 'TRUE',  -- TRUE
    ['ITEMS_QUE_SE_LIGAN_AL_USAR']      = 'TRUE',  -- TRUE
    ['ITEMS_QUE_SE_LIGAN_MISION']       = 'FALSE', -- FALSE
    ['ITEMS_QUE_SE_LIGAN_iCOKE']        = 'FALSE', -- FALSE
    ['CALIDAD_GRIS']                    = 'FALSE', -- FALSE
    ['CALIDAD_BLANCO']                  = 'TRUE',  -- TRUE
    ['CALIDAD_VERDE']                   = 'TRUE',  -- TRUE
    ['CALIDAD_AZUL']                    = 'TRUE',  -- TRUE
    ['CALIDAD_MORADO']                  = 'FALSE', -- FALSE
    ['CALIDAD_NARANJA']                 = 'FALSE', -- FALSE
    ['CALIDAD_ARTEFACTO']               = 'FALSE', -- FALSE
    ['ITEMS_QUE_SE_LIGAN_A_LA_CUENTA']  = 'FALSE', -- FALSE
    ['CONSUMIBLES']                     = 'TRUE',  -- TRUE
    ['BOLSAS']                          = 'TRUE',  -- TRUE
    ['GEMAS']                           = 'TRUE',  -- TRUE
    ['PROYECTILES']                     = 'TRUE',  -- TRUE
    ['RECETAS']                         = 'TRUE',  -- TRUE
    ['MARCAS_DE_HONOR']                 = 'FALSE', -- FALSE
    ['CARCAJ']                          = 'TRUE',  -- TRUE
    ['OBJETOS_DE_MISION']               = 'FALSE', -- FALSE
    ['LLAVES']                          = 'FALSE', -- FALSE
    ['OBJETOS_COMERCIABLES']            = 'TRUE',  -- TRUE
    ['MISCELANEA']                      = 'FALSE', -- FALSE
    ['GLIFOS']                          = 'TRUE'   -- TRUE
}

-- Agregar más objetos si se quiere
local LISTA_NEGRA = "33350,37410,24477,24476,33470,21877,28430,40553,41257,41383,41384,44926,44948,30732,30724,31318,34622,39302,"
    .. "31342,31322,31336,31334,31332,31331,31323,20698,45173,45174,45175,38497,38496,38498,27965,34025,34030,37126,28388,28389,17882,"
    .. "17887,22023,22024,22584,29841,29868,29871,14891,21442,26173,26174,26175,26180,26235,26324,26368,26372,26464,26465,26548,26655,26738,"
    .. "26792,26843,27196,27218,37301,38292,39163,138,931,2275,2588,2599,3884,3934,5632,40754,40948,43336,43337,43384,31266,27774,27811,"
    .. "28117,28122,41403,41404,41405,41406,41407,41408,41409,41410,41411,41412,41413,41414,41415,41416,41417,41418,41419,41420,41421,41422,"
    .. "41423,43362,45908,21038,32722,33226,34062,34599,38294,38518,42986,43523,46783,54822,52252,996,1020,1021,1024,1025,1027,1162,5235,"
    .. "19642,22822,49191,48509,48442,50319,45605,40408,42254,39427,42241,42247,42345,43613,44310,37856,37697,37649,42215,42216,42217,42343,"
    .. "45172,37739,29828,37611,36477,36673,38247,32053,32046,32044,28297,28310,28312,37597,32659,28929,28930,28931,28957,28955,28954,31492,"
    .. "26779,32190,32179,32178,32914,22802,22804,23044,22803,23458,17142,24071,20720,10049, 3222, 2664,23422,2502, 2484,24100,12991,19924,"
    .. "32841,5283,2184,48515,48444,42269,42264,42259,42220,42218,42219,36561,38243,32028,32003,53890,53889,28313,28314,38469,28947,28922,28928,"
    .. "28953,32188,32189,23242,11743,20005,28905,5600,48440,48507,42238,42231,42226,42207,42236,42206,42212,42213,42214,45575,36575,31985,31965,"
    .. "28308,28309,28946,28920,32175,32174,22816,45630,17068,33080,3895,5255,4965,2498,2482,20979,37,49689,29712,29419,12348,1259"

-- Volcado de items en la db, se puede agregar más IDs aquí
local dump_data = "INSERT INTO aa_itemvendor (entry, `name`, buyPrice, maxCount) " ..
    "SELECT it.entry, itl.Name, it.buyPrice, it.maxcount " ..
    "FROM item_template it " ..
    "JOIN item_template_locale itl ON it.entry = itl.ID " ..
    "WHERE itl.locale = 'esMX' " ..
    
    -- Condiciones por binding
    "AND (" ..
    "(it.bonding = 0 AND " .. CONF['ITEMS_QUE_NO_SE_LIGAN'] .. ") OR " ..
    "(it.bonding = 1 AND " .. CONF['ITEMS_QUE_SE_LIGAN_AL_RECOGER'] .. ") OR " ..
    "(it.bonding = 2 AND " .. CONF['ITEMS_QUE_SE_LIGAN_AL_EQUIPAR'] .. ") OR " ..
    "(it.bonding = 3 AND " .. CONF['ITEMS_QUE_SE_LIGAN_AL_USAR'] .. ") OR " ..
    "(it.bonding = 4 AND " .. CONF['ITEMS_QUE_SE_LIGAN_MISION'] .. ") OR " ..
    "(it.bonding = 5 AND " .. CONF['ITEMS_QUE_SE_LIGAN_iCOKE'] .. ")) " ..

    -- Condiciones por clase, algunas hardcoded 
    "AND (" ..
    "(it.class = 0 AND " .. CONF['CONSUMIBLES'] .. ") OR " ..
    "(it.class = 1 AND " .. CONF['BOLSAS'] .. ") OR " ..
    "(it.class = 2 AND " .. CONF['ARMAS'] .. ") OR " ..
    "(it.class = 3 AND " .. CONF['GEMAS'] .. ") OR " ..
    "(it.class = 4 AND " .. CONF['ARMADURAS'] .. ") OR " ..
    "(it.class = 5 AND " .. CONF['MARCAS_DE_HONOR'] .. ") OR " ..
    "(it.class = 6 AND " .. CONF['PROYECTILES'] .. ") OR " ..
    "(it.class = 7 AND " .. CONF['OBJETOS_COMERCIABLES'] .. ") OR " ..
    "(it.class = 8 AND FALSE) OR "..
    "(it.class = 9 AND " .. CONF['RECETAS'] .. ") OR " ..
    "(it.class = 10 AND FALSE) OR "..
    "(it.class = 11 AND " .. CONF['CARCAJ'] .. ") OR " ..
    "(it.class = 12 AND " .. CONF['OBJETOS_DE_MISION'] .. ") OR " ..
    "(it.class = 13 AND " .. CONF['LLAVES'] .. ") OR " ..
    "(it.class = 14 AND FALSE) OR "..
    "(it.class = 15 AND " .. CONF['MISCELANEA'] .. ") OR " ..
    "(it.class = 16 AND " .. CONF['GLIFOS'] .. ")) " .. 

    -- Condiciones por calidad
    "AND (" ..
    "(it.quality = 0 AND " .. CONF['CALIDAD_GRIS'] .. ") OR " ..
    "(it.quality = 1 AND " .. CONF['CALIDAD_BLANCO'] .. ") OR " ..
    "(it.quality = 2 AND " .. CONF['CALIDAD_VERDE'] .. ") OR " ..
    "(it.quality = 3 AND " .. CONF['CALIDAD_AZUL'] .. ") OR " ..
    "(it.quality = 4 AND " .. CONF['CALIDAD_MORADO'] .. ") OR " ..
    "(it.quality = 5 AND " .. CONF['CALIDAD_NARANJA'] .. ") OR " ..
    "(it.quality = 6 AND " .. CONF['CALIDAD_ARTEFACTO'] .. ") OR " ..
    "(it.quality = 7 AND " .. CONF['ITEMS_QUE_SE_LIGAN_A_LA_CUENTA'] .. ")) " ..

    -- Excepciones por armas y armaduras épicas
    "AND NOT (it.class = 2 AND it.quality = 4 AND NOT " .. CONF['ARMAS_EPICAS'] .. ") " ..
    "AND NOT (it.class = 4 AND it.quality = 4 AND NOT " .. CONF['ARMADURAS_EPICAS'] .. ") " ..

    -- Exclusión de la lista negra
    "AND it.entry NOT IN ("..LISTA_NEGRA..")"


-- Tablas que contendrán los resultados y podrán ser leídas desde la segunda función `CLICK_2` --
local ITEMS_IDS
local ITEMS_NAMES
local ITEMS_PRICES
local ITEMS_MAXCOUNTS
local ITEMS_UNIQUES
local ITEM_ADD

local function formatCurrency(a)
    if a < 100 then 
        return ("%d cobre"):format(a)
    end
    local d,u = a < 10000 and 100 or 10000, a < 10000 and "plata" or "oro"
    return tostring(math.floor(a/d*100+0.5)/100):gsub("(%..-)0+$","%1"):gsub("%.$","") .. " " .. u
end

local function escaparSQL(input)
    if not input then
        return nil -- Maneja valores nulos
    end
    -- Elimina las comillas simples y dobles del string
    return input:gsub("['\"]", "")
end

-- Función para determinar si hay caracteres peligrosos en la entrada
local function hasForbiddenChars(str)
    for c in str:gmatch(".") do
        for _, forbidden in ipairs(FORBIDDEN_CHARACTERS) do
            if c == forbidden then
                return true
            end
        end
    end
    return false
end

-- Función que facilita enviar mensajes diferentes
local function MSG(text, Player, option)
    if option then 
        -- Mensaje de error -failed-
        Player:SendBroadcastMessage('|cffff3030' .. text)
    else           
        -- Mensaje correcto -success-
        Player:SendBroadcastMessage('|cff00ff00' .. text)
    end
end

-- Función para extraer el nombre en español de un GetItemLink()
local function extractItemName(inputString)
    -- Usar string.match para extraer directamente el contenido dentro de []
    return string.match(inputString, "%[(.-)%]")
end


-- Funcion del primer click
local function CLICK_1(e, P, U)

    local sql = GetQuery()
    local table_is_populated = WorldDBQuery( sql.CHECK_IF_TABLE_IS_POPULATED() ) 

    if not table_is_populated then
        WorldDBExecute(dump_data)
    end

    P:GossipMenuAddItem(8, ico(1) .. 'Buscar un objeto', 0, 0, true, 'Ingresa parte del nombre del objeto...')
    P:GossipMenuAddItem(8, ico(3) .. 'Compras frecuentes', 5, 0)    
    P:GossipMenuAddItem(8, ico(2) .. 'Ver mis últimas compras', 4, 0)

    local player_account = P:GetAccountId()
    local account_is_allowed = player_account == 1 -- or player_account == 5 -- arielcamilo y ariel2

    if account_is_allowed then
        P:GossipMenuAddItem(0, ico(1) .. '[|cff0080ffAñadir objeto|r]', 1, 0, true, 'Ingresar el ID de objeto')
        P:GossipMenuAddItem(0, ico(1) .. '[|cff1b7300Editar precio de objeto|r]', 2, 0, true, 'Ingresar el ID de objeto')
        P:GossipMenuAddItem(0, ico(1) .. '[|cffff0000Eliminar objeto|r]', 3, 0, true, 'Ingresar el ID de objeto')
    end

    P:GossipSendMenu(1, U)
end

-- Función Principal - Segundo click
local function CLICK_2(e, P, U, send, option, raw_input)

    -- Compras frecuentes
    if (send == 5 and option == 0) then
    
        local Q = GetQuery().SELECT_FRECUENT_PURCHASES_BY_PLAYER_ID(P:GetGUIDLow())
        local frecuently_bought_items = WorldDBQuery(Q);

        if frecuently_bought_items then

            -- Pasamos agua, jabón y lejía
            ITEMS_IDS       = {}
            ITEMS_NAMES     = {}
            ITEMS_PRICES    = {}
            ITEMS_MAXCOUNTS = {}
            ITEMS_UNIQUES   = {}
            
            local conteo = 1

            P:SendBroadcastMessage('Mostrando compras frecuentes de ' .. P:GetName()..'.')
            
            repeat

                local item_entry    = frecuently_bought_items:GetUInt32(0);
                local item_name     = frecuently_bought_items:GetString(1);
                local item_buyprice = (frecuently_bought_items:GetUInt32(2) == 0) and FLAT_PRICE or frecuently_bought_items:GetUInt32(2);
                local item_maxcount = frecuently_bought_items:GetUInt32(3);
                local item_unique   = (item_maxcount == 1) and true or false
                local item_link     = GetItemLink(item_entry, 7)
                local price_show    = formatCurrency(item_buyprice * COEFFICIENT_PRICE);

                P:GossipMenuAddItem(0, item_link .. ' |cff752f00' .. price_show, item_entry, conteo, true, 'Ingresa la cantidad que quieres comprar.')

                table.insert(ITEMS_IDS, item_entry)
                table.insert(ITEMS_NAMES, item_name)
                table.insert(ITEMS_PRICES, item_buyprice)
                table.insert(ITEMS_MAXCOUNTS, item_maxcount)
                table.insert(ITEMS_UNIQUES, item_unique)
                P:SendBroadcastMessage(conteo .. '. ' .. item_link .. ' ' .. price_show)
                conteo = conteo + 1 

            until not frecuently_bought_items:NextRow();

            P:GossipSendMenu(1, U)
        else    
            P:GossipComplete();
            P:SendBroadcastMessage('|cffff0000No tienes registros de compras frecuentes.')
        end
        return
    end

    -- Aceptar un registro
    if (send == 100) and (option > 25) then
        local entry = option
        local nombre, precio, maximo = escaparSQL(ITEM_ADD[1]), ITEM_ADD[2], ITEM_ADD[3]
        local item_exists = WorldDBQuery( GetQuery().SELECT_ONE_BY_ENTRY(entry) );

        if not item_exists then
            WorldDBExecute( GetQuery().INSERT_ITEM_INTO_VENDOR_TABLE(entry, nombre, precio, maximo) )
            P:SendBroadcastMessage(GetItemLink(entry, 7) .. '|cff00ff00 agregado con éxito!!')
            P:GossipComplete()
        else
            P:SendBroadcastMessage('|cffff0000[ERROR]: Ese objeto ya existe en los registros.')
        end
        ITEM_ADD = {}
        P:GossipComplete()
        return
    end

    -- Editar un precio
    if (send == 101) and (option > 25) then
        -- Asegurarse que la entrada es numérica entera positiva, en este caso el INPUT es el precio en COBRE
        local input = (tonumber(raw_input) and math.floor(tonumber(raw_input)) >= 1) and math.floor(tonumber(raw_input)) or 0;

        local item_exists = WorldDBQuery( GetQuery().SELECT_ONE_BY_ENTRY(option) );

        if item_exists then
            WorldDBExecute( GetQuery().UPDATE_ITEM_BUY_PRICE(input, option) )
            P:SendBroadcastMessage('|cff00ff00Precio modificado con éxito!!')
        else
            P:SendBroadcastMessage('|cffff0000[ERROR]: Ese objeto no existe en los registros.')
        end
        P:GossipComplete()
        return
    end

    -- Eliminar un objeto
    if (send == 102) and (option > 25) then
        
        WorldDBExecute( GetQuery().DELETE_ONE_BY_ENTRY(option) )

        P:SendBroadcastMessage('|cff00ff00Objeto eliminado con éxito!!')
        P:GossipComplete()
        return
    end

    -- Limpiar el menú (enviar al primer click)
    if send == 999 and option == 999 then
        CLICK_1(1, P, U)
        return
    end

    -- Ver registros
    if (send == 4) then
        if (option == 0) then
            local playerID = P:GetGUIDLow()
            local check_log = WorldDBQuery( GetQuery().SELECT_ONE_FROM_LOG_BY_PLAYER_ID(playerID) );

            if check_log then
                local Q = WorldDBQuery( GetQuery().SELECT_LAST_20_FROM_LOG_BY_PLAYER_ID(playerID) )

                P:SendBroadcastMessage('Mostrando los últimos registros de ' .. P:GetName() .. '.')

                local counter = 1
                repeat
                    local cantidad = Q:GetUInt32(0)
                    local itemID = Q:GetUInt32(1)
                    local fecha = Q:GetString(2)

                    P:SendBroadcastMessage(counter .. '. ' .. GetItemLink(itemID, 7) .. ' x' .. cantidad .. ' - ' .. fecha)
                    counter = counter + 1
                until not Q:NextRow();
            else
                P:SendBroadcastMessage('|cffff0000Aún no has comprado ningún objeto.')
            end
        end
        P:GossipComplete()
        return
    end

    -- Checkear la entrada por caracteres maliciosos
    if hasForbiddenChars(raw_input) then
        MSG('[Error]: No se puede realizar la búsqueda con esos caracteres.', P, 1)
        P:GossipComplete()
        return
    else
        local search_query
        -- Búsqueda de objeto
        if (send + option == 0) then
            -- El NPC avisa al jugador que ha iniciado la busqueda con las palabras clave
            U:SendUnitSay('Buscando "' .. raw_input .. '" para ' .. P:GetName() .. '...', 0)

            local Q = WorldDBQuery( GetQuery().SELECT_ITEM_BY_NAME(raw_input));

            local conteo = 1

            if Q then
                P:SendBroadcastMessage('Mostrando resultados para "|cff00ff00' .. raw_input .. '|r"')

                -- Pasamos agua, jabón y lejía
                ITEMS_IDS       = {}
                ITEMS_NAMES     = {}
                ITEMS_PRICES    = {}
                ITEMS_MAXCOUNTS = {}
                ITEMS_UNIQUES   = {}

                repeat -- Bloque iterativo
                    -- 0:entry, 1:name, 2:buyPrice, 3:maxCount
                    local item_entry    = Q:GetUInt32(0)
                    local item_name     = escaparSQL(Q:GetString(1))
                    local item_buyPrice = (Q:GetUInt32(2) == 0) and FLAT_PRICE or Q:GetUInt32(2)
                    local item_maxCount = Q:GetUInt32(3)
                    local price_show    = formatCurrency(item_buyPrice * COEFFICIENT_PRICE);
                    local isUnique      = (item_maxCount == 1) and true or false
                    local item_link     = GetItemLink(item_entry, 7);

                    P:GossipMenuAddItem(0, item_link .. ' |cff752f00' .. price_show .. '|r', item_entry, conteo, true, 'Ingresa la cantidad que quieres comprar.')

                    -- Guardamos los precios solamente de los objetos que se mostrarán en el diálogo final.
                    table.insert(ITEMS_IDS, item_entry)
                    table.insert(ITEMS_NAMES, item_name)
                    table.insert(ITEMS_PRICES, item_buyPrice)
                    table.insert(ITEMS_MAXCOUNTS, item_maxCount)
                    table.insert(ITEMS_UNIQUES, isUnique)       

                    P:SendBroadcastMessage(conteo .. '. ' .. item_link .. ' ' .. price_show)                   
                    conteo = conteo + 1
                until not Q:NextRow();

                local plural = (conteo <= 2) and 'encontró un objeto' or 'encontraron ' .. (conteo - 1) .. ' objetos '

                P:SendBroadcastMessage('--------- Se ' .. plural .. ' ------------')
                P:GossipSendMenu(1, U)
            else
                MSG('No se encontraron resultados...', P, 'error')
                P:GossipComplete()
                return
            end
        end
    end

    -- Lógica de compras
    if (option > 0) and (option < 10) then
        local item_id       = send
        local item_name     = ITEMS_NAMES[option]
        local item_price    = ITEMS_PRICES[option]
        local item_maxCount = ITEMS_MAXCOUNTS[option]
        local is_unique     = ITEMS_UNIQUES[option]

        P:SendBroadcastMessage('Selección: ' .. GetItemLink(item_id, 7))
        P:SendBroadcastMessage('Precio: ' .. formatCurrency(item_price))

        local input = (tonumber(raw_input) and math.floor(tonumber(raw_input)) >= 1) and math.floor(tonumber(raw_input)) or 0;

        -- Limitamos la entrada a 200 unidades
        input = (input > 200) and 200 or input

        -- El jugador ingresó un número correcto
        if (input >= 1) then
            local player_money = P:GetCoinage();
            local amount = item_price * COEFFICIENT_PRICE * input;
            local playerID = P:GetGUIDLow();

            if (player_money >= amount) then -- El jugador tiene dinero
                local pago = formatCurrency(item_price * COEFFICIENT_PRICE * input)

                if is_unique then -- El objeto es único
                    -- El jugador desea comprar un objeto único que ya posee
                    if P:HasItem(item_id) then
                        P:SendBroadcastMessage('|cffff0000No puedes llevar más de ese objeto único.')
                        P:GossipComplete()
                        return
                    else -- El jugador no posee el objeto único que desea comprar
                        local single_purchase = item_price * COEFFICIENT_PRICE

                        P:ModifyMoney(-single_purchase)
                        P:AddItem(item_id, 1)
                        P:SendBroadcastMessage('|cff00ff00Has comprado 1x |cffff00ff[' .. item_name .. ']|cff00ff00 por |cffff00ff' .. pago)

                        WorldDBExecute( GetQuery().INSERT_INTO_LOG(P:GetName(), playerID, item_name, item_id, 1, single_purchase) )
                    end
                else -- El objeto NO es único así que la compra solo es limitada por la cantidad de oro del jugador
                    P:ModifyMoney(-amount)
                    P:AddItem(item_id, input)
                    P:SendBroadcastMessage('|cff00ff00Has comprado ' .. input .. 'x |cffff00ff[' .. item_name .. ']|cff00ff00 por |cffff00ff' .. pago)

                    WorldDBExecute( GetQuery().INSERT_INTO_LOG(P:GetName(), playerID, item_name, item_id, input, amount) )
                end
                U:SendUnitSay(P:GetName() .. ' ha comprado ' .. input .. ' ' .. GetItemLink(item_id, 7), 0)

                WorldDBExecute( GetQuery().INSERT_OR_UPDATE_FREQUENT_PURCHASE(item_id, escaparSQL(item_name), item_price, item_maxCount, playerID))

            else -- El jugador no tiene dinero
                P:SendBroadcastMessage('|cffff0000No tienes suficiente dinero para esa compra.')
            end
        else -- El jugador ingresó un número incorrecto
            P:SendBroadcastMessage('|cffff0000Ingresa un número entero positivo.')
        end
        P:GossipComplete()
    end

    -- Añadir objetos (Solo GM)
    if (send == 1) and (option == 0) then
        local input = (tonumber(raw_input) and math.floor(tonumber(raw_input)) >= 1) and math.floor(tonumber(raw_input)) or 0;

        if (input >= 1) then
            --P:SendBroadcastMessage(input .. ' OK!')
            local Q = WorldDBQuery(GetQuery().SELECT_BUYPRICE_AND_MAXCOUNT_BY_ITEM_ENTRY(input) );

            if Q then
                ITEM_ADD     = {}
                local price  = Q:GetUInt32(0);
                local precio = (price == 0) and (COEFFICIENT_PRICE * FLAT_PRICE) or price;
                local maximo = Q:GetUInt32(1);
                local nombre = nombre and extractItemName(GetItemLink(input, 7)) or false;

                if not nombre then
                    nombre = extractItemName(GetItemLink(input, 1))
                end

                P:GossipClearMenu()
                P:GossipMenuAddItem(0, ico(1) .. '[|cff1414ffADD ' .. nombre .. '|r]', 100, input)
                P:GossipMenuAddItem(0, ico(1) .. '[|cffff0000CANCELAR|r]', 999, 999)
                P:GossipSendMenu(1, U)

                table.insert(ITEM_ADD, nombre)
                table.insert(ITEM_ADD, precio)
                table.insert(ITEM_ADD, maximo)

                local link = GetItemLink(input, 7) or GetItemLink(input, 1)

                P:SendBroadcastMessage('Objeto: ' .. link)
                P:SendBroadcastMessage('ID: |cff00ff00' .. input)
                P:SendBroadcastMessage('Precio: |cff00ff00' .. precio)
            else
                P:SendBroadcastMessage('|cffff0000[ERROR]: Ese entry no existe.')
                P:GossipComplete()
            end
        else
            P:SendBroadcastMessage('|cffff0000[ERROR]: Ingresa un número entero positivo.')
            P:GossipComplete()
        end

    elseif (send == 2) and (option == 0) then

        local input = (tonumber(raw_input) and math.floor(tonumber(raw_input)) >= 1) and math.floor(tonumber(raw_input)) or 0;
        local Q = WorldDBQuery(GetQuery().SELECT_BUYPRICE_BY_ITEM_ENTRY(input))

        if Q then
            local link = GetItemLink(input, 7)
            local precio = Q:GetUInt32(0)

            P:GossipClearMenu()
            P:GossipMenuAddItem(0, ico(1) .. 'Ingresar nuevo precio', 101, input, true, "Escribe la cantidad en cobre:")
            P:GossipSendMenu(1, U)

            P:SendBroadcastMessage('Objeto: ' .. link)
            P:SendBroadcastMessage('Precio: |cff00ff00' .. precio)
        else
            P:SendBroadcastMessage('|cffff0000[ERROR]: Ese entry no existe.')
            P:GossipComplete()
        end
        
    -- Eliminar objeto
    elseif (send == 3) and (option == 0) then
        local input = (tonumber(raw_input) and math.floor(tonumber(raw_input)) >= 1) and math.floor(tonumber(raw_input)) or 0;
        local Q = WorldDBQuery(GetQuery().SELECT_ONE_BY_ENTRY(input));

        if Q then
            local link = GetItemLink(input, 7)

            P:GossipClearMenu()
            P:GossipMenuAddItem(0, ico(1) .. 'Eliminar objeto', 102, input, false, "¿Seguro que deseas eliminar este objeto?")
            P:GossipSendMenu(1, U)

            P:SendBroadcastMessage('Objeto: ' .. link)
        else
            P:SendBroadcastMessage('|cffff0000[ERROR]: Ese entry no existe.')
            P:GossipComplete()
        end
    end

end

local function AL_RECARGAR_ELUNA(e)
    local querys = GetQuery()
    WorldDBExecute(querys.CREATE_DATABASE())
    WorldDBExecute(querys.CREATE_LOG_TABLE())
    WorldDBExecute(querys.CREATE_FRECUENT_TABLE())
end

RegisterCreatureGossipEvent(NPC_ID, 1, CLICK_1)
RegisterCreatureGossipEvent(NPC_ID, 2, CLICK_2)
RegisterServerEvent(33, AL_RECARGAR_ELUNA)
