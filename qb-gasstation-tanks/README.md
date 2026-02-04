# QBCore Gas Station Tanks

Komplex benzinkút tartály üzlet QBCore + FiveM számára. Háromféle tartály vásárolható, a tulajdonos üzemanyagot rendel, amit később egy civil munka kézbesít.

## Funkciók
- 3 tartály típus (small/medium/large) eltérő kapacitással és árral.
- Admin kioszthatja a benzinkút üzletet.
- Tulajdonos tartályt fejleszthet (cooldownos), és üzemanyagot rendelhet.
- Civil munkás átveszi és leszállítja a rendelést.
- Adatok JSON fájlban tárolódnak (`data/gasstations.json`).

## Telepítés
1. Másold a `qb-gasstation-tanks` mappát a `resources` alá.
2. Add az `server.cfg`-be:
   ```
   ensure qb-gasstation-tanks
   ```

## Parancsok
- `/gs_assign [playerId] [stationId]` – üzlet kiosztása (admin)
- `/gs_upgrade [stationId] [small|medium|large]` – tartály fejlesztése
- `/gs_order [stationId] [liters]` – üzemanyag rendelés (tulaj)
- `/gs_claim [stationId]` – rendelés felvétele (civil)
- `/gs_deliver [stationId]` – rendelés leadása (civil)

## Konfiguráció
Minden beállítás a `config.lua` fájlban található.
