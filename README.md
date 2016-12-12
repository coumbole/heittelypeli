# heittelypeli
Vuorovaikutustekniikan studion projekti

## Featuret
Uusi branch aina develop -branchista
```
git checkout develop
git checkout -b feat/featuren_nimi
```

Kun valmista, mergaa mahdolliset developiin tehdyt muutokset
```
git merge develop feat/featuren_nimi
```
Ratkaise merge conflictit ja mergaa takaisin developiin

```
git checkout develop
git merge develop feat/featuren_nimi
```
